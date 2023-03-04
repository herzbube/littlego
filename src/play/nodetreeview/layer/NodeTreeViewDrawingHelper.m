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
#import "../../model/NodeTreeViewModel.h"
#import "../../../ui/Tile.h"
#import "../../../ui/CGDrawingHelper.h"
#import "../../../ui/UiUtilities.h"


@implementation NodeTreeViewDrawingHelper

#pragma mark - Private API - Layer creation functions

// -----------------------------------------------------------------------------
/// @brief Calculates 4 quarter rectangles from @a drawingRect and fills/strokes
/// each of the quarter rectangles according to the specified 4 GoColor values.
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
/// @brief Calculates 4 quarter rectangles from @a drawingRect and draws a
/// filled/stroked circle within each of the quarter rectangles according to
/// the specified 4 GoColor values.
///
/// An attempt is made that the 4 circles do not touch each other near the
/// center of @a drawingRect. To that end, the specified @a radius is reduced
/// somewhat.
///
/// Also the 4 circles are inset in an attempt so that they do not touch the
/// circle line that passes through each of the @a drawingRect corners, with the
/// circle center being located at the center point of @a drawingRect.
///
/// For small values of @a radius the outcome of the insetting/radius reduction
/// will result in a mess of pixels. As an alternative, the function
/// DrawNodeTreeViewCellSymbolSetupRectangleStyle() can be invoked to convey the
/// same meaning with a different geometric style (the quarter rectangles
/// themselves are filled/stroked instead of drawing circles).
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
/// @brief Calculates 4 quarter rectangles from @a drawingRect and draws either
/// a filled/stroked circle within each of the quarter rectangles, or
/// fills/strokes the quarter rectangles themselves, according to the specified
/// 4 GoColor values. Which drawing method is used depends on the size of
/// @a drawingRect.
// -----------------------------------------------------------------------------
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

void DrawSurroundingCircle(CGContextRef layerContext, CGPoint center, CGFloat radius, UIColor* strokeColor, CGFloat strokeLineWidth)
{
  [CGDrawingHelper drawCircleWithContext:layerContext center:center radius:radius fillColor:nil strokeColor:strokeColor strokeLineWidth:strokeLineWidth];
}

#pragma mark - Public API - Layer creation functions

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

  CGRect drawingRect = [NodeTreeViewDrawingHelper drawingRectForNodeSymbolInCell:condensed
                                                          withDrawingRectForCell:layerRect
                                                                     withMetrics:metrics];

  CGFloat strokeLineWidth = metrics.normalLineWidth * metrics.contentsScale;

  CGPoint drawingRectCenter;
  CGFloat clippingPathRadius;
  CGFloat radius;
  [NodeTreeViewDrawingHelper circularDrawingParametersInRect:drawingRect
                                             strokeLineWidth:strokeLineWidth
                                                      center:&drawingRectCenter
                                              clippingRadius:&clippingPathRadius
                                               drawingRadius:&radius];

  switch (symbolType)
  {
    case NodeTreeViewCellSymbolBlackSetupStones:
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext allowDrawingInCircleWithCenter:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorBlack, GoColorBlack, GoColorBlack);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [NodeTreeViewDrawingHelper removeNodeSymbolClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolWhiteSetupStones:
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext allowDrawingInCircleWithCenter:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorWhite, GoColorWhite, GoColorWhite, GoColorWhite);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [NodeTreeViewDrawingHelper removeNodeSymbolClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolNoSetupStones:
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext allowDrawingInCircleWithCenter:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorNone, GoColorNone, GoColorNone, GoColorNone);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [NodeTreeViewDrawingHelper removeNodeSymbolClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolBlackAndWhiteSetupStones:
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext allowDrawingInCircleWithCenter:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorWhite, GoColorWhite, GoColorBlack);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [NodeTreeViewDrawingHelper removeNodeSymbolClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolBlackAndNoSetupStones:
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext allowDrawingInCircleWithCenter:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorNone, GoColorNone, GoColorBlack);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [NodeTreeViewDrawingHelper removeNodeSymbolClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolWhiteAndNoSetupStones:
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext allowDrawingInCircleWithCenter:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorWhite, GoColorNone, GoColorNone, GoColorWhite);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [NodeTreeViewDrawingHelper removeNodeSymbolClippingPathWithContext:layerContext];
      break;
    }
    case NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones:
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext allowDrawingInCircleWithCenter:drawingRectCenter radius:clippingPathRadius];
      DrawNodeTreeViewCellSymbolSetup(layerContext, drawingRect, strokeLineWidth, GoColorBlack, GoColorNone, GoColorNone, GoColorWhite);
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);
      [NodeTreeViewDrawingHelper removeNodeSymbolClippingPathWithContext:layerContext];
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
    case NodeTreeViewCellSymbolHandicap:
    case NodeTreeViewCellSymbolKomi:
    case NodeTreeViewCellSymbolRoot:
    {
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);

      NSString* nodeSymbolString = [NodeTreeViewDrawingHelper stringForNodeSymbolType:symbolType];
      [NodeTreeViewDrawingHelper drawNodeSymbolString:nodeSymbolString
                                          withContext:layerContext
                                          drawingRect:drawingRect
                                                 font:metrics.singleCharacterNodeSymbolFont
                                              metrics:metrics];
      break;
    }
    case NodeTreeViewCellSymbolMarkup:
    case NodeTreeViewCellSymbolHandicapAndKomi:
    {
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);

      NSString* nodeSymbolString = [NodeTreeViewDrawingHelper stringForNodeSymbolType:symbolType];
      [NodeTreeViewDrawingHelper drawNodeSymbolString:nodeSymbolString
                                          withContext:layerContext
                                          drawingRect:drawingRect
                                                 font:metrics.threeCharactersNodeSymbolFont
                                              metrics:metrics];
      break;
    }
    case NodeTreeViewCellSymbolAnnotationsAndMarkup:
    {
      DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.normalLineColor, strokeLineWidth);

      CGRect drawingRectSymbolAnnotation = drawingRect;
      drawingRectSymbolAnnotation.size.height /= 2.0;
      NSString* annotationsNodeSymbolString = [NodeTreeViewDrawingHelper stringForNodeSymbolType:NodeTreeViewCellSymbolAnnotations];
      [NodeTreeViewDrawingHelper drawNodeSymbolString:annotationsNodeSymbolString
                                          withContext:layerContext
                                          drawingRect:drawingRectSymbolAnnotation
                                                 font:metrics.twoLinesOfCharactersNodeSymbolFont
                                              metrics:metrics];

      CGRect drawingRectSymbolMarkup = drawingRect;
      drawingRectSymbolMarkup.size.height /= 2.0;
      drawingRectSymbolMarkup.origin.y += drawingRectSymbolMarkup.size.height;
      // Without this adjustment the text + its shadow are too close to the
      // surrounding circle's bounding line
      drawingRectSymbolMarkup.origin.y -= 3 * metrics.contentsScale;
      NSString* markupNodeSymbolString = [NodeTreeViewDrawingHelper stringForNodeSymbolType:NodeTreeViewCellSymbolMarkup];
      [NodeTreeViewDrawingHelper drawNodeSymbolString:markupNodeSymbolString
                                          withContext:layerContext
                                          drawingRect:drawingRectSymbolMarkup
                                                 font:metrics.twoLinesOfCharactersNodeSymbolFont
                                              metrics:metrics];
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
/// @a model is used to determine the style of the node selection marker.
///
/// All sizes are taken from the metrics values in @a metrics.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateNodeSelectionLayer(CGContextRef context, bool condensed, NodeTreeViewModel* model, NodeTreeViewMetrics* metrics)
{
  CGRect layerRect = [NodeTreeViewDrawingHelper drawingRectForCell:condensed withMetrics:metrics];

  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  if (! layer)
    return NULL;

  CGContextRef layerContext = CGLayerGetContext(layer);

  CGRect drawingRect =  [NodeTreeViewDrawingHelper drawingRectForNodeSymbolInCell:condensed
                                                           withDrawingRectForCell:layerRect
                                                                      withMetrics:metrics];

  if (model.nodeSelectionStyle == NodeTreeViewNodeSelectionStyleLightCircular)
  {
    CGFloat strokeLineWidth = metrics.selectedLineWidth * metrics.contentsScale;

    CGPoint drawingRectCenter;
    CGFloat radius;
    [NodeTreeViewDrawingHelper circularDrawingParametersInRect:drawingRect
                                               strokeLineWidth:strokeLineWidth
                                                        center:&drawingRectCenter
                                                 drawingRadius:&radius];

    DrawSurroundingCircle(layerContext, drawingRectCenter, radius, metrics.selectedNodeColor, strokeLineWidth);
  }
  else
  {
    if (model.nodeSelectionStyle == NodeTreeViewNodeSelectionStyleHeavyCircular)
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext
                                 allowDrawingInCircleOfFullCellRect:layerRect
                                    disallowDrawingInNodeSymbolRect:drawingRect];

      CGPoint drawingRectCenter;
      CGFloat radius;
      [NodeTreeViewDrawingHelper circularDrawingParametersInRect:layerRect
                                                 strokeLineWidth:0.0f
                                                          center:&drawingRectCenter
                                                   drawingRadius:&radius];

      [CGDrawingHelper drawCircleWithContext:layerContext
                                      center:drawingRectCenter
                                      radius:radius
                                   fillColor:metrics.selectedNodeColor
                                 strokeColor:nil
                             strokeLineWidth:0.0f];
    }
    else
    {
      [NodeTreeViewDrawingHelper setNodeSymbolClippingPathInContext:layerContext
                                         allowDrawingInFullCellRect:layerRect
                                    disallowDrawingInNodeSymbolRect:drawingRect];

      CGFloat widthAndHeightToFill = MIN(layerRect.size.width, layerRect.size.height);
      CGSize sizeToFill = CGSizeMake(widthAndHeightToFill, widthAndHeightToFill);
      CGRect rectToFill = [UiUtilities rectWithSize:sizeToFill centeredInRect:layerRect];

      CGFloat cornerWidthAndHeight = floorf(widthAndHeightToFill / 4.0);
      CGSize cornerRadius = CGSizeMake(cornerWidthAndHeight, cornerWidthAndHeight);

      [CGDrawingHelper drawRoundedRectangleWithContext:layerContext
                                             rectangle:rectToFill
                                          cornerRadius:cornerRadius
                                             fillColor:metrics.selectedNodeColor
                                           strokeColor:nil
                                       strokeLineWidth:0.0f];
    }

    [NodeTreeViewDrawingHelper removeNodeSymbolClippingPathWithContext:layerContext];
  }

  return layer;
}

#pragma mark - Private API - Helpers for layer creation functions

// -----------------------------------------------------------------------------
/// @brief Helper method for CreateNodeSymbolLayer() that returns the string
/// that should be used to depict a node with symbol type @a symbolType.
// -----------------------------------------------------------------------------
+ (NSString*) stringForNodeSymbolType:(enum NodeTreeViewCellSymbol)symbolType
{
  switch (symbolType)
  {
    case NodeTreeViewCellSymbolAnnotations:
      return @"i";
    case NodeTreeViewCellSymbolMarkup:
      return @"</>";
    case NodeTreeViewCellSymbolHandicap:
      return @"h";
    case NodeTreeViewCellSymbolKomi:
      return @"k";
    case NodeTreeViewCellSymbolHandicapAndKomi:
      return @"h/k";
    case NodeTreeViewCellSymbolRoot:
      return @"r";
    default:
      assert(0);
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Helper method for CreateNodeSymbolLayer(), to draw @a string as part
/// of a textual node symbol.
// -----------------------------------------------------------------------------
+ (void) drawNodeSymbolString:(NSString*)string
                  withContext:(CGContextRef)context
                  drawingRect:(CGRect)drawingRect
                         font:(UIFont*)font
                      metrics:(NodeTreeViewMetrics*)metrics
{
  NSDictionary* textAttributes = @{ NSFontAttributeName : font,
                                    NSForegroundColorAttributeName : metrics.nodeSymbolTextColor,
                                    NSShadowAttributeName: metrics.nodeSymbolTextShadow };

  [CGDrawingHelper drawStringWithContext:context
                          centeredInRect:drawingRect
                                  string:string
                          textAttributes:textAttributes];
}

#pragma mark - Public API - Helpers for setting a clipping path

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with a clipping path that
/// allows drawing only within the circular area occupied by node symbols. The
/// circular area is defined by @a center and @a radius.
///
/// Invocation of this method must be balanced by also invoking
/// removeNodeSymbolClippingPathWithContext:().
///
/// This method does not use any constant values. It can therefore be used for
/// drawing into both scaled layers (e.g. CALayer) and unscaled layers
/// (e.g. CGLayerRef)
///
/// This is a simple front-end method for a corresponding backend method in
/// CGDrawingHelper. The reason why this method exists is purely to give it a
/// name to make explicit when node symbol clipping is performed.
// -----------------------------------------------------------------------------
+ (void) setNodeSymbolClippingPathInContext:(CGContextRef)context
             allowDrawingInCircleWithCenter:(CGPoint)center
                                     radius:(CGFloat)radius
{
  [CGDrawingHelper setCircularClippingPathWithContext:context
                                               center:center
                                               radius:radius];
}

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with a clipping path that
/// allows drawing everywhere within the rectangle of a full cell
/// @a fullCellRect except within the circular area occupied by the node symbol
/// inside @a nodeSymbolRect. The radius of the circular area occupied by the
/// node symbol is defined by the smaller dimension of @a nodeSymbolRect.
///
/// Invocation of this method must be balanced by also invoking
/// removeNodeSymbolClippingPathWithContext:().
///
/// This method was tested to work for drawing into unscaled layers (e.g.
/// CGLayerRef). It may not work for drawing into scaled layers (e.g. CALayer).
// -----------------------------------------------------------------------------
+ (void) setNodeSymbolClippingPathInContext:(CGContextRef)context
                 allowDrawingInFullCellRect:(CGRect)fullCellRect
            disallowDrawingInNodeSymbolRect:(CGRect)nodeSymbolRect
{
  CGPoint clippingCenter;
  CGFloat clippingRadius;
  [NodeTreeViewDrawingHelper circularClippingParametersInRect:nodeSymbolRect
                                                clippingCenter:&clippingCenter
                                               clippingRadius:&clippingRadius];

  // Although the clipping radius calculated above is geometrically correct,
  // we have to increase it by half a pixel to keep all of the stroking pixels
  // from the node symbol drawing intact. Without this adjustment, the drawing
  // that will take place within fullCellRect will overdraw some of those
  // stroking pixels. The reason why this adjustment is necessary is not
  // entirely clear, but it must be somehow related to the inversion of the
  // clipping taking place here.
  // Note: This adjustment has been tested when it is used with a CGContext
  // that is drawing into a CGLayer (A) that is not scaled, and when that
  // CGLayer (A) is later drawn on top of another CGLayer (B) that also is not
  // scaled - specifically when the node selection layer is drawn on top of a
  // node symbol layer. This adjustment might not work if the clipping path
  // is set on a CGContext that is scaled, such as the one used for drawing by
  // CALayer.
  clippingRadius += 0.5;

  [CGDrawingHelper setCircularClippingPathWithContext:context
                                               center:clippingCenter
                                               radius:clippingRadius
                                       outerRectangle:fullCellRect];
}

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with a clipping path that
/// allows drawing everywhere within the circular area defined by the smaller
/// dimension of @a fullCellRect, except within the circular area occupied by
/// the node symbol inside @a nodeSymbolRect. The radius of the circular area
/// occupied by the node symbol is defined by the smaller dimension of
/// @a nodeSymbolRect.
///
/// Invocation of this method must be balanced by also invoking
/// removeNodeSymbolClippingPathWithContext:().
///
/// This method was tested to work for drawing into unscaled layers (e.g.
/// CGLayerRef). It may not work for drawing into scaled layers (e.g. CALayer).
// -----------------------------------------------------------------------------
+ (void) setNodeSymbolClippingPathInContext:(CGContextRef)context
         allowDrawingInCircleOfFullCellRect:(CGRect)fullCellRect
            disallowDrawingInNodeSymbolRect:(CGRect)nodeSymbolRect
{
  CGPoint innerClippingCenter;
  CGFloat innerClippingRadius;
  [NodeTreeViewDrawingHelper circularClippingParametersInRect:nodeSymbolRect
                                               clippingCenter:&innerClippingCenter
                                               clippingRadius:&innerClippingRadius];

  // We ignore the outer clipping center because we assume that the two
  // rectangles have the same center
  CGPoint outerClippingCenter;
  CGFloat outerClippingRadius;
  [NodeTreeViewDrawingHelper circularClippingParametersInRect:fullCellRect
                                               clippingCenter:&outerClippingCenter
                                               clippingRadius:&outerClippingRadius];

  // Although the clipping radius calculated above is geometrically correct,
  // we have to increase it by half a pixel to keep all of the stroking pixels
  // from the node symbol drawing intact. Without this adjustment, the drawing
  // that will take place within fullCellRect will overdraw some of those
  // stroking pixels. The reason why this adjustment is necessary is not
  // entirely clear, but it must be somehow related to the inversion of the
  // clipping taking place here.
  // Note: This adjustment has been tested when it is used with a CGContext
  // that is drawing into a CGLayer (A) that is not scaled, and when that
  // CGLayer (A) is later drawn on top of another CGLayer (B) that also is not
  // scaled - specifically when the node selection layer is drawn on top of a
  // node symbol layer. This adjustment might not work if the clipping path
  // is set on a CGContext that is scaled, such as the one used for drawing by
  // CALayer.
  innerClippingRadius += 0.5;

  [CGDrawingHelper setCircularClippingPathWithContext:context
                                               center:innerClippingCenter
                                          innerRadius:innerClippingRadius
                                          outerRadius:outerClippingRadius];
}

// -----------------------------------------------------------------------------
/// @brief Removes a previously configured node symbol clipping path from the
/// drawing context @a context. Invocation of this method balances a previous
/// invocation of any of the setNodeSymbolClippingPathInContext:() methods.
///
/// This is a simple front-end method for a corresponding backend method in
/// CGDrawingHelper. The reason why this method exists is purely to give it a
/// name to make explicit when node symbol clipping is performed.
// -----------------------------------------------------------------------------
+ (void) removeNodeSymbolClippingPathWithContext:(CGContextRef)context
{
  [CGDrawingHelper removeClippingPathWithContext:context];
}

#pragma mark - Public API - Drawing helpers

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
  CGContextDrawLayerInRect(context, drawingRect, layer);
}

// -----------------------------------------------------------------------------
/// @brief Draws the node number string @a nodeNumberString using the specified
/// drawing context and attributes @a textAttributes so that the string is
/// centered within the cell identified by @a position.
///
/// The layer is not drawn if it does not intersect with the tile @a tileRect.
/// The tile rectangle origin must be in the canvas coordinate system.
// -----------------------------------------------------------------------------
+ (void) drawNodeNumber:(NSString*)nodeNumberString
            withContext:(CGContextRef)context
         textAttributes:(NSDictionary*)textAttributes
             centeredAt:(NodeTreeViewCellPosition*)position
         inTileWithRect:(CGRect)tileRect
            withMetrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRectForNodeNumberCell = [NodeTreeViewDrawingHelper canvasRectForNodeNumberCellAtPosition:position metrics:metrics];
  CGSize drawingSizeForNodeNumber = metrics.nodeNumberLabelMaximumSize;
  CGRect canvasRectForNodeNumber = [UiUtilities rectWithSize:drawingSizeForNodeNumber
                                              centeredInRect:canvasRectForNodeNumberCell];
  if (! CGRectIntersectsRect(tileRect, canvasRectForNodeNumber))
    return;

  CGRect drawingRect = [NodeTreeViewDrawingHelper drawingRectFromCanvasRect:canvasRectForNodeNumber
                                                             inTileWithRect:tileRect];
  [CGDrawingHelper drawStringWithContext:context
                          centeredInRect:drawingRect
                                  string:nodeNumberString
                          textAttributes:textAttributes];
}

// -----------------------------------------------------------------------------
/// @brief Draws the node number string @a nodeNumberString using the specified
/// drawing context and attributes @a textAttributes so that the string is
/// centered within a multipart cell. Only that part of the string which
/// intersects with the standalone cell @a part of the multipart cell needs
/// to be drawn. The standalone cell is identified by @a position, this defines
/// the multipart cell's location on the canvas.
///
/// The string is not drawn if it does not intersect with the tile @a tileRect.
/// The tile rectangle origin must be in the canvas coordinate system.
// -----------------------------------------------------------------------------
+ (void) drawNodeNumber:(NSString*)nodeNumberString
            withContext:(CGContextRef)context
         textAttributes:(NSDictionary*)textAttributes
                   part:(int)part
           partPosition:(NodeTreeViewCellPosition*)position
         inTileWithRect:(CGRect)tileRect
            withMetrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRectForNodeNumberMultipartCell = [NodeTreeViewDrawingHelper canvasRectForNodeNumberMultipartCellPart:part
                                                                                                       partPosition:position
                                                                                                            metrics:metrics];
  CGSize drawingSizeForNodeNumber = metrics.nodeNumberLabelMaximumSize;
  CGRect canvasRectForNodeNumber = [UiUtilities rectWithSize:drawingSizeForNodeNumber
                                              centeredInRect:canvasRectForNodeNumberMultipartCell];
  if (! CGRectIntersectsRect(tileRect, canvasRectForNodeNumber))
    return;

  CGRect drawingRect = [NodeTreeViewDrawingHelper drawingRectFromCanvasRect:canvasRectForNodeNumber
                                                             inTileWithRect:tileRect];
  [CGDrawingHelper drawStringWithContext:context
                          centeredInRect:drawingRect
                                  string:nodeNumberString
                          textAttributes:textAttributes];
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
/// @brief Returns the rectangle occupied by the specified multipart cell on
/// the "canvas", i.e. the area covered by the entire node tree view. The
/// multipart cell is identified by one of its sub-cells. @a part identifies
/// the sub-cell within the multipart cell, @a position the sub-cell's position
/// on the canvas. The origin of the returned rectangle is in the upper-left
/// corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForMultipartCellPart:(int)part
                             partPosition:(NodeTreeViewCellPosition*)position
                               metrics:(NodeTreeViewMetrics*)metrics
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
/// @brief Returns the rectangle occupied by the specified multipart cell on
/// the node number view "canvas", i.e. the area covered by the entire node
/// number view. The multipart cell is identified by one of its sub-cells.
/// @a part identifies the sub-cell within the multipart cell, @a position the
/// sub-cell's position on the canvas. The origin of the returned rectangle is
/// in the upper-left corner.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForNodeNumberMultipartCellPart:(int)part
                                       partPosition:(NodeTreeViewCellPosition*)position
                                            metrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRectForCell = [NodeTreeViewDrawingHelper canvasRectForNodeNumberCellAtPosition:position metrics:metrics];

  CGRect canvasRectForMultipartCell = CGRectZero;
  canvasRectForMultipartCell.size.height = canvasRectForCell.size.height;
  canvasRectForMultipartCell.size.width =  metrics.nodeNumberViewMultipartCellSize.width;
  canvasRectForMultipartCell.origin.y = canvasRectForCell.origin.y;
  canvasRectForMultipartCell.origin.x = canvasRectForCell.origin.x - (canvasRectForCell.size.width * part);

  return canvasRectForMultipartCell;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by a cell on the node tree view
/// "canvas", i.e. the area covered by the entire node tree view, which is
/// identified by @a position. The cell can be either a standalone cell, or
/// a sub-cell. The origin of the returned rectangle is in the upper-left
/// corner.
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
/// @brief Returns the rectangle occupied by a cell on the node number view
/// "canvas", i.e. the area covered by the entire node number view, which is
/// identified by @a position.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForNodeNumberCellAtPosition:(NodeTreeViewCellPosition*)position
                                         metrics:(NodeTreeViewMetrics*)metrics
{
  CGRect canvasRect = CGRectZero;
  canvasRect.origin = [metrics nodeNumberCellRectOriginFromPosition:position];
  canvasRect.size = metrics.nodeNumberViewCellSize;
  return canvasRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by @a layer on the "canvas", i.e. the
/// area covered by the entire node tree view, after placing @a layer so that it
/// is centered within the cell identified by @a position. The cell can be
/// either a standalone cell, or a sub-cell. The origin of the returned
/// rectangle is in the upper-left corner.
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
/// center of the cell identified by @a position. The cell can be either a
/// standalone cell, or a sub-cell. The origin of the returned rectangle is in
/// the upper-left corner.
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
/// @brief Returns the rectangle occupied by the specified multipart cell on
/// @a tile. The multipart cell is identified by one of its sub-cells. @a part
/// identifies the sub-cell within the multipart cell, @a position the
/// sub-cell's position on the canvas. The origin of the returned rectangle is
/// in the upper-left corner. Returns CGRectZero if the multipart cell is not
/// located on @a tile.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForMultipartCellPart:(int)part
                              partPosition:(NodeTreeViewCellPosition*)position
                                    onTile:(id<Tile>)tile
                                   metrics:(NodeTreeViewMetrics*)metrics
{
  if (! position)
    return CGRectZero;

  CGRect canvasRectForTile = [NodeTreeViewDrawingHelper canvasRectForTile:tile
                                                                  metrics:metrics];
  CGRect canvasRectForMultipartCell = [NodeTreeViewDrawingHelper canvasRectForMultipartCellPart:part
                                                                                   partPosition:position
                                                                                        metrics:metrics];
  CGRect canvasRectForMultipartCellOnTile = CGRectIntersection(canvasRectForTile, canvasRectForMultipartCell);
  // Rectangles that are adjacent and share a side *do* intersect: The
  // intersection rectangle has either zero width or zero height, depending on
  // which side the two intersecting rectangles share. For this reason, we
  // must check CGRectIsEmpty() in addition to CGRectIsNull().
  if (CGRectIsNull(canvasRectForMultipartCellOnTile) || CGRectIsEmpty(canvasRectForMultipartCellOnTile))
  {
    return CGRectZero;
  }

  CGRect drawingRectForMultipartCell = [NodeTreeViewDrawingHelper drawingRectFromCanvasRect:canvasRectForMultipartCellOnTile
                                                                             inTileWithRect:canvasRectForTile];
  return drawingRectForMultipartCell;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by the specified cell on @a tile.
/// @a position identifies the cell's position on the canvas. The cell can be
/// either a standalone cell, or a sub-cell. The origin of the returned
/// rectangle is in the upper-left corner. Returns CGRectZero if the standalone
/// cell is not located on @a tile.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForCellAtPosition:(NodeTreeViewCellPosition*)position
                                 onTile:(id<Tile>)tile
                                metrics:(NodeTreeViewMetrics*)metrics
{
  if (! position)
    return CGRectZero;

  CGRect canvasRectForTile = [NodeTreeViewDrawingHelper canvasRectForTile:tile
                                                                  metrics:metrics];
  CGRect canvasRectForCell = [NodeTreeViewDrawingHelper canvasRectForCellAtPosition:position
                                                                            metrics:metrics];
  CGRect canvasRectForCellOnTile = CGRectIntersection(canvasRectForTile, canvasRectForCell);
  // Rectangles that are adjacent and share a side *do* intersect: The
  // intersection rectangle has either zero width or zero height, depending on
  // which side the two intersecting rectangles share. For this reason, we
  // must check CGRectIsEmpty() in addition to CGRectIsNull().
  if (CGRectIsNull(canvasRectForCellOnTile) || CGRectIsEmpty(canvasRectForCellOnTile))
  {
    return CGRectZero;
  }

  CGRect drawingRectForCell = [NodeTreeViewDrawingHelper drawingRectFromCanvasRect:canvasRectForCellOnTile
                                                                    inTileWithRect:canvasRectForTile];
  return drawingRectForCell;
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

#pragma mark - Public API - Helpers for calculating parameters for drawing in a circular area

// -----------------------------------------------------------------------------
/// @brief Helper method to calculate the parameters for drawing within a
/// circular area defined by the bounding rectangle @a rect. The radius of the
/// circular area is defined by the smaller dimension of the bounding rectangle.
/// The calculated values are filled into the out parameters @a center,
/// @a clippingRadius and @a drawingRadius.
///
/// @a center is the exact (i.e. not floor'ed) center of the circular area. It
/// is equal to the center of the bounding rectangle @a rect.
///
/// @a clippingRadius is equal to exactly (i.e. not floor'ed) one half of the
/// smaller dimension of the bounding rectangle @a rect. Together with @a center
/// this exactly defines the circular area within which drawing should take
/// place. To enforce this @a clippingRadius can be used to set a circular
/// clipping path.
///
/// @a drawingRadius is set to the radius that can be used to draw a stroked
/// circle line, where the stroke line width is set to @a strokeLineWidth. The
/// resulting circle line remains completely within the bounds defined by
/// @a clippingRadius. @a drawingRadius is floor'ed to the nearest integer
/// value.
///
/// This method does not use any constant values. It can therefore be used for
/// calculating parameters for drawing into both scaled layers (e.g. CALayer)
/// and unscaled layers (e.g. CGLayerRef)
// -----------------------------------------------------------------------------
+ (void) circularDrawingParametersInRect:(CGRect)rect
                         strokeLineWidth:(CGFloat)strokeLineWidth
                                  center:(CGPoint*)center
                          clippingRadius:(CGFloat*)clippingRadius
                           drawingRadius:(CGFloat*)drawingRadius
{
  *center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

  // Clipping path is not stroked, so we can use the exact radius without
  // floor'ing
  *clippingRadius = MIN(rect.size.width, rect.size.height) / 2.0f;

  // Adjust radius to stay within the rectangle. Also note that we floorf()
  // only at the end, after all the results and potential rounding errors
  // have been accumulated
  *drawingRadius = floorf(*clippingRadius - strokeLineWidth / 2.0f);
}

// -----------------------------------------------------------------------------
/// @brief Helper method to calculate the parameters for drawing a stroked
/// circle line that remains within a circular area defined by the bounding
/// rectangle @a rect. The radius of the circular area is defined by the smaller
/// dimension of the bounding rectangle. The calculated values are filled into
/// the out parameters @a center and @a drawingRadius.
///
/// @a center is the exact (i.e. not floor'ed) center of the circular area. It
/// is equal to the center of the bounding rectangle @a rect.
///
/// @a drawingRadius is set to the radius that can be used to draw a stroked
/// circle line, where the stroke line width is set to @a strokeLineWidth. The
/// resulting circle line is completely within the circular area defined by
/// the smaller dimension of the bounding rectangle @a rect. @a drawingRadius
/// is floor'ed to the nearest integer value.
///
/// This method does not use any constant values. It can therefore be used for
/// calculating parameters for drawing into both scaled layers (e.g. CALayer)
/// and unscaled layers (e.g. CGLayerRef)
// -----------------------------------------------------------------------------
+ (void) circularDrawingParametersInRect:(CGRect)rect
                         strokeLineWidth:(CGFloat)strokeLineWidth
                                  center:(CGPoint*)center
                           drawingRadius:(CGFloat*)drawingRadius
{
  CGFloat clippingRadius;
  [NodeTreeViewDrawingHelper circularDrawingParametersInRect:rect
                                             strokeLineWidth:strokeLineWidth
                                                      center:center
                                              clippingRadius:&clippingRadius
                                               drawingRadius:drawingRadius];
}

// -----------------------------------------------------------------------------
/// @brief Helper method to calculate the parameters for setting a clipping path
/// to prevent drawing outside of a circular area defined by the bounding
/// rectangle @a rect. The radius of the circular area is defined by the smaller
/// dimension of the bounding rectangle. The calculated values are filled into
/// the out parameters @a center and @a clippingRadius.
///
/// @a center is the exact (i.e. not floor'ed) center of the circular area. It
/// is equal to the center of the bounding rectangle @a rect.
///
/// @a clippingRadius is equal to exactly (i.e. not floor'ed) one half of the
/// smaller dimension of the bounding rectangle @a rect. Together with @a center
/// this exactly defines the circular area within which drawing should take
/// place. To enforce this @a clippingRadius can be used to set a circular
/// clipping path.
///
/// This method does not use any constant values. It can therefore be used for
/// calculating parameters for drawing into both scaled layers (e.g. CALayer)
/// and unscaled layers (e.g. CGLayerRef)
// -----------------------------------------------------------------------------
+ (void) circularClippingParametersInRect:(CGRect)rect
                           clippingCenter:(CGPoint*)clippingCenter
                           clippingRadius:(CGFloat*)clippingRadius
{
  CGFloat drawingRadius;
  [NodeTreeViewDrawingHelper circularDrawingParametersInRect:rect
                                             strokeLineWidth:0.0f
                                                      center:clippingCenter
                                              clippingRadius:clippingRadius
                                               drawingRadius:&drawingRadius];
}


@end
