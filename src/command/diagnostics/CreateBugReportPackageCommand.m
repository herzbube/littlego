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
#import "CreateBugReportPackageCommand.h"
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
/// CreateBugReportPackageCommand.
// -----------------------------------------------------------------------------
@interface CreateBugReportPackageCommand()
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
/// @name Helpers
//@{
- (void) setup;
- (void) cleanup;
- (void) zipBugReportFolder;
- (void) writeBugReportFormatVersion:(int)version toFile:(NSString*)filePath;
- (NSString*) boardAsSeenByGtpEngine;
- (void) writeBoardAsSeenByGtpEngine:(NSString*)boardAsSeenByGtpEngine toFile:(NSString*)filePath;
//@}
/// @name Private properties
//@{
@property(nonatomic, retain) NSString* bugReportFolderPath;
//@}
@end


@implementation CreateBugReportPackageCommand

@synthesize bugReportFolderPath;
@synthesize bugReportFilePath;


// -----------------------------------------------------------------------------
/// @brief Initializes a CreateBugReportPackageCommand object.
///
/// @note This is the designated initializer of CreateBugReportPackageCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.bugReportFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:bugReportFolderName];
  self.bugReportFilePath = [self.bugReportFolderPath stringByAppendingString:@".zip"];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CreateBugReportPackageCommand
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.bugReportFolderPath = nil;
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

    [self zipBugReportFolder];
  }
  @catch (NSException* exception)
  {
    NSString* logMessage = [NSString stringWithFormat:@"CreateBugReportPackageCommand: Failed with exception %@. Exception reason: %@", [exception name], [exception reason]];
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
/// @brief Saves those in-memory objects that are necessary for a bug report to
/// an on-disk file.
// -----------------------------------------------------------------------------
- (void) saveInMemoryObjects
{
  DDLogInfo(@"CreateBugReportPackageCommand: Writing in-memory objects to file");

  NSMutableData* data = [NSMutableData data];
  NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

  GoGame* game = [GoGame sharedGame];
  [archiver encodeObject:game forKey:@"GoGame"];
  [archiver finishEncoding];

  NSString* archivePath = [self.bugReportFolderPath stringByAppendingPathComponent:bugReportInMemoryObjectsArchiveFileName];
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
  DDLogInfo(@"CreateBugReportPackageCommand: Writing user defaults to file");

  [[ApplicationDelegate sharedDelegate] writeUserDefaults];

  NSString* userDefaultsDictionaryPath = [self.bugReportFolderPath stringByAppendingPathComponent:bugReportUserDefaultsFileName];
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
  DDLogInfo(@"CreateBugReportPackageCommand: Saving current game to .sgf file");

  // Temporarily change working directory so that the .sgf file goes into our
  // archive folder
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:self.bugReportFolderPath];

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
  DDLogInfo(@"CreateBugReportPackageCommand: Making screen shot of Play view");

  // Can't use PlayView because we also want the toolbar and the buttons it
  // displays
  UIImage* image = [UiUtilities captureView:[[ApplicationDelegate sharedDelegate] tabView:TabTypePlay]];
  NSData* data = UIImagePNGRepresentation(image);
  NSString* screenshotPath = [self.bugReportFolderPath stringByAppendingPathComponent:bugReportScreenshotFileName];
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
  DDLogInfo(@"CreateBugReportPackageCommand: Writing result of 'showboard' GTP command to file");

  NSString* boardAsSeenByGtpEngine = [self boardAsSeenByGtpEngine];
  [self writeBoardAsSeenByGtpEngine:boardAsSeenByGtpEngine
                             toFile:[self.bugReportFolderPath stringByAppendingPathComponent:bugReportBoardAsSeenByGtpEngineFileName]];
}

// -----------------------------------------------------------------------------
/// @brief Creates a .zip archive with the contents of the bug report folder.
// -----------------------------------------------------------------------------
- (void) zipBugReportFolder
{
  DDLogInfo(@"CreateBugReportPackageCommand: Compressing folder");

  ZKFileArchive* bugReportArchive = [ZKFileArchive archiveWithArchivePath:bugReportFilePath];
  NSInteger result = [bugReportArchive deflateDirectory:self.bugReportFolderPath
                                         relativeToPath:[self.bugReportFolderPath stringByDeletingLastPathComponent]
                                      usingResourceFork:NO];
  if (result != zkSucceeded)
  {
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:[NSString stringWithFormat:@"Failed to create bug report archive from folder %@, error code is %d", self.bugReportFolderPath, result]
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs setup operations to prepare for collecting bug report
/// information.
///
/// Removes bug report file and folder if they exist. Creates a new bug report
/// folder that is ready to receive the various pieces of information that are
/// part of a bug report.
// -----------------------------------------------------------------------------
- (void) setup
{
  NSString* logMessage = [NSString stringWithFormat:@"CreateBugReportPackageCommand: Creating folder ", self.bugReportFolderPath];
  DDLogInfo(logMessage);

  [PathUtilities deleteItemIfExists:self.bugReportFilePath];
  [PathUtilities createFolder:self.bugReportFolderPath removeIfExists:true];
  [self writeBugReportFormatVersion:bugReportFormatVersion
                             toFile:[self.bugReportFolderPath stringByAppendingPathComponent:bugReportFormatVersionFileName]];
}

// -----------------------------------------------------------------------------
/// @brief Performs cleanup operations after bug report information has been
/// collected in a .zip archive.
///
/// Removes the bug report folder as part of the cleanup operations.
// -----------------------------------------------------------------------------
- (void) cleanup
{
  DDLogInfo(@"CreateBugReportPackageCommand: Cleaning up");

  [PathUtilities deleteItemIfExists:self.bugReportFolderPath];
}

// -----------------------------------------------------------------------------
/// @brief Writes the bug report format version @a version to the file located
/// at @a filePath.
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
                                                     reason:[NSString stringWithFormat:@"Failed to write bug report format version %@ to file %@", version, filePath]
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
