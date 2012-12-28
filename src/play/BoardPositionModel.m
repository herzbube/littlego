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
- (void) updateBoardToNewPosition:(int)newBoardPosition;
//@}
@end


@implementation BoardPositionModel

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

  [self updateBoardToNewPosition:newBoardPosition];

  currentBoardPosition = newBoardPosition;
  [[NSNotificationCenter defaultCenter] postNotificationName:playViewBoardPositionChanged object:self];
}

// -----------------------------------------------------------------------------
/// @brief Private helper method for setCurrentBoardPosition:()
// -----------------------------------------------------------------------------
- (void) updateBoardToNewPosition:(int)newBoardPosition
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
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  currentBoardPosition = 0;
  [[NSNotificationCenter defaultCenter] postNotificationName:playViewBoardPositionChanged object:self];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goMoveModelChanged notification.
// -----------------------------------------------------------------------------
- (void) goMoveModelChanged:(NSNotification*)notification
{
  GoMoveModel* moveModel = [GoGame sharedGame].moveModel;
  int numberOfMoves = moveModel.numberOfMoves;
  currentBoardPosition = numberOfMoves;
  [[NSNotificationCenter defaultCenter] postNotificationName:playViewBoardPositionChanged object:self];
}

@end
