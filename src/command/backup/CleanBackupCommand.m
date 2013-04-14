// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "CleanBackupCommand.h"
#import "../../utility/PathUtilities.h"


@implementation CleanBackupCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL fileExists;
  NSString* sgfBackupFilePath = [PathUtilities filePathForBackupFileNamed:sgfBackupFileName
                                                               fileExists:&fileExists];
  if (fileExists)
  {
    BOOL result = [fileManager removeItemAtPath:sgfBackupFilePath error:nil];
    DDLogVerbose(@"%@: Removed .sgf file %@, result = %d", [self shortDescription], sgfBackupFilePath, result);
  }
  NSString* archiveBackupFilePath = [PathUtilities filePathForBackupFileNamed:archiveBackupFileName
                                                                   fileExists:&fileExists];
  if (fileExists)
  {
    BOOL result = [fileManager removeItemAtPath:archiveBackupFilePath error:nil];
    DDLogVerbose(@"%@: Removed archive file %@, result = %d", [self shortDescription], archiveBackupFilePath, result);
  }
  return true;
}

@end
