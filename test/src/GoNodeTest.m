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


// Test includes
#import "GoNodeTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoMove.h>
#import <go/GoNode.h>
#import <go/GoNodeAdditions.h>
#import <go/GoNodeAnnotation.h>
#import <go/GoNodeMarkup.h>
#import <go/GoNodeModel.h>
#import <go/GoNodeSetup.h>
#import <go/GoPoint.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeTest.
// -----------------------------------------------------------------------------
@interface GoNodeTest()
// Properties are declared with assign, not retain, so nodes will be deallocated
// automatically and no tear-down/cleanup is necessary. Furthermore, properties
// are declared nonatomic so that getters do not use retain/autorelease. This
// is important so that proper memory management can also be tested.
@property(nonatomic, assign) GoNode* rootNode;
@property(nonatomic, assign) GoNode* nodeA;
@property(nonatomic, assign) GoNode* nodeB;
@property(nonatomic, assign) GoNode* nodeC;
@property(nonatomic, assign) GoNode* nodeA1;
@property(nonatomic, assign) GoNode* nodeA2;
@property(nonatomic, assign) GoNode* nodeA3;
@property(nonatomic, assign) GoNode* nodeA2a;
@property(nonatomic, assign) GoNode* nodeA2b;
@property(nonatomic, assign) GoNode* nodeA2c;
@property(nonatomic, assign) GoNode* freeNode1;
@property(nonatomic, assign) GoNode* freeNode2;
@end


@implementation GoNodeTest

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up a tree of nodes on which test methods can
/// operate.
///
/// @verbatim
/// rootNode
/// +-- nodeA
/// |   +-- nodeA1
/// |   +-- nodeA2
/// |   |   +-- nodeA2a
/// |   |   +-- nodeA2b
/// |   |   +-- nodeA2c
/// |   +-- nodeA3
/// +-- nodeB
/// +-- nodeC
/// @endverbatim
// -----------------------------------------------------------------------------
- (void) setupNodeTree
{
  // The root node is created outside the @autoreleasepool block so that it
  // survives and can be accessed by the invoking test method. All other nodes
  // are created within the @autoreleasepool block, so when the block ends they
  // are kept alive only via GoNode property references of properties declared
  // with "retain". The consequence: When an invoking test method is
  // manipulating the node tree it is also testing that the tree manipulation
  // methods implemented in GoNode are using memory management properly.
  self.rootNode = [GoNode node];

  // Nodes that are not added to the tree are not kept alive by the root node,
  // so to survive they also need to be created outside the @autoreleasepool
  // block.
  self.freeNode1 = [GoNode node];
  self.freeNode2 = [GoNode node];

  @autoreleasepool
  {
    self.nodeA = [GoNode node];
    self.nodeB = [GoNode node];
    self.nodeC = [GoNode node];
    self.nodeA1 = [GoNode node];
    self.nodeA2 = [GoNode node];
    self.nodeA3 = [GoNode node];
    self.nodeA2a = [GoNode node];
    self.nodeA2b = [GoNode node];
    self.nodeA2c = [GoNode node];

    [self.rootNode appendChild:self.nodeA];
    [self.rootNode appendChild:self.nodeB];
    [self.rootNode appendChild:self.nodeC];
    [self.nodeA appendChild:self.nodeA1];
    [self.nodeA appendChild:self.nodeA2];
    [self.nodeA appendChild:self.nodeA3];
    [self.nodeA2 appendChild:self.nodeA2a];
    [self.nodeA2 appendChild:self.nodeA2b];
    [self.nodeA2 appendChild:self.nodeA2c];
  }
}

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoNode object after a new
/// instance has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoNode* testee = [GoNode node];

  XCTAssertNil(testee.firstChild);
  XCTAssertNil(testee.lastChild);
  XCTAssertNotNil(testee.children);
  XCTAssertEqual(0, testee.children.count);
  XCTAssertFalse(testee.hasChildren);
  XCTAssertFalse(testee.isBranchingNode);
  XCTAssertNil(testee.nextSibling);
  XCTAssertFalse(testee.hasNextSibling);
  XCTAssertNil(testee.previousSibling);
  XCTAssertFalse(testee.hasPreviousSibling);
  XCTAssertNil(testee.parent);
  XCTAssertFalse(testee.hasParent);
  XCTAssertTrue(testee.isRoot);
  XCTAssertTrue(testee.isLeaf);
  XCTAssertTrue(testee.isEmpty);
  XCTAssertNil(testee.goNodeSetup);
  XCTAssertNil(testee.goMove);
  XCTAssertNil(testee.goNodeAnnotation);
  XCTAssertNil(testee.goNodeMarkup);
  XCTAssertEqual(0, testee.zobristHash);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testNode
{
  // TODO xxx implement
}

// -----------------------------------------------------------------------------
/// @brief Exercises the nodeWithMove:() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testNodeWithMove
{
  // TODO xxx implement
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setFirstChild:() method.
// -----------------------------------------------------------------------------
- (void) testSetFirstChild
{
  [self setupNodeTree];
  GoNode* testee = self.nodeA2a;

  // Set nil when firstChild is already nil
  XCTAssertEqual(testee.firstChild, nil);
  [testee setFirstChild:nil];
  XCTAssertEqual(testee.firstChild, nil);

  // Set nil when firstChild is not nil
  [testee setFirstChild:self.freeNode1];
  XCTAssertEqual(testee.firstChild, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);
  [testee setFirstChild:nil];
  XCTAssertEqual(testee.firstChild, nil);
  XCTAssertEqual(self.freeNode1.parent, nil);

  // Set non-nil when firstChild is nil
  [testee setFirstChild:self.freeNode1];
  XCTAssertEqual(testee.firstChild, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // Set same non-nil value
  [testee setFirstChild:self.freeNode1];
  XCTAssertEqual(testee.firstChild, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // Set different non-nil value
  [testee setFirstChild:self.freeNode2];
  XCTAssertEqual(testee.firstChild, self.freeNode2);
  XCTAssertEqual(self.freeNode2.parent, testee);

  // The new firstChild node is moved from its previous location in the tree
  XCTAssertEqual(self.nodeB.parent, self.rootNode);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.previousSibling, self.nodeA);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeB);
  [testee setFirstChild:self.nodeB];
  XCTAssertEqual(testee.firstChild, self.nodeB);
  XCTAssertEqual(self.nodeB.parent, testee);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeB.previousSibling, nil);
  XCTAssertEqual(self.nodeB.nextSibling, nil);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeA);

  // Setting firstChild discards the parent's other children
  testee = self.nodeA2;
  XCTAssertEqual(self.freeNode2.parent, nil);
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);
  [testee setFirstChild:self.freeNode2];
  XCTAssertEqual(testee.firstChild, self.freeNode2);
  XCTAssertEqual(self.freeNode2.parent, testee);
  XCTAssertEqual(testee.children.count, 1);
  XCTAssertEqual(self.nodeA2a.nextSibling, nil);  // sibling linkage is broken!
  XCTAssertEqual(self.nodeA2b.nextSibling, nil);  // sibling linkage is broken!
  XCTAssertEqual(self.nodeA2a.parent, nil);
  XCTAssertEqual(self.nodeA2b.parent, nil);
  XCTAssertEqual(self.nodeA2c.parent, nil);

  // Moving also works if the new firstChild is already a child of the parent
  [self setupNodeTree];
  testee = self.nodeA2;
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);
  [testee setFirstChild:self.nodeA2c];
  XCTAssertEqual(testee.firstChild, self.nodeA2c);
  XCTAssertEqual(testee.children.count, 1);
  XCTAssertEqual(self.nodeA2a.nextSibling, nil);  // sibling linkage is broken!
  XCTAssertEqual(self.nodeA2b.nextSibling, nil);
  XCTAssertEqual(self.nodeA2a.parent, nil);
  XCTAssertEqual(self.nodeA2b.parent, nil);
  XCTAssertEqual(self.nodeA2c.parent, testee);

  // Replacing firstChild with the nextSibling of the current firstChild retains
  // only the nextSibling
  [self setupNodeTree];
  testee = self.nodeA2;
  testee.firstChild = self.nodeA2b;
  XCTAssertNil(self.nodeA2a.parent);
  XCTAssertNil(self.nodeA2a.nextSibling);
  XCTAssertEqualObjects(self.nodeA2b.parent, testee);
  XCTAssertNil(self.nodeA2b.nextSibling);
  XCTAssertNil(self.nodeA2c.parent);
  XCTAssertNil(self.nodeA2c.nextSibling);
  XCTAssertEqualObjects(testee.firstChild, self.nodeA2b);

  // Replacing firstChild with the lastChild retains only the lastChild
  [self setupNodeTree];
  testee = self.nodeA2;
  testee.firstChild = self.nodeA2c;
  XCTAssertNil(self.nodeA2a.parent);
  XCTAssertNil(self.nodeA2a.nextSibling);
  XCTAssertNil(self.nodeA2b.parent);
  XCTAssertNil(self.nodeA2b.nextSibling);
  XCTAssertEqualObjects(self.nodeA2c.parent, testee);
  XCTAssertNil(self.nodeA2c.nextSibling);
  XCTAssertEqualObjects(testee.lastChild, self.nodeA2c);

  XCTAssertThrowsSpecificNamed([testee setFirstChild:testee],
                               NSException, NSInvalidArgumentException, @"setFirstChild: node cannot be its own first child");
  XCTAssertThrowsSpecificNamed([testee setFirstChild:self.rootNode],
                               NSException, NSInvalidArgumentException, @"setFirstChild: ancestor of node cannot be node's first child");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e children, @e hasChildren and @e isBranchingNode
/// properties.
// -----------------------------------------------------------------------------
- (void) testChildrenAndHasChildrenAndIsBranchingNode
{
  [self setupNodeTree];
  GoNode* testee = self.nodeA2a;

  NSArray* newChildren = @[];
  XCTAssertNotIdentical(testee.children, newChildren);
  XCTAssertEqualObjects(testee.children, newChildren);
  XCTAssertFalse(testee.hasChildren);
  XCTAssertFalse(testee.isBranchingNode);
  [testee setFirstChild:self.freeNode1];
  newChildren = @[self.freeNode1];
  XCTAssertNotIdentical(testee.children, newChildren);
  XCTAssertEqualObjects(testee.children, newChildren);
  XCTAssertTrue(testee.hasChildren);
  XCTAssertFalse(testee.isBranchingNode);
  [testee appendChild:self.freeNode2];
  newChildren = @[self.freeNode1, self.freeNode2];
  XCTAssertNotIdentical(testee.children, newChildren);
  XCTAssertEqualObjects(testee.children, newChildren);
  XCTAssertTrue(testee.hasChildren);
  XCTAssertTrue(testee.isBranchingNode);
  [testee setFirstChild:nil];
  newChildren = @[];
  XCTAssertNotIdentical(testee.children, newChildren);
  XCTAssertEqualObjects(testee.children, newChildren);
  XCTAssertFalse(testee.hasChildren);
  XCTAssertFalse(testee.isBranchingNode);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the appendChild:() method.
///
///
/// These are exactly the same tests as in
/// testInsertChildBeforeReferenceChildWhenReferenceChildIsNil().
// -----------------------------------------------------------------------------
- (void) testAppendChild
{
  [self setupNodeTree];
  GoNode* testee = self.nodeA2a;

  // Set non-nil when lastChild is nil
  XCTAssertEqual(testee.lastChild, nil);
  [testee appendChild:self.freeNode1];
  XCTAssertEqual(testee.lastChild, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // Set same non-nil value
  [testee appendChild:self.freeNode1];
  XCTAssertEqual(testee.lastChild, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // Set different non-nil value
  [testee appendChild:self.freeNode2];
  XCTAssertEqual(testee.lastChild, self.freeNode2);
  XCTAssertEqual(self.freeNode2.parent, testee);
  XCTAssertEqual(self.freeNode1.nextSibling, self.freeNode2);

  // The new lastChild node is moved from its previous location in the tree
  XCTAssertEqual(self.nodeB.parent, self.rootNode);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.previousSibling, self.nodeA);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeB);
  [testee appendChild:self.nodeB];
  XCTAssertEqual(testee.lastChild, self.nodeB);
  XCTAssertEqual(self.nodeB.parent, testee);
  XCTAssertEqual(self.freeNode2.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeB.previousSibling, self.freeNode2);
  XCTAssertEqual(self.nodeB.nextSibling, nil);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeA);

  // Moving also works if the new lastChild is already a child of the parent
  [self setupNodeTree];
  testee = self.nodeA2;
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(testee.lastChild, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);
  [testee appendChild:self.nodeA2a];
  XCTAssertEqual(testee.firstChild, self.nodeA2b);
  XCTAssertEqual(testee.lastChild, self.nodeA2a);
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(self.nodeA2a.nextSibling, nil);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2c.nextSibling, self.nodeA2a);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);

  XCTAssertThrowsSpecificNamed([testee appendChild:nil],
                               NSException, NSInvalidArgumentException, @"appendChild: node cannot be nil");
  XCTAssertThrowsSpecificNamed([testee appendChild:testee],
                               NSException, NSInvalidArgumentException, @"appendChild: node cannot be its own child");
  XCTAssertThrowsSpecificNamed([testee appendChild:self.rootNode],
                               NSException, NSInvalidArgumentException, @"appendChild: ancestor of node cannot be node's child");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the insertChild:beforeReferenceChild:() method when the
/// @e referenceChild parameter is @e nil.
///
/// These are exactly the same tests as in testAppendChild().
// -----------------------------------------------------------------------------
- (void) testInsertChildBeforeReferenceChildWhenReferenceChildIsNil
{
  [self setupNodeTree];
  GoNode* testee = self.nodeA2a;

  // Set non-nil when lastChild is nil
  XCTAssertEqual(testee.lastChild, nil);
  [testee insertChild:self.freeNode1 beforeReferenceChild:nil];
  XCTAssertEqual(testee.lastChild, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // Set same non-nil value
  [testee insertChild:self.freeNode1 beforeReferenceChild:nil];
  XCTAssertEqual(testee.lastChild, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // Set different non-nil value
  [testee insertChild:self.freeNode2 beforeReferenceChild:nil];
  XCTAssertEqual(testee.lastChild, self.freeNode2);
  XCTAssertEqual(self.freeNode2.parent, testee);
  XCTAssertEqual(self.freeNode1.nextSibling, self.freeNode2);

  // The new lastChild node is moved from its previous location in the tree
  XCTAssertEqual(self.nodeB.parent, self.rootNode);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.previousSibling, self.nodeA);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeB);
  [testee insertChild:self.nodeB beforeReferenceChild:nil];
  XCTAssertEqual(testee.lastChild, self.nodeB);
  XCTAssertEqual(self.nodeB.parent, testee);
  XCTAssertEqual(self.freeNode2.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeB.previousSibling, self.freeNode2);
  XCTAssertEqual(self.nodeB.nextSibling, nil);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeA);

  // Moving also works if the new lastChild is already a child of the parent
  [self setupNodeTree];
  testee = self.nodeA2;
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(testee.lastChild, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);
  [testee insertChild:self.nodeA2a beforeReferenceChild:nil];
  XCTAssertEqual(testee.firstChild, self.nodeA2b);
  XCTAssertEqual(testee.lastChild, self.nodeA2a);
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(self.nodeA2a.nextSibling, nil);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2c.nextSibling, self.nodeA2a);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);

  XCTAssertThrowsSpecificNamed([testee insertChild:nil beforeReferenceChild:nil],
                               NSException, NSInvalidArgumentException, @"insertChild:beforeReferenceChild: node cannot be nil");
  XCTAssertThrowsSpecificNamed([testee insertChild:testee beforeReferenceChild:nil],
                               NSException, NSInvalidArgumentException, @"insertChild:beforeReferenceChild: node cannot be its own child");
  XCTAssertThrowsSpecificNamed([testee insertChild:self.rootNode beforeReferenceChild:nil],
                               NSException, NSInvalidArgumentException, @"insertChild:beforeReferenceChild: ancestor of node cannot be node's child");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the insertChild:beforeReferenceChild:() method when the
/// @e referenceChild parameter is not @e nil.
// -----------------------------------------------------------------------------
- (void) testInsertChildBeforeReferenceChildWhenReferenceChildIsNotNil
{
  [self setupNodeTree];
  GoNode* testee = self.nodeA2;

  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  [testee insertChild:self.freeNode1 beforeReferenceChild:self.nodeA2b];
  XCTAssertEqual(self.nodeA2a.nextSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.previousSibling, self.nodeA2a);
  XCTAssertEqual(self.freeNode1.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // Set same value
  [testee insertChild:self.freeNode1 beforeReferenceChild:self.nodeA2b];
  XCTAssertEqual(self.nodeA2a.nextSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.previousSibling, self.nodeA2a);
  XCTAssertEqual(self.freeNode1.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // The new child node is moved from its previous location in the tree
  XCTAssertEqual(self.nodeB.parent, self.rootNode);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.previousSibling, self.nodeA);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeB);
  [testee insertChild:self.nodeB beforeReferenceChild:self.nodeA2b];
  XCTAssertEqual(self.freeNode1.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.parent, testee);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeB.previousSibling, self.freeNode1);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeA);

  // Moving also works if the new child is already a child of the parent
  [self setupNodeTree];
  testee = self.nodeA2;
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(testee.lastChild, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);
  [testee insertChild:self.nodeA2c beforeReferenceChild:self.nodeA2a];
  XCTAssertEqual(testee.firstChild, self.nodeA2c);
  XCTAssertEqual(testee.lastChild, self.nodeA2b);
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, nil);
  XCTAssertEqual(self.nodeA2c.nextSibling, self.nodeA2a);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);

  XCTAssertThrowsSpecificNamed([testee insertChild:nil beforeReferenceChild:nil],
                               NSException, NSInvalidArgumentException, @"insertChild:beforeReferenceChild: node cannot be nil");
  XCTAssertThrowsSpecificNamed([testee insertChild:self.freeNode1 beforeReferenceChild:self.freeNode2],
                               NSException, NSInvalidArgumentException, @"insertChild:beforeReferenceChild: reference node must be child node");
  XCTAssertThrowsSpecificNamed([testee insertChild:testee beforeReferenceChild:testee.firstChild],
                               NSException, NSInvalidArgumentException, @"insertChild:beforeReferenceChild: node cannot be its own child");
  XCTAssertThrowsSpecificNamed([testee insertChild:self.rootNode beforeReferenceChild:testee.firstChild],
                               NSException, NSInvalidArgumentException, @"insertChild:beforeReferenceChild: ancestor of node cannot be node's child");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeChild:() method.
// -----------------------------------------------------------------------------
- (void) testRemoveChild
{
  [self setupNodeTree];
  GoNode* testee = self.nodeA2;

  // Gap after removal is closed
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(testee.lastChild, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);
  [testee removeChild:self.nodeA2b];
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(testee.lastChild, self.nodeA2c);
  XCTAssertEqual(testee.children.count, 2);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2b.previousSibling, nil);
  XCTAssertEqual(self.nodeA2b.nextSibling, nil);
  XCTAssertEqual(self.nodeA2c.previousSibling, self.nodeA2a);
  XCTAssertEqual(self.nodeA2c.nextSibling, nil);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, nil);
  XCTAssertEqual(self.nodeA2c.parent, testee);

  // Remove last child
  [testee removeChild:self.nodeA2c];
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(testee.lastChild, self.nodeA2a);
  XCTAssertEqual(testee.children.count, 1);
  XCTAssertEqual(self.nodeA2a.nextSibling, nil);
  XCTAssertEqual(self.nodeA2c.previousSibling, nil);
  XCTAssertEqual(self.nodeA2c.nextSibling, nil);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, nil);

  // Remove first (and only) child
  [testee removeChild:self.nodeA2a];
  XCTAssertEqual(testee.firstChild, nil);
  XCTAssertEqual(testee.lastChild, nil);
  XCTAssertEqual(testee.children.count, 0);
  XCTAssertEqual(self.nodeA2a.parent, nil);

  XCTAssertThrowsSpecificNamed([testee removeChild:nil],
                               NSException, NSInvalidArgumentException, @"removeChild: node cannot be nil");
  XCTAssertThrowsSpecificNamed([testee removeChild:self.freeNode1],
                               NSException, NSInvalidArgumentException, @"removeChild: node must be a child");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the replaceChild:() method.
// -----------------------------------------------------------------------------
- (void) testReplaceChild
{
  [self setupNodeTree];
  GoNode* testee = self.nodeA2;

  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.previousSibling, self.nodeA2a);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2c.previousSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  [testee replaceChild:self.nodeA2b withNewChild:self.freeNode1];
  XCTAssertEqual(self.nodeA2a.nextSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.previousSibling, self.nodeA2a);
  XCTAssertEqual(self.freeNode1.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2c.previousSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, nil);
  XCTAssertEqual(self.nodeA2b.previousSibling, nil);
  XCTAssertEqual(self.nodeA2b.nextSibling, nil);

  // Set same value
  [testee replaceChild:self.freeNode1 withNewChild:self.freeNode1];
  XCTAssertEqual(self.nodeA2a.nextSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.previousSibling, self.nodeA2a);
  XCTAssertEqual(self.freeNode1.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2c.previousSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, testee);

  // The new child node is moved from its previous location in the tree
  XCTAssertEqual(self.nodeB.parent, self.rootNode);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.previousSibling, self.nodeA);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeB);
  [testee replaceChild:self.freeNode1 withNewChild:self.nodeB];
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.previousSibling, self.nodeA2a);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2c.previousSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.parent, testee);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeA);

  // Moving also works if the new child is already a child of the parent
  [self setupNodeTree];
  testee = self.nodeA2;
  XCTAssertEqual(testee.children.count, 3);
  XCTAssertEqual(testee.firstChild, self.nodeA2a);
  XCTAssertEqual(testee.lastChild, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, testee);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);
  [testee replaceChild:self.nodeA2a withNewChild:self.nodeA2c];
  XCTAssertEqual(testee.firstChild, self.nodeA2c);
  XCTAssertEqual(testee.lastChild, self.nodeA2b);
  XCTAssertEqual(testee.children.count, 2);
  XCTAssertEqual(self.nodeA2a.nextSibling, nil);
  XCTAssertEqual(self.nodeA2b.nextSibling, nil);
  XCTAssertEqual(self.nodeA2c.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2a.parent, nil);
  XCTAssertEqual(self.nodeA2b.parent, testee);
  XCTAssertEqual(self.nodeA2c.parent, testee);

  XCTAssertThrowsSpecificNamed([testee replaceChild:nil withNewChild:self.freeNode1],
                               NSException, NSInvalidArgumentException, @"replaceChild:withNewChild: old child node cannot be nil");
  XCTAssertThrowsSpecificNamed([testee replaceChild:testee.firstChild withNewChild:nil],
                               NSException, NSInvalidArgumentException, @"replaceChild:withNewChild: new child node cannot be nil");
  XCTAssertThrowsSpecificNamed([testee replaceChild:self.freeNode2 withNewChild:self.freeNode1],
                               NSException, NSInvalidArgumentException, @"replaceChild:withNewChild: old child node must be child node");
  XCTAssertThrowsSpecificNamed([testee replaceChild:testee.firstChild withNewChild:testee],
                               NSException, NSInvalidArgumentException, @"replaceChild:withNewChild: node cannot be its own child");
  XCTAssertThrowsSpecificNamed([testee replaceChild:testee.firstChild withNewChild:self.rootNode],
                               NSException, NSInvalidArgumentException, @"replaceChild:withNewChild: ancestor of node cannot be node's child");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setNextSibling:() method.
// -----------------------------------------------------------------------------
- (void) testSetNextSibling
{
  [self setupNodeTree];
  GoNode* testee = self.nodeA2c;

  // Set nil when nextSibling is already nil
  XCTAssertEqual(testee.nextSibling, nil);
  [testee setNextSibling:nil];
  XCTAssertEqual(testee.nextSibling, nil);

  // Set nil when nextSibling is not nil
  [testee setNextSibling:self.freeNode1];
  XCTAssertEqual(testee.nextSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, self.nodeA2);
  [testee setNextSibling:nil];
  XCTAssertEqual(testee.nextSibling, nil);
  XCTAssertEqual(self.freeNode1.parent, nil);

  // Set non-nil when nextSibling is nil
  [testee setNextSibling:self.freeNode1];
  XCTAssertEqual(testee.nextSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, self.nodeA2);

  // Set same non-nil value
  [testee setNextSibling:self.freeNode1];
  XCTAssertEqual(testee.nextSibling, self.freeNode1);
  XCTAssertEqual(self.freeNode1.parent, self.nodeA2);

  // Set different non-nil value
  [testee setNextSibling:self.freeNode2];
  XCTAssertEqual(testee.nextSibling, self.freeNode2);
  XCTAssertEqual(self.freeNode2.parent, self.nodeA2);
  XCTAssertEqual(self.freeNode2.nextSibling, nil);
  XCTAssertEqual(self.freeNode1.parent, nil);
  XCTAssertEqual(self.freeNode1.previousSibling, nil);

  // The new nextSibling node is moved from its previous location in the tree
  XCTAssertEqual(self.nodeB.parent, self.rootNode);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.previousSibling, self.nodeA);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeB);
  [testee setNextSibling:self.nodeB];
  XCTAssertEqual(testee.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeB.previousSibling, testee);
  XCTAssertEqual(self.nodeB.nextSibling, nil);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeA);

  // Setting nextSibling discards the old nextSibling
  [self setupNodeTree];
  testee = self.nodeA2a;
  XCTAssertEqual(self.freeNode2.parent, nil);
  XCTAssertEqual(self.nodeA2.children.count, 3);
  XCTAssertEqual(self.nodeA2.firstChild, self.nodeA2a);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA2b.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA2c.parent, self.nodeA2);
  [testee setNextSibling:self.freeNode2];
  XCTAssertEqual(self.nodeA2.firstChild, self.nodeA2a);
  XCTAssertEqual(self.freeNode2.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA2.children.count, 2);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.freeNode2);
  XCTAssertEqual(self.freeNode2.nextSibling, nil);
  XCTAssertEqual(self.nodeA2b.nextSibling, nil);  // sibling linkage is broken!
  XCTAssertEqual(self.nodeA2a.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA2b.parent, nil);
  XCTAssertEqual(self.nodeA2c.parent, nil);

  // Moving also works if the new nextSibling is already a child of the parent
  [self setupNodeTree];
  testee = self.nodeA2a;
  XCTAssertEqual(self.nodeA2.children.count, 3);
  XCTAssertEqual(self.nodeA2.firstChild, self.nodeA2a);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2b);
  XCTAssertEqual(self.nodeA2b.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA2b.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA2c.parent, self.nodeA2);
  [testee setNextSibling:self.nodeA2c];
  XCTAssertEqual(self.nodeA2.firstChild, self.nodeA2a);
  XCTAssertEqual(self.nodeA2.children.count, 2);
  XCTAssertEqual(self.nodeA2a.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2b.nextSibling, nil);
  XCTAssertEqual(self.nodeA2c.nextSibling, nil);
  XCTAssertEqual(self.nodeA2a.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA2b.parent, nil);
  XCTAssertEqual(self.nodeA2c.parent, self.nodeA2);

  XCTAssertThrowsSpecificNamed([testee setNextSibling:testee],
                               NSException, NSInvalidArgumentException, @"setNextSibling: node cannot be its own next sibling");
  XCTAssertThrowsSpecificNamed([testee setNextSibling:self.rootNode],
                               NSException, NSInvalidArgumentException, @"setNextSibling: ancestor of node cannot be node's next sibling");
  XCTAssertThrowsSpecificNamed([self.rootNode setNextSibling:self.freeNode1],
                               NSException, NSInvalidArgumentException, @"setNextSibling: root node cannot have a next sibling");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setParent:() method.
// -----------------------------------------------------------------------------
- (void) testSetParent
{
  [self setupNodeTree];
  GoNode* testee = self.freeNode1;

  // Set nil when parent is already nil
  XCTAssertEqual(testee.parent, nil);
  [testee setParent:nil];
  XCTAssertEqual(testee.nextSibling, nil);

  // Set nil when parent is not nil
  [testee setParent:self.freeNode2];
  XCTAssertEqual(testee.parent, self.freeNode2);
  XCTAssertEqual(self.freeNode2.firstChild, testee);
  [testee setParent:nil];
  XCTAssertEqual(testee.parent, nil);
  XCTAssertEqual(self.freeNode2.firstChild, nil);

  // Set non-nil when parent is nil
  [testee setParent:self.freeNode2];
  XCTAssertEqual(testee.parent, self.freeNode2);
  XCTAssertEqual(self.freeNode2.firstChild, testee);

  // Set same non-nil value
  [testee setParent:self.freeNode2];
  XCTAssertEqual(testee.parent, self.freeNode2);
  XCTAssertEqual(self.freeNode2.firstChild, testee);

  // Set different non-nil value
  [testee setParent:self.nodeA2a];
  XCTAssertEqual(testee.parent, self.nodeA2a);
  XCTAssertEqual(self.nodeA2a.firstChild, testee);
  XCTAssertEqual(self.freeNode2.firstChild, nil);

  // If new parent already has child nodes, append at the end
  [testee setParent:self.rootNode];
  XCTAssertEqual(testee.parent, self.rootNode);
  XCTAssertEqual(self.rootNode.firstChild, self.nodeA);
  XCTAssertEqual(self.rootNode.lastChild, testee);

  // The node is moved from its previous location in the tree. The gap is
  // closed.
  testee = self.nodeB;
  XCTAssertEqual(self.nodeB.parent, self.rootNode);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeB);
  XCTAssertEqual(self.nodeB.previousSibling, self.nodeA);
  XCTAssertEqual(self.nodeB.nextSibling, self.nodeC);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeB);
  [testee setParent:self.nodeA2];
  XCTAssertEqual(self.nodeA2.lastChild, testee);
  XCTAssertEqual(testee.parent, self.nodeA2);
  XCTAssertEqual(self.nodeA2c.nextSibling, testee);
  XCTAssertEqual(self.nodeA.nextSibling, self.nodeC);
  XCTAssertEqual(testee.previousSibling, self.nodeA2c);
  XCTAssertEqual(testee.nextSibling, nil);
  XCTAssertEqual(self.nodeC.previousSibling, self.nodeA);

  // Setting same parent has no effect on the order of the parent's children
  [self setupNodeTree];
  testee = self.nodeA2b;
  XCTAssertEqual(self.nodeA2.firstChild, self.nodeA2a);
  XCTAssertEqual(self.nodeA2.lastChild, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.nextSibling, testee);
  XCTAssertEqual(testee.previousSibling, self.nodeA2a);
  XCTAssertEqual(testee.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2c.previousSibling, testee);
  [testee setParent:self.nodeA2];
  XCTAssertEqual(self.nodeA2.firstChild, self.nodeA2a);
  XCTAssertEqual(self.nodeA2.lastChild, self.nodeA2c);
  XCTAssertEqual(self.nodeA2a.nextSibling, testee);
  XCTAssertEqual(testee.previousSibling, self.nodeA2a);
  XCTAssertEqual(testee.nextSibling, self.nodeA2c);
  XCTAssertEqual(self.nodeA2c.previousSibling, testee);

  testee = self.nodeA2;
  XCTAssertThrowsSpecificNamed([testee setParent:testee],
                               NSException, NSInvalidArgumentException, @"setParent: node cannot be its own parent");
  XCTAssertThrowsSpecificNamed([testee setParent:self.nodeA2b],
                               NSException, NSInvalidArgumentException, @"setParent: descendant of node cannot be node's parent");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isDescendantOfNode:() method.
// -----------------------------------------------------------------------------
- (void) testIsDescendantOfNode
{
  [self setupNodeTree];

  XCTAssertTrue([self.nodeA2a isDescendantOfNode:self.nodeA]);
  XCTAssertTrue([self.nodeA2 isDescendantOfNode:self.nodeA]);
  XCTAssertFalse([self.nodeA isDescendantOfNode:self.nodeA]);
  XCTAssertFalse([self.rootNode isDescendantOfNode:self.nodeA]);

  XCTAssertFalse([self.nodeA2a isDescendantOfNode:self.nodeB]);

  XCTAssertThrowsSpecificNamed([self.rootNode isDescendantOfNode:nil],
                               NSException, NSInvalidArgumentException, @"isDescendantOfNode: node cannot be nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isAncestorOfNode:() method.
// -----------------------------------------------------------------------------
- (void) testIsAncestorOfNode
{
  [self setupNodeTree];

  XCTAssertFalse([self.nodeA2a isAncestorOfNode:self.nodeA]);
  XCTAssertFalse([self.nodeA2 isAncestorOfNode:self.nodeA]);
  XCTAssertFalse([self.nodeA isAncestorOfNode:self.nodeA]);
  XCTAssertTrue([self.rootNode isAncestorOfNode:self.nodeA]);

  XCTAssertFalse([self.nodeB isAncestorOfNode:self.nodeA2a]);

  XCTAssertThrowsSpecificNamed([self.rootNode isAncestorOfNode:nil],
                               NSException, NSInvalidArgumentException, @"isAncestorOfNode: node cannot be nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e empty property.
// -----------------------------------------------------------------------------
- (void) testEmpty
{
  GoNode* testee = [GoNode node];

  XCTAssertTrue(testee.isEmpty);
  XCTAssertNil(testee.goNodeSetup);
  XCTAssertNil(testee.goMove);
  XCTAssertNil(testee.goNodeAnnotation);
  XCTAssertNil(testee.goNodeMarkup);

  testee.goNodeSetup = [[[GoNodeSetup alloc] init] autorelease];
  XCTAssertTrue(testee.isEmpty);
  testee.goNodeSetup.setupFirstMoveColor = GoColorBlack;
  XCTAssertFalse(testee.isEmpty);
  testee.goNodeSetup = nil;
  XCTAssertTrue(testee.isEmpty);

  testee.goMove = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  XCTAssertFalse(testee.isEmpty);
  testee.goMove = nil;
  XCTAssertTrue(testee.isEmpty);

  testee.goNodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  XCTAssertFalse(testee.isEmpty);
  testee.goNodeAnnotation = nil;
  XCTAssertTrue(testee.isEmpty);

  testee.goNodeMarkup = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertTrue(testee.isEmpty);
  [testee.goNodeMarkup setSymbol:GoMarkupSymbolCircle atVertex:@"A1"];
  XCTAssertFalse(testee.isEmpty);
  testee.goNodeMarkup = nil;
  XCTAssertTrue(testee.isEmpty);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the modifyBoard() method.
// -----------------------------------------------------------------------------
- (void) testModifyBoard
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoBoardRegion* mainRegion = point1.region;
  XCTAssertEqual(mainRegion, point2.region);
  long long zobristHashEmptyBoard = 0;

  // In practice modifyBoard is never invoked on the root node because the user
  // cannot go back to a board position before the first. However, at the moment
  // there is no guard against invoking modifyBoard on the root node.
  GoNode* rootNode = m_game.nodeModel.rootNode;
  [rootNode modifyBoard];
  long long zobristHashRootNode = rootNode.zobristHash;
  XCTAssertEqual(zobristHashRootNode, zobristHashEmptyBoard);

  // Modify board when node is empty
  [m_game addEmptyNodeToCurrentGameVariation];
  GoNode* emptyNode = m_game.nodeModel.leafNode;;
  [emptyNode modifyBoard];
  long long zobristHashEmptyNode = emptyNode.zobristHash;
  XCTAssertEqual(zobristHashEmptyNode, zobristHashRootNode);

  // Modify board when node contains setup information
  [m_game addEmptyNodeToCurrentGameVariation];
  GoNode* nodeWithSetupInformation = m_game.nodeModel.leafNode;;
  nodeWithSetupInformation.goNodeSetup = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  [nodeWithSetupInformation.goNodeSetup setupBlackStone:point1];
  XCTAssertEqual(point1.stoneState, GoColorNone);
  [nodeWithSetupInformation modifyBoard];
  XCTAssertEqual(point1.stoneState, GoColorBlack);
  XCTAssertNotEqual(point1.region, mainRegion);
  long long zobristHashSetupInformation = nodeWithSetupInformation.zobristHash;
  XCTAssertNotEqual(zobristHashSetupInformation, zobristHashEmptyNode);

  // Modify board when node contains move
  [m_game addEmptyNodeToCurrentGameVariation];
  GoNode* nodeWithMove = m_game.nodeModel.leafNode;
  nodeWithMove.goMove = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  nodeWithMove.goMove.point = point2;
  XCTAssertEqual(point2.stoneState, GoColorNone);
  [nodeWithMove modifyBoard];
  XCTAssertEqual(point2.stoneState, GoColorWhite);
  XCTAssertNotEqual(point2.region, mainRegion);
  XCTAssertNotEqual(point2.region, point1.region);
  long long zobristHashMove = nodeWithMove.zobristHash;
  XCTAssertNotEqual(zobristHashMove, zobristHashEmptyNode);
  XCTAssertNotEqual(zobristHashMove, zobristHashSetupInformation);

  // Modify board when node is not empty but does not contain setup information
  // or a move
  [m_game addEmptyNodeToCurrentGameVariation];
  GoNode* nodeWithAnnotationsAndMarkup = m_game.nodeModel.leafNode;
  nodeWithAnnotationsAndMarkup.goNodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  nodeWithAnnotationsAndMarkup.goNodeAnnotation.shortDescription = @"foo";
  nodeWithAnnotationsAndMarkup.goNodeMarkup = [[[GoNodeMarkup alloc] init] autorelease];
  [nodeWithAnnotationsAndMarkup.goNodeMarkup setSymbol:GoMarkupSymbolCircle atVertex:@"A1"];
  [nodeWithAnnotationsAndMarkup modifyBoard];
  long long zobristHashAnnotationsAndMarkup = nodeWithAnnotationsAndMarkup.zobristHash;
  XCTAssertEqual(zobristHashAnnotationsAndMarkup, zobristHashMove);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the revertBoard() method.
// -----------------------------------------------------------------------------
- (void) testRevertBoard
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoBoardRegion* mainRegion = point1.region;
  XCTAssertEqual(mainRegion, point2.region);

  GoNode* rootNode = m_game.nodeModel.rootNode;

  [m_game addEmptyNodeToCurrentGameVariation];
  GoNode* emptyNode = m_game.nodeModel.leafNode;;
  [emptyNode modifyBoard];

  [m_game addEmptyNodeToCurrentGameVariation];
  GoNode* nodeWithSetupInformation = m_game.nodeModel.leafNode;;
  [m_game changeSetupPoint:point1 toStoneState:GoColorBlack];
  [m_game changeSetupFirstMoveColor:GoColorWhite];

  [m_game play:point2];
  GoNode* nodeWithMove = m_game.nodeModel.leafNode;

  [m_game addEmptyNodeToCurrentGameVariation];
  GoNode* nodeWithAnnotationsAndMarkup = m_game.nodeModel.leafNode;
  nodeWithAnnotationsAndMarkup.goNodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  nodeWithAnnotationsAndMarkup.goNodeAnnotation.shortDescription = @"foo";
  nodeWithAnnotationsAndMarkup.goNodeMarkup = [[[GoNodeMarkup alloc] init] autorelease];
  [nodeWithAnnotationsAndMarkup.goNodeMarkup setSymbol:GoMarkupSymbolCircle atVertex:@"A1"];
  [nodeWithAnnotationsAndMarkup modifyBoard];

  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(point1.stoneState, GoColorBlack);
  XCTAssertEqual(point2.stoneState, GoColorWhite);
  XCTAssertNotEqual(point1.region, mainRegion);
  XCTAssertNotEqual(point2.region, mainRegion);
  XCTAssertNotEqual(point2.region, point1.region);

  [nodeWithAnnotationsAndMarkup revertBoard];
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(point1.stoneState, GoColorBlack);
  XCTAssertEqual(point2.stoneState, GoColorWhite);
  XCTAssertNotEqual(point1.region, mainRegion);
  XCTAssertNotEqual(point2.region, mainRegion);
  XCTAssertNotEqual(point2.region, point1.region);

  [nodeWithMove revertBoard];
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(point1.stoneState, GoColorBlack);
  XCTAssertEqual(point2.stoneState, GoColorNone);
  XCTAssertNotEqual(point1.region, mainRegion);
  XCTAssertEqual(point2.region, mainRegion);

  [nodeWithSetupInformation revertBoard];
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorNone);
  XCTAssertEqual(point1.stoneState, GoColorNone);
  XCTAssertEqual(point2.stoneState, GoColorNone);
  XCTAssertEqual(point1.region, mainRegion);
  XCTAssertEqual(point2.region, mainRegion);

  [emptyNode revertBoard];
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorNone);
  XCTAssertEqual(point1.stoneState, GoColorNone);
  XCTAssertEqual(point2.stoneState, GoColorNone);
  XCTAssertEqual(point1.region, mainRegion);
  XCTAssertEqual(point2.region, mainRegion);

  // In practice revertBoard is never invoked on the root node because the user
  // cannot go back to a board position before the first. However, at the moment
  // there is no guard against invoking revertBoard on the root node.
  [rootNode revertBoard];
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorNone);
  XCTAssertEqual(point1.stoneState, GoColorNone);
  XCTAssertEqual(point2.stoneState, GoColorNone);
  XCTAssertEqual(point1.region, mainRegion);
  XCTAssertEqual(point2.region, mainRegion);
}

@end
