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
#import "GoBoardPosition.h"
#import "../go/GoGame.h"
#import "../go/GoNode.h"
#import "../go/GoNodeModel.h"
#import "../go/GoPlayer.h"
#import "../go/GoUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoBoardPosition.
// -----------------------------------------------------------------------------
@interface GoBoardPosition()
@property(nonatomic, assign) GoGame* game;
@end


@implementation GoBoardPosition

#pragma mark - Initialization and deallocation

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
  _numberOfBoardPositions = self.game.nodeModel.numberOfNodes;

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

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoBoardPosition object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;

  [super dealloc];
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

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Changes the value of property @e currentBoardPosition so that it
/// refers to the last board position, without also changing the state of
/// GoPoint and GoBoardRegion objects. The value of property
/// @e numberOfBoardPositions is used to determine the last board position.
///
/// This method is intended to be invoked exceptionally only, as part of the
/// configuration process after a new game was loaded from an SGF file.
// -----------------------------------------------------------------------------
- (void) changeToLastBoardPositionWithoutUpdatingGoObjects
{
  int lastBoardPosition = self.numberOfBoardPositions - 1;
  if (self.currentBoardPosition == lastBoardPosition)
    return;

  // Don't invoke property's setter since there is no need to update the state
  // of Go objects. The drawback is that we have to perform some additional
  // bookkeeping and generate KVO notifications ourselves.
  [self willChangeValueForKey:@"currentBoardPosition"];
  _currentBoardPosition = lastBoardPosition;
  [self didChangeValueForKey:@"currentBoardPosition"];
}

#pragma mark - Properties

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setCurrentBoardPosition:(int)newBoardPosition
{
  if (newBoardPosition == _currentBoardPosition)
    return;

  int indexOfTargetNode = newBoardPosition;
  GoNodeModel* nodeModel = self.game.nodeModel;
  int numberOfNodes = nodeModel.numberOfNodes;
  int indexOfLeafNode = numberOfNodes - 1;
  if (newBoardPosition < 0 || indexOfTargetNode > indexOfLeafNode)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Illegal board position %d is either <0 or exceeds index of leaf node (%d) in current variation", newBoardPosition, indexOfLeafNode];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [self updateGoObjectsToNewPosition:newBoardPosition];
  _currentBoardPosition = newBoardPosition;
  if (self.game.alternatingPlay)
  {
    GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:self.currentNode];
    GoMove* mostRecentMove = nodeWithMostRecentMove ? nodeWithMostRecentMove.goMove : nil;
    // Requires setupFirstMoveColor to be set correctly, i.e.
    // updateGoObjectsToNewPosition must have been invoked
    self.game.nextMoveColor = [GoUtilities playerAfter:mostRecentMove inGame:self.game].color;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper method for setCurrentBoardPosition:()
// -----------------------------------------------------------------------------
- (void) updateGoObjectsToNewPosition:(int)newBoardPosition
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  GoNodeModel* nodeModel = self.game.nodeModel;
  int indexOfTargetNode = newBoardPosition;
  int indexOfCurrentNode = self.currentBoardPosition;
  if (newBoardPosition > self.currentBoardPosition)
  {
    for (int indexOfNode = indexOfCurrentNode + 1; indexOfNode <= indexOfTargetNode; ++indexOfNode)
    {
      GoNode* node = [nodeModel nodeAtIndex:indexOfNode];
      [node modifyBoard];
      [center postNotificationName:boardPositionChangeProgress object:nil];
    }
  }
  else
  {
    for (int indexOfNode = indexOfCurrentNode; indexOfNode > indexOfTargetNode; --indexOfNode)
    {
      GoNode* node = [nodeModel nodeAtIndex:indexOfNode];
      [node revertBoard];
      [center postNotificationName:boardPositionChangeProgress object:nil];
    }
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoNode*) currentNode
{
  int indexOfCurrentNode = self.currentBoardPosition;
  return [self.game.nodeModel nodeAtIndex:indexOfCurrentNode];
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
  return ((self.currentBoardPosition + 1) == self.numberOfBoardPositions);
}

@end
