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


// todo xxx dumb name because of name collision with crosshairlineslayerdelegate
NSArray* lineRectangles1 = nil;


@implementation BVGridLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a GridLayerDelegate object.
///
/// @note This is the designated initializer of GridLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTileView:(BoardTileView*)tileView metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTileView:tileView metrics:metrics];
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
  // TODO xxx cannot release the lineRectangles array, other tile views might
  // still depend on it. someone else should be the holder of the array, e.g.
  // PlayViewMetrics?
  //[self invalidateLineRectangles];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates pre-calculated line rectangles. Invoke this if the board
/// geometry changes.
// -----------------------------------------------------------------------------
- (void) invalidateLineRectangles
{
  if (lineRectangles1)
  {
    [lineRectangles1 release];
    lineRectangles1 = nil;  // when it is next invoked, drawLayer:inContext:() will re-create and populate the array
  }
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case BVLDEventRectangleChanged:
    {
      CGRect layerFrame = CGRectZero;
      layerFrame.size = self.playViewMetrics.tileSize;
      self.layer.frame = layerFrame;
      [self invalidateLineRectangles];
      self.dirty = true;
      break;
    }
    case BVLDEventBoardSizeChanged:
    {
      [self invalidateLineRectangles];
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
  if (! [GoGame sharedGame])
    return;
  DDLogVerbose(@"GridLayerDelegate is drawing");

  // There are many GridLayerDelegate instances around - whichever instance gets
  // here first re-creates and populates the lineRectangles array for all the
  // other instances
  if (! lineRectangles1)
  {
    lineRectangles1 = [BoardViewDrawingHelper calculateLineRectanglesStartingAtTopLeftPoint:[[GoGame sharedGame].board topLeftPoint]
                                                                                withMetrics:self.playViewMetrics];
    [lineRectangles1 retain];
  }

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];
  for (NSValue* lineRectValue in lineRectangles1)
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

@end
