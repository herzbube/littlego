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
#import "ChangeAndDiscardCommand.h"
#import "ChangeBoardPositionCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
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
  if (! shouldDiscardBoardPositions)
    return true;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    // Before we discard, first change to a board position that will be valid
    // even after the discard.
    bool success = [self changeBoardPosition];
    if (! success)
    {
      DDLogError(@"%@: Aborting because changeBoardPosition failed", [self shortDescription]);
      return false;
    }
    success = [self revertGameStateIfNecessary];
    if (! success)
    {
      DDLogError(@"%@: Aborting because revertGameStateIfNecessary failed", [self shortDescription]);
      return false;
    }
    success = [self discardMoves];
    if (! success)
    {
      DDLogError(@"%@: Aborting because discardMoves failed", [self shortDescription]);
      return false;
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
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) changeBoardPosition
{
  int numberOfBoardPositionsToDiscard = 1;

  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  if (boardPositionModel.discardMyLastMove)
  {
    GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
    GoMove* currentMove = boardPosition.currentMove;

    // We only trigger the "Discard my last move" behaviour if the current board
    // position was created by the computer player.
    // - The main reason is that in a human vs. human game we don't want to
    //   discard more than one board position.
    // - Even in a computer vs. human game, though, it is possible to have
    //   non-alternating play where the human player made several moves in a
    //   row. If the user is viewing a board position in the middle or at the
    //   end of such a row of human player moves we also want to discard only
    //   one board position. It may become necessary to revisit this decision,
    //   but at the time of writing this routine it seems best not to discard
    //   too many board positions.
    if (! currentMove.player.player.human)
    {
      GoMove* move = currentMove.previous;
      while (move && move.player.player.human)
      {
        numberOfBoardPositionsToDiscard++;
        move = move.previous;
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
- (bool) discardMoves
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
- (bool) backupGame
{
  return [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
}

@end
