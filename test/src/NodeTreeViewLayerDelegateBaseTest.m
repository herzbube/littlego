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
#import "NodeTreeViewLayerDelegateBaseTest.h"

// Application includes
#import <play/model/NodeTreeViewModel.h>
#import <play/nodetreeview/NodeTreeViewMetrics.h>
#import <play/nodetreeview/canvas/NodeTreeViewCanvas.h>
#import <play/nodetreeview/canvas/NodeTreeViewCellPosition.h>
#import <play/nodetreeview/layer/NodeTreeViewLayerDelegateBase.h>
#import <ui/Tile.h>

// Mock implementation of Tile protocol
@interface MockTile : NSObject<Tile>
{
@public
  int _row;
  int _column;
}

+ (instancetype) topLeftTile;
+ (instancetype) tileWithRow:(int)row column:(int)column;

@end

@implementation MockTile

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// Tile protocol.
@synthesize row = _row;
@synthesize column = _column;

- (void) invalidateContent {};

+ (instancetype) topLeftTile
{
  return [MockTile tileWithRow:0 column:0];
}

+ (instancetype) tileWithRow:(int)row column:(int)column
{
  MockTile* tile = [[[MockTile alloc] init] autorelease];
  tile->_row = row;
  tile->_column = column;
  return tile;
}

@end

@implementation NodeTreeViewLayerDelegateBaseTest

#pragma mark - Test methods

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// the top-left tile.
///
/// - Padding is > 0 so that the top/left edges of the top-left tile are
///   above/on the left of the top-left cell
/// - Canvas size is sufficient to fill the tile
/// - Tile/cell size alignment is not the focus of this test
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TopLeftTileStartsBeforeTopLeftCell
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self paddedMetricsWithCellsPerTile:2];
  id<Tile> tile = [MockTile topLeftTile];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:0 y:0], [self cellWithX:1 y:0],
                             [self cellWithX:0 y:1], [self cellWithX:1 y:1]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// the top-left tile.
///
/// - Padding is 0 so that the top/left edges of the top-left tile and of the
///   top-left cell are aligned
/// - Canvas size is sufficient to fill the tile
/// - Tile/cell sizes are aligned
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TopLeftTileStartsAtTopLeftCell_TileAndCellSizeAligned
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self unpaddedMetricsWithCellsPerTile:2];
  id<Tile> tile = [MockTile topLeftTile];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:0 y:0], [self cellWithX:1 y:0],
                             [self cellWithX:0 y:1], [self cellWithX:1 y:1]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// the top-left tile.
///
/// - Padding is 0 so that the top/left edges of the top-left tile and of the
///   top-left cell are aligned
/// - Canvas size is sufficient to fill the tile
/// - Tile/cell sizes are not aligned
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TopLeftTileStartsAtTopLeftCell_TileAndCellSizeNotAligned
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self unpaddedMetricsWithCellsPerTile:2.1];
  id<Tile> tile = [MockTile topLeftTile];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:0 y:0], [self cellWithX:1 y:0], [self cellWithX:2 y:0],
                             [self cellWithX:0 y:1], [self cellWithX:1 y:1], [self cellWithX:2 y:1],
                             [self cellWithX:0 y:2], [self cellWithX:1 y:2], [self cellWithX:2 y:2]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// the top-left tile.
///
/// - Tile/cell top/left edge alignment is not the focus of this test
/// - Canvas size is not sufficient to fill the tile
/// - Tile/cell size alignment is not the focus of this test
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TopLeftTileEndsAfterBottomRightCell
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self paddedMetricsWithCellsPerTile:5 canvasSize:2];
  id<Tile> tile = [MockTile topLeftTile];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:0 y:0], [self cellWithX:1 y:0],
                             [self cellWithX:0 y:1], [self cellWithX:1 y:1]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// a tile in the middle of the canvas.
///
/// - Cells/tile is a number with fractions so that the top/left edges of the
///   tile start within a cell, and the bottom/right edges of the tile end
///   within a cell
/// - Canvas size is sufficient to fill the tile
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TileStartsWithinCell
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self unpaddedMetricsWithCellsPerTile:2.6];
  // Tile has 0.4 parts of cell 2, entire cell 3 + 4, plus 0.2 parts of cell 5
  id<Tile> tile = [MockTile tileWithRow:1 column:1];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:2 y:2], [self cellWithX:3 y:2], [self cellWithX:4 y:2], [self cellWithX:5 y:2],
                             [self cellWithX:2 y:3], [self cellWithX:3 y:3], [self cellWithX:4 y:3], [self cellWithX:5 y:3],
                             [self cellWithX:2 y:4], [self cellWithX:3 y:4], [self cellWithX:4 y:4], [self cellWithX:5 y:4],
                             [self cellWithX:2 y:5], [self cellWithX:3 y:5], [self cellWithX:4 y:5], [self cellWithX:5 y:5]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// a tile in the middle of the canvas.
///
/// - Cells/tile is a number with fractions but the tile is chosen so that its
///   top/left edges are exactly aligned with the top/left edges of a cell.
///   The bottom/right edges of the tile end within a cell due to the fraction.
/// - Canvas size is sufficient to fill the tile
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TileStartsAtCell
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self unpaddedMetricsWithCellsPerTile:2.5];
  id<Tile> tile = [MockTile tileWithRow:2 column:2];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:5 y:5], [self cellWithX:6 y:5], [self cellWithX:7 y:5],
                             [self cellWithX:5 y:6], [self cellWithX:6 y:6], [self cellWithX:7 y:6],
                             [self cellWithX:5 y:7], [self cellWithX:6 y:7], [self cellWithX:7 y:7]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// a tile in the middle of the canvas.
///
/// - Cells/tile is a number with fractions so that the top/left edges of the
///   tile start within a cell, but the tile is chosen so that its bottom/right
///   edges are exactly aligned with the bottom/right edges of a cell.
/// - Canvas size is sufficient to fill the tile
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TileEndsAtCell
{
  // Arrange
  id<Tile> tile = [MockTile tileWithRow:1 column:1];
  NodeTreeViewMetrics* metrics = [self unpaddedMetricsWithCellsPerTile:2.5];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:2 y:2], [self cellWithX:3 y:2], [self cellWithX:4 y:2],
                             [self cellWithX:2 y:3], [self cellWithX:3 y:3], [self cellWithX:4 y:3],
                             [self cellWithX:2 y:4], [self cellWithX:3 y:4], [self cellWithX:4 y:4]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// the bottom-right tile.
///
/// - Cells/tile is a number with fractions so that the top/left edges of the
///   tile start within a cell, but the tile's bottom/right edges are exactly
///   aligned with the bottom/right edges of the bottom-right cell of the
///   canvas.
/// - Canvas size is sufficient to fill the tile
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_BottomRightTileEndsAtBottomRightCell
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self unpaddedMetricsWithCellsPerTile:2.5 canvasSize:10];
  id<Tile> tile = [MockTile tileWithRow:3 column:3];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:7 y:7], [self cellWithX:8 y:7], [self cellWithX:9 y:7],
                             [self cellWithX:7 y:8], [self cellWithX:8 y:8], [self cellWithX:9 y:8],
                             [self cellWithX:7 y:9], [self cellWithX:8 y:9], [self cellWithX:9 y:9]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// the bottom-right tile.
///
/// - Cells/tile is a number with fractions so that the top/left edges of the
///   tile start within a cell
/// - Canvas size is not sufficient to fill the tile
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_BottomRightTileEndsAfterBottomRightCell
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self unpaddedMetricsWithCellsPerTile:2.5 canvasSize:9];
  id<Tile> tile = [MockTile tileWithRow:3 column:3];
  NodeTreeViewLayerDelegateBase* testee = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile metrics:metrics] autorelease];
  NSArray* expectedCells = @[[self cellWithX:7 y:7], [self cellWithX:8 y:7],
                             [self cellWithX:7 y:8], [self cellWithX:8 y:8]];

  // Act
  NSArray* cells = [testee calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells, expectedCells);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// the bottom-right tile.
///
/// - Padding is > 0 so that the content of the bottom-right tile only contains
///   padding
/// - Tile/cell sizes are chosen so that the bottom-right tile starts after the
///   bottom-right cell
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_BottomRightTileStartsAfterBottomRightCell
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self metricsWithCellsPerTile:3 padding:20 cellSize:10 canvasSize:3];
  // Tile 0 has full padding + cell 0
  id<Tile> tile0 = [MockTile tileWithRow:0 column:0];
  NodeTreeViewLayerDelegateBase* testee0 = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile0 metrics:metrics] autorelease];
  NSArray* expectedCells0 = @[[self cellWithX:0 y:0]];
  // Tile 1 has cells 1 an 2 and 0.5 of the padding
  id<Tile> tile1 = [MockTile tileWithRow:1 column:1];
  NodeTreeViewLayerDelegateBase* testee1 = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile1 metrics:metrics] autorelease];
  NSArray* expectedCells1 = @[[self cellWithX:1 y:1], [self cellWithX:2 y:1],
                             [self cellWithX:1 y:2], [self cellWithX:2 y:2]];
  // Tile 2 has the remaining 0.5 of the padding
  id<Tile> tile2 = [MockTile tileWithRow:2 column:2];
  NodeTreeViewLayerDelegateBase* testee2 = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile2 metrics:metrics] autorelease];
  NSArray* expectedCells2 = @[];

  // Act
  NSArray* cells0 = [testee0 calculateNodeTreeViewDrawingCellsOnTile];
  NSArray* cells1 = [testee1 calculateNodeTreeViewDrawingCellsOnTile];
  NSArray* cells2 = [testee2 calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells0, expectedCells0);
  XCTAssertEqualObjects(cells1, expectedCells1);
  XCTAssertEqualObjects(cells2, expectedCells2);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the calculateNodeTreeViewDrawingCellsOnTile() method for
/// tiles that are smaller than cells.
// -----------------------------------------------------------------------------
- (void) testCalculateNodeTreeViewDrawingCellsOnTile_TileSizeSmallerThanCellSize
{
  // Arrange
  NodeTreeViewMetrics* metrics = [self metricsWithCellsPerTile:0.4 padding:10 cellSize:40 canvasSize:100];
  // Tile 0 has full padding (0.25 of a cell) + 0.15 of cell 0
  id<Tile> tile0 = [MockTile tileWithRow:0 column:0];
  NodeTreeViewLayerDelegateBase* testee0 = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile0 metrics:metrics] autorelease];
  NSArray* expectedCells0 = @[[self cellWithX:0 y:0]];
  // Tiles 1+2 each have 0.4 of cell 0
  id<Tile> tile1 = [MockTile tileWithRow:1 column:1];
  NodeTreeViewLayerDelegateBase* testee1 = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile1 metrics:metrics] autorelease];
  NSArray* expectedCells1 = @[[self cellWithX:0 y:0]];
  id<Tile> tile2 = [MockTile tileWithRow:2 column:2];
  NodeTreeViewLayerDelegateBase* testee2 = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile2 metrics:metrics] autorelease];
  NSArray* expectedCells2 = @[[self cellWithX:0 y:0]];
  // Tile 3 has 0.05 of cell 0 plus 0.35 of cell 1
  id<Tile> tile3 = [MockTile tileWithRow:3 column:3];
  NodeTreeViewLayerDelegateBase* testee3 = [[[NodeTreeViewLayerDelegateBase alloc] initWithTile:tile3 metrics:metrics] autorelease];
  NSArray* expectedCells3 = @[[self cellWithX:0 y:0], [self cellWithX:1 y:0],
                             [self cellWithX:0 y:1], [self cellWithX:1 y:1]];

  // Act
  NSArray* cells0 = [testee0 calculateNodeTreeViewDrawingCellsOnTile];
  NSArray* cells1 = [testee1 calculateNodeTreeViewDrawingCellsOnTile];
  NSArray* cells2 = [testee2 calculateNodeTreeViewDrawingCellsOnTile];
  NSArray* cells3 = [testee3 calculateNodeTreeViewDrawingCellsOnTile];

  // Assert
  XCTAssertEqualObjects(cells0, expectedCells0);
  XCTAssertEqualObjects(cells1, expectedCells1);
  XCTAssertEqualObjects(cells2, expectedCells2);
  XCTAssertEqualObjects(cells3, expectedCells3);
}

#pragma mark - Helper methods

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewCellPosition object.
// -----------------------------------------------------------------------------
- (NodeTreeViewCellPosition*) cellWithX:(unsigned short)x y:(unsigned short)y
{
  return [NodeTreeViewCellPosition positionWithX:x y:y];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewMetrics object with a
/// non-zero padding and a tile size set so that @a cellsPerTile cells fit into
/// a tile.
// -----------------------------------------------------------------------------
- (NodeTreeViewMetrics*) paddedMetricsWithCellsPerTile:(CGFloat)cellsPerTile
{
  return [self metricsWithCellsPerTile:cellsPerTile padding:10];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewMetrics object with a
/// non-zero padding, a tile size set so that @a cellsPerTile cells fit into
/// a tile, and a canvas size set to @a canvasSize.
// -----------------------------------------------------------------------------
- (NodeTreeViewMetrics*) paddedMetricsWithCellsPerTile:(CGFloat)cellsPerTile canvasSize:(int)canvasSize
{
  return [self metricsWithCellsPerTile:cellsPerTile padding:10 canvasSize:canvasSize];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewMetrics object with no
/// padding and a tile size set so that @a cellsPerTile cells fit into a tile.
// -----------------------------------------------------------------------------
- (NodeTreeViewMetrics*) unpaddedMetricsWithCellsPerTile:(CGFloat)cellsPerTile
{
  return [self metricsWithCellsPerTile:cellsPerTile padding:0];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewMetrics object with no
/// padding, a tile size set so that @a cellsPerTile cells fit into a tile, and
/// a canvas size set to @a canvasSize.
// -----------------------------------------------------------------------------
- (NodeTreeViewMetrics*) unpaddedMetricsWithCellsPerTile:(CGFloat)cellsPerTile canvasSize:(int)canvasSize
{
  return [self metricsWithCellsPerTile:cellsPerTile padding:0 canvasSize:canvasSize];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewMetrics object with a
/// padding set to @a padding and a tile size set so that @a cellsPerTile cells
/// fit into a tile.
// -----------------------------------------------------------------------------
- (NodeTreeViewMetrics*) metricsWithCellsPerTile:(CGFloat)cellsPerTile padding:(int)padding
{
  return [self metricsWithCellsPerTile:cellsPerTile padding:padding canvasSize:cellsPerTile * 100];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewMetrics object with a
/// padding set to @a padding, a tile size set so that @a cellsPerTile cells
/// fit into a tile, and a canvas size set to @a canvasSize.
// -----------------------------------------------------------------------------
- (NodeTreeViewMetrics*) metricsWithCellsPerTile:(CGFloat)cellsPerTile padding:(int)padding canvasSize:(int)canvasSize
{
  return [self metricsWithCellsPerTile:cellsPerTile padding:padding cellSize:20 canvasSize:canvasSize];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a NodeTreeViewMetrics object with a
/// padding set to @a padding, a tile size set so that @a cellsPerTile cells
/// fit into a tile, a cell size set to @a cellSize, and a canvas size set to
/// @a canvasSize.
// -----------------------------------------------------------------------------
- (NodeTreeViewMetrics*) metricsWithCellsPerTile:(CGFloat)cellsPerTile padding:(int)padding cellSize:(int)cellSize canvasSize:(int)canvasSize
{
  NodeTreeViewModel* nodeTreeViewModel = [[[NodeTreeViewModel alloc] init] autorelease];
  nodeTreeViewModel.numberOfCellsOfMultipartCell = 1;
  nodeTreeViewModel.displayNodeNumbers = false;

  NodeTreeViewCanvas* nodeTreeViewCanvas = [[[NodeTreeViewCanvas alloc] initWithModel:nodeTreeViewModel] autorelease];

  NodeTreeViewMetrics* metrics = [[[NodeTreeViewMetrics alloc] initWithModel:nodeTreeViewModel canvas:nodeTreeViewCanvas] autorelease];

  metrics.nodeTreeViewCellBaseSize = cellSize;
  metrics.tileSize = CGSizeMake(metrics.nodeTreeViewCellBaseSize * cellsPerTile,
                                metrics.nodeTreeViewCellBaseSize * cellsPerTile * metrics.numberOfCellsOfMultipartCell);
  metrics.paddingX = padding;
  metrics.paddingY = padding;
  [metrics updateWithAbstractCanvasSize:CGSizeMake(canvasSize, canvasSize)];

  return metrics;
}

@end
