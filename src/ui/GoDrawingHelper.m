// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoDrawingHelper.h"
#import "CGDrawingHelper.h"
#import "../utility/UIColorAdditions.h"


@implementation GoDrawingHelper

#pragma mark - Drawing shapes

// -----------------------------------------------------------------------------
/// @brief Draws a circle with center point @a center and radius @a radius.
/// The circle represents a Go stone with color @a stoneColor.
///
/// If @a stoneColor is #GoColorBlack then the circle is filled with black
/// color. The circle is not stroked.
///
/// If @a stoneColor is #GoColorWhite then the circle is filled with white
/// color. The circle is stroked with black color, using the stroke line
/// width @a strokeLineWidth.
///
/// If @a stoneColor is #GoColorNone then the circle is not filled. The
/// circle is stroked with black color, using the stroke line width
/// @a strokeLineWidth.
// -----------------------------------------------------------------------------
+ (void) drawStoneCircleWithContext:(CGContextRef)context
                             center:(CGPoint)center
                             radius:(CGFloat)radius
                         stoneColor:(enum GoColor)stoneColor
                    strokeLineWidth:(CGFloat)strokeLineWidth
{
  UIColor* fillColor;
  UIColor* strokeColor;
  [GoDrawingHelper fillAndStrokeColorsForStoneColor:stoneColor fillColor:&fillColor strokeColor:&strokeColor];

  [CGDrawingHelper drawCircleWithContext:context
                                  center:center
                                  radius:radius
                               fillColor:fillColor
                             strokeColor:strokeColor
                         strokeLineWidth:strokeLineWidth];
}

// -----------------------------------------------------------------------------
/// @brief Draws a Go stone with a 3D effect (shadow and highlight) within the
/// bounding rectangle @a boundingRectangle. The stone color is determined by
/// @a stoneColor and @a isCrossHairStone (the latter indicates whether the
/// stone has its natural color or uses a special cross-hair stone color).
///
/// If @a boundingRectangle is not square, then the smaller dimension is used to
/// limit the stone circle size.
///
/// The result of this method approximates the images in the resource files
/// stone-black.png, stone-white.png and stone-crosshair.png, which were
/// produced by exporting from the original SVG file stones.svg with the export
/// function of Inkscape (see the MediaFiles text file in the documentation for
/// details on the process). The SVG source in stones.svg was analyzed manually
/// to obtain the numbers that are used in the implementation of this method and
/// its sub-methods. The implementation is written so that stones of variable
/// size can be drawn while all aspects of the stone image are scaled to the
/// desired target size.
///
/// Notes on the SVG source analysis, and how this method imitates the SVG
/// drawing with Core Graphics:
/// - Each of the stones consists of 3 layers:
///   - A shadow layer at the bottom.
///   - The actual stone layer above the shadow layer.
///   - A highlight layer at the top.
/// - All layers use a circle to represent a stone. The circle has a fixed
///   radius <r>.
/// - Shadow layer: In SVG this is done with a gaussian blur applied to the
///   stone circle. Core Graphics does not have a gaussian blur function, it
///   only allows to generate a shadow with an amount of blur for the fill
///   and/or stroke of a path. This method approximates the SVG gaussian blur
///   shadow by drawing a Core Graphics shadow for the filled stone, with
///   experimentally determined blur and offset numbers so that the result looks
///   approximately the same as in the SVG original.
/// - Stone layer: This uses a radial gradient with solid colors, to the effect
///   that the entire stone circle is filled. The focus of the radial gradient
///   is located a certain distance above the stone circle center which results
///   in a moderate lighting effect as if the light source is above the stone.
///   To allow for variable stone sizes, the distance of the gradient focus
///   above the stone circle center can be expressed as a percentage of the
///   stone circle radius. The percentage used in the implementation of this
///   method was determined with the measuring tool in Inkscape.
/// - Highlight layer: This uses another radial gradient, but this time the end
///   color is fully transparent. The end circle of the gradient uses a very
///   small radius so that the bright white'ish starting color quickly fades out
///   to nothing, thus creating the glare lighting effect. Both the start and
///   end circle centers of the radial gradient are located above the stone
///   circle center, at varying distances. As for the stone layer, the distances
///   above the stone circle center can be expressed as percentages of the stone
///   circle radius, and the percentages used in the implementation of this
///   method were determined with the measuring tool in Inkscape.
// -----------------------------------------------------------------------------
+ (void) draw3dStoneWithContext:(CGContextRef)context
              boundingRectangle:(CGRect)boundingRectangle
                     stoneColor:(enum GoColor)stoneColor
               isCrossHairStone:(bool)isCrossHairStone;
{
  CGFloat lesserDimension = MIN(boundingRectangle.size.width, boundingRectangle.size.height);

  // Both the stone and its shadow must fit into the bounding rectangle.
  // - The shadow is bigger than the stone, otherwise it would not be visible
  //   => The stone circle does not extend to the edge of the bounding rectangle
  // - The shadow is offset in y-direction but not in x-direction
  //   => The stone circle center is not equal to the bounding rectangle center
  CGPoint boundingRectangleCenter = CGPointMake(CGRectGetMidX(boundingRectangle),
                                                CGRectGetMidY(boundingRectangle));

  // Both the stone and its shadow must fit into the layer. The shadow must be
  // larger than the stone, otherwise it would not be visible because it would
  // be covered by the stone. The size that the caller specifies therefore
  // corresponds to the shadow size, and the stone circle must not use the
  // entire available size, i.e. the stone circle radius must be less than 50%.
  // Specifically, the shadow layer in stones.svg is 294.4px wide/high. This
  // corresponds to the size we have available for drawing. The stone circle
  // radius in stones.svg is 131.42857px, or 44.64% of the available size. Here
  // we round this to 45%.
  CGFloat stoneCircleRadius = lesserDimension * 0.45f;
  // The remaining area around the stone circle is used for drawing the shadow.
  // Specifically, the diameter of the stone layer in stones.svg is 262.85714,
  // which leaves 31.54286px for the shadow.
  CGFloat widthAndHeightAvailableForShadow = lesserDimension - stoneCircleRadius * 2.0f;
  // In Core Graphics, shadowing works by defining an amount of blur. This is
  // the number of points that are added ***ON ALL SIDES*** of a filled path
  // (or on all sides of the stroke of a path, but since we don't stroke this
  // is not relevant here). The width/height available for drawing the shadow
  // must therefore be divided by 2 to get the amount of blur.
  // Note: In the Inkscape UI the amount of blur is shown as 22.4%, in the
  // underlying SVG markup this results in an feGaussianBlur element with the
  // attribute stdDeviation="6.5714287". These values are of no use here,
  // though, because the Core Graphics shadow API does not correspond to the
  // Gaussian blur API of SVG/Inkscape.
  CGFloat shadowBlur = widthAndHeightAvailableForShadow / 2.0f;
  // We don't want the shadow to surround the stone on all sides, we want it to
  // be offset in y-direction. Specifically, in stones.svg the center of the
  // circle in the shadow layer is offset by about 8.5px below the center of the
  // circle in the stone layer. This is 26.95% of the height available for
  // drawing the shadow. Here we round this to 27%.
  CGFloat shadowOffsetY = widthAndHeightAvailableForShadow * 0.27f;
  // Initially we said that the size that the caller specifies corresponds to
  // the shadow size. The layer center therefore corresponds to the shadow
  // center, and the shadow offset in y-direction in relation to the stone
  // circle is achieved by placing the stone circle center above the layer
  // (= shadow) center.
  CGPoint stoneCircleCenter = CGPointMake(boundingRectangleCenter.x,
                                          boundingRectangleCenter.y - shadowOffsetY);

  [GoDrawingHelper drawStoneWithContext:context
                      stoneCircleCenter:stoneCircleCenter
                      stoneCircleRadius:stoneCircleRadius
                             stoneColor:stoneColor
                       isCrossHairStone:isCrossHairStone
                             shadowBlur:shadowBlur
                          shadowOffsetY:shadowOffsetY];
}

// -----------------------------------------------------------------------------
/// @brief Draws a rectangle with origin and size specified by @a rectangle.
/// The rectangle uses a fill/stroke color scheme that corresponds to a Go stone
/// with color @a stoneColor.
///
/// If @a stoneColor is #GoColorBlack then the rectangle is filled with black
/// color. The rectangle is not stroked.
///
/// If @a stoneColor is #GoColorWhite then the rectangle is filled with white
/// color. The rectangle is stroked with black color, using the stroke line
/// width @a strokeLineWidth.
///
/// If @a stoneColor is #GoColorNone then the rectangle is not filled. The
/// rectangle is stroked with black color, using the stroke line width
/// @a strokeLineWidth.
// -----------------------------------------------------------------------------
+ (void) drawStoneRectangleWithContext:(CGContextRef)context
                             rectangle:(CGRect)rectangle
                            stoneColor:(enum GoColor)stoneColor
                       strokeLineWidth:(CGFloat)strokeLineWidth
{
  UIColor* fillColor;
  UIColor* strokeColor;
  [GoDrawingHelper fillAndStrokeColorsForStoneColor:stoneColor fillColor:&fillColor strokeColor:&strokeColor];

  [CGDrawingHelper drawRectangleWithContext:context
                                  rectangle:rectangle
                                  fillColor:fillColor
                                strokeColor:strokeColor
                            strokeLineWidth:strokeLineWidth];
}

#pragma mark - Filling and stroking

// -----------------------------------------------------------------------------
/// @brief Fills the out parameters @a fillColor and @a strokeColor with
/// fill/and or stroke colors that can be used to draw a Go stone with color
/// @a stoneColor.
///
/// If @a stoneColor is #GoColorBlack then both @a fillColor and @a strokeColor
/// are set to black. Note that the black stone must also be stroked to make it
/// the same size as the white stone.
///
/// If @a stoneColor is #GoColorWhite then @a fillColor is set to white and
/// @a strokeColor is set to black.
///
/// If @a stoneColor is #GoColorNone then @a fillColor is set to @e nil and
/// @a strokeColor is set to black.
// -----------------------------------------------------------------------------
+ (void) fillAndStrokeColorsForStoneColor:(enum GoColor)stoneColor
                                fillColor:(UIColor**)fillColor
                              strokeColor:(UIColor**)strokeColor
{
  if (stoneColor == GoColorBlack)
  {
    *fillColor = [UIColor blackColor];
    *strokeColor = [UIColor blackColor];
  }
  else if (stoneColor == GoColorWhite)
  {
    *fillColor = [UIColor whiteColor];
    *strokeColor = [UIColor blackColor];
  }
  else
  {
    *fillColor = nil;
    *strokeColor = [UIColor blackColor];
  }
}

#pragma mark - Private API - Helper functions for draw3dStoneWithContext:boundingRectangle:stoneColor:isCrossHairStone:()

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// draw3dStoneWithContext:boundingRectangle:stoneColor:isCrossHairStone:()
/// that draws all 3 layers that make up a Go stone.
// -----------------------------------------------------------------------------
+ (void) drawStoneWithContext:(CGContextRef)context
            stoneCircleCenter:(CGPoint)stoneCircleCenter
            stoneCircleRadius:(CGFloat)stoneCircleRadius
                   stoneColor:(enum GoColor)stoneColor
             isCrossHairStone:(bool)isCrossHairStone
                   shadowBlur:(CGFloat)shadowBlur
                shadowOffsetY:(CGFloat)shadowOffsetY
{
  // The order in which things are drawn is important: Later drawing covers
  // earlier drawing.

  [GoDrawingHelper drawStoneShadowLayerWithContext:context
                                 stoneCircleCenter:stoneCircleCenter
                                 stoneCircleRadius:stoneCircleRadius
                                              blur:shadowBlur
                                           offsetY:shadowOffsetY];

  [GoDrawingHelper drawStoneMainLayerWithContext:context
                               stoneCircleCenter:stoneCircleCenter
                               stoneCircleRadius:stoneCircleRadius
                                      stoneColor:stoneColor
                                isCrossHairStone:isCrossHairStone];

  [GoDrawingHelper drawStoneHighlightLayerWithContext:context
                                    stoneCircleCenter:stoneCircleCenter
                                    stoneCircleRadius:stoneCircleRadius
                                           stoneColor:stoneColor
                                     isCrossHairStone:isCrossHairStone];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// draw3dStoneWithContext:boundingRectangle:stoneColor:isCrossHairStone:()
/// that draws the shadow layer of a Go stone.
// -----------------------------------------------------------------------------
+ (void) drawStoneShadowLayerWithContext:(CGContextRef)context
                       stoneCircleCenter:(CGPoint)stoneCircleCenter
                       stoneCircleRadius:(CGFloat)stoneCircleRadius
                                    blur:(CGFloat)blur
                                 offsetY:(CGFloat)offsetY
{
  CGContextSaveGState(context);

  // Same fill color as in stones.svg.
  UIColor* fillColor = [UIColor blackColor];

  CGSize offset = CGSizeMake(0.0f, offsetY);
  // The opacity of the shadow layer in stones.svg is 60.1%. This corresponds
  // to alpha 39.9%, or hex 0x65. However, because shadowing in SVG works
  // differently than in Core Graphics, the opacity from stones.svg cannot be
  // used directly here. Instead, an experimentally determined alpha value is
  // used here for the shadow color. Note that unlike SVG/Inkscape, which only
  // works with opacity/alpha, Core Graphics wants a full shadow color value,
  // so we use the same base color as the fill color (i.e. black), just with an
  // alpha.
  UIColor* shadowColor = [UIColor colorFromHexString:@"00000080"];

  CGContextSetShadowWithColor(context,
                              offset,
                              blur,
                              shadowColor.CGColor);

  [CGDrawingHelper drawCircleWithContext:context
                                  center:stoneCircleCenter
                                  radius:stoneCircleRadius
                               fillColor:fillColor
                             strokeColor:nil
                         strokeLineWidth:0.0f];
  // Remove shadow
  CGContextRestoreGState(context);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// draw3dStoneWithContext:boundingRectangle:stoneColor:isCrossHairStone:()
/// that draws the main stone layer of a Go stone.
// -----------------------------------------------------------------------------
+ (void) drawStoneMainLayerWithContext:(CGContextRef)context
                     stoneCircleCenter:(CGPoint)stoneCircleCenter
                     stoneCircleRadius:(CGFloat)stoneCircleRadius
                            stoneColor:(enum GoColor)stoneColor
                      isCrossHairStone:(bool)isCrossHairStone
{
  // The gradient start/end colors can be taken from the Inkscape UI by
  // inspecting the radial gradient's two stop colors.
  UIColor* gradientStartColor;
  UIColor* gradientEndColor;
  // The gradient focal center (i.e. center of the gradient start circle) and
  // the center of the gradient end circle are located a certain distance above
  // the stone circle center. The distance in pixel must be measured manually in
  // the Inkscape UI. To remain flexible, the distance is then expressed as a
  // percentage, or factor, of the stone circle radius.
  CGFloat gradientFocalCenterYFactor;
  // For the stone layer the end circle center is the same as the stone circle
  // center, so we can assign factor 0.0f here for all stones.
  CGFloat gradientEndCenterYFactor = 0.0f;
  // The scale factors can be taken from the gradientTransform property of the
  // <radialGradient> element in the stones.svg source. The transform parameters
  // a and d correspond to the x/y factors.
  // The factors are the same for all stones, so we can ssign them here.
  CGFloat gradientEndRadiusScaleFactorX = 1.2021983f;
  CGFloat gradientEndRadiusScaleFactorY = 1.1837884f;

  if (isCrossHairStone)
  {
    // The radial gradient used to fill the cross-hair stone layer in stones.svg
    // has id="radialGradient3893"
    gradientStartColor = [UIColor colorFromHexString:@"3232ffff"];
    gradientEndColor = [UIColor colorFromHexString:@"1515c8ff"];
    // The focal center of the radial gradient used to fill the cross-hair stone
    // layer in stones.svg is about 90px above the stone circle center. This is
    // 68.48% of the stone circle radius 131.42857px.
    gradientFocalCenterYFactor = 0.6848f;
  }
  else if (stoneColor == GoColorBlack)
  {
    // The radial gradient used to fill the black stone layer in stones.svg
    // has id="radialGradient3768"
    gradientStartColor = [UIColor colorFromHexString:@"323232ff"];
    gradientEndColor = [UIColor colorFromHexString:@"151515ff"];
    // The focal center of the radial gradient used to fill the black stone
    // layer in stones.svg is about 90px above the stone circle center. This is
    // 68.48% of the stone circle radius 131.42857px.
    gradientFocalCenterYFactor = 0.6848f;
  }
  else
  {
    // The radial gradient used to fill the white stone layer in stones.svg
    // has id="radialGradient3778"
    gradientStartColor = [UIColor whiteColor];
    gradientEndColor = [UIColor colorFromHexString:@"dadadaff"];
    // The focal center of the radial gradient used to fill the white stone
    // layer in stones.svg is about 69px above the stone circle center. This is
    // 52.57% of the stone circle radius 131.42857px.
    gradientFocalCenterYFactor = 0.5257f;
  }

  [GoDrawingHelper drawStoneLayerWithContext:context
                           stoneCircleCenter:stoneCircleCenter
                           stoneCircleRadius:stoneCircleRadius
                          gradientStartColor:gradientStartColor
                            gradientEndColor:gradientEndColor
                  gradientFocalCenterYFactor:gradientFocalCenterYFactor
                    gradientEndCenterYFactor:gradientEndCenterYFactor
               gradientEndRadiusScaleFactorX:gradientEndRadiusScaleFactorX
               gradientEndRadiusScaleFactorY:gradientEndRadiusScaleFactorY];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// draw3dStoneWithContext:boundingRectangle:stoneColor:isCrossHairStone:()
/// that draws the highlight layer of a Go stone.
// -----------------------------------------------------------------------------
+ (void) drawStoneHighlightLayerWithContext:(CGContextRef)context
                          stoneCircleCenter:(CGPoint)stoneCircleCenter
                          stoneCircleRadius:(CGFloat)stoneCircleRadius
                                 stoneColor:(enum GoColor)stoneColor
                           isCrossHairStone:(bool)isCrossHairStone
{
  // For a description of the parameters, see the method
  // drawStoneMainLayerWithContext...
  UIColor* gradientStartColor;
  UIColor* gradientEndColor;
  // The focal center of the radial gradient used to fill any of the stone
  // highlight layers in stones.svg is about 111px above the stone circle
  // center. This is 84.73% of the stone circle radius 131.42857px.
  CGFloat gradientFocalCenterYFactor = 0.8473f;
  // The end circle center of the radial gradient used to fill any of the
  // stone highlight layer in stones.svg is about 80px above the stone circle
  // center. This is 61.07% of the stone circle radius 131.42857px.
  CGFloat gradientEndCenterYFactor = 0.6107f;
  CGFloat gradientEndRadiusScaleFactorX = 0.81687026f;
  CGFloat gradientEndRadiusScaleFactorY = 0.39511169f;

  if (isCrossHairStone)
  {
    // The radial gradient used to fill the cross-hair stone highlight layer in
    // stones.svg has id="radialGradient3923"
    gradientStartColor = [UIColor colorFromHexString:@"8585ffff"];
    gradientEndColor = [UIColor colorFromHexString:@"1515c800"];

  }
  else if (stoneColor == GoColorBlack)
  {
    // The radial gradient used to fill the black stone highlight layer in
    // stones.svg has id="radialGradient3810"
    gradientStartColor = [UIColor colorFromHexString:@"858585ff"];
    gradientEndColor = [UIColor colorFromHexString:@"15151500"];
  }
  else
  {
    // The radial gradient used to fill the white stone highlight layer in
    // stones.svg has id="radialGradient3759"
    gradientStartColor = [UIColor colorFromHexString:@"f9f9f9ff"];
    gradientEndColor = [UIColor colorFromHexString:@"dcdcdc00"];
  }

  [GoDrawingHelper drawStoneLayerWithContext:context
                           stoneCircleCenter:stoneCircleCenter
                           stoneCircleRadius:stoneCircleRadius
                          gradientStartColor:gradientStartColor
                            gradientEndColor:gradientEndColor
                  gradientFocalCenterYFactor:gradientFocalCenterYFactor
                    gradientEndCenterYFactor:gradientEndCenterYFactor
               gradientEndRadiusScaleFactorX:gradientEndRadiusScaleFactorX
               gradientEndRadiusScaleFactorY:gradientEndRadiusScaleFactorY];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// draw3dStoneWithContext:boundingRectangle:stoneColor:isCrossHairStone:()
/// that draws a radial gradient that is clipped by the boundaries of a Go
/// stone.
// -----------------------------------------------------------------------------
+ (void) drawStoneLayerWithContext:(CGContextRef)context
                 stoneCircleCenter:(CGPoint)stoneCircleCenter
                 stoneCircleRadius:(CGFloat)stoneCircleRadius
                gradientStartColor:(UIColor*)gradientStartColor
                  gradientEndColor:(UIColor*)gradientEndColor
        gradientFocalCenterYFactor:(CGFloat)gradientFocalCenterYFactor
          gradientEndCenterYFactor:(CGFloat)gradientEndCenterYFactor
     gradientEndRadiusScaleFactorX:(CGFloat)gradientEndRadiusScaleFactorX
     gradientEndRadiusScaleFactorY:(CGFloat)gradientEndRadiusScaleFactorY
{
  CGPoint startCenter = CGPointMake(stoneCircleCenter.x,
                                    stoneCircleCenter.y - stoneCircleRadius * gradientFocalCenterYFactor);
  CGPoint endCenter = CGPointMake(stoneCircleCenter.x,
                                  stoneCircleCenter.y - stoneCircleRadius * gradientEndCenterYFactor);

  // The radial gradient end circle may be larger than the stone circle, so we
  // must clip radial gradient drawing to confine it to the stone circle
  // boundary
  [CGDrawingHelper setCircularClippingPathWithContext:context
                                               center:stoneCircleCenter
                                               radius:stoneCircleRadius];

  [CGDrawingHelper drawRadialGradientWithContext:context
                                      startColor:gradientStartColor
                                        endColor:gradientEndColor
                                     startCenter:startCenter
                                       endCenter:endCenter
                                       endRadius:stoneCircleRadius
                           endRadiusScaleFactorX:gradientEndRadiusScaleFactorX
                           endRadiusScaleFactorY:gradientEndRadiusScaleFactorY];

  [CGDrawingHelper removeClippingPathWithContext:context];
}

@end
