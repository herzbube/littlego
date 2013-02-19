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
#import "SyncGTPEngineCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for SyncGTPEngineCommand.
// -----------------------------------------------------------------------------
@interface SyncGTPEngineCommand()
/// @name Private helpers
//@{
- (bool) syncGTPEngineClearBoard;
- (bool) syncGTPEngineHandicap;
- (bool) syncGTPEngineMoves;
//@}
@end


@implementation SyncGTPEngineCommand


// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! [self syncGTPEngineClearBoard])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineClearBoard failed", [self shortDescription]);
    return false;
  }
  // clear_board affects handicap (but not board size and komi)
  if (! [self syncGTPEngineHandicap])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineHandicap failed", [self shortDescription]);
    return false;
  }
  if (! [self syncGTPEngineMoves])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineMoves failed", [self shortDescription]);
    return false;
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineClearBoard
{
  GtpCommand* commandClearBoard = [GtpCommand command:@"clear_board"];
  commandClearBoard.waitUntilDone = true;
  [commandClearBoard submit];
  assert(commandClearBoard.response.status);
  return commandClearBoard.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineHandicap
{
  GoGame* game = [GoGame sharedGame];
  int handicap = game.handicapPoints.count;
  if (0 == handicap)
    return true;
  GtpCommand* commandFixedHandicap = [GtpCommand command:[NSString stringWithFormat:@"fixed_handicap %d", handicap]];
  commandFixedHandicap.waitUntilDone = true;
  [commandFixedHandicap submit];
  assert(commandFixedHandicap.response.status);
  return commandFixedHandicap.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineMoves
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoMove* moveForCurrentBoardPosition = boardPosition.currentMove;
  if (! moveForCurrentBoardPosition)
    return true;
  NSString* commandString = @"gogui-play_sequence";
  GoMove* move = game.moveModel.firstMove;
  while (true)
  {
    if (move.player.black)
      commandString = [commandString stringByAppendingString:@" B "];
    else
      commandString = [commandString stringByAppendingString:@" W "];
    switch (move.type)
    {
      case GoMoveTypePlay:
        commandString = [commandString stringByAppendingString:move.point.vertex.string];
        break;
      case GoMoveTypePass:
        commandString = [commandString stringByAppendingString:@" PASS"];
        break;
      default:
        DDLogError(@"%@: Unexpected move type %d", [self shortDescription], move.type);
        assert(0);
        return false;
    }
    if (move == moveForCurrentBoardPosition)
      break;
    move = move.next;
  }
  GtpCommand* commandSetup = [GtpCommand command:commandString];
  commandSetup.waitUntilDone = true;
  [commandSetup submit];
  assert(commandSetup.response.status);
  return commandSetup.response.status;
}

@end
