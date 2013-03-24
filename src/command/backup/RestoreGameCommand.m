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
#import "RestoreGameCommand.h"
#import "../boardposition/ChangeBoardPositionCommand.h"
#import "../game/LoadGameCommand.h"
#import "../game/NewGameCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/ScoringModel.h"
#import "../../play/boardposition/BoardPositionModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for RestoreGameCommand.
// -----------------------------------------------------------------------------
@interface RestoreGameCommand()
@property(nonatomic, retain) GoGame* unarchivedGame;
@property(nonatomic, retain) GoScore* unarchivedScore;
@end


@implementation RestoreGameCommand

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this RestoreGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.unarchivedGame = nil;
  self.unarchivedScore = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! [self tryRestoreFromArchive])
  {
    if (! [self tryRestoreFromSgf])
    {
      [[[[NewGameCommand alloc] init] autorelease] submit];
    }
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (bool) tryRestoreFromArchive
{
  DDLogVerbose(@"%@: Restoring game from NSCoding archive", [self shortDescription]);
  BOOL fileExists;
  NSString* backupFilePath = [self filePathForBackupFileNamed:archiveBackupFileName fileExists:&fileExists];
  if (! fileExists)
    return false;
  NSData* data = [NSData dataWithContentsOfFile:backupFilePath];
  NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  self.unarchivedGame = [unarchiver decodeObjectForKey:nsCodingGoGameKey];
  self.unarchivedScore = [unarchiver decodeObjectForKey:nsCodingGoScoreKey];
  [unarchiver finishDecoding];
  [unarchiver release];
  if (! self.unarchivedGame)
    return false;
  [self fixObjectReferences];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tryRestoreFromArchive().
// -----------------------------------------------------------------------------
- (void) fixObjectReferences
{
  DDLogVerbose(@"%@: Fixing object references", [self shortDescription]);
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  applicationDelegate.game = self.unarchivedGame;
  // Must send this notification manually. Must send it now before scoring model
  // sends its own notification.
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameDidCreate object:self.unarchivedGame];
  if (self.unarchivedScore)
  {
    ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
    // Scoring model sends its own notification
    [scoringModel restoreScoringModeWithScoreObject:self.unarchivedScore];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (bool) tryRestoreFromSgf
{
  DDLogVerbose(@"%@: Restoring game from .sgf file", [self shortDescription]);
  BOOL fileExists;
  NSString* backupFilePath = [self filePathForBackupFileNamed:sgfBackupFileName fileExists:&fileExists];
  if (! fileExists)
    return false;
  LoadGameCommand* loadCommand = [[[LoadGameCommand alloc] initWithFilePath:backupFilePath] autorelease];
  loadCommand.restoreMode = true;
  // LoadGameCommand executes synchronously because this RestoreGameCommand
  // is already asynchronous
  bool success = [loadCommand submit];
  if (! success)
    return false;
  [self restoreBoardPosition];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tryRestoreFromSgf().
// -----------------------------------------------------------------------------
- (void) restoreBoardPosition
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  // Integrity check in case the model has a stale value (e.g. due to an app
  // crash)
  if (boardPositionModel.boardPositionLastViewed > boardPosition.currentBoardPosition)
    return;
  // Special value -1 means "last board position of the game"
  if (-1 == boardPositionModel.boardPositionLastViewed)
    boardPositionModel.boardPositionLastViewed = boardPosition.currentBoardPosition;
  else
  {
    // We don't care whether ChangeBoardPositionCommand presents itself as a
    // synchronous or asynchronous command - because this RestoreGamecommand
    // class already is asynchronous, ChangeBoardPositionCommand will always
    // be executed synchronously.
    [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:boardPositionModel.boardPositionLastViewed] autorelease] submit];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (NSString*) filePathForBackupFileNamed:(NSString*)backupFileName fileExists:(BOOL*)fileExists
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* appSupportDirectory = [paths objectAtIndex:0];
  NSString* backupFilePath = [appSupportDirectory stringByAppendingPathComponent:backupFileName];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  *fileExists = [fileManager fileExistsAtPath:backupFilePath];
  DDLogVerbose(@"%@: Checking file %@, file exists = %d", [self shortDescription], backupFilePath, *fileExists);
  return backupFilePath;
}

@end
