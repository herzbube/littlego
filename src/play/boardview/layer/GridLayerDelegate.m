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


NSMutableArray* lineRectangles = nil;


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
  if (lineRectangles)
  {
    [lineRectangles release];
    lineRectangles = nil;  // when it is next invoked, drawLayer:inContext:() will re-create and populate the array
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
  if (! lineRectangles)
  {
    lineRectangles = [BVGridLayerDelegate calculateLineRectanglesWithMetrics:self.playViewMetrics];
    [lineRectangles retain];
  }

  CGRect canvasRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                            metrics:self.playViewMetrics];
  for (NSValue* lineRectValue in lineRectangles)
  {
    CGRect lineRect = [lineRectValue CGRectValue];
    CGRect drawingRect = CGRectIntersection(canvasRect, lineRect);
    if (CGRectIsNull(drawingRect))
      continue;
    drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:drawingRect
                                                     inTileWithRect:canvasRect];
    CGContextSetFillColorWithColor(context, self.playViewMetrics.lineColor.CGColor);
    CGContextFillRect(context, drawingRect);
  }
}

// TODO xxx move this to drawing helper
+ (NSMutableArray*) calculateLineRectanglesWithMetrics:(PlayViewMetrics*)metrics
{
  NSMutableArray* lineRectangles = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

  GoPoint* topLeftPoint = [[GoGame sharedGame].board topLeftPoint];
  for (int lineDirection = 0; lineDirection < 2; ++lineDirection)
  {
    bool isHorizontalLine = (0 == lineDirection) ? true : false;
    GoPoint* previousPoint = nil;
    GoPoint* currentPoint = topLeftPoint;
    while (currentPoint)
    {
      GoPoint* nextPoint;
      if (isHorizontalLine)
        nextPoint = currentPoint.below;
      else
        nextPoint = currentPoint.right;
      CGPoint pointCoordinates = [metrics coordinatesFromPoint:currentPoint];

      int lineWidth;
      bool isBoundingLine = (nil == previousPoint || nil == nextPoint);
      if (isBoundingLine)
        lineWidth = metrics.boundingLineWidth;
      else
        lineWidth = metrics.normalLineWidth;
      CGFloat lineHalfWidth = lineWidth / 2.0f;

      struct GoVertexNumeric numericVertex = currentPoint.vertex.numeric;
      int lineIndexCountingFromTopLeft;
      if (isHorizontalLine)
        lineIndexCountingFromTopLeft = metrics.boardSize - numericVertex.y;
      else
        lineIndexCountingFromTopLeft = numericVertex.x - 1;
      bool isBoundingLineLeftOrTop = (0 == lineIndexCountingFromTopLeft);
      bool isBoundingLineRightOrBottom = ((metrics.boardSize - 1) == lineIndexCountingFromTopLeft);

      CGRect lineRect;
      if (isHorizontalLine)
      {
        // 1. Determine the rectangle size. Everything below this deals with
        // the rectangle origin.
        lineRect.size = CGSizeMake(metrics.lineLength, lineWidth);
        // 2. Place line so that its upper-left corner is at the y-position of
        // the specified intersection
        lineRect.origin.x = metrics.topLeftPointX;
        lineRect.origin.y = pointCoordinates.y;
        // 3. Place line so that it straddles the y-position of the specified
        // intersection
        lineRect.origin.y -= lineHalfWidth;
        // 4. If it's a bounding line, adjust the line position so that its edge
        // is in the same position as if a normal line were drawn. The surplus
        // width lies outside of the board. As a result, all cells inside the
        // board have the same size.
        if (isBoundingLineLeftOrTop)
          lineRect.origin.y -= metrics.boundingLineStrokeOffset;
        else if (isBoundingLineRightOrBottom)
          lineRect.origin.y += metrics.boundingLineStrokeOffset;
        // 5. Adjust horizontal line position so that it starts at the left edge
        // of the left bounding line
        lineRect.origin.x -= metrics.lineStartOffset;
      }
      else
      {
        // The if-branch above that deals with horizontal lines has more
        // detailed comments.

        // 1. Rectangle size
        lineRect.size = CGSizeMake(lineWidth, metrics.lineLength);
        // 2. Initial rectangle origin
        lineRect.origin.x = pointCoordinates.x;
        lineRect.origin.y = metrics.topLeftPointY;
        // 3. Straddle intersection
        lineRect.origin.x -= lineHalfWidth;
        // 4. Position bounding lines
        if (isBoundingLineLeftOrTop)
          lineRect.origin.x -= metrics.boundingLineStrokeOffset;
        else if (isBoundingLineRightOrBottom)
          lineRect.origin.x += metrics.boundingLineStrokeOffset;
        // 5. Adjust vertical line position
        lineRect.origin.y -= metrics.lineStartOffset;
        // Shift all vertical lines 1 point to the right. This is what I call
        // "the mystery point" - I couldn't come up with a satisfactory
        // explanation why this is needed even after hours of geometric drawings
        // and manual calculations. Very unsatisfactory :-(
        // TODO xxx It appears that this is no longer necessary. If this is
        // true, then close the corresponding GitHub issue. The reason probably
        // is connected with the CTM rotation that we did in the old drawing
        // mechanism.
        //lineRect.origin.x += 1;
      }

      [lineRectangles addObject:[NSValue valueWithCGRect:lineRect]];

      previousPoint = currentPoint;
      currentPoint = nextPoint;
    }
  }

  return lineRectangles;
}

@end
