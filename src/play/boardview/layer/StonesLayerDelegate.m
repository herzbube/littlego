// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "StonesLayerDelegate.h"
#import "BoardViewCGLayerCache.h"
#import "BoardViewDrawingHelper.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StonesLayerDelegate.
// -----------------------------------------------------------------------------
@interface StonesLayerDelegate()
/// @brief Store list of points to draw between notify:eventInfo:() and
/// drawLayer:inContext:(), and also between drawing cycles.
@property(nonatomic, retain) NSMutableDictionary* drawingPoints;
/// @brief Refers to the GoPoint object that marks the current focus of the
/// cross-hair (even if the point is not on this tile).
@property(nonatomic, assign) GoPoint* currentCrossHairPoint;
/// @brief Refers to the GoPoint object that previously marked the focus of the
/// cross-hair (even if the point is not on this tile).
@property(nonatomic, assign) GoPoint* previousCrossHairPoint;
/// @brief The rectangle for drawing @e currentCrossHairPoint. Is CGRectZero
/// if the cross-hair point is not on this tile.
@property(nonatomic, assign) CGRect drawingRectForCrossHairPoint;
/// @brief The dirty rect calculated by notify:eventInfo:() that later needs to
/// be used by drawLayer(). Used only when drawing is required because of a
/// cross-hair change.
@property(nonatomic, assign) CGRect dirtyRectForCrossHairPoint;
/// @brief Is true if only either @e currentCrossHairPoint or
/// @e previousCrossHairPoint needs to be drawn.
@property(nonatomic, assign) bool drawCrossHairPointsOnly;
@end


@implementation StonesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a StonesLayerDelegate object.
///
/// @note This is the designated initializer of StonesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  self.drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
  self.currentCrossHairPoint = nil;
  self.previousCrossHairPoint = nil;
  self.drawingRectForCrossHairPoint = CGRectZero;
  self.dirtyRectForCrossHairPoint = CGRectZero;
  self.drawCrossHairPointsOnly = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StonesLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.drawingPoints = nil;
  self.currentCrossHairPoint = nil;
  self.previousCrossHairPoint = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the stone layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  [cache invalidateLayerOfType:BlackStoneLayerType];
  [cache invalidateLayerOfType:WhiteStoneLayerType];
  [cache invalidateLayerOfType:CrossHairStoneLayerType];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the drawing rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDrawingRectForCrossHairPoint
{
  self.drawingRectForCrossHairPoint = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the dirty rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyRectForCrossHairPoint
{
  self.dirtyRectForCrossHairPoint = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case BVLDEventBoardGeometryChanged:
    case BVLDEventBoardSizeChanged:
    {
      [self invalidateLayers];
      self.currentCrossHairPoint = nil;
      self.previousCrossHairPoint = nil;
      [self invalidateDirtyRectForCrossHairPoint];
      self.drawCrossHairPointsOnly = false;
      self.drawingPoints = [self calculateDrawingPoints];
      self.dirty = true;
      break;
    }
    case BVLDEventGoGameStarted:  // place handicap stones
    case BVLDEventInvalidateContent:
    {
      self.currentCrossHairPoint = nil;
      self.previousCrossHairPoint = nil;
      [self invalidateDirtyRectForCrossHairPoint];
      self.drawCrossHairPointsOnly = false;
      self.drawingPoints = [self calculateDrawingPoints];
      self.dirty = true;
      break;
    }
    case BVLDEventBoardPositionChanged:
    {
      self.currentCrossHairPoint = nil;
      self.previousCrossHairPoint = nil;
      [self invalidateDirtyRectForCrossHairPoint];
      self.drawCrossHairPointsOnly = false;
      NSMutableDictionary* oldDrawingPoints = self.drawingPoints;
      NSMutableDictionary* newDrawingPoints = [self calculateDrawingPoints];
      // The dictionary must contain the intersection state so that the
      // dictionary comparison detects whether a stone was placed or captured
      if (! [oldDrawingPoints isEqualToDictionary:newDrawingPoints])
      {
        self.drawingPoints = newDrawingPoints;
        // Re-draw the entire layer. Further optimization could be made here
        // by only drawing that rectangle which is actually affected by
        // self.drawingPoints.
        self.dirty = true;
      }
      break;
    }
    case BVLDEventCrossHairChanged:
    {
      // Assume that the event is not going to trigger a redraw
      self.previousCrossHairPoint = self.currentCrossHairPoint;
      self.currentCrossHairPoint = eventInfo;
      if (self.previousCrossHairPoint == self.currentCrossHairPoint)
        break;
      CGRect oldDrawingRect = self.drawingRectForCrossHairPoint;
      CGRect newDrawingRect = [self calculateDrawingRectangleForCrossHairPoint:self.currentCrossHairPoint];
      // We need to compare the drawing rectangles, not the cross-hair points.
      // The points may have changed, but if BOTH the old and the new point are
      // not on this tile, the old and the new drawing rectangle have NOT
      // changed - which is exactly what we want.
      if (CGRectEqualToRect(oldDrawingRect, newDrawingRect))
        break;
      // Ok, so we need to redraw something
      self.drawingRectForCrossHairPoint = newDrawingRect;
      self.dirty = true;
      if (CGRectIsEmpty(newDrawingRect))
      {
        // The cross-hair stone is no longer visible on this tile (we don't
        // care if moved to a different tile, or if it is gone entirely), so
        // we need to clear the stone from the previous drawing cycle
        self.dirtyRectForCrossHairPoint = oldDrawingRect;
        self.drawCrossHairPointsOnly = true;
      }
      else if (CGRectIsEmpty(oldDrawingRect))
      {
        // The cross-hair stone was not visible on this tile in the previous
        // drawing cycle, but now it is
        self.dirtyRectForCrossHairPoint = newDrawingRect;
        self.drawCrossHairPointsOnly = true;
      }
      else
      {
        // The cross-hair stone was and still is visible on this tile
        self.dirtyRectForCrossHairPoint = CGRectUnion(oldDrawingRect, newDrawingRect);
        // The union of two rectangles forces us to draw more than just one
        // intersection
        self.drawCrossHairPointsOnly = false;
      }
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;
    if (CGRectIsEmpty(self.dirtyRectForCrossHairPoint))
      [self.layer setNeedsDisplay];
    else
      [self.layer setNeedsDisplayInRect:self.dirtyRectForCrossHairPoint];
    [self invalidateDirtyRectForCrossHairPoint];
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  CGLayerRef blackStoneLayer = [cache layerOfType:BlackStoneLayerType];
  if (! blackStoneLayer)
  {
    blackStoneLayer = CreateStoneLayerWithImage(context, stoneBlackImageResource, self.boardViewMetrics);
    [cache setLayer:blackStoneLayer ofType:BlackStoneLayerType];
    CGLayerRelease(blackStoneLayer);
  }
  CGLayerRef whiteStoneLayer = [cache layerOfType:WhiteStoneLayerType];
  if (! whiteStoneLayer)
  {
    whiteStoneLayer = CreateStoneLayerWithImage(context, stoneWhiteImageResource, self.boardViewMetrics);
    [cache setLayer:whiteStoneLayer ofType:WhiteStoneLayerType];
    CGLayerRelease(whiteStoneLayer);
  }
  CGLayerRef crossHairStoneLayer = [cache layerOfType:CrossHairStoneLayerType];
  if (! crossHairStoneLayer)
  {
    crossHairStoneLayer = CreateStoneLayerWithImage(context, stoneCrosshairImageResource, self.boardViewMetrics);
    [cache setLayer:crossHairStoneLayer ofType:CrossHairStoneLayerType];
    CGLayerRelease(crossHairStoneLayer);
  }

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;
  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];

  [self.drawingPoints enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* stoneStateAsNumber, BOOL* stop)
   {
     // Ignore stoneStateAsNumber, get the current values directly from the
     // GoPoint object
     GoPoint* point = [board pointAtVertex:vertexString];

     if (self.drawCrossHairPointsOnly)
     {
       // Only draw the point if it is either the previous or the current
       // cross-hair point. We can't tell if we need to draw one or the other,
       // so we draw both.
       if (point != self.currentCrossHairPoint && point != self.previousCrossHairPoint)
         return;
     }

     CGLayerRef stoneLayer;
     if (point == self.currentCrossHairPoint)
     {
       if (self.currentCrossHairPoint.hasStone)
       {
         stoneLayer = crossHairStoneLayer;
       }
       else
       {
         GoBoardPosition* boardPosition = game.boardPosition;
         if (boardPosition.currentPlayer.isBlack)
           stoneLayer = blackStoneLayer;
         else
           stoneLayer = whiteStoneLayer;
       }
     }
     else
     {
       if (! point.hasStone)
         return;
       if (point.blackStone)
         stoneLayer = blackStoneLayer;
       else
         stoneLayer = whiteStoneLayer;
     }
     [BoardViewDrawingHelper drawLayer:stoneLayer
                           withContext:context
                       centeredAtPoint:point
                        inTileWithRect:tileRect
                           withMetrics:self.boardViewMetrics];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Returns a dictionary that identifies the points whose intersections
/// are located on this tile, and their current states.
///
/// Dictionary keys are NSString objects that contain the intersection vertex.
/// The vertex string can be used to get the GoPoint object that corresponds to
/// the intersection.
///
/// Dictionary values are NSNumber objects that store a GoColor enum value. The
/// value identifies what needs to be drawn at the intersection (i.e. a black
/// or white stone, or nothing).
// -----------------------------------------------------------------------------
- (NSMutableDictionary*) calculateDrawingPoints
{
  NSMutableDictionary* drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];

  // TODO: Currently we always iterate over all points. This could be
  // optimized: If the tile rect stays the same, we should already know which
  // points intersect with the tile, so we could fall back on a pre-filtered
  // list of points. On a 19x19 board this could save us quite a bit of time:
  // 381 points are iterated on 16 tiles (iPhone), i.e. over 6000 iterations.
  // on iPad where there are more tiles it is even worse.
  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:point
                                                                 metrics:self.boardViewMetrics];
    if (! CGRectIntersectsRect(tileRect, stoneRect))
      continue;
    NSNumber* stoneStateAsNumber = [[[NSNumber alloc] initWithInt:point.stoneState] autorelease];
    [drawingPoints setObject:stoneStateAsNumber forKey:point.vertex.string];
  }

  return drawingPoints;
}

// -----------------------------------------------------------------------------
/// @brief Returns a rectangle in which to draw the stone centered the specified
/// cross-hair point.
///
/// Returns CGRectZero if the stone is not located on this tile.
// -----------------------------------------------------------------------------
- (CGRect) calculateDrawingRectangleForCrossHairPoint:(GoPoint*)crossHairPoint
{
  if (! crossHairPoint)
    return CGRectZero;
  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];
  CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:crossHairPoint
                                                               metrics:self.boardViewMetrics];
  CGRect drawingRectForCrossHairPoint = CGRectIntersection(tileRect, stoneRect);
  if (CGRectIsNull(drawingRectForCrossHairPoint))
  {
    drawingRectForCrossHairPoint = CGRectZero;
  }
  else
  {
    drawingRectForCrossHairPoint = [BoardViewDrawingHelper drawingRectFromCanvasRect:drawingRectForCrossHairPoint
                                                                      inTileWithRect:tileRect];
  }
  return drawingRectForCrossHairPoint;
}

@end
