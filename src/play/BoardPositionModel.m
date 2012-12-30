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
#import "BoardPositionModel.h"
#import "../go/GoGame.h"
#import "../go/GoMove.h"
#import "../go/GoMoveModel.h"
#import "../go/GoPlayer.h"
#import "../go/GoUtilities.h"
#import "../player/Player.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for BoardPositionModel.
// -----------------------------------------------------------------------------
@interface BoardPositionModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) goGameWillCreate:(NSNotification*)notification;
- (void) goMoveModelChanged:(NSNotification*)notification;
//@}
/// @name Private methods
//@{
- (void) updateGoObjectsToNewPosition:(int)newBoardPosition;
//@}
@end


@implementation BoardPositionModel

@synthesize discardFutureMovesAlert;
@synthesize playOnComputersTurnAlert;
@synthesize currentBoardPosition;


// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionModel object with board position set to 0.
///
/// @note This is the designated initializer of BoardPositionModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.discardFutureMovesAlert = discardFutureMovesAlertDefault;
  self.playOnComputersTurnAlert = playOnComputersTurnAlertDefault;
  self.currentBoardPosition = 0;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goMoveModelChanged:) name:goMoveModelChanged object:nil];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:boardPositionKey];
  self.discardFutureMovesAlert = [[dictionary valueForKey:discardFutureMovesAlertKey] boolValue];
  self.playOnComputersTurnAlert = [[dictionary valueForKey:playOnComputersTurnAlertKey] boolValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithBool:self.discardFutureMovesAlert] forKey:discardFutureMovesAlertKey];
  [dictionary setValue:[NSNumber numberWithBool:self.playOnComputersTurnAlert] forKey:playOnComputersTurnAlertKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:boardPositionKey];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setCurrentBoardPosition:(int)newBoardPosition
{
  if (newBoardPosition == currentBoardPosition)
    return;

  int indexOfTargetMove = newBoardPosition - 1;
  GoMoveModel* moveModel = [GoGame sharedGame].moveModel;
  int numberOfMoves = moveModel.numberOfMoves;
  int indexOfLastMove = numberOfMoves - 1;
  if (newBoardPosition < 0 || indexOfTargetMove > indexOfLastMove)
  {
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:[NSString stringWithFormat:@"Illegal board position %d is either <0 or exceeds number of moves (%d) in current game", newBoardPosition, numberOfMoves]
                                                   userInfo:nil];
    @throw exception;
  }

  [self updateGoObjectsToNewPosition:newBoardPosition];

  currentBoardPosition = newBoardPosition;
  [[NSNotificationCenter defaultCenter] postNotificationName:playViewBoardPositionChanged object:self];
}

// -----------------------------------------------------------------------------
/// @brief Private helper method for setCurrentBoardPosition:()
// -----------------------------------------------------------------------------
- (void) updateGoObjectsToNewPosition:(int)newBoardPosition
{
  GoMoveModel* moveModel = [GoGame sharedGame].moveModel;
  int indexOfTargetMove = newBoardPosition - 1;
  int indexOfCurrentMove = currentBoardPosition - 1;
  if (newBoardPosition > currentBoardPosition)
  {
    for (int indexOfMove = indexOfCurrentMove + 1; indexOfMove <= indexOfTargetMove; ++indexOfMove)
    {
      GoMove* move = [moveModel moveAtIndex:indexOfMove];
      [move doIt];
    }
  }
  else
  {
    for (int indexOfMove = indexOfCurrentMove; indexOfMove > indexOfTargetMove; --indexOfMove)
    {
      GoMove* move = [moveModel moveAtIndex:indexOfMove];
      [move undo];
    }
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoMove*) currentMove
{
  if (0 == self.currentBoardPosition)
    return nil;
  int indexOfCurrentMove = self.currentBoardPosition - 1;
  return [[GoGame sharedGame].moveModel moveAtIndex:indexOfCurrentMove];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoPlayer*) currentPlayer
{
  return [GoUtilities playerAfter:self.currentMove inGame:[GoGame sharedGame]];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) isFirstPosition
{
  return (0 == self.currentBoardPosition);
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) isLastPosition
{
  int numberOfMoves = [GoGame sharedGame].moveModel.numberOfMoves;
  int indexOfLastMove = numberOfMoves - 1;
  int indexOfCurrentMove = self.currentBoardPosition - 1;
  return (indexOfCurrentMove == indexOfLastMove);
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) isComputerPlayersTurn
{
  return (! self.currentPlayer.player.isHuman);
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
///
/// This method responds by setting the current board position to 0 (zero) and
/// sending #playViewBoardPositionChanged.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  // Don't invoke property's setter since there is no need to update the state
  // of Go objects
  currentBoardPosition = 0;
  [[NSNotificationCenter defaultCenter] postNotificationName:playViewBoardPositionChanged object:self];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goMoveModelChanged notification.
///
/// @note The following details are rather deep implementation notes made to
/// understand the maybe not-so-obvious interaction between the Play view
/// classes, GoMoveModel and BoardPositionmodel. If any changes are made to this
/// method, the scenarios described must be taken into account.
///
/// This method responds in the following ways:
/// - If the current board position is larger than the number of moves in
///   GoMoveModel, the current board position is adjusted so that it refers to
///   the last move in GoMoveModel. This is purely a safety mechanism, it is not
///   expected that this scenario actually occurs.
/// - If the current board position refers to the previous-to-last move in
///   GoMoveModel, then the current board position is advanced to refer to the
///   last move in GoMoveModel. This covers the following "regular play"
///   scenario: The Play view displays the most recent board position, a new
///   move is made, the Play view should update itself to display the board
///   position after the new move.
/// - If the current board position refers to any other move in GoMoveModel,
///   nothing happens and #goMoveModelChanged is ignored. This covers the
///   scenario where a new move is made while viewing a board position in the
///   middle of the game. In this scenario, #goMoveModelChanged is sent for the
///   first time (and can be ignored) when all future moves after the current
///   board position are discarded. #goMoveModelChanged will be sent a second
///   time later on, when the new move is actually made. On this occasion
///   where the board position will be a
///
/// #playViewBoardPositionChanged is sent if the current board position is
/// changed in any way.
// -----------------------------------------------------------------------------
- (void) goMoveModelChanged:(NSNotification*)notification
{
  GoMoveModel* moveModel = [GoGame sharedGame].moveModel;
  int numberOfMoves = moveModel.numberOfMoves;

  if (currentBoardPosition > numberOfMoves)
  {
    // Unexpected scenario (see method docs)
    DDLogWarn(@"Current board position %d is greater than the number of moves %d", currentBoardPosition, numberOfMoves);
  }
  else if ((currentBoardPosition + 1) == numberOfMoves)
  {
    // Scenario "regular play" (see method docs)
  }
  else
  {
    // Scenario "move is made while viewing a board position in the middle of
    // the game" (see method docs)
    return;
  }

  // Don't invoke property's setter since there is no need to update the state
  // of Go objects
  currentBoardPosition = numberOfMoves;
  [[NSNotificationCenter defaultCenter] postNotificationName:playViewBoardPositionChanged object:self];
}

@end
