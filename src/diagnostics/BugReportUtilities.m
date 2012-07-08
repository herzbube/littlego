// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "BugReportUtilities.h"


@implementation BugReportUtilities

// -----------------------------------------------------------------------------
/// @brief Returns true if a file with diagnostics information exists in the app
/// bundle's Application Support folder. Returns false if no such file exists.
// -----------------------------------------------------------------------------
+ (bool) diagnosticsInformationExists
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  return [fileManager fileExistsAtPath:[self diagnosticsInformationFilePath]];
}

// -----------------------------------------------------------------------------
/// @brief Returns the name (i.e. not the path) of the diagnostics information
/// folder.
// -----------------------------------------------------------------------------
+ (NSString*) diagnosticsInformationFolderName
{
  return [bugReportDiagnosticsInformationFileName stringByDeletingPathExtension];
}

// -----------------------------------------------------------------------------
/// @brief Returns the full path of the diagnostics information folder.
///
/// This is the location where the folder must exist in order for its content
/// to be restored when the application is launched.
// -----------------------------------------------------------------------------
+ (NSString*) diagnosticsInformationFolderPath
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* applicationSupportFolder = [paths objectAtIndex:0];
  return [applicationSupportFolder stringByAppendingPathComponent:[BugReportUtilities diagnosticsInformationFolderName]];
}

// -----------------------------------------------------------------------------
/// @brief Returns the full path of the diagnostics information file.
///
/// This is the location where the file must exist in order for its content
/// to be restored when the application is launched.
// -----------------------------------------------------------------------------
+ (NSString*) diagnosticsInformationFilePath
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* applicationSupportFolder = [paths objectAtIndex:0];
  return [applicationSupportFolder stringByAppendingPathComponent:bugReportDiagnosticsInformationFileName];
}

@end
