// -----------------------------------------------------------------------------
// Copyright 2012 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "GenerateDiagnosticsInformationFileCommand.h"
#import "../../go/GoGame.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/PathUtilities.h"

// 3rdparty library includes
#import <zipkit/ZKDefs.h>
#import <zipkit/ZKFileArchive.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// GenerateDiagnosticsInformationFileCommand.
// -----------------------------------------------------------------------------
@interface GenerateDiagnosticsInformationFileCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Collecting pieces of information
//@{
- (void) saveInMemoryObjects;
- (void) saveUserDefaults;
- (void) saveCurrentGameAsSgf;
- (void) saveBoardScreenshot;
- (void) saveBoardAsSeenByGtpEngine;
//@}
/// @name Private helpers
//@{
- (void) setup;
- (void) cleanup;
- (void) zipDiagnosticsInformationFolder;
- (void) writeBugReportFormatVersion:(int)version toFile:(NSString*)filePath;
- (NSString*) boardAsSeenByGtpEngine;
- (void) writeBoardAsSeenByGtpEngine:(NSString*)boardAsSeenByGtpEngine toFile:(NSString*)filePath;
//@}
/// @name Private properties
//@{
@property(nonatomic, retain) NSString* diagnosticsInformationFolderPath;
//@}
@end


@implementation GenerateDiagnosticsInformationFileCommand

@synthesize diagnosticsInformationFolderPath;
@synthesize diagnosticsInformationFilePath;


// -----------------------------------------------------------------------------
/// @brief Initializes a GenerateDiagnosticsInformationFileCommand object.
///
/// @note This is the designated initializer of
/// GenerateDiagnosticsInformationFileCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  // Collect information in temp folder
  NSString* diagnosticsInformationFolderName = [bugReportDiagnosticsInformationFileName stringByDeletingPathExtension];
  self.diagnosticsInformationFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:diagnosticsInformationFolderName];

  // Place final diagnostics information file in document folder where it can
  // be picked up by iTunes file sharing.
  // NOTE: If you change the folder where the file is stored, you must also
  // change code in ArchiveViewModel where the file is ignored.
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, expandTilde);
  self.diagnosticsInformationFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:bugReportDiagnosticsInformationFileName];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// GenerateDiagnosticsInformationFileCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.diagnosticsInformationFolderPath = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool success = true;
  @try
  {
    [self setup];

    [self saveInMemoryObjects];
    [self saveUserDefaults];
    [self saveCurrentGameAsSgf];
    [self saveBoardScreenshot];
    [self saveBoardAsSeenByGtpEngine];

    [self zipDiagnosticsInformationFolder];
  }
  @catch (NSException* exception)
  {
    NSString* logMessage = [NSString stringWithFormat:@"GenerateDiagnosticsInformationFileCommand: Failed with exception %@. Exception reason: %@", [exception name], [exception reason]];
    DDLogError(logMessage);
    success = false;
  }
  @finally
  {
    [self cleanup];
  }

  return success;
}

// -----------------------------------------------------------------------------
/// @brief Saves in-memory objects to an on-disk file.
// -----------------------------------------------------------------------------
- (void) saveInMemoryObjects
{
  DDLogInfo(@"GenerateDiagnosticsInformationFileCommand: Writing in-memory objects to file");

  NSMutableData* data = [NSMutableData data];
  NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

  GoGame* game = [GoGame sharedGame];
  [archiver encodeObject:game forKey:@"GoGame"];
  [archiver finishEncoding];

  NSString* archivePath = [self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportInMemoryObjectsArchiveFileName];
  BOOL success = [data writeToFile:archivePath atomically:YES];
  [archiver release];

  if (! success)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to write in-memory objects to file %@", archivePath]
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Saves the current user defaults to an on-disk file.
// -----------------------------------------------------------------------------
- (void) saveUserDefaults
{
  DDLogInfo(@"GenerateDiagnosticsInformationFileCommand: Writing user defaults to file");

  [[ApplicationDelegate sharedDelegate] writeUserDefaults];

  NSString* userDefaultsDictionaryPath = [self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportUserDefaultsFileName];
  NSDictionary* userDefaultsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
  BOOL success = [userDefaultsDictionary writeToFile:userDefaultsDictionaryPath atomically:YES];
  if (! success)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to write user defaults to file %@", userDefaultsDictionaryPath]
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Saves the current game to an .sgf file. This task is delegated to
/// the GTP engine.
// -----------------------------------------------------------------------------
- (void) saveCurrentGameAsSgf
{
  DDLogInfo(@"GenerateDiagnosticsInformationFileCommand: Saving current game to .sgf file");

  // Temporarily change working directory so that the .sgf file goes into our
  // folder
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:self.diagnosticsInformationFolderPath];

  NSString* commandString = [NSString stringWithFormat:@"savesgf %@", bugReportCurrentGameFileName];
  GtpCommand* gtpCommand = [GtpCommand command:commandString];
  gtpCommand.waitUntilDone = true;
  [gtpCommand submit];
  bool success = gtpCommand.response.status;

  [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];

  if (! success)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to write current game to .sgf file %@, error while executing 'savesgf' GTP command", bugReportCurrentGameFileName]
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates a screenshot of the views visible on the "Play" tab and
/// saves that screenshot to file.
// -----------------------------------------------------------------------------
- (void) saveBoardScreenshot
{
  DDLogInfo(@"GenerateDiagnosticsInformationFileCommand: Making screen shot of Play view");

  UIImage* image = [UiUtilities captureView:[[ApplicationDelegate sharedDelegate] tabView:TabTypePlay]];
  NSData* data = UIImagePNGRepresentation(image);
  NSString* screenshotPath = [self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportScreenshotFileName];
  BOOL success = [data writeToFile:screenshotPath atomically:YES];
  if (! success)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to save screenshot to file %@", screenshotPath]
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates a text file that contains the output of the "showboard" GTP
/// command.
// -----------------------------------------------------------------------------
- (void) saveBoardAsSeenByGtpEngine
{
  DDLogInfo(@"GenerateDiagnosticsInformationFileCommand: Writing result of 'showboard' GTP command to file");

  NSString* boardAsSeenByGtpEngine = [self boardAsSeenByGtpEngine];
  [self writeBoardAsSeenByGtpEngine:boardAsSeenByGtpEngine
                             toFile:[self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportBoardAsSeenByGtpEngineFileName]];
}

// -----------------------------------------------------------------------------
/// @brief Creates a .zip archive with the information collected in the
/// diagnostics information folder.
// -----------------------------------------------------------------------------
- (void) zipDiagnosticsInformationFolder
{
  DDLogInfo(@"GenerateDiagnosticsInformationFileCommand: Compressing folder");

  ZKFileArchive* bugReportArchive = [ZKFileArchive archiveWithArchivePath:diagnosticsInformationFilePath];
  NSInteger result = [bugReportArchive deflateDirectory:self.diagnosticsInformationFolderPath
                                         relativeToPath:[self.diagnosticsInformationFolderPath stringByDeletingLastPathComponent]
                                      usingResourceFork:NO];
  if (result != zkSucceeded)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to create diagnostics information file from folder %@, error code is %d", self.diagnosticsInformationFolderPath, result]
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs setup operations to prepare for collecting diagnostics
/// information.
///
/// Removes diagnostics information file and folder if they exist. Creates a new
/// diagnostics information folder that is ready to receive the various files
/// that go into the diagnostics information file.
// -----------------------------------------------------------------------------
- (void) setup
{
  NSString* logMessage = [NSString stringWithFormat:@"GenerateDiagnosticsInformationFileCommand: Creating folder ", self.diagnosticsInformationFolderPath];
  DDLogInfo(logMessage);

  [PathUtilities deleteItemIfExists:self.diagnosticsInformationFilePath];
  [PathUtilities createFolder:self.diagnosticsInformationFolderPath removeIfExists:true];
  [self writeBugReportFormatVersion:bugReportFormatVersion
                             toFile:[self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportFormatVersionFileName]];
}

// -----------------------------------------------------------------------------
/// @brief Performs cleanup operations after the diagnostics information file
/// has been created.
///
/// Removes the diagnostics information folder as part of the cleanup
/// operations.
// -----------------------------------------------------------------------------
- (void) cleanup
{
  DDLogInfo(@"GenerateDiagnosticsInformationFileCommand: Cleaning up");

  [PathUtilities deleteItemIfExists:self.diagnosticsInformationFolderPath];
}

// -----------------------------------------------------------------------------
/// @brief Writes the diagnostics information format version @a version to the
/// file located at @a filePath.
// -----------------------------------------------------------------------------
- (void) writeBugReportFormatVersion:(int)version toFile:(NSString*)filePath
{
  NSString* versionString = [NSString stringWithFormat:@"%d", version];
  BOOL success = [versionString writeToFile:filePath
                                 atomically:YES
                                   encoding:NSUTF8StringEncoding
                                      error:nil];
  if (! success)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to write diagnostics information format version %@ to file %@", version, filePath]
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for saveBoardAsSeenByGtpEngine().
// -----------------------------------------------------------------------------
- (NSString*) boardAsSeenByGtpEngine
{
  GtpCommand* gtpCommand = [GtpCommand command:@"showboard"];
  gtpCommand.waitUntilDone = true;
  [gtpCommand submit];
  bool success = gtpCommand.response.status;
  if (! success)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to execute 'showboard' GTP command, response is %@", [gtpCommand.response parsedResponse]]
                                                   userInfo:nil];
    @throw exception;
  }
  return [gtpCommand.response parsedResponse];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for saveBoardAsSeenByGtpEngine().
// -----------------------------------------------------------------------------
- (void) writeBoardAsSeenByGtpEngine:(NSString*)boardAsSeenByGtpEngine toFile:(NSString*)filePath
{
  BOOL success = [boardAsSeenByGtpEngine writeToFile:filePath
                                      atomically:YES
                                        encoding:NSUTF8StringEncoding
                                           error:nil];
  if (! success)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to write result of 'showboard' GTP command to file %@", filePath]
                                                   userInfo:nil];
    @throw exception;
  }
}

@end
