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
#import "GridLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../BoardTileView.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"


CGLayerRef starPointLayer;


@implementation BVGridLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a GridLayerDelegate object.
///
/// @note This is the designated initializer of GridLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  starPointLayer = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GridLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self invalidateLayer];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the star point layer.
// -----------------------------------------------------------------------------
- (void) invalidateLayer
{
  if (starPointLayer)
  {
    CGLayerRelease(starPointLayer);
    starPointLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
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
      [self invalidateLayer];
      self.dirty = true;
      break;
    }
    case BVLDEventBoardSizeChanged:
    {
      [self invalidateLayer];
      self.dirty = true;
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  if (! starPointLayer)
    starPointLayer = BVCreateStarPointLayer(context, self.playViewMetrics);

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.playViewMetrics];
  [self drawGridLinesWithContext:context inTileRect:tileRect];
  [self drawStarPointsWithContext:context inTileRect:tileRect];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawGridLinesWithContext:(CGContextRef)context inTileRect:(CGRect)tileRect
{
  for (NSValue* lineRectValue in self.playViewMetrics.lineRectangles)
  {
    CGRect lineRect = [lineRectValue CGRectValue];
    CGRect drawingRect = CGRectIntersection(tileRect, lineRect);
    if (CGRectIsNull(drawingRect))
      continue;
    drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:drawingRect
                                                     inTileWithRect:tileRect];
    CGContextSetFillColorWithColor(context, self.playViewMetrics.lineColor.CGColor);
    CGContextFillRect(context, drawingRect);
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawStarPointsWithContext:(CGContextRef)context inTileRect:(CGRect)tileRect
{
  for (GoPoint* starPoint in [GoGame sharedGame].board.starPoints)
  {
    [BoardViewDrawingHelper drawLayer:starPointLayer
                          withContext:context
                      centeredAtPoint:starPoint
                       inTileWithRect:tileRect
                          withMetrics:self.playViewMetrics];
  }
}

@end
