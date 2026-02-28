// -----------------------------------------------------------------------------
// Copyright 2012-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayCommand.h"
#import "../game/ContinueGameCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../move/PlayMoveCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameInfo.h"
#import "../../go/GoGameResult.h"
#import "../../go/GoNodeModel.h"
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
#import "../../play/model/GameVariationModel.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates different types of commands that PlayCommand knows how
/// to execute.
// -----------------------------------------------------------------------------
enum PlayCommandType
{
  PlayCommandTypePlayMove,
  PlayCommandTypeComputerPlayMove,
  PlayCommandTypeContinue
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayCommand.
// -----------------------------------------------------------------------------
@interface PlayCommand()
@property(nonatomic, assign) enum PlayCommandType playCommandType;
@property(nonatomic, assign) enum GoMoveType moveType;
@property(nonatomic, retain) GoPoint* point;
@property(nonatomic, assign) bool didRevertStateFromEndedToInProgress;
@end


@implementation PlayCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayCommand object that will make a play move at
/// @a point.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)aPoint
{
  assert(aPoint);
  if (! aPoint)
  {
    DDLogError(@"%@: GoPoint object is nil", [self shortDescription]);
    return nil;
  }
  self = [self initWithCommandType:PlayCommandTypePlayMove];
  self.moveType = GoMoveTypePlay;
  self.point = aPoint;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayCommand object that will make a pass move.
// -----------------------------------------------------------------------------
- (id) initPass
{
  self = [self initWithCommandType:PlayCommandTypePlayMove];
  self.moveType = GoMoveTypePass;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayCommand object that will delegate the move to the
/// computer player.
// -----------------------------------------------------------------------------
- (id) initComputerPlay
{
  return [self initWithCommandType:PlayCommandTypeComputerPlayMove];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayCommand object that will continue a
/// computer vs. computer game that is paused.
// -----------------------------------------------------------------------------
- (id) initContinue
{
  return [self initWithCommandType:PlayCommandTypeContinue];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayCommand object that will make a move based on
/// @a aPlayCommandType and the property values found when the command is
/// executed.
///
/// @note This is the designated initializer of PlayCommand.
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
  self.didRevertStateFromEndedToInProgress = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayCommand object.
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
  @try
  {
    [[LongRunningActionCounter sharedCounter] increment];

    // GoGame does not allow moves to be played if the game state is
    // GoGameStateGameHasEnded => revert to "not ended" if necessary.
    // The game state can be GoGameStateGameHasEnded if the user is currently
    // viewing a board position that is not the last board position. In that
    // case the new move is expected to create a new game variation. The
    // game state may become GoGameStateGameHasEnded again after the move
    // was played.
    bool success = [self revertGameStateIfNecessary];
    if (! success)
    {
      DDLogError(@"%@: Aborting because revertGameStateIfNecessary failed", [self shortDescription]);
      return false;
    }

    success = [self playCommand];
    if (! success)
    {
      DDLogError(@"%@: Aborting because playCommand failed", [self shortDescription]);
      return false;
    }

    success = [self updateGameResultIfNecessary];
    if (! success)
    {
      DDLogError(@"%@: Aborting because updateGameResultIfNecessary failed", [self shortDescription]);
      return false;
    }

    return true;
  }
  @finally
  {
    [[LongRunningActionCounter sharedCounter] decrement];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) revertGameStateIfNecessary
{
  GoGame* game = [GoGame sharedGame];
  if (GoGameStateGameHasEnded == game.state)
  {
    // If the current game variation is the main variation, the game result
    // needs to be updated in the following cases:
    // - If the new move replaces future nodes, which means we modify the main
    //   variation without changing to a different game variation.
    // - If the new move creates a new game variation, and that new game
    //   variation becomes the main variation (e.g. because of
    //   #GoNewMoveInsertPositionNewVariationAtTop).
    //
    // However, the logic that evaluates GoNewMoveInsertPolicy and
    // GoNewMoveInsertPosition is encapsulated in GoGame, and we don't want to
    // replicate that logic here. We therefore postpone the decision whether to
    // update the game result until after the move was played and we can examine
    // the situation.
    self.didRevertStateFromEndedToInProgress = true;

    [game revertStateFromEndedToInProgress:false];
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) playCommand
{
  DDLogVerbose(@"%@: Play command type = %d", [self shortDescription], self.playCommandType);
  CommandBase* command = nil;
  switch (self.playCommandType)
  {
    case PlayCommandTypePlayMove:
    {
      switch (self.moveType)
      {
        case GoMoveTypePlay:
          command = [[[PlayMoveCommand alloc] initWithPoint:self.point] autorelease];
          break;
        case GoMoveTypePass:
          command = [[[PlayMoveCommand alloc] initPass] autorelease];
          break;
        default:
          DDLogError(@"%@: Unexpected move type %d", [self shortDescription], self.moveType);
          assert(0);
          break;
      }
      break;
    }
    case PlayCommandTypeComputerPlayMove:
    {
      command = [[[ComputerPlayMoveCommand alloc] init] autorelease];
      break;
    }
    case PlayCommandTypeContinue:
    {
      command = [[[ContinueGameCommand alloc] init] autorelease];
      break;
    }
    default:
    {
      DDLogError(@"%@: Unexpected command type %d", [self shortDescription], self.playCommandType);
      assert(0);
      break;
    }
  }

  if (command)
  {
    return [command submit];
  }
  else
  {
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) updateGameResultIfNecessary
{
  if (! self.didRevertStateFromEndedToInProgress)
    return true;

  GoGame* game = [GoGame sharedGame];

  // The move that was played may have ended the game again with a reason that
  // caused the game result to be updated already => in that case we don't have
  // to do anything. At least the following scenarios are conceivable, maybe
  // even more exist:
  // - The computer player resigns
  // - The computer player took too long for its move and the game meanwhile
  //   was ended by the app's time-keeping service (Fuego should always play
  //   before time is up, but the scenario may be real because of unexpected
  //   time effects)
  if (game.state == GoGameStateGameHasEnded)
  {
    switch (game.reasonForGameHasEnded)
    {
      case GoGameHasEndedReasonBlackWinsByResignation:
      case GoGameHasEndedReasonWhiteWinsByResignation:
      case GoGameHasEndedReasonBlackWinsOnTime:
      case GoGameHasEndedReasonWhiteWinsOnTime:
      case GoGameHasEndedReasonBlackWinsByForfeit:
      case GoGameHasEndedReasonWhiteWinsByForfeit:
        return true;
      default:
        break;
    }
  }

  // The game result only needs to be updated if the main variation was
  // changed, or a new game variation has become the main variation
  if (! game.nodeModel.isMainVariation)
    return true;

  GoGameResult* gameResult = game.gameInfo.gameResult;
  if (gameResult.updatePolicy != GoGameResultUpdatePolicyAutomatic)
    return false;

  gameResult.dataType = GoGameResultDataTypeNoResult;
  return true;
}

@end
