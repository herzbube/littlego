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
#import "CrossHairStoneLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"


CGLayerRef blackStoneLayer;
CGLayerRef whiteStoneLayer;
CGLayerRef crossHairStoneLayer;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// CrossHairStoneLayerDelegate.
// -----------------------------------------------------------------------------
@interface BVCrossHairStoneLayerDelegate()
/// @brief Refers to the GoPoint object that marks the focus of the cross-hair.
@property(nonatomic, assign) GoPoint* crossHairPoint;
/// @brief Store drawing rectangle between notify:eventInfo:() and
/// drawLayer:inContext:(), and also between drawing cycles.
@property(nonatomic, assign) CGRect drawingRect;
/// @brief Store dirty rect between notify:eventInfo:() and drawLayer().
@property(nonatomic, assign) CGRect dirtyRect;
@end


@implementation BVCrossHairStoneLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairStoneLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairStoneLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  self.crossHairPoint = nil;
  self.drawingRect = CGRectZero;
  self.dirtyRect = CGRectZero;
  blackStoneLayer = NULL;
  whiteStoneLayer = NULL;
  crossHairStoneLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrossHairStoneLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crossHairPoint = nil;
  [self invalidateLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates stone layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  if (blackStoneLayer)
  {
    CGLayerRelease(blackStoneLayer);
    blackStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (whiteStoneLayer)
  {
    CGLayerRelease(whiteStoneLayer);
    whiteStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (crossHairStoneLayer)
  {
    CGLayerRelease(crossHairStoneLayer);
    crossHairStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the drawing rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDrawingRect
{
  self.dirtyRect = CGRectZero;
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
    {
      self.crossHairPoint = nil;
      [self invalidateLayers];
      [self invalidateDrawingRect];
      [self invalidateDirtyRect];
      self.dirty = true;
      break;
    }
    case BVLDEventBoardSizeChanged:
    {
      self.crossHairPoint = nil;
      [self invalidateLayers];
      [self invalidateDrawingRect];
      [self invalidateDirtyRect];
      self.dirty = true;
      break;      
    }
    case BVLDEventCrossHairChanged:
    {
      // Assume that we won't draw the stone and reset the property
      self.crossHairPoint = nil;

      GoPoint* crossHairPoint = eventInfo;
      CGRect oldDrawingRect = self.drawingRect;
      CGRect newDrawingRect = [self calculateDrawingRectangleForCrossHairPoint:crossHairPoint];
      // We need to compare the drawing rectangles, not the dirty rects. For
      // instance, if newDrawingRect is empty, but oldDrawingRect is not, this
      // means that we need to draw to clear the stone from the previous drawing
      // cycle. The old and the new dirty rects, however, are the same, so it's
      // clear that we can't just compare those.
      if (! CGRectEqualToRect(oldDrawingRect, newDrawingRect))
      {
        self.drawingRect = newDrawingRect;
        if (CGRectIsEmpty(oldDrawingRect))
          self.dirtyRect = newDrawingRect;
        else if (CGRectIsEmpty(newDrawingRect))
          self.dirtyRect = oldDrawingRect;
        else
          self.dirtyRect = CGRectUnion(oldDrawingRect, newDrawingRect);
        self.dirty = true;
        // Remember the point where we are going to draw the stone
        if (! CGRectIsEmpty(newDrawingRect))
          self.crossHairPoint = crossHairPoint;
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
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  // If we haven't remembered the cross-hair point this means that we won't
  // draw the stone (probably beause we are clearing a stone from a previous
  // drawing cycle). We can abort here, which will result in an empty layer.
  if (! self.crossHairPoint)
    return;

  if (! blackStoneLayer)
    blackStoneLayer = BVCreateStoneLayerWithImage(context, stoneBlackImageResource, self.playViewMetrics);
  if (! whiteStoneLayer)
    whiteStoneLayer = BVCreateStoneLayerWithImage(context, stoneWhiteImageResource, self.playViewMetrics);
  if (! crossHairStoneLayer)
    crossHairStoneLayer = BVCreateStoneLayerWithImage(context, stoneCrosshairImageResource, self.playViewMetrics);

  CGLayerRef stoneLayer;
  if (self.crossHairPoint.hasStone)
    stoneLayer = crossHairStoneLayer;
  else
  {
    GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
    if (boardPosition.currentPlayer.isBlack)
      stoneLayer = blackStoneLayer;
    else
      stoneLayer = whiteStoneLayer;
  }

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.playViewMetrics];
  [BoardViewDrawingHelper drawLayer:stoneLayer
                        withContext:context
                    centeredAtPoint:self.crossHairPoint
                     inTileWithRect:tileRect
                        withMetrics:self.playViewMetrics];
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
                                                      metrics:self.playViewMetrics];
  CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:crossHairPoint
                                                               metrics:self.playViewMetrics];
  CGRect drawingRect = CGRectIntersection(tileRect, stoneRect);
  if (CGRectIsNull(drawingRect))
  {
    drawingRect = CGRectZero;
  }
  else
  {
    drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:drawingRect
                                                     inTileWithRect:tileRect];
  }
  return drawingRect;
}

@end
