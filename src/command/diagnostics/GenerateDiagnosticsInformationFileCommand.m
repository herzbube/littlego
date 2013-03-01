// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../diagnostics/BugReportUtilities.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/ScoringModel.h"
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
- (void) saveBugReportInfo;
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
- (NSString*) boardAsSeenByGtpEngine;
- (void) writeBoardAsSeenByGtpEngine:(NSString*)boardAsSeenByGtpEngine toFile:(NSString*)filePath;
- (bool) shouldIgnoreUserDefaultsKey:(NSString*)key;
//@}
/// @name Private properties
//@{
@property(nonatomic, retain) NSString* diagnosticsInformationFolderPath;
@property(nonatomic, retain) NSDictionary* registrationDomainDefaults;
//@}
@end


@implementation GenerateDiagnosticsInformationFileCommand

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

  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  // !! IMPORTANT
  // !! The path we use here must be different from the path returned by
  // !! BugReportUtilities::diagnosticsInformationFolderPath(). This is to
  // !! eliminate even the most remote chance (e.g. due to some unexpected
  // !! malfunctioning) that the application launches into bug report mode
  // !! when it is deployed to a productive device.
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  NSString* diagnosticsInformationFolderName = [BugReportUtilities diagnosticsInformationFolderName];
  self.diagnosticsInformationFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:diagnosticsInformationFolderName];

  // Place final diagnostics information file in document folder where it can
  // be picked up by iTunes file sharing.
  // NOTE: If you change the folder where the file is stored, you must also
  // change code in ArchiveViewModel where the file is ignored.
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, expandTilde);
  self.diagnosticsInformationFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:bugReportDiagnosticsInformationFileName];

  self.registrationDomainDefaults = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// GenerateDiagnosticsInformationFileCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.diagnosticsInformationFolderPath = nil;
  self.registrationDomainDefaults = nil;
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

    [self saveBugReportInfo];
    [self saveInMemoryObjects];
    [self saveUserDefaults];
    [self saveCurrentGameAsSgf];
    [self saveBoardScreenshot];
    [self saveBoardAsSeenByGtpEngine];
    [self zipLogFiles];

    [self zipDiagnosticsInformationFolder];
  }
  @catch (NSException* exception)
  {
    DDLogError(@"%@ failed with exception %@", [self shortDescription], exception);
    success = false;
  }
  @finally
  {
    [self cleanup];
  }

  return success;
}

// -----------------------------------------------------------------------------
/// @brief Saves bug report information such as the format version of the
/// diagnostics information and environmental information (iOS version, device
/// type) into a .plist file.
// -----------------------------------------------------------------------------
- (void) saveBugReportInfo
{
  UIDevice* device = [UIDevice currentDevice];
  NSMutableDictionary* bugReportInfoDictionary = [NSMutableDictionary dictionary];
  [bugReportInfoDictionary setValue:[NSString stringWithFormat:@"%d", bugReportFormatVersion] forKey:@"BugReportFormatVersion"];
  [bugReportInfoDictionary setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:@"LittleGoVersion"];
  [bugReportInfoDictionary setValue:[device systemName] forKey:@"SystemName"];
  [bugReportInfoDictionary setValue:[device systemVersion] forKey:@"SystemVersion"];
  [bugReportInfoDictionary setValue:[device model] forKey:@"DeviceModel"];

  NSString* bugReportInfoFilePath = [self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportInfoFileName];
  BOOL success = [bugReportInfoDictionary writeToFile:bugReportInfoFilePath atomically:YES];
  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to write bug report info to file %@", bugReportInfoFilePath];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Saves in-memory objects to an on-disk file.
// -----------------------------------------------------------------------------
- (void) saveInMemoryObjects
{
  DDLogVerbose(@"%@: Writing in-memory objects to file", [self shortDescription]);

  NSMutableData* data = [NSMutableData data];
  NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

  GoGame* game = [GoGame sharedGame];
  [archiver encodeObject:game forKey:@"GoGame"];
  ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
  if (scoringModel.scoringMode)
  {
    GoScore* score = scoringModel.score;
    [archiver encodeObject:score forKey:@"GoScore"];
  }
  [archiver finishEncoding];

  NSString* archivePath = [self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportInMemoryObjectsArchiveFileName];
  BOOL success = [data writeToFile:archivePath atomically:YES];
  [archiver release];

  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to write in-memory objects to file %@", archivePath];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Saves the current user defaults to an on-disk file.
// -----------------------------------------------------------------------------
- (void) saveUserDefaults
{
  DDLogVerbose(@"%@: Writing user defaults to file", [self shortDescription]);

  NSBundle* resourceBundle = [ApplicationDelegate sharedDelegate].resourceBundle;
  NSString* registrationDomainDefaultsPath = [resourceBundle pathForResource:registrationDomainDefaultsResource ofType:nil];
  self.registrationDomainDefaults = [NSDictionary dictionaryWithContentsOfFile:registrationDomainDefaultsPath];

  [[ApplicationDelegate sharedDelegate] writeUserDefaults];
  NSDictionary* userDefaultsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

  NSMutableDictionary* exportDictionary = [NSMutableDictionary dictionary];
  for (NSString* key in userDefaultsDictionary)
  {
    if ([self shouldIgnoreUserDefaultsKey:key])
      continue;
    id value = [userDefaultsDictionary valueForKey:key];
    [exportDictionary setValue:value forKey:key];
  }

  NSString* exportDictionaryPath = [self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportUserDefaultsFileName];
  BOOL success = [exportDictionary writeToFile:exportDictionaryPath atomically:YES];
  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to write user defaults to file %@", exportDictionaryPath];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
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
  DDLogVerbose(@"%@: Saving current game to .sgf file", [self shortDescription]);

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
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to write current game to .sgf file %@, error while executing 'savesgf' GTP command", bugReportCurrentGameFileName];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
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
  DDLogVerbose(@"%@: Making screen shot of Play view", [self shortDescription]);

  UIImage* image = [UiUtilities captureView:[[ApplicationDelegate sharedDelegate] tabView:TabTypePlay]];
  NSData* data = UIImagePNGRepresentation(image);
  NSString* screenshotPath = [self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportScreenshotFileName];
  BOOL success = [data writeToFile:screenshotPath atomically:YES];
  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to save screenshot to file %@", screenshotPath];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
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
  DDLogVerbose(@"%@: Writing result of 'showboard' GTP command to file", [self shortDescription]);

  NSString* boardAsSeenByGtpEngine = [self boardAsSeenByGtpEngine];
  [self writeBoardAsSeenByGtpEngine:boardAsSeenByGtpEngine
                             toFile:[self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportBoardAsSeenByGtpEngineFileName]];
}

// -----------------------------------------------------------------------------
/// @brief Creates a .zip archive in the diagnostics information folder that
/// contains the application log files. The .zip archive is not created if no
/// log files exist.
// -----------------------------------------------------------------------------
- (void) zipLogFiles
{
  DDLogVerbose(@"%@: Zipping log files", [self shortDescription]);
  NSString* logFolder = [[ApplicationDelegate sharedDelegate] logFolder];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (! [fileManager fileExistsAtPath:logFolder])
  {
    DDLogInfo(@"%@: Log folder not found", [self shortDescription]);
    return;
  }
  NSArray* fileList = [fileManager contentsOfDirectoryAtPath:logFolder error:nil];
  if (0 == fileList.count)
  {
    DDLogInfo(@"%@: Log folder found but contains no files", [self shortDescription]);
    return;
  }

  NSString* bugReportLogsArchiveFilePath = [self.diagnosticsInformationFolderPath stringByAppendingPathComponent:bugReportLogsArchiveFileName];
  ZKFileArchive* bugReportArchive = [ZKFileArchive archiveWithArchivePath:bugReportLogsArchiveFilePath];
  NSInteger result = [bugReportArchive deflateDirectory:logFolder
                                         relativeToPath:[logFolder stringByDeletingLastPathComponent]
                                      usingResourceFork:NO];
  if (result != zkSucceeded)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to create logs archive file from folder %@, error code is %d", logFolder, result];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates a .zip archive with the information collected in the
/// diagnostics information folder.
// -----------------------------------------------------------------------------
- (void) zipDiagnosticsInformationFolder
{
  DDLogVerbose(@"%@: Compressing folder", [self shortDescription]);

  ZKFileArchive* bugReportArchive = [ZKFileArchive archiveWithArchivePath:self.diagnosticsInformationFilePath];
  NSInteger result = [bugReportArchive deflateDirectory:self.diagnosticsInformationFolderPath
                                         relativeToPath:[self.diagnosticsInformationFolderPath stringByDeletingLastPathComponent]
                                      usingResourceFork:NO];
  if (result != zkSucceeded)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to create diagnostics information file from folder %@, error code is %d", self.diagnosticsInformationFolderPath, result];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
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
  NSString* logMessage = [NSString stringWithFormat:@"%@: Creating folder %@", [self shortDescription], self.diagnosticsInformationFolderPath];
  DDLogVerbose(@"%@", logMessage);

  [PathUtilities deleteItemIfExists:self.diagnosticsInformationFilePath];
  [PathUtilities createFolder:self.diagnosticsInformationFolderPath removeIfExists:true];
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
  DDLogVerbose(@"%@: Cleaning up", [self shortDescription]);

  [PathUtilities deleteItemIfExists:self.diagnosticsInformationFolderPath];
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
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to execute 'showboard' GTP command, response is %@", [gtpCommand.response parsedResponse]];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
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
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to write result of 'showboard' GTP command to file %@", filePath];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the user default named @a key should be ignored and
/// not be exported to the user defaults dump file.
///
/// The purpose of this method is to ignore alls keys that do not belong to
/// Little Go. The key userDefaultsVersionRegistrationDomainKey is also not
/// exported because this key must never exist outside the registration domain
/// defaults, i.e. if we were exporting it now, the dump file could not be
/// imported later on.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreUserDefaultsKey:(NSString*)key
{
  // Special handling because this key is ***NOT*** in the registration domain
  // defaults, but we want it exported
  if ([key isEqualToString:userDefaultsVersionApplicationDomainKey])
    return false;
  // Special handling because this key ***IS*** in the registration domain
  // defaults, but we don't want it exported
  if ([key isEqualToString:userDefaultsVersionRegistrationDomainKey])
    return true;
  // Everything else that is not in the registration domain defaults is
  // ignored
  if (nil == [self.registrationDomainDefaults objectForKey:key])
    return true;
  else
    return false;
}

@end
