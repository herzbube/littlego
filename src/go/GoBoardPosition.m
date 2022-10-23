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
  _numberOfBoardPositions = self.game.nodeModel.numberOfNodes;
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
  [self.game.nodeModel removeObserver:self forKeyPath:@"numberOfNodes"];
  self.game = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupKVOObserving
{
  [self.game.nodeModel addObserver:self forKeyPath:@"numberOfNodes" options:0 context:NULL];
}

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
  int numberOfNodes = self.game.nodeModel.numberOfNodes;
  int indexOfLeafNode = numberOfNodes - 1;
  int indexOfCurrentNode = self.currentBoardPosition;
  return (indexOfCurrentNode == indexOfLeafNode);
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications from GoNodeModel. If the response
/// includes changes to numberOfBoardPositions and/or currentBoardPosition, the
/// appropriate KVO notifications are also generated.
///
/// @note The following details are rather deep implementation notes made to
/// understand the maybe not-so-obvious interaction between the board view
/// classes, GoNodeModel and GoBoardPosition. If any changes are made to this
/// method, the scenarios described must be taken into account.
///
/// This method responds in the following ways:
/// - If the current board position points to a node beyond the leaf node in
///   GoNodeModel, the current board position is adjusted so that it refers to
///   the leaf node in GoNodeModel. This is purely a safety mechanism, it is not
///   expected that this scenario actually occurs.
/// - If the current board position refers to the parent node of the leaf node
///   in GoNodeModel ("previous-to-last node"), then the current board position
///   is advanced to refer to the leaf node in GoNodeModel. This covers the
///   following "regular play" scenario: The Go board displays the most recent
///   board position, a new move is made, the Go board should update itself to
///   display the board position after the new move. All other scenarios where
///   a new node is created are also covered.
/// - If the current board position refers to any other node in GoNodeModel,
///   nothing happens and the KVO notification is ignored. This covers the
///   scenarios where 1) a new node is created while viewing a board position in
///   the middle of the game; and 2) all nodes after the current board position
///   are discarded.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  // !!! IMPORTANT !!!
  // This method must NOT query the GoNodeModel property numberOfMoves! See
  // documentation of property numberOfNodes.
  // !!! IMPORTANT !!!

  GoNodeModel* nodeModel = object;
  int numberOfNodes = nodeModel.numberOfNodes;

  // Trigger KVO notification for numberOfBoardPositions before notification
  // for currentBoardPosition. This order is defined in the class docs; it is
  // important for observers that observe both properties.
  self.numberOfBoardPositions = numberOfNodes;

  int indexOfLeafNode = numberOfNodes - 1;
  int indexOfCurrentNode = self.currentBoardPosition;

  if (indexOfCurrentNode > indexOfLeafNode)
  {
    // Unexpected scenario (see method docs)
    DDLogWarn(@"Current board position %d is greater than the number of nodes %d", self.currentBoardPosition, numberOfNodes);
  }
  else if ((indexOfCurrentNode + 1) == indexOfLeafNode)
  {
    // Scenario "regular play" (see method docs)
  }
  else
  {
    // Scenario "a new node is created while viewing a board position in the
    // middle of the game" (see method docs)
    return;
  }

  int newBoardPosition = indexOfLeafNode;

  // Don't invoke property's setter since there is no need to update the state
  // of Go objects. The drawback is that we have to perform some additional
  // bookkeeping and generate KVO notifications ourselves.
  [self willChangeValueForKey:@"currentBoardPosition"];
  _currentBoardPosition = newBoardPosition;
  if (self.game.alternatingPlay)
  {
    GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:self.currentNode];
    GoMove* mostRecentMove = nodeWithMostRecentMove ? nodeWithMostRecentMove.goMove : nil;
    self.game.nextMoveColor = [GoUtilities playerAfter:mostRecentMove inGame:self.game].color;
  }
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
