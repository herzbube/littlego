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
#import "BoardViewDrawingHelper.h"
#import "../Tile.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"
#import "../../../ui/UiUtilities.h"


@implementation BoardViewDrawingHelper

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a star
/// point.
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
CGLayerRef CreateStarPointLayer(CGContextRef context, BoardViewMetrics* metrics)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = metrics.pointCellSize;
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
  const int startRadius = [UiUtilities radians:0];
  const int endRadius = [UiUtilities radians:360];
  const int clockwise = 0;
  CGContextAddArc(layerContext,
                  layerCenter.x,
                  layerCenter.y,
                  metrics.starPointRadius * metrics.contentsScale,
                  startRadius,
                  endRadius,
                  clockwise);
	CGContextSetFillColorWithColor(layerContext, metrics.starPointColor.CGColor);
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
CGLayerRef CreateStoneLayerWithImage(CGContextRef context, NSString* stoneImageName, BoardViewMetrics* metrics)
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
/// fits into the "inner square" rectangle (cf. BoardViewMetrics property
/// @e stoneInnerSquareSize). The symbol uses the specified color
/// @a symbolColor.
///
/// @see CreateDeadStoneSymbolLayer().
// -----------------------------------------------------------------------------
CGLayerRef CreateSquareSymbolLayer(CGContextRef context, UIColor* symbolColor, BoardViewMetrics* metrics)
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
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a "dead
/// stone" symbol.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateDeadStoneSymbolLayer(CGContextRef context, BoardViewMetrics* metrics)
{
  // The symbol for marking a dead stone is an "x"; we draw this as the two
  // diagonals of a Go stone's "inner square". We make the diagonals shorter by
  // making the square's size slightly smaller
  CGSize layerSize = metrics.stoneInnerSquareSize;
  layerSize.width *= metrics.contentsScale;
  layerSize.height *= metrics.contentsScale;
  CGFloat inset = floor(layerSize.width * (1.0 - metrics.deadStoneSymbolPercentage));
  layerSize.width -= inset * metrics.contentsScale;
  layerSize.height -= inset * metrics.contentsScale;

  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = layerSize;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGContextBeginPath(layerContext);
  CGContextMoveToPoint(layerContext, layerRect.origin.x, layerRect.origin.y);
  CGContextAddLineToPoint(layerContext, layerRect.origin.x + layerRect.size.width, layerRect.origin.y + layerRect.size.width);
  CGContextMoveToPoint(layerContext, layerRect.origin.x, layerRect.origin.y + layerRect.size.width);
  CGContextAddLineToPoint(layerContext, layerRect.origin.x + layerRect.size.width, layerRect.origin.y);
  CGContextSetStrokeColorWithColor(layerContext, metrics.deadStoneSymbolColor.CGColor);
  CGContextSetLineWidth(layerContext, metrics.normalLineWidth);
  CGContextStrokePath(layerContext);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to markup territory
/// in the specified style @a territoryMarkupStyle.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateTerritoryLayer(CGContextRef context, enum TerritoryMarkupStyle territoryMarkupStyle, BoardViewMetrics* metrics)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = metrics.pointCellSize;
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  UIColor* fillColor;
  switch (territoryMarkupStyle)
  {
    case TerritoryMarkupStyleBlack:
      fillColor = metrics.territoryColorBlack;
      break;
    case TerritoryMarkupStyleWhite:
      fillColor = metrics.territoryColorWhite;
      break;
    case TerritoryMarkupStyleInconsistentFillColor:
      fillColor = metrics.territoryColorInconsistent;
      break;
    case TerritoryMarkupStyleInconsistentDotSymbol:
      fillColor = metrics.inconsistentTerritoryDotSymbolColor;
      break;
    default:
      CGLayerRelease(layer);
      return NULL;
  }
  CGContextSetFillColorWithColor(layerContext, fillColor.CGColor);
  if (TerritoryMarkupStyleInconsistentDotSymbol == territoryMarkupStyle)
  {
    CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
    const int startRadius = [UiUtilities radians:0];
    const int endRadius = [UiUtilities radians:360];
    const int clockwise = 0;
    CGContextAddArc(layerContext,
                    layerCenter.x,
                    layerCenter.y,
                    metrics.stoneRadius * metrics.inconsistentTerritoryDotSymbolPercentage * metrics.contentsScale,
                    startRadius,
                    endRadius,
                    clockwise);
  }
  else
  {
    CGContextAddRect(layerContext, layerRect);
    CGContextSetBlendMode(layerContext, kCGBlendModeNormal);
  }
  CGContextFillPath(layerContext);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context so that
/// the layer is centered at the intersection specified by @a point.
///
/// The layer is not drawn if it does not intersect with the tile @a tileRect.
/// The tile rectangle origin must be in the canvas coordinate system.
// -----------------------------------------------------------------------------
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
   centeredAtPoint:(GoPoint*)point
    inTileWithRect:(CGRect)tileRect
       withMetrics:(BoardViewMetrics*)metrics
{
  CGRect layerRect = [BoardViewDrawingHelper canvasRectForScaledLayer:layer
                                                      centeredAtPoint:point
                                                              metrics:metrics];
  if (! CGRectIntersectsRect(tileRect, layerRect))
    return;
  CGRect drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:layerRect
                                                          inTileWithRect:tileRect];
  CGContextDrawLayerInRect(context, drawingRect, layer);
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
        withMetrics:(BoardViewMetrics*)metrics
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
/// @brief Draws the string @a string using the specified drawing context. The
/// text is drawn into a rectangle of the specified size, and the rectangle is
/// positioned so that it is centered at the intersection specified by @a point.
// -----------------------------------------------------------------------------
+ (void) drawString:(NSString*)string
        withContext:(CGContextRef)context
         attributes:(NSDictionary*)attributes
     inRectWithSize:(CGSize)size
    centeredAtPoint:(GoPoint*)point
     inTileWithRect:(CGRect)tileRect
        withMetrics:(BoardViewMetrics*)metrics
{
  CGRect textRect = [BoardViewDrawingHelper canvasRectForSize:size
                                              centeredAtPoint:point
                                                      metrics:metrics];
  if (! CGRectIntersectsRect(tileRect, textRect))
    return;

  CGRect drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:textRect
                                                          inTileWithRect:tileRect];

  UIGraphicsPushContext(context);
  [string drawInRect:drawingRect withAttributes:attributes];
  UIGraphicsPopContext();
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by @a tile on the "canvas", i.e. the
/// area covered by the entire board view. The origin is in the upper-left
/// corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForTile:(id<Tile>)tile
                     metrics:(BoardViewMetrics*)metrics
{
  CGRect canvasRect = CGRectZero;
  canvasRect.size = metrics.tileSize;
  // The tile with row/column = 0/0 is in the upper-left corner
  canvasRect.origin.x = tile.column * canvasRect.size.width;
  canvasRect.origin.y = tile.row * canvasRect.size.height;
  return canvasRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by a stone on the "canvas", i.e. the
/// area covered by the entire board view, after placing the stone so that it is
/// centered on the coordinates of the intersection @a point. The origin is in
/// the upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForStoneAtPoint:(GoPoint*)point
                             metrics:(BoardViewMetrics*)metrics
{
  return [BoardViewDrawingHelper canvasRectForSize:metrics.pointCellSize
                                   centeredAtPoint:point
                                           metrics:metrics];
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by @a layer on the "canvas", i.e. the
/// area covered by the entire board view, after placing @a layer so that it is
/// centered on the coordinates of the intersection @a point. The origin is in
/// the upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForScaledLayer:(CGLayerRef)layer
                    centeredAtPoint:(GoPoint*)point
                            metrics:(BoardViewMetrics*)metrics
{
  CGPoint pointCoordinates = [metrics coordinatesFromPoint:point];

  CGRect drawingRect = [BoardViewDrawingHelper drawingRectForScaledLayer:layer
                                                             withMetrics:metrics];
  CGPoint drawingCenter = CGPointMake(CGRectGetMidX(drawingRect), CGRectGetMidY(drawingRect));

  CGRect canvasRect;
  canvasRect.size = drawingRect.size;
  canvasRect.origin.x = pointCoordinates.x - drawingCenter.x;
  canvasRect.origin.y = pointCoordinates.y - drawingCenter.y;
  return canvasRect;
}

// todo xxx document
+ (CGRect) canvasRectForSize:(CGSize)size
             centeredAtPoint:(GoPoint*)point
                     metrics:(BoardViewMetrics*)metrics
{
  CGRect canvasRect = CGRectZero;
  canvasRect.size = size;
  CGPoint canvasRectCenter = CGPointMake(CGRectGetMidX(canvasRect), CGRectGetMidY(canvasRect));
  CGPoint pointCoordinates = [metrics coordinatesFromPoint:point];
  canvasRect.origin.x = pointCoordinates.x - canvasRectCenter.x;
  canvasRect.origin.y = pointCoordinates.y - canvasRectCenter.y;
  return canvasRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle that must be passed to CGContextDrawLayerInRect
/// for drawing the specified layer, which must have a size that is scaled up
/// using @e metrics.contentScale.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForScaledLayer:(CGLayerRef)layer
                         withMetrics:(BoardViewMetrics*)metrics
{
  CGSize drawingSize = CGLayerGetSize(layer);
  drawingSize.width /= metrics.contentsScale;
  drawingSize.height /= metrics.contentsScale;
  CGRect drawingRect;
  drawingRect.origin = CGPointZero;
  drawingRect.size = drawingSize;
  return drawingRect;
}

// todo xxx document
+ (CGRect) drawingRectFromCanvasRect:(CGRect)canvasRect
                      inTileWithRect:(CGRect)tileRect
{
  CGRect drawingRect = canvasRect;
  drawingRect.origin.x -= tileRect.origin.x;
  drawingRect.origin.y -= tileRect.origin.y;
  return drawingRect;
}

@end
