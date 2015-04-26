// -----------------------------------------------------------------------------
// Copyright 2012-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "../game/ContinueGameCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../move/PlayMoveCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMoveModel.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates different types of commands that DiscardAndPlayCommand
/// knows how to execute.
// -----------------------------------------------------------------------------
enum PlayCommandType
{
  PlayCommandTypePlayMove,
  PlayCommandTypeComputerPlayMove,
  PlayCommandTypeContinue
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for DiscardAndPlayCommand.
// -----------------------------------------------------------------------------
@interface DiscardAndPlayCommand()
@property(nonatomic, assign) enum PlayCommandType playCommandType;
@property(nonatomic, assign) enum GoMoveType moveType;
@property(nonatomic, retain) GoPoint* point;
@end


@implementation DiscardAndPlayCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a DiscardAndPlayCommand object that will make a play
/// move at @a point.
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
- (id) initComputerPlay
{
  return [self initWithCommandType:PlayCommandTypeComputerPlayMove];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a DiscardAndPlayCommand object that will continue a
/// computer vs. computer game that is paused.
// -----------------------------------------------------------------------------
- (id) initContinue
{
  return [self initWithCommandType:PlayCommandTypeContinue];
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
  @try
  {
    [[LongRunningActionCounter sharedCounter] increment];
    bool shouldDiscardBoardPositions = [self shouldDiscardBoardPositions];
    if (shouldDiscardBoardPositions)
    {
      bool success = [self revertGameStateIfNecessary];
      if (! success)
      {
        DDLogError(@"%@: Aborting because revertGameStateIfNecessary failed", [self shortDescription]);
        return false;
      }
      success = [self discardBoardPositions];
      if (! success)
      {
        DDLogError(@"%@: Aborting because discardBoardPositions failed", [self shortDescription]);
        return false;
      }
    }
    bool success = [self playCommand];
    if (! success)
    {
      DDLogError(@"%@: Aborting because playCommand failed", [self shortDescription]);
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
/// @brief Private helper for doIt(). Returns true if board positions need to be
/// discarded, false otherwise.
// -----------------------------------------------------------------------------
- (bool) shouldDiscardBoardPositions
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  bool shouldDiscardBoardPositions;
  if (boardPosition.isLastPosition)
    shouldDiscardBoardPositions =  false;
  else
    shouldDiscardBoardPositions = true;
  DDLogVerbose(@"%@: shouldDiscardBoardPositions = %d", [self shortDescription], shouldDiscardBoardPositions);
  return shouldDiscardBoardPositions;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) revertGameStateIfNecessary
{
  GoGame* game = [GoGame sharedGame];
  if (GoGameStateGameHasEnded == game.state)
    [game revertStateFromEndedToInProgress];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) discardBoardPositions
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  int indexOfFirstMoveToDiscard = boardPosition.currentBoardPosition;
  DDLogInfo(@"%@: Index position of first move to discard = %d", [self shortDescription], indexOfFirstMoveToDiscard);
  GoMoveModel* moveModel = game.moveModel;
  [moveModel discardMovesFromIndex:indexOfFirstMoveToDiscard];
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
    [command submit];
    return true;
  }
  else
  {
    return false;
  }
}

@end
