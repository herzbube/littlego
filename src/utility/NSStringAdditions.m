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
#import "NSStringAdditions.h"


@implementation NSString(NSStringAdditions)

// -----------------------------------------------------------------------------
/// @brief Returns a string UUID. Example: C42B7FB8-F5DC-4D07-877E-AA583EFECF80.
///
/// The code for this method was copied more or less verbatim from
/// http://www.cocoabuilder.com/archive/cocoa/217665-how-to-create-guid.html
// -----------------------------------------------------------------------------
+ (NSString*) UUIDString
{
  CFUUIDRef UUIDRef = CFUUIDCreate(NULL);
  NSString* uuidString = (NSString*)CFUUIDCreateString(NULL, UUIDRef);
  CFRelease(UUIDRef);
  return [uuidString autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Returns an image whose sole content is a rendered version of the
/// receiver.
///
/// If @a font is nil the font used for rendering is
/// [UIFont systemFontOfSize:[UIFont labelFontSize]].
///
/// If @a drawShadow is true the rendered text floats on a light gray shadow.
/// The image size increases slightly when a shadow is used.
///
/// The code for this method is based on
/// http://stackoverflow.com/questions/2765537/how-do-i-use-the-nsstring-draw-functionality-to-create-a-uiimage-from-text
// -----------------------------------------------------------------------------
- (UIImage*) imageWithFont:(UIFont*)font drawShadow:(bool)drawShadow
{
  if (! nil)
    font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  CGSize size = [self sizeWithFont:font];
  const CGSize shadowOffset = CGSizeMake(1, 1);
  // Increase the context size to avoid clipping the shadow
  if (drawShadow)
  {
    size.width += shadowOffset.width;
    size.height += shadowOffset.height;
  }

  UIGraphicsBeginImageContextWithOptions(size, NO, 0);
  if (drawShadow)
  {
    CGContextRef context = UIGraphicsGetCurrentContext();
    const CGFloat shadowBlur = 5.0;
    UIColor* shadowColor = [UIColor grayColor];
    // From now on, all objects drawn subsequently will be shadowed
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlur, shadowColor.CGColor);
  }

  [self drawAtPoint:CGPointMake(0, 0) withFont:font];
  UIImage* outputImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return outputImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns a nicely formatted string for the komi value @a komi.
///
/// The fractional part of @a komi is expected to be either 0.0, or 0.5.
///
/// Generally, if the fractional part is 0.0, the string representation returned
/// by this method omits the fraction. If the fractional part is 0.5, it is
/// represented using the unicode character for "one half".
///
/// Examples: A komi value of 6.5 results in the string representation "6½".
/// A komi value of 6.0 results in "6".
///
/// Special cases are komi values where the integral part is 0: A komi value 0.0
/// is represented as "No komi", while the value 0.5 is represented as "½"
/// (the integral part 0 is omitted).
// -----------------------------------------------------------------------------
+ (NSString*) stringWithKomi:(double)komi
{
  if (0.0 == komi)
    return @"No komi";
  else if (0.5 == komi)
    return @"½";

  double komiIntegerPart;
  double komiFractionalPart = modf(komi, &komiIntegerPart);
  if (0.0 == komiFractionalPart)
    return [NSString stringWithFormat:@"%.0f", komiIntegerPart];
  else if (0.5 == komiFractionalPart)
    return [NSString stringWithFormat:@"%.0f½", komiIntegerPart];
  else
    return [NSString stringWithFormat:@"%f", komi];  // got an unexpected fraction
}

@end
