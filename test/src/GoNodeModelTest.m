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


// Test includes
#import "GoNodeModelTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoGameDocument.h>
#import <go/GoMove.h>
#import <go/GoNode.h>
#import <go/GoNodeAdditions.h>
#import <go/GoNodeModel.h>
#import <go/GoPoint.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeModelTest.
// -----------------------------------------------------------------------------
@interface GoNodeModelTest()
@property(nonatomic, assign) GoNode* nodeA;
@property(nonatomic, assign) GoNode* nodeB;
@property(nonatomic, assign) GoNode* nodeC;
@property(nonatomic, assign) GoNode* nodeD;
@property(nonatomic, assign) GoNode* nodeE;
@property(nonatomic, assign) GoNode* nodeF;
@property(nonatomic, assign) GoNode* nodeG;
@property(nonatomic, assign) GoNode* nodeH;
@property(nonatomic, assign) GoNode* nodeI;
@property(nonatomic, assign) GoNode* nodeJ;
@end


@implementation GoNodeModelTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoNodeModel object after a new
/// GoGame has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  XCTAssertNotNil(nodeModel);
  XCTAssertNotNil(nodeModel.rootNode);
  XCTAssertNotNil(nodeModel.leafNode);
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the createVariationWithNode:nextSibling:parent:() method.
// -----------------------------------------------------------------------------
- (void) testCreateVariationWithNodeNextSiblingParent
{
  GoNodeModel* testee = m_game.nodeModel;
  GoNode* rootNode = testee.rootNode;

  GoNode* node;

  // nextSibling is nil, lastChild of parent is nil
  node = [GoNode node];
  XCTAssertNil(rootNode.lastChild);
  [testee createVariationWithNode:node nextSibling:nil parent:rootNode];
  XCTAssertEqualObjects(rootNode.lastChild, node);
  XCTAssertEqualObjects(node.parent, rootNode);
  XCTAssertNil(node.nextSibling);

  // nextSibling is nil, lastChild of parent is not nil
  [self setupGameTree:rootNode];
  node = [GoNode node];
  XCTAssertNotNil(rootNode.lastChild);
  XCTAssertNotEqualObjects(rootNode.lastChild, node);
  [testee createVariationWithNode:node nextSibling:nil parent:rootNode];
  XCTAssertEqualObjects(rootNode.lastChild, node);
  XCTAssertEqualObjects(node.parent, rootNode);
  XCTAssertNil(node.nextSibling);

  // nextSibling is not nil, insert before firstChild of parent
  [self setupGameTree:rootNode];
  node = [GoNode node];
  GoNode* originalFirstChild = rootNode.firstChild;
  XCTAssertNotNil(originalFirstChild);
  XCTAssertNotEqualObjects(originalFirstChild, node);
  [testee createVariationWithNode:node nextSibling:originalFirstChild parent:rootNode];
  XCTAssertEqualObjects(rootNode.firstChild, node);
  XCTAssertEqualObjects(node.parent, rootNode);
  XCTAssertEqualObjects(node.nextSibling, originalFirstChild);

  // nextSibling is not nil, insert after firstChild of parent
  [self setupGameTree:rootNode];
  node = [GoNode node];
  GoNode* originalNextSiblingOfFirstChild = rootNode.firstChild.nextSibling;
  XCTAssertNotNil(originalNextSiblingOfFirstChild);
  XCTAssertNotEqualObjects(originalNextSiblingOfFirstChild, node);
  [testee createVariationWithNode:node nextSibling:originalNextSiblingOfFirstChild parent:rootNode];
  XCTAssertNotEqualObjects(rootNode.firstChild, node);
  XCTAssertEqualObjects(rootNode.firstChild.nextSibling, node);
  XCTAssertEqualObjects(node.parent, rootNode);
  XCTAssertEqualObjects(node.nextSibling, originalNextSiblingOfFirstChild);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the changeToMainVariation() method.
// -----------------------------------------------------------------------------
- (void) testChangeToMainVariation
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoNode* rootNode = nodeModel.rootNode;

  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);
  XCTAssertEqual(rootNode, nodeModel.leafNode);

  // Changing to variation works when node tree consists of only the root node
  [nodeModel changeToMainVariation];
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);
  XCTAssertEqual(rootNode, nodeModel.leafNode);

  [self setupGameTree:rootNode];

  [nodeModel changeToMainVariation];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);

  // Changing the linkage of nodes in the game tree does not automatically
  // update GoNodeModel
  [rootNode.firstChild setFirstChild:nil];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);

  // changeToMainVariation updates GoNodeModel according to the current game
  // tree linkage
  [nodeModel changeToMainVariation];
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the changeToVariationContainingNode:() method.
// -----------------------------------------------------------------------------
- (void) testChangeToVariationContainingNode
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoNode* rootNode = nodeModel.rootNode;

  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);
  XCTAssertEqual(rootNode, nodeModel.leafNode);

  // Changing to variation works when node tree consists of only the root node
  [nodeModel changeToVariationContainingNode:rootNode];
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);
  XCTAssertEqual(rootNode, nodeModel.leafNode);

  [self setupGameTree:rootNode];

  [nodeModel changeToVariationContainingNode:rootNode];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);

  // Changing the linkage of nodes in the game tree does not automatically
  // update GoNodeModel
  [rootNode.firstChild setFirstChild:nil];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);

  // changeToVariationContainingNode: updates GoNodeModel according to the
  // current game tree linkage
  [nodeModel changeToVariationContainingNode:rootNode];
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);

  [nodeModel changeToVariationContainingNode:rootNode.lastChild];
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);

  [nodeModel changeToVariationContainingNode:rootNode.firstChild];
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);

  XCTAssertThrowsSpecificNamed([nodeModel changeToVariationContainingNode:nil],
                               NSException, NSInvalidArgumentException, @"changeToVariationContainingNode with nil object");
  GoNode* nodeNotInGameTree = [GoNode node];
  XCTAssertThrowsSpecificNamed([nodeModel changeToVariationContainingNode:nodeNotInGameTree],
                               NSException, NSInvalidArgumentException, @"changeToVariationContainingNode with node that is not in the game tree");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the ancestorOfNodeInCurrentVariation:() method.
// -----------------------------------------------------------------------------
- (void) testAncestorOfNodeInCurrentVariation
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoNode* rootNode = nodeModel.rootNode;

  [self setupGameTree:rootNode];
  [nodeModel changeToVariationContainingNode:rootNode];
  GoNode* leafNode = nodeModel.leafNode;

  GoNode* ancestor;

  // Test if node is already in the current variation
  ancestor = [nodeModel ancestorOfNodeInCurrentVariation:rootNode];
  XCTAssertEqual(rootNode, ancestor);
  ancestor = [nodeModel ancestorOfNodeInCurrentVariation:leafNode];
  XCTAssertEqual(leafNode, ancestor);

  // Test if node is not in current variation, and the variation is branching
  // off from the root node
  // => result must always be the root node
  ancestor = [nodeModel ancestorOfNodeInCurrentVariation:rootNode.lastChild];
  XCTAssertEqual(rootNode, ancestor);
  ancestor = [nodeModel ancestorOfNodeInCurrentVariation:rootNode.lastChild.firstChild];
  XCTAssertEqual(rootNode, ancestor);
  ancestor = [nodeModel ancestorOfNodeInCurrentVariation:rootNode.lastChild.lastChild];
  XCTAssertEqual(rootNode, ancestor);

  // Test if node is not in current variation, and the variation is branching
  // off from a node in the current variation that is not the root node
  // => result must be the branching node
  ancestor = [nodeModel ancestorOfNodeInCurrentVariation:rootNode.firstChild.lastChild];
  XCTAssertEqual(rootNode.firstChild, ancestor);

  XCTAssertThrowsSpecificNamed([nodeModel ancestorOfNodeInCurrentVariation:nil],
                               NSException, NSInvalidArgumentException, @"ancestorOfNodeInCurrentVariation with nil object");
  GoNode* nodeNotInGameTree = [GoNode node];
  XCTAssertThrowsSpecificNamed([nodeModel ancestorOfNodeInCurrentVariation:nodeNotInGameTree],
                               NSException, NSInvalidArgumentException, @"ancestorOfNodeInCurrentVariation with node that is not in the game tree");
}

// -----------------------------------------------------------------------------
/// @brief Private helper for testChangeToMainVariation(),
/// testChangeToVariationContainingNode(),
/// testAncestorOfNodeInCurrentVariation() and
/// testCreateVariationWithNodeNextSiblingParent().
// -----------------------------------------------------------------------------
- (void) setupGameTree:(GoNode*)rootNode
{
  // Schema of tree being built:
  // o--o--o--o
  // |  +--o
  // +--o--o
  //    +--o

  GoNode* mainVariationNode0 = rootNode;
  GoNode* mainVariationNode1 = [GoNode node];
  GoNode* mainVariationNode2 = [GoNode nodeWithMove:[GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil]];
  GoNode* mainVariationNode3 = [GoNode node];
  [mainVariationNode0 setFirstChild:mainVariationNode1];
  [mainVariationNode1 setFirstChild:mainVariationNode2];
  [mainVariationNode2 setFirstChild:mainVariationNode3];

  GoNode* secondaryVariationNode0 = rootNode;
  GoNode* secondaryVariationNode1 = [GoNode node];
  GoNode* secondaryVariationNode2 = [GoNode nodeWithMove:[GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil]];;
  [secondaryVariationNode0 appendChild:secondaryVariationNode1];
  [secondaryVariationNode1 setFirstChild:secondaryVariationNode2];

  GoNode* variation3Node2 = [GoNode node];
  [mainVariationNode1 appendChild:variation3Node2];
  GoNode* variation4Node2 = [GoNode node];
  [secondaryVariationNode1 appendChild:variation4Node2];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the nodeAtIndex:() method.
// -----------------------------------------------------------------------------
- (void) testNodeAtIndex
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoNode* rootNode = nodeModel.rootNode;

  GoNode* node1 = [GoNode node];
  GoNode* node2 = [GoNode node];
  GoNode* node3 = [GoNode node];
  [nodeModel appendNode:node1];
  [nodeModel appendNode:node2];
  [nodeModel appendNode:node3];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(rootNode, [nodeModel nodeAtIndex:0]);
  XCTAssertEqual(node1, [nodeModel nodeAtIndex:1]);
  XCTAssertEqual(node2, [nodeModel nodeAtIndex:2]);
  XCTAssertEqual(node3, [nodeModel nodeAtIndex:3]);

  XCTAssertThrowsSpecificNamed([nodeModel nodeAtIndex:4],
                              NSException, NSRangeException, @"nodeAtIndex with index too high");
  XCTAssertThrowsSpecificNamed([nodeModel nodeAtIndex:-1],
                              NSException, NSRangeException, @"nodeAtIndex with negative index");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the indexOfNode:() method.
// -----------------------------------------------------------------------------
- (void) testIndexOfNode
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoNode* rootNode = nodeModel.rootNode;

  GoNode* node1 = [GoNode node];
  GoNode* node2 = [GoNode node];
  GoNode* node3 = [GoNode node];
  [nodeModel appendNode:node1];
  [nodeModel appendNode:node2];
  [nodeModel appendNode:node3];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(0, [nodeModel indexOfNode:rootNode]);
  XCTAssertEqual(1, [nodeModel indexOfNode:node1]);
  XCTAssertEqual(2, [nodeModel indexOfNode:node2]);
  XCTAssertEqual(3, [nodeModel indexOfNode:node3]);

  GoNode* nodeNotInVariation = [GoNode node];
  XCTAssertEqual(-1, [nodeModel indexOfNode:nodeNotInVariation]);

  XCTAssertThrowsSpecificNamed([nodeModel indexOfNode:nil],
                               NSException, NSInvalidArgumentException, @"indexOfNode with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the appendNode:() method.
// -----------------------------------------------------------------------------
- (void) testAppendNode
{
  GoNodeModel* nodeModel = m_game.nodeModel;

  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  GoNode* rootNode = nodeModel.rootNode;
  XCTAssertNil(rootNode.firstChild);

  GoNode* node1 = [GoNode node];
  XCTAssertFalse(m_game.document.isDirty);
  [nodeModel appendNode:node1];
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertNotNil(rootNode.firstChild);
  XCTAssertEqual(rootNode.firstChild, node1);
  XCTAssertEqual(node1.parent, rootNode);
  XCTAssertNil(node1.firstChild);

  GoMove* move = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move.point = [m_game.board pointAtVertex:@"A1"];
  GoNode* node2 = [GoNode nodeWithMove:move];
  [nodeModel appendNode:node2];
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertNotNil(node1.firstChild);
  XCTAssertEqual(node1.firstChild, node2);
  XCTAssertEqual(node2.parent, node1);
  XCTAssertNil(node2.firstChild);

  XCTAssertThrowsSpecificNamed([nodeModel appendNode:nil],
                               NSException, NSInvalidArgumentException, @"appendNode with nil object");
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertThrowsSpecificNamed([nodeModel appendNode:node1],
                               NSException, NSInvalidArgumentException, @"appendNode with node that is already an ancestor of the last node");
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertThrowsSpecificNamed([nodeModel appendNode:rootNode],
                               NSException, NSInvalidArgumentException, @"appendNode with root node");
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertThrowsSpecificNamed([nodeModel appendNode:rootNode],
                               NSException, NSInvalidArgumentException, @"appendNode with leaf node");
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardNodesFromIndex:() method.
// -----------------------------------------------------------------------------
- (void) testDiscardNodesFromIndex
{
  GoNodeModel* nodeModel = m_game.nodeModel;

  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move1.point = [m_game.board pointAtVertex:@"A1"];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  GoMove* move3 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:move2];
  GoNode* node1 = [GoNode nodeWithMove:move1];
  GoNode* node2 = [GoNode nodeWithMove:move2];
  GoNode* node3 = [GoNode nodeWithMove:move3];
  [nodeModel appendNode:node1];
  [nodeModel appendNode:node2];
  [nodeModel appendNode:node3];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 3);
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.rootNode.firstChild, node1);
  XCTAssertEqual(node1.parent, nodeModel.rootNode);
  XCTAssertEqual(node1.firstChild, node2);
  XCTAssertEqual(node2.parent, node1);
  XCTAssertEqual(node2.firstChild, node3);
  XCTAssertEqual(node3.parent, node2);

  m_game.document.dirty = false;
  XCTAssertThrowsSpecificNamed([nodeModel discardNodesFromIndex:4],
                              NSException, NSRangeException, @"discardNodesFromIndex with index too high");
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertThrowsSpecificNamed([nodeModel discardNodesFromIndex:0],
                              NSException, NSRangeException, @"discardNodesFromIndex with root node index");
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertThrowsSpecificNamed([nodeModel discardNodesFromIndex:-1],
                              NSException, NSRangeException, @"discardNodesFromIndex with negative index");
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertFalse(m_game.document.isDirty);

  // Discard >1 nodes
  [nodeModel discardNodesFromIndex:2];
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertTrue(m_game.document.isDirty);
  // Linking is broken between new leaf node and the first node to be discarded
  XCTAssertNil(node1.firstChild);
  XCTAssertNil(node2.parent);
  // Linking remains intact within the series of nodes that is discarded
  XCTAssertEqual(node2.firstChild, node3);
  XCTAssertEqual(node3.parent, node2);

  // Discard single node
  [nodeModel discardNodesFromIndex:1];
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertNil(nodeModel.rootNode.firstChild);
  XCTAssertNil(node1.parent);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardLeafNode() method.
// -----------------------------------------------------------------------------
- (void) testDiscardLeafNode
{
  GoNodeModel* nodeModel = m_game.nodeModel;

  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move1.point = [m_game.board pointAtVertex:@"A1"];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  GoNode* node1 = [GoNode nodeWithMove:move1];
  GoNode* node2 = [GoNode nodeWithMove:move2];

  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  [nodeModel appendNode:node1];
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  [nodeModel appendNode:node2];
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertEqual(nodeModel.numberOfMoves, 2);
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.rootNode.firstChild, node1);
  XCTAssertEqual(node1.parent, nodeModel.rootNode);
  XCTAssertEqual(node1.firstChild, node2);
  XCTAssertEqual(node2.parent, node1);

  m_game.document.dirty = false;
  [nodeModel discardLeafNode];
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertNil(node1.firstChild);
  XCTAssertNil(node2.parent);
  [nodeModel discardLeafNode];
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertNil(nodeModel.rootNode.firstChild);
  XCTAssertNil(node1.parent);

  XCTAssertThrowsSpecificNamed([nodeModel discardLeafNode],
                               NSException, NSRangeException, @"discardLeafNode with only root node left");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardAllNodes() method.
// -----------------------------------------------------------------------------
- (void) testDiscardAllNodes
{
  GoNodeModel* nodeModel = m_game.nodeModel;

  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move1.point = [m_game.board pointAtVertex:@"A1"];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  GoMove* move3 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:move2];
  GoNode* node1 = [GoNode nodeWithMove:move1];
  GoNode* node2 = [GoNode nodeWithMove:move2];
  GoNode* node3 = [GoNode nodeWithMove:move3];
  [nodeModel appendNode:node1];
  [nodeModel appendNode:node2];
  [nodeModel appendNode:node3];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 3);
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.rootNode.firstChild, node1);
  XCTAssertEqual(node1.parent, nodeModel.rootNode);
  XCTAssertEqual(node1.firstChild, node2);
  XCTAssertEqual(node2.parent, node1);
  XCTAssertEqual(node2.firstChild, node3);
  XCTAssertEqual(node3.parent, node2);

  m_game.document.dirty = false;
  [nodeModel discardAllNodes];
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertNil(nodeModel.rootNode.firstChild);
  XCTAssertNil(node1.parent);
  XCTAssertEqual(node1.firstChild, node2);
  XCTAssertEqual(node2.parent, node1);
  XCTAssertEqual(node2.firstChild, node3);
  XCTAssertEqual(node3.parent, node2);

  XCTAssertThrowsSpecificNamed([nodeModel discardAllNodes],
                               NSException, NSRangeException, @"discardAllNodes with only root node left");
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up a tree of nodes on which test methods with
/// suffix "FirstDiscardedNodeHasNextSibling" or suffix
/// "FirstDiscardedNodeHasPreviousSibling" can operate.
///
/// This is a schematic of the node tree being set up. The labels illustrate
/// what happens if node B, which has a next sibling (node E), is being
/// discarded. Some tests are discarding node C and node A, respectively, to
/// prove that the correct same thing is happening when other discard methods
/// in GoNodeModel are used. Last but not least, there are also tests that
/// verify that the correct thing happens when a node has a previous sibling
/// but no next sibling - nodes D, H and I, respectively are discarded for
/// testing these cases.
/// @verbatim
///      +-- branching node
///      |    +-- first node to discard
///      |    |    +-- current leaf node
///      v    v    v
/// o----A----B----C        <-- current variation (1 move)
/// |    |    |
/// |    |    +----D----E   <-- other variation, not involved in node B discard (3 moves)
/// |    |    +-- next sibling of first node to discard => replaces node to discard
/// |    |    v
/// |    +----F----G----H   <-- variation becomes the new current variation (2 moves)
/// |    |              ^
/// |    |              +-- new leaf node
/// |    +----I             <-- variation does not become the new current variation (1 move)
/// +----J                  <-- other variation, not involved in node B discard (0 moves)
/// @verbatim
// -----------------------------------------------------------------------------
- (void) setupNodeTree_FirstDiscardedNodeHasNextOrPreviousSibling
{
  self.nodeA = [GoNode node];
  self.nodeB = [GoNode nodeWithMove:[GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil]];;
  self.nodeC = [GoNode node];
  self.nodeD = [GoNode nodeWithMove:[GoMove move:GoMoveTypePass by:m_game.playerBlack after:self.nodeB.goMove]];;
  self.nodeE = [GoNode nodeWithMove:[GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil]];;
  self.nodeF = [GoNode nodeWithMove:[GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil]];;
  self.nodeG = [GoNode nodeWithMove:[GoMove move:GoMoveTypePass by:m_game.playerBlack after:self.nodeE.goMove]];;
  self.nodeH = [GoNode node];
  self.nodeI = [GoNode nodeWithMove:[GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil]];;
  self.nodeJ = [GoNode node];

  GoNodeModel* nodeModel = m_game.nodeModel;
  [nodeModel.rootNode setFirstChild:self.nodeA];
  [self.nodeA setFirstChild:self.nodeB];
  [self.nodeB setFirstChild:self.nodeC];
  [self.nodeB appendChild:self.nodeD];
  [self.nodeA appendChild:self.nodeF];
  [self.nodeD setFirstChild:self.nodeE];
  [self.nodeF setFirstChild:self.nodeG];
  [self.nodeG setFirstChild:self.nodeH];
  [self.nodeA appendChild:self.nodeI];
  [nodeModel.rootNode appendChild:self.nodeJ];

  [nodeModel changeToVariationContainingNode:nodeModel.rootNode];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardNodesFromIndex:() method when the first node to
/// discard has a next sibling.
/// -----------------------------------------------------------------------------
- (void) testDiscardNodesFromIndex_FirstDiscardedNodeHasNextSibling
{
  // Arrange
  [self setupNodeTree_FirstDiscardedNodeHasNextOrPreviousSibling];
  GoNodeModel* nodeModel = m_game.nodeModel;
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeC);
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqualObjects(self.nodeA.lastChild, self.nodeI);
  XCTAssertEqualObjects(self.nodeF.nextSibling, self.nodeI);

  // Act
  int indexOfNodeToDiscard = [nodeModel indexOfNode:self.nodeB];
  [nodeModel discardNodesFromIndex:indexOfNodeToDiscard];

  // Assert
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeH);
  XCTAssertEqual(nodeModel.numberOfNodes, 5);
  XCTAssertEqual(nodeModel.numberOfMoves, 2);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeF], 2);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeG], 3);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeH], 4);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeI], -1);
  XCTAssertEqualObjects(self.nodeA.firstChild, self.nodeF);
  XCTAssertEqualObjects(self.nodeA.lastChild, self.nodeI);
  XCTAssertEqualObjects(self.nodeF.nextSibling, self.nodeI);
  XCTAssertNil(self.nodeB.parent);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the testDiscardLeafNode:() method when the leaf node to
/// discard has a next sibling.
/// -----------------------------------------------------------------------------
- (void) testDiscardLeafNode_FirstDiscardedNodeHasNextSibling
{
  // Arrange
  [self setupNodeTree_FirstDiscardedNodeHasNextOrPreviousSibling];
  GoNodeModel* nodeModel = m_game.nodeModel;
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeC);
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqualObjects(nodeModel.rootNode.lastChild, self.nodeJ);
  XCTAssertEqualObjects(self.nodeA.nextSibling, self.nodeJ);

  // Act
  [nodeModel discardLeafNode];

  // Assert
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeE);
  XCTAssertEqual(nodeModel.numberOfNodes, 5);
  XCTAssertEqual(nodeModel.numberOfMoves, 3);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeD], 3);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeE], 4);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeC], -1);
  XCTAssertEqualObjects(self.nodeB.firstChild, self.nodeD);
  XCTAssertEqualObjects(self.nodeB.lastChild, self.nodeD);
  XCTAssertNil(self.nodeC.parent);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the testDiscardAllNodes:() method when the direct child
/// of the root node, which is to be discarded, has a next sibling.
/// -----------------------------------------------------------------------------
- (void) testDiscardAllNodes_FirstDiscardedNodeHasNextSibling
{
  // Arrange
  [self setupNodeTree_FirstDiscardedNodeHasNextOrPreviousSibling];
  GoNodeModel* nodeModel = m_game.nodeModel;
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeC);
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqualObjects(self.nodeB.lastChild, self.nodeD);
  XCTAssertEqualObjects(self.nodeC.nextSibling, self.nodeD);

  // Act
  [nodeModel discardAllNodes];

  // Assert
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeJ);
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeJ], 1);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeA], -1);
  XCTAssertEqualObjects(nodeModel.rootNode.firstChild, self.nodeJ);
  XCTAssertEqualObjects(nodeModel.rootNode.lastChild, self.nodeJ);
  XCTAssertNil(self.nodeA.parent);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardNodesFromIndex:() method when the first node to
/// discard has a previous sibling.
/// -----------------------------------------------------------------------------
- (void) testDiscardNodesFromIndex_FirstDiscardedNodeHasPreviousSibling
{
  // Arrange
  [self setupNodeTree_FirstDiscardedNodeHasNextOrPreviousSibling];
  GoNodeModel* nodeModel = m_game.nodeModel;
  [nodeModel changeToVariationContainingNode:self.nodeE];
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeE);
  XCTAssertEqual(nodeModel.numberOfNodes, 5);
  XCTAssertEqual(nodeModel.numberOfMoves, 3);
  XCTAssertEqualObjects(self.nodeB.firstChild, self.nodeC);
  XCTAssertEqualObjects(self.nodeB.lastChild, self.nodeD);
  XCTAssertEqualObjects(self.nodeC.nextSibling, self.nodeD);

  // Act
  int indexOfNodeToDiscard = [nodeModel indexOfNode:self.nodeD];
  [nodeModel discardNodesFromIndex:indexOfNodeToDiscard];

  // Assert
  XCTAssertEqual(nodeModel.leafNode, self.nodeC);
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeC], 3);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeD], -1);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeE], -1);
  XCTAssertEqualObjects(self.nodeB.firstChild, self.nodeC);
  XCTAssertEqualObjects(self.nodeB.lastChild, self.nodeC);
  XCTAssertNil(self.nodeC.nextSibling);
  XCTAssertNil(self.nodeD.parent);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the testDiscardLeafNode:() method when the leaf node to
/// discard has a previous sibling.
/// -----------------------------------------------------------------------------
- (void) testDiscardLeafNode_FirstDiscardedNodeHasPreviousSibling
{
  // Arrange
  [self setupNodeTree_FirstDiscardedNodeHasNextOrPreviousSibling];
  GoNodeModel* nodeModel = m_game.nodeModel;
  [nodeModel changeToVariationContainingNode:self.nodeI];
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeI);
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqualObjects(self.nodeA.firstChild, self.nodeB);
  XCTAssertEqualObjects(self.nodeA.lastChild, self.nodeI);
  XCTAssertEqualObjects(self.nodeB.nextSibling, self.nodeF);
  XCTAssertEqualObjects(self.nodeF.nextSibling, self.nodeI);

  // Act
  [nodeModel discardLeafNode];

  // Assert
  XCTAssertEqual(nodeModel.leafNode, self.nodeH);
  XCTAssertEqual(nodeModel.numberOfNodes, 5);
  XCTAssertEqual(nodeModel.numberOfMoves, 2);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeF], 2);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeG], 3);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeH], 4);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeI], -1);
  XCTAssertEqualObjects(self.nodeA.firstChild, self.nodeB);
  XCTAssertEqualObjects(self.nodeA.lastChild, self.nodeF);
  XCTAssertEqualObjects(self.nodeB.nextSibling, self.nodeF);
  XCTAssertNil(self.nodeF.nextSibling);
  XCTAssertNil(self.nodeI.parent);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the testDiscardAllNodes:() method when the direct child
/// of the root node, which is to be discarded, has a previous sibling.
/// -----------------------------------------------------------------------------
- (void) testDiscardAllNodes_FirstDiscardedNodeHasPreviousSibling
{
  // Arrange
  [self setupNodeTree_FirstDiscardedNodeHasNextOrPreviousSibling];
  GoNodeModel* nodeModel = m_game.nodeModel;
  [nodeModel changeToVariationContainingNode:self.nodeJ];
  XCTAssertEqualObjects(nodeModel.leafNode, self.nodeJ);
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  XCTAssertEqualObjects(nodeModel.rootNode.firstChild, self.nodeA);
  XCTAssertEqualObjects(nodeModel.rootNode.lastChild, self.nodeJ);
  XCTAssertEqualObjects(self.nodeA.nextSibling, self.nodeJ);

  // Act
  [nodeModel discardAllNodes];

  // Assert
  XCTAssertEqual(nodeModel.leafNode, self.nodeC);
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeA], 1);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeB], 2);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeC], 3);
  XCTAssertEqual([nodeModel indexOfNode:self.nodeJ], -1);
  XCTAssertEqualObjects(nodeModel.rootNode.firstChild, self.nodeA);
  XCTAssertEqualObjects(nodeModel.rootNode.lastChild, self.nodeA);
  XCTAssertNil(self.nodeA.nextSibling);
  XCTAssertNil(self.nodeJ.parent);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e numberOfNodes property.
// -----------------------------------------------------------------------------
- (void) testNumberOfNodes
{
  GoNodeModel* nodeModel = m_game.nodeModel;

  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  GoNode* node1 = [GoNode node];
  [nodeModel appendNode:node1];
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  GoMove* move = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  GoNode* node2 = [GoNode nodeWithMove:move];
  [nodeModel appendNode:node2];
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  [nodeModel discardAllNodes];
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e numberOfMoves property.
// -----------------------------------------------------------------------------
- (void) testNumberOfMoves
{
  GoNodeModel* nodeModel = m_game.nodeModel;

  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  GoNode* node1 = [GoNode node];
  [nodeModel appendNode:node1];
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
  GoMove* move = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  GoNode* node2 = [GoNode nodeWithMove:move];
  [nodeModel appendNode:node2];
  XCTAssertEqual(nodeModel.numberOfMoves, 1);
  [nodeModel discardAllNodes];
  XCTAssertEqual(nodeModel.numberOfMoves, 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e rootNode property.
// -----------------------------------------------------------------------------
- (void) testRootNode
{
  GoNodeModel* nodeModel = m_game.nodeModel;

  XCTAssertNotNil(nodeModel.rootNode);
  GoNode* rootNode = nodeModel.rootNode;

  GoNode* node1 = [GoNode node];
  [nodeModel appendNode:node1];
  XCTAssertNotNil(nodeModel.rootNode);
  XCTAssertEqual(nodeModel.rootNode, rootNode);

  [nodeModel discardAllNodes];
  XCTAssertNotNil(nodeModel.rootNode);
  XCTAssertEqual(nodeModel.rootNode, rootNode);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e leafNode property.
// -----------------------------------------------------------------------------
- (void) testLeafNode
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoNode* rootNode = nodeModel.rootNode;

  XCTAssertNotNil(nodeModel.leafNode);
  XCTAssertEqual(nodeModel.leafNode, rootNode);

  GoNode* node1 = [GoNode node];
  [nodeModel appendNode:node1];
  XCTAssertEqual(nodeModel.leafNode, node1);

  GoNode* node2 = [GoNode node];
  [nodeModel appendNode:node2];
  XCTAssertEqual(nodeModel.leafNode, node2);

  [nodeModel discardAllNodes];
  XCTAssertNotNil(nodeModel.leafNode);
  XCTAssertEqual(nodeModel.leafNode, rootNode);
}

@end
