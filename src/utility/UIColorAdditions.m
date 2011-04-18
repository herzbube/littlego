// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
  return [NSString stringWithFormat:@"{0.5f, %0.5f, %0.5f, %0.5f}", 
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
  
@end
