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
#import "BackupGameCommand.h"
#import "../../go/GoGame.h"
#import "../../gtp/GtpCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/model/ScoringModel.h"


@implementation BackupGameCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSString* backupFolder = [self backupFolder];
  [self saveArchive:backupFolder];
  if (self.saveSgf)
    [self saveSgf:backupFolder];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (NSString*) backupFolder
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  return [paths objectAtIndex:0];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) saveArchive:(NSString*)backupFolder
{
  DDLogVerbose(@"%@: Saving NSCoding archive", [self shortDescription]);

  NSMutableData* data = [NSMutableData data];
  NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

  GoGame* game = [GoGame sharedGame];
  [archiver encodeObject:game forKey:nsCodingGoGameKey];
  ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
  if (scoringModel.scoringMode)
  {
    GoScore* score = scoringModel.score;
    [archiver encodeObject:score forKey:nsCodingGoScoreKey];
  }
  [archiver finishEncoding];

  NSString* archivePath = [backupFolder stringByAppendingPathComponent:archiveBackupFileName];
  BOOL success = [data writeToFile:archivePath atomically:YES];
  [archiver release];

  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to save NSCoding archive file %@", archivePath];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) saveSgf:(NSString*)backupFolder
{
  DDLogVerbose(@"%@: Saving current game to .sgf file", [self shortDescription]);

  // Secretly and heinously change the working directory so that the .sgf
  // file goes to a directory that the user cannot look into
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:backupFolder];
  DDLogVerbose(@"%@: Working directory changed to %@", [self shortDescription], backupFolder);

  NSString* commandString = [NSString stringWithFormat:@"savesgf %@", sgfBackupFileName];
  GtpCommand* command = [GtpCommand command:commandString];
  command.waitUntilDone = true;
  [command submit];

  // Switch back to the original directory
  [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];
  DDLogVerbose(@"%@: Working directory changed to %@", [self shortDescription], oldCurrentDirectory);
}

@end
