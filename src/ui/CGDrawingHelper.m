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
#import "CGDrawingHelper.h"
#import "Tile.h"
#import "UiUtilities.h"


@implementation CGDrawingHelper

#pragma mark - Drawing shapes

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
/// @brief Draws a rectangle with rounded corners with origin and size specified
/// by @a rectangle. @a cornerRadius specifies the width and height of the
/// rounded corner sections. The rectangle is either filled, or stroked, or
/// both, or none.
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
+ (void) drawRoundedRectangleWithContext:(CGContextRef)context
                               rectangle:(CGRect)rectangle
                            cornerRadius:(CGSize)cornerRadius
                               fillColor:(UIColor*)fillColor
                             strokeColor:(UIColor*)strokeColor
                         strokeLineWidth:(CGFloat)strokeLineWidth
{
  CGPathRef roundedRectanglePath = CGPathCreateWithRoundedRect(rectangle,
                                                               cornerRadius.width,
                                                               cornerRadius.height,
                                                               NULL);
  CGContextAddPath(context, roundedRectanglePath);

  [CGDrawingHelper fillOrStrokePathWithContext:context
                                     fillColor:fillColor
                                   strokeColor:strokeColor
                               strokeLineWidth:strokeLineWidth];

  CGPathRelease(roundedRectanglePath);
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
/// @brief Draws a line between the two points @a startPoint and @e endPoint.
/// The line is stroked with @a strokeColor, using the stroke line width
/// @a strokeLineWidth.
// -----------------------------------------------------------------------------
+ (void) drawLineWithContext:(CGContextRef)context
                   fromPoint:(CGPoint)startPoint
                     toPoint:(CGPoint)endPoint
                 strokeColor:(UIColor*)strokeColor
             strokeLineWidth:(CGFloat)strokeLineWidth
{
  CGContextBeginPath(context);

  CGContextMoveToPoint(context, startPoint.x, startPoint.y);
  CGContextAddLineToPoint(context, endPoint.x, endPoint.y);

  [CGDrawingHelper fillOrStrokePathWithContext:context
                                     fillColor:nil
                                   strokeColor:strokeColor
                               strokeLineWidth:strokeLineWidth];
}

#pragma mark - Filling and stroking

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

#pragma mark - Drawing images

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

#pragma mark - Drawing strings

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
  return [CGDrawingHelper drawStringWithContext:context
                                 centeredInRect:rectangle
                            rotatedCcwByDegrees:0.0f
                                         string:string
                                 textAttributes:textAttributes];
}

// -----------------------------------------------------------------------------
/// @brief Draws the string @a string using the attributes @a textAttributes.
/// The string is drawn both horizontally and vertically centered within the
/// rectangle with origin and size specified by @a rectangle. The string is
/// rotated counter-clockwise by @a degrees, with the rotation center being the
/// center of @a rectangle, which is the same as the center of the rendered text
/// itself. The string is not clipped to the bounds defined by @a rectangle.
// -----------------------------------------------------------------------------
+ (void) drawStringWithContext:(CGContextRef)context
                centeredInRect:(CGRect)rectangle
           rotatedCcwByDegrees:(CGFloat)degrees
                        string:(NSString*)string
                textAttributes:(NSDictionary*)textAttributes
{
  CGRect boundingBox = CGRectZero;
  boundingBox.size = [string sizeWithAttributes:textAttributes];

  CGPoint centerOfRectangle = CGPointMake(CGRectGetMidX(rectangle), CGRectGetMidY(rectangle));
  CGPoint centerOfBoundingBox = CGPointMake(CGRectGetMidX(boundingBox), CGRectGetMidY(boundingBox));

  CGRect drawingRect = CGRectZero;
  // Use the bounding box size for drawing so that the string is not clipped
  drawingRect.size = boundingBox.size;
  // Set the drawing origin so that the text is centered both horizontally and
  // vertically. Horizontal centering could also be achieved via text attributes
  // (with a paragraph style that uses NSTextAlignmentCenter), but vertical
  // centering cannot.
  drawingRect.origin.x = centerOfRectangle.x - centerOfBoundingBox.x;
  drawingRect.origin.y = centerOfRectangle.y - centerOfBoundingBox.y;

  bool shouldRotate = degrees != 0.0f;
  if (shouldRotate)
  {
    CGFloat angle = [UiUtilities radians:360 - degrees];
    CGPoint rotationCenter = centerOfRectangle;

    CGContextSaveGState(context);

    // Shift the CTM to make the rotation center the origin
    CGContextTranslateCTM(context, rotationCenter.x, rotationCenter.y);
    CGContextRotateCTM(context, angle);
    // Undo the shift
    CGContextTranslateCTM(context, -rotationCenter.x, -rotationCenter.y);
  }

  // NSString's drawInRect:withAttributes: is a UIKit drawing function. To make
  // it work we need to push the specified drawing context to the top of the
  // UIKit context stack (which is currently empty).
  UIGraphicsPushContext(context);
  [string drawInRect:drawingRect withAttributes:textAttributes];
  UIGraphicsPopContext();

  if (shouldRotate)
    CGContextRestoreGState(context);
}

#pragma mark - Drawing gradients

// -----------------------------------------------------------------------------
/// @brief Draws a radial gradient with only two colors, @a startColor and
/// @a endColor, which are set at the gradient stops 0.0 and 1.0, respectively.
/// The gradient start circle (aka focal circle) is defined by @a startCenter
/// and a radius of length zero. The gradient end circle, which effectively is
/// an ellipse, is defined by @a endCenter and a base radius @a @a endRadius,
/// which is then scaled in x- and y-direction by @a endRadiusScaleFactorX and
/// @a endRadiusScaleFactorY, respectively, to give the end circle its
/// elliptical form.
///
/// This method imitates the Inkscape user interface which allows the user to
/// give the end circle an elliptical form by defining different lengths for the
/// end circle radius in x- and y-direction. How is it possible to have two
/// radius values, given that in the underlying SVG source, the end circle can
/// have only one radius value (SVG attribute @e r)? Inkscape solves this by
/// setting the SVG attribute @e gradientTransform with an affine transform that
/// has scaling factors in x- and y-direction, resulting in the end circle
/// radius (SVG attribute @e r) to have different values in the two directions.
/// But Inkscape then also adds translation to the affine transform to reverse
/// the effect that the scaling has on the location of the start/end circle
/// centers. Because the radius of the start (= focal) circle is always zero, it
/// is unaffected by the scaling.
///
/// To achieve its task, this method duplicates Inkscape's behaviour: It
/// temporarily applies the affine transform describe above to the CTM of
/// @a context, draws the gradient, and then restores the original CTM of
/// @a context.
///
/// @see drawRadialGradientWithContext:startColor:endColor:startCenter:startRadius:endCenter:endRadius:()
/// for details how to match method parameters to the SVG model for drawing
/// radial gradients:
// -----------------------------------------------------------------------------
+ (void) drawRadialGradientWithContext:(CGContextRef)context
                            startColor:(UIColor*)startColor
                              endColor:(UIColor*)endColor
                           startCenter:(CGPoint)startCenter
                             endCenter:(CGPoint)endCenter
                             endRadius:(CGFloat)endRadius
                 endRadiusScaleFactorX:(CGFloat)endRadiusScaleFactorX
                 endRadiusScaleFactorY:(CGFloat)endRadiusScaleFactorY
{
  CGFloat a = endRadiusScaleFactorX;
  CGFloat b = 0.0;
  CGFloat c = 0.0;
  CGFloat d = endRadiusScaleFactorY;
  // Translation is used to move the start/end centers back to their original
  // position
  CGFloat tx = endRadius - endRadius * endRadiusScaleFactorX;
  CGFloat ty = endRadius - endRadius * endRadiusScaleFactorY;
  CGAffineTransform affineTransform = CGAffineTransformMake(a, b, c, d, tx, ty);

  CGPoint startCenterBeforeTransform = CGPointMake((startCenter.x - tx) / a,
                                                   (startCenter.y - ty) / d);
  CGPoint endCenterBeforeTransform = CGPointMake((endCenter.x - tx) / a,
                                                 (endCenter.y - ty) / d);

  CGContextSaveGState(context);

  CGContextConcatCTM(context, affineTransform);

  [CGDrawingHelper drawRadialGradientWithContext:context
                                      startColor:startColor
                                        endColor:endColor
                                     startCenter:startCenterBeforeTransform
                                     startRadius:0.0f
                                       endCenter:endCenterBeforeTransform
                                       endRadius:endRadius];
  // Remove transform
  CGContextRestoreGState(context);
}

// -----------------------------------------------------------------------------
/// @brief Draws a radial gradient with only two colors, @a startColor and
/// @a endColor, which are set at the gradient stops 0.0 and 1.0, respectively.
/// The gradient start circle (aka focal circle) is defined by @a startCenter
/// and @a startRadius, and the gradient end circle is defined by @a endCenter.
///
/// The parameters of this method can be matched as follows to the SVG model
/// for drawing radial gradients:
/// - @a startCenter corresponds to the SVG attributes @e fx and @e fy
///   (prefix "f" referring to the term "focal").
/// - @a startRadius corresponds to the SVG attribute @e fr.
/// - @a endCenter corresponds to the SVG attributes @e cx and @e cy.
/// - @a endRadius corresponds to the SVG attribute @e r.
///
/// The SVG attribute @e gradientTransform, is not a parameter of this method
/// by design. If an affine transform is desired, it must be applied to
/// @a context prior to invoking this method.
///
/// The following SVG attributes are not part of this API because they don't
/// make sense for the CoreGraphics drawing model:
/// - @e gradientUnits
/// - @e spreadMethod
///
/// @see https://svgwg.org/svg2-draft/pservers.html#RadialGradients
// -----------------------------------------------------------------------------
+ (void) drawRadialGradientWithContext:(CGContextRef)context
                            startColor:(UIColor*)startColor
                              endColor:(UIColor*)endColor
                           startCenter:(CGPoint)startCenter
                           startRadius:(CGFloat)startRadius
                             endCenter:(CGPoint)endCenter
                             endRadius:(CGFloat)endRadius
{
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  NSArray* colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
  CGFloat locations[] = { 0.0, 1.0 };

  // NSArray is toll-free bridged, so we can simply cast to CGArrayRef
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                      (CFArrayRef)colors,
                                                      locations);

  CGContextDrawRadialGradient(context,
                              gradient,
                              startCenter,
                              startRadius,
                              endCenter,
                              endRadius,
                              0);

  CGGradientRelease(gradient);
  CGColorSpaceRelease(colorSpace);
}

#pragma mark - Setting and removing clipping paths

// -----------------------------------------------------------------------------
/// @brief Configures the drawing context @a context with a circular clipping
/// path with center point @a center and radius @a radius. Drawing takes place
/// only within the circular area defined by the clipping path. Invocation of
/// this method must be balanced by also invoking
/// removeClippingPathWithContext:().
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
/// removeClippingPathWithContext:().
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
/// by also invoking removeClippingPathWithContext:().
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
/// of this method must be balanced by also invoking
/// removeClippingPathWithContext:().
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
/// balanced by also invoking removeClippingPathWithContext:().
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
/// be balanced by also invoking removeClippingPathWithContext:().
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

#pragma mark - Calculating points, sizes and rectangles

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle occupied by @a tile on the "canvas", i.e. the
/// entire drawing area covered by a tiled view. The origin is in the upper-left
/// corner. The tile with row/column = 0/0 is assumed to contain the origin.
// -----------------------------------------------------------------------------
+ (CGRect) canvasRectForTile:(id<Tile>)tile
                    withSize:(CGSize)tileSize
{
  CGRect canvasRect = CGRectZero;
  canvasRect.size = tileSize;
  canvasRect.origin.x = tile.column * tileSize.width;
  canvasRect.origin.y = tile.row * tileSize.height;
  return canvasRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle that must be passed to CGContextDrawLayerInRect
/// for drawing the specified layer, which must have a size that is scaled up
/// using @a contentScale.
// -----------------------------------------------------------------------------
+ (CGRect) drawingRectForScaledLayer:(CGLayerRef)layer
                   withContentsScale:(CGFloat)contentsScale
{
  CGSize drawingSize = CGLayerGetSize(layer);
  drawingSize.width /= contentsScale;
  drawingSize.height /= contentsScale;

  CGRect drawingRect;
  drawingRect.origin = CGPointZero;
  drawingRect.size = drawingSize;

  return drawingRect;
}

// -----------------------------------------------------------------------------
/// @brief Translates the origin of @a canvasRect (a rectangle on the "canvas",
/// i.e. the entire drawing area covered by a tiled view) into the coordinate
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
