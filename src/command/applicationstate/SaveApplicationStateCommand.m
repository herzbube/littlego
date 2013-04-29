// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "SaveApplicationStateCommand.h"
#import "../../go/GoGame.h"
#import "../../utility/PathUtilities.h"


@implementation SaveApplicationStateCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSMutableData* data = [NSMutableData data];
  NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  [archiver encodeObject:[GoGame sharedGame] forKey:nsCodingGoGameKey];
  [archiver finishEncoding];

  NSString* backupFolderPath = [PathUtilities backupFolderPath];
  NSString* archiveFilePath = [backupFolderPath stringByAppendingPathComponent:archiveBackupFileName];
  BOOL success = [data writeToFile:archiveFilePath atomically:YES];
  [archiver release];

  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to save NSCoding archive file %@", archiveFilePath];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  return true;
}

@end
