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
#import "NodeTreeViewLayerDelegateBase.h"
#import "../NodeTreeViewMetrics.h"
#import "../canvas/NodeTreeViewCellPosition.h"
#import "../../../ui/CGDrawingHelper.h"


@implementation NodeTreeViewLayerDelegateBase

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// NodeTreeViewLayerDelegate protocol.
@synthesize layer = _layer;
@synthesize tile = _tile;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewLayerDelegateBase object. Creates a new
/// CALayer that uses this NodeTreeViewLayerDelegateBase as its delegate.
///
/// @note This is the designated initializer of NodeTreeViewLayerDelegateBase.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(NodeTreeViewMetrics*)metrics
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.layer = [CALayer layer];
  self.tile = tile;
  self.nodeTreeViewMetrics = metrics;
  self.dirty = false;

  CGRect layerFrame = CGRectZero;
  layerFrame.size = metrics.tileSize;
  self.layer.frame = layerFrame;

  self.layer.delegate = self;
  // Without this, all manner of drawing looks blurry on Retina displays
  self.layer.contentsScale = metrics.contentsScale;

  // This disables the implicit animation that normally occurs when the layer
  // delegate is drawing. As always, stackoverflow.com is our friend:
  // http://stackoverflow.com/questions/2244147/disabling-implicit-animations-in-calayer-setneedsdisplayinrect
  NSMutableDictionary* newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"contents", nil];
  self.layer.actions = newActions;
  [newActions release];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewLayerDelegateBase
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.layer = nil;
  self.tile = nil;
  self.nodeTreeViewMetrics = nil;

  [super dealloc];
}

#pragma mark - NodeTreeViewLayerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief NodeTreeViewLayerDelegate method. See the
/// NodeTreeViewLayerDelegateBase class documentation for details about this
/// implementation.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;
    [self.layer setNeedsDisplay];
  }
}

// -----------------------------------------------------------------------------
/// @brief NodeTreeViewLayerDelegate method. See the
/// NodeTreeViewLayerDelegateBase class documentation for details about this
/// implementation.
// -----------------------------------------------------------------------------
- (void) notify:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  // empty "do-nothing" implementation
}

#pragma mark - Helper methods for subclasses

// -----------------------------------------------------------------------------
/// @brief Returns an array that identifies the node tree view cells whose
/// drawing rectangle intersects with this tile's canvas rectangle. Array
/// elements are NodeTreeViewCellPosition objects.
///
/// @note The cell drawing rectangle is defined as having a size that is equal
/// to the value of the NodeTreeViewMetrics property @e nodeTreeViewCellSize,
/// and a position that is derived from the @e x/y values in
/// NodeTreeViewCellPosition. If only a small part of the drawing rectangle
/// intersects with the tile's canvas rectangle,  and the tile wants to draw an
/// artifact with a size that is less than @e nodeTreeViewCellSize, then it may
/// turn out that the artifact's drawing rectangle falls completely outside of
/// the tile's canvas rectangle.
// -----------------------------------------------------------------------------
- (NSArray*) calculateNodeTreeViewDrawingCellsOnTile
{
  NodeTreeViewCellPosition* topLeftPosition = [NodeTreeViewCellPosition topLeftPosition];
  CGPoint topLeftCellRectOrigin = [self.nodeTreeViewMetrics cellRectOriginFromPosition:topLeftPosition];
  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.nodeTreeViewMetrics.tileSize];
  return [self calculateDrawingCellsOnTile:self.nodeTreeViewMetrics.nodeTreeViewCellSize
                     topLeftCellRectOrigin:topLeftCellRectOrigin
                                  tileRect:tileRect];
}

// -----------------------------------------------------------------------------
/// @brief Returns an array that identifies the node number view cells whose
/// drawing rectangle intersects with this tile's canvas rectangle. Array
/// elements are NodeTreeViewCellPosition objects.
///
/// @note The cell drawing rectangle is defined as having a size that is equal
/// to the value of the NodeTreeViewMetrics property @e nodeNumberViewCellSize,
/// and a position that is derived from the @e x/y values in
/// NodeTreeViewCellPosition. If only a small part of the drawing rectangle
/// intersects with the tile's canvas rectangle,  and the tile wants to draw an
/// artifact with a size that is less than @e nodeNumberViewCellSize, then it
/// may turn out that the artifact's drawing rectangle falls completely outside
/// of the tile's canvas rectangle.
// -----------------------------------------------------------------------------
- (NSArray*) calculateNodeNumberViewDrawingCellsOnTile
{
  NodeTreeViewCellPosition* topLeftPosition = [NodeTreeViewCellPosition topLeftPosition];
  CGPoint topLeftCellRectOrigin = [self.nodeTreeViewMetrics nodeNumberCellRectOriginFromPosition:topLeftPosition];
  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.nodeTreeViewMetrics.tileSize];
  tileRect.size.height = self.nodeTreeViewMetrics.nodeNumberViewHeight;
  return [self calculateDrawingCellsOnTile:self.nodeTreeViewMetrics.nodeNumberViewCellSize
                     topLeftCellRectOrigin:topLeftCellRectOrigin
                                  tileRect:tileRect];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for calculateDrawingCellsOnTile() and
/// calculateNodeTreeViewDrawingCellsOnTile().
// -----------------------------------------------------------------------------
- (NSArray*) calculateDrawingCellsOnTile:(CGSize)cellSize
                   topLeftCellRectOrigin:(CGPoint)topLeftCellRectOrigin
                                tileRect:(CGRect)tileRect
{
  NSMutableArray* drawingCells = [NSMutableArray array];

  // Abort early if no useful cell size is available yet (e.g. during app
  // launch)
  if (CGSizeEqualToSize(cellSize, CGSizeZero))
    return drawingCells;
  // Also abort early if the tree is empty
  if (CGSizeEqualToSize(self.nodeTreeViewMetrics.abstractCanvasSize, CGSizeZero))
    return drawingCells;

  CGFloat tileRectLeftEdge = CGRectGetMinX(tileRect);
  CGFloat tileRectRightEdge = CGRectGetMaxX(tileRect);
  CGFloat tileRectTopEdge = CGRectGetMinY(tileRect);
  CGFloat tileRectBottomEdge = CGRectGetMaxY(tileRect);

  // Currently cells are adjacent horizontally as well as vertically. This
  // may change in the future, especially vertically.
  CGFloat xDistanceBetweenCellEdges = cellSize.width;
  CGFloat yDistanceBetweenCellEdges = cellSize.height;

  // Simplified schematics how tile rects and cell rects can overlap.
  //
  // canvas origin
  // o---------------------------------------->
  // |       ^
  // |       | paddingY
  // |       |
  // |       | +--- top left cell
  // |       v v
  // |      +---++---++---++---++---++---+
  // |<---->|   ||   ||   ||   ||   ||   |
  // |  p   +---++---++---++---++---++---+
  // |  a               +--------------+
  // |  d               |              |
  // |  d   +---++---++-+-++---++---++-|-++---+
  // |  i   |   ||   || | ||   ||   || | ||   |
  // |  n   +---++---++-+-++---++---++-+-++---+
  // |  g               |              |
  // |  X               |              |
  // |      +---++---++-+-++---++---++-|-+
  // |      |   ||   || +-||---||---||-+ |
  // v      +---++---++---++---++---++---+

  // The canvas coordinate system has its origin in the upper-left corner, so
  // we base our calculations and iterations also on the top-left corner
  // coordinates.
  CGRect topLeftCornerCellRect = CGRectZero;
  topLeftCornerCellRect.origin = topLeftCellRectOrigin;
  topLeftCornerCellRect.size = cellSize;
  CGFloat topLeftCornerCellRectLeftEdge = CGRectGetMinX(topLeftCornerCellRect);
  CGFloat topLeftCornerCellRectTopEdge = CGRectGetMinY(topLeftCornerCellRect);

  // Step 1: Determine the x/y position of the top-left cell that intersects
  // with the tile
  unsigned short xPositionOfTopLeftCellIntersectingWithTile;
  unsigned short yPositionOfTopLeftCellIntersectingWithTile;
  CGRect topLeftCellIntersectingWithTileRect = CGRectZero;
  topLeftCellIntersectingWithTileRect.size =  cellSize;

  if (tileRectLeftEdge > topLeftCornerCellRectLeftEdge)
  {
    int numberOfFullCellsOutsideOfTileOnTheLeft = floor((tileRectLeftEdge - topLeftCornerCellRectLeftEdge) / xDistanceBetweenCellEdges);
    xPositionOfTopLeftCellIntersectingWithTile = numberOfFullCellsOutsideOfTileOnTheLeft;
    topLeftCellIntersectingWithTileRect.origin.x = topLeftCornerCellRectLeftEdge + numberOfFullCellsOutsideOfTileOnTheLeft * xDistanceBetweenCellEdges;

    if (xPositionOfTopLeftCellIntersectingWithTile > self.nodeTreeViewMetrics.bottomRightCellX)
      return drawingCells;
  }
  else
  {
    if (tileRectRightEdge > topLeftCornerCellRectLeftEdge)
    {
      xPositionOfTopLeftCellIntersectingWithTile = 0;
      topLeftCellIntersectingWithTileRect.origin.x = topLeftCornerCellRect.origin.x;
    }
    else
    {
      // The tile is so small that the right edge of the tile ends before the
      // left edge of the first cell (cell with x-position 0) begins
      // => no cells are on the tile
      return drawingCells;
    }
  }

  if (tileRectTopEdge > topLeftCornerCellRectTopEdge)
  {
    int numberOfFullCellsOutsideOfTileAbove = floor((tileRectTopEdge - topLeftCornerCellRectTopEdge) / yDistanceBetweenCellEdges);
    yPositionOfTopLeftCellIntersectingWithTile = numberOfFullCellsOutsideOfTileAbove;
    topLeftCellIntersectingWithTileRect.origin.y = topLeftCornerCellRectTopEdge + numberOfFullCellsOutsideOfTileAbove * yDistanceBetweenCellEdges;

    if (yPositionOfTopLeftCellIntersectingWithTile > self.nodeTreeViewMetrics.bottomRightCellY)
      return drawingCells;
  }
  else
  {
    if (tileRectBottomEdge > topLeftCornerCellRectTopEdge)
    {
      yPositionOfTopLeftCellIntersectingWithTile = 0;
      topLeftCellIntersectingWithTileRect.origin.y = topLeftCornerCellRect.origin.y;
    }
    else
    {
      // The tile is so small that the bottom edge of the tile ends before the
      // top edge of the first cell (cell with y-position 0) begins
      // => no cells are on the tile
      return drawingCells;
    }
  }

  // Step 2: Determine the x/y position of the bottom-right cell that intersects
  // with the tile
  CGFloat topLeftCellIntersectingWithTileRectLeftEdge = CGRectGetMinX(topLeftCellIntersectingWithTileRect);
  CGFloat topLeftCellIntersectingWithTileRectRightEdge = CGRectGetMaxX(topLeftCellIntersectingWithTileRect);
  CGFloat topLeftCellIntersectingWithTileRectTopEdge = CGRectGetMinY(topLeftCellIntersectingWithTileRect);
  CGFloat topLeftCellIntersectingWithTileRectBottomEdge = CGRectGetMaxY(topLeftCellIntersectingWithTileRect);

  unsigned short xPositionOfBottomRightCellIntersectingWithTile;
  unsigned short yPositionOfBottomRightCellIntersectingWithTile;

  if (tileRectRightEdge > topLeftCellIntersectingWithTileRectRightEdge)
  {
    int numberOfCellsIntersectingHorizontallyWithTile = ceil((tileRectRightEdge - topLeftCellIntersectingWithTileRectLeftEdge) / xDistanceBetweenCellEdges);
    xPositionOfBottomRightCellIntersectingWithTile = xPositionOfTopLeftCellIntersectingWithTile + numberOfCellsIntersectingHorizontallyWithTile - 1;

    if (xPositionOfBottomRightCellIntersectingWithTile > self.nodeTreeViewMetrics.bottomRightCellX)
      xPositionOfBottomRightCellIntersectingWithTile = self.nodeTreeViewMetrics.bottomRightCellX;
  }
  else
  {
    // The tile is less wide than the cell
    xPositionOfBottomRightCellIntersectingWithTile = xPositionOfTopLeftCellIntersectingWithTile;
  }

  if (tileRectBottomEdge > topLeftCellIntersectingWithTileRectBottomEdge)
  {
    int numberOfCellsIntersectingVerticallyWithTile = ceil((tileRectBottomEdge - topLeftCellIntersectingWithTileRectTopEdge) / yDistanceBetweenCellEdges);
    yPositionOfBottomRightCellIntersectingWithTile = yPositionOfTopLeftCellIntersectingWithTile + numberOfCellsIntersectingVerticallyWithTile - 1;

    if (yPositionOfBottomRightCellIntersectingWithTile > self.nodeTreeViewMetrics.bottomRightCellY)
      yPositionOfBottomRightCellIntersectingWithTile = self.nodeTreeViewMetrics.bottomRightCellY;
  }
  else
  {
    // The tile is less high than the cell
    yPositionOfBottomRightCellIntersectingWithTile = yPositionOfTopLeftCellIntersectingWithTile;
  }

  // Step 3: Simple iteration of x/y positions to create the desired
  // NodeTreeViewCellPosition objects
  for (unsigned int yPosition = yPositionOfTopLeftCellIntersectingWithTile; yPosition <= yPositionOfBottomRightCellIntersectingWithTile; yPosition++)
  {
    for (unsigned int xPosition = xPositionOfTopLeftCellIntersectingWithTile; xPosition <= xPositionOfBottomRightCellIntersectingWithTile; xPosition++)
    {
      NodeTreeViewCellPosition* cell = [NodeTreeViewCellPosition positionWithX:xPosition
                                                                             y:yPosition];
      [drawingCells addObject:cell];
    }
  }

  return drawingCells;
}

@end
