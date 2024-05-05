// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import <go/GoBoardPosition.h>
#import <go/GoGame.h>
#import <go/GoMove.h>
#import <go/GoMoveAdditions.h>
#import <go/GoMoveNodeCreationOptions.h>
#import <go/GoNodeAdditions.h>
#import <go/GoNodeAnnotation.h>
#import <go/GoNodeMarkup.h>
#import <go/GoNodeModel.h>
#import <go/GoNodeSetup.h>
#import <play/model/NodeTreeViewModel.h>
#import <play/nodetreeview/canvas/NodeNumbersViewCell.h>
#import <play/nodetreeview/canvas/NodeTreeViewCanvas.h>
#import <play/nodetreeview/canvas/NodeTreeViewCanvasAdditions.h>
#import <play/nodetreeview/canvas/NodeTreeViewCell.h>
#import <play/nodetreeview/canvas/NodeTreeViewCellPosition.h>


@implementation NodeTreeViewCanvasTest

#pragma mark - Test methods

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the NodeTreeViewCanvas object after a new
/// instance has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;

  // Act
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Assert
  XCTAssertTrue(CGSizeEqualToSize(testee.canvasSize, CGSizeZero));
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the node tree is minimal and consists of only a root node, and the user
/// preference "condense move nodes" is disabled.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_UncondenseMoveNodes_RootNodeOnly
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary = @{ [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi] };
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the node tree is minimal and consists of only a root node, and the user
/// preference "condense move nodes" is enabled.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_CondenseMoveNodes_RootNodeOnly
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:0],
    [self positionWithX:1 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:1],
    [self positionWithX:2 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:2],
  };
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is enabled. The node tree is built
/// so that all scenarios are covered where the algorithm must decide between
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
- (void) testRecalculateCanvas_CondenseMoveNodes_UncondensedNodes
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // rootNode
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:0],
    [self positionWithX:1 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:2 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is disabled. The node tree is
/// built so that the algorithm must generate each value in the enumeration
/// #NodeTreeViewCellSymbol at least once.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_NodeSymbols
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is disabled and there is a
/// selected node.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_UncondenseMoveNodes_Selected
{
  // Arrange
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeB
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeC
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeD

  m_game.boardPosition.currentBoardPosition = 2;  // select nodeC

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolKomi linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToRight],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeC
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove
                                            selected:true
                                               lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight
                          linesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight
                                                part:0
                                               parts:1],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolEmpty linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft],
  };
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is enabled and there is a
/// selected node.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_CondenseMoveNodes_Selected
{
  // Arrange
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeB
  [m_game play:[m_game.board pointAtVertex:@"B1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeC
  [m_game play:[m_game.board pointAtVertex:@"C1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeD
  [m_game play:[m_game.board pointAtVertex:@"D1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeE
  [m_game play:[m_game.board pointAtVertex:@"E1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeF
  [m_game play:[m_game.board pointAtVertex:@"F1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeG

  m_game.boardPosition.currentBoardPosition = 3;  // select nodeD

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolKomi part:0],
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolKomi linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolKomi linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeB
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeC
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeD
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove
                                            selected:true
                                               lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight
                          linesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight
                                                part:0
                                               parts:1],
    // nodeE
    [self positionWithX:8 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeF
    [self positionWithX:9 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeG
    [self positionWithX:10 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:11 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:12 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolWhiteMove part:2],
  };
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// a branch's y-position is increased by its sibling branches. The user
/// preferences "condense move nodes" and "branching style" are not relevant
/// for this test case because they have no particular influence on the part of
/// the algorithm that is under test.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like. Important is that not only the branch with node G is pushed down by
/// the branch with node F, but the branches with nodes H and I as well. An
/// initial simplistic implementation of the algorithm did not take this
/// cascading scenario into account properly.
/// @verbatim
/// A---B---C---D---E
/// |   |   |   +---F
/// |   |   +---G
/// |   +---H
/// +---I
/// @endverbatim
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_BranchIsPushedDownBySiblingBranch
{
  // Arrange
  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeD appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeD appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeC appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeB appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false branchingStyle:NodeTreeViewBranchingStyleRightAngle];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeC
    [self positionWithX:2 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom],
    // nodeE
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeA > nodeI
    [self positionWithX:0 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeB > nodeH
    [self positionWithX:1 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeC > nodeG
    [self positionWithX:2 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeD > nodeF
    [self positionWithX:3 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeF
    [self positionWithX:4 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeA > nodeI
    [self positionWithX:0 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeB > nodeH
    [self positionWithX:1 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeC > nodeG
    [self positionWithX:2 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeG
    [self positionWithX:3 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeA > nodeI
    [self positionWithX:0 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeB > nodeH
    [self positionWithX:1 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeH
    [self positionWithX:2 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
    // nodeA > nodeI
    [self positionWithX:0 y:4]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToRight],
    // nodeI
    [self positionWithX:1 y:4]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft],
  };
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is disabled and the user
/// preference "branching style" is set to diagonal. The node tree is built so
/// that all scenarios are covered where the algorithm must decide between the
/// different diagonal line options.
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
- (void) testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleDiagonal_Lines
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is disabled and the user
/// preference "branching style" is set to right-angle. The node tree is built
/// so that all scenarios are covered where the algorithm must decide between
/// the different right-angle line options.
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
/// testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleDiagonal_Lines().
/// The differences are the perpendicular instead of diagonal lines, and that
/// the branch with node J does not fit on the same line as the branch with
/// node K.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleRightAngle_Lines
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false branchingStyle:NodeTreeViewBranchingStyleRightAngle];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is enabled and the user preference
/// "branching style" is set to diagonal. The node tree is built so that all
/// scenarios are covered where the algorithm must decide between the different
/// diagonal line options.
///
/// See testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleDiagonal_Lines()
/// for details on the possible options. The difference is the branch with
/// node J no longer fits on y-position 2, because diagonal branching does not
/// gain sufficient space when multipart cells are involved. See comment in
/// implementation.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_CondenseMoveNodes_BranchingStyleDiagonal_Lines
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:0],
    [self positionWithX:1 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:2 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is enabled, multipart cells are
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
- (void) testRecalculateCanvas_CondenseMoveNodes_ExtraWideMultipartCells_BranchingStyleDiagonal_Lines
{
  // Arrange
  GoNode* nodeA = m_game.nodeModel.rootNode;
  [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];
  [self parentNode:nodeA appendChildNode:[self createBlackMoveNode]];

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  nodeTreeViewModel.numberOfCellsOfMultipartCell = 5;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:0],
    [self positionWithX:1 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:1],
    [self positionWithX:2 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottomRight part:2],
    [self positionWithX:3 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:3],
    [self positionWithX:4 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:4],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is enabled and the user preference
/// "branching style" is set to right-angle. The node tree is built so that all
/// scenarios are covered where the algorithm must decide between the different
/// right-angle line options.
///
/// See
/// testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleRightAngle_Lines()
/// for details on the possible options.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_CondenseMoveNodes_BranchingStyleRightAngle_Lines
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleRightAngle];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:0],
    [self positionWithX:1 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:2 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is disabled and the user
/// preference "align moves" is enabled. The node tree is built so that all
/// scenarios are covered where the algorithm must align move nodes.
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
- (void) testRecalculateCanvas_UncondenseMoveNodes_AlignMoves
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleRightAngle];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is disabled, the user preference
/// "branching style" is set to right-angle, and the user preference
/// "align moves" is enabled. A scenario is tested where aligning moves causes
/// a branch to no longer fit and be moved to a new y-position.
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
- (void) testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleRightAngle_AlignMoves_BranchMovedToNewYPosition
{
  // Arrange
  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createAnnotationNode]];
  GoNode* nodeD = [self parentNode:nodeC appendChildNode:[self createAnnotationNode]];
  GoNode* nodeE = [self parentNode:nodeD appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeE appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  [self parentNode:nodeB appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  [self parentNode:nodeD appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleRightAngle];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is disabled, the user preference
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
- (void) testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleDiagonal_AlignMoves_BranchMovedToNewYPosition
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:false alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises NodeTreeViewCanvas's canvas calculation algorithm, when
/// the user preference "condense move nodes" is enabled, the user preference
/// "branching style" is set to right-angle, and the user preference
/// "align moves" is enabled. The node tree is built so that all scenarios are
/// covered where the algorithm must align move nodes.
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
- (void) testRecalculateCanvas_CondenseMoveNodes_BranchingStyleRightAngle_AlignMoves
{
  // Arrange
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

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleRightAngle];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:0],
    [self positionWithX:1 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:2 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
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
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises the part of NodeTreeViewCanvas's canvas calculation
/// algorithm that calculates the @e linesSelectedGameVariation property value
/// of NodeTreeViewCell objects.
///
/// This is a best-effort attempt to verify all scenarios in a single test.
/// The node tree is built, and the user preferences are selected, to create
/// a "worst case" scenario where all, or at least most, of the algorithm's
/// decisions how to set the @e linesSelectedGameVariation property are covered.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like.
/// @verbatim
///             +-- move node, uncondensed
///             v
/// A---B---C---D       +-- move node, uncondensed, aligned+3 to node N
///     |   |\--E       |   +-- move node, uncondensed
///     |    \--F       v   v
///     |\------G-------H---I
///      \--J   |\--K
///              \--L---M
///             ^    \--N---O---P <-- selected game variation
///             |       ^   ^   ^
///             |       |   |   +-- move node, uncondensed
///             |       |   +-- move node, condensed, aligned+1 (after shifting+3) to node I
///             |       +-- move node, uncondensed
///             +-- move node, uncondensed, aligned+3 to node D
/// @endverbatim
///
/// User preferences:
/// - "condense move nodes" is enabled so that the algorithm has to set lines
///   in sub-cells of multipart cells
/// - "align move nodes" is enabled so that the algorithm has to set lines
///   in standalone cells created on the left of a multipart cell, required to
///   connect to a branching line
/// - diagonal branching style is used because it requires the algorithm to
///   make more complex decisions
///
/// Covered scenarios:
/// - Horizontal lines directly on the right of a node: A
/// - No horizontal lines directly on the right of a node: B (and others)
/// - Horizontal lines directly on the left of a node: B, G, L, N, O, P
/// - No horizontal lines directly on the left of a node: C (and others)
/// - Horizontal lines extending on the left of a node, to connect to a
///   branching line: Left of G
/// - Horizontal lines extending on the left of a node, to connect to a
///   previous node in the same branch: Left of O
/// - Vertical line directly below a node: B
/// - Full vertical line below a node: Below B
/// - Diagonal line branching off from a vertical line below a node: Below B
/// - Diagonal line branching off from a vertical line below a node, and the
///   diagonal line is the last section of the branching line: Below G
/// - Diagonal line directly below a node: L
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_LinesSelectedGameVariation
{
  // Arrange
  GoNode* nodeA = m_game.nodeModel.rootNode;
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createAnnotationNode]];
  GoNode* nodeC = [self parentNode:nodeB appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeC appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  [self parentNode:nodeC appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeC appendChildNode:[self createAnnotationNode]];
  GoNode* nodeG = [self parentNode:nodeB appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  GoNode* nodeH = [self parentNode:nodeG appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  [self parentNode:nodeH appendChildNode:[self createBlackMoveNodeWithMoveNumber:3]];
  [self parentNode:nodeB appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeG appendChildNode:[self createAnnotationNode]];
  GoNode* nodeL = [self parentNode:nodeG appendChildNode:[self createAnnotationNode]];
  [self parentNode:nodeL appendChildNode:[self createAnnotationNode]];
  GoNode* nodeN = [self parentNode:nodeL appendChildNode:[self createBlackMoveNodeWithMoveNumber:2]];
  GoNode* nodeO = [self parentNode:nodeN appendChildNode:[self createBlackMoveNodeWithMoveNumber:3]];
  GoNode* nodeP = [self parentNode:nodeO appendChildNode:[self createBlackMoveNodeWithMoveNumber:4]];
  [m_game.nodeModel changeToVariationContainingNode:nodeP];

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true alignMoveNodes:true branchingStyle:NodeTreeViewBranchingStyleDiagonal];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedCellsDictionary =
  @{
    // nodeA (= rootNode)
    [self positionWithX:0 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi part:0],
    [self positionWithX:1 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:2 y:0]: [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeB
    [self positionWithX:3 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:4 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom linesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:5 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeC
    [self positionWithX:6 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom | NodeTreeViewCellLineCenterToBottomRight part:1],
    [self positionWithX:8 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeD
    [self positionWithX:9 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:11 y:0]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeB > nodeG + nodeJ
    [self positionWithX:4 y:1]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom],
    // nodeC > nodeF
    [self positionWithX:7 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeC > nodeE
    [self positionWithX:8 y:1]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeE
    [self positionWithX:9 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:11 y:1]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations part:2],
    // nodeB > nodeG + nodeJ
    [self positionWithX:4 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottom | NodeTreeViewCellLineCenterToBottomRight linesSelectedGameVariation:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeC > nodeF
    [self positionWithX:8 y:2]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeF
    [self positionWithX:9 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:11 y:2]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations part:2],
    // nodeB > nodeJ
    [self positionWithX:4 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeB > nodeG
    [self positionWithX:5 y:3]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:6 y:3]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:7 y:3]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:8 y:3]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeG
    [self positionWithX:9 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:10 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottom | NodeTreeViewCellLineCenterToBottomRight linesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToBottom part:1],
    [self positionWithX:11 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeG > nodeH
    [self positionWithX:12 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:13 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    [self positionWithX:14 y:3]: [self cellWithLines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeH
    [self positionWithX:15 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:16 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:17 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeI
    [self positionWithX:18 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:19 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:20 y:3]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
    // nodeB > nodeJ
    [self positionWithX:5 y:4]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeJ
    [self positionWithX:6 y:4]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:7 y:4]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:8 y:4]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations part:2],
    // nodeG > nodeL
    [self positionWithX:10 y:4]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToTop | NodeTreeViewCellLineCenterToBottomRight],
    // nodeG > nodeK
    [self positionWithX:11 y:4]: [self cellWithLines:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeK
    [self positionWithX:12 y:4]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:13 y:4]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:14 y:4]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations part:2],
    // nodeG > nodeL
    [self positionWithX:11 y:5]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeL
    [self positionWithX:12 y:5]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:13 y:5]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottomRight linesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToBottomRight part:1],
    [self positionWithX:14 y:5]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeM
    [self positionWithX:15 y:5]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:16 y:5]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations lines:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:17 y:5]: [self cellWithSymbol:NodeTreeViewCellSymbolAnnotations part:2],
    // nodeL > nodeN
    [self positionWithX:14 y:6]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight],
    // nodeN
    [self positionWithX:15 y:6]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:16 y:6]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:1],
    [self positionWithX:17 y:6]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:2],
    // nodeN > nodeO
    [self positionWithX:18 y:6]: [self cellWithLinesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeO
    [self positionWithX:19 y:6]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight],
    // nodeP
    [self positionWithX:20 y:6]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight part:0],
    [self positionWithX:21 y:6]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove linesAndLinesSelectedGameVariation:NodeTreeViewCellLineCenterToLeft part:1],
    [self positionWithX:22 y:6]: [self cellWithSymbol:NodeTreeViewCellSymbolBlackMove part:2],
  };
  [self assertCells:[testee getCellsDictionary] areEqualToExpectedCells:expectedCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises the part of NodeTreeViewCanvas's canvas calculation
/// algorithm that generates node numbers, when the user preferences
/// "condensed move nodes" and "align move nodes" are both disabled.
///
/// The user preference "node number interval" is set to 3.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like. Note: If you change this tree, also adapt
/// testRecalculateCanvas_NodeNumbers_UncondenseMoveNodes_AlignMoves().
///
/// @verbatim
///     +-- selected        +---+-------+-- these three nodes are not move nodes
///     v                   v   v       v
/// 0   1   2   3   4   5   6   7   8   9   10  11  12  13  <-- theoretical node number
/// A---B---C---D---E---F---G---H---I---J---K---L---M---N
///                  \--O---P---Q---R        \--S
///                                 ^
///                                 +-- current game variation
/// @endverbatim
///
/// Covered node numbering rules:
/// - Rule 5: Nodes in the current game variation are considered for numbering.
///   This is the main rule that is implicitly covered by most other rules.
/// - Rule 6: Nodes A, D, and P are numbered because they are part of the
///   current game variation and match the numbering interval. Nodes C and Q are
///   not numbered although they are part of the current game variation, because
///   do not match the numbering interval.
/// - Rule 7: Node R is numbered because it is the leaf node of the current game
///   variation, even though it does not match the numbering interval.
/// - Rule 8: Nodes E and O are numbered because they are a branching node and
///   its child node in the current game variation, even though they do not
///   match the numbering interval. For comparison: The branching node K and its
///   child node S are not numbered because they are not part of the current
///   game variation (and they also do not match the numbering interval).
/// - Rule 9: Nodes J and M are numbered because they are part of the longest
///   game variation, they match the numbering interval, and
///   "condense move nodes" and "align move nodes" are both disabled.
/// - Rule 9: Node N is numbered befause it is the leaf node of the longest game
///   variation, and "condense move nodes" and "align move nodes" are both
///   disabled.
/// - Rule 10: Node B is numbered because it is the selected node, even though
///   it does not match the numbering interval.
///
/// Rules 1-4 are not relevant for this test because "condense move nodes" is
/// not enabled in this test.
///
/// As a side effect, this test also shows that the following things have no
/// effect on node numbering:
/// - Consecutive move nodes do not affect node numbering because
///   "condense move nodes" is disabled.
/// - Nodes that are not move nodes (G, H, J) do not affect node numbering.
///   This has nothing to do with "align move nodes" being disabled. In the next
///   test it is shown that even when "align move nodes" is enabled it has no
///   effect on node numbering.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_NodeNumbers_UncondenseMoveNodes
{
  // Arrange
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeB
  [m_game play:[m_game.board pointAtVertex:@"B1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeC
  [m_game play:[m_game.board pointAtVertex:@"C1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeD
  [m_game play:[m_game.board pointAtVertex:@"D1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeE
  [m_game play:[m_game.board pointAtVertex:@"E1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeF
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeG
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeH
  [m_game play:[m_game.board pointAtVertex:@"H1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeI
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeH
  [m_game play:[m_game.board pointAtVertex:@"K1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeK
  [m_game play:[m_game.board pointAtVertex:@"L1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeL
  [m_game play:[m_game.board pointAtVertex:@"M1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeM
  [m_game play:[m_game.board pointAtVertex:@"N1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeN

  m_game.boardPosition.currentBoardPosition = 10;  // select nodeK
  [m_game play:[m_game.board pointAtVertex:@"Q1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeS

  m_game.boardPosition.currentBoardPosition = 4;  // select nodeE
  [m_game play:[m_game.board pointAtVertex:@"M1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeO
  [m_game play:[m_game.board pointAtVertex:@"N1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeP
  [m_game play:[m_game.board pointAtVertex:@"O1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeQ
  [m_game play:[m_game.board pointAtVertex:@"P1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeR

  m_game.boardPosition.currentBoardPosition = 1;  // select nodeB

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  nodeTreeViewModel.nodeNumberInterval = 3;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedNodeNumbersViewCellsDictionary =
  @{
    // nodeA
    [self positionWithX:0 y:0]: [self cellWithNodeNumber:0],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithNodeNumber:1 selected:true part:0 nodeNumberExistsOnlyForSelection:true],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithNodeNumber:3],
    // nodeE
    [self positionWithX:4 y:0]: [self cellWithNodeNumber:4],
    // nodeO
    [self positionWithX:5 y:0]: [self cellWithNodeNumber:5],
    // nodeP
    [self positionWithX:6 y:0]: [self cellWithNodeNumber:6],
    // nodeR
    [self positionWithX:8 y:0]: [self cellWithNodeNumber:8],
    // nodeJ
    [self positionWithX:9 y:0]: [self cellWithNodeNumber:9],
    // nodeM
    [self positionWithX:12 y:0]: [self cellWithNodeNumber:12],
    // nodeN
    [self positionWithX:13 y:0]: [self cellWithNodeNumber:13],
  };
  [self assertNodeNumbersViewCells:[testee getNodeNumbersViewCellsDictionary] areEqualToExpectedCells:expectedNodeNumbersViewCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises the part of NodeTreeViewCanvas's canvas calculation
/// algorithm that generates node numbers, when the user preference
/// "condensed move nodes" is disabled and the user preference
/// "align move nodes" is enabled.
///
/// The user preference "node number interval" is set to 3.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like. Note: The tree content is exactly the same as for
/// testRecalculateCanvas_NodeNumbers_UncondenseMoveNodes(), the only difference
/// is that the effect of "align move nodes" enabled is visually shown in the
/// diagram.
///
/// @verbatim
///     +-- selected        +---+-------+-- these three nodes are not move nodes
///     v                   v   v       v
/// A---B---C---D---E---F---G---H---I---J---K---L---M---N
///                  \--O-----------P-------Q---R    \--S
/// 0   1   2   3   4   5           6       7   8  <-- theoretical node number
///                                             ^
///                                             +-- current game variation
/// @endverbatim
///
/// Covered node numbering rules:
/// - Rules 5-8 and 10: Same as in
///   testRecalculateCanvas_NodeNumbers_UncondenseMoveNodes().
/// - Rule 9: Nodes J, M and N are not numbered because they are part of the
///   longest game variation, but nodes in that game variation are not numbered
///   due to "align move nodes" being enabled.
/// - Because "align move node" is enabled the x-position of the node number of
///   nodes P and R is different from the x-position of the node number of these
///   nodes in testRecalculateCanvas_NodeNumbers_UncondenseMoveNodes().
///
/// Rules 1-4 are not relevant for this test because "condense move nodes" is
/// not enabled in this test.
///
/// As a side effect, this test also shows that the following things have no
/// effect on node numbering:
/// - Consecutive move nodes do not affect node numbering because
///   "condense move nodes" is disabled.
/// - Aligning move nodes has no effect on node numbering, even though aligning
///   move nodes causes nodes to be visually rendered in a different horizontal
///   position. Node numbers are incremented one by one just as usual.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_NodeNumbers_UncondenseMoveNodes_AlignMoves
{
  // Arrange
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeB
  [m_game play:[m_game.board pointAtVertex:@"B1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeC
  [m_game play:[m_game.board pointAtVertex:@"C1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeD
  [m_game play:[m_game.board pointAtVertex:@"D1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeE
  [m_game play:[m_game.board pointAtVertex:@"E1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeF
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeG
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeH
  [m_game play:[m_game.board pointAtVertex:@"H1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeI
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeH
  [m_game play:[m_game.board pointAtVertex:@"K1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeK
  [m_game play:[m_game.board pointAtVertex:@"L1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeL
  [m_game play:[m_game.board pointAtVertex:@"M1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeM
  [m_game play:[m_game.board pointAtVertex:@"N1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeN

  m_game.boardPosition.currentBoardPosition = 10;  // select nodeK
  [m_game play:[m_game.board pointAtVertex:@"Q1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeS

  m_game.boardPosition.currentBoardPosition = 4;  // select nodeE
  [m_game play:[m_game.board pointAtVertex:@"M1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeO
  [m_game play:[m_game.board pointAtVertex:@"N1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeP
  [m_game play:[m_game.board pointAtVertex:@"O1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeQ
  [m_game play:[m_game.board pointAtVertex:@"P1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeR

  m_game.boardPosition.currentBoardPosition = 1;  // select nodeB

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  nodeTreeViewModel.nodeNumberInterval = 3;
  nodeTreeViewModel.alignMoveNodes = true;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedNodeNumbersViewCellsDictionary =
  @{
    // nodeA
    [self positionWithX:0 y:0]: [self cellWithNodeNumber:0],
    // nodeB
    [self positionWithX:1 y:0]: [self cellWithNodeNumber:1 selected:true part:0 nodeNumberExistsOnlyForSelection:true],
    // nodeD
    [self positionWithX:3 y:0]: [self cellWithNodeNumber:3],
    // nodeE
    [self positionWithX:4 y:0]: [self cellWithNodeNumber:4],
    // nodeO
    [self positionWithX:5 y:0]: [self cellWithNodeNumber:5],
    // nodeP
    [self positionWithX:8 y:0]: [self cellWithNodeNumber:6],
    // nodeR
    [self positionWithX:11 y:0]: [self cellWithNodeNumber:8],
  };
  [self assertNodeNumbersViewCells:[testee getNodeNumbersViewCellsDictionary] areEqualToExpectedCells:expectedNodeNumbersViewCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises the part of NodeTreeViewCanvas's canvas calculation
/// algorithm that generates node numbers, when the user preferences
/// "condensed move nodes" and "align move nodes" are both enabled.
///
/// The user preference "node number interval" is set to 2.
///
/// This is a best-effort attempt to verify all scenarios in a single test.
/// The node tree is built, and the user preferences are selected, to create
/// a "worst case" scenario where all, or at least most, of the algorithm's
/// decisions how to generate node numbers are covered.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like.
/// @verbatim
///                                                                                         +-- selected
///                                                                                         v
/// A---B*--C*--D---e---F---G*--H*--I---j---k---l---m---n---o---P---Q---R-------s---t---U---V*--W---X  <-- current game variation
///                                                              \   \--Z---A1*-B1--c1--d1--e1--f1--g1--H1
///                                                               \-Y
/// 0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17      18  19  20  21  22  23  <-- theoretical node number
/// ^       ^       ^       ^       ^       ^                   ^   ^   ^       ^       ^   ^   ^   ^
///
/// Legend:
/// - Nodes marked with an asterisk (*) are no moves, i.e. they are uncondensed
/// - Nodes with an uppercase letter and no asterisk (*) are uncondensed move
///   nodes
/// - Nodes with a lowercase letter and no asterisk (*) are condensed move nodes
/// - Node numbers that are expected to be generated are marked with "^"
/// @endverbatim
///
/// Covered node numbering rules:
/// - Rule 1:
///   - Node e is condensed but numbered because it gets sufficient space,
///     because the two surrounding uncondensed nodes D and F are not numbered
///     due to not matching the number interval.
///   - Node k is condensed but numbered because it gets sufficient space,
///     because the two surrounding condensed nodes j and l are not numbered
///     due to not matching the number interval.
///   - Node m is condensed but not numbered because it does not get sufficient
///     space, because the space of the preceding unnumbered condensed node l
///     is used up already for the number of node k.
///   - Node o is condensed but not numbered because it does not get sufficient
///     space, because the subsequent node P is uncondensed and numbered due to
///     it being a branching node.
///   - Node s is condensed but numbered because it gets sufficient space,
///     because due to "align move nodes" it gets shifted so that it has
///     sufficient distance to the previous numbered uncondensed node R, and
///     the following condensed node is not numbered due to not matching number
///     interval.
/// - Rule 2a: Nodes E, K and S are condensed nodes, but their node numbers
///   still take up the width of an uncondensed node.
/// - Rule 2b: All uncondensed nodes, regardless of whether they are move nodes
///   or not, always get sufficient space to be numbered if one of the other
///   rules allows them to be numbered. Applies to nodes A, C, G, I, P, Q, R,
///   U, V, W and X.
/// - Rule 3: This rule cannot be covered with node number interval 2 because
///   two adjacent uncondensed/condensed nodes can never be numbered at the same
///   time due to the number interval. And if the uncondensed node is numbered
///   due to some other rule it can always be argued that it is the other rule
///   that has higher precedence, not the fact that the node is uncondensed.
/// - Rule 4: Node k is numbered, node m is not numbered, because node k is
///   closer to the root node and therefore has precedence.
/// - Rule 5: Nodes in the current game variation are considered for numbering.
///   This is the main rule that is implicitly covered by most other rules.
/// - Rule 6: Nodes A, C, e, G, I, k, Q, s, U and W are numbered because they
///   are part of the current game variation and match the numbering interval.
///   Nodes B, D, F, H, j, l, n and t are not numbered although they are part
///   of the current game variation, because do not match the numbering
///   interval.
///   - Nodes D and F not being numbered is of special interest, because it
///     shows that uncondensed move nodes do not get numbered automatically
///     even though they get sufficient space.
/// - Rule 7: Node X is numbered because it is the leaf node of the current game
///   variation, even though it does not match the numbering interval.
/// - Rule 8: Nodes P and R are numbered even though they do not match the
///   numbering interval, because they are, respectively, a branching node and
///   a child node of a branching node in the current game variation.
/// - Rule 9: Nodes G1 and H1 are not numbered because they are part of the
///   longest game variation, but nodes in that game variation are not numbered
///   due to "condense move nodes" and "align move nodes" being enabled.
/// - Rule 10: Node V is numbered because it is the selected node, even though
///   it does not match the numbering interval.
///
/// As a side effect, this test also shows that the following things have no
/// effect on node numbering:
/// - Aligning move nodes has no effect on node numbering, even though aligning
///   move nodes causes nodes to be visually rendered in a different horizontal
///   position. Node numbers are incremented one by one just as usual.
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_NodeNumbers_CondenseMoveNodes_AlignMoves
{
  // Arrange
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeB
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeC
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeD
  [m_game play:[m_game.board pointAtVertex:@"B1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeE
  [m_game play:[m_game.board pointAtVertex:@"C1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeF
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeG
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeH
  [m_game play:[m_game.board pointAtVertex:@"D1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeI
  [m_game play:[m_game.board pointAtVertex:@"E1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeJ
  [m_game play:[m_game.board pointAtVertex:@"F1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeK
  [m_game play:[m_game.board pointAtVertex:@"G1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeL
  [m_game play:[m_game.board pointAtVertex:@"H1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeM
  [m_game play:[m_game.board pointAtVertex:@"J1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeN
  [m_game play:[m_game.board pointAtVertex:@"K1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeO
  [m_game play:[m_game.board pointAtVertex:@"L1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeP
  [m_game play:[m_game.board pointAtVertex:@"M1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeQ
  [m_game play:[m_game.board pointAtVertex:@"N1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeR

  [m_game play:[m_game.board pointAtVertex:@"O1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeS
  [m_game play:[m_game.board pointAtVertex:@"P1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeT
  [m_game play:[m_game.board pointAtVertex:@"Q1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeU
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeV
  [m_game play:[m_game.board pointAtVertex:@"R1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeW
  [m_game play:[m_game.board pointAtVertex:@"S1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeX

  m_game.boardPosition.currentBoardPosition = 16;  // select nodeQ
  [m_game play:[m_game.board pointAtVertex:@"N1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeZ
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeA1
  [m_game play:[m_game.board pointAtVertex:@"O1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeB1
  [m_game play:[m_game.board pointAtVertex:@"P1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeC1
  [m_game play:[m_game.board pointAtVertex:@"Q1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeD1
  [m_game play:[m_game.board pointAtVertex:@"R1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeE1
  [m_game play:[m_game.board pointAtVertex:@"S1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeF1
  [m_game play:[m_game.board pointAtVertex:@"T1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeG1
  [m_game play:[m_game.board pointAtVertex:@"A2"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeH1

  m_game.boardPosition.currentBoardPosition = 15;  // select nodeP
  [m_game play:[m_game.board pointAtVertex:@"M1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeY

  m_game.boardPosition.currentBoardPosition = 15;  // select nodeP (part of main variation)
  [m_game.nodeModel changeToMainVariation];
  m_game.boardPosition.numberOfBoardPositions = m_game.nodeModel.numberOfNodes;
  m_game.boardPosition.currentBoardPosition = 21;  // select nodeV

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  nodeTreeViewModel.nodeNumberInterval = 2;
  nodeTreeViewModel.alignMoveNodes = true;
  nodeTreeViewModel.condenseMoveNodes = true;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedNodeNumbersViewCellsDictionary =
  @{
    // nodeA
    [self positionWithX:0 y:0]: [self cellWithNodeNumber:0 part:0],
    [self positionWithX:1 y:0]: [self cellWithNodeNumber:0 part:1],
    [self positionWithX:2 y:0]: [self cellWithNodeNumber:0 part:2],
    // nodeC
    [self positionWithX:6 y:0]: [self cellWithNodeNumber:2 part:0],
    [self positionWithX:7 y:0]: [self cellWithNodeNumber:2 part:1],
    [self positionWithX:8 y:0]: [self cellWithNodeNumber:2 part:2],
    // nodeE - node is condensed but according to rule 2a the node number still
    // takes up 3 cells
    [self positionWithX:11 y:0]: [self cellWithNodeNumber:4 part:0],
    [self positionWithX:12 y:0]: [self cellWithNodeNumber:4 part:1],
    [self positionWithX:13 y:0]: [self cellWithNodeNumber:4 part:2],
    // nodeG
    [self positionWithX:16 y:0]: [self cellWithNodeNumber:6 part:0],
    [self positionWithX:17 y:0]: [self cellWithNodeNumber:6 part:1],
    [self positionWithX:18 y:0]: [self cellWithNodeNumber:6 part:2],
    // nodeI
    [self positionWithX:22 y:0]: [self cellWithNodeNumber:8 part:0],
    [self positionWithX:23 y:0]: [self cellWithNodeNumber:8 part:1],
    [self positionWithX:24 y:0]: [self cellWithNodeNumber:8 part:2],
    // nodeK - node is condensed but according to rule 2a the node number still
    // takes up 3 cells
    [self positionWithX:25 y:0]: [self cellWithNodeNumber:10 part:0],
    [self positionWithX:26 y:0]: [self cellWithNodeNumber:10 part:1],
    [self positionWithX:27 y:0]: [self cellWithNodeNumber:10 part:2],
    // nodeP
    [self positionWithX:31 y:0]: [self cellWithNodeNumber:15 part:0],
    [self positionWithX:32 y:0]: [self cellWithNodeNumber:15 part:1],
    [self positionWithX:33 y:0]: [self cellWithNodeNumber:15 part:2],
    // nodeQ
    [self positionWithX:34 y:0]: [self cellWithNodeNumber:16 part:0],
    [self positionWithX:35 y:0]: [self cellWithNodeNumber:16 part:1],
    [self positionWithX:36 y:0]: [self cellWithNodeNumber:16 part:2],
    // nodeR
    [self positionWithX:37 y:0]: [self cellWithNodeNumber:17 part:0],
    [self positionWithX:38 y:0]: [self cellWithNodeNumber:17 part:1],
    [self positionWithX:39 y:0]: [self cellWithNodeNumber:17 part:2],
    // nodeS - node is condensed but according to rule 2a the node number still
    // takes up 3 cells
    [self positionWithX:43 y:0]: [self cellWithNodeNumber:18 part:0],
    [self positionWithX:44 y:0]: [self cellWithNodeNumber:18 part:1],
    [self positionWithX:45 y:0]: [self cellWithNodeNumber:18 part:2],
    // nodeU
    [self positionWithX:47 y:0]: [self cellWithNodeNumber:20 part:0],
    [self positionWithX:48 y:0]: [self cellWithNodeNumber:20 part:1],
    [self positionWithX:49 y:0]: [self cellWithNodeNumber:20 part:2],
    // nodeV
    [self positionWithX:50 y:0]: [self cellWithNodeNumber:21 selected:true part:0 nodeNumberExistsOnlyForSelection:true],
    [self positionWithX:51 y:0]: [self cellWithNodeNumber:21 selected:true part:1 nodeNumberExistsOnlyForSelection:true],
    [self positionWithX:52 y:0]: [self cellWithNodeNumber:21 selected:true part:2 nodeNumberExistsOnlyForSelection:true],
    // nodeW
    [self positionWithX:53 y:0]: [self cellWithNodeNumber:22 part:0],
    [self positionWithX:54 y:0]: [self cellWithNodeNumber:22 part:1],
    [self positionWithX:55 y:0]: [self cellWithNodeNumber:22 part:2],
    // nodeX
    [self positionWithX:56 y:0]: [self cellWithNodeNumber:23 part:0],
    [self positionWithX:57 y:0]: [self cellWithNodeNumber:23 part:1],
    [self positionWithX:58 y:0]: [self cellWithNodeNumber:23 part:2],
  };
  [self assertNodeNumbersViewCells:[testee getNodeNumbersViewCellsDictionary] areEqualToExpectedCells:expectedNodeNumbersViewCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Excercises the part of NodeTreeViewCanvas's canvas calculation
/// algorithm that generates node numbers, specifically rule 3 of that
/// algorithm, when the user preference "condensed move nodes" is enabled. The
/// value of user preference "align move nodes" is not relevant for this test.
///
/// The user preference "node number interval" is set to 1 because rule 3 can
/// only be tested with this interval: Two adjacent nodes can only be candidates
/// for numbering with interval 1, and rule 3 can only be tested when the
/// condensed and uncondensed nodes are adjacent.
///
/// The following diagram illustrates how the node tree built in this test looks
/// like.
/// @verbatim
///                         +-- not numbered
///                         |       +-- selected
///                         v       v
/// A---B---c---d---e---f---g---H---I*
/// 0   1   2   3   4   5   6   7   8
/// ^   ^       ^               ^   ^
///
/// Legend:
/// - Nodes marked with an asterisk (*) are no moves, i.e. they are uncondensed
/// - Nodes with an uppercase letter and no asterisk (*) are uncondensed move
///   nodes
/// - Nodes with a lowercase letter and no asterisk (*) are condensed move nodes
/// - Node numbers that are expected to be generated are marked with "^"
/// @endverbatim
///
/// Rule 3 stipulates that numbering uncondensed nodes has higher priority than
/// numbering condensed move nodes. If a decision must be made whether to number
/// an uncondensed node or a condensed move node, it is always the uncondensed
/// node that "wins".
///
/// The reasoning behind the setup in this test is this:
/// - Node G should be numbered because it belongs to the current game variation
///   and matches the node number interval (rule 6).
/// - Node G should be numbered because there is sufficient space to display
///   the node number (rule 1) and numbering nodes that are closer to the root
///   node has higher priority than numbering nodes that are farther away from
///   the root node (rule 4).
/// - But effectively node G is not numbered, because rule 3 takes precedence
///   over rule 4 and therefore numbering the uncondensed node H has higher
///   priority than numbering the condensed node G.
/// - Also note that node H is a candidate for numbering solely because it
///   belongs to the current game variation and matches the node number
///   interval. There are no other special rules in play that somehow force the
///   numbering of node H (e.g. it's not the leaf node or a branching node).
// -----------------------------------------------------------------------------
- (void) testRecalculateCanvas_NodeNumbers_CondenseMoveNodes_Rule3
{
  // Arrange
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeB
  [m_game play:[m_game.board pointAtVertex:@"B1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeC
  [m_game play:[m_game.board pointAtVertex:@"C1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeD
  [m_game play:[m_game.board pointAtVertex:@"D1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeE
  [m_game play:[m_game.board pointAtVertex:@"E1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeF
  [m_game play:[m_game.board pointAtVertex:@"F1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeG
  [m_game play:[m_game.board pointAtVertex:@"G1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // nodeH
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeI

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  nodeTreeViewModel.nodeNumberInterval = 1;
  nodeTreeViewModel.condenseMoveNodes = true;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  [testee recalculateCanvas];

  // Assert
  NSDictionary* expectedNodeNumbersViewCellsDictionary =
  @{
    // nodeA
    [self positionWithX:0 y:0]: [self cellWithNodeNumber:0 part:0],
    [self positionWithX:1 y:0]: [self cellWithNodeNumber:0 part:1],
    [self positionWithX:2 y:0]: [self cellWithNodeNumber:0 part:2],
    // nodeB
    [self positionWithX:3 y:0]: [self cellWithNodeNumber:1 part:0],
    [self positionWithX:4 y:0]: [self cellWithNodeNumber:1 part:1],
    [self positionWithX:5 y:0]: [self cellWithNodeNumber:1 part:2],
    // nodeD - node is condensed but according to rule 2a the node number still
    // takes up 3 cells
    [self positionWithX:6 y:0]: [self cellWithNodeNumber:3 part:0],
    [self positionWithX:7 y:0]: [self cellWithNodeNumber:3 part:1],
    [self positionWithX:8 y:0]: [self cellWithNodeNumber:3 part:2],
    // nodeH
    [self positionWithX:11 y:0]: [self cellWithNodeNumber:7 part:0],
    [self positionWithX:12 y:0]: [self cellWithNodeNumber:7 part:1],
    [self positionWithX:13 y:0]: [self cellWithNodeNumber:7 part:2],
    // nodeI
    [self positionWithX:14 y:0]: [self selectedCellWithNodeNumber:8 part:0],
    [self positionWithX:15 y:0]: [self selectedCellWithNodeNumber:8 part:1],
    [self positionWithX:16 y:0]: [self selectedCellWithNodeNumber:8 part:2],
  };
  [self assertNodeNumbersViewCells:[testee getNodeNumbersViewCellsDictionary] areEqualToExpectedCells:expectedNodeNumbersViewCellsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the cellAtPosition:() method.
// -----------------------------------------------------------------------------
- (void) testCellAtPosition
{
  // Arrange
  //
  // Root--NodeA--NodeB
  //          \---NodeC                                                         |
  GoNode* rootNode = m_game.nodeModel.rootNode;
  GoNode* nodeA = [self parentNode:rootNode appendChildNode:[self createEmptyNode]];
  [self parentNode:nodeA appendChildNode:[self createEmptyNode]];
  [self parentNode:nodeA appendChildNode:[self createEmptyNode]];

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];
  [testee recalculateCanvas];

  // Act
  NodeTreeViewCell* rootNodeCell = [testee cellAtPosition:[self positionWithX:0 y:0]];
  NodeTreeViewCell* nodeACell = [testee cellAtPosition:[self positionWithX:1 y:0]];
  NodeTreeViewCell* nodeBCell = [testee cellAtPosition:[self positionWithX:2 y:0]];
  NodeTreeViewCell* emptyCell1 = [testee cellAtPosition:[self positionWithX:0 y:1]];
  NodeTreeViewCell* emptyCell2 = [testee cellAtPosition:[self positionWithX:1 y:1]];
  NodeTreeViewCell* nodeCCell = [testee cellAtPosition:[self positionWithX:2 y:1]];
  NodeTreeViewCell* cellOutsideOfCanvas = [testee cellAtPosition:[self positionWithX:3 y:3]];

  // Assert
  XCTAssertNotNil(rootNodeCell);
  XCTAssertEqualObjects(rootNodeCell, [self selectedCellWithSymbol:NodeTreeViewCellSymbolKomi lines:NodeTreeViewCellLineCenterToRight]);
  XCTAssertNotNil(nodeACell);
  XCTAssertEqualObjects(nodeACell, [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight | NodeTreeViewCellLineCenterToBottomRight]);
  XCTAssertNotNil(nodeBCell);
  XCTAssertEqualObjects(nodeBCell, [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToLeft]);
  XCTAssertNotNil(emptyCell1);
  XCTAssertEqualObjects(emptyCell1, [NodeTreeViewCell emptyCell]);
  XCTAssertNotNil(emptyCell2);
  XCTAssertEqualObjects(emptyCell2, [NodeTreeViewCell emptyCell]);
  XCTAssertNotNil(nodeCCell);
  XCTAssertEqualObjects(nodeCCell, [self cellWithSymbol:NodeTreeViewCellSymbolEmpty lines:NodeTreeViewCellLineCenterToTopLeft]);
  XCTAssertNil(cellOutsideOfCanvas);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the nodeAtPosition:() method.
// -----------------------------------------------------------------------------
- (void) testNodeAtPosition
{
  // Arrange
  //
  // Root--NodeA--NodeB
  //          \---NodeC                                                         |
  GoNode* rootNode = m_game.nodeModel.rootNode;
  GoNode* nodeA = [self parentNode:rootNode appendChildNode:[self createEmptyNode]];
  GoNode* nodeB = [self parentNode:nodeA appendChildNode:[self createEmptyNode]];
  GoNode* nodeC = [self parentNode:nodeA appendChildNode:[self createEmptyNode]];

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];
  [testee recalculateCanvas];

  // Act
  GoNode* nodeAtRootNodeCell = [testee nodeAtPosition:[self positionWithX:0 y:0]];
  GoNode* nodeAtNodeACell = [testee nodeAtPosition:[self positionWithX:1 y:0]];
  GoNode* nodeAtNodeBCell = [testee nodeAtPosition:[self positionWithX:2 y:0]];
  GoNode* nodeAtEmptyCell1 = [testee nodeAtPosition:[self positionWithX:0 y:1]];
  GoNode* nodeAtEmptyCell2 = [testee nodeAtPosition:[self positionWithX:1 y:1]];
  GoNode* nodeAtNodeCCell = [testee nodeAtPosition:[self positionWithX:2 y:1]];
  GoNode* nodeAtCellOutsideOfCanvas = [testee nodeAtPosition:[self positionWithX:3 y:3]];

  // Assert
  XCTAssertEqual(nodeAtRootNodeCell, rootNode);
  XCTAssertEqual(nodeAtNodeACell, nodeA);
  XCTAssertEqual(nodeAtNodeBCell, nodeB);
  XCTAssertNil(nodeAtEmptyCell1);
  XCTAssertNil(nodeAtEmptyCell2);
  XCTAssertEqual(nodeAtNodeCCell, nodeC);
  XCTAssertNil(nodeAtCellOutsideOfCanvas);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the positionsForNode:() method.
// -----------------------------------------------------------------------------
- (void) testPositionsForNode
{
  // Arrange
  //
  // Root--NodeMove1--NodeMove2---NodeMove3
  //                  ^
  //                  condensed
  GoNode* rootNode = m_game.nodeModel.rootNode;
  GoNode* nodeMove1 = [self parentNode:rootNode appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];
  GoNode* nodeMove2 = [self parentNode:nodeMove1 appendChildNode:[self createWhiteMoveNodeWithMoveNumber:2]];
  GoNode* nodeMove3 = [self parentNode:nodeMove2 appendChildNode:[self createBlackMoveNodeWithMoveNumber:3]];
  GoNode* nodeNotInTree = [GoNode node];
  GoNode* nilNode = nil;

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];
  [testee recalculateCanvas];

  // Act
  NSArray* positionsForRootNode = [testee positionsForNode:rootNode];
  NSArray* positionsForNodeMove1 = [testee positionsForNode:nodeMove1];
  NSArray* positionsForNodeMove2 = [testee positionsForNode:nodeMove2];
  NSArray* positionsForNodeMove3 = [testee positionsForNode:nodeMove3];
  NSArray* positionsForNodeNotInTree = [testee positionsForNode:nodeNotInTree];
  NSArray* positionsForNilNode = [testee positionsForNode:nilNode];

  // Assert
  XCTAssertNotNil(positionsForRootNode);
  NSArray* expectedPositionsForRootNode = @[ [self positionWithX:0 y:0], [self positionWithX:1 y:0], [self positionWithX:2 y:0] ];
  XCTAssertEqualObjects(positionsForRootNode, expectedPositionsForRootNode);

  XCTAssertNotNil(positionsForNodeMove1);
  NSArray* expectedPositionsForNodeMove1 = @[ [self positionWithX:3 y:0], [self positionWithX:4 y:0], [self positionWithX:5 y:0] ];
  XCTAssertEqualObjects(positionsForNodeMove1, expectedPositionsForNodeMove1);

  XCTAssertNotNil(positionsForNodeMove2);
  NSArray* expectedPositionsForNodeMove2 = @[ [self positionWithX:6 y:0] ];
  XCTAssertEqualObjects(positionsForNodeMove2, expectedPositionsForNodeMove2);

  XCTAssertNotNil(positionsForNodeMove3);
  NSArray* expectedPositionsForNodeMove3 = @[ [self positionWithX:7 y:0], [self positionWithX:8 y:0], [self positionWithX:9 y:0] ];
  XCTAssertEqualObjects(positionsForNodeMove3, expectedPositionsForNodeMove3);

  XCTAssertNotNil(positionsForNodeNotInTree);
  XCTAssertEqual(positionsForNodeNotInTree.count, 0);

  XCTAssertNotNil(positionsForNilNode);
  XCTAssertEqual(positionsForNilNode.count, 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the selectedNodePositions() method.
// -----------------------------------------------------------------------------
- (void) testSelectedNodePositions
{
  // Arrange
  GoNode* rootNode = m_game.nodeModel.rootNode;
  [self parentNode:rootNode appendChildNode:[self createBlackMoveNodeWithMoveNumber:1]];

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];
  [testee recalculateCanvas];

  // Act
  NSArray* selectedNodePositions = [testee selectedNodePositions];

  // Assert
  XCTAssertNotNil(selectedNodePositions);
  NSArray* expectedSelectedNodePositions = @[ [self positionWithX:0 y:0], [self positionWithX:1 y:0], [self positionWithX:2 y:0] ];
  XCTAssertEqualObjects(selectedNodePositions, expectedSelectedNodePositions);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the nodeNumbersViewCellAtPosition:() method.
// -----------------------------------------------------------------------------
- (void) testNodeNumbersViewCellAtPosition
{
  // Arrange
  //
  // Root--NodeA--NodeB
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeA
  [m_game addEmptyNodeToCurrentGameVariation];  // nodeB

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  nodeTreeViewModel.nodeNumberInterval = 2;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];
  [testee recalculateCanvas];

  // Act
  NodeNumbersViewCell* rootNodeCell = [testee nodeNumbersViewCellAtPosition:[self positionWithX:0 y:0]];
  NodeNumbersViewCell* nodeACell = [testee nodeNumbersViewCellAtPosition:[self positionWithX:1 y:0]];
  NodeNumbersViewCell* nodeBCell = [testee nodeNumbersViewCellAtPosition:[self positionWithX:2 y:0]];
  NodeNumbersViewCell* cellOutsideOfCanvas = [testee nodeNumbersViewCellAtPosition:[self positionWithX:3 y:0]];

  // Assert
  XCTAssertNotNil(rootNodeCell);
  XCTAssertEqualObjects(rootNodeCell, [self cellWithNodeNumber:0]);
  XCTAssertNotNil(nodeACell);
  XCTAssertEqualObjects(nodeACell, [self cellWithNodeNumber:-1]);
  XCTAssertNotNil(nodeBCell);
  XCTAssertEqualObjects(nodeBCell, [self selectedCellWithNodeNumber:2]);
  XCTAssertNil(cellOutsideOfCanvas);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the nodeNumbersViewPositionsForNode:() method.
// -----------------------------------------------------------------------------
- (void) testNodeNumbersViewPositionsForNode
{
  // Arrange
  //
  // Root--NodeMove1--NodeMove2---NodeMove3---Node4
  //                  ^
  //                  condensed
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove1
  [m_game play:[m_game.board pointAtVertex:@"B1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove2
  [m_game play:[m_game.board pointAtVertex:@"C1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove3
  [m_game addEmptyNodeToCurrentGameVariation];  // Node4
  GoNode* rootNode = m_game.nodeModel.rootNode;
  GoNode* nodeMove1 = rootNode.firstChild;
  GoNode* nodeMove2 = nodeMove1.firstChild;
  GoNode* nodeMove3 = nodeMove2.firstChild;
  GoNode* node4 = nodeMove3.firstChild;
  GoNode* nodeNotInTree = [GoNode node];
  GoNode* nilNode = nil;

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true];
  nodeTreeViewModel.nodeNumberInterval = 2;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];
  [testee recalculateCanvas];

  // Act
  NSArray* positionsForRootNode = [testee nodeNumbersViewPositionsForNode:rootNode];
  NSArray* positionsForNodeMove1 = [testee nodeNumbersViewPositionsForNode:nodeMove1];
  NSArray* positionsForNodeMove2 = [testee nodeNumbersViewPositionsForNode:nodeMove2];
  NSArray* positionsForNodeMove3 = [testee nodeNumbersViewPositionsForNode:nodeMove3];
  NSArray* positionsForNode4 = [testee nodeNumbersViewPositionsForNode:node4];
  NSArray* positionsForNodeNotInTree = [testee nodeNumbersViewPositionsForNode:nodeNotInTree];
  NSArray* positionsForNilNode = [testee nodeNumbersViewPositionsForNode:nilNode];

  // Assert
  XCTAssertNotNil(positionsForRootNode);
  NSArray* expectedPositionsForRootNode = @[ [self positionWithX:0 y:0], [self positionWithX:1 y:0], [self positionWithX:2 y:0] ];
  XCTAssertEqualObjects(positionsForRootNode, expectedPositionsForRootNode);

  // We get positions even though NodeMove1 is not numbered
  XCTAssertNotNil(positionsForNodeMove1);
  NSArray* expectedPositionsForNodeMove1 = @[ [self positionWithX:3 y:0], [self positionWithX:4 y:0], [self positionWithX:5 y:0] ];
  XCTAssertEqualObjects(positionsForNodeMove1, expectedPositionsForNodeMove1);

  // We get the number of positions for an uncondensed node even though
  // NodeMove2 is condensed - node numbers always take up the same amount of
  // space
  XCTAssertNotNil(positionsForNodeMove2);
  NSArray* expectedPositionsForNodeMove2 = @[ [self positionWithX:5 y:0], [self positionWithX:6 y:0], [self positionWithX:7 y:0] ];
  XCTAssertEqualObjects(positionsForNodeMove2, expectedPositionsForNodeMove2);

  // We get positions even though NodeMove3 is not numbered
  XCTAssertNotNil(positionsForNodeMove3);
  NSArray* expectedPositionsForNodeMove3 = @[ [self positionWithX:7 y:0], [self positionWithX:8 y:0], [self positionWithX:9 y:0] ];
  XCTAssertEqualObjects(positionsForNodeMove3, expectedPositionsForNodeMove3);

  XCTAssertNotNil(positionsForNode4);
  NSArray* expectedPositionsForNode4 = @[ [self positionWithX:10 y:0], [self positionWithX:11 y:0], [self positionWithX:12 y:0] ];
  XCTAssertEqualObjects(positionsForNode4, expectedPositionsForNode4);

  XCTAssertNotNil(positionsForNodeNotInTree);
  XCTAssertEqual(positionsForNodeNotInTree.count, 0);

  XCTAssertNotNil(positionsForNilNode);
  XCTAssertEqual(positionsForNilNode.count, 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the selectedNodeNodeNumbersViewPositions() method.
// -----------------------------------------------------------------------------
- (void) testSelectedNodeNodeNumbersViewPositions
{
  // Arrange
  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true];
  nodeTreeViewModel.nodeNumberInterval = 2;
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  // Not having a selected node is a theoretical scenario only, because
  // GoBoardPosition must point to a valid note at all times. The only way to
  // test the "no selected node" scenario is to invoke the method when no canvas
  // data is available yet because no calculation has been performed yet.
  NSArray* positionsForNoSelectedNode = [testee selectedNodeNodeNumbersViewPositions];

  [testee recalculateCanvas];
  NSArray* positionsForSelectedNodeIsRootNode = [testee selectedNodeNodeNumbersViewPositions];

  // Root--NodeMove1--NodeMove2---NodeMove3---Node4
  //                  ^
  //                  condensed
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove1
  [m_game play:[m_game.board pointAtVertex:@"B1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove2
  [m_game play:[m_game.board pointAtVertex:@"C1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove3
  [m_game addEmptyNodeToCurrentGameVariation];  // Node4
  [testee recalculateCanvas];
  NSArray* positionsForSelectedNodeIsNode4 = [testee selectedNodeNodeNumbersViewPositions];

  m_game.boardPosition.currentBoardPosition = 3;  // select NodeMove3
  [testee recalculateCanvas];
  NSArray* positionsForSelectedNodeIsNodeMove3 = [testee selectedNodeNodeNumbersViewPositions];

  m_game.boardPosition.currentBoardPosition = 2;  // select NodeMove2
  [testee recalculateCanvas];
  NSArray* positionsForSelectedNodeIsNodeMove2 = [testee selectedNodeNodeNumbersViewPositions];

  // Assert
  XCTAssertNotNil(positionsForNoSelectedNode);
  XCTAssertEqual(positionsForNoSelectedNode.count, 0);

  XCTAssertNotNil(positionsForSelectedNodeIsRootNode);
  NSArray* expectedPositionsForSelectedNodeIsRootNode = @[ [self positionWithX:0 y:0], [self positionWithX:1 y:0], [self positionWithX:2 y:0] ];
  XCTAssertEqualObjects(positionsForSelectedNodeIsRootNode, expectedPositionsForSelectedNodeIsRootNode);

  XCTAssertNotNil(positionsForSelectedNodeIsNode4);
  NSArray* expectedPositionsForSelectedNodeIsNode4 = @[ [self positionWithX:10 y:0], [self positionWithX:11 y:0], [self positionWithX:12 y:0] ];
  XCTAssertEqualObjects(positionsForSelectedNodeIsNode4, expectedPositionsForSelectedNodeIsNode4);

  // We get positions even though NodeMove3 is not numbered
  XCTAssertNotNil(positionsForSelectedNodeIsNodeMove3);
  NSArray* expectedPositionsForSelectedNodeIsNodeMove3 = @[ [self positionWithX:7 y:0], [self positionWithX:8 y:0], [self positionWithX:9 y:0] ];
  XCTAssertEqualObjects(positionsForSelectedNodeIsNodeMove3, expectedPositionsForSelectedNodeIsNodeMove3);

  // We get the number of positions for an uncondensed node even though
  // NodeMove2 is condensed - node numbers always take up the same amount of
  // space
  XCTAssertNotNil(positionsForSelectedNodeIsNodeMove2);
  NSArray* expectedPositionsForSelectedNodeIsNodeMove2 = @[ [self positionWithX:5 y:0], [self positionWithX:6 y:0], [self positionWithX:7 y:0] ];
  XCTAssertEqualObjects(positionsForSelectedNodeIsNodeMove2, expectedPositionsForSelectedNodeIsNodeMove2);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e canvasSize property.
// -----------------------------------------------------------------------------
- (void) testCanvasSize
{
  // Arrange
  //
  // Root--NodeMove1--NodeMove2---NodeMove3---Node4
  //   \---NodeMove5  ^
  //                  condensed
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [GoMoveNodeCreationOptions moveNodeCreationOptions];
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove1
  [m_game play:[m_game.board pointAtVertex:@"B1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove2
  [m_game play:[m_game.board pointAtVertex:@"C1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove3
  [m_game addEmptyNodeToCurrentGameVariation];  // Node4
  m_game.boardPosition.currentBoardPosition = 0;  // select root node
  [m_game play:[m_game.board pointAtVertex:@"A1"] withMoveNodeCreationOptions:moveNodeCreationOptions];  // NodeMove5

  NodeTreeViewModel* nodeTreeViewModel = m_delegate.nodeTreeViewModel;
  [self setupModel:nodeTreeViewModel condenseMoveNodes:true];
  NodeTreeViewCanvas* testee = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  // Act
  CGSize defaultCanvasSize = testee.canvasSize;
  [testee recalculateCanvas];
  CGSize calculatedCanvasSize = testee.canvasSize;

  // Assert
  XCTAssertTrue(CGSizeEqualToSize(defaultCanvasSize, CGSizeZero));
  XCTAssertTrue(CGSizeEqualToSize(calculatedCanvasSize, CGSizeMake(13, 2)));
}

#pragma mark - Helper methods - Configure NodeTreeViewModel

// -----------------------------------------------------------------------------
/// @brief Helper method that configures @a model with @a condenseMoveNodes.
/// Move nodes are not aligned and the branching style is set to right-angle.
// -----------------------------------------------------------------------------
- (void) setupModel:(NodeTreeViewModel*)model condenseMoveNodes:(bool)condenseMoveNodes
{
  [self setupModel:model condenseMoveNodes:condenseMoveNodes alignMoveNodes:false branchingStyle:NodeTreeViewBranchingStyleRightAngle];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that configures @a model with @a condenseMoveNodes and
/// @a branchingStyle. Move nodes are not aligned.
// -----------------------------------------------------------------------------
- (void) setupModel:(NodeTreeViewModel*)model
  condenseMoveNodes:(bool)condenseMoveNodes
     branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  [self setupModel:model condenseMoveNodes:condenseMoveNodes alignMoveNodes:false branchingStyle:branchingStyle];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that configures @a model with @a condenseMoveNodes,
/// @a alignMoveNodes and @a branchingStyle. The number of cells of a multipart
/// is set to 3.
// -----------------------------------------------------------------------------
- (void) setupModel:(NodeTreeViewModel*)model
  condenseMoveNodes:(bool)condenseMoveNodes
     alignMoveNodes:(bool)alignMoveNodes
     branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  model.condenseMoveNodes = condenseMoveNodes;
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
/// standalone cell. The cell contains the specified symbol and no lines. The
/// cell is selected and contains no selected lines.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) selectedCellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
{
  return [self selectedCellWithSymbol:symbol
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
/// standalone cell. The cell contains no symbol and the specified lines and
/// selected lines (both line types have the same value). The cell is
/// unselected.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithLinesAndLinesSelectedGameVariation:(NodeTreeViewCellLines)linesAndLinesSelectedGameVariation
{
  return [self cellWithSymbol:NodeTreeViewCellSymbolNone
                        lines:linesAndLinesSelectedGameVariation
   linesSelectedGameVariation:linesAndLinesSelectedGameVariation];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is a
/// standalone cell. The cell contains no symbol and the specified lines and
/// selected lines. The cell is unselected.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithLines:(NodeTreeViewCellLines)lines
         linesSelectedGameVariation:(NodeTreeViewCellLines)linesSelectedGameVariation
{
  return [self cellWithSymbol:NodeTreeViewCellSymbolNone
                        lines:lines
   linesSelectedGameVariation:linesSelectedGameVariation];
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
/// @brief Helper method that creates a NodeTreeViewCell object that is a
/// standalone cell. The cell contains the specified symbol and lines. The cell
/// is selected and contains no selected lines.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) selectedCellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                                       lines:(NodeTreeViewCellLines)lines
{
  return [self cellWithSymbol:symbol
                     selected:true
                        lines:lines
   linesSelectedGameVariation:NodeTreeViewCellLineNone
                         part:0
                        parts:1];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is a
/// standalone cell. The cell contains the specified symbol, lines and selected
/// lines (both line types have the same value). The cell is unselected.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
  linesAndLinesSelectedGameVariation:(NodeTreeViewCellLines)linesAndLinesSelectedGameVariation
{
  return [self cellWithSymbol:symbol
                     selected:false
                        lines:linesAndLinesSelectedGameVariation
   linesSelectedGameVariation:linesAndLinesSelectedGameVariation
                         part:0
                        parts:1];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is a
/// standalone cell. The cell contains the specified symbol, lines and selected
/// lines. The cell is unselected.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                               lines:(NodeTreeViewCellLines)lines
          linesSelectedGameVariation:(NodeTreeViewCellLines)linesSelectedGameVariation
{
  return [self cellWithSymbol:symbol
                     selected:false
                        lines:lines
   linesSelectedGameVariation:linesSelectedGameVariation
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
/// sub-cell @a part of a multipart cell. The cell contains the specified symbol
/// and no lines. The cell is selected and contains no selected lines. The
/// number of cells of a multipart cell is taken from the current
/// NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) selectedCellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                                        part:(int)part
{
  return [self selectedCellWithSymbol:symbol
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
/// @brief Helper method that creates a NodeTreeViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell contains the specified symbol
/// and lines. The cell is selected and contains no selected lines. The
/// number of cells of a multipart cell is taken from the current
/// NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) selectedCellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                                       lines:(NodeTreeViewCellLines)lines
                                        part:(int)part
{
  return [self cellWithSymbol:symbol
                     selected:true
                        lines:lines
   linesSelectedGameVariation:NodeTreeViewCellLineNone
                         part:part
                        parts:m_delegate.nodeTreeViewModel.numberOfCellsOfMultipartCell];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell contains the specified
/// symbol, lines and selected lines (both line types have the same value). The
/// cell is unselected. The number of cells of a multipart cell is taken from
/// the current NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
  linesAndLinesSelectedGameVariation:(NodeTreeViewCellLines)linesAndLinesSelectedGameVariation
                                part:(int)part
{
  return [self cellWithSymbol:symbol
                     selected:false
                        lines:linesAndLinesSelectedGameVariation
   linesSelectedGameVariation:linesAndLinesSelectedGameVariation
                         part:part
                        parts:m_delegate.nodeTreeViewModel.numberOfCellsOfMultipartCell];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell contains the specified
/// symbol, lines and selected lines (both line types have the same value). The
/// cell is selected. The number of cells of a multipart cell is taken from
/// the current NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) selectedCellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
          linesAndLinesSelectedGameVariation:(NodeTreeViewCellLines)linesAndLinesSelectedGameVariation
                                        part:(int)part
{
  return [self cellWithSymbol:symbol
                     selected:true
                        lines:linesAndLinesSelectedGameVariation
   linesSelectedGameVariation:linesAndLinesSelectedGameVariation
                         part:part
                        parts:m_delegate.nodeTreeViewModel.numberOfCellsOfMultipartCell];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell contains the specified
/// symbol, lines and selected lines. The cell is unselected. The
/// number of cells of a multipart cell is taken from the current
/// NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellWithSymbol:(enum NodeTreeViewCellSymbol)symbol
                               lines:(NodeTreeViewCellLines)lines
          linesSelectedGameVariation:(NodeTreeViewCellLines)linesSelectedGameVariation
                                part:(int)part
{
  return [self cellWithSymbol:symbol
                     selected:false
                        lines:lines
   linesSelectedGameVariation:linesSelectedGameVariation
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

#pragma mark - Helper methods - Create NodeNumbersViewCell objects

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeNumbersViewCell object that is a
/// standalone cell. The cell has the specified node number. The cell
/// is unselected.
// -----------------------------------------------------------------------------
- (NodeNumbersViewCell*) cellWithNodeNumber:(int)nodeNumber
{
  return [self cellWithNodeNumber:nodeNumber
                         selected:false
                             part:0
 nodeNumberExistsOnlyForSelection:false];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeNumbersViewCell object that is a
/// standalone cell. The cell has the specified node number. The cell
/// is selected, but the node number exists not just because of the selection.
// -----------------------------------------------------------------------------
- (NodeNumbersViewCell*) selectedCellWithNodeNumber:(int)nodeNumber
{
  return [self cellWithNodeNumber:nodeNumber
                         selected:true
                             part:0
 nodeNumberExistsOnlyForSelection:false];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeNumbersViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell has the specified node
/// number. The cell is unselected.
// -----------------------------------------------------------------------------
- (NodeNumbersViewCell*) cellWithNodeNumber:(int)nodeNumber
                                       part:(int)part
{
  return [self cellWithNodeNumber:nodeNumber
                         selected:false
                             part:part
 nodeNumberExistsOnlyForSelection:false];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeNumbersViewCell object that is the
/// sub-cell @a part of a multipart cell. The cell has the specified node
/// number. The cell is selected, but the node number exists not just because
/// of the selection.
// -----------------------------------------------------------------------------
- (NodeNumbersViewCell*) selectedCellWithNodeNumber:(int)nodeNumber
                                               part:(int)part
{
  return [self cellWithNodeNumber:nodeNumber
                         selected:true
                             part:part
 nodeNumberExistsOnlyForSelection:false];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeNumbersViewCell object with the
/// specified property values.
// -----------------------------------------------------------------------------
- (NodeNumbersViewCell*) cellWithNodeNumber:(int)nodeNumber
                                   selected:(bool)selected
                                       part:(int)part
           nodeNumberExistsOnlyForSelection:(bool)nodeNumberExistsOnlyForSelection
{
  NodeNumbersViewCell* cell = [[[NodeNumbersViewCell alloc] init] autorelease];

  cell.nodeNumber = nodeNumber;
  cell.part = part;
  cell.selected = selected;;
  cell.nodeNumberExistsOnlyForSelection = nodeNumberExistsOnlyForSelection;
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
  GoNode* node = [GoNode node];
  node.goMove = [self createMoveForPlayer:player moveNumber:moveNumber];
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

#pragma mark - Helper methods - Assert

// -----------------------------------------------------------------------------
/// @brief Assert helper method that verifies that the positions and cells in
/// @a actualCellsDictionary match the expected ones in
/// @a expectedCellsDictionary.
// -----------------------------------------------------------------------------
- (void) assertCells:(NSDictionary*)actualCellsDictionary areEqualToExpectedCells:(NSDictionary*)expectedCellsDictionary
{
  XCTAssertEqual(actualCellsDictionary.allKeys.count, expectedCellsDictionary.allKeys.count);

  [expectedCellsDictionary enumerateKeysAndObjectsUsingBlock:^(NodeTreeViewCellPosition* expectedPosition, NodeTreeViewCell* expectedCell, BOOL* stop)
  {
    NSArray* tuple = actualCellsDictionary[expectedPosition];
    NodeTreeViewCell* actualCell = tuple.firstObject;

    XCTAssertEqualObjects(actualCell, expectedCell);
  }];
}

// -----------------------------------------------------------------------------
/// @brief Assert helper method that verifies that the positions and cells in
/// @a actualCellsDictionary match the expected ones in
/// @a expectedCellsDictionary.
// -----------------------------------------------------------------------------
- (void) assertNodeNumbersViewCells:(NSDictionary*)actualCellsDictionary areEqualToExpectedCells:(NSDictionary*)expectedCellsDictionary
{
  XCTAssertEqual(actualCellsDictionary.allKeys.count, expectedCellsDictionary.allKeys.count);

  [expectedCellsDictionary enumerateKeysAndObjectsUsingBlock:^(NodeTreeViewCellPosition* expectedPosition, NodeNumbersViewCell* expectedCell, BOOL* stop)
  {
    NodeNumbersViewCell* actualCell = actualCellsDictionary[expectedPosition];

    XCTAssertEqualObjects(actualCell, expectedCell);
  }];
}

@end
