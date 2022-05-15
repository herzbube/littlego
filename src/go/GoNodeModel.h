// -----------------------------------------------------------------------------
// Copyright 2012-2022 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoGame;
@class GoNode;


// -----------------------------------------------------------------------------
/// @brief The GoNodeModel class provides data related to the nodes of the
/// current game tree to its clients.
///
/// All indexes in GoNodeModel are zero-based.
///
/// Invoking GoNodeModel methods that add or discard moves generally sets the
/// GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
@interface GoNodeModel : NSObject <NSCoding>
{
}

- (id) initWithGame:(GoGame*)game;

- (GoNode*) nodeAtIndex:(int)index;
- (int) indexOfNode:(GoNode*)node;
- (void) appendNode:(GoNode*)node;
- (void) discardNodesFromIndex:(int)index;
- (void) discardLeafNode;
- (void) discardAllNodes;
- (void) nodeAnnotationDataDidChange:(GoNode*)node;

/// @brief The game tree's root node. This always returns a non-nil value, i.e.
/// when a new game is created it already has a root node.
@property(nonatomic, retain, readonly) GoNode* rootNode;

/// @brief The leaf node of the current variation, i.e. the node at the tip of
/// the game tree branch that is represented by the current variation. This
/// always returns a non-nil value because there always is at least a root node.
@property(nonatomic, assign, readonly) GoNode* leafNode;

/// @brief Returns the number of nodes in the current variation. Always returns
/// at least 1 because there always is at least a root node.
@property(nonatomic, assign, readonly) int numberOfNodes;

/// @brief Returns the number of moves in the current variation. Returns 0 if
/// there are no moves.
@property(nonatomic, assign, readonly) int numberOfMoves;

@end
