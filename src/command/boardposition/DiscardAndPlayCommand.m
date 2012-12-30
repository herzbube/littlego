// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "DiscardAndPlayCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../move/PlayMoveCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/BoardPositionModel.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates different types of commands that DiscardAndPlayCommand
/// knows how to execute.
// -----------------------------------------------------------------------------
enum PlayCommandType
{
  PlayCommandTypePlayMove,
  PlayCommandTypePlayForMe
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for DiscardAndPlayCommand.
// -----------------------------------------------------------------------------
@interface DiscardAndPlayCommand()
/// @name Initialization and deallocation
//@{
- (id) initWithCommandType:(enum PlayCommandType)aPlayCommandType;
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (bool) discardMoves;
- (bool) syncGTPEngine;
- (bool) syncGTPEngineClearBoard;
- (bool) syncGTPEngineHandicap;
- (bool) syncGTPEngineMoves;
- (bool) playCommand;
//@}
/// @name Private properties
//@{
@property(nonatomic, assign) enum PlayCommandType playCommandType;
@property(nonatomic, assign) enum GoMoveType moveType;
@property(nonatomic, retain) GoPoint* point;
//@}
@end


@implementation DiscardAndPlayCommand

@synthesize playCommandType;
@synthesize moveType;
@synthesize point;


// -----------------------------------------------------------------------------
/// @brief Initializes a DiscardAndPlayCommand object that will make a play
/// move at @a point.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)aPoint
{
  assert(aPoint);
  if (! aPoint)
    return nil;
  self = [self initWithCommandType:PlayCommandTypePlayMove];
  self.moveType = GoMoveTypePlay;
  self.point = aPoint;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a DiscardAndPlayCommand object that will make a pass
/// move.
// -----------------------------------------------------------------------------
- (id) initPass
{
  self = [self initWithCommandType:PlayCommandTypePlayMove];
  self.moveType = GoMoveTypePass;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a DiscardAndPlayCommand object that will delegate the
/// move to the computer player.
// -----------------------------------------------------------------------------
- (id) initPlayForMe
{
  return [self initWithCommandType:PlayCommandTypePlayForMe];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a DiscardAndPlayCommand object that will make a move
/// based on @a aPlayCommandType and the property values found when the command
/// is executed.
///
/// @note This is the designated initializer of DiscardAndPlayCommand.
// -----------------------------------------------------------------------------
- (id) initWithCommandType:(enum PlayCommandType)aPlayCommandType
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.playCommandType = aPlayCommandType;
  self.moveType = -1;
  self.point = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DiscardAndPlayCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.point = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool success = [self discardMoves];
  if (success)
  {
    success = [self syncGTPEngine];
    if (success)
      success = [self playCommand];
  }
  return success;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) discardMoves
{
  GoGame* game = [GoGame sharedGame];
  enum GoGameState gameState = game.state;
  assert(GoGameStateGameHasEnded != gameState);
  if (GoGameStateGameHasEnded == gameState)
    return false;
  GoMoveModel* moveModel = game.moveModel;

  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  if (boardPositionModel.isLastPosition)
    return true;
  int indexOfFirstMoveToDiscard = boardPositionModel.currentBoardPosition;
  [moveModel discardMovesFromIndex:indexOfFirstMoveToDiscard];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngine
{
  if (! [self syncGTPEngineClearBoard])
    return false;
  // clear_board affects handicap (but not board size and komi)
  if (! [self syncGTPEngineHandicap])
    return false;
  if (! [self syncGTPEngineMoves])
    return false;
  
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for syncGTPEngine(). Returns true on success, false
/// on failure.
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
/// @brief Private helper for syncGTPEngine(). Returns true on success, false
/// on failure.
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
/// @brief Private helper for syncGTPEngine(). Returns true on success, false
/// on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineMoves
{
  GoMoveModel* moveModel = [GoGame sharedGame].moveModel;
  if (0 == moveModel.numberOfMoves)
    return true;
  NSString* commandString = @"gogui-play_sequence";
  GoMove* move = moveModel.firstMove;
  while (move)
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
        return false;
    }
    move = move.next;
  }
  GtpCommand* commandSetup = [GtpCommand command:commandString];
  commandSetup.waitUntilDone = true;
  [commandSetup submit];
  assert(commandSetup.response.status);
  return commandSetup.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) playCommand
{
  CommandBase* command = nil;
  switch (self.playCommandType)
  {
    case PlayCommandTypePlayMove:
    {
      switch (self.moveType)
      {
        case GoMoveTypePlay:
          command = [[PlayMoveCommand alloc] initWithPoint:self.point];
          break;
        case GoMoveTypePass:
          command = [[PlayMoveCommand alloc] initPass];
          break;
        default:
          break;
      }
      break;
    }
    case PlayCommandTypePlayForMe:
    {
      command = [[ComputerPlayMoveCommand alloc] init];
      break;
    }
    default:
    {
      break;
    }
  }

  if (command)
  {
    [command submit];
    return true;
  }
  else
  {
    return false;
  }
}

@end
