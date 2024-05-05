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


// Project includes
#import "BaseTestCase.h"


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewCanvasTest class contains unit tests that
/// exercise the NodeTreeViewCanvas class.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCanvasTest : BaseTestCase
{
}

- (void) testInitialState;
- (void) testRecalculateCanvas_UncondenseMoveNodes_RootNodeOnly;
- (void) testRecalculateCanvas_CondenseMoveNodes_RootNodeOnly;
- (void) testRecalculateCanvas_CondenseMoveNodes_UncondensedNodes;
- (void) testRecalculateCanvas_NodeSymbols;
- (void) testRecalculateCanvas_UncondenseMoveNodes_Selected;
- (void) testRecalculateCanvas_CondenseMoveNodes_Selected;
- (void) testRecalculateCanvas_BranchIsPushedDownBySiblingBranch;
- (void) testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleDiagonal_Lines;
- (void) testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleRightAngle_Lines;
- (void) testRecalculateCanvas_CondenseMoveNodes_BranchingStyleDiagonal_Lines;
- (void) testRecalculateCanvas_CondenseMoveNodes_ExtraWideMultipartCells_BranchingStyleDiagonal_Lines;
- (void) testRecalculateCanvas_CondenseMoveNodes_BranchingStyleRightAngle_Lines;
- (void) testRecalculateCanvas_UncondenseMoveNodes_AlignMoves;
- (void) testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleRightAngle_AlignMoves_BranchMovedToNewYPosition;
- (void) testRecalculateCanvas_UncondenseMoveNodes_BranchingStyleDiagonal_AlignMoves_BranchMovedToNewYPosition;
- (void) testRecalculateCanvas_CondenseMoveNodes_BranchingStyleRightAngle_AlignMoves;
- (void) testRecalculateCanvas_LinesSelectedGameVariation;
- (void) testRecalculateCanvas_NodeNumbers_UncondenseMoveNodes;
- (void) testRecalculateCanvas_NodeNumbers_UncondenseMoveNodes_AlignMoves;
- (void) testRecalculateCanvas_NodeNumbers_CondenseMoveNodes_AlignMoves;
- (void) testRecalculateCanvas_NodeNumbers_CondenseMoveNodes_Rule3;
- (void) testCellAtPosition;
- (void) testNodeAtPosition;
- (void) testPositionsForNode;
- (void) testSelectedNodePositions;
- (void) testNodeNumbersViewCellAtPosition;
- (void) testNodeNumbersViewPositionsForNode;
- (void) testSelectedNodeNodeNumbersViewPositions;
- (void) testCanvasSize;

@end
