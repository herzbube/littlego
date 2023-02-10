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


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewLayerDelegateBaseTest class contains unit tests that
/// exercise the NodeTreeViewLayerDelegateBase class.
// -----------------------------------------------------------------------------
@interface NodeTreeViewLayerDelegateBaseTest : XCTestCase
{
}

- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TopLeftTileStartsBeforeTopLeftCell;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TopLeftTileStartsAtTopLeftCell_TileAndCellSizeAligned;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TopLeftTileStartsAtTopLeftCell_TileAndCellSizeNotAligned;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TopLeftTileEndsAfterBottomRightCell;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TileStartsWithinCell;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TileStartsAtCell;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TileEndsAtCell;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_BottomRightTileEndsAtBottomRightCell;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_BottomRightTileEndsAfterBottomRightCell;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_BottomRightTileStartsAfterBottomRightCell;
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TileSizeSmallerThanCellSize;

@end
