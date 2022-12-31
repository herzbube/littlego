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
#import "NodeTreeViewCanvasTest.h"

// Application includes
#import <main/ApplicationDelegate.h>
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoMove.h>
#import <go/GoMoveAdditions.h>
#import <go/GoNodeAdditions.h>
#import <go/GoNodeAnnotation.h>
#import <go/GoNodeMarkup.h>
#import <go/GoNodeModel.h>
#import <go/GoNodeSetup.h>
#import <play/model/NodeTreeViewModel.h>
#import <play/nodetreeview/canvas/NodeTreeViewCanvas.h>
#import <play/nodetreeview/canvas/NodeTreeViewCanvasAdditions.h>
#import <play/nodetreeview/canvas/NodeTreeViewCell.h>
#import <play/nodetreeview/canvas/NodeTreeViewCellPosition.h>


@implementation NodeTreeViewCanvasTest

#pragma mark - Test methods

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the node tree is minimal and consists of only a root node, and the user
/// preference "condense tree" is disabled.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_RootNodeOnly
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:false];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary = @{ [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty] };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the node tree is minimal and consists of only a root node, and the user
/// preference "condense tree" is enabled.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_RootNodeOnly
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:true];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:0],
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:1],
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:2],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is enabled. The node tree is built so
/// that all scenarios are covered where the algorithm must decide between
/// generating a condensed or uncondensed node.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like. Unless marked, all nodes are uncondensed. Only move nodes are
/// condensed which are in the middle of a sequence of move nodes. The exception
/// are move nodes that are branching nodes (Move3) or the child of a branching
/// node (Move4a and Move4b). A move node in the middle of a sequence of move
/// nodes is condensed even if it also contains annotations and/or markup
/// (Move5a and Move5b).
/// @verbatim
///                                                +-- condensed         +-- condensed
///                                                |                     |
///                                                v                     v
/// Root--Empty--Setup--Annotation--Markup--Move1--Move2--Move3--Move4a--Move5a--Move6a
///                                                         |
///                                                         +----Move4b--Move5b--Move6b
///                                                                      ^
///                                                                      |
///                                                                      +-- condensed
/// @endverbatim
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_UncondensedNodes
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:true];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  GoNode* emptyNode = [self parentNode:rootNode appendChildNode:[self createEmptyNode]];
  GoNode* setupNode = [self parentNode:emptyNode appendChildNode:[self createSetupNodeForSymbol:NodeTreeViewCellSymbolBlackSetupStones]];
  GoNode* annotationNode = [self parentNode:setupNode appendChildNode:[self createAnnotationNode]];
  GoNode* markupNode = [self parentNode:annotationNode appendChildNode:[self createMarkupNode]];
  GoNode* move1Node = [self parentNode:markupNode appendChildNode:[self createBlackMoveNode]];
  GoNode* move2Node = [self parentNode:move1Node appendChildNode:[self createBlackMoveNode]];
  GoNode* move3Node = [self parentNode:move2Node appendChildNode:[self createBlackMoveNode]];
  GoNode* move4aNode = [self parentNode:move3Node appendChildNode:[self createBlackMoveNode]];
  GoNode* move5aNode = [self parentNode:move4aNode appendChildNode:[self createBlackMoveNodeWithAnnotationsAndMarkup]];
  [self parentNode:move5aNode appendChildNode:[self createBlackMoveNode]];
  GoNode* move4bNode = [self parentNode:move3Node appendChildNode:[self createBlackMoveNode]];
  GoNode* move5bNode = [self parentNode:move4bNode appendChildNode:[self createBlackMoveNodeWithAnnotationsAndMarkup]];
  [self parentNode:move5bNode appendChildNode:[self createBlackMoveNode]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // rootNode
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:0],
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // emptyNode
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // setupNode
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:8 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // annotationNode
    [self positionWithX:9 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:11 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // markupNode
    [self positionWithX:12 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolMarkup lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:13 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolMarkup lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:14 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolMarkup lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // move1Node
    [self positionWithX:15 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:16 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:17 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // move2Node
    [self positionWithX:18 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // move3Node
    [self positionWithX:19 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:20 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:21 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // move4aNode
    [self positionWithX:22 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:23 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:24 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // move5aNode
    [self positionWithX:25 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // move6aNode
    [self positionWithX:26 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:27 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:28 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // Branching lines
    [self positionWithX:20 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:21 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // move4bNode
    [self positionWithX:22 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:23 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:24 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // move5bNode
    [self positionWithX:25 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // move6bNode
    [self positionWithX:26 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:27 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:28 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is disabled. The node tree is built so
/// that the algorithm must generate each value in the enumeration
/// #NodeTreeViewCellSymbol at least once.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_NodeSymbols
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:false];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* parentNode = m_game.nodeModel.rootNode;
  parentNode = [self parentNode:parentNode appendChildNode:[self createEmptyNode]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createSetupNodeForSymbol:NodeTreeViewCellSymbolBlackSetupStones]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createSetupNodeForSymbol:NodeTreeViewCellSymbolWhiteSetupStones]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createSetupNodeForSymbol:NodeTreeViewCellSymbolNoSetupStones]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createSetupNodeForSymbol:NodeTreeViewCellSymbolBlackAndWhiteSetupStones]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createSetupNodeForSymbol:NodeTreeViewCellSymbolBlackAndNoSetupStones]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createSetupNodeForSymbol:NodeTreeViewCellSymbolWhiteAndNoSetupStones]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createSetupNodeForSymbol:NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createBlackMoveNode]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createWhiteMoveNode]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createAnnotationNode]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createMarkupNode]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createAnnotationsAndMarkupNode]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createSetupNodeWithAnnotationsAndMarkupForSymbol:NodeTreeViewCellSymbolBlackSetupStones]];
  parentNode = [self parentNode:parentNode appendChildNode:[self createBlackMoveNodeWithAnnotationsAndMarkup]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight],
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolNoSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackAndWhiteSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackAndNoSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteAndNoSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:8 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:9 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:10 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:11 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:12 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolMarkup lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:13 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotationsAndMarkup lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // The presence of annotations and/or markup does not affect the symbol if
    // the node also contains setup information
    [self positionWithX:14 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackSetupStones lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // ... or a move
    [self positionWithX:15 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is disabled and there is a selected
/// node.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_Selected
{
  // TODO xxx Node selection not yet implemented in NodeTreeViewCanvas
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is enabled and there is a selected node.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_Selected
{
  // TODO xxx Node selection not yet implemented in NodeTreeViewCanvas
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is disabled and the user preference
/// "branching style" is set to diagonal. The node tree is built so that all
/// scenarios are covered where the algorithm must decide between the different
/// diagonal line options.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like.
/// @verbatim
/// A---B---C---D---E---F---G
///     |   |\--H   |    \--I
///      \--J\--K    \--L---M
/// @endverbatim
///
/// The tested scenarios are:
/// - Scenario 1: Single child branch. The cell below the branching node has
///   only a diagonal line. In the diagram above this is the branching line that
///   goes from branching node F to child node I.
/// - Scenario 2: Multiple child branches. The cell below the branching node has
///   both a diagonal and a vertical line. In the diagram above this is the
///   branching line that goes from branching node C to child nodes H and K.
/// - Scenario 3: A child branch B1 fits on a line because the diagonal
///   branching line of another child branch B2 leaves just enough space for it.
///   In the diagram above B1 is the branch with node J, B2 is the branch with
///   node K. B1 fits on the same y-position as B2 because 1) the diagonal
///   branching line leading from C to K does not occupy the space of J, and
///   there is also no vertical branching line to another child node of C that
///   would take the space away from J.
/// - Scenario 4: A child branch B1 does not fit on a line because another child
///   branch B2 does not leave enough space for it. In the diagram above this
///   scenario occurs in two places:
///   - B1 is the branch with nodes L and M, B2 is the branch with node M. Here
///     B1 does not fit because it contains two nodes, which is too many to fit
///     despite the diagonal branching line leading from F to I.
///   - B1 is the branch with node J, B2 is the branch with H. Here B1 does not
///     fit because the vertical line leading from C to K takes away the space.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_BranchingStyleDiagonal_Lines
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:false branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeF = [self parentNode:nodeE appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  // White move to distinguish content from nodeH => verifies that sibling
  // child branches are created on the correct y-position
  [self parentNode:nodeC appendChildNode:[self createWhiteMoveNode]];
  GoNode* nodeL = [self parentNode:nodeE appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeL appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNode]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeC
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom | NodeTreeViewCellLineCenterToBottomRight],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeE
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeF
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottomRight],
    // nodeG
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeJ
    [self positionWithX:1 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeC > nodeK
    [self positionWithX:2 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeH
    [self positionWithX:3 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToTopLeft],
    // nodeE > nodeL
    [self positionWithX:4 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeI
    [self positionWithX:6 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToTopLeft],
    // nodeJ
    [self positionWithX:2 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToTopLeft],
    // nodeK
    [self positionWithX:3 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove lines:NodeTreeViewCellLineCenterToTopLeft],
    // nodeL
    [self positionWithX:5 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeM
    [self positionWithX:6 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is disabled and the user preference
/// "branching style" is set bracket. The node tree is built so that all
/// scenarios are covered where the algorithm must decide between the different
/// bracket line options.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like.
/// @verbatim
/// A---B---C---D---E---F---G
///     |   +---H   |   +---I
///     |   +---K   +---L---M
///     +---J
/// @endverbatim
///
/// The tested scenarios are basically the same as in
/// testCalculateCanvas_UncondensedTree_BranchingStyleDiagonal_Lines(). The
/// differences are the perpendicular instead of diagonal lines, and that the
/// branch with node J does not fit on the same line as the branch with node K.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_BranchingStyleBracket_Lines
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:false branchingStyle:NodeTreeViewBranchingStyleBracket];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeF = [self parentNode:nodeE appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  // White move to distinguish content from nodeH => verifies that sibling
  // child branches are created on the correct y-position
  [self parentNode:nodeC appendChildNode:[self createWhiteMoveNode]];
  GoNode* nodeL = [self parentNode:nodeE appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeL appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNode]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeC
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeE
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeF
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeG
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeJ
    [self positionWithX:1 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeC > nodeH + nodeK
    [self positionWithX:2 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom | NodeTreeViewCellLineCenterToRight],
    // nodeH
    [self positionWithX:3 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeE > nodeL
    [self positionWithX:4 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeF > nodeI
    [self positionWithX:5 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeI
    [self positionWithX:6 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeJ
    [self positionWithX:1 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeC > nodeK
    [self positionWithX:2 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeK
    [self positionWithX:3 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeE > nodeL
    [self positionWithX:4 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeL
    [self positionWithX:5 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeM
    [self positionWithX:6 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeJ
    [self positionWithX:1 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeJ
    [self positionWithX:2 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is enabled and the user preference
/// "branching style" is set to diagonal. The node tree is built so that all
/// scenarios are covered where the algorithm must decide between the different
/// diagonal line options.
///
/// See testCalculateCanvas_UncondensedTree_BranchingStyleDiagonal_Lines()
/// for details on the possible options. The difference is the branch with
/// node J no longer fits on y-position 2, because diagonal branching does not
/// gain sufficient space when multipart cells are involved. See comment in
/// implementation.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_BranchingStyleDiagonal_Lines
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeF = [self parentNode:nodeE appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  // White move to distinguish content from nodeH => verifies that sibling
  // child branches are created on the correct y-position
  [self parentNode:nodeC appendChildNode:[self createWhiteMoveNode]];
  GoNode* nodeL = [self parentNode:nodeE appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeL appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNode]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:0],
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeB
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeC
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom | NodeTreeViewCellLineCenterToBottomRight part:1],
    [self positionWithX:8 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeD
    [self positionWithX:9 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:11 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeE
    [self positionWithX:12 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:13 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:14 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeF
    [self positionWithX:15 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:16 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottomRight part:1],
    [self positionWithX:17 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeG
    [self positionWithX:18 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:19 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:20 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeB > nodeJ
    [self positionWithX:4 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeC > nodeK
    [self positionWithX:7 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeC > nodeH
    [self positionWithX:8 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeH
    [self positionWithX:9 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:11 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeE > nodeL
    [self positionWithX:13 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeF > nodeI
    [self positionWithX:17 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeI
    [self positionWithX:18 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:19 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:20 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeB > nodeJ
    [self positionWithX:4 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeC > nodeK
    [self positionWithX:8 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeK
    [self positionWithX:9 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:11 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove part:2],
    // nodeE > nodeL
    [self positionWithX:14 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeL
    [self positionWithX:15 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:16 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:17 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeM
    [self positionWithX:18 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:19 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:20 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeB > nodeJ
    [self positionWithX:5 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeJ
    [self positionWithX:6 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:8 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is enabled, multipart cells are
/// extra-wide, and the user preference "branching style" is set to diagonal.
///
/// This covers a special case for diagonal lines that occurs only when
/// multipart cells consist of 5 or more sub-cells. In the following diagram,
/// cell 4/1 is an extra cell with horizontal lines only - this extra cell is
/// not generated for multiplart cells that consist of only 3 sub-cells.
/// @verbatim
///    +---++---++---++---++---++---++---++---++---++---+
///    |   ||   ||   ||   ||   ||   ||   ||   ||   ||   |
/// 0  |   ||   || A------------------------B ||   ||   |
///    |   ||   ||  \||   ||   ||   ||   ||   ||   ||   |
///    +---++---++---++---++---++---++---++---++---++---+
///    +---++---++---++---++---++---++---++---++---++---+
///    |   ||   ||   ||\  ||   ||   ||   ||   ||   ||   |
/// 1  |   ||   ||   || o-------------------C ||   ||   |
///    |   ||   ||   ||   ||   ||   ||   ||   ||   ||   |
///    +---++---++---++---++---++---++---++---++---++---+
///      0    1    2    3    4    5    6    7    8    9
/// @endverbatim
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_ExtraWideMultipartCells_BranchingStyleDiagonal_Lines
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  nodeTreeViewModel.numberOfCellsOfMultipartCell = 5;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:0],
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:1],
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottomRight part:2],
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:3],
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:4],
    // nodeB
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:2],
    [self positionWithX:8 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:3],
    [self positionWithX:9 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:4],
    // nodeA > nodeC
    [self positionWithX:3 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:4 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeC
    [self positionWithX:5 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:6 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:7 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:2],
    [self positionWithX:8 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:3],
    [self positionWithX:9 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:4],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is enabled and the user preference
/// "branching style" is set to bracket. The node tree is built so that all
/// scenarios are covered where the algorithm must decide between the different
/// bracket line options.
///
/// See testCalculateCanvas_UncondensedTree_BranchingStyleBracket_Lines()
/// for details on the possible options.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_BranchingStyleBracket_Lines
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:true branchingStyle:NodeTreeViewBranchingStyleBracket];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeF = [self parentNode:nodeE appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  // White move to distinguish content from nodeH => verifies that sibling
  // child branches are created on the correct y-position
  [self parentNode:nodeC appendChildNode:[self createWhiteMoveNode]];
  GoNode* nodeL = [self parentNode:nodeE appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeL appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNode]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:0],
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeB
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeC
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:8 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeD
    [self positionWithX:9 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:11 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeE
    [self positionWithX:12 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:13 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:14 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeF
    [self positionWithX:15 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:16 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:17 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeG
    [self positionWithX:18 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:19 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:20 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeB > nodeJ
    [self positionWithX:4 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeC > nodeH + nodeK
    [self positionWithX:7 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom | NodeTreeViewCellLineCenterToRight],
    // nodeC > nodeH
    [self positionWithX:8 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeH
    [self positionWithX:9 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:11 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeE > nodeL
    [self positionWithX:13 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeF > nodeI
    [self positionWithX:16 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:17 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeI
    [self positionWithX:18 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:19 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:20 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeB > nodeJ
    [self positionWithX:4 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeC > nodeK
    [self positionWithX:7 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:8 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeK
    [self positionWithX:9 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:11 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove part:2],
    // nodeE > nodeL
    [self positionWithX:13 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:14 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeL
    [self positionWithX:15 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:16 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:17 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeM
    [self positionWithX:18 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:19 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:20 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeB > nodeJ
    [self positionWithX:4 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:5 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeJ
    [self positionWithX:6 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:8 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is disabled and the user preference
/// "align moves" is enabled. The node tree is built so that all scenarios are
/// covered where the algorithm must align move nodes.
///
/// The following diagrams illustrate how the node tree built in this test looks
/// like. Legend: A-S=Node IDs, in paranthesis: R=Root node, M<n>=Move node,
/// A=Annotation node.
/// @verbatim
/// Before alignment:
///
///     A(R)----B(M1)---C(A)----D(M2)---E(M3)---F(A)----G(M4)---H(M5)
///               |                                       |
///               +-----I(M2)---J(A)----K(M3)             +-----L(A)----M(A)
///                       |                                       |
///                       +-----N(A)----O(A)----P(M3)             +-----Q(M5)
/// x = 0       1       2       3       4       5       6       7       8
///
/// After alignment:
///
///     A(R)----B(M1)---C(A)----D(M2)-------------------E(M3)---F(A)----G(M4)----------H(M5)
///               |                                                       |
///               +-------------I(M2)---J(A)------------K(M3)             +-----L(A)---M(A)
///                               |                                               |
///                               +-----N(A)----O(A)----P(M3)                     +----Q(M5)
/// x = 0       1       2       3       4       5       6       7       8       9      10
/// @endverbatim
///
/// Scenarios that are covered in this test:
/// - A move node needs no alignment (B(M1) and G(M4))
/// - Aligning a move shifts all nodes behind the move in the same branch
///   (I(M2), E(M3) and K(M3))
/// - Aligning a move shifts an entire child branch (branch that contains N(A))
/// - No nodes to shift after a move is aligned (H(M5) and Q(M5))
/// - A move in a child branch is aligned with a move in the parent branch
///   (I(M2))
/// - A move in the parent branch is aligned with a move in a child branch
///   (E(M3), H(M5) and K(M3))
/// - Aligning a move creates an extra cell at the start of a branch (in front
///   of node I(M2))
/// - After moves were already aligned, suddenly a move <n> exists in only one
///   branch, but moves <n+1> again exist in multiple branches => The alignment
///   algorithm must not stop when it encounters move <n> (move 4 exists only
///   in node G(M4), but move 5 exists in nodes H(M5) and Q(M5))
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_AlignMoves
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:false alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleBracket];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createAnnotationNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createBlackMoveNodeWithMoveNumber:3]];
  GoNode* nodeF = [self parentNode:nodeE appendChildNode:[self createAnnotationNode]];
  GoNode* nodeG = [self parentNode:nodeF appendChildNode:[self createBlackMoveNodeWithMoveNumber:4]];
  [self parentNode:nodeG appendChildNode:[self createBlackMoveNodeWithMoveNumber:5]];
  GoNode* nodeI = [self parentNode:nodeB appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  GoNode* nodeJ = [self parentNode:nodeI appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeJ appendChildNode:[self createBlackMoveNodeWithMoveNumber:3]];
  GoNode* nodeL = [self parentNode:nodeG appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeL appendChildNode:[self createAnnotationNode]];
  GoNode* nodeN = [self parentNode:nodeI appendChildNode:[self createAnnotationNode]];
  GoNode* nodeO = [self parentNode:nodeN appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeO appendChildNode:[self createBlackMoveNodeWithMoveNumber:3]];
  [self parentNode:nodeL appendChildNode:[self createBlackMoveNodeWithMoveNumber:5]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeC
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeD > nodeE
    [self positionWithX:4 y:0]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:5 y:0]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeE
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeF
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeG
    [self positionWithX:8 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeG > nodeH
    [self positionWithX:9 y:0]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeH
    [self positionWithX:10 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeI
    [self positionWithX:1 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:2 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeI
    [self positionWithX:3 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft| NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeJ
    [self positionWithX:4 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeJ > nodeK
    [self positionWithX:5 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeK
    [self positionWithX:6 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeG > nodeL
    [self positionWithX:8 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeL
    [self positionWithX:9 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft| NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeM
    [self positionWithX:10 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft],
    // nodeI > nodeN
    [self positionWithX:3 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeN
    [self positionWithX:4 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft| NodeTreeViewCellLineCenterToRight],
    // nodeO
    [self positionWithX:5 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeP
    [self positionWithX:6 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeL > nodeQ
    [self positionWithX:9 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeQ
    [self positionWithX:10 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is disabled, the user preference
/// "branching style" is set to bracket, and the user preference "align moves"
/// is enabled. A scenario is tested where aligning moves causes a branch to no
/// longer fit and be moved to a new y-position.
///
/// The following diagrams illustrate the scenario. Legend: R=Root node,
/// M<n>=Move node, A=Annotation node.
/// @verbatim
/// Before alignment:
///
///     A(R)----B(M1)---C(A)----D(A)----E(A)----F(M2)
///               +-----G(M2)     +-----H(M2)
/// x = 0       1       2       3       4       5
///
/// After alignment:
///
/// A(R)----B(M1)---C(A)----D(A)----E(A)----F(M2)
///           |               +-------------H(M2)
///           +-----------------------------G(M2)
/// x = 0       1       2       3       4       5
/// @endverbatim
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_BranchingStyleBracket_AlignMoves_BranchMovedToNewYPosition
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:false alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleBracket];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createAnnotationNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createAnnotationNode]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeE appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  [self parentNode:nodeB appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  [self parentNode:nodeD appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeC
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeE
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeF
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeG
    [self positionWithX:1 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeD > nodeH
    [self positionWithX:3 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:4 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeH
    [self positionWithX:5 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeG
    [self positionWithX:1 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:2 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:3 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:4 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeG
    [self positionWithX:5 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is disabled, the user preference
/// "branching style" is set to diagonal, and the user preference "align moves"
/// is enabled. Two scenarios are tested where aligning moves causes a branch
/// to no longer fit and be moved to a new y-position.
///
/// The following diagrams illustrate the scenarios. Note that the branch
/// going off of A2 would fit on the same line as the one going off of A3
/// because of the space optimization that is possible for diagonal branching.
/// Legend: R=Root node, M<n>=Move node, A=Annotation node.
/// @verbatim
/// Before alignment:
///
///     A(R)----B(M1)---C(A)----D(A)----E(A)----F(A)----G(M2)
///                  \--H(M2)       \---I(M2)\--J(M2)
/// x = 0       1       2       3       4       5       6
///
/// After alignment:
///
///     A(R)----B(M1)---C(A)----D(A)----E(A)----F(A)----G(M2)
///               |               |         \-----------J(M2)
///               |                \--------------------I(M2)
///                \------------------------------------H(M2)
/// x = 0       1       2       3       4       5       6
/// @endverbatim
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_BranchingStyleDiagonal_AlignMoves_BranchMovedToNewYPosition
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:false alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createAnnotationNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createAnnotationNode]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createAnnotationNode]];
  GoNode* nodeF = [self parentNode:nodeE appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeF appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  [self parentNode:nodeB appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  [self parentNode:nodeD appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  [self parentNode:nodeE appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeC
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeE
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottomRight],
    // nodeF
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeG
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeH
    [self positionWithX:1 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeD > nodeI
    [self positionWithX:3 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeE > nodeJ
    [self positionWithX:5 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeJ
    [self positionWithX:6 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeH
    [self positionWithX:1 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeD > nodeI
    [self positionWithX:4 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:5 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeI
    [self positionWithX:6 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeB > nodeH
    [self positionWithX:2 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:3 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:4 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:5 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeH
    [self positionWithX:6 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense tree" is enabled, the user preference
/// "branching style" is set to bracket, and the user preference "align moves"
/// is enabled. The node tree is built so that all scenarios are covered where
/// the algorithm must align move nodes.
///
/// The following diagrams illustrate the scenarios. Legend: R=Root node,
/// M<n>=Move node, A=Annotation node.
/// @verbatim
/// Before alignment:
///
///     uncondensed, x=0-2
///     |       uncondensed, x=3-5
///     |       |       condensed, x=6
///     |       |       |       condensed, x=7
///     |       |       |       |       uncondensed, x=8-10
///     |       |       |       |       |       uncondensed, x=11-13
///     |       |       |       |       |       |       uncondensed, x=14-16
///     |       |       |       |       |       |       |       uncondensed, x=17-19
///     |       |       |       |       |       |       |       |       uncondensed, x=20-22
///     v       v       v       v       v       v       v       v       v
///     A(R)----B(M1)---C(M2)---D(M3)---E(M4)---F(A)----G(M5)---H(A)----I(M6)
///       |                                               +-----J(M6)
///       |     uncondensed, x=3-5                              ^
///       |     |       uncondensed, x=6-8                      uncondensed, x=17-19
///       |     |       |       condensed, x=9
///       |     |       |       |       condensed, x=10
///       |     |       |       |       |       condensed, x=11
///       |     |       |       |       |       |       uncondensed, x=12-14
///       |     v       v       v       v       v       v
///       +-----K(M1)---L(M2)---M(M3)---N(M4)---O(M5)---P(M6)
///               +-----Q(A)
///                     ^
///                     uncondensed, x=6-8
///
/// After alignment:
///
///     uncondensed, x=0-2
///     |       uncondensed, x=3-5
///     |       |       condensed, x=7, aligned+1
///     |       |       |       condensed, x=9, aligned+1 (after shifting+1)
///     |       |       |       |       uncondensed, x=10-12
///     |       |       |       |       |       uncondensed, x=13-15
///     |       |       |       |       |       |       uncondensed, x=16-18
///     |       |       |       |       |       |       |       uncondensed, x=19-21
///     |       |       |       |       |       |       |       |       uncondensed, x=22-24
///     v       v       v       v       v       v       v       v       v
///     A(R)----B(M1)---C(M2)---D(M3)---E(M4)---F(A)----G(M5)---H(A)----I(M6)
///       |                                               +-------------J(M6)
///       |     uncondensed, x=3-5                                      ^
///       |     |       uncondensed, x=6-8                              uncondensed, x=22-24, aligned+3 (after shifting+2)
///       |     |       |       condensed, x=9
///       |     |       |       |       condensed, x=11, aligned+1
///       |     |       |       |       |               condensed, x=17, aligned+5 (after shifting+1)
///       |     |       |       |       |               |               uncondensed, x=22-24, aligned+4 (after shifting+6)
///       |     v       v       v       v               v               v
///       +-----K(M1)---L(M2)---M(M3)---N(M4)-----------O(M5)-----------P(M6)
///               +-----Q(A)
///                     ^
///                     uncondensed, x=6-8
/// @endverbatim
///
/// Scenarios that are covered in this test:
/// - A condensed move node on the parent branch is aligned with an uncondensed
///   move node on a child branch (C(M2))
/// - A condensed move node on a child branch is aligned with an uncondensed
///   move node on the parent branch (N(M4) and O(M5))
/// - A condensed move node is aligned with another condensed move node (D(M3))
/// - An uncondensed move node is aligned with another uncondensed move node
///   (J(M6) and P(M6))
/// - An uncondensed move node is aligned with another uncondensed move node,
///   causing a branching line to be extended (J(M6))
///
/// Note that under the current condensation rules (only move nodes within an
/// uninterrupted sequence of move nodes are condensed, and then only if they
/// are not branching nodes or a child of a branching node) it is NOT possible
/// for an uncondensed move node to be aligned with a condensed move node.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_BranchingStyleBracket_AlignMoves
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condensedTree:true alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleBracket];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createBlackMoveNodeWithMoveNumber:3]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createBlackMoveNodeWithMoveNumber:4]];
  GoNode* nodeF = [self parentNode:nodeE appendChildNode:[self createAnnotationNode]];
  GoNode* nodeG = [self parentNode:nodeF appendChildNode:[self createBlackMoveNodeWithMoveNumber:5]];
  GoNode* nodeH = [self parentNode:nodeG appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeH appendChildNode:[self createBlackMoveNodeWithMoveNumber:6]];
  [self parentNode:nodeG appendChildNode:[self createBlackMoveNodeWithMoveNumber:6]];
  GoNode* nodeK = [self parentNode:nodeA appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  GoNode* nodeL = [self parentNode:nodeK appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  GoNode* nodeM = [self parentNode:nodeL appendChildNode:[self createBlackMoveNodeWithMoveNumber:3]];
  GoNode* nodeN = [self parentNode:nodeM appendChildNode:[self createBlackMoveNodeWithMoveNumber:4]];
  GoNode* nodeO = [self parentNode:nodeN appendChildNode:[self createBlackMoveNodeWithMoveNumber:5]];
  [self parentNode:nodeO appendChildNode:[self createBlackMoveNodeWithMoveNumber:6]];
  [self parentNode:nodeK appendChildNode:[self createAnnotationNode]];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty part:0],
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeB
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeB > nodeC
    [self positionWithX:6 y:0]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeC
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeC > nodeD
    [self positionWithX:8 y:0]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeD
    [self positionWithX:9 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeE
    [self positionWithX:10 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:11 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:12 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeF
    [self positionWithX:13 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:14 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:15 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeG
    [self positionWithX:16 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:17 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:18 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeH
    [self positionWithX:19 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:20 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:21 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeI
    [self positionWithX:22 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:23 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:24 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeA > nodeK
    [self positionWithX:1 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeG > nodeJ
    [self positionWithX:17 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:18 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:19 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:20 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:21 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeJ
    [self positionWithX:22 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:23 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:24 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeA > nodeK
    [self positionWithX:1 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:2 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeK
    [self positionWithX:3 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:4 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:5 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeL
    [self positionWithX:6 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:8 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeM
    [self positionWithX:9 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeM > nodeN
    [self positionWithX:10 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeN
    [self positionWithX:11 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeN > nodeO
    [self positionWithX:12 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:13 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:14 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:15 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:16 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeO
    [self positionWithX:17 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeO > nodeP
    [self positionWithX:18 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:19 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:20 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:21 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeP
    [self positionWithX:22 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:23 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:24 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeK > nodeQ
    [self positionWithX:4 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:5 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeQ
    [self positionWithX:6 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:8 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations part:2],
  };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when a
/// game variation that is not the main branch is selected.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_LinesSelectedGameVariation
{
  // TODO xxx Branch selection not yet implemented in NodeTreeViewCanvas
}

#pragma mark - Helper methods - Configure NodeTreeViewModel

// -----------------------------------------------------------------------------
/// @brief Helper method that configures @a model with @a condensedTree.
/// Move nodes are not aligned and the branching style is set to bracket.
// -----------------------------------------------------------------------------
- (void) setupModel:(NodeTreeViewModel*)model condensedTree:(bool)condensedTree
{
  [self setupModel:model condensedTree:condensedTree alignMoveNodes:false branchingStyle:NodeTreeViewBranchingStyleBracket];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that configures @a model with @a condensedTree and
/// @a branchingStyle. Move nodes are not aligned.
// -----------------------------------------------------------------------------
- (void) setupModel:(NodeTreeViewModel*)model
      condensedTree:(bool)condensedTree
     branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  [self setupModel:model condensedTree:condensedTree alignMoveNodes:false branchingStyle:branchingStyle];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that configures @a model with @a condensedTree,
/// @a alignMoveNodes and @a branchingStyle. The number of cells of a multipart
/// is set to 3.
// -----------------------------------------------------------------------------
- (void) setupModel:(NodeTreeViewModel*)model
      condensedTree:(bool)condensedTree
     alignMoveNodes:(bool)alignMoveNodes
     branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  model.condenseTree = condensedTree;
  model.alignMoveNodes = alignMoveNodes;
  model.branchingStyle = branchingStyle;
  model.numberOfCellsOfMultipartCell = 3;
}

#pragma mark - Helper methods - Create NodeTreeViewCellPosition objects

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCellPosition object.
// -----------------------------------------------------------------------------
- (NodeTreeViewCellPosition*) positionWithX:(unsigned short)x y:(unsigned short)y
{
  return [NodeTreeViewCellPosition positionWithX:x y:y];
}

#pragma mark - Helper methods - Create NodeTreeViewCell objects

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is a
/// standalone cell. The cell contains the specified symbol and no lines. The
/// cell is unselected and contains no selected lines.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
{
  return [self cellWithSymbol:symbol
                        lines:NodeTreeViewCellLineNone];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is a
/// standalone cell. The cell contains no symbol and the specified lines. The
/// cell is unselected and contains no selected lines.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithLines:(NodeTreeViewCellLines)lines
{
  return [self cellWithSymbol:NodeTreeViewCellSymbolNone
                        lines:lines];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is a
/// standalone cell. The cell contains the specified symbol and lines. The cell
/// is unselected and contains no selected lines.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                               lines:(NodeTreeViewCellLines)lines
{
  return [self cellWithSymbol:symbol
                     selected:false
                        lines:lines
   linesSelectedGameVariation:NodeTreeViewCellLineNone
                         part:0
                        parts:1];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell contains the specified symbol
/// and no lines. The cell is unselected and contains no selected lines. The
/// number of cells of a multipart cell is taken from the current
/// NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                                part:(int)part
{
  return [self cellWithSymbol:symbol
                        lines:NodeTreeViewCellLineNone
                         part:part];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell contains no symbol and the
/// specified lines. The cell is unselected and contains no selected lines. The
/// number of cells of a multipart cell is taken from the current
/// NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithLines:(NodeTreeViewCellLines)lines
                               part:(int)part
{
  return [self cellWithSymbol:NodeTreeViewCellSymbolNone
                        lines:lines
                         part:part];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell contains the specified symbol
/// and lines. The cell is unselected and contains no selected lines. The
/// number of cells of a multipart cell is taken from the current
/// NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                               lines:(NodeTreeViewCellLines)lines
                                part:(int)part
{
  return [self cellWithSymbol:symbol
                     selected:false
                        lines:lines
   linesSelectedGameVariation:NodeTreeViewCellLineNone
                         part:part
                        parts:m_delegate.nodeTreeViewModel.numberOfCellsOfMultipartCell];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object with the
/// specified property values.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                            selected:(bool)selected
                               lines:(NodeTreeViewCellLines)lines
          linesSelectedGameVariation:(NodeTreeViewCellLines)linesSelectedGameVariation
                                part:(int)part
                               parts:(int)parts
{
  NodeTreeViewCell* cell = [[[NodeTreeViewCell alloc] init] autorelease];
  cell.symbol = symbol;
  cell.selected = selected;
  cell.lines = lines;
  cell.linesSelectedGameVariation = linesSelectedGameVariation;
  cell.part = part;
  cell.parts = parts;
  return cell;
}

#pragma mark - Helper methods - Create GoNode objects

// -----------------------------------------------------------------------------
/// @brief Helper method that appends @a childNode to @a parentNode and returns
/// @a childNode.
// -----------------------------------------------------------------------------
- (GoNode*) parentNode:(GoNode*)parentNode appendChildNode:(GoNode*)childNode
{
  [parentNode appendChild:childNode];
  return childNode;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that is empty.
// -----------------------------------------------------------------------------
- (GoNode*) createEmptyNode
{
  return [GoNode node];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains setup
/// information that matches @e symbol.
// -----------------------------------------------------------------------------
- (GoNode*) createSetupNodeForSymbol:(enum NodeTreeViewCellSymbol)symbol
{
  GoNode* node = [GoNode node];
  node.goNodeSetup = [self createNodeSetupForSymbol:symbol];
  return node;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNodeSetup object that contains setup
/// information that matches @e symbol.
// -----------------------------------------------------------------------------
- (GoNodeSetup*) createNodeSetupForSymbol:(enum NodeTreeViewCellSymbol)symbol
{
  GoNodeSetup* nodeSetup = [[[GoNodeSetup alloc] init] autorelease];

  switch (symbol)
  {
    case NodeTreeViewCellSymbolBlackSetupStones:
      [nodeSetup setupValidatedBlackStones:@[[m_game.board pointAtVertex:@"A1"]]];
      break;
    case NodeTreeViewCellSymbolWhiteSetupStones:
      [nodeSetup setupValidatedWhiteStones:@[[m_game.board pointAtVertex:@"A1"]]];
      break;
    case NodeTreeViewCellSymbolNoSetupStones:
      [nodeSetup setupValidatedNoStones:@[[m_game.board pointAtVertex:@"A1"]]];
      break;
    case NodeTreeViewCellSymbolBlackAndWhiteSetupStones:
      [nodeSetup setupValidatedBlackStones:@[[m_game.board pointAtVertex:@"A1"]]];
      [nodeSetup setupValidatedWhiteStones:@[[m_game.board pointAtVertex:@"A1"]]];
      break;
    case NodeTreeViewCellSymbolBlackAndNoSetupStones:
      [nodeSetup setupValidatedBlackStones:@[[m_game.board pointAtVertex:@"A1"]]];
      [nodeSetup setupValidatedNoStones:@[[m_game.board pointAtVertex:@"A1"]]];
      break;
    case NodeTreeViewCellSymbolWhiteAndNoSetupStones:
      [nodeSetup setupValidatedWhiteStones:@[[m_game.board pointAtVertex:@"A1"]]];
      [nodeSetup setupValidatedNoStones:@[[m_game.board pointAtVertex:@"A1"]]];
      break;
    case NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones:
      [nodeSetup setupValidatedBlackStones:@[[m_game.board pointAtVertex:@"A1"]]];
      [nodeSetup setupValidatedWhiteStones:@[[m_game.board pointAtVertex:@"A1"]]];
      [nodeSetup setupValidatedNoStones:@[[m_game.board pointAtVertex:@"A1"]]];
      break;
    default:
      XCTAssertTrue(false, @"Symbol type with no setup specified: %d", symbol);
      break;
  }

  return nodeSetup;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains a black
/// move. The move has the move number 1.
// -----------------------------------------------------------------------------
- (GoNode*) createBlackMoveNode
{
  return [self createMoveNodeForPlayer:m_game.playerBlack moveNumber:1];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains a black
/// move. The move has the specified move number.
// -----------------------------------------------------------------------------
- (GoNode*) createBlackMoveNodeWithMoveNumber:(int)moveNumber
{
  return [self createMoveNodeForPlayer:m_game.playerBlack moveNumber:moveNumber];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains a white
/// move. The move has the move number 1.
// -----------------------------------------------------------------------------
- (GoNode*) createWhiteMoveNode
{
  return [self createMoveNodeForPlayer:m_game.playerWhite moveNumber:1];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains a white
/// move. The move has the specified move number.
// -----------------------------------------------------------------------------
- (GoNode*) createWhiteMoveNodeWithMoveNumber:(int)moveNumber
{
  return [self createMoveNodeForPlayer:m_game.playerWhite moveNumber:moveNumber];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains a move
/// made by @a player. The move has the specified move number.
// -----------------------------------------------------------------------------
- (GoNode*) createMoveNodeForPlayer:(GoPlayer*)player moveNumber:(int)moveNumber
{
  GoNode* node = [GoNode nodeWithMove:[self createMoveForPlayer:player moveNumber:moveNumber]];
  return node;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoMove object for a move made by
/// @a player. The move has the specified move number.
// -----------------------------------------------------------------------------
- (GoMove*) createMoveForPlayer:(GoPlayer*)player moveNumber:(int)moveNumber
{
  // For node tree view purposes it doesn't matter that the move's predecessor
  // move is not correctly set up: Only the node tree structure is relevant.
  GoMove* move = [GoMove move:GoMoveTypePass by:player after:nil];
  move.moveNumber = moveNumber;
  return move;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains some node
/// annotations.
// -----------------------------------------------------------------------------
- (GoNode*) createAnnotationNode
{
  GoNode* node = [GoNode node];
  node.goNodeAnnotation = [self createNodeAnnotation];
  return node;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNodeAnnotation object with some node
/// annotations.
// -----------------------------------------------------------------------------
- (GoNodeAnnotation*) createNodeAnnotation
{
  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  nodeAnnotation.shortDescription = @"foo";
  return nodeAnnotation;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains node markup.
// -----------------------------------------------------------------------------
- (GoNode*) createMarkupNode
{
  GoNode* node = [GoNode node];
  node.goNodeMarkup = [self createNodeMarkup];
  return node;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNodeMarkup object with some node
/// markup.
// -----------------------------------------------------------------------------
- (GoNodeMarkup*) createNodeMarkup
{
  GoNodeMarkup* nodeMarkup = [[[GoNodeMarkup alloc] init] autorelease];
  [nodeMarkup setSymbol:GoMarkupSymbolSquare atVertex:@"A1"];
  return nodeMarkup;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains annotations
/// and markup.
// -----------------------------------------------------------------------------
- (GoNode*) createAnnotationsAndMarkupNode
{
  GoNode* node = [GoNode node];
  node.goNodeAnnotation = [self createNodeAnnotation];
  node.goNodeMarkup = [self createNodeMarkup];
  return node;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains setup
/// information that matches @e symbol, plus annotations and markup.
// -----------------------------------------------------------------------------
- (GoNode*) createSetupNodeWithAnnotationsAndMarkupForSymbol:(enum NodeTreeViewCellSymbol)symbol
{
  GoNode* node = [self createSetupNodeForSymbol:symbol];
  node.goNodeAnnotation = [self createNodeAnnotation];
  node.goNodeMarkup = [self createNodeMarkup];
  return node;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains a black
/// move, annotations and markup.
// -----------------------------------------------------------------------------
- (GoNode*) createBlackMoveNodeWithAnnotationsAndMarkup
{
  GoNode* node = [self createBlackMoveNode];
  node.goNodeAnnotation = [self createNodeAnnotation];
  node.goNodeMarkup = [self createNodeMarkup];
  return node;
}

@end
