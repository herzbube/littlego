// -----------------------------------------------------------------------------
// Copyright 2011-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewLayerDelegateBase.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../ui/CGDrawingHelper.h"


@implementation BoardViewLayerDelegateBase

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// BoardViewLayerDelegate protocol.
@synthesize layer = _layer;
@synthesize tile = _tile;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardViewLayerDelegateBase object. Creates a new
/// CALayer that uses this BoardViewLayerDelegateBase as its delegate.
///
/// @note This is the designated initializer of BoardViewLayerDelegateBase.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.layer = [CALayer layer];
  self.tile = tile;
  self.boardViewMetrics = metrics;
  self.dirty = false;

  CGRect layerFrame = CGRectZero;
  layerFrame.size = self.boardViewMetrics.tileSize;
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
/// @brief Deallocates memory allocated by this BoardViewLayerDelegateBase
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.layer = nil;
  self.tile = nil;
  self.boardViewMetrics = nil;
  [super dealloc];
}

#pragma mark - BoardViewLayerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method. See the BoardViewLayerDelegateBase
/// class documentation for details about this implementation.
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
/// @brief BoardViewLayerDelegate method. See the BoardViewLayerDelegateBase
/// class documentation for details about this implementation.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  // empty "do-nothing" implementation
}

#pragma mark - Helper methods for subclasses

// -----------------------------------------------------------------------------
/// @brief Returns an array that identifies the points whose intersections
/// are located on this tile. Array elements are GoPoint objects.
// -----------------------------------------------------------------------------
- (NSArray*) calculateDrawingPointsOnTile
{
  return [self calculateDrawingPointsOnTileWithCallback:nil];
}

// -----------------------------------------------------------------------------
/// @brief Returns an array that identifies the points whose "point cell"
/// drawing rectangle intersects with this tile's canvas rectangle. Array
/// elements are GoPoint objects. If @a callback is not @e nil, invokes
/// @a callback for each GoPoint object that is found to be on this tile.
///
/// The callback must return a boolean value that indicates whether the point
/// should be used or not. Value @e true indicates that the point should be
/// added to the NSArray that is returned, value @e false indicates that the
/// point should not be added (although the point is on this tile).
///
/// The callback can set @a stop to @e true to stop the search for further
/// points before all points have been examined.
///
/// @note Use GoUtilities::pointsInBothFirstArray:andSecondArray:() to find the
/// intersection between the GoPoints returned by this method and some other
/// collection of GoPoints.
///
/// @note The "point cell" drawing rectangle is defined as having the point's
/// coordinates at its center, with a size that is equal to the value of the
/// BoardViewMetrics property @e pointCellSize. If only a small part of the
/// "point cell" drawing rectangle intersects with the tile's canvas rectangle,
/// and the tile wants to draw an artifact with a size that is less than
/// @e pointCellSize (e.g. something that is drawn within the boundaries of the
/// @e stoneInnerSquareSize), then it may turn out that the artifact's drawing
/// rectangle falls completely outside of the tile's canvas rectangle.
// -----------------------------------------------------------------------------
- (NSArray*) calculateDrawingPointsOnTileWithCallback:(bool (^)(GoPoint* point, bool* stop))callback
{
  bool stop = false;
  NSMutableArray* drawingPoints = [NSMutableArray array];

  // Abort early if boardViewMetrics does not yet have useful values (e.g.
  // during app launch)
  CGSize pointCellSize = self.boardViewMetrics.pointCellSize;
  if (CGSizeEqualToSize(pointCellSize, CGSizeZero))
    return drawingPoints;

  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.boardViewMetrics.tileSize];
  CGFloat tileRectLeftEdge = CGRectGetMinX(tileRect);
  CGFloat tileRectRightEdge = CGRectGetMaxX(tileRect);
  CGFloat tileRectTopEdge = CGRectGetMinY(tileRect);
  CGFloat tileRectBottomEdge = CGRectGetMaxY(tileRect);

  // Simplified schematics how tile rects and point rects can overlap. Also
  // this shows that there can be an unused margin around the board edges.
  //
  // canvas origin
  // o--->
  // |
  // |
  // v   topLeftCornerPointBoard
  //     +---++---++---++---++---++---+
  //     |   ||   ||   ||   ||   ||   |
  //     +---++---++---++---++---++---+
  //                 +--------------+
  //                 |              |
  //     +---++---++-+-++---++---++-|-++---+
  //     |   ||   || | ||   ||   || | ||   |
  //     +---++---++-+-++---++---++-+-++---+
  //                 |              |
  //                 |              |
  //     +---++---++-+-++---++---++-|-+
  //     |   ||   || +-||---||---||-+ |
  //     +---++---++---++---++---++---+

  // The canvas coordinate system has its origin in the upper-left corner, so
  // we base our calculations and iterations also on the top-left edge board
  // corner point.
  GoGame* game = [GoGame sharedGame];
  GoPoint* topLeftCornerPointBoard = [game.board pointAtCorner:GoBoardCornerTopLeft];
  CGRect topLeftCornerPointRectBoard = [BoardViewDrawingHelper canvasRectForStoneAtPoint:topLeftCornerPointBoard
                                                                                 metrics:self.boardViewMetrics];
  CGFloat topLeftCornerPointRectBoardLeftEdge = CGRectGetMinX(topLeftCornerPointRectBoard);
  CGFloat topLeftCornerPointRectBoardTopEdge = CGRectGetMinY(topLeftCornerPointRectBoard);

  // The rectangle of the top-left corner point on the board does not have
  // origin 0/0 if the board view has an unused margin around the board edges.
  // The top-left tile rectangle, however, has origin 0/0.
  int numberOfPointRectsLeftOfTileRect;
  if (tileRectLeftEdge < topLeftCornerPointRectBoardLeftEdge)
    numberOfPointRectsLeftOfTileRect = 0;
  else
    numberOfPointRectsLeftOfTileRect = floorf((tileRectLeftEdge - topLeftCornerPointRectBoardLeftEdge) / pointCellSize.width);
  int numberOfPointRectsAboveTileRect;
  if (tileRectTopEdge < topLeftCornerPointRectBoardTopEdge)
    numberOfPointRectsAboveTileRect = 0;
  else
    numberOfPointRectsAboveTileRect = floorf((tileRectTopEdge - topLeftCornerPointRectBoardTopEdge) / pointCellSize.height);

  // Accessing GoPoint properties right and below are very fast once they have
  // their value in the cache.
  //
  // Note: topLeftCornerPointTile may become nil here if the user is zooming out
  // and a layer of a tile that will soon become obsolete is recalculating its
  // stuff.
  GoPoint* topLeftCornerPointTile = topLeftCornerPointBoard;
  for (int i = 0; i < numberOfPointRectsLeftOfTileRect && topLeftCornerPointTile; i++)
    topLeftCornerPointTile = topLeftCornerPointTile.right;
  for (int i = 0; i < numberOfPointRectsAboveTileRect && topLeftCornerPointTile; i++)
    topLeftCornerPointTile = topLeftCornerPointTile.below;
  if (! topLeftCornerPointTile)
    return drawingPoints;

  CGRect topLeftCornerPointRectTile = [BoardViewDrawingHelper canvasRectForStoneAtPoint:topLeftCornerPointTile
                                                                                metrics:self.boardViewMetrics];
  CGFloat topLeftCornerPointRectTileLeftEdge = CGRectGetMinX(topLeftCornerPointRectTile);
  CGFloat topLeftCornerPointRectTileTopEdge = CGRectGetMinY(topLeftCornerPointRectTile);

  // The number of rows and columns we calculate here usually are not accurate
  // for tiles at the right and/or bottom edge of the board, either because the
  // board view has an unused margin around the board edges, or because those
  // right/bottom edge tiles cover surplus space that is even outside the board
  // view. This inaccuracy will be handled below by additional for-loop
  // criteria.
  int numberOfPointRectsOnTileRectHorizontal = ceilf((tileRectRightEdge - topLeftCornerPointRectTileLeftEdge) / pointCellSize.width);
  int numberOfPointRectsOnTileRectVertical = ceilf((tileRectBottomEdge - topLeftCornerPointRectTileTopEdge) / pointCellSize.height);

  GoPoint* leftEdgePointTile = topLeftCornerPointTile;
  for (int indexOfPointRectOnTileRectHorizontal = 0;
       indexOfPointRectOnTileRectHorizontal < numberOfPointRectsOnTileRectVertical && leftEdgePointTile && ! stop;
       indexOfPointRectOnTileRectHorizontal++)
  {
    GoPoint* point = leftEdgePointTile;

    for (int indexOfPointRectOnTileRectHorizontal = 0;
         indexOfPointRectOnTileRectHorizontal < numberOfPointRectsOnTileRectHorizontal && point && ! stop;
         indexOfPointRectOnTileRectHorizontal++)
    {
      bool shouldAddPoint = true;
      if (callback)
        shouldAddPoint = callback(point, &stop);

      if (shouldAddPoint)
        [drawingPoints addObject:point];

      // Here point can become nil for tiles at the right edge of the board
      // view, if the board ends before the right edge of the tile is reached
      point = point.right;
    }

    // Here leftEdgePointTile can become nil for tiles at the bottom edge of
    // the board view, if the board ends before the bottom edge of the tile is
    // reached
    leftEdgePointTile = leftEdgePointTile.below;
  }

  return drawingPoints;
}

@end
