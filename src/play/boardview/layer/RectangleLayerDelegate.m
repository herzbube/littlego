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
#import "RectangleLayerDelegate.h"
#import "BoardViewCGLayerCache.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoUtilities.h"
#import "../../../ui/CGDrawingHelper.h"


enum DrawingArtifactType
{
  DrawingArtifactTypeArrow,
  DrawingArtifactTypeLine,
  DrawingArtifactTypeSelectionRectangle,
  DrawingArtifactTypeNone,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for RectangleLayerDelegate.
// -----------------------------------------------------------------------------
@interface RectangleLayerDelegate()
/// @brief List of GoPoint objects for points that are on this tile.
@property(nonatomic, retain) NSArray* drawingPointsOnTile;
/// @brief Store drawing rectangle between invocations of notify:eventInfo:().
@property(nonatomic, assign) CGRect drawingRectangle;
/// @brief Store dirty rect between invocations of notify:eventInfo:() and
/// drawLayer().
@property(nonatomic, assign) CGRect dirtyRect;
/// @brief First corner point of the rectangle in which to draw. Diagonally
/// opposite to @e toPoint.
@property(nonatomic, retain) GoPoint* fromPoint;
/// @brief Second corner point of the rectangle in which to draw. Diagonally
/// opposite to @e fromPoint.
@property(nonatomic, retain) GoPoint* toPoint;
/// @brief The artifact to draw during the next drawing cycle.
@property(nonatomic, assign) enum DrawingArtifactType drawingArtifactType;
/// @brief List of GoPoint objects for points that are on this tile and that
/// are also in the selection rectangle.
@property(nonatomic, retain) NSArray* pointsOnTileInSelectionRectangle;
@end


@implementation RectangleLayerDelegate

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a RectangleLayerDelegate object.
///
/// @note This is the designated initializer of RectangleLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;

  self.drawingPointsOnTile = @[];
  self.drawingRectangle = CGRectZero;
  self.dirtyRect = CGRectZero;
  self.fromPoint = nil;
  self.toPoint = nil;
  self.drawingArtifactType = DrawingArtifactTypeNone;
  self.pointsOnTileInSelectionRectangle = @[];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this RectangleLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // There are times when no RectangleLayerDelegate instances are around to
  // react to events that invalidate the cached CGLayers, so the cached CGLayers
  // will inevitably become out-of-date. To prevent this, we invalidate the
  // CGLayers *NOW*.
  [self invalidateLayers];

  self.drawingPointsOnTile = nil;
  self.fromPoint = nil;
  self.toPoint = nil;
  self.pointsOnTileInSelectionRectangle = nil;

  [super dealloc];
}

#pragma mark - State invalidation

// -----------------------------------------------------------------------------
/// @brief Invalidates the layers for drawing the selection rectangle.
///
/// When it is next invoked, drawLayer:inContext:() will re-create the layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  [cache invalidateLayerOfType:SelectionRectangleLayerType];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the drawing rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDrawingRectangle
{
  self.drawingRectangle = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the dirty rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyRect
{
  self.dirtyRect = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the list of points that are on this tile and in the
/// selection rectangle.
// -----------------------------------------------------------------------------
- (void) invalidatePointsOnTileInSelectionRectangle
{
  self.pointsOnTileInSelectionRectangle = @[];
}

#pragma mark - BoardViewLayerDelegate overrides

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
      [self invalidateDrawingRectangle];
      [self invalidateDirtyRect];
      [self invalidatePointsOnTileInSelectionRectangle];
      self.drawingPointsOnTile = [self calculateDrawingPointsOnTile];
      self.dirty = true;
      break;
    }
    case BVLDEventGoGameStarted:        // update GoPoint instances (even if board size remains the same)
    case BVLDEventInvalidateContent:
    {
      [self invalidateDrawingRectangle];
      [self invalidateDirtyRect];
      [self invalidatePointsOnTileInSelectionRectangle];
      self.drawingPointsOnTile = [self calculateDrawingPointsOnTile];
      self.dirty = true;
      break;
    }
    // The layer is removed/added dynamically as a result of markup editing mode
    // becoming enabled/disabled. This is the only event we get after being
    // added, so we react to it to trigger a redraw.
    case BVLDEventUIAreaPlayModeChanged:
    {
      self.drawingPointsOnTile = [self calculateDrawingPointsOnTile];
      self.dirty = true;
      break;
    }
    case BVLDEventMarkupConnectionDidMove:
    {
      NSArray* connectionInformation = eventInfo;

      enum DrawingArtifactType newDrawingArtifactType;
      GoPoint* newFromPoint;
      GoPoint* newToPoint;
      if (connectionInformation.count == 0)
      {
        newDrawingArtifactType = DrawingArtifactTypeNone;
        newFromPoint = nil;
        newToPoint = nil;
      }
      else
      {
        NSNumber* connectionAsNumber = [connectionInformation objectAtIndex:0];
        enum GoMarkupConnection connection = connectionAsNumber.intValue;
        newDrawingArtifactType = (connection == GoMarkupConnectionArrow) ? DrawingArtifactTypeArrow : DrawingArtifactTypeLine;
        newFromPoint = [connectionInformation objectAtIndex:1];
        newToPoint = [connectionInformation objectAtIndex:2];
      }

      if (newDrawingArtifactType == self.drawingArtifactType && newFromPoint == self.fromPoint && newToPoint == self.toPoint)
        break;

      self.drawingArtifactType = newDrawingArtifactType;
      self.fromPoint = newFromPoint;
      self.toPoint = newToPoint;

      // We cannot just compare the old and the new drawing rectangle with
      // CGRectEqualToRect() - we need to redraw even when the two rectangles
      // are the same, because the angle of the connection that is passing
      // through the drawing rectangle has changed. Only if no part of the
      // connection is drawn in the previous and in the current drawing cycles
      // are we allowed to not draw anything.
      CGRect oldDrawingRectangle = self.drawingRectangle;
      CGRect newDrawingRectangle = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                                    fromPoint:self.fromPoint
                                                                      toPoint:self.toPoint
                                                                  withMetrics:self.boardViewMetrics];
      if (! CGRectIsEmpty(oldDrawingRectangle) || ! CGRectIsEmpty(newDrawingRectangle))
      {
        self.drawingRectangle = newDrawingRectangle;
        self.dirtyRect = CGRectUnion(oldDrawingRectangle, newDrawingRectangle);
        self.dirty = true;
      }

      break;
    }
    case BVLDEventSelectionRectangleDidChange:
    {
      NSArray* rectangleInformation = eventInfo;

      enum DrawingArtifactType newDrawingArtifactType;
      GoPoint* newFromPoint;
      GoPoint* newToPoint;
      NSArray* newPointsInSelectionRectangle;
      if (rectangleInformation.count == 0)
      {
        newDrawingArtifactType = DrawingArtifactTypeNone;
        newFromPoint = nil;
        newToPoint = nil;
        newPointsInSelectionRectangle = nil;
      }
      else
      {
        newDrawingArtifactType = DrawingArtifactTypeSelectionRectangle;
        newFromPoint = [rectangleInformation objectAtIndex:0];
        newToPoint = [rectangleInformation objectAtIndex:1];
        newPointsInSelectionRectangle = [rectangleInformation objectAtIndex:2];
      }

      if (newDrawingArtifactType == self.drawingArtifactType && newFromPoint == self.fromPoint && newToPoint == self.toPoint)
        break;

      self.drawingArtifactType = newDrawingArtifactType;
      self.fromPoint = newFromPoint;
      self.toPoint = newToPoint;

      CGRect oldDrawingRectangle = self.drawingRectangle;
      CGRect newDrawingRectangle = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                                    fromPoint:self.fromPoint
                                                                      toPoint:self.toPoint
                                                                  withMetrics:self.boardViewMetrics];

      // Unlike the comparison done for
      // BVLDEventInteractiveMarkupBetweenPointsDidChange, here we can use a
      // simple CGRectEqualToRect comparison because the selection rectangle
      // is composed of the same uniform layer being drawn on all points in
      // the rectangle.
      if (! CGRectEqualToRect(oldDrawingRectangle, newDrawingRectangle))
      {
        self.pointsOnTileInSelectionRectangle = [GoUtilities pointsInBothFirstArray:self.drawingPointsOnTile
                                                                     andSecondArray:newPointsInSelectionRectangle];
        self.drawingRectangle = newDrawingRectangle;
        self.dirtyRect = CGRectUnion(oldDrawingRectangle, newDrawingRectangle);
        self.dirty = true;
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
    if (CGRectIsEmpty(self.dirtyRect))
      [self.layer setNeedsDisplay];
    else
      [self.layer setNeedsDisplayInRect:self.dirtyRect];
    [self invalidateDirtyRect];
  }
}

#pragma mark - CALayerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief CALayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  if (! self.fromPoint || ! self.toPoint)
    return;

  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.boardViewMetrics.tileSize];
  CGRect canvasRect = [BoardViewDrawingHelper canvasRectFromPoint:self.fromPoint
                                                          toPoint:self.toPoint
                                                          metrics:self.boardViewMetrics];
  if (! CGRectIntersectsRect(tileRect, canvasRect))
    return;

  switch (self.drawingArtifactType)
  {
    case DrawingArtifactTypeArrow:
    case DrawingArtifactTypeLine:
    {
      [self drawConnection:self.drawingArtifactType
                 fromPoint:self.fromPoint
                   toPoint:self.toPoint
               withContext:context
                inTileRect:tileRect
            withCanvasRect:canvasRect];
      break;
    }
    case DrawingArtifactTypeSelectionRectangle:
    {
      [self createLayersIfNecessaryWithContext:context];

      [self drawSelectionRectangleWithContext:context
                                   inTileRect:tileRect];
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) createLayersIfNecessaryWithContext:(CGContextRef)context
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];

  BoardViewCGLayerCacheEntry selectionRectangleLayerEntry = [cache layerOfType:SelectionRectangleLayerType];
  if (! selectionRectangleLayerEntry.isValid)
  {
    CGLayerRef selectionRectangleLayer = CreateTerritoryLayer(context, TerritoryMarkupStyleWhite, self.boardViewMetrics);
    [cache setLayer:selectionRectangleLayer ofType:SelectionRectangleLayerType];
    CGLayerRelease(selectionRectangleLayer);
  }
}

#pragma mark - Drawing - Selection rectangle

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawSelectionRectangleWithContext:(CGContextRef)context
                                inTileRect:(CGRect)tileRect
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  BoardViewCGLayerCacheEntry selectionRectangleLayerEntry = [cache layerOfType:SelectionRectangleLayerType];

  for (GoPoint* pointOnTileInSelectionRectangle in self.pointsOnTileInSelectionRectangle)
  {
    [BoardViewDrawingHelper drawLayer:selectionRectangleLayerEntry.layer
                          withContext:context
                      centeredAtPoint:pointOnTileInSelectionRectangle
                       inTileWithRect:tileRect
                          withMetrics:self.boardViewMetrics];
  }
}

#pragma mark - Drawing - Connections

// -----------------------------------------------------------------------------
/// @brief Draws a connection of type @a drawingArtifactType between the points
/// @a fromPoint and @a toPoint.
// -----------------------------------------------------------------------------
- (void) drawConnection:(enum DrawingArtifactType)drawingArtifactType
              fromPoint:(GoPoint*)fromPoint
                toPoint:(GoPoint*)toPoint
            withContext:(CGContextRef)context
             inTileRect:(CGRect)tileRect
         withCanvasRect:(CGRect)canvasRect
{
  enum GoMarkupConnection connection = (drawingArtifactType == DrawingArtifactTypeArrow)
    ? GoMarkupConnectionArrow
    : GoMarkupConnectionLine;

  CGLayerRef layer = CreateConnectionLayer(context,
                                           connection,
                                           self.boardViewMetrics.connectionFillColor,
                                           self.boardViewMetrics.connectionStrokeColor,
                                           fromPoint,
                                           toPoint,
                                           canvasRect,
                                           self.boardViewMetrics);

  [BoardViewDrawingHelper drawLayer:layer
                        withContext:context
                       inCanvasRect:canvasRect
                     inTileWithRect:tileRect
                        withMetrics:self.boardViewMetrics];

  CGLayerRelease(layer);
}

@end
