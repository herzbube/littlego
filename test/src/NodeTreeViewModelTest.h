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
#import "BaseTestCase.h"


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewModelTest class contains unit tests that
/// exercise the NodeTreeViewModel class.
// -----------------------------------------------------------------------------
@interface NodeTreeViewModelTest : BaseTestCase
{
}

// Align moves
// Condense tree
// Branching style

- (void) testCalculateCanvas_UncondensedTree_RootNodeOnly;
- (void) testCalculateCanvas_CondensedTree_RootNodeOnly;
- (void) testCalculateCanvas_CondensedTree_UncondensedNodes;
- (void) testCalculateCanvas_NodeSymbols;
- (void) testCalculateCanvas_UncondensedTree_Selected;
- (void) testCalculateCanvas_CondensedTree_Selected;
- (void) testCalculateCanvas_UncondensedTree_BranchingStyleDiagonal_Lines;
- (void) testCalculateCanvas_UncondensedTree_BranchingStyleBracket_Lines;
- (void) testCalculateCanvas_CondensedTree_BranchingStyleDiagonal_Lines;
- (void) testCalculateCanvas_CondensedTree_ExtraWideMultipartCells_BranchingStyleDiagonal_Lines;
- (void) testCalculateCanvas_CondensedTree_BranchingStyleBracket_Lines;
- (void) testCalculateCanvas_UncondensedTree_AlignMoves;
- (void) testCalculateCanvas_UncondensedTree_BranchingStyleBracket_AlignMoves_BranchMovedToNewYPosition;
- (void) testCalculateCanvas_UncondensedTree_BranchingStyleDiagonal_AlignMoves_BranchMovedToNewYPosition;
- (void) testCalculateCanvas_CondensedTree_BranchingStyleBracket_AlignMoves;
- (void) testCalculateCanvas_LinesSelectedGameVariation;

@end
