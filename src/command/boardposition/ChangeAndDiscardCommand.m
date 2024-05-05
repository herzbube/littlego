// -----------------------------------------------------------------------------
// Copyright 2013-2024 Patrick Näf (herzbube@herzbube.ch)
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
  bool shouldDiscardNodes = [self shouldDiscardNodes];
  bool shouldRevertGameStateToInProgress = [self shouldRevertGameStateToInProgress];
  if (! shouldDiscardNodes && ! shouldRevertGameStateToInProgress)
    return true;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    bool success;

    // Before we discard, first change to a node that will be valid even after
    // the discard.
    if (shouldDiscardNodes)
    {
      success = [self changeCurrentNodeIfNecessary];
      if (! success)
      {
        DDLogError(@"%@: Aborting because changeCurrentNodeIfNecessary failed", [self shortDescription]);
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

    if (shouldDiscardNodes)
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
/// @brief Private helper for doIt(). Returns true if nodes need to be
/// discarded, false otherwise.
// -----------------------------------------------------------------------------
- (bool) shouldDiscardNodes
{
  GoGame* game = [GoGame sharedGame];

  // If the root node has any children, then
  // - If the current node is not the root node: We have to discard at least the
  //   current node
  // - If the current node is the root node: We have to discard the first child
  //   of the root node that comes next in the current game variation. It is
  //   not possible that the current game variation consists of only the root
  //   node.
  // In both cases we have to discard at least one node and can therefore return
  // true.
  return game.nodeModel.rootNode.hasChildren;
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
///
/// This method changes the current node in preparation of the discard. When
/// this method returns, the first child of the current node that comes next in
/// the current game variation can be discarded. Read the class documentation
/// for details.
// -----------------------------------------------------------------------------
- (bool) changeCurrentNodeIfNecessary
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  if (boardPosition.currentBoardPosition == 0)
    return true;

  int numberOfNodesInCurrentGameVariationToDiscard = 1;

  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  if (boardPositionModel.discardMyLastMove)
  {
    GoMove* currentMove = boardPosition.currentNode.goMove;

    // The idea of the "Discard my last move" feature is to make the user's life
    // easier when a computer vs. human game is going on. For the feature to
    // have any effect the current node must therefore be created by a move
    // played by the computer player, and the current node's parent node must
    // be created by a move played by the human player. Only then do we discard
    // more than 1 board position. Multiple human player moves (which means
    // non-alternating play) are all discarded together. This can occur even in
    // a computer vs. human game. Any board positions that are non-moves break
    // the discard chain.
    if (currentMove && ! currentMove.player.player.human)
    {
      GoNode* node = boardPosition.currentNode.parent;
      while (node && node.goMove && node.goMove.player.player.human)
      {
        numberOfNodesInCurrentGameVariationToDiscard++;
        node = node.parent;
      }
    }
  }

  // We want ChangeBoardPositionCommand to execute synchronously because the
  // remaining parts of ChangeAndDiscardCommand depend on the current node
  // having changed. ChangeBoardPositionCommand executes synchronously only if
  // the new board position is not more than a given maximum number of positions
  // away from the current board position. Because of this we use a loop that
  // changes board positions in chunks.
  int changeChunkSize = [ChangeBoardPositionCommand synchronousExecutionThreshold];
  while (numberOfNodesInCurrentGameVariationToDiscard > 0)
  {
    int offset;
    if (numberOfNodesInCurrentGameVariationToDiscard > changeChunkSize)
      offset = -changeChunkSize;
    else
      offset = -numberOfNodesInCurrentGameVariationToDiscard;
    numberOfNodesInCurrentGameVariationToDiscard += offset;

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
///
/// This method discards the child node of the current node that comes next in
/// the current game variation, and all of that child node's children. This
/// method expects that the current node was changed before this method was
/// invoked, so that the discard operation does what is documented in the
/// class documentation.
// -----------------------------------------------------------------------------
- (bool) discardNodesIfNecessary
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoNodeModel* nodeModel = game.nodeModel;

  int indexOfFirstNodeToDiscard = boardPosition.currentBoardPosition + 1;
  int numberOfNodesInCurrentGameVariation = nodeModel.numberOfNodes;
  if (indexOfFirstNodeToDiscard >= numberOfNodesInCurrentGameVariation)
    return true;

  GoNode* firstNodeToDiscard = [nodeModel nodeAtIndex:indexOfFirstNodeToDiscard];
  bool newNodesWillBeMergedIntoCurrentGameVariation = (firstNodeToDiscard.hasNextSibling ||
                                                       firstNodeToDiscard.hasPreviousSibling);

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

  if (newNodesWillBeMergedIntoCurrentGameVariation)
    [center postNotificationName:currentGameVariationWillChange object:nil];

  // This counts only the direct descendant nodes in the current game variation.
  // If any of the children of the first discarded node has siblings then
  // the total number of discarded nodes is higher
  int numberOfNodesInCurrentGameVariationToDiscard = numberOfNodesInCurrentGameVariation - indexOfFirstNodeToDiscard;
  DDLogInfo(@"%@: Index position of first node to discard = %d, number of nodes in current game variation to discard = %d", [self shortDescription], indexOfFirstNodeToDiscard, numberOfNodesInCurrentGameVariationToDiscard);
  [nodeModel discardNodesFromIndex:indexOfFirstNodeToDiscard];

  // Adjust number of board positions and send numberOfBoardPositionsDidChange
  // after currentGameVariationWillChange, but before
  // currentGameVariationDidChange => the game variation change and the number
  // of board positions change can be seen as belonging to the same
  // "transaction" that is bounded by the willChange/didChange notifications.
  int oldNumberOfBoardPositions = boardPosition.numberOfBoardPositions;
  int newNumberOfBoardPositions = nodeModel.numberOfNodes;
  if (oldNumberOfBoardPositions != newNumberOfBoardPositions)
  {
    boardPosition.numberOfBoardPositions = newNumberOfBoardPositions;
    [center postNotificationName:numberOfBoardPositionsDidChange object:@[[NSNumber numberWithInt:oldNumberOfBoardPositions], [NSNumber numberWithInt:newNumberOfBoardPositions]]];
  }

  if (newNodesWillBeMergedIntoCurrentGameVariation)
    [center postNotificationName:currentGameVariationDidChange object:nil];

  [center postNotificationName:goNodeTreeLayoutDidChange object:nil];

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
