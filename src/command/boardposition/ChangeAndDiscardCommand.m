// -----------------------------------------------------------------------------
// Copyright 2013-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "ChangeAndDiscardCommand.h"
#import "ChangeBoardPositionCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoPlayer.h"
#import "../../main/ApplicationDelegate.h"
#import "../../player/Player.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../play/model/BoardPositionModel.h"


@implementation ChangeAndDiscardCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool shouldDiscardBoardPositions = [self shouldDiscardBoardPositions];
  bool shouldRevertGameStateToInProgress = [self shouldRevertGameStateToInProgress];
  if (! shouldDiscardBoardPositions && ! shouldRevertGameStateToInProgress)
    return true;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    bool success;

    // Before we discard, first change to a board position that will be valid
    // even after the discard.
    if (shouldDiscardBoardPositions)
    {
      success = [self changeBoardPositionIfNecessary];
      if (! success)
      {
        DDLogError(@"%@: Aborting because changeBoardPositionIfNecessary failed", [self shortDescription]);
        return false;
      }
    }

    if (shouldRevertGameStateToInProgress)
    {
      success = [self revertGameStateIfNecessary];
      if (! success)
      {
        DDLogError(@"%@: Aborting because revertGameStateIfNecessary failed", [self shortDescription]);
        return false;
      }
    }

    if (shouldDiscardBoardPositions)
    {
      success = [self discardNodesIfNecessary];
      if (! success)
      {
        DDLogError(@"%@: Aborting because discardNodesIfNecessary failed", [self shortDescription]);
        return false;
      }
    }

    success = [self backupGame];
    if (! success)
    {
      DDLogError(@"%@: Aborting because backupGame failed", [self shortDescription]);
      return false;
    }

    return success;
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
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
  if (boardPosition.isFirstPosition && 1 == boardPosition.numberOfBoardPositions)
    return false;
  else
    return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true if the game state needs to
/// be reverted to "in progress", false otherwise.
// -----------------------------------------------------------------------------
- (bool) shouldRevertGameStateToInProgress
{
  GoGame* game = [GoGame sharedGame];
  return (game.state == GoGameStateGameHasEnded);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) changeBoardPositionIfNecessary
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  if (boardPosition.currentBoardPosition == 0)
    return true;

  int numberOfBoardPositionsToDiscard = 1;

  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  if (boardPositionModel.discardMyLastMove)
  {
    GoMove* currentMove = boardPosition.currentNode.goMove;

    // The idea of the "Discard my last move" feature is to make the user's life
    // easier when a computer vs. human game is going on. For the feature to
    // have any effect the current board position must therefore be created by
    // a move played by the computer player, and the previous board position
    // must be created by a move played by the human player. Only then do we
    // discard more than 1 board position. Multiple human player moves (which
    // means non-alternating play) are all discarded together. This can occur
    // even in a computer vs. human game. Any board positions that are non-moves
    // break the discard chain.
    if (currentMove && ! currentMove.player.player.human)
    {
      GoNode* node = boardPosition.currentNode.parent;
      while (node && node.goMove && node.goMove.player.player.human)
      {
        numberOfBoardPositionsToDiscard++;
        node = node.parent;
      }
    }
  }

  // We want ChangeBoardPositionCommand to execute synchronously because the
  // remaining parts of ChangeAndDiscardCommand depend on the board position
  // having changed. ChangeBoardPositionCommand executes synchronously only if
  // the new board position is not more than a given maximum number of positions
  // away from the current board position. Because of this we use a loop that
  // changes board positions in chunks.
  int changeChunkSize = [ChangeBoardPositionCommand synchronousExecutionThreshold];
  while (numberOfBoardPositionsToDiscard > 0)
  {
    int offset;
    if (numberOfBoardPositionsToDiscard > changeChunkSize)
      offset = -changeChunkSize;
    else
      offset = -numberOfBoardPositionsToDiscard;
    numberOfBoardPositionsToDiscard += offset;

    // initWithOffset:() is permissive and allows us to specify an offset that
    // would result in an invalid board position. The offset is adjusted in that
    // case to result in a valid board position.
    bool success = [[[[ChangeBoardPositionCommand alloc] initWithOffset:offset] autorelease] submit];
    if (! success)
      return false;
  }

  return true;
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
- (bool) discardNodesIfNecessary
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoNodeModel* nodeModel = game.nodeModel;

  int indexOfFirstNodeToDiscard = boardPosition.currentBoardPosition + 1;
  int numberOfNodes = nodeModel.numberOfNodes;
  if (indexOfFirstNodeToDiscard >= numberOfNodes)
    return true;

  // Adjust number of board positions before nodes are discarded. If we were
  // adjusting the number of board positions after discarding nodes, there
  // would be a small gap in which someone who works with board positions might
  // attempt to access an invalid node.
  int oldNumberOfBoardPositions = boardPosition.numberOfBoardPositions;
  int newNumberOfBoardPositions = indexOfFirstNodeToDiscard;
  boardPosition.numberOfBoardPositions = newNumberOfBoardPositions;
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center postNotificationName:numberOfBoardPositionsDidChange object:@[[NSNumber numberWithInt:oldNumberOfBoardPositions], [NSNumber numberWithInt:newNumberOfBoardPositions]]];

  DDLogInfo(@"%@: Index position of first node to discard = %d, number of nodes = %d", [self shortDescription], indexOfFirstNodeToDiscard, numberOfNodes);
  [nodeModel discardNodesFromIndex:indexOfFirstNodeToDiscard];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) backupGame
{
  return [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
}

@end
