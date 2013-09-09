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
#import "GoBoardPosition.h"
#import "../go/GoGame.h"
#import "../go/GoMove.h"
#import "../go/GoMoveModel.h"
#import "../go/GoPlayer.h"
#import "../go/GoUtilities.h"
#import "../player/Player.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoBoardPosition.
// -----------------------------------------------------------------------------
@interface GoBoardPosition()
/// @name Private properties
//@{
@property(nonatomic, assign) GoGame* game;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) int numberOfBoardPositions;
//@}
@end


@implementation GoBoardPosition

// -----------------------------------------------------------------------------
/// @brief Initializes a GoBoardPosition object that is associated with @a aGame
/// and whose current board position is 0 (zero).
///
/// @note This is the designated initializer of GoBoardPosition.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)aGame
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.game = aGame;
  _currentBoardPosition = 0;  // don't use self to avoid the setter
  _numberOfBoardPositions = self.game.moveModel.numberOfMoves + 1;
  [self setupKVOObserving];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;
  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;
  self.game = [decoder decodeObjectForKey:goBoardPositionGameKey];
  // Don't use self, otherwise we trigger the setter!
  _currentBoardPosition = [decoder decodeIntForKey:goBoardPositionCurrentBoardPositionKey];
  self.numberOfBoardPositions = [decoder decodeIntForKey:goBoardPositionNumberOfBoardPositionsKey];
  [self setupKVOObserving];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoBoardPosition object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self.game.moveModel removeObserver:self forKeyPath:@"numberOfMoves"];
  self.game = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupKVOObserving
{
  [self.game.moveModel addObserver:self forKeyPath:@"numberOfMoves" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setCurrentBoardPosition:(int)newBoardPosition
{
  if (newBoardPosition == _currentBoardPosition)
    return;

  int indexOfTargetMove = newBoardPosition - 1;
  GoMoveModel* moveModel = self.game.moveModel;
  int numberOfMoves = moveModel.numberOfMoves;
  int indexOfLastMove = numberOfMoves - 1;
  if (newBoardPosition < 0 || indexOfTargetMove > indexOfLastMove)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Illegal board position %d is either <0 or exceeds number of moves (%d) in current game", newBoardPosition, numberOfMoves];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [self updateGoObjectsToNewPosition:newBoardPosition];
  _currentBoardPosition = newBoardPosition;
}

// -----------------------------------------------------------------------------
/// @brief Private helper method for setCurrentBoardPosition:()
// -----------------------------------------------------------------------------
- (void) updateGoObjectsToNewPosition:(int)newBoardPosition
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  GoMoveModel* moveModel = self.game.moveModel;
  int indexOfTargetMove = newBoardPosition - 1;
  int indexOfCurrentMove = self.currentBoardPosition - 1;
  if (newBoardPosition > self.currentBoardPosition)
  {
    for (int indexOfMove = indexOfCurrentMove + 1; indexOfMove <= indexOfTargetMove; ++indexOfMove)
    {
      GoMove* move = [moveModel moveAtIndex:indexOfMove];
      [move doIt];
      [center postNotificationName:boardPositionChangeProgress object:nil];
    }
  }
  else
  {
    for (int indexOfMove = indexOfCurrentMove; indexOfMove > indexOfTargetMove; --indexOfMove)
    {
      GoMove* move = [moveModel moveAtIndex:indexOfMove];
      [move undo];
      [center postNotificationName:boardPositionChangeProgress object:nil];
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
  return [self.game.moveModel moveAtIndex:indexOfCurrentMove];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoPlayer*) currentPlayer
{
  return [GoUtilities playerAfter:self.currentMove inGame:self.game];
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
  int numberOfMoves = self.game.moveModel.numberOfMoves;
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
/// @brief Responds to KVO notifications from GoMoveModel. If the response
/// includes changes to numberOfBoardPositions and/or currentBoardPosition, the
/// appropriate KVO notifications are also generated.
///
/// @note The following details are rather deep implementation notes made to
/// understand the maybe not-so-obvious interaction between the Play view
/// classes, GoMoveModel and GoBoardPosition. If any changes are made to this
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
///   nothing happens and the KVO notification is ignored. This covers the
///   scenarios where 1) a new move is made while viewing a board position in
///   the middle of the game; and 2) all moves after the current board position
///   are discarded.
///
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  GoMoveModel* moveModel = object;
  int numberOfMoves = moveModel.numberOfMoves;

  // Trigger KVO notification for numberOfBoardPositions before notification
  // for currentBoardPosition. This order is defined in the class docs; it is
  // important for observers that observer both properties.
  self.numberOfBoardPositions = numberOfMoves + 1;

  if (self.currentBoardPosition > numberOfMoves)
  {
    // Unexpected scenario (see method docs)
    DDLogWarn(@"Current board position %d is greater than the number of moves %d", self.currentBoardPosition, numberOfMoves);
  }
  else if ((self.currentBoardPosition + 1) == numberOfMoves)
  {
    // Scenario "regular play" (see method docs)
  }
  else
  {
    // Scenario "a new move is made while viewing a board position in the
    // middle of the game" (see method docs)
    return;
  }

  // Don't invoke property's setter since there is no need to update the state
  // of Go objects. The drawback is that we have to generate KVO notifications
  // ourselves.
  [self willChangeValueForKey:@"currentBoardPosition"];
  _currentBoardPosition = numberOfMoves;
  [self didChangeValueForKey:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.game forKey:goBoardPositionGameKey];
  [encoder encodeInt:self.currentBoardPosition forKey:goBoardPositionCurrentBoardPositionKey];
  [encoder encodeInt:self.numberOfBoardPositions forKey:goBoardPositionNumberOfBoardPositionsKey];
}

@end
