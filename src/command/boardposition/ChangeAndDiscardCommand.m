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
#import "ChangeAndDiscardCommand.h"
#import "ChangeBoardPositionCommand.h"
#import "../backup/BackupGameCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMoveModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ChangeAndDiscardCommand.
// -----------------------------------------------------------------------------
@interface ChangeAndDiscardCommand()
/// @name Private helpers
//@{
- (bool) shouldDiscardBoardPositions;
- (bool) discardMoves;
//@}
@end


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
    [self performSelector:@selector(postLongRunningNotificationOnMainThread:)
                 onThread:[NSThread mainThread]
               withObject:longRunningActionStarts
            waitUntilDone:YES];
    // Before we discard, first change to a board position that will be valid
    // even after the discard. Note that because we step back only one board
    // position, ChangeBoardPositionCommand is executed synchronously.
    bool success = [[[[ChangeBoardPositionCommand alloc] initWithOffset:-1] autorelease] submit];
    if (! success)
    {
      DDLogError(@"%@: Aborting because ChangeBoardPositionCommand execution failed", [self shortDescription]);
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
    success = [[[[BackupGameCommand alloc] init] autorelease] submit];
    if (! success)
    {
      DDLogError(@"%@: Aborting because BackupGameCommand execution failed", [self shortDescription]);
      return false;
    }
    return success;
  }
  @finally
  {
    [self performSelector:@selector(postLongRunningNotificationOnMainThread:)
                 onThread:[NSThread mainThread]
               withObject:longRunningActionEnds
            waitUntilDone:YES];
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
  enum GoGameState gameState = game.state;
  assert(GoGameStateGameHasEnded != gameState);
  if (GoGameStateGameHasEnded == gameState)
  {
    DDLogError(@"%@: Unexpected game state: GoGameStateGameHasEnded", [self shortDescription]);
    return false;
  }
  GoBoardPosition* boardPosition = game.boardPosition;
  int indexOfFirstMoveToDiscard = boardPosition.currentBoardPosition;
  GoMoveModel* moveModel = game.moveModel;
  [moveModel discardMovesFromIndex:indexOfFirstMoveToDiscard];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper. Is invoked in the context of the main thread.
// -----------------------------------------------------------------------------
- (void) postLongRunningNotificationOnMainThread:(NSString*)notificationName
{
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

@end
