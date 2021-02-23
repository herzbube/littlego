// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SyncGTPEngineCommand
// -----------------------------------------------------------------------------
@interface SyncGTPEngineCommand()
@property(nonatomic, retain, readwrite) NSString* errorDescription;
@end

@implementation SyncGTPEngineCommand


// -----------------------------------------------------------------------------
/// @brief Initializes a SyncGTPEngineCommand object.
///
/// @note This is the designated initializer of SyncGTPEngineCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;
  self.syncMoveType = SyncMovesUpToCurrentBoardPosition;
  self.errorDescription = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SyncGTPEngineCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.errorDescription = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  // This clears all board state related parameters (handicap, komi, setup
  // stones, setup player, moves) but leaves board size, game rules and player
  // configuration (e.g. UCT parameters) untouched
  if (! [self syncGTPEngineClearBoard])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineClearBoard failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineHandicap])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineHandicap failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineKomi])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineKomi failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineSetupStones])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineSetupStones failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineSetupPlayer])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineSetupPlayer failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineMoves])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineMoves failed: %@", [self shortDescription], self.errorDescription);
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
  [commandClearBoard submit];
  assert(commandClearBoard.response.status);
  if (commandClearBoard.response.status)
    self.errorDescription = commandClearBoard.response.parsedResponse;
  return commandClearBoard.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineHandicap
{
  GoGame* game = [GoGame sharedGame];

  // The previously sent GTP command "clear_board" has left Fuego without a
  // handicap, so we need to setup handicap only if there is one. The GTP
  NSUInteger handicap = game.handicapPoints.count;
  if (0 == handicap)
    return true;

  NSString* verticesString = [GoUtilities verticesStringForPoints:game.handicapPoints];
  NSString* commandString = [@"set_free_handicap " stringByAppendingString:verticesString];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  assert(command.response.status);
  if (! command.response.status)
    self.errorDescription = command.response.parsedResponse;
  return command.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineKomi
{
  GoGame* game = [GoGame sharedGame];

  // The previously sent GTP command "clear_board" has caused Fuego to reset
  // komi to the last value that was explicitly set with the GTP command "komi"
  // (or to the built-in default komi value, in case no "komi" command was ever
  // sent). Therefore, unlike handicap we always have to setup komi.
  GtpCommand* command = [GtpCommand command:[NSString stringWithFormat:@"komi %.1f", game.komi]];
  [command submit];
  assert(command.response.status);
  if (! command.response.status)
    self.errorDescription = command.response.parsedResponse;
  return command.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineSetupStones
{
  GoGame* game = [GoGame sharedGame];
  if (game.blackSetupPoints.count == 0 && game.whiteSetupPoints.count == 0)
    return true;

  NSString* commandString = @"gogui-setup";

  for (NSNumber* stoneColorAsNumber in @[[NSNumber numberWithInt:GoColorBlack], [NSNumber numberWithInt:GoColorWhite]])
  {
    enum GoColor stoneColor = [stoneColorAsNumber intValue];

    NSArray* setupPoints;
    NSString* colorString;
    if (stoneColor == GoColorBlack)
    {
      setupPoints = game.blackSetupPoints;
      colorString = @"B";
    }
    else
    {
      setupPoints = game.whiteSetupPoints;
      colorString = @"W";
    }

    for (GoPoint* setupPoint in setupPoints)
    {
      NSString* setupStoneString = [NSString stringWithFormat:@" %@ %@", colorString, setupPoint.vertex.string];
      commandString = [commandString stringByAppendingString:setupStoneString];
    }
  }

  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  assert(command.response.status);
  if (! command.response.status)
    self.errorDescription = command.response.parsedResponse;
  return command.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineSetupPlayer
{
  GoGame* game = [GoGame sharedGame];
  if (game.setupFirstMoveColor == GoColorNone)
    return true;

  NSString* colorString;
  if (game.setupFirstMoveColor == GoColorBlack)
    colorString = @"B";
  else
    colorString = @"W";

  NSString* commandString = [NSString stringWithFormat:@"gogui-setup_player %@", colorString];

  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  assert(command.response.status);
  if (! command.response.status)
    self.errorDescription = command.response.parsedResponse;
  return command.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineMoves
{
  GoGame* game = [GoGame sharedGame];
  GoMove* syncUpToThisMove = nil;
  if (SyncMovesUpToCurrentBoardPosition == self.syncMoveType)
    syncUpToThisMove = game.boardPosition.currentMove;
  else
    syncUpToThisMove = game.lastMove;
  if (! syncUpToThisMove)
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
    if (move == syncUpToThisMove)
      break;
    move = move.next;
  }
  GtpCommand* commandSetup = [GtpCommand command:commandString];
  [commandSetup submit];
  assert(commandSetup.response.status);
  if (! commandSetup.response.status)
    self.errorDescription = commandSetup.response.parsedResponse;
  return commandSetup.response.status;
}

@end
