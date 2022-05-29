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
#import <go/GoNodeModel.h>
#import <go/GoPoint.h>


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

  XCTAssertThrowsSpecificNamed([nodeModel indexOfNode:nil],
                               NSException, NSInvalidArgumentException, @"indexOfNode with nil object");
  GoNode* nodeNotInVariation = [GoNode node];
  XCTAssertThrowsSpecificNamed([nodeModel indexOfNode:nodeNotInVariation],
                               NSException, NSInvalidArgumentException, @"indexOfNode with node not in current variation");
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
