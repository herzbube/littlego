// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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
/// https://stackoverflow.com/questions/11083335/no-shadow-emboss-on-uibarbuttonitem
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
///
/// Returns the current image if @a newSize is equal to the size of the current
/// image.
// -----------------------------------------------------------------------------
- (UIImage*) imageByResizingToSize:(CGSize)newSize
{
  if (CGSizeEqualToSize(self.size, newSize))
    return self;

  UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
  CGRect resizedImageRect = CGRectMake(0, 0, newSize.width, newSize.height);
  [self drawInRect:resizedImageRect];
  UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return resizedImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by scaling the current image by @a factor in both
/// directions (width and height).
///
/// Returns the current image if @a factor is 1.0f.
// -----------------------------------------------------------------------------
- (UIImage*) imageByScalingWithFactor:(CGFloat)factor
{
  CGSize newSize = self.size;
  newSize.width *= factor;
  newSize.height *= factor;
  return [self imageByResizingToSize:newSize];
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by scaling the current image so that its new
/// height is @a height.
///
/// Returns the current image if @a newHeight is equal to the height of the
/// current image.
// -----------------------------------------------------------------------------
- (UIImage*) imageByScalingToHeight:(CGFloat)newHeight
{
  if (self.size.height == newHeight)
    return self;

  CGFloat factor = newHeight / self.size.height;
  CGSize newSize = self.size;
  newSize.width *= factor;
  newSize.height = newHeight;

  return [self imageByResizingToSize:newSize];
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by resizing the current image to @a newSize. The
/// new image is always rendered as a template image. This allows to apply a
/// tint color to it when it is rendered in an image view or web view.
// -----------------------------------------------------------------------------
- (UIImage*) templateImageByResizingToSize:(CGSize)newSize
{
  UIImage* resizedImage = [self imageByResizingToSize:newSize];
  return [resizedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by scaling the current image by @a factor in both
/// directions (width and height). The new image is always rendered as a
/// template image. This allows to apply a tint color to it when it is rendered
/// in an image view or web view.
// -----------------------------------------------------------------------------
- (UIImage*) templateImageByScalingWithFactor:(CGFloat)factor
{
  UIImage* resizedImage = [self imageByScalingWithFactor:factor];
  return [resizedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by scaling the current image so that its new
/// height is @a height. The new image is always rendered as a template image.
/// This allows to apply a tint color to it when it is rendered in an image view
/// or web view.
// -----------------------------------------------------------------------------
- (UIImage*) templateImageByScalingToHeight:(CGFloat)newHeight
{
  UIImage* resizedImage = [self imageByScalingToHeight:newHeight];
  return [resizedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by padding the current image so that the new
/// image has @a newWidth. The current image is expected to have a smaller width
/// than @a newWidth. The padding is applied uniformly on both sides of the
/// image, i.e. the original image is centered within the new image. The padding
/// has a transparent background.
///
/// Returns the current image if @a newWidth is equal to the width of the
/// current image.
// -----------------------------------------------------------------------------
- (UIImage*) imageByPaddingToWidth:(CGFloat)newWidth
{
  CGSize newSize = CGSizeMake(newWidth, self.size.height);
  return [self imageByPaddingToSize:newSize];
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by padding the current image so that the new
/// image has @a newSize. The current image is expected to have a smaller size
/// than @a newSize. The padding is applied uniformly on all 4 sides of the
/// image, i.e. the original image is horizontally and vertically centered
/// within the new image. The padding has a transparent background.
///
/// Returns the current image if @a newSize is equal to the size of the
/// current image.
// -----------------------------------------------------------------------------
- (UIImage*) imageByPaddingToSize:(CGSize)newSize
{
  CGSize originalSize = self.size;
  if (CGSizeEqualToSize(originalSize, newSize))
    return self;

  BOOL opaque = NO;
  CGFloat scale = 0.0f;
  UIGraphicsBeginImageContextWithOptions(newSize, opaque, scale);

  CGFloat leftEdgePadding = (newSize.width - originalSize.width) / 2.0f;
  CGFloat topEdgePadding = (newSize.height - originalSize.height) / 2.0f;
  CGRect drawingRect = CGRectMake(leftEdgePadding, topEdgePadding, originalSize.width, originalSize.height);
  [self drawInRect:drawingRect];

  UIImage* paddedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return paddedImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by padding the current image so that the new
/// image has @a newSize. The current image is expected to have a smaller size
/// than @a newSize. The padding is applied uniformly on all 4 sides of the
/// image, i.e. the original image is horizontally and vertically centered
/// within the new image. The padding has a transparent background. The padded
/// image is tinted to contrast a dark/light background matching
/// @a userInterfaceStyle.
///
/// Returns the current image if @a newSize is equal to the size of the
/// current image.
// -----------------------------------------------------------------------------
- (UIImage*) imageByPaddingToSize:(CGSize)newSize tintedFor:(UIUserInterfaceStyle)userInterfaceStyle
{
  UIColor* tintColor = (userInterfaceStyle == UIUserInterfaceStyleLight) ? [UIColor blackColor] : [UIColor whiteColor];
  UIImage* paddedAndTintedImage = [self imageByPaddingToSize:newSize tintedWith:tintColor];
  return paddedAndTintedImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by padding the current image so that the new
/// image has @a newSize. The current image is expected to have a smaller size
/// than @a newSize. The padding is applied uniformly on all 4 sides of the
/// image, i.e. the original image is horizontally and vertically centered
/// within the new image. The padding has a transparent background. The padded
/// image is tinted with @a tintColor.
///
/// Returns the current image if @a newSize is equal to the size of the
/// current image.
// -----------------------------------------------------------------------------
- (UIImage*) imageByPaddingToSize:(CGSize)newSize tintedWith:(UIColor*)tintColor
{
  UIImage* paddedImage = [self imageByPaddingToSize:newSize];

  if (@available(iOS 13, *))
    return [paddedImage imageWithTintColor:tintColor];
  else
    return [paddedImage imageByTintingWithColor:tintColor];
}

// -----------------------------------------------------------------------------
/// @brief Returns a new image by tinting the current image with @a tintColor.
///
/// The code for this method is based on https://stackoverflow.com/a/19275079.
/// It has not been analyzed for correctness or tested thoroughly.
///
/// This method exists only to support tinting in iOS versions older than 13.0.
/// Beginning with iOS 13.0 the native UIImage::imageWithTintColor:() should
/// be used.
// -----------------------------------------------------------------------------
- (UIImage*) imageByTintingWithColor:(UIColor*)tintColor
{
  BOOL opaque = NO;
  UIGraphicsBeginImageContextWithOptions(self.size, opaque, self.scale);

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, 0, self.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);

  CGContextSetBlendMode(context, kCGBlendModeNormal);

  CGRect drawingRect = CGRectMake(0, 0, self.size.width, self.size.height);
  CGContextClipToMask(context, drawingRect, self.CGImage);

  [tintColor setFill];
  CGContextFillRect(context, drawingRect);

  UIImage* tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return tintedImage;
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

// -----------------------------------------------------------------------------
/// @brief Returns an icon image that describes @a boardPositionValuation.
// -----------------------------------------------------------------------------
+ (UIImage*) iconForBoardPositionValuation:(enum GoBoardPositionValuation)boardPositionValuation
{
  switch (boardPositionValuation)
  {
    case GoBoardPositionValuationGoodForBlack:
      return [UIImage imageNamed:stoneBlackButtonIconResource];
    case GoBoardPositionValuationVeryGoodForBlack:
      return [UIImage imageNamed:stonesOverlappingBlackButtonIconResource];
    case GoBoardPositionValuationGoodForWhite:
      return [UIImage imageNamed:stoneWhiteButtonIconResource];
    case GoBoardPositionValuationVeryGoodForWhite:
      return [UIImage imageNamed:stonesOverlappingWhiteButtonIconResource];
    case GoBoardPositionValuationEven:
      return [UIImage imageNamed:stoneBlackAndWhiteButtonIconResource];
    case GoBoardPositionValuationVeryEven:
      return [UIImage imageNamed:stonesOverlappingBlackAndWhiteButtonIconResource];
    case GoBoardPositionValuationUnclear:
      return [UIImage imageNamed:unclearButtonIconResource];
    case GoBoardPositionValuationVeryUnclear:
      return [UIImage imageNamed:veryUnclearButtonIconResource];
    case GoBoardPositionValuationNone:
      return [UIImage imageNamed:noneButtonIconResource];
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an icon image that describes @a moveValuation.
// -----------------------------------------------------------------------------
+ (UIImage*) iconForMoveValuation:(enum GoMoveValuation)moveValuation
{
  switch (moveValuation)
  {
    case GoMoveValuationGood:
      return [UIImage imageNamed:goodButtonIconResource];
    case GoMoveValuationVeryGood:
      return [UIImage imageNamed:veryGoodButtonIconResource];
    case GoMoveValuationBad:
      return [UIImage imageNamed:badButtonIconResource];
    case GoMoveValuationVeryBad:
      return [UIImage imageNamed:veryBadButtonIconResource];
    case GoMoveValuationInteresting:
      return [UIImage imageNamed:interestingButtonIconResource];
    case GoMoveValuationDoubtful:
      return [UIImage imageNamed:doubtfulButtonIconResource];
    case GoMoveValuationNone:
      return [UIImage imageNamed:noneButtonIconResource];
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an icon image that describes @a scoreSummary and @a scoreValue.
// -----------------------------------------------------------------------------
+ (UIImage*) iconForScoreSummary:(enum GoScoreSummary)scoreSummary
{
  switch (scoreSummary)
  {
    case GoScoreSummaryBlackWins:
      return [UIImage imageNamed:stoneBlackButtonIconResource];
    case GoScoreSummaryWhiteWins:
      return [UIImage imageNamed:stoneWhiteButtonIconResource];
    case GoScoreSummaryTie:
      return [UIImage imageNamed:stoneBlackAndWhiteButtonIconResource];
    case GoScoreSummaryNone:
      return [UIImage imageNamed:noneButtonIconResource];
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an icon image that describes @a boardPositionHotspotDesignation.
// -----------------------------------------------------------------------------
+ (UIImage*) iconForBoardPositionHotspotDesignation:(enum GoBoardPositionHotspotDesignation)boardPositionHotspotDesignation
{
  switch (boardPositionHotspotDesignation)
  {
    case GoBoardPositionHotspotDesignationYes:
      return [UIImage imageNamed:hotspotIconResource];
    case GoBoardPositionHotspotDesignationYesEmphasized:
      // TODO xxx in iOS 13 and newer there is an imageWithTintColor method
      // https://developer.apple.com/documentation/uikit/uiimage/3327300-imagewithtintcolor?language=objc
      return [UIImage imageNamed:hotspotIconResource];
    case GoBoardPositionHotspotDesignationNone:
      return [UIImage imageNamed:noneButtonIconResource];
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an edit icon image.
// -----------------------------------------------------------------------------
+ (UIImage*) editIcon
{
  if (@available(iOS 13, *))
    return [UIImage systemImageNamed:@"square.and.pencil"];
  else
    return [UIImage imageNamed:editButtonIconResource];
}

// -----------------------------------------------------------------------------
/// @brief Returns a trashcan icon image.
// -----------------------------------------------------------------------------
+ (UIImage*) trashcanIcon
{
  if (@available(iOS 13, *))
    return [UIImage systemImageNamed:@"trash"];
  else
    return [UIImage imageNamed:trashcanButtonIconResource];
}

@end
