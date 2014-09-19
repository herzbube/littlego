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
#import "BoardViewCGLayerCache.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"


@implementation GridLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a GridLayerDelegate object.
///
/// @note This is the designated initializer of GridLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GridLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
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
      [[BoardViewCGLayerCache sharedCache] invalidateLayerOfType:StarPointLayerType];
      self.dirty = true;
      break;
    }
    case BVLDEventInvalidateContent:
    {
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
  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];
  [self drawGridLinesWithContext:context inTileRect:tileRect];
  [self drawStarPointsWithContext:context inTileRect:tileRect];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawGridLinesWithContext:(CGContextRef)context inTileRect:(CGRect)tileRect
{
  for (NSValue* lineRectValue in self.boardViewMetrics.lineRectangles)
  {
    CGRect lineRect = [lineRectValue CGRectValue];
    CGRect drawingRect = CGRectIntersection(tileRect, lineRect);
    // Rectangles that are adjacent and share a side *do* intersect: The
    // intersection rectangle has either zero width or zero height, depending on
    // which side the two intersecting rectangles share. For this reason, we
    // must check CGRectIsEmpty() in addition to CGRectIsNull().
    if (CGRectIsNull(drawingRect) || CGRectIsEmpty(drawingRect))
      continue;
    drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:drawingRect
                                                     inTileWithRect:tileRect];
    CGContextSetFillColorWithColor(context, self.boardViewMetrics.lineColor.CGColor);
    CGContextFillRect(context, drawingRect);
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawStarPointsWithContext:(CGContextRef)context inTileRect:(CGRect)tileRect
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  CGLayerRef starPointLayer = [cache layerOfType:StarPointLayerType];
  if (! starPointLayer)
  {
    starPointLayer = CreateStarPointLayer(context, self.boardViewMetrics);
    [cache setLayer:starPointLayer ofType:StarPointLayerType];
    CGLayerRelease(starPointLayer);
  }

  for (GoPoint* starPoint in [GoGame sharedGame].board.starPoints)
  {
    [BoardViewDrawingHelper drawLayer:starPointLayer
                          withContext:context
                      centeredAtPoint:starPoint
                       inTileWithRect:tileRect
                          withMetrics:self.boardViewMetrics];
  }
}

@end
