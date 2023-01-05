// -----------------------------------------------------------------------------
// Copyright 2014-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewDrawingHelper.h"
#import "../NodeTreeViewMetrics.h"
#import "../../../ui/Tile.h"
#import "../../../ui/CGDrawingHelper.h"
#import "../../../ui/UiUtilities.h"


@implementation NodeTreeViewDrawingHelper

// TODO xxx remove
void CreateDummySymbol(CGContextRef layerContext, CGRect drawingRect)
{
  CGContextAddRect(layerContext, drawingRect);

  CGContextSetStrokeColorWithColor(layerContext, [UIColor redColor].CGColor);
  CGContextSetLineWidth(layerContext, 1);
  CGContextStrokePath(layerContext);
}

void DrawNodeTreeViewCellSymbolSetupRectangleStyle(CGContextRef layerContext,
                                                   CGRect drawingRect,
                                                   CGFloat strokeLineWidth,
                                                   enum GoColor topLeftStoneColor,
                                                   enum GoColor topRightStoneColor,
                                                   enum GoColor bottomLeftStoneColor,
                                                   enum GoColor bottomRightStoneColor)
{
  // Black quarters are not stroked => Without any countermeasures, a set of
  // four black quarters would therefore be indistinguishable from a black
  // stone symbol. By adding a small gap between the 4 black quarters we create
  // a visual distinction to the black stone symbol - this looks as if the black
  // quarters were stroked with clear color.
  CGFloat gap;
  if (topLeftStoneColor == GoColorBlack && topRightStoneColor == GoColorBlack && bottomLeftStoneColor == GoColorBlack && bottomRightStoneColor == GoColorBlack)
    gap = 1.0f;
  else
    gap = 0.0f;

  CGFloat drawingRectHalfX = drawingRect.size.width / 2;
  CGFloat drawingRectHalfY = drawingRect.size.height / 2;

  CGSize drawingSize = CGSizeMake(drawingRectHalfX - gap, drawingRectHalfY - gap);
  CGFloat offsetSecondHalfX = drawingRectHalfX + 2 * gap;
  CGFloat offsetSecondHalfY = drawingRectHalfY + 2 * gap;

  CGRect topLeftRect = CGRectMake(drawingRect.origin.x, drawingRect.origin.y, drawingSize.width, drawingSize.height);
  [CGDrawingHelper drawStoneRectangleWithContext:layerContext rectangle:topLeftRect stoneColor:topLeftStoneColor strokeLineWidth:strokeLineWidth];

  CGRect topRightRect = CGRectMake(drawingRect.origin.x + offsetSecondHalfX, drawingRect.origin.y, drawingSize.width, drawingSize.height);
  [CGDrawingHelper drawStoneRectangleWithContext:layerContext rectangle:topRightRect stoneColor:topRightStoneColor strokeLineWidth:strokeLineWidth];

  CGRect bottomLeftRect = CGRectMake(drawingRect.origin.x, drawingRect.origin.y + offsetSecondHalfY, drawingSize.width, drawingSize.height);
  [CGDrawingHelper drawStoneRectangleWithContext:layerContext rectangle:bottomLeftRect stoneColor:bottomLeftStoneColor strokeLineWidth:strokeLineWidth];

  CGRect bottomRightRect = CGRectMake(drawingRect.origin.x + offsetSecondHalfX, drawingRect.origin.y + offsetSecondHalfY, drawingSize.width, drawingSize.height);
  [CGDrawingHelper drawStoneRectangleWithContext:layerContext rectangle:bottomRightRect stoneColor:bottomRightStoneColor strokeLineWidth:strokeLineWidth];
}

void DrawNodeTreeViewCellSymbolSetupCircleStyle(CGContextRef layerContext,
                                                CGRect drawingRect,
                                                CGFloat strokeLineWidth,
                                                CGFloat radius,
                                                enum GoColor topLeftStoneColor,
                                                enum GoColor topRightStoneColor,
                                                enum GoColor bottomLeftStoneColor,
                                                enum GoColor bottomRightStoneColor)
{
  CGFloat drawingRectQuarterX = drawingRect.size.width / 4;
  CGFloat drawingRectQuarterY = drawingRect.size.height / 4;

  // There should be a minimal gap between stone icons so that their edges
  // do not touch.
  const CGFloat gapBetweenStoneIcons = 4;
  radius -= gapBetweenStoneIcons / 2.0;

  // Stone icon center points should be slightly inset so they are not clipped
  // by the surrounding circle. The radius needs to be adjusted as well,
  // otherwise the stone circles will overlap.
  const CGFloat insetCenter = 4;
  radius -= insetCenter;

  CGFloat symbolXSize = radius * 0.5;
  UIColor* symbolXStrokeColor = [UIColor blackColor];

  CGPoint topLeftCenter = CGPointMake(drawingRect.origin.x + drawingRectQuarterX + insetCenter, drawingRect.origin.y + drawingRectQuarterY + insetCenter);
  [CGDrawingHelper drawStoneCircleWithContext:layerContext center:topLeftCenter radius:radius stoneColor:topLeftStoneColor strokeLineWidth:strokeLineWidth];
  if (topLeftStoneColor == GoColorNone)
    [CGDrawingHelper drawSymbolXWithContext:layerContext center:topLeftCenter symbolSize:symbolXSize strokeColor:symbolXStrokeColor strokeLineWidth:strokeLineWidth];

  CGPoint topRightCenter = CGPointMake(drawingRect.origin.x + 3 * drawingRectQuarterX - insetCenter, drawingRect.origin.y + drawingRectQuarterY + insetCenter);
  [CGDrawingHelper drawStoneCircleWithContext:layerContext center:topRightCenter radius:radius stoneColor:topRightStoneColor strokeLineWidth:strokeLineWidth];
  if (topRightStoneColor == GoColorNone)
    [CGDrawingHelper drawSymbolXWithContext:layerContext center:topRightCenter symbolSize:symbolXSize strokeColor:symbolXStrokeColor strokeLineWidth:strokeLineWidth];

  CGPoint bottomLeftCenter = CGPointMake(drawingRect.origin.x + drawingRectQuarterX + insetCenter, drawingRect.origin.y + 3 * drawingRectQuarterY - insetCenter);
  [CGDrawingHelper drawStoneCircleWithContext:layerContext center:bottomLeftCenter radius:radius stoneColor:bottomLeftStoneColor strokeLineWidth:strokeLineWidth];
  if (bottomLeftStoneColor == GoColorNone)
    [CGDrawingHelper drawSymbolXWithContext:layerContext center:bottomLeftCenter symbolSize:symbolXSize strokeColor:symbolXStrokeColor strokeLineWidth:strokeLineWidth];

  CGPoint bottomRightCenter = CGPointMake(drawingRect.origin.x + 3 * drawingRectQuarterX - insetCenter, drawingRect.origin.y + 3 * drawingRectQuarterY - insetCenter);
  [CGDrawingHelper drawStoneCircleWithContext:layerContext center:bottomRightCenter radius:radius stoneColor:bottomRightStoneColor strokeLineWidth:strokeLineWidth];
  if (bottomRightStoneColor == GoColorNone)
    [CGDrawingHelper drawSymbolXWithContext:layerContext center:bottomRightCenter symbolSize:symbolXSize strokeColor:symbolXStrokeColor strokeLineWidth:strokeLineWidth];
}

void DrawNodeTreeViewCellSymbolSetup(CGContextRef layerContext,
                                     CGRect drawingRect,
                                     CGFloat strokeLineWidth,
                                     enum GoColor topLeftStoneColor,
                                     enum GoColor topRightStoneColor,
                                     enum GoColor bottomLeftStoneColor,
                                     enum GoColor bottomRightStoneColor)
{
  CGFloat drawingRectQuarterX = drawingRect.size.width / 4;
  CGFloat drawingRectQuarterY = drawingRect.size.height / 4;
  CGFloat radius = floorf(MIN(drawingRectQuarterX, drawingRectQuarterY));

  // If the radius becomes too small, the "X" symbol becomes an unrecognizable
  // pixel mess. The limit used here was experimentally determined, with the
  // assumption that the actual radius will be reduced even more by the
  // circle-style drawing routine.
  const CGFloat minimumRadiusForCircleStyle = 12.0;

  if (radius >= minimumRadiusForCircleStyle)
  {
    DrawNodeTreeViewCellSymbolSetupCircleStyle(layerContext,
                                               drawingRect,
                                               strokeLineWidth,
                                               radius,
                                               topLeftStoneColor,
                                               topRightStoneColor,
                                               bottomLeftStoneColor,
                                               bottomRightStoneColor);
  }
  else
  {
    DrawNodeTreeViewCellSymbolSetupRectangleStyle(layerContext,
                                                  drawingRect,
                                                  strokeLineWidth,
                                                  topLeftStoneColor,
                                                  topRightStoneColor,
                                                  bottomLeftStoneColor,
                                                  bottomRightStoneColor);
  }
}

// TODO xxx Make this reusable for BoardViewDrawingHelper
void DrawString(CGContextRef layerContext, CGRect drawingRect, NSString* string, CGFloat fontSize)
{
  UIFont* font;
  if (@available(iOS 13, *))
    font = [UIFont monospacedSystemFontOfSize:fontSize weight:UIFontWeightRegular];
  else
    font = [UIFont fontWithName:@"Menlo" size:fontSize];

  UIColor* textColor = [UIColor whiteColor];
  NSShadow* whiteTextShadow = [[[NSShadow alloc] init] autorelease];
  whiteTextShadow.shadowColor = [UIColor blackColor];
  whiteTextShadow.shadowBlurRadius = 5.0;
  whiteTextShadow.shadowOffset = CGSizeMake(1.0, 1.0);
  NSDictionary* textAttributes = @{ NSFontAttributeName : font,
                                    NSForegroundColorAttributeName : textColor,
                                    NSShadowAttributeName: whiteTextShadow };

  [CGDrawingHelper drawStringWithContext:layerContext
                          centeredInRect:drawingRect
                                  string:string
                          textAttributes:textAttributes];
}

void DrawSurroundingCircle(CGContextRef layerContext, CGPoint center, CGFloat radius, UIColor* strokeColor, CGFloat strokeLineWidth)
{
  [CGDrawingHelper drawCircleWithContext:layerContext center:center radius:radius fillColor:nil strokeColor:strokeColor strokeLineWidth:strokeLineWidth];
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a node symbol
/// of type @a symbolType. If @a condensed is true the symbol is drawn in
/// reduced size, if @a condensed is false the symbol is drawn in normal size.
///
/// All sizes are taken from the metrics values in @a metrics.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateNodeSymbolLayer(CGContextRef context, enum NodeTreeViewCellSymbol symbolType, bool condensed, NodeTreeViewMetrics* metrics)
{
  CGRect layerRect = [NodeTreeViewDrawingHelper drawingRectForCell:condensed withMetrics:metrics];

  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  CGRect drawingRect =  [NodeTreeViewDrawingHelper drawingRectForNodeSymbolInCell:condensed
                                                           withDrawingRectForCell:layerRect
                                                                      withMetrics:metrics];

  CGFloat strokeLineWidth = metrics.normalLineWidth * metrics.contentsScale;

  CGPoint drawingRectCenter = CGPointMake(CGRectGetMidX(drawingRect), CGRectGetMidY(drawingRect));
  CGFloat radius = floorf(MIN(drawingRect.size.width, drawingRect.size.height) / 2);
  CGFloat clippingPathRadius = radius + strokeLineWidth / 2.0;

  switch (symbolType)
  {
    case NodeTreeViewCellSymbolBlackSetupStones:
    {
      [CGDrawingHelper setCircularClippingPathWithContext:layerContext center:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorBlack, GoColorBlack, GoColorBlack);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [CGDrawingHelper removeClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolWhiteSetupStones:
    {
      [CGDrawingHelper setCircularClippingPathWithContext:layerContext center:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorWhite, GoColorWhite, GoColorWhite, GoColorWhite);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [CGDrawingHelper removeClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolNoSetupStones:
    {
      [CGDrawingHelper setCircularClippingPathWithContext:layerContext center:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorNone, GoColorNone, GoColorNone, GoColorNone);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [CGDrawingHelper removeClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolBlackAndWhiteSetupStones:
    {
      [CGDrawingHelper setCircularClippingPathWithContext:layerContext center:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorWhite, GoColorWhite, GoColorBlack);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [CGDrawingHelper removeClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolBlackAndNoSetupStones:
    {
      [CGDrawingHelper setCircularClippingPathWithContext:layerContext center:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorNone, GoColorNone, GoColorBlack);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [CGDrawingHelper removeClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolWhiteAndNoSetupStones:
    {
      [CGDrawingHelper setCircularClippingPathWithContext:layerContext center:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorWhite, GoColorNone, GoColorNone, GoColorWhite);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [CGDrawingHelper removeClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones:
    {
      [CGDrawingHelper setCircularClippingPathWithContext:layerContext center:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorNone, GoColorNone, GoColorWhite);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [CGDrawingHelper removeClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolBlackMove:
    case NodeTreeViewCellSymbolWhiteMove:
    {
      enum GoColor stoneColor = symbolType == NodeTreeViewCellSymbolBlackMove ? GoColorBlack : GoColorWhite;
      [CGDrawingHelper drawStoneCircleWithContext:layerContext center:drawingRectCenter radius:radius stoneColor:stoneColor strokeLineWidth:strokeLineWidth];
      break;
    }
    case NodeTreeViewCellSymbolAnnotations:
    {
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      // Same size as markup would be logical, but then the "i" looks too small
      // within the available space
      DrawString(layerContext, drawingRect, @"i", 35);
      break;
    }
    case NodeTreeViewCellSymbolMarkup:
    {
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      DrawString(layerContext, drawingRect, @"</>", 25);
      break;
    }
    case NodeTreeViewCellSymbolAnnotationsAndMarkup:
    {
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);

      CGRect drawingRectSymbolAnnotation = drawingRect;
      drawingRectSymbolAnnotation.size.height /= 2.0;
      DrawString(layerContext, drawingRectSymbolAnnotation, @"i", 20);

      CGRect drawingRectSymbolMarkup = drawingRect;
      drawingRectSymbolMarkup.size.height /= 2.0;
      drawingRectSymbolMarkup.origin.y += drawingRectSymbolMarkup.size.height;
      // Without this adjustment the text + its shadow are too close to the
      // circle bounding line
      drawingRectSymbolMarkup.origin.y -= 6;
      DrawString(layerContext, drawingRectSymbolMarkup, @"</>", 20);
      break;
    }
    case NodeTreeViewCellSymbolEmpty:
    {
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      break;
    }
    default:
    {
      assert(0);
      return NULL;
    }
  }

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a node
/// selection marker. If @a condensed is true the marker is drawn in reduced
/// size, if @a condensed is false the marker is drawn in normal size.
///
/// All sizes are taken from the metrics values in @a metrics.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateNodeSelectionLayer(CGContextRef context, bool condensed, NodeTreeViewMetrics* metrics)
{
  CGRect layerRect = [NodeTreeViewDrawingHelper drawingRectForCell:condensed withMetrics:metrics];

  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  CGRect drawingRect =  [NodeTreeViewDrawingHelper drawingRectForNodeSymbolInCell:condensed
                                                           withDrawingRectForCell:layerRect
                                                                      withMetrics:metrics];

  CGPoint drawingRectCenter = CGPointMake(CGRectGetMidX(drawingRect), CGRectGetMidY(drawingRect));
  CGFloat radius = floorf(MIN(drawingRect.size.width, drawingRect.size.height) / 2);
  CGFloat strokeLineWidth = metrics.selectedLineWidth * metrics.contentsScale;

  DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.selectedNodeColor, strokeLineWidth);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context so that
/// the layer is centered within the cell identified by @a position.
///
/// The layer is not drawn if it does not intersect with the tile @a tileRect.
/// The tile rectangle origin must be in the canvas coordinate system.
// -----------------------------------------------------------------------------
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
        centeredAt:(NodeTreeViewCellPosition*)position
    inTileWithRect:(CGRect)tileRect
       withMetrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRectForLayer = [NodeTreeViewDrawingHelper canvasRectForScaledLayer:layer
                                                                       centeredAt:position
                                                                          metrics:metrics];
  if (! CGRectIntersectsRect(tileRect, canvasRectForLayer))
    return;
  CGRect drawingRect = [NodeTreeViewDrawingHelper drawingRectFromCanvasRect:canvasRectForLayer
                                                             inTileWithRect:tileRect];
  CGContextDrawLayerInRect(context, drawingRect, layer);
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context so that
/// the layer is centered within a multipart cell. Only that part of the layer
/// which corresponds to the standalone cell @a part of the multipart cell needs
/// to be drawn. The standalone cell is identified by @a position, this defines
/// the multipart cell's location on the canvas.
///
/// The layer is not drawn if it does not intersect with the tile @a tileRect.
/// The tile rectangle origin must be in the canvas coordinate system.
// -----------------------------------------------------------------------------
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
              part:(int)part
      partPosition:(NodeTreeViewCellPosition*)position
    inTileWithRect:(CGRect)tileRect
       withMetrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRectForMultipartCell = [NodeTreeViewDrawingHelper canvasRectForMultipartCellPart:part
                                                                                   partPosition:position
                                                                                        metrics:metrics];
  CGRect drawingRectForLayerWithCorrectSize = [NodeTreeViewDrawingHelper drawingRectForScaledLayer:layer
                                                                                       withMetrics:metrics];
  CGRect canvasRectForLayer = [UiUtilities rectWithSize:drawingRectForLayerWithCorrectSize.size
                                         centeredInRect:canvasRectForMultipartCell];

  if (! CGRectIntersectsRect(tileRect, canvasRectForLayer))
    return;
  CGRect drawingRect = [NodeTreeViewDrawingHelper drawingRectFromCanvasRect:canvasRectForLayer
                                                             inTileWithRect:tileRect];

  // TODO xxx set clipping bounds? if yes => canvasRectForCell

  CGContextDrawLayerInRect(context, drawingRect, layer);
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by @a tile on the "canvas", i.e. the
/// area covered by the entire node tree view. The origin is in the upper-left
/// corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForTile:(id<Tile>)tile
                     metrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRect = CGRectZero;
  canvasRect.size = metrics.tileSize;
  // The tile with row/column = 0/0 is in the upper-left corner
  canvasRect.origin.x = tile.column * canvasRect.size.width;
  canvasRect.origin.y = tile.row * canvasRect.size.height;
  return canvasRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by the multipart cell on the "canvas",
/// i.e. the area covered by the entire node tree view, of which the specified
/// sub-cell is a part of. @a part identifies the sub-cell within the multipart
/// cell, @a position the sub-cell's position on the canvas. The origin is in
/// the upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForMultipartCellPart:(int)part
                             partPosition:(NodeTreeViewCellPosition*)position
                               metrics:(NodeTreeViewMetrics*)metrics;
{
  CGRect canvasRectForCell = [NodeTreeViewDrawingHelper canvasRectForCellAtPosition:position metrics:metrics];

  CGRect canvasRectForMultipartCell = CGRectZero;
  canvasRectForMultipartCell.size.height = canvasRectForCell.size.height;
  canvasRectForMultipartCell.size.width =  metrics.nodeTreeViewMultipartCellSize.width;
  canvasRectForMultipartCell.origin.y = canvasRectForCell.origin.y;
  canvasRectForMultipartCell.origin.x = canvasRectForCell.origin.x - (canvasRectForCell.size.width * part);

  return canvasRectForMultipartCell;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by a cell on the "canvas", i.e. the
/// area covered by the entire node tree view, which is identified by
/// @a position. The origin is in the upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForCellAtPosition:(NodeTreeViewCellPosition*)position
                               metrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRect = CGRectZero;
  canvasRect.origin = [metrics cellRectOriginFromPosition:position];
  canvasRect.size = metrics.nodeTreeViewCellSize;
  return canvasRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by @a layer on the "canvas", i.e. the
/// area covered by the entire node tree view, after placing @a layer so that it
/// is centered within the cell identified by @a position. The origin is in the
/// upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForScaledLayer:(CGLayerRef)layer
                         centeredAt:(NodeTreeViewCellPosition*)position
                            metrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRectForCell = [NodeTreeViewDrawingHelper canvasRectForCellAtPosition:position metrics:metrics];
  CGRect drawingRect = [NodeTreeViewDrawingHelper drawingRectForScaledLayer:layer
                                                                withMetrics:metrics];
  return [UiUtilities rectWithSize:drawingRect.size centeredInRect:canvasRectForCell];
}

// -----------------------------------------------------------------------------
/// @brief Returns a rectangle of size @a size whose center on the "canvas",
/// i.e. the area covered by the entire node tree view, is the same as the
/// center of the cell identified by @a position. The origin is in the
/// upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForSize:(CGSize)size
                  centeredAt:(NodeTreeViewCellPosition*)position
                     metrics:(NodeTreeViewMetrics*)metrics
{
  CGRect cellRect = CGRectZero;
  cellRect.origin = [metrics cellRectOriginFromPosition:position];
  cellRect.size = metrics.nodeTreeViewCellSize;

  return [UiUtilities rectWithSize:size centeredInRect:cellRect];
}

// -----------------------------------------------------------------------------
/// @brief Returns a rectangle for drawing that covers the entire area of a
/// cell. If @a condensed is @e true this indicates that the cell is a
/// standalone cell, if @a condensed is @e false this indicates that the cell
/// is a multipart cell.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForCell:(bool)condensed
                  withMetrics:(NodeTreeViewMetrics*)metrics
{
  CGRect drawingRectForCell;
  drawingRectForCell.origin = CGPointZero;
  drawingRectForCell.size = condensed ? metrics.nodeTreeViewCellSize : metrics.nodeTreeViewMultipartCellSize;
  drawingRectForCell.size.width *= metrics.contentsScale;
  drawingRectForCell.size.height *= metrics.contentsScale;

  return drawingRectForCell;
}

// -----------------------------------------------------------------------------
/// @brief Returns a rectangle for drawing that covers the area of a node symbol
/// within a cell. If @a condensed is @e true this indicates that the cell is a
/// standalone cell, if @a condensed is @e false this indicates that the cell
/// is a multipart cell.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForNodeSymbolInCell:(bool)condensed
                              withMetrics:(NodeTreeViewMetrics*)metrics
{
  CGRect drawingRectForCell = [NodeTreeViewDrawingHelper drawingRectForCell:condensed
                                                                withMetrics:metrics];
  return [NodeTreeViewDrawingHelper drawingRectForNodeSymbolInCell:condensed
                                            withDrawingRectForCell:drawingRectForCell
                                                       withMetrics:metrics];
}

// -----------------------------------------------------------------------------
/// @brief Returns a rectangle for drawing that covers the area of a node symbol
/// within a cell whose drawing rect is @a drawingRectForCell. If @a condensed
/// is @e true this indicates that the cell is a standalone cell, if
/// @a condensed is @e false this indicates that the cell is a multipart cell.
///
/// The value for @a drawingRectForCell should be calculated by
/// drawingRectForCell:withMetrics:().
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForNodeSymbolInCell:(bool)condensed
                   withDrawingRectForCell:(CGRect)drawingRectForCell
                              withMetrics:(NodeTreeViewMetrics*)metrics
{
  CGSize drawingRectSize = condensed ? metrics.condensedNodeSymbolSize : metrics.uncondensedNodeSymbolSize;
  drawingRectSize.width *= metrics.contentsScale;
  drawingRectSize.height *= metrics.contentsScale;
  CGRect drawingRect = [UiUtilities rectWithSize:drawingRectSize centeredInRect:drawingRectForCell];

  return drawingRect;
}

// TODO xxx this is exactly the same as the identically named method in BoardViewDrawingHelper => code duplication
// -----------------------------------------------------------------------------
/// @brief Returns the rectangle that must be passed to CGContextDrawLayerInRect
/// for drawing the specified layer, which must have a size that is scaled up
/// using @e metrics.contentScale.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForScaledLayer:(CGLayerRef)layer
                         withMetrics:(NodeTreeViewMetrics*)metrics
{
  CGSize drawingSize = CGLayerGetSize(layer);
  drawingSize.width /= metrics.contentsScale;
  drawingSize.height /= metrics.contentsScale;
  CGRect drawingRect;
  drawingRect.origin = CGPointZero;
  drawingRect.size = drawingSize;
  return drawingRect;
}

// TODO xxx this is exactly the same as the identically named method in BoardViewDrawingHelper => code duplication
// -----------------------------------------------------------------------------
/// @brief Translates the origin of @a canvasRect (a rectangle on the "canvas",
/// i.e. the area covered by the entire node tree view) into the coordinate
/// system of the tile described by @a tileRect (the rectangle on the "canvas"
/// occupied by the tile). The origin is in the upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectFromCanvasRect:(CGRect)canvasRect
                      inTileWithRect:(CGRect)tileRect
{
  CGRect drawingRect = canvasRect;
  drawingRect.origin.x -= tileRect.origin.x;
  drawingRect.origin.y -= tileRect.origin.y;
  return drawingRect;
}

@end
