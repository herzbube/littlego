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
#import "ChangeNodeSelectionAsyncCommand.h"
#import "ChangeGameVariationCommand.h"
#import "../boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoNodeModel.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ChangeNodeSelectionAsyncCommand.
// -----------------------------------------------------------------------------
@interface ChangeNodeSelectionAsyncCommand()
@property(nonatomic, retain) GoNode* node;
@end


@implementation ChangeNodeSelectionAsyncCommand

@synthesize asynchronousCommandDelegate;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeNodeSelectionAsyncCommand object that will change
/// the selected node to @a node.
///
/// @note This is the designated initializer of ChangeNodeSelectionAsyncCommand.
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
/// @brief Deallocates memory allocated by this ChangeNodeSelectionAsyncCommand
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
  GoGame* game = [GoGame sharedGame];
  GoNodeModel* nodeModel = game.nodeModel;
  GoBoardPosition* boardPosition = game.boardPosition;

  // Nothing to do if the current board position already matches the node to
  // select
  GoNode* currentBoardPositionNode = boardPosition.currentNode;
  if (currentBoardPositionNode == self.node)
    return true;

  // A simple board position change is sufficient if the current game variation
  // already contains the node. Note that ChangeBoardPositionCommand may
  // execute asynchronously.
  int indexOfNode = [nodeModel indexOfNode:self.node];
  if (indexOfNode >= 0)
  {
    int newBoardPosition = indexOfNode;
    return [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
  }

  @try
  {
    [[LongRunningActionCounter sharedCounter] increment];

    bool success = [self changeBoardPositionToBranchingNode:nodeModel];
    if (! success)
      return false;

    success = [self changeGameVariation];
    if (! success)
      return false;

    success = [self changeBoardPositionToNodeToSelect:nodeModel];
    if (! success)
      return false;
  }
  @finally
  {
    // Application state will be saved later
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[LongRunningActionCounter sharedCounter] decrement];
  }

  return true;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Changes the current board position in the current game variation to
/// the nearest ancestor of the node to select that is also in the current game
/// variation. The ancestor node is the branching node after which the current
/// and new game variations differ.
// -----------------------------------------------------------------------------
- (bool) changeBoardPositionToBranchingNode:(GoNodeModel*)nodeModel
{
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                            didProgress:0.0
                                        nextStepMessage:@"Changing board position..."];

  GoNode* ancestorOfNodeInCurrentVariation = [nodeModel ancestorOfNodeInCurrentVariation:self.node];
  int indexOfAncestorOfNodeInCurrentVariation = [nodeModel indexOfNode:ancestorOfNodeInCurrentVariation];

  int newBoardPosition = indexOfAncestorOfNodeInCurrentVariation;
  bool success = [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
  if (! success)
    DDLogError(@"%@: Aborting because changing board position to branching node failed", [self shortDescription]);

  return success;
}

// -----------------------------------------------------------------------------
/// @brief Changes the current game variation to the one that contains the
/// node to select and its @e firstChild descendants.
// -----------------------------------------------------------------------------
- (bool) changeGameVariation
{
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                            didProgress:0.3
                                        nextStepMessage:@"Changing game variation..."];

  bool success = [[[[ChangeGameVariationCommand alloc] initWithNode:self.node] autorelease] submit];
  if (! success)
    DDLogError(@"%@: Aborting because changing the game variation failed", [self shortDescription]);

  return success;
}

// -----------------------------------------------------------------------------
/// @brief Changes the current board position in the new game variation to
/// the node to select.
// -----------------------------------------------------------------------------
- (bool) changeBoardPositionToNodeToSelect:(GoNodeModel*)nodeModel
{
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                            didProgress:0.6
                                        nextStepMessage:@"Changing board position..."];

  int indexOfNode = [nodeModel indexOfNode:self.node];
  int newBoardPosition = indexOfNode;
  bool success = [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
  if (! success)
    DDLogError(@"%@: Aborting because changing board position to node to select failed", [self shortDescription]);

  return success;
}

@end
