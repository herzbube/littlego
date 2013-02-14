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
#import "../../main/ApplicationDelegate.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../play/boardposition/BoardPositionModel.h"


@implementation RestoreGameCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSString* sgfBackupFilePath = [self sgfBackupFilePath];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:sgfBackupFilePath])
  {
    [self restoreGame:sgfBackupFilePath];
    [self restoreBoardPosition];
  }
  else
  {
    [[[NewGameCommand alloc] init] submit];
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (NSString*) sgfBackupFilePath
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* appSupportDirectory = [paths objectAtIndex:0];
  return [appSupportDirectory stringByAppendingPathComponent:sgfBackupFileName];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) restoreGame:(NSString*)sgfBackupFilePath
{
  LoadGameCommand* loadCommand = [[LoadGameCommand alloc] initWithFilePath:sgfBackupFilePath gameName:@"Backup"];
  loadCommand.restoreMode = true;
  [loadCommand submit];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
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
    [[[ChangeBoardPositionCommand alloc] initWithBoardPosition:boardPositionModel.boardPositionLastViewed] submit];
  }
}

@end
