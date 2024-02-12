// -----------------------------------------------------------------------------
// Copyright 2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "UserManualUtilities.h"
#import "../utility/PathUtilities.h"


@implementation UserManualUtilities

// -----------------------------------------------------------------------------
/// @brief Returns the full path to the user manual base folder, i.e. where all
/// files related to the user manual are located.
// -----------------------------------------------------------------------------
+ (NSString*) userManualBaseFolderPath
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* applicationSupportDirectory = [paths objectAtIndex:0];
  return [applicationSupportDirectory stringByAppendingPathComponent:userManualFolderName];
}

// -----------------------------------------------------------------------------
/// @brief Prepends a pre-defined folder to @a fileName, then returns the
/// resulting full path.
///
/// If @a fileExists is not nil, this method also checks whether the file
/// exists and fills @a fileExists with the result.
// -----------------------------------------------------------------------------
+ (NSString*) filePathForUserManualFileNamed:(NSString*)fileName fileExists:(BOOL*)fileExists
{
  NSString* userManualBaseFolderPath = [UserManualUtilities userManualBaseFolderPath];
  return [PathUtilities filePathForFileNamed:fileName
                                  folderPath:userManualBaseFolderPath
                                  fileExists:fileExists];
}

// -----------------------------------------------------------------------------
/// @brief Returns the full path to the file that is the entry point to the
/// user manual.
// -----------------------------------------------------------------------------
+ (NSString*) userManualEntryPointFilePath
{
  NSString* path = [UserManualUtilities userManualBaseFolderPath];

  // Path components must match how the user manual zip archive was generated
  // upstream
  NSArray* pathComponents = @[@"littlego-usermanual", @"public", @"index.html"];
  for (NSString* pathComponent in pathComponents)
    path = [path stringByAppendingPathComponent:pathComponent];

  return path;
}

@end
