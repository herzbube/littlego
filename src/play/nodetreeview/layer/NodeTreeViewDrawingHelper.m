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
#import "../../model/NodeTreeViewMetrics.h"
#import "../../../ui/Tile.h"
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

// TODO xxx Make this reusable for BoardViewDrawingHelper
void DrawStoneCircle(CGContextRef layerContext, CGPoint center, CGFloat radius, enum GoColor stoneColor, CGFloat strokeLineWidth)
{
  const CGFloat startRadius = [UiUtilities radians:0];
  const CGFloat endRadius = [UiUtilities radians:360];
  const int clockwise = 0;
  CGContextAddArc(layerContext,
                  center.x,
                  center.y,
                  radius,
                  startRadius,
                  endRadius,
                  clockwise);

  if (stoneColor == GoColorBlack)
  {
    CGContextSetFillColorWithColor(layerContext, [UIColor blackColor].CGColor);
    CGContextFillPath(layerContext);
  }
  else if (stoneColor == GoColorWhite)
  {
    CGContextSetFillColorWithColor(layerContext, [UIColor whiteColor].CGColor);
    CGContextSetStrokeColorWithColor(layerContext, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(layerContext, strokeLineWidth);
    CGContextDrawPath(layerContext, kCGPathFillStroke);
  }
  else
  {
    CGContextSetStrokeColorWithColor(layerContext, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(layerContext, strokeLineWidth);
    CGContextStrokePath(layerContext);
  }
}

// TODO xxx Make this reusable for BoardViewDrawingHelper
void DrawSymbolX(CGContextRef layerContext, CGPoint center, CGFloat symbolSize, UIColor* symbolStrokeColor, CGFloat strokeLineWidth)
{
  // Draw path from A => B, then from C => D
  // C o     o B
  //    \   /
  //     \ /
  //      o <-- center
  //     / \
  //    /   \
  // A o     o D
  //   ^     ^
  //   +-----+
  //    symbolSize * 2
  CGContextBeginPath(layerContext);
  CGContextMoveToPoint(layerContext, center.x - symbolSize, center.y + symbolSize);
  CGContextAddLineToPoint(layerContext, center.x + symbolSize, center.y - symbolSize);
  CGContextMoveToPoint(layerContext, center.x - symbolSize, center.y - symbolSize);
  CGContextAddLineToPoint(layerContext, center.x + symbolSize, center.y + symbolSize);

  CGContextSetStrokeColorWithColor(layerContext, symbolStrokeColor.CGColor);
  CGContextSetLineWidth(layerContext, strokeLineWidth);
  CGContextStrokePath(layerContext);
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
  // Reduce radius so that there is a minimal gap between the stone icons
  CGFloat radius = floorf(MIN(drawingRectQuarterX, drawingRectQuarterY) - 2);
  CGFloat symbolXSize = radius * 0.5;
  UIColor* symbolXStrokeColor = [UIColor blackColor];

  CGPoint topLeftCenter = CGPointMake(drawingRect.origin.x + drawingRectQuarterX, drawingRect.origin.y + drawingRectQuarterY);
  DrawStoneCircle(layerContext, topLeftCenter, radius, topLeftStoneColor, strokeLineWidth);
  if (topLeftStoneColor == GoColorNone)
    DrawSymbolX(layerContext, topLeftCenter, symbolXSize, symbolXStrokeColor, strokeLineWidth);

  CGPoint topRightCenter = CGPointMake(drawingRect.origin.x + 3 * drawingRectQuarterX, drawingRect.origin.y + drawingRectQuarterY);
  DrawStoneCircle(layerContext, topRightCenter, radius, topRightStoneColor, strokeLineWidth);
  if (topRightStoneColor == GoColorNone)
    DrawSymbolX(layerContext, topRightCenter, symbolXSize, symbolXStrokeColor, strokeLineWidth);

  CGPoint bottomLeftCenter = CGPointMake(drawingRect.origin.x + drawingRectQuarterX, drawingRect.origin.y + 3 * drawingRectQuarterY);
  DrawStoneCircle(layerContext, bottomLeftCenter, radius, bottomLeftStoneColor, strokeLineWidth);
  if (bottomLeftStoneColor == GoColorNone)
    DrawSymbolX(layerContext, bottomLeftCenter, symbolXSize, symbolXStrokeColor, strokeLineWidth);

  CGPoint bottomRightCenter = CGPointMake(drawingRect.origin.x + 3 * drawingRectQuarterX, drawingRect.origin.y + 3 * drawingRectQuarterY);
  DrawStoneCircle(layerContext, bottomRightCenter, radius, bottomRightStoneColor, strokeLineWidth);
  if (bottomRightStoneColor == GoColorNone)
    DrawSymbolX(layerContext, bottomRightCenter, symbolXSize, symbolXStrokeColor, strokeLineWidth);
}

// TODO xxx Make this reusable for BoardViewDrawingHelper
void DrawImageWithName(CGContextRef layerContext, CGRect drawingRect, NSString* imageName)
{
  UIImage* image = [UIImage imageNamed:imageName];
  // Let UIImage do all the drawing for us. This includes 1) compensating for
  // coordinate system differences (if we use CGContextDrawImage() the image
  // is drawn upside down); and 2) for scaling.
  UIGraphicsPushContext(layerContext);
  [image drawInRect:drawingRect];
  UIGraphicsPopContext();
}

void SetClippingPath(CGContextRef layerContext, CGPoint center, CGFloat radius, CGFloat strokeLineWidth)
{
  const CGFloat startRadius = [UiUtilities radians:0];
  const CGFloat endRadius = [UiUtilities radians:360];
  const int clockwise = 0;
  CGContextAddArc(layerContext,
                  center.x,
                  center.y,
                  radius + strokeLineWidth / 2,
                  startRadius,
                  endRadius,
                  clockwise);
  CGContextClip(layerContext);
}

void DrawSurroundingCircle(CGContextRef layerContext, CGPoint center, CGFloat radius, CGFloat strokeLineWidth)
{
  DrawStoneCircle(layerContext, center, radius, GoColorNone, strokeLineWidth);
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
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = condensed ? metrics.nodeTreeViewCellSize : metrics.nodeTreeViewMultipartCellSize;
  layerRect.size.width *= metrics.contentsScale;
  layerRect.size.height *= metrics.contentsScale;

  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  CGSize drawingRectSize = condensed ? metrics.condensedNodeSymbolSize : metrics.uncondensedNodeSymbolSize;
  drawingRectSize.width *= metrics.contentsScale;
  drawingRectSize.height *= metrics.contentsScale;
  CGRect drawingRect = [UiUtilities rectWithSize:drawingRectSize centeredInRect:layerRect];

  CGFloat strokeLineWidth = metrics.normalLineWidth * metrics.contentsScale;

  // TODO xxx remove if no longer needed
  bool useClipping = false;
  CGPoint drawingRectCenter = CGPointMake(CGRectGetMidX(drawingRect), CGRectGetMidY(drawingRect));
  CGFloat radius = floorf(MIN(drawingRect.size.width, drawingRect.size.height) / 2);

  switch (symbolType)
  {
    case NodeTreeViewCellSymbolBlackSetupStones:
    {
      if (useClipping)
      {
        SetClippingPath(layerContext, drawingRectCenter, radius, strokeLineWidth);
        DrawSurroundingCircle(layerContext, drawingRectCenter, radius, strokeLineWidth);
      }
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorBlack, GoColorBlack, GoColorBlack);
      break;
    }
    case NodeTreeViewCellSymbolWhiteSetupStones:
    {
      if (useClipping)
      {
        SetClippingPath(layerContext, drawingRectCenter, radius, strokeLineWidth);
        DrawSurroundingCircle(layerContext, drawingRectCenter, radius, strokeLineWidth);
      }
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorWhite, GoColorWhite, GoColorWhite, GoColorWhite);
      break;
    }
    case NodeTreeViewCellSymbolNoSetupStones:
    {
      if (useClipping)
      {
        SetClippingPath(layerContext, drawingRectCenter, radius, strokeLineWidth);
        DrawSurroundingCircle(layerContext, drawingRectCenter, radius, strokeLineWidth);
      }
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorNone, GoColorNone, GoColorNone, GoColorNone);
      break;
    }
    case NodeTreeViewCellSymbolBlackAndWhiteSetupStones:
    {
      if (useClipping)
      {
        SetClippingPath(layerContext, drawingRectCenter, radius, strokeLineWidth);
        DrawSurroundingCircle(layerContext, drawingRectCenter, radius, strokeLineWidth);
      }
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorWhite, GoColorWhite, GoColorBlack);
      break;
    }
    case NodeTreeViewCellSymbolBlackAndNoSetupStones:
    {
      if (useClipping)
      {
        SetClippingPath(layerContext, drawingRectCenter, radius, strokeLineWidth);
        DrawSurroundingCircle(layerContext, drawingRectCenter, radius, strokeLineWidth);
      }
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorNone, GoColorNone, GoColorBlack);
      break;
    }
    case NodeTreeViewCellSymbolWhiteAndNoSetupStones:
    {
      if (useClipping)
      {
        SetClippingPath(layerContext, drawingRectCenter, radius, strokeLineWidth);
        DrawSurroundingCircle(layerContext, drawingRectCenter, radius, strokeLineWidth);
      }
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorWhite, GoColorNone, GoColorNone, GoColorWhite);
      break;
    }
    case NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones:
    {
      if (useClipping)
      {
        SetClippingPath(layerContext, drawingRectCenter, radius, strokeLineWidth);
        DrawSurroundingCircle(layerContext, drawingRectCenter, radius, strokeLineWidth);
      }
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorNone, GoColorNone, GoColorWhite);
      break;
    }
    case NodeTreeViewCellSymbolBlackMove:
    case NodeTreeViewCellSymbolWhiteMove:
    {
      enum GoColor stoneColor = symbolType == NodeTreeViewCellSymbolBlackMove ? GoColorBlack : GoColorWhite;
      DrawStoneCircle(layerContext, drawingRectCenter, radius, stoneColor, strokeLineWidth);
      break;
    }
    case NodeTreeViewCellSymbolAnnotations:
    {
      DrawImageWithName(layerContext, drawingRect, uiAreaAboutIconResource);
      break;
    }
    case NodeTreeViewCellSymbolMarkup:
    {
      DrawImageWithName(layerContext, drawingRect, markupIconResource);
      break;
    }
    case NodeTreeViewCellSymbolAnnotationsAndMarkup:
    {
      CGRect drawingRectSymbolAnnotation = drawingRect;
      drawingRectSymbolAnnotation.size.width = drawingRectCenter.x - drawingRect.origin.x;
      drawingRectSymbolAnnotation.size.height = drawingRectCenter.y - drawingRect.origin.y;
      DrawImageWithName(layerContext, drawingRectSymbolAnnotation, uiAreaAboutIconResource);

      CGRect drawingRectSymbolMarkup = drawingRectSymbolAnnotation;
      drawingRectSymbolMarkup.origin = drawingRectCenter;
      DrawImageWithName(layerContext, drawingRectSymbolMarkup, markupIconResource);
      break;
    }
    case NodeTreeViewCellSymbolEmpty:
    {
      DrawStoneCircle(layerContext, drawingRectCenter, radius, GoColorNone, strokeLineWidth);
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
  CGRect canvasRectForCell = [NodeTreeViewDrawingHelper canvasRectForCellAtPosition:position metrics:metrics];

  CGRect canvasRectForMultipartCell = CGRectZero;
  canvasRectForMultipartCell.size.height = canvasRectForCell.size.height;
  canvasRectForMultipartCell.size.width =  metrics.nodeTreeViewMultipartCellSize.width;
  canvasRectForMultipartCell.origin.y = canvasRectForCell.origin.y;
  canvasRectForMultipartCell.origin.x = canvasRectForCell.origin.x - (canvasRectForCell.size.width * part);

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
