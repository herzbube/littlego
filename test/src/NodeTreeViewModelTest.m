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
#import "NodeTreeViewModelTest.h"

// Application includes
#import <main/ApplicationDelegate.h>
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoMove.h>
#import <go/GoNodeAdditions.h>
#import <go/GoNodeAnnotation.h>
#import <go/GoNodeMarkup.h>
#import <go/GoNodeModel.h>
#import <go/GoNodeSetup.h>
#import <play/model/NodeTreeViewModel.h>
#import <play/model/NodeTreeViewModelAdditions.h>
#import <play/nodetreeview/NodeTreeViewCell.h>
#import <play/nodetreeview/NodeTreeViewCellPosition.h>


@implementation NodeTreeViewModelTest

#pragma mark - Test methods

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// node tree is minimal and consists of only a root node, and the user
/// preference "condense tree" is disabled.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_RootNodeOnly
{
  // Arrange
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:false];

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* expectedCellsDictionary = @{ [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty] };
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// node tree is minimal and consists of only a root node, and the user
/// preference "condense tree" is enabled.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_RootNodeOnly
{
  // Arrange
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:true];

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
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is enabled. The node tree is built so that
/// all scenarios are covered where the algorithm must decide between generating
/// a condensed or uncondensed node.
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
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:true];
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
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is disabled. The node tree is built so that
/// the algorithm must generate each value in the enumeration
/// #NodeTreeViewCellSymbol at least once.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_NodeSymbols
{
  // Arrange
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:false];
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
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is disabled and there is a selected node.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_Selected
{
  // TODO xxx Node selection not yet implemented in NodeTreeViewModel
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is enabled and there is a selected node.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_Selected
{
  // TODO xxx Node selection not yet implemented in NodeTreeViewModel
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is disabled and the user preference
/// "branching style" is set to diagonal. The node tree is built so all
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
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:false branchingStyle:NodeTreeViewBranchingStyleDiagonal];
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
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is disabled and the user preference
/// "branching style" is set bracket. The node tree is built so all
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
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:false branchingStyle:NodeTreeViewBranchingStyleBracket];
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
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is enabled and the user preference
/// "branching style" is set to diagonal. The node tree is built so all
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
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
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
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is enabled, multipart cells are extra-wide,
/// and the user preference "branching style" is set to diagonal.
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
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  testee.numberOfCellsOfMultipartCell = 5;
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
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is enabled and the user preference
/// "branching style" is set to bracket. The node tree is built so all
/// scenarios are covered where the algorithm must decide between the different
/// bracket line options.
///
/// See testCalculateCanvas_UncondensedTree_BranchingStyleBracket_Lines()
/// for details on the possible options.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_BranchingStyleBracket_Lines
{
  // Arrange
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;
  [self setupModel:testee condensedTree:true branchingStyle:NodeTreeViewBranchingStyleBracket];
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
  XCTAssertEqualObjects([testee getCellsDictionary], expectedCellsDictionary);}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is disabled and the user preference
/// "align moves" is enabled. The node tree is built so all scenarios are
/// covered where the algorithm must align moves.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_UncondensedTree_AlignMoves
{
  // Arrange
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* cellsDictionary = [testee getCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when the
/// user preference "condense tree" is enabled and the user preference
/// "align moves" is enabled. The node tree is built so all scenarios are
/// covered where the algorithm must align moves.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_CondensedTree_AlignMoves
{
  // Arrange
  NodeTreeViewModel* testee = m_delegate.nodeTreeViewModel;

  // Act
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeLayoutDidChange object:nil];

  // Assert
  NSDictionary* cellsDictionary = [testee getCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewModel's canvas calculation algorithm, when a
/// game variation that is not the main branch is selected.
// -----------------------------------------------------------------------------
- (void) testCalculateCanvas_LinesSelectedGameVariation
{
  // TODO xxx Branch selection not yet implemented in NodeTreeViewModel
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
/// move.
// -----------------------------------------------------------------------------
- (GoNode*) createBlackMoveNode
{
  return [self createMoveNodeForPlayer:m_game.playerBlack];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains a white
/// move.
// -----------------------------------------------------------------------------
- (GoNode*) createWhiteMoveNode
{
  return [self createMoveNodeForPlayer:m_game.playerWhite];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoNode object that contains a move
/// made by @a player.
// -----------------------------------------------------------------------------
- (GoNode*) createMoveNodeForPlayer:(GoPlayer*)player
{
  GoNode* node = [GoNode nodeWithMove:[self createMoveForPlayer:player]];
  return node;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoMove object for a move made by
/// @a player.
// -----------------------------------------------------------------------------
- (GoMove*) createMoveForPlayer:(GoPlayer*)player
{
  // For node tree view purposes it doesn't matter that the move's predecessor
  // move is not correctly set up: Only the node tree structure is relevant.
  GoMove* move = [GoMove move:GoMoveTypePass by:player after:nil];
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
