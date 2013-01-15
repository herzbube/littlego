// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "UIImageAdditions.h"
#import "../ui/UiUtilities.h"


@implementation UIImage(UIImageAdditions)

// -----------------------------------------------------------------------------
/// @brief Returns a new image that is based on @a image but has a
/// UIBarButtonItem styling (i.e. "embossed" look) applied to it.
///
/// The image returned can be used as the image for a custom UIButton. The image
/// returned is slightly larger than the original image.
///
/// The code for this method is based on
/// http://stackoverflow.com/questions/11083335/no-shadow-emboss-on-uibarbuttonitem
// -----------------------------------------------------------------------------
+ (UIImage*) imageByApplyingUIBarButtonItemStyling:(UIImage*)image
{
  CGFloat shadowOffset = 1;
  CGFloat shadowOpacity = .54;
  CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
  CGRect shadowRect = CGRectMake(0, shadowOffset, image.size.width, image.size.height);
  CGRect newImageRect = CGRectUnion(imageRect, shadowRect);

  BOOL opaque = NO;
  UIGraphicsBeginImageContextWithOptions(newImageRect.size, opaque, image.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextScaleCTM(context, 1, -1);
  CGContextTranslateCTM(context, 0, -(newImageRect.size.height));

  CGContextSaveGState(context);
  CGContextClipToMask(context, shadowRect, image.CGImage);
  CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0 alpha:shadowOpacity].CGColor);
  CGContextFillRect(context, shadowRect);
  CGContextRestoreGState(context);

  CGContextClipToMask(context, imageRect, image.CGImage);
  CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1 alpha:1].CGColor);
  CGContextFillRect(context, imageRect);

  UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns an image of size @a size with a linear gradient drawn along
/// the axis that runs from the top-middle to the bottom-middle point.
// -----------------------------------------------------------------------------
+ (UIImage*) gradientImageWithSize:(CGSize)size startColor:(UIColor*)startColor endColor:(UIColor*)endColor
{
  UIGraphicsBeginImageContext(size);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  [UiUtilities drawLinearGradientWithContext:context rect:rect startColor:startColor.CGColor endColor:endColor.CGColor];

  UIImage* gradientImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return gradientImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns an image of size @a size with a 3-color-stop linear gradient
/// drawn along the axis that runs from the top-middle to the bottom-middle
/// point.
// -----------------------------------------------------------------------------
+ (UIImage*) gradientImageWithSize:(CGSize)size startColor:(UIColor*)startColor middleColor:(UIColor*)middleColor endColor:(UIColor*)endColor
{
  UIGraphicsBeginImageContext(size);
  CGContextRef context = UIGraphicsGetCurrentContext();

  int topHalfRectHeight = size.height / 2;
  CGRect topHalfRect = CGRectMake(0, 0, size.width, topHalfRectHeight);
  [UiUtilities drawLinearGradientWithContext:context rect:topHalfRect startColor:startColor.CGColor endColor:middleColor.CGColor];
  CGRect bottomHalfRect = CGRectMake(0, topHalfRectHeight - 1, size.width, size.height - topHalfRectHeight + 1);
  [UiUtilities drawLinearGradientWithContext:context rect:bottomHalfRect startColor:middleColor.CGColor endColor:endColor.CGColor];

  UIImage* gradientImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return gradientImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns an image of size @a size with two linear gradients vertically
/// arrayed, each gradient taking up half of the height of @a size. Both
/// gradients are drawn along the axis that runs from the top-middle to the
/// bottom-middle point of @a rect.
// -----------------------------------------------------------------------------
+ (UIImage*) gradientImageWithSize:(CGSize)size startColor1:(UIColor*)startColor1 endColor1:(UIColor*)endColor1 startColor2:(UIColor*)startColor2 endColor2:(UIColor*)endColor2
{
  UIGraphicsBeginImageContext(size);
  CGContextRef context = UIGraphicsGetCurrentContext();

  int topHalfRectHeight = size.height / 2;
  CGRect topHalfRect = CGRectMake(0, 0, size.width, topHalfRectHeight);
  [UiUtilities drawLinearGradientWithContext:context rect:topHalfRect startColor:startColor1.CGColor endColor:endColor1.CGColor];
  CGRect bottomHalfRect = CGRectMake(0, topHalfRectHeight, size.width, size.height - topHalfRectHeight);
  [UiUtilities drawLinearGradientWithContext:context rect:bottomHalfRect startColor:startColor2.CGColor endColor:endColor2.CGColor];

  UIImage* gradientImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return gradientImage;
}

@end
