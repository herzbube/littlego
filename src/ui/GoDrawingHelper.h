// -----------------------------------------------------------------------------
// Copyright 2023-2024 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The GoDrawingHelper class provides helper functions for drawing
/// Go-specific UI elements with Core Graphics.
///
/// There is no need to create an instance of GoDrawingHelper because
/// the class contains only functions and class methods.
// -----------------------------------------------------------------------------
@interface GoDrawingHelper : NSObject
{
}

/// @name Drawing shapes
//@{
+ (void) drawStoneCircleWithContext:(CGContextRef)context
                             center:(CGPoint)center
                             radius:(CGFloat)radius
                         stoneColor:(enum GoColor)stoneColor
                    strokeLineWidth:(CGFloat)strokeLineWidth;

+ (void) draw3dStoneWithContext:(CGContextRef)context
              boundingRectangle:(CGRect)boundingRectangle
                     stoneColor:(enum GoColor)stoneColor
               isCrossHairStone:(bool)isCrossHairStone;

+ (void) drawStoneRectangleWithContext:(CGContextRef)context
                             rectangle:(CGRect)rectangle
                            stoneColor:(enum GoColor)stoneColor
                       strokeLineWidth:(CGFloat)strokeLineWidth;
//@}

/// @name Filling and stroking
//@{
+ (void) fillAndStrokeColorsForStoneColor:(enum GoColor)stoneColor
                                fillColor:(UIColor**)fillColor
                              strokeColor:(UIColor**)strokeColor;
//@}

@end
