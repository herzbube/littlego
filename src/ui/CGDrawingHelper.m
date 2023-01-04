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
#import "CGDrawingHelper.h"
#import "UiUtilities.h"


@implementation CGDrawingHelper

// -----------------------------------------------------------------------------
/// @brief Draws a circle with center point @a center and radius @a radius.
/// The circle is either filled, or stroked, or both, or none.
///
/// If @a fillColor is not @e nil the circle is filled with @a fillColor.
///
/// If @a strokeColor is not @e nil the circle is stroked with
/// @a strokeColor, using the stroke line width @a strokeLineWidth.
///
/// If both @a fillColor and @a strokeColor are not @e nil then the circle
/// is both filled and stroked.
///
/// If both @a fillColor and @a strokeColor are @e nil then this function
/// only creates a path without adding any visuals. It is up to the caller to
/// do something with the path (e.g. clipping).
// -----------------------------------------------------------------------------
+ (void) drawCircleWithContext:(CGContextRef)context
                        center:(CGPoint)center
                        radius:(CGFloat)radius
                     fillColor:(UIColor*)fillColor
                   strokeColor:(UIColor*)strokeColor
               strokeLineWidth:(CGFloat)strokeLineWidth
{
  const CGFloat startRadius = [UiUtilities radians:0];
  const CGFloat endRadius = [UiUtilities radians:360];
  const int clockwise = 0;
  CGContextAddArc(context,
                  center.x,
                  center.y,
                  radius,
                  startRadius,
                  endRadius,
                  clockwise);

  [CGDrawingHelper fillOrStrokePathWithContext:context
                                     fillColor:fillColor
                                   strokeColor:strokeColor
                               strokeLineWidth:strokeLineWidth];
}

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
  [CGDrawingHelper fillAndStrokeColorsForStoneColor:stoneColor fillColor:&fillColor strokeColor:&strokeColor];

  [CGDrawingHelper drawCircleWithContext:context
                                  center:center
                                  radius:radius
                               fillColor:fillColor
                             strokeColor:strokeColor
                         strokeLineWidth:strokeLineWidth];
}

// -----------------------------------------------------------------------------
/// @brief Draws a rectangle with origin and size specified by @a rectangle.
/// The rectangle is either filled, or stroked, or both, or none.
///
/// If @a fillColor is not @e nil the rectangle is filled with @a fillColor.
///
/// If @a strokeColor is not @e nil the rectangle is stroked with
/// @a strokeColor, using the stroke line width @a strokeLineWidth.
///
/// If both @a fillColor and @a strokeColor are not @e nil then the rectangle
/// is both filled and stroked.
///
/// If both @a fillColor and @a strokeColor are @e nil then this function
/// only creates a path without adding any visuals. It is up to the caller to
/// do something with the path (e.g. clipping).
// -----------------------------------------------------------------------------
+ (void) drawRectangleWithContext:(CGContextRef)context
                        rectangle:(CGRect)rectangle
                        fillColor:(UIColor*)fillColor
                      strokeColor:(UIColor*)strokeColor
                  strokeLineWidth:(CGFloat)strokeLineWidth
{
  CGContextAddRect(context, rectangle);

  [CGDrawingHelper fillOrStrokePathWithContext:context
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
  [CGDrawingHelper fillAndStrokeColorsForStoneColor:stoneColor fillColor:&fillColor strokeColor:&strokeColor];

  [CGDrawingHelper drawRectangleWithContext:context
                                  rectangle:rectangle
                                  fillColor:fillColor
                                strokeColor:strokeColor
                            strokeLineWidth:strokeLineWidth];
}

// -----------------------------------------------------------------------------
/// @brief Draws a triangle that fits within a rectangle with origin and size
/// specified by @a rectangle. The triangle is either filled, or stroked,
/// or both, or none.
///
/// The following diagram illustrates how the triangle is drawn. The path
/// consists of three lines, the first going from A to B, the second going from
/// B to C, the third going from C to A.
/// @verbatim
/// Draw path from A => B => C
///     C
///     /\ <-----+
///    /  \      | rectangle.size.height
/// A /____\ B <-+
///   ^    ^
///   +----+
///   rectangle.size.width
/// @endverbatim
///
/// If @a fillColor is not @e nil the triangle is filled with @a fillColor.
///
/// If @a strokeColor is not @e nil the triangle is stroked with
/// @a strokeColor, using the stroke line width @a strokeLineWidth.
///
/// If both @a fillColor and @a strokeColor are not @e nil then the triangle
/// is both filled and stroked.
///
/// If both @a fillColor and @a strokeColor are @e nil then this function
/// only creates a path without adding any visuals. It is up to the caller to
/// do something with the path (e.g. clipping).
// -----------------------------------------------------------------------------
+ (void) drawTriangleWithContext:(CGContextRef)context
                 insideRectangle:(CGRect)rectangle
                       fillColor:(UIColor*)fillColor
                     strokeColor:(UIColor*)strokeColor
                 strokeLineWidth:(CGFloat)strokeLineWidth
{
  CGContextBeginPath(context);

  CGContextMoveToPoint(context, rectangle.origin.x, rectangle.origin.y + rectangle.size.height);
  CGContextAddLineToPoint(context, rectangle.origin.x + rectangle.size.width, rectangle.origin.y + rectangle.size.height);
  CGContextAddLineToPoint(context, rectangle.origin.x + floorf(rectangle.size.width / 2.0f), rectangle.origin.y);
  CGContextAddLineToPoint(context, rectangle.origin.x, rectangle.origin.y + rectangle.size.height);

  [CGDrawingHelper fillOrStrokePathWithContext:context
                                     fillColor:fillColor
                                   strokeColor:strokeColor
                               strokeLineWidth:strokeLineWidth];
}

// -----------------------------------------------------------------------------
/// @brief Draws an "X" symbol that fits within a rectangle with origin and size
/// specified by @a rectangle. The lines of the symbol are stroked with
/// @a strokeColor, using the stroke line width @a strokeLineWidth.
///
/// The following diagram illustrates how the "X" symbol is drawn. The path
/// consists of two lines, the first going from A to B, the second going from
/// C to D.
/// @verbatim
/// C o     o B  <-+
///    \   /       |
///     \ /        |
///      o         | rectangle.size.height
///     / \        |
///    /   \       |
/// A o     o D  <-+
///   ^     ^
///   +-----+
///   rectangle.size.width
/// @endverbatim
// -----------------------------------------------------------------------------
+ (void) drawSymbolXWithContext:(CGContextRef)context
                insideRectangle:(CGRect)rectangle
                    strokeColor:(UIColor*)strokeColor
                strokeLineWidth:(CGFloat)strokeLineWidth
{
  CGContextBeginPath(context);

  CGContextMoveToPoint(context, rectangle.origin.x, rectangle.origin.y + rectangle.size.height);
  CGContextAddLineToPoint(context, rectangle.origin.x + rectangle.size.width, rectangle.origin.y);

  CGContextMoveToPoint(context, rectangle.origin.x, rectangle.origin.y);
  CGContextAddLineToPoint(context, rectangle.origin.x + rectangle.size.width, rectangle.origin.y + rectangle.size.height);

  [CGDrawingHelper fillOrStrokePathWithContext:context
                                     fillColor:nil
                                   strokeColor:strokeColor
                               strokeLineWidth:strokeLineWidth];
}

// -----------------------------------------------------------------------------
/// @brief Draws an "X" symbol that fits within a square with center point
/// @a center and side length that is 2 * @a symbolSize. The lines of the symbol
/// are stroked with @a strokeColor, using the stroke line width
/// @a strokeLineWidth.
///
/// The following diagram illustrates how the "X" symbol is drawn. The path
/// consists of two lines, the first going from A to B, the second going from
/// C to D.
/// @verbatim
/// C o     o B
///    \   /
///     \ /
///      o <-- center
///     / \
///    /   \
/// A o     o D
///   ^     ^
///   +-----+
///    symbolSize * 2
/// @endverbatim
// -----------------------------------------------------------------------------
+ (void) drawSymbolXWithContext:(CGContextRef)context
                         center:(CGPoint)center
                     symbolSize:(CGFloat)symbolSize
                    strokeColor:(UIColor*)strokeColor
                strokeLineWidth:(CGFloat)strokeLineWidth
{
  CGContextBeginPath(context);

  CGContextMoveToPoint(context, center.x - symbolSize, center.y + symbolSize);
  CGContextAddLineToPoint(context, center.x + symbolSize, center.y - symbolSize);

  CGContextMoveToPoint(context, center.x - symbolSize, center.y - symbolSize);
  CGContextAddLineToPoint(context, center.x + symbolSize, center.y + symbolSize);

  [CGDrawingHelper fillOrStrokePathWithContext:context
                                     fillColor:nil
                                   strokeColor:strokeColor
                               strokeLineWidth:strokeLineWidth];
}

// -----------------------------------------------------------------------------
/// @brief Draws a checkmark symbol that fits within a rectangle with origin
/// and size specified by @a rectangle. The lines of the symbol are stroked with
/// @a strokeColor, using the stroke line width @a strokeLineWidth.
///
/// The following diagram illustrates how the checkmark symbol is drawn. The
/// path consists of two lines, the first going from A to B, the second going
/// from B to C.
/// @verbatim
///         C
///        /   <-+
///  A    / ^    | rectangle.size.height
///   \  /  |    |
///    \/   |  <-+
///     B   |
///  ^      |
///  +------+
///  rectangle.size.width
/// @endverbatim
// -----------------------------------------------------------------------------
+ (void) drawCheckmarkWithContext:(CGContextRef)context
                  insideRectangle:(CGRect)rectangle
                      strokeColor:(UIColor*)strokeColor
                  strokeLineWidth:(CGFloat)strokeLineWidth
{
  CGContextBeginPath(context);

  CGContextMoveToPoint(context, rectangle.origin.x, rectangle.origin.y + floorf(2.0f * rectangle.size.height / 3.0f));
  CGContextAddLineToPoint(context, rectangle.origin.x + floorf(rectangle.size.width / 3.0f), rectangle.origin.y + rectangle.size.height);
  CGContextAddLineToPoint(context, rectangle.origin.x + rectangle.size.width, rectangle.origin.y);

  [CGDrawingHelper fillOrStrokePathWithContext:context
                                     fillColor:nil
                                   strokeColor:strokeColor
                               strokeLineWidth:strokeLineWidth];
}


// -----------------------------------------------------------------------------
/// @brief Fills and/or strokes an existing path.
///
/// If @a fillColor is not @e nil the path is filled with @a fillColor.
///
/// If @a strokeColor is not @e nil the path is stroked with
/// @a strokeColor, using the stroke line width @a strokeLineWidth.
///
/// If both @a fillColor and @a strokeColor are not @e nil then the path
/// is both filled and stroked.
///
/// If both @a fillColor and @a strokeColor are @e nil then this function
/// does nothing.
// -----------------------------------------------------------------------------
+ (void) fillOrStrokePathWithContext:(CGContextRef)context
                           fillColor:(UIColor*)fillColor
                         strokeColor:(UIColor*)strokeColor
                     strokeLineWidth:(CGFloat)strokeLineWidth
{
  if (fillColor)
  {
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    if (! strokeColor)
    {
      CGContextFillPath(context);
      return;
    }
  }

  if (strokeColor)
  {
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetLineWidth(context, strokeLineWidth);
    if (! fillColor)
    {
      CGContextStrokePath(context);
      return;
    }
  }

  if (fillColor && strokeColor)
    CGContextDrawPath(context, kCGPathFillStroke);
}

// -----------------------------------------------------------------------------
/// @brief Fills the out parameters @a fillColor and @a strokeColor with
/// fill/and or stroke colors that can be used to draw a Go stone with color
/// @a stoneColor.
///
/// If @a stoneColor is #GoColorBlack then @a fillColor is set to black and
/// @a strokeColor is set to @e nil.
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
    *strokeColor = nil;
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

// -----------------------------------------------------------------------------
/// @brief Draws a bitmap image within the rectangle with origin and size
/// specified by @a rectangle. The bitmap image is resized so that it fits
/// within the rectangle. The image is a custom image located in a bundle
/// resource file or an asset catalog. The image name is @a imageName.
// -----------------------------------------------------------------------------
+ (void) drawImageWithContext:(CGContextRef)context
                       inRect:(CGRect)rectangle
                    imageName:(NSString*)imageName
{
  UIImage* image = [UIImage imageNamed:imageName];
  [CGDrawingHelper drawImageWithContext:context inRect:rectangle image:image];
}

// -----------------------------------------------------------------------------
/// @brief Draws a bitmap image within the rectangle with origin and size
/// specified by @a rectangle. The bitmap image is resized so that it fits
/// within the rectangle. The image is a system-defined symbol image. The image
/// name is @a imageName.
// -----------------------------------------------------------------------------
+ (void) drawSystemImageWithContext:(CGContextRef)context
                             inRect:(CGRect)rectangle
                          imageName:(NSString*)imageName
{
  UIImage* image = [UIImage systemImageNamed:imageName];
  [CGDrawingHelper drawImageWithContext:context inRect:rectangle image:image];
}

// -----------------------------------------------------------------------------
/// @brief Draws the bitmap image @a image within the rectangle with origin and
/// size specified by @a rectangle. The bitmap image is resized so that it fits
/// within the rectangle.
// -----------------------------------------------------------------------------
+ (void) drawImageWithContext:(CGContextRef)context
                       inRect:(CGRect)rectangle
                        image:(UIImage*)image
{
  // Let UIImage do all the drawing for us. This includes 1) compensating for
  // coordinate system differences (if we use CGContextDrawImage() the image
  // is drawn upside down); and 2) for scaling.
  UIGraphicsPushContext(context);
  [image drawInRect:rectangle];
  UIGraphicsPopContext();
}

// -----------------------------------------------------------------------------
/// @brief Draws the string @a string using the attributes @a textAttributes.
/// The string is drawn both horizontally and vertically centered within the
/// rectangle with origin and size specified by @a rectangle. The string is not
/// clipped to the bounds defined by @a rectangle.
// -----------------------------------------------------------------------------
+ (void) drawStringWithContext:(CGContextRef)context
                centeredInRect:(CGRect)rectangle
                        string:(NSString*)string
                textAttributes:(NSDictionary*)textAttributes
{
  CGRect boundingBox = CGRectZero;
  boundingBox.size = [string sizeWithAttributes:textAttributes];

  CGRect drawingRect = CGRectZero;
  // Use the bounding box size for drawing so that the string is not clipped
  drawingRect.size = boundingBox.size;
  // Set the drawing origin so that the text is centered both horizontally and
  // vertically. Horizontal centering could also be achieved via text attributes
  // (with a paragraph style that uses NSTextAlignmentCenter), but vertical
  // centering cannot.
  drawingRect.origin.x = CGRectGetMidX(rectangle) - CGRectGetMidX(boundingBox);
  drawingRect.origin.y = CGRectGetMidY(rectangle) - CGRectGetMidY(boundingBox);

  // NSString's drawInRect:withAttributes: is a UIKit drawing function. To make
  // it work we need to push the specified drawing context to the top of the
  // UIKit context stack (which is currently empty).
  UIGraphicsPushContext(context);
  [string drawInRect:drawingRect withAttributes:textAttributes];
  UIGraphicsPopContext();
}

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with a circular clipping
/// path with center point @a center and radius @a radius. Drawing takes place
/// only within the circular area defined by the clipping path. Invocation of
/// this method must be balanced by also invoking removeClippingPath:().
// -----------------------------------------------------------------------------
+ (void) setCircularClippingPathWithContext:(CGContextRef)context
                                     center:(CGPoint)center
                                     radius:(CGFloat)radius
{
  CGContextSaveGState(context);

  [CGDrawingHelper drawCircleWithContext:context
                                  center:center
                                  radius:radius
                               fillColor:nil
                             strokeColor:nil
                         strokeLineWidth:0.0f];
  CGContextClip(context);
}

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with two concentric
/// circles with the radii @a innerRadius and @a outerRadius, both of which
/// share the center point @a center. Drawing that takes place within the outer
/// circle's area is clipped so that nothing is drawn within the inner circle's
/// area. Invocation of this method must be balanced by also invoking
/// removeClippingPath:().
// -----------------------------------------------------------------------------
+ (void) setCircularClippingPathWithContext:(CGContextRef)context
                                     center:(CGPoint)center
                                innerRadius:(CGFloat)innerRadius
                                outerRadius:(CGFloat)outerRadius
{
  CGContextSaveGState(context);

  // To draw OUTSIDE of a given area, first set a path that defines the entire
  // drawing area, then set a second path that defines the area to exclude, then
  // set the clipping path using the even-odd (EO) rule. Solution found here:
  // https://www.kodeco.com/349664-core-graphics-tutorial-arcs-and-paths
  [CGDrawingHelper drawCircleWithContext:context
                                  center:center
                                  radius:outerRadius
                               fillColor:nil
                             strokeColor:nil
                         strokeLineWidth:0.0f];
  [CGDrawingHelper drawCircleWithContext:context
                                  center:center
                                  radius:innerRadius
                               fillColor:nil
                             strokeColor:nil
                         strokeLineWidth:0.0f];
  CGContextEOClip(context);
}

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with an inner circular area
/// with center point @a center and radius @a radius, and an outer rectangular
/// area with origin and size specified by @a outerRectangle. The inner circular
/// area is fully surrounded by the outer rectangular area. Drawing that takes
/// place within the outer rectangular area is clipped so that nothing is drawn
/// within the inner circular area. Invocation of this method must be balanced
/// by also invoking removeClippingPath:().
// -----------------------------------------------------------------------------
+ (void) setCircularClippingPathWithContext:(CGContextRef)context
                                     center:(CGPoint)center
                                     radius:(CGFloat)radius
                             outerRectangle:(CGRect)outerRectangle
{
  CGContextSaveGState(context);

  // To draw OUTSIDE of a given area, first set a path that defines the entire
  // drawing area, then set a second path that defines the area to exclude, then
  // set the clipping path using the even-odd (EO) rule. Solution found here:
  // https://www.kodeco.com/349664-core-graphics-tutorial-arcs-and-paths
  [CGDrawingHelper drawRectangleWithContext:context
                                  rectangle:outerRectangle
                                  fillColor:nil
                                strokeColor:nil
                            strokeLineWidth:0.0f];
  [CGDrawingHelper drawCircleWithContext:context
                                  center:center
                                  radius:radius
                               fillColor:nil
                             strokeColor:nil
                         strokeLineWidth:0.0f];
  CGContextEOClip(context);
}

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with a rectangular clipping
/// path with origin and size specified by @a rectangle. Drawing takes place
/// only within the rectangular area defined by the clipping path. Invocation
/// of this method must be balanced by also invoking removeClippingPath:().
// -----------------------------------------------------------------------------
+ (void) setRectangularClippingPathWithContext:(CGContextRef)context
                                     rectangle:(CGRect)rectangle
{
  CGContextSaveGState(context);

  [CGDrawingHelper drawRectangleWithContext:context
                                  rectangle:rectangle
                                  fillColor:nil
                                strokeColor:nil
                            strokeLineWidth:0.0f];
  CGContextClip(context);
}

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with an inner and an outer
/// rectangular area whose origins and sizes are specified by @a innerRectangle
/// and @a outerRectangle, respectively. The inner rectangular area is fully
/// surrounded by the outer rectangular area. Drawing that takes place within
/// the outer rectangular area is clipped so that nothing is drawn within the
/// area of the inner rectangular area. Invocation of this method must be
/// balanced by also invoking removeClippingPath:().
// -----------------------------------------------------------------------------
+ (void) setRectangularClippingPathWithContext:(CGContextRef)context
                                innerRectangle:(CGRect)innerRectangle
                                outerRectangle:(CGRect)outerRectangle
{
  CGContextSaveGState(context);

  // To draw OUTSIDE of a given area, first set a path that defines the entire
  // drawing area, then set a second path that defines the area to exclude, then
  // set the clipping path using the even-odd (EO) rule. Solution found here:
  // https://www.kodeco.com/349664-core-graphics-tutorial-arcs-and-paths
  [CGDrawingHelper drawRectangleWithContext:context
                                  rectangle:outerRectangle
                                  fillColor:nil
                                strokeColor:nil
                            strokeLineWidth:0.0f];
  [CGDrawingHelper drawRectangleWithContext:context
                                  rectangle:innerRectangle
                                  fillColor:nil
                                strokeColor:nil
                            strokeLineWidth:0.0f];
  CGContextEOClip(context);
}

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with an inner rectangular
/// area with origin and size specified by @a innerRectangle, and an outer
/// circular area with center point @a center and radius @a radius. The inner
/// rectangular area is fully surrounded by the outer circular area. Drawing
/// that takes place within the outer circular area is clipped so that nothing
/// is drawn within the inner rectangular area. Invocation of this method must
/// be balanced by also invoking removeClippingPath:().
// -----------------------------------------------------------------------------
+ (void) setRectangularClippingPathWithContext:(CGContextRef)context
                                innerRectangle:(CGRect)innerRectangle
                                        center:(CGPoint)center
                                        radius:(CGFloat)radius
{
  CGContextSaveGState(context);

  // To draw OUTSIDE of a given area, first set a path that defines the entire
  // drawing area, then set a second path that defines the area to exclude, then
  // set the clipping path using the even-odd (EO) rule. Solution found here:
  // https://www.kodeco.com/349664-core-graphics-tutorial-arcs-and-paths
  [CGDrawingHelper drawCircleWithContext:context
                                  center:center
                                  radius:radius
                               fillColor:nil
                             strokeColor:nil
                         strokeLineWidth:0.0f];
  [CGDrawingHelper drawRectangleWithContext:context
                                  rectangle:innerRectangle
                                  fillColor:nil
                                strokeColor:nil
                            strokeLineWidth:0.0f];
  CGContextEOClip(context);
}

// -----------------------------------------------------------------------------
/// @brief Removes a previously configured clipping path from the drawing
/// context @a context. Invocation of this method balances a previous invocation
/// of any of the set...ClippingPathWithContext:() methods.
// -----------------------------------------------------------------------------
+ (void) removeClippingPathWithContext:(CGContextRef)context
{
  // Clipping can only be removed by restoring a previously saved graphics
  // state
  CGContextRestoreGState(context);
}

@end
