// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "UIColorAdditions.h"

// System includes
#import <UIKit/UIKit.h>


// -----------------------------------------------------------------------------
/// @brief The UIColorAdditionsPrivate category enhances UIColor by adding
/// private helper methods.
// -----------------------------------------------------------------------------
@interface UIColor(UIColorAdditionsPrivate)
- (CGFloat) rgbComponentAtIndex:(int)index;
@end


@implementation UIColor(UIColorAdditionsPrivate)

// -----------------------------------------------------------------------------
/// @brief Returns the color component of this UIColor at position @a index in
/// the device RGB colorspace (0=red, 1=green, 2=blue, 3=alpha).
///
/// Returns 0 if any error occurs (e.g. the colorspace of this UIColor is not
/// RGB).
// -----------------------------------------------------------------------------
- (CGFloat) rgbComponentAtIndex:(int)index
{
  CGColorRef color = self.CGColor;
  CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
  CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
  if (colorSpaceModel != kCGColorSpaceModelRGB)
    return 0;
  if (index < 0 || index > CGColorSpaceGetNumberOfComponents(colorSpace))
    return 0;
  const CGFloat* colorComponents = CGColorGetComponents(color);
  return colorComponents[index];
}

@end


@implementation UIColor(UIColorAdditions)

// -----------------------------------------------------------------------------
/// @brief Returns a human-readable string representation of @a color. For
/// instance "{0.7, 0.92, 0.3, 0.0}", the components being red, green, blue and
/// alpha.
// -----------------------------------------------------------------------------
+ (NSString*) stringFromUIColor:(UIColor*)color
{
  return [NSString stringWithFormat:@"{%0.5f, %0.5f, %0.5f, %0.5f}", 
                                    color.red, color.green, color.blue,
                                    color.alpha];
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a color that consists of the
/// hexadecimal components of the color (e.g. "0c88ff"). The alpha component
/// is ignored.
// -----------------------------------------------------------------------------
+ (NSString*) hexStringFromUIColor:(UIColor*)color
{
  int red = color.red * 255;
  if (red < 0)
    red = 0;
  if (red > 255)
    red = 255;
  int green = color.green * 255;
  if (green < 0)
    green = 0;
  if (green > 255)
    green = 255;
  int blue = color.blue * 255;
  if (blue < 0)
    blue = 0;
  if (blue > 255)
    blue = 255;
  return [NSString stringWithFormat:@"%02X%02X%02X", red, green, blue]; 
}

// -----------------------------------------------------------------------------
/// @brief Converts @a string, which must be a human-readable string
/// representation of a color (e.g. "{0.7, 0.92, 0.3, 0.0}"), into a UIColor
/// object.
///
/// Returns a black color object if any error occurs (e.g. the format of the
/// string representation is incorrect).
// -----------------------------------------------------------------------------
+ (UIColor*) colorFromString:(NSString*)string
{
  if (! [string hasPrefix:@"{"])
    return [UIColor blackColor];
  if (! [string hasSuffix:@"}"])
    return [UIColor blackColor];
  NSCharacterSet* charSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
  string = [string stringByTrimmingCharactersInSet:charSet];
  NSArray* components = [string componentsSeparatedByString:@", "];
  return [UIColor colorWithRed:[[components objectAtIndex:0] floatValue]
                         green:[[components objectAtIndex:1] floatValue]
                          blue:[[components objectAtIndex:2] floatValue]
                         alpha:[[components objectAtIndex:3] floatValue]];
}

// -----------------------------------------------------------------------------
/// @brief Converts @a hexString, which must be a string representation of a
/// color (e.g. "0c88ff"), into a UIColor object. The object has alpha 1.0.
///
/// Returns a black color object if any error occurs (e.g. the format of the
/// string representation is incorrect).
// -----------------------------------------------------------------------------
+ (UIColor*) colorFromHexString:(NSString*)hexString
{
  if ([hexString length] != 6)
    return [UIColor blackColor];

  NSRange range = NSMakeRange(0, 2);
  NSString* redString = [hexString substringWithRange:range];
  range = NSMakeRange(2, 2);
  NSString* greenString = [hexString substringWithRange:range];
  range = NSMakeRange(4, 2);
  NSString* blueString = [hexString substringWithRange:range];

  unsigned int red;
  [[NSScanner scannerWithString:redString] scanHexInt:&red];
  unsigned int green;
  [[NSScanner scannerWithString:greenString] scanHexInt:&green];
  unsigned int blue;
  [[NSScanner scannerWithString:blueString] scanHexInt:&blue];

  return [UIColor colorWithRed:red / 255.0
                         green:green / 255.0
                          blue:blue / 255.0
                         alpha:1.0]; 
}

// -----------------------------------------------------------------------------
/// @brief Returns the red component of this UIColor in the device RGB
/// colorspace.
// -----------------------------------------------------------------------------
- (CGFloat) red
{
  return [self rgbComponentAtIndex:0];
}

// -----------------------------------------------------------------------------
/// @brief Returns the green component of this UIColor in the device RGB
/// colorspace.
// -----------------------------------------------------------------------------
- (CGFloat) green
{
  return [self rgbComponentAtIndex:1];
}

// -----------------------------------------------------------------------------
/// @brief Returns the blue component of this UIColor in the device RGB
/// colorspace.
// -----------------------------------------------------------------------------
- (CGFloat) blue
{
  return [self rgbComponentAtIndex:2];
}

// -----------------------------------------------------------------------------
/// @brief Returns the alpha, or opacity, component of this UIColor in the
/// device RGB colorspace.
// -----------------------------------------------------------------------------
- (CGFloat) alpha
{
  return [self rgbComponentAtIndex:3];
}

// -----------------------------------------------------------------------------
/// @brief Returns a color object whose RGB values are 0.22, 0.33, and 0.53 and
/// whose alpha value is 1.0.
///
/// This is the color that Apple uses in their UIs for displaying editable text
/// and selected values.
// -----------------------------------------------------------------------------
+ (UIColor*) slateBlueColor
{
  return [UIColor colorWithRed:0.22f green:0.33f blue:0.53f alpha:1.0f];
}

// -----------------------------------------------------------------------------
/// @brief Returns a color object whose RGB values are randomly chosen and
/// whose alpha value is 1.0.
// -----------------------------------------------------------------------------
+ (UIColor*) randomColor
{
  CGFloat red = (CGFloat)random() / (CGFloat)RAND_MAX;
  CGFloat blue = (CGFloat)random() / (CGFloat)RAND_MAX;
  CGFloat green = (CGFloat)random() / (CGFloat)RAND_MAX;
  return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

// -----------------------------------------------------------------------------
/// @brief Returns a color object whose RGB values are 226/229/234 and whose
/// alpha value is 1.0.
///
/// On the iPad, group table views have a background view that employs a
/// linear gradient. The color returned by this method is the gradient's start
/// color. See this stackoverflow.com question for information about how the
/// color can be experimentally determined:
/// http://stackoverflow.com/questions/5736515/ipad-grouped-tableview-background-color-what-is-it/
// -----------------------------------------------------------------------------
+ (UIColor*) iPadGroupTableViewBackgroundGradientStartColor
{
  return [UIColor colorWithRed:226.0/255.0 green:229.0/255.0 blue:234.0/255.0 alpha:1.0];
}

// -----------------------------------------------------------------------------
/// @brief Returns a color object whose RGB values are 208/210/216 and whose
/// alpha value is 1.0.
///
/// This is the gradient end color, as described in this method's documentation:
/// iPadGroupTableViewBackgroundGradientStartColor().
// -----------------------------------------------------------------------------
+ (UIColor*) iPadGroupTableViewBackgroundGradientEndColor
{
  return [UIColor colorWithRed:208.0/255.0 green:210.0/255.0 blue:216.0/255.0 alpha:1.0];
}

// -----------------------------------------------------------------------------
/// @brief Returns 4 color objects that can be used to create a background view
/// image that will look like the red delete button in Apple's address book.
///
/// The 4 color objects are intended to be used to form 2 linear gradients
/// that are then vertically arrayed.
///
/// The colors have been experimentally determined from an iPhone screenshot.
///
/// The color objects have the following RGB values (all use alpha 1.0):
/// - 230/192/193
/// - 181/36/37
/// - 170/2/3
/// - 189/58/59
// -----------------------------------------------------------------------------
+ (NSArray*) redButtonTableViewCellBackgroundGradientColors
{
  UIColor* startColor1 = [UIColor colorWithRed:230.0/255.0 green:192.0/255.0 blue:193.0/255.0 alpha:1.0];
  UIColor* endColor1 = [UIColor colorWithRed:181.0/255.0 green:36.0/255.0 blue:37.0/255.0 alpha:1.0];
  UIColor* startColor2 = [UIColor colorWithRed:170.0/255.0 green:2.0/255.0 blue:3.0/255.0 alpha:1.0];
  UIColor* endColor2 = [UIColor colorWithRed:189.0/255.0 green:58.0/255.0 blue:59.0/255.0 alpha:1.0];
  return [NSArray arrayWithObjects:startColor1, endColor1, startColor2, endColor2, nil];
}

// -----------------------------------------------------------------------------
/// @brief Returns 4 color objects that can be used to create a background view
/// image that will look like the red delete button in Apple's address book, in
/// selected state.
///
/// The colors have been determined by reducing the brightness of the colors
/// specified by redButtonTableViewCellBackgroundGradientColors() by 45.
///
/// The color objects have the following RGB values (all use alpha 1.0):
/// - 189/158/159
/// - 149/30/30
/// - 140/2/3
/// - 155/48/49
// -----------------------------------------------------------------------------
+ (NSArray*) redButtonTableViewCellSelectedBackgroundGradientColors
{
  // Abgedunkelt -45
  UIColor* startColor1 = [UIColor colorWithRed:189.0/255.0 green:158.0/255.0 blue:159.0/255.0 alpha:1.0];
  UIColor* endColor1 = [UIColor colorWithRed:149.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1.0];
  UIColor* startColor2 = [UIColor colorWithRed:140.0/255.0 green:2.0/255.0 blue:2.0/255.0 alpha:1.0];
  UIColor* endColor2 = [UIColor colorWithRed:155.0/255.0 green:48.0/255.0 blue:49.0/255.0 alpha:1.0];
  return [NSArray arrayWithObjects:startColor1, endColor1, startColor2, endColor2, nil];
}

@end
