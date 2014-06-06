// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"
#import "../../../ui/UiUtilities.h"


@implementation PlayViewDrawingHelper

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a horizontal
/// grid line that uses the specified color @a lineColor and width @a lineWidth.
///
/// If the grid line should be drawn vertically, a 90 degrees rotation must be
/// added to the CTM before drawing.
///
/// All sizes are taken from the current metrics values.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateLineLayer(CGContextRef context, UIColor* lineColor, int lineWidth, PlayViewMetrics* metrics)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = CGSizeMake(metrics.lineLength, lineWidth);
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGContextSetFillColorWithColor(layerContext, lineColor.CGColor);
  CGContextFillRect(layerContext, layerRect);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context so that
/// the layer is suitably placed with @a point as the reference.
///
/// The numeric vertex of @a point is also used to determine whether the line
/// to be drawn is a normal or a bounding line.
///
/// @note This method assumes that @a layer contains the drawing operations for
/// rendering a horizontal line. If @a horizontal is false, the CTM will
/// therefore be rotated to make the line point downwards.
// -----------------------------------------------------------------------------
+ (void) drawLineLayer:(CGLayerRef)layer
           withContext:(CGContextRef)context
            horizontal:(bool)horizontal
     positionedAtPoint:(GoPoint*)point
           withMetrics:(PlayViewMetrics*)metrics
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  int lineIndexCountingFromTopLeft;
  if (horizontal)
    lineIndexCountingFromTopLeft = metrics.boardSize - numericVertex.y;
  else
    lineIndexCountingFromTopLeft = numericVertex.x - 1;
  bool isBoundingLineLeftOrTop = (0 == lineIndexCountingFromTopLeft);
  bool isBoundingLineRightOrBottom = ((metrics.boardSize - 1) == lineIndexCountingFromTopLeft);
  // Line layer must refer to a horizontal line
  CGRect drawingRect = [PlayViewDrawingHelper drawingRectForScaledLayer:layer withMetrics:metrics];
  CGFloat lineHalfWidth = drawingRect.size.height / 2.0;

  // Create a save point that we can restore to before we leave this method
  CGContextSaveGState(context);

  CGPoint pointCoordinates = [metrics coordinatesFromPoint:point];
  if (horizontal)
  {
    // Place line so that its upper-left corner is at the y-position of the
    // specified intersections
    CGContextTranslateCTM(context, metrics.topLeftPointX, pointCoordinates.y);
    // Place line so that it straddles the y-position of the specified
    // intersection
    CGContextTranslateCTM(context, 0, -lineHalfWidth);
    // If it's a bounding line, adjust the line position so that its edge is
    // in the same position as if a normal line were drawn. The surplus width
    // lies outside of the board. As a result, all cells inside the board have
    // the same size.
    if (isBoundingLineLeftOrTop)
      CGContextTranslateCTM(context, 0, -metrics.boundingLineStrokeOffset);
    else if (isBoundingLineRightOrBottom)
      CGContextTranslateCTM(context, 0, metrics.boundingLineStrokeOffset);
    // Adjust horizontal line position so that it starts at the left edge of
    // the left bounding line
    CGContextTranslateCTM(context, -metrics.lineStartOffset, 0);
  }
  else
  {
    // Perform translations as if the line were already vertical, pointing
    // downwards from the top-left origin. We are going to perform the rotation
    // further down, but only *AFTER* doing translations; if we were rotating
    // *BEFORE* doing translations, we would have to swap x/y translation
    // components, which would be very confusing and potentially dangerous to
    // the brain of whoever tries to debug this code :-)
    CGContextTranslateCTM(context, pointCoordinates.x, metrics.topLeftPointY);
    CGContextTranslateCTM(context, -lineHalfWidth, 0);  // use y-coordinate because layer rect is horizontal
    if (isBoundingLineLeftOrTop)
      CGContextTranslateCTM(context, -metrics.boundingLineStrokeOffset, 0);
    else if (isBoundingLineRightOrBottom)
      CGContextTranslateCTM(context, metrics.boundingLineStrokeOffset, 0);
    CGContextTranslateCTM(context, 0, -metrics.lineStartOffset);
    // Shift all vertical lines 1 point to the right. This is what I call
    // "the mystery point" - I couldn't come up with a satisfactory explanation
    // why this is needed even after hours of geometric drawings and manual
    // calculations. Very unsatisfactory :-(
    CGContextTranslateCTM(context, 1, 0);
    // We are finished with regular translations and are now almost ready to
    // rotate. However, we must still perform one final translation: The one
    // that makes sure that the rotation will align the left (not the right!)
    // border of the line with y-coordinate 0. If this is hard to understand,
    // take a piece of paper and make some drawings. Keep in mind that the
    // origin used for rotation will also be moved by CTM translations (or maybe
    // it's more intuitive to imagine that any artifact will be rotated
    // "in place")!
    CGContextTranslateCTM(context, drawingRect.size.height, 0);
    // Phew, done, finally we can rotate.
    CGContextRotateCTM(context, [UiUtilities radians:90]);
  }
  // Half-pixel translation to prevent unnecessary anti-aliasing. We need this
  // because above at some point we perform a translation that lets the line
  // straddle the intersection.
  CGContextTranslateCTM(context, gHalfPixel, gHalfPixel);

  // Because of the CTM adjustments, we can now draw into a rect with origin
  // CGPointZero
  CGContextDrawLayerInRect(context, drawingRect, layer);

  // Restore the drawing context to undo CTM adjustments
  CGContextRestoreGState(context);
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a stone that
/// uses the specified color @a stoneColor.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
///
/// @note This method is currently not in use, it has been superseded by
/// stoneLayerWithContext:stoneImageNamed:(). This method is preserved for
/// demonstration purposes, i.e. how to draw a simple circle with a fill color.
// -----------------------------------------------------------------------------
CGLayerRef CreateStoneLayerWithColor(CGContextRef context, UIColor* stoneColor, PlayViewMetrics* metrics)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = metrics.pointCellSize;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
  const int startRadius = [UiUtilities radians:0];
  const int endRadius = [UiUtilities radians:360];
  const int clockwise = 0;

  // Half-pixel translation is added at the time when the layer is actually
  // drawn
  CGContextAddArc(layerContext,
                  layerCenter.x,
                  layerCenter.y,
                  metrics.stoneRadius,
                  startRadius,
                  endRadius,
                  clockwise);
  CGContextSetFillColorWithColor(layerContext, stoneColor.CGColor);
  CGContextFillPath(layerContext);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a stone that
/// uses the bitmap image in the bundle resource file named @a name.
///
/// All sizes are taken from the current metrics values.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateStoneLayerWithImage(CGContextRef context, NSString* stoneImageName, PlayViewMetrics* metrics)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = metrics.pointCellSize;
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  // The values assigned here have been determined experimentally
  CGFloat yAxisAdjustmentToVerticallyCenterImageOnIntersection;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    yAxisAdjustmentToVerticallyCenterImageOnIntersection = 0.5;
  }
  else
  {
    switch (metrics.boardSize)
    {
      case GoBoardSize7:
      case GoBoardSize9:
        yAxisAdjustmentToVerticallyCenterImageOnIntersection = 2.0;
        break;
      default:
        yAxisAdjustmentToVerticallyCenterImageOnIntersection = 1.0;
        break;
    }
  }
  CGContextTranslateCTM(layerContext, 0, yAxisAdjustmentToVerticallyCenterImageOnIntersection);

  UIImage* stoneImage = [UIImage imageNamed:stoneImageName];
  // Let UIImage do all the drawing for us. This includes 1) compensating for
  // coordinate system differences (if we use CGContextDrawImage() the image
  // is drawn upside down); and 2) for scaling.
  UIGraphicsPushContext(layerContext);
  [stoneImage drawInRect:layerRect];
  UIGraphicsPopContext();

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a symbol that
/// fits into the "inner square" rectangle (cf. PlayViewMetrics property
/// @e stoneInnerSquareSize). The symbol uses the specified color
/// @a symbolColor.
///
/// @see CreateDeadStoneSymbolLayer().
// -----------------------------------------------------------------------------
CGLayerRef CreateSquareSymbolLayer(CGContextRef context, UIColor* symbolColor, PlayViewMetrics* metrics)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = metrics.stoneInnerSquareSize;
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;
  // It looks better if the marker is slightly inset, and on the iPad we can
  // afford to waste the space
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
  {
    layerRect.size.width -= 2 * metrics.contentsScale;
    layerRect.size.height -= 2 * metrics.contentsScale;
  }
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  // Half-pixel translation is added at the time when the layer is actually
  // drawn
  CGContextBeginPath(layerContext);
  CGContextAddRect(layerContext, layerRect);
  CGContextSetStrokeColorWithColor(layerContext, symbolColor.CGColor);
  CGContextSetLineWidth(layerContext, metrics.normalLineWidth);
  CGContextStrokePath(layerContext);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context so that
/// the layer is centered at the intersection specified by @a point.
// -----------------------------------------------------------------------------
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
   centeredAtPoint:(GoPoint*)point
       withMetrics:(PlayViewMetrics*)metrics
{
  // Create a save point that we can restore to before we leave this method
  CGContextSaveGState(context);

  // Adjust the CTM as if we were drawing the layer with its upper-left corner
  // at the specified intersection
  CGPoint pointCoordinates = [metrics coordinatesFromPoint:point];
  CGContextTranslateCTM(context,
                        pointCoordinates.x,
                        pointCoordinates.y);
  // Align the layer center with the intersection
  CGRect drawingRect = [PlayViewDrawingHelper drawingRectForScaledLayer:layer withMetrics:metrics];
  CGPoint layerCenter = CGPointMake(CGRectGetMidX(drawingRect), CGRectGetMidY(drawingRect));
  CGContextTranslateCTM(context, -layerCenter.x, -layerCenter.y);
  // Half-pixel translation to prevent unnecessary anti-aliasing
  CGContextTranslateCTM(context, gHalfPixel, gHalfPixel);

  // Because of the CTM adjustments, we can now draw into a rect with origin
  // CGPointZero
  CGContextDrawLayerInRect(context, drawingRect, layer);

  // Restore the drawing context to undo CTM adjustments
  CGContextRestoreGState(context);
}

// -----------------------------------------------------------------------------
/// @brief Draws the string @a string using the specified drawing context. The
/// text is drawn into a rectangle of the specified size, and the rectangle is
/// positioned so that it is centered at the intersection specified by @a point.
// -----------------------------------------------------------------------------
+ (void) drawString:(NSString*)string
        withContext:(CGContextRef)context
         attributes:(NSDictionary*)attributes
     inRectWithSize:(CGSize)size
    centeredAtPoint:(GoPoint*)point
        withMetrics:(PlayViewMetrics*)metrics
{
  // Create a save point that we can restore to before we leave this method
  CGContextSaveGState(context);

  // The text is drawn into this rectangle. The rect origin will remain at
  // CGPointZero because we are going to use CTM translations for positioning.
  CGRect textRect = CGRectZero;
  textRect.size = size;

  // Adjust the CTM as if we were drawing the text with its upper-left corner
  // at the specified intersection
  CGPoint pointCoordinates = [metrics coordinatesFromPoint:point];
  CGContextTranslateCTM(context,
                        pointCoordinates.x,
                        pointCoordinates.y);

  // Adjust the CTM to align the rect center with the intersection
  CGPoint textRectCenter = CGPointMake(CGRectGetMidX(textRect), CGRectGetMidY(textRect));
  CGContextTranslateCTM(context, -textRectCenter.x, -textRectCenter.y);

  [string drawInRect:textRect withAttributes:attributes];

  // Restore the drawing context to undo CTM adjustments
  CGContextRestoreGState(context);
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle that must be passed to CGContextDrawLayerInRect
/// for drawing the specified layer, which must have a size that is scaled up
/// using @e metrics.contentScale.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForScaledLayer:(CGLayerRef)layer
                         withMetrics:(PlayViewMetrics*)metrics
{
  CGSize drawingSize = CGLayerGetSize(layer);
  drawingSize.width /= metrics.contentsScale;
  drawingSize.height /= metrics.contentsScale;
  CGRect drawingRect;
  drawingRect.origin = CGPointZero;
  drawingRect.size = drawingSize;
  return drawingRect;
}
@end
