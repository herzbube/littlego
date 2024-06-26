// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@protocol Tile;


// -----------------------------------------------------------------------------
/// @brief The CGDrawingHelper class provides generic helper functions for
/// drawing UI elements with Core Graphics.
///
/// There is no need to create an instance of CGDrawingHelper because
/// the class contains only functions and class methods.
// -----------------------------------------------------------------------------
@interface CGDrawingHelper : NSObject
{
}

/// @name Drawing shapes
//@{
+ (void) drawCircleWithContext:(CGContextRef)context
                        center:(CGPoint)center
                        radius:(CGFloat)radius
                     fillColor:(UIColor*)fillColor
                   strokeColor:(UIColor*)strokeColor
               strokeLineWidth:(CGFloat)strokeLineWidth;

+ (void) drawRectangleWithContext:(CGContextRef)context
                        rectangle:(CGRect)rectangle
                        fillColor:(UIColor*)fillColor
                      strokeColor:(UIColor*)strokeColor
                  strokeLineWidth:(CGFloat)strokeLineWidth;

+ (void) drawRoundedRectangleWithContext:(CGContextRef)context
                               rectangle:(CGRect)rectangle
                            cornerRadius:(CGSize)cornerRadius
                               fillColor:(UIColor*)fillColor
                             strokeColor:(UIColor*)strokeColor
                         strokeLineWidth:(CGFloat)strokeLineWidth;

+ (void) drawTriangleWithContext:(CGContextRef)context
                 insideRectangle:(CGRect)rectangle
                       fillColor:(UIColor*)fillColor
                     strokeColor:(UIColor*)strokeColor
                 strokeLineWidth:(CGFloat)strokeLineWidth;

+ (void) drawSymbolXWithContext:(CGContextRef)context
                insideRectangle:(CGRect)rectangle
                    strokeColor:(UIColor*)strokeColor
                strokeLineWidth:(CGFloat)strokeLineWidth;

+ (void) drawSymbolXWithContext:(CGContextRef)context
                         center:(CGPoint)center
                     symbolSize:(CGFloat)symbolSize
                    strokeColor:(UIColor*)strokeColor
                strokeLineWidth:(CGFloat)strokeLineWidth;

+ (void) drawCheckmarkWithContext:(CGContextRef)context
                  insideRectangle:(CGRect)rectangle
                      strokeColor:(UIColor*)strokeColor
                  strokeLineWidth:(CGFloat)strokeLineWidth;

+ (void) drawLineWithContext:(CGContextRef)context
                   fromPoint:(CGPoint)startPoint
                     toPoint:(CGPoint)endPoint
                 strokeColor:(UIColor*)strokeColor
             strokeLineWidth:(CGFloat)strokeLineWidth;
//@}

/// @name Filling and stroking
//@{
+ (void) fillOrStrokePathWithContext:(CGContextRef)context
                           fillColor:(UIColor*)fillColor
                         strokeColor:(UIColor*)strokeColor
                     strokeLineWidth:(CGFloat)strokeLineWidth;
//@}

/// @name Drawing images
//@{
+ (void) drawImageWithContext:(CGContextRef)context
                       inRect:(CGRect)rectangle
                    imageName:(NSString*)imageName;

+ (void) drawSystemImageWithContext:(CGContextRef)context
                             inRect:(CGRect)rectangle
                          imageName:(NSString*)imageName API_AVAILABLE(ios(13.0));

+ (void) drawImageWithContext:(CGContextRef)context
                       inRect:(CGRect)rectangle
                        image:(UIImage*)image;
//@}

/// @name Drawing strings
//@{
+ (void) drawStringWithContext:(CGContextRef)context
                centeredInRect:(CGRect)rectangle
                        string:(NSString*)string
                textAttributes:(NSDictionary*)textAttributes;

+ (void) drawStringWithContext:(CGContextRef)context
                centeredInRect:(CGRect)rectangle
           rotatedCcwByDegrees:(CGFloat)degrees
                        string:(NSString*)string
                textAttributes:(NSDictionary*)textAttributes;
//@}

/// @name Drawing gradients
//@{
+ (void) drawRadialGradientWithContext:(CGContextRef)context
                            startColor:(UIColor*)startColor
                              endColor:(UIColor*)endColor
                           startCenter:(CGPoint)startCenter
                             endCenter:(CGPoint)endCenter
                             endRadius:(CGFloat)endRadius
                 endRadiusScaleFactorX:(CGFloat)endRadiusScaleFactorX
                 endRadiusScaleFactorY:(CGFloat)endRadiusScaleFactorY;

+ (void) drawRadialGradientWithContext:(CGContextRef)context
                            startColor:(UIColor*)startColor
                              endColor:(UIColor*)endColor
                           startCenter:(CGPoint)startCenter
                           startRadius:(CGFloat)startRadius
                             endCenter:(CGPoint)endCenter
                             endRadius:(CGFloat)endRadius;
//@}

/// @name Setting and removing clipping paths
//@{
+ (void) setCircularClippingPathWithContext:(CGContextRef)context
                                     center:(CGPoint)center
                                     radius:(CGFloat)radius;

+ (void) setCircularClippingPathWithContext:(CGContextRef)context
                                     center:(CGPoint)center
                                innerRadius:(CGFloat)innerRadius
                                outerRadius:(CGFloat)outerRadius;

+ (void) setCircularClippingPathWithContext:(CGContextRef)context
                                     center:(CGPoint)center
                                     radius:(CGFloat)innerRadius
                             outerRectangle:(CGRect)outerRectangle;

+ (void) setRectangularClippingPathWithContext:(CGContextRef)context
                                     rectangle:(CGRect)rectangle;

+ (void) setRectangularClippingPathWithContext:(CGContextRef)context
                                innerRectangle:(CGRect)innerRectangle
                                outerRectangle:(CGRect)outerRectangle;

+ (void) setRectangularClippingPathWithContext:(CGContextRef)context
                                innerRectangle:(CGRect)innerRectangle
                                        center:(CGPoint)center
                                        radius:(CGFloat)radius;

+ (void) removeClippingPathWithContext:(CGContextRef)context;
//@}

/// @name Calculating points, sizes and rectangles
//@{
+ (CGRect) canvasRectForTile:(id<Tile>)tile
                    withSize:(CGSize)tileSize;

+ (CGRect) drawingRectForScaledLayer:(CGLayerRef)layer
                   withContentsScale:(CGFloat)contentsScale;

+ (CGRect) drawingRectFromCanvasRect:(CGRect)canvasRect
                      inTileWithRect:(CGRect)tileRect;
//@}

@end
