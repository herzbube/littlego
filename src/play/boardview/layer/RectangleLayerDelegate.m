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
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"


enum DrawingArtifactType
{
  DrawingArtifactTypeArrow,
  DrawingArtifactTypeLine,
  DrawingArtifactTypeSelection,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for RectangleLayerDelegate.
// -----------------------------------------------------------------------------
@interface RectangleLayerDelegate()
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
@end


@implementation RectangleLayerDelegate

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

  self.drawingRectangle = CGRectZero;
  self.dirtyRect = CGRectZero;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this RectangleLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.fromPoint = nil;
  self.toPoint = nil;
  [super dealloc];
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
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case BVLDEventBoardGeometryChanged:
    case BVLDEventBoardSizeChanged:
    case BVLDEventInvalidateContent:
    {
      [self invalidateDrawingRectangle];
      [self invalidateDirtyRect];
      self.dirty = true;
      break;
    }
    case BVLDEventInteractiveMarkupBetweenPointsDidChange:
    {
      NSArray* connectionInformation = eventInfo;

      enum DrawingArtifactType newDrawingArtifactType;
      GoPoint* newFromPoint;
      GoPoint* newToPoint;
      if (connectionInformation.count == 0)
      {
        newDrawingArtifactType = DrawingArtifactTypeArrow;
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

// -----------------------------------------------------------------------------
/// @brief CALayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  if (! self.fromPoint || ! self.toPoint)
    return;

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];
  CGRect canvasRect = [BoardViewDrawingHelper canvasRectFromPoint:self.fromPoint
                                                          toPoint:self.toPoint
                                                          metrics:self.boardViewMetrics];
  if (! CGRectIntersectsRect(tileRect, canvasRect))
    return;

  if (self.drawingArtifactType == DrawingArtifactTypeSelection)
  {
    // TODO xxx implement
  }
  else
  {
    enum GoMarkupConnection connection = (self.drawingArtifactType == DrawingArtifactTypeArrow)
      ? GoMarkupConnectionArrow
      : GoMarkupConnectionLine;

    CGLayerRef layer = CreateConnectionLayer(context,
                                             connection,
                                             self.boardViewMetrics.connectionFillColor,
                                             self.boardViewMetrics.connectionStrokeColor,
                                             self.fromPoint,
                                             self.toPoint,
                                             canvasRect,
                                             self.boardViewMetrics);

    [BoardViewDrawingHelper drawLayer:layer
                          withContext:context
                         inCanvasRect:canvasRect
                       inTileWithRect:tileRect
                          withMetrics:self.boardViewMetrics];

    CGLayerRelease(layer);
  }
}

@end
