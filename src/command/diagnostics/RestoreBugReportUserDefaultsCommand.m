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
#import "RestoreBugReportUserDefaultsCommand.h"
#import "../../diagnostics/BugReportUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../utility/PathUtilities.h"

// 3rdparty library includes
#import <zipkit/ZKDefs.h>
#import <zipkit/ZKFileArchive.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// RestoreBugReportUserDefaultsCommand.
// -----------------------------------------------------------------------------
@interface RestoreBugReportUserDefaultsCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Initialization and deallocation
//@{
- (bool) unzipDiagnosticsInformationFile;
- (bool) restoreUserDefaults;
//@}
@end


@implementation RestoreBugReportUserDefaultsCommand


// -----------------------------------------------------------------------------
/// @brief Initializes a RestoreBugReportUserDefaultsCommand object.
///
/// @note This is the designated initializer of
/// RestoreBugReportUserDefaultsCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// RestoreBugReportUserDefaultsCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool success = [self unzipDiagnosticsInformationFile];
  if (! success)
    return false;
  success = [self restoreUserDefaults];
  if (! success)
    return false;
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Extracts the contents of the diagnostics information file into a
/// folder from where subsequent operations can take whatever files they
/// require.
// -----------------------------------------------------------------------------
- (bool) unzipDiagnosticsInformationFile
{
  NSString* diagnosticsInformationFolderPath = [BugReportUtilities diagnosticsInformationFolderPath];
  [PathUtilities deleteItemIfExists:diagnosticsInformationFolderPath];

  NSString* diagnosticsInformationFilePath = [BugReportUtilities diagnosticsInformationFilePath];
  ZKFileArchive* diagnosticsInformationArchive = [ZKFileArchive archiveWithArchivePath:diagnosticsInformationFilePath];
  NSInteger result = [diagnosticsInformationArchive inflateToDiskUsingResourceFork:NO];
  if (zkSucceeded != result)
  {
    DDLogError(@"RestoreBugReportUserDefaultsCommand: Failed to extract content of diagnostics information file");
    return false;
  }

  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (! [fileManager fileExistsAtPath:[BugReportUtilities diagnosticsInformationFolderPath]])
  {
    NSString* logMessage = [NSString stringWithFormat:@"RestoreBugReportUserDefaultsCommand: Diagnostics information file did not expand to expected folder %@", diagnosticsInformationFolderPath];
    DDLogError(@"%@", logMessage);
    return false;
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Performs the actual restore of the user defaults inside the
/// diagnostics information package.
// -----------------------------------------------------------------------------
- (bool) restoreUserDefaults
{
  NSString* bugReportUserDefaultsFilePath = [[BugReportUtilities diagnosticsInformationFolderPath] stringByAppendingPathComponent:bugReportUserDefaultsFileName];
  NSDictionary* bugReportUserDefaults = [NSDictionary dictionaryWithContentsOfFile:bugReportUserDefaultsFilePath];
  if (! bugReportUserDefaults)
  {
    DDLogError(@"RestoreBugReportUserDefaultsCommand: Failed to load user defaults from diagnostics information packge");
    return false;
  }

  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  for (NSString* key in bugReportUserDefaults)
  {
    id value = [bugReportUserDefaults valueForKey:key];
    [userDefaults setValue:value forKey:key];
  }
  return true;
}

@end
