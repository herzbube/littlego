// -----------------------------------------------------------------------------
// Copyright 2014-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewCGLayerCache.h"
#import "../../model/BoardViewMetrics.h"
#import "../../model/MarkupModel.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"
#import "../../../shared/LayoutManager.h"
#import "../../../ui/Tile.h"
#import "../../../ui/CGDrawingHelper.h"
#import "../../../ui/GoDrawingHelper.h"
#import "../../../ui/UiUtilities.h"


@implementation BoardViewDrawingHelper

// -----------------------------------------------------------------------------
/// @brief Returns true if @a rect is not a valid rectangle for drawing with
/// Core Graphics. Returns false if @a rect is a valid rectangle. A rectangle
/// is not valid if one or more of its 4 components (x, y, width, height) is NaN
/// and/or Inf, or if the rectangle's width and/or height are less than zero.
///
/// If CGLayerCreateWithContext is invoked with an invalid rectangle, the
/// function returns NULL instead of a CGLayer object, so a NULL check may be
/// used instead of invoking this function to test for rectangle validity.
///
/// Other Core Graphics drawing functions that operate on invalid values will
/// also refuse to draw anything, but in addition they generate warnings that
/// are visible in Xcode's debug console and are distracting from other, more
/// important console output. This function is therefore useful to avoid
/// invalid drawing operations and unnecessary warnings.
///
/// @note This checking function became necessary when it became possible for
/// the user to resize the board view to extremely small dimensions.
// -----------------------------------------------------------------------------
bool IsRectangleInvalid(CGRect rect)
{
  // isfinite includes the check for NaN
  if (!isfinite(rect.origin.x) || !isfinite(rect.origin.y) || !isfinite(rect.size.width) || !isfinite(rect.size.height))
    return true;

  if (rect.size.width < 0.0f || rect.size.height < 0.0f)
    return true;

  return false;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a star
/// point.
///
/// All sizes are taken from the metrics values in @a metrics. This function may
/// return @e NULL instead of a CGLayer object if the metrics values in
/// @a metrics refer to a board with extremely small dimensions.
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
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
  CGFloat radius = metrics.starPointRadius * metrics.contentsScale;

  [CGDrawingHelper drawCircleWithContext:layerContext
                                  center:layerCenter
                                  radius:radius
                               fillColor:metrics.starPointColor
                             strokeColor:nil
                         strokeLineWidth:0.0f];

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a stone that
/// uses the bitmap image in the bundle resource file named @a name.
///
/// All sizes are taken from the metrics values in @a metrics. This function may
/// return @e NULL instead of a CGLayer object if the metrics values in
/// @a metrics refer to a board with extremely small dimensions.
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
  CGLayerRef layer = CreateStoneLayer(context, metrics);

  CGContextRef layerContext = CGLayerGetContext(layer);
  CGRect layerRect = CGRectZero;
  layerRect.size = CGLayerGetSize(layer);

  [CGDrawingHelper drawImageWithContext:layerContext
                                 inRect:layerRect
                              imageName:stoneImageName];

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a stone the
/// color of which is determined by @a stoneColor and @a isCrossHairStone (the
/// latter indicates whether the stone has its natural color or uses a special
/// cross-hair stone color).
///
/// All sizes are taken from the metrics values in @a metrics. This function may
/// return @e NULL instead of a CGLayer object if the metrics values in
/// @a metrics refer to a board with extremely small dimensions.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateStoneLayerWithCoreGraphics(CGContextRef context, enum GoColor stoneColor, bool isCrossHairStone, BoardViewMetrics* metrics)
{
  CGLayerRef layer = CreateStoneLayer(context, metrics);

  CGContextRef layerContext = CGLayerGetContext(layer);
  CGRect layerRect = CGRectZero;
  layerRect.size = CGLayerGetSize(layer);

  [GoDrawingHelper draw3dStoneWithContext:layerContext
                        boundingRectangle:layerRect
                               stoneColor:stoneColor
                         isCrossHairStone:isCrossHairStone];

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for CreateStoneLayerWithImage() and
/// CreateStoneLayerWithCoreGraphics(). The returned CGLayer is ready to receive
/// the drawing operations to draw a Go stone.
// -----------------------------------------------------------------------------
CGLayerRef CreateStoneLayer(CGContextRef context, BoardViewMetrics* metrics)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = metrics.pointCellSize;
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;

  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  // The y-axis adjustment made here is done because the Go stone will be drawn
  // with a shadow at the bottom, which causes the main stone circle center to
  // be slightly offset in y-direction in relation to the layer center. The
  // y-axis adjustment "pushes" the stone slightly downwards. The drawback of
  // this is that the stone shadow does not fully fit into the layer and a bit
  // of it will be cut off.
  // Note: The values assigned here have been determined experimentally.
  CGFloat yAxisAdjustmentToVerticallyCenterImageOnIntersection;
  if ([LayoutManager sharedManager].uiType != UITypePad)
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

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a symbol that
/// fits into the "inner square" rectangle (cf. BoardViewMetrics property
/// @e stoneInnerSquareSize). The symbol uses the specified color
/// @a symbolColor as the stroke color.
///
/// All sizes are taken from the metrics values in @a metrics. This function may
/// return @e NULL instead of a CGLayer object if the metrics values in
/// @a metrics refer to a board with extremely small dimensions.
///
/// @see CreateDeadStoneSymbolLayer().
// -----------------------------------------------------------------------------
CGLayerRef CreateSymbolLayer(CGContextRef context, enum GoMarkupSymbol symbol, UIColor* symbolFillColor, UIColor* symbolStrokeColor, MarkupModel* markupModel, BoardViewMetrics* metrics)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = metrics.stoneInnerSquareSize;
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;

  // If the layer size is large enough (look at the size after scaling) we use a
  // heavier stroke to give the markup symbol more weight. If the layer size is
  // below a certain threshold (unzoomed big board on small devices) we use the
  // regular stroke because the heavy stroke looks "blocky".
  // The threshold was experimentally determined to look good on an iPhone 5S.
  CGFloat strokeWeight;
  if (layerRect.size.width <= 30.0f)
    strokeWeight = 1.0f;
  else
    strokeWeight = 2.0f;
  CGFloat strokeLineWidth = metrics.normalLineWidth * strokeWeight * metrics.contentsScale;

  // Inset the drawing rect so that the stroke is not clipped
  CGRect drawingRect = CGRectInset(layerRect, strokeLineWidth, strokeLineWidth);

  if (symbol == GoMarkupSymbolTriangle)
  {
    // Slightly adjust the triangle's y-position, by one point, so that it looks
    // properly centered on the intersection. We can't do this by adjusting the
    // drawing rect (drawingRect.origin.y -= 1.0f * metrics.contentsScale)
    // because then the stroke of the triangle will be clipped. Instead we
    // adjust the layer rect height AFTER the drawing rect was calculated - the
    // drawing rect is now no longer vertically centered within the layer rect
    // but slightly shifted upwards. Because we know that later on the layer
    // will be drawn centered on an intersection, we have to add TWO points to
    // the layer rect height, to make sure that the layer's vertical center does
    // not change when it will be drawn eventually.
    layerRect.size.height += 2.0f * metrics.contentsScale;
  }

  if (IsRectangleInvalid(drawingRect))
    return NULL;

  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  // Half-pixel translation is added at the time when the layer is actually
  // drawn

  switch (symbol)
  {
    case GoMarkupSymbolCircle:
    {
      CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
      CGFloat radius = floorf(drawingRect.size.width / 2.0f);

      [CGDrawingHelper drawCircleWithContext:layerContext
                                      center:layerCenter
                                      radius:radius
                                   fillColor:nil
                                 strokeColor:symbolStrokeColor
                             strokeLineWidth:strokeLineWidth];
      break;
    }
    case GoMarkupSymbolSquare:
    {
      [CGDrawingHelper drawRectangleWithContext:layerContext
                                      rectangle:drawingRect
                                      fillColor:nil
                                    strokeColor:symbolStrokeColor
                                strokeLineWidth:strokeLineWidth];
      break;
    }
    case GoMarkupSymbolTriangle:
    {
      [CGDrawingHelper drawTriangleWithContext:layerContext
                               insideRectangle:drawingRect
                                     fillColor:nil
                                   strokeColor:symbolStrokeColor
                               strokeLineWidth:strokeLineWidth];
      break;
    }
    case GoMarkupSymbolX:
    {
      [CGDrawingHelper drawSymbolXWithContext:layerContext
                              insideRectangle:drawingRect
                                  strokeColor:symbolStrokeColor
                              strokeLineWidth:strokeLineWidth];
      break;
    }
    case GoMarkupSymbolSelected:
    {
      if (markupModel.selectedSymbolMarkupStyle == SelectedSymbolMarkupStyleDotSymbol)
      {
        CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
        CGFloat radius = floorf(drawingRect.size.width / 2.0f);

        [CGDrawingHelper drawCircleWithContext:layerContext
                                        center:layerCenter
                                        radius:radius
                                     fillColor:symbolFillColor
                                   strokeColor:symbolStrokeColor
                               strokeLineWidth:1.0f];
      }
      else
      {
        [CGDrawingHelper drawCheckmarkWithContext:layerContext
                                  insideRectangle:drawingRect
                                      strokeColor:symbolStrokeColor
                                  strokeLineWidth:strokeLineWidth];
      }
      break;
    }
  }

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a connection
/// between two intersections on the board. @a canvasRect describes a rectangle
/// that has the two intersections at diagonally opposed corners. The connection
/// uses @a connectionFillColor and @a connectionStrokeColor to fill and stroke
/// the connection.
///
/// If @a fromPoint is the same as @a toPoint, the connection is drawn as a
/// stub that starts at @a fromPoint and extends horizontally to the right edge
/// of the layer.
///
/// Drawing the connection with a stroke is important so that it remains
/// distinguishable even if it is drawn over content that has the same color as
/// the connection fill color (e.g. white connection over a white stone).
///
/// All sizes are taken from the metrics values in @a metrics. This function may
/// return @e NULL instead of a CGLayer object if the metrics values in
/// @a metrics refer to a board with extremely small dimensions.
// -----------------------------------------------------------------------------
CGLayerRef CreateConnectionLayer(CGContextRef context, enum GoMarkupConnection connection, UIColor* connectionFillColor, UIColor* connectionStrokeColor, GoPoint* fromPoint, GoPoint* toPoint, CGRect canvasRect, BoardViewMetrics* metrics)
{
  CGRect layerRect = CGRectMake(0.0f, 0.0f, canvasRect.size.width, canvasRect.size.height);
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;

  // Don't multiply with metrics.contentsScale, always use only a very fine
  // stroke line
  CGFloat strokeLineWidth = metrics.normalLineWidth;

  CGPoint fromPointCoordinates = [metrics coordinatesFromPoint:fromPoint];
  fromPointCoordinates.x -= canvasRect.origin.x;
  fromPointCoordinates.y -= canvasRect.origin.y;

  CGPoint toPointCoordinates;
  if (fromPoint == toPoint)
  {
    toPointCoordinates.x = canvasRect.size.width - strokeLineWidth;
    toPointCoordinates.y = fromPointCoordinates.y;
  }
  else
  {
    toPointCoordinates = [metrics coordinatesFromPoint:toPoint];
    toPointCoordinates.x -= canvasRect.origin.x;
    toPointCoordinates.y -= canvasRect.origin.y;
  }

  fromPointCoordinates.x *= metrics.contentsScale;
  fromPointCoordinates.y *= metrics.contentsScale;
  toPointCoordinates.x *= metrics.contentsScale;
  toPointCoordinates.y *= metrics.contentsScale;

  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  // Half-pixel translation is added at the time when the layer is actually
  // drawn
  CGContextBeginPath(layerContext);

  // In theory we could use a lighter weight if metrics.pointCellSize falls
  // below a certain threshold (same way we do for symbols drawing). However,
  // in practice connection lines become too thin with a lighter weight - so
  // currently we always use a weight heavier than 1.0.
  static const CGFloat connectionWeight = 2.0f;
  // Use the wider bounding line, not the normal line, as the base value,
  // otherwise connections are not noticeable enough
  CGFloat tailWidth = metrics.boundingLineWidth * connectionWeight * metrics.contentsScale;
  CGFloat headWidth;
  CGFloat headLength;

  if (connection == GoMarkupConnectionArrow)
  {
    // Use a relatively wide arrow head to make it distinct. On smaller
    // metrics.pointCellSize this can look quite blocky and a bit ugly, but
    // it has to be to remain noticeable. On the smallest metrics.pointCellSize
    // (smallest devices like iPhone 5S, board size 19) this results in an arrow
    // head that is as large as the entire metrics.pointCellSize - for that
    // reason we make sure that the head does not get wider than two thirds of
    // metrics.pointCellSize.
    //
    // In theory we could make the head smaller if the distance between the
    // points falls below a certain threshold. However, this could result in
    // arrows with differently sized heads being visible at the same time. Not
    // only does this look ugly - it looks ***WRONG***. So whatever criteria
    // might be chosen in the future - make sure that all arrows use the same
    // heads size on the same zoom level.
    static const CGFloat headWeight = 4.0f;
    headWidth = tailWidth * headWeight;
    headWidth = fminf(headWidth, metrics.pointCellSize.width * metrics.contentsScale * 2.0 / 3.0f);
    // Make the arrow head square
    headLength = headWidth;
  }
  else
  {
    headWidth = 0;
    headLength = 0;
  }

  CGPathRef arrowPath = [BoardViewDrawingHelper newPathWithArrowFromPoint:fromPointCoordinates
                                                                  toPoint:toPointCoordinates
                                                                tailWidth:tailWidth
                                                                headWidth:headWidth
                                                               headLength:headLength];
  CGContextAddPath(layerContext, arrowPath);

  [CGDrawingHelper fillOrStrokePathWithContext:layerContext
                                     fillColor:connectionFillColor
                                   strokeColor:connectionStrokeColor
                               strokeLineWidth:strokeLineWidth];

  CGPathRelease(arrowPath);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a square
/// symbol that fits into the "inner square" rectangle (cf. BoardViewMetrics
/// property @e stoneInnerSquareSize). The symbol uses the specified color
/// @a symbolColor.
///
/// All sizes are taken from the metrics values in @a metrics. This function may
/// return @e NULL instead of a CGLayer object if the metrics values in
/// @a metrics refer to a board with extremely small dimensions.
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

  CGFloat strokeLineWidth = metrics.normalLineWidth * metrics.contentsScale;

  // Inset the drawing rect so that the stroke is not clipped
  CGRect drawingRect = CGRectInset(layerRect, strokeLineWidth, strokeLineWidth);

  if (IsRectangleInvalid(drawingRect))
    return NULL;

  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  // Half-pixel translation is added at the time when the layer is actually
  // drawn
  [CGDrawingHelper drawRectangleWithContext:layerContext
                                  rectangle:drawingRect
                                  fillColor:nil
                                strokeColor:symbolColor
                            strokeLineWidth:strokeLineWidth];

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a "dead
/// stone" symbol.
///
/// All sizes are taken from the metrics values in @a metrics. This function may
/// return @e NULL instead of a CGLayer object if the metrics values in
/// @a metrics refer to a board with extremely small dimensions.
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
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  [CGDrawingHelper drawSymbolXWithContext:layerContext
                          insideRectangle:layerRect
                              strokeColor:metrics.deadStoneSymbolColor
                          strokeLineWidth:metrics.normalLineWidth * metrics.contentsScale];

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to markup territory
/// in the specified style @a territoryMarkupStyle.
///
/// All sizes are taken from the metrics values in @a metrics. This function may
/// return @e NULL instead of a CGLayer object if the metrics values in
/// @a metrics refer to a board with extremely small dimensions.
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
  if (! layer)
    return NULL;

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

  if (TerritoryMarkupStyleInconsistentDotSymbol == territoryMarkupStyle)
  {
    CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
    CGFloat radius = metrics.stoneRadius * metrics.inconsistentTerritoryDotSymbolPercentage * metrics.contentsScale;

    [CGDrawingHelper drawCircleWithContext:layerContext
                                    center:layerCenter
                                    radius:radius
                                 fillColor:fillColor
                               strokeColor:nil
                           strokeLineWidth:0.0f];
  }
  else
  {
    [CGDrawingHelper drawRectangleWithContext:layerContext
                                    rectangle:layerRect
                                    fillColor:fillColor
                                  strokeColor:nil
                              strokeLineWidth:0.0f];
  }

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context so that
/// the layer is centered at the intersection specified by @a point.
///
/// The layer is not drawn if it does not intersect with the tile @a tileRect.
/// The tile rectangle origin must be in the canvas coordinate system.
///
/// If @a layer is NULL (e.g. because the Go board has been reduced to very
/// small dimensions) this method returns immediately without drawing.
// -----------------------------------------------------------------------------
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
   centeredAtPoint:(GoPoint*)point
    inTileWithRect:(CGRect)tileRect
       withMetrics:(BoardViewMetrics*)metrics
{
  if (! layer)
    return;

  CGRect layerRect = [BoardViewDrawingHelper canvasRectForScaledLayer:layer
                                                      centeredAtPoint:point
                                                              metrics:metrics];
  if (! CGRectIntersectsRect(tileRect, layerRect))
    return;
  CGRect drawingRect = [CGDrawingHelper drawingRectFromCanvasRect:layerRect
                                                   inTileWithRect:tileRect];
  CGContextDrawLayerInRect(context, drawingRect, layer);
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context in the
/// canvas rectangle @a canvasRect.
///
/// This method makes a number of assumptions:
/// - The layer size is assumed to be the size of @a canvasRect plus applied
///   @e contentsScale from @a metrics.
/// - No check is made whether @a canvasRect and @a tileRect intersect - this
///   method assumes that the check has already been made by the caller.
///
/// The origin of @a tileRect must be in the canvas coordinate system.
///
/// If @a layer is NULL (e.g. because the Go board has been reduced to very
/// small dimensions) this method returns immediately without drawing.
// -----------------------------------------------------------------------------
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
      inCanvasRect:(CGRect)canvasRect
    inTileWithRect:(CGRect)tileRect
       withMetrics:(BoardViewMetrics*)metrics
{
  if (! layer)
    return;

  CGRect drawingRect = [CGDrawingHelper drawingRectFromCanvasRect:canvasRect
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
     inTileWithRect:(CGRect)tileRect
        withMetrics:(BoardViewMetrics*)metrics
{
  CGRect textRect = [BoardViewDrawingHelper canvasRectForSize:size
                                              centeredAtPoint:point
                                                      metrics:metrics];
  if (! CGRectIntersectsRect(tileRect, textRect))
    return;

  CGRect drawingRect = [CGDrawingHelper drawingRectFromCanvasRect:textRect
                                                   inTileWithRect:tileRect];

  [CGDrawingHelper drawStringWithContext:context
                          centeredInRect:drawingRect
                                  string:string
                          textAttributes:attributes];
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
/// @brief Returns the rectangle defined by two intersections @a fromPoint and
/// @a toPoint on the "canvas", i.e. the area covered by the entire board view.
/// The intersections are located on two diagonally opposite corners of the
/// rectangle. The rectangle is padded by half of @e metrics.pointCellSize on
/// all sides so that there is sufficient room for drawing symbols on the corner
/// points. The origin is in the upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectFromPoint:(GoPoint*)fromPoint
                       toPoint:(GoPoint*)toPoint
                       metrics:(BoardViewMetrics*)metrics
{
  CGPoint fromPointCoordinates = [metrics coordinatesFromPoint:fromPoint];
  CGPoint toPointCoordinates = [metrics coordinatesFromPoint:toPoint];

  CGFloat xMin = fminf(fromPointCoordinates.x, toPointCoordinates.x);
  CGFloat yMin = fminf(fromPointCoordinates.y, toPointCoordinates.y);
  CGFloat xDistanceBetweenPoints = fabs(toPointCoordinates.x - fromPointCoordinates.x);
  CGFloat yDistanceBetweenPoints = fabs(toPointCoordinates.y - fromPointCoordinates.y);

  CGSize paddingSize = metrics.pointCellSize;

  CGRect canvasRect = CGRectMake(xMin - (paddingSize.width / 2.0f),
                                 yMin - (paddingSize.height / 2.0f),
                                 xDistanceBetweenPoints + paddingSize.width,
                                 yDistanceBetweenPoints + paddingSize.height);
  return canvasRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle defined by the row that goes across the entire
/// "canvas", i.e. the area covered by the entire board view, and that also
/// contains @a point. The origin is in the upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForRowContainingPoint:(GoPoint*)point
                                   metrics:(BoardViewMetrics*)metrics
{
  CGRect canvasRectForPoint = [BoardViewDrawingHelper canvasRectForSize:metrics.pointCellSize
                                                        centeredAtPoint:point
                                                                metrics:metrics];

  // The row rectangle has the same y-position and height as the rectangle for
  // the single point, but starts at the left edge of the canvas and spans the
  // entire canvas width
  CGRect canvasRectForRow = CGRectMake(0,
                                       canvasRectForPoint.origin.y,
                                       metrics.canvasSize.width,
                                       canvasRectForPoint.size.height);  // <- metrics.pointCellSize.height
  return canvasRectForRow;
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

  CGRect drawingRect = [CGDrawingHelper drawingRectForScaledLayer:layer
                                                withContentsScale:metrics.contentsScale];
  CGPoint drawingCenter = CGPointMake(CGRectGetMidX(drawingRect), CGRectGetMidY(drawingRect));

  CGRect canvasRect;
  canvasRect.size = drawingRect.size;
  canvasRect.origin.x = pointCoordinates.x - drawingCenter.x;
  canvasRect.origin.y = pointCoordinates.y - drawingCenter.y;
  return canvasRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns a rectangle of size @a size that is centered on the "canvas",
/// i.e. the area covered by the entire board view, on the coordinates of the
/// intersection @a point. The origin is in the upper-left corner.
// -----------------------------------------------------------------------------
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
/// @brief Returns a rectangle in which to draw the stone centered at the
/// specified point. Returns CGRectZero if the point is not located on this
/// tile.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForTile:(id<Tile>)tile
              centeredAtPoint:(GoPoint*)point
                  withMetrics:(BoardViewMetrics*)metrics
{
  if (! point)
    return CGRectZero;

  CGRect tileRect = [CGDrawingHelper canvasRectForTile:tile
                                               withSize:metrics.tileSize];
  CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:point
                                                               metrics:metrics];
  CGRect drawingRectForPoint = CGRectIntersection(tileRect, stoneRect);
  // Rectangles that are adjacent and share a side *do* intersect: The
  // intersection rectangle has either zero width or zero height, depending on
  // which side the two intersecting rectangles share. For this reason, we
  // must check CGRectIsEmpty() in addition to CGRectIsNull().
  if (CGRectIsNull(drawingRectForPoint) || CGRectIsEmpty(drawingRectForPoint))
  {
    drawingRectForPoint = CGRectZero;
  }
  else
  {
    drawingRectForPoint = [CGDrawingHelper drawingRectFromCanvasRect:drawingRectForPoint
                                                      inTileWithRect:tileRect];
  }
  return drawingRectForPoint;
}

// -----------------------------------------------------------------------------
/// @brief Returns a drawing rectangle that is the intersection of the tile
/// @a tile with the rectangle defined by the diagonally opposite corners
/// @a fromPoint and @a endPoint. Returns @e CGRectZero if there is no
/// intersection.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForTile:(id<Tile>)tile
                    fromPoint:(GoPoint*)fromPoint
                      toPoint:(GoPoint*)toPoint
                  withMetrics:(BoardViewMetrics*)metrics
{
  if (! fromPoint || ! toPoint)
    return CGRectZero;

  CGRect tileRect = [CGDrawingHelper canvasRectForTile:tile
                                              withSize:metrics.tileSize];
  CGRect canvasRect = [BoardViewDrawingHelper canvasRectFromPoint:fromPoint
                                                          toPoint:toPoint
                                                          metrics:metrics];

  CGRect drawingRect = CGRectIntersection(tileRect, canvasRect);

  // Rectangles that are adjacent and share a side *do* intersect: The
  // intersection rectangle has either zero width or zero height, depending on
  // which side the two intersecting rectangles share. For this reason, we
  // must check CGRectIsEmpty() in addition to CGRectIsNull().
  if (CGRectIsNull(drawingRect) || CGRectIsEmpty(drawingRect))
    return CGRectZero;

  drawingRect = [CGDrawingHelper drawingRectFromCanvasRect:drawingRect
                                            inTileWithRect:tileRect];

  return drawingRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns a drawing rectangle that is the intersection of the tile
/// @a tile with the rectangle defined by the row of points across the entire
/// board that contains @a point. Returns @e CGRectZero if there is no
/// intersection.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForTile:(id<Tile>)tile
     inRowContainingPoint:(GoPoint*)point
                  withMetrics:(BoardViewMetrics*)metrics
{
  if (! point)
    return CGRectZero;

  CGRect tileRect = [CGDrawingHelper canvasRectForTile:tile
                                              withSize:metrics.tileSize];
  CGRect rowRect = [BoardViewDrawingHelper canvasRectForRowContainingPoint:point
                                                                   metrics:metrics];
  CGRect drawingRectForRow = CGRectIntersection(tileRect, rowRect);
  // Rectangles that are adjacent and share a side *do* intersect: The
  // intersection rectangle has either zero width or zero height, depending on
  // which side the two intersecting rectangles share. For this reason, we
  // must check CGRectIsEmpty() in addition to CGRectIsNull().
  if (CGRectIsNull(drawingRectForRow) || CGRectIsEmpty(drawingRectForRow))
  {
    drawingRectForRow = CGRectZero;
  }
  else
  {
    drawingRectForRow = [CGDrawingHelper drawingRectFromCanvasRect:drawingRectForRow
                                                    inTileWithRect:tileRect];
  }
  return drawingRectForRow;
}

// -----------------------------------------------------------------------------
/// @brief Returns a layer from the cache in which a black stone is drawn
/// sized according to the definitions in @a metrics. If the cache does not
/// contain the requested layer this method draws the layer and populates the
/// cache with it.
// -----------------------------------------------------------------------------
+ (CGLayerRef) cachedBlackStoneLayerWithContext:(CGContextRef)context
                                    withMetrics:(BoardViewMetrics*)metrics
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];

  BoardViewCGLayerCacheEntry blackStoneLayerEntry = [cache layerOfType:BlackStoneLayerType];
  if (! blackStoneLayerEntry.isValid)
  {
    if (metrics.useImageFilesToDrawStones)
      blackStoneLayerEntry.layer = CreateStoneLayerWithImage(context, stoneBlackImageResource, metrics);
    else
      blackStoneLayerEntry.layer = CreateStoneLayerWithCoreGraphics(context, GoColorBlack, false, metrics);
    [cache setLayer:blackStoneLayerEntry.layer ofType:BlackStoneLayerType];
    CGLayerRelease(blackStoneLayerEntry.layer);
  }

  return blackStoneLayerEntry.layer;
}

// -----------------------------------------------------------------------------
/// @brief Returns a layer from the cache in which a white stone is drawn
/// sized according to the definitions in @a metrics. If the cache does not
/// contain the requested layer this method draws the layer and populates the
/// cache with it.
// -----------------------------------------------------------------------------
+ (CGLayerRef) cachedWhiteStoneLayerWithContext:(CGContextRef)context
                                    withMetrics:(BoardViewMetrics*)metrics
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];

  BoardViewCGLayerCacheEntry whiteStoneLayerEntry = [cache layerOfType:WhiteStoneLayerType];
  if (! whiteStoneLayerEntry.isValid)
  {
    if (metrics.useImageFilesToDrawStones)
      whiteStoneLayerEntry.layer = CreateStoneLayerWithImage(context, stoneWhiteImageResource, metrics);
    else
      whiteStoneLayerEntry.layer = CreateStoneLayerWithCoreGraphics(context, GoColorWhite, false, metrics);
    [cache setLayer:whiteStoneLayerEntry.layer ofType:WhiteStoneLayerType];
    CGLayerRelease(whiteStoneLayerEntry.layer);
  }

  return whiteStoneLayerEntry.layer;
}

// -----------------------------------------------------------------------------
/// @brief Returns a layer from the cache in which a crosshair stone is drawn
/// sized according to the definitions in @a metrics. If the cache does not
/// contain the requested layer this method draws the layer and populates the
/// cache with it.
// -----------------------------------------------------------------------------
+ (CGLayerRef) cachedCrossHairStoneLayerWithContext:(CGContextRef)context
                                        withMetrics:(BoardViewMetrics*)metrics
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];

  BoardViewCGLayerCacheEntry crossHairStoneLayerEntry = [cache layerOfType:CrossHairStoneLayerType];
  if (! crossHairStoneLayerEntry.isValid)
  {
    if (metrics.useImageFilesToDrawStones)
      crossHairStoneLayerEntry.layer = CreateStoneLayerWithImage(context, stoneCrosshairImageResource, metrics);
    else
      crossHairStoneLayerEntry.layer = CreateStoneLayerWithCoreGraphics(context, GoColorBlack, true, metrics);
    [cache setLayer:crossHairStoneLayerEntry.layer ofType:CrossHairStoneLayerType];
    CGLayerRelease(crossHairStoneLayerEntry.layer);
  }

  return crossHairStoneLayerEntry.layer;
}

// -----------------------------------------------------------------------------
/// @brief Returns a CGPath object that describes an arrow between the two
/// points @a startPoint and @a endPoint. The arrow characteristics are defined
/// by @a tailWidth, @a headWidth and @a headLength. If @a headLength is zero
/// the result is a line.
///
/// @verbatim
///                              4\ <---------------+
///                              | \                |
///        +-->  6---------------5  \               |
///        |     |                   \              |
/// tail   |     X start point        3 end point   | head
/// width  |     |                   /              | width
///        +-->  0---------------1  / ^             |
///                              | /  |             |
///                              2/ <-+-------------+
///                                   |
///                              ^    |
///                              |    |
///                              +----+
///                              head length
/// @endverbatim
///
/// Diagram notes
/// - Note the 7 points numbered from 0-6. These are the points that make up
///   the path and that are calculated by the method
///   getAxisAlignedArrowPoints:forLength:tailWidth:headWith:headLength:().
///
/// The code of this method and its helper methods was adapted from this
/// StackOverflow answer: https://stackoverflow.com/a/13559449/1054378 (the code
/// itself was taken from the Gist https://gist.github.com/mayoff/4146780 that
/// is referenced by the SO answer).
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGPathRef object using the function CGPathRelease when the path is
/// no longer needed.
// -----------------------------------------------------------------------------
+ (CGPathRef) newPathWithArrowFromPoint:(CGPoint)startPoint
                                toPoint:(CGPoint)endPoint
                              tailWidth:(CGFloat)tailWidth
                              headWidth:(CGFloat)headWidth
                             headLength:(CGFloat)headLength
{
  CGFloat arrowLength = [BoardViewDrawingHelper distanceFromPoint:startPoint toPoint:endPoint];

  CGPoint points[kArrowPointCount];
  [self getAxisAlignedArrowPoints:points
                   forArrowLength:arrowLength
                        tailWidth:tailWidth
                        headWidth:headWidth
                       headLength:headLength];

  CGAffineTransform transform = [self transformForStartPoint:startPoint
                                                    endPoint:endPoint
                                                 arrowLength:arrowLength];

  CGMutablePathRef cgPath = CGPathCreateMutable();
  CGPathAddLines(cgPath, &transform, points, kArrowPointCount);
  CGPathCloseSubpath(cgPath);

  return cgPath;
}

// -----------------------------------------------------------------------------
/// @brief Helper method for
/// newPathWithArrowFromPoint:toPoint:tailWidth:headWidth:headLength:().
// -----------------------------------------------------------------------------
+ (void) getAxisAlignedArrowPoints:(CGPoint[kArrowPointCount])points
                    forArrowLength:(CGFloat)arrowLength
                         tailWidth:(CGFloat)tailWidth
                         headWidth:(CGFloat)headWidth
                        headLength:(CGFloat)headLength
{
  if (headLength > arrowLength)
    headLength = arrowLength;

  CGFloat tailLength = arrowLength - headLength;
  points[0] = CGPointMake(0, tailWidth / 2);
  points[1] = CGPointMake(tailLength, tailWidth / 2);
  points[2] = CGPointMake(tailLength, headWidth / 2);
  points[3] = CGPointMake(arrowLength, 0);
  points[4] = CGPointMake(tailLength, -headWidth / 2);
  points[5] = CGPointMake(tailLength, -tailWidth / 2);
  points[6] = CGPointMake(0, -tailWidth / 2);
}

// -----------------------------------------------------------------------------
/// @brief Helper method for
/// newPathWithArrowFromPoint:toPoint:tailWidth:headWidth:headLength:().
// -----------------------------------------------------------------------------
+ (CGAffineTransform) transformForStartPoint:(CGPoint)startPoint
                                    endPoint:(CGPoint)endPoint
                                 arrowLength:(CGFloat)arrowLength
{
  CGFloat cosine = (endPoint.x - startPoint.x) / arrowLength;
  CGFloat sine = (endPoint.y - startPoint.y) / arrowLength;
  return (CGAffineTransform) { cosine, sine, -sine, cosine, startPoint.x, startPoint.y };
}

// -----------------------------------------------------------------------------
/// @brief Helper method for
/// newPathWithArrowFromPoint:toPoint:tailWidth:headWidth:headLength:().
// -----------------------------------------------------------------------------
+ (CGFloat) distanceFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
  CGFloat distance = hypotf(toPoint.x - fromPoint.x, toPoint.y - fromPoint.y);
  return distance;
}

@end
