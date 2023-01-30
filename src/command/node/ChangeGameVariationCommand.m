// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "ChangeGameVariationCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoNodeModel.h"
#import "../../shared/ApplicationStateManager.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ChangeGameVariationCommand.
// -----------------------------------------------------------------------------
@interface ChangeGameVariationCommand()
@property(nonatomic, retain) GoNode* node;
@end


@implementation ChangeGameVariationCommand

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeGameVariationCommand object that will change the
/// current game variation in GoNodeModel to @a node, all of @a node's ancestors
/// up to the root node of the game tree, and all of @a node's @e firstChild
/// descendants.
///
/// @note This is the designated initializer of ChangeGameVariationCommand.
// -----------------------------------------------------------------------------
- (id) initWithNode:(GoNode*)node
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  if (! node)
  {
    NSString* errorMessage = @"initWithNode: failed: node is nil object";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  self.node = node;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ChangeGameVariationCommand
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.node = nil;

  [super dealloc];
}

#pragma mark - CommandBase methods

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  GoGame* game = [GoGame sharedGame];
  GoNodeModel* nodeModel = game.nodeModel;
  GoBoardPosition* boardPosition = game.boardPosition;

  // Nothing to do if the current game variation already contains the node
  int indexOfNode = [nodeModel indexOfNode:self.node];
  if (indexOfNode >= 0)
    return true;

  GoNode* currentBoardPositionNode = boardPosition.currentNode;
  int indexOfCurrentBoardPositionNodeInOldGameVariation = [nodeModel indexOfNode:currentBoardPositionNode];
  if (indexOfCurrentBoardPositionNodeInOldGameVariation == -1)
  {
    NSString* errorMessage = @"Current board position node is not in the current game variation";
    DDLogError(@"%@: %@", self, errorMessage);
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:errorMessage
                                 userInfo:nil];
  }

  @try
  {
    [center postNotificationName:currentGameVariationWillChange object:nil];

    if (game.state == GoGameStateGameHasEnded)
      [game revertStateFromEndedToInProgress];

    [nodeModel changeToVariationContainingNode:self.node];

    int indexOfCurrentBoardPositionNodeInNewGameVariation = [nodeModel indexOfNode:currentBoardPositionNode];
    if (indexOfCurrentBoardPositionNodeInNewGameVariation == -1)
    {
      NSString* errorMessage = @"Current board position node is not in the new game variation";
      DDLogError(@"%@: %@", self, errorMessage);
      @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:errorMessage
                                   userInfo:nil];
    }

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

    [game endGameDueToPassMovesIfGameRulesRequireIt];

    [center postNotificationName:currentGameVariationDidChange object:nil];
  }
  @finally
  {
    // Application state will be saved later
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
  }

  return true;
}

@end
