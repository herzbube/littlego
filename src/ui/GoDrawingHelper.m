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

@end
