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
#import "BackupGameToSgfCommand.h"
#import "../../gtp/GtpCommand.h"
#import "../../utility/PathUtilities.h"


@implementation BackupGameToSgfCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSString* backupFolderPath = [PathUtilities backupFolderPath];

  // Secretly and heinously change the working directory so that the .sgf
  // file goes to a directory that the user cannot look into
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:backupFolderPath];
  DDLogVerbose(@"%@: Working directory changed to %@", [self shortDescription], backupFolderPath);

  NSString* commandString = [NSString stringWithFormat:@"savesgf %@", sgfBackupFileName];
  [[GtpCommand command:commandString] submit];

  // Switch back to the original directory
  [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];
  DDLogVerbose(@"%@: Working directory changed to %@", [self shortDescription], oldCurrentDirectory);

  return true;
}

@end
