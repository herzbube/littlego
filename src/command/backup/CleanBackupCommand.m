// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for CleanBackupCommand.
// -----------------------------------------------------------------------------
@interface CleanBackupCommand()
@end


@implementation CleanBackupCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* appSupportDirectory = [paths objectAtIndex:0];
  NSString* sgfBackupFilePath = [appSupportDirectory stringByAppendingPathComponent:sgfBackupFileName];

  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:sgfBackupFilePath])
    [fileManager removeItemAtPath:sgfBackupFilePath error:nil];

  return true;
}

@end
