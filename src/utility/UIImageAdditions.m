// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Returns a new image by resizing the current image to @a newSize.
// -----------------------------------------------------------------------------
- (UIImage*) imageByResizingToSize:(CGSize)newSize
{
  UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
  CGRect resizedImageRect = CGRectMake(0, 0, newSize.width, newSize.height);
  [self drawInRect:resizedImageRect];
  UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return resizedImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns an image of size @a size with a linear gradient drawn along
/// the axis that runs from the top-middle to the bottom-middle point.
// -----------------------------------------------------------------------------
+ (UIImage*) gradientImageWithSize:(CGSize)size startColor:(UIColor*)startColor endColor:(UIColor*)endColor
{
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
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
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
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
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
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

// -----------------------------------------------------------------------------
/// @brief Returns an image of size @a size which has @a originalImage at its
/// center. The original image is expected to have a smaller size than @a size.
/// The effect is that the original image is padded by a certain amount of
/// pixels on all 4 sides. The amount of padding depends on the difference in
/// size of the original and the new image.
///
/// One application of this method is to create uniformly sized images from a
/// number of differently sized original images.
// -----------------------------------------------------------------------------
+ (UIImage*) paddedImageWithSize:(CGSize)size originalImage:(UIImage*)originalImage
{
  CGSize originalImageSize = originalImage.size;
  CGFloat leftEdgePadding = (size.width - originalImageSize.width) / 2.0f;
  CGFloat topEdgePadding = (size.height - originalImageSize.height) / 2.0f;
  CGRect drawingRect = CGRectMake(leftEdgePadding, topEdgePadding, originalImageSize.width, originalImageSize.height);

  BOOL opaque = NO;
  CGFloat scale = 0.0f;
  UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
  [originalImage drawInRect:drawingRect];

  UIImage* paddedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return paddedImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns an image of size @a size which consists of repetitions of
/// the tile image @a tile. If @a size is smaller than the dimensions of
/// @a tile, only the upper-left part of @a tile is used.
///
/// The tile image @a tile must already be suitable for tiling.
// -----------------------------------------------------------------------------
+ (UIImage*) tiledImageWithSize:(CGSize)size fromTile:(UIImage*)tile
{
  BOOL opaque = NO;
  CGFloat scale = 0.0f;
  UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGRect drawingRect = CGRectMake(0, 0, size.width, size.height);
  CGContextClipToRect(context, drawingRect);
  CGRect tileRect = CGRectMake(0, 0, tile.size.width, tile.size.height);
  CGContextDrawTiledImage(context, tileRect, tile.CGImage);

  UIImage* tiledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return tiledImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns an image object that can be used to display a wooden
/// background. The image is suitable for tiling.
// -----------------------------------------------------------------------------
+ (UIImage*) woodenBackgroundTileImage
{
  // The background image is quite large, so we don't use UIImage namedImage:()
  // because that method caches the image in the background. We don't need
  // caching because we only load the image once, so not using namedImage:()
  // saves us quite a bit of valuable memory.
  NSString* imagePath = [[NSBundle mainBundle] pathForResource:woodenBackgroundImageResource
                                                        ofType:nil];
  NSData* imageData = [NSData dataWithContentsOfFile:imagePath];
  return [UIImage imageWithData:imageData];
}

@end
