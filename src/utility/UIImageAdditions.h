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


// -----------------------------------------------------------------------------
/// @brief The UIImageAdditions category enhances UIImage by adding convenience
/// drawing functions that create new images.
///
/// @ingroup utility
// -----------------------------------------------------------------------------
@interface UIImage(UIImageAdditions)

+ (UIImage*) imageByApplyingUIBarButtonItemStyling:(UIImage*)image;
- (UIImage*) imageByResizingToSize:(CGSize)newSize;
- (UIImage*) imageByScalingWithFactor:(CGFloat)factor;
- (UIImage*) imageByScalingToHeight:(CGFloat)newHeight;
- (UIImage*) templateImageByResizingToSize:(CGSize)newSize;
- (UIImage*) templateImageByScalingWithFactor:(CGFloat)factor;
- (UIImage*) templateImageByScalingToHeight:(CGFloat)newHeight;
- (UIImage*) imageByPaddingToWidth:(CGFloat)newWidth;
- (UIImage*) imageByPaddingToSize:(CGSize)newSize;
- (UIImage*) imageByPaddingToSize:(CGSize)newSize tintedFor:(UIUserInterfaceStyle)userInterfaceStyle API_AVAILABLE(ios(12.0));
- (UIImage*) imageByPaddingToSize:(CGSize)newSize tintedWith:(UIColor*)tintColor;
- (UIImage*) imageByTintingWithColor:(UIColor*)tintColor API_DEPRECATED("use built-in imageWithTintColor: instead", ios(2.0, 13.0));
+ (UIImage*) gradientImageWithSize:(CGSize)size startColor:(UIColor*)startColor endColor:(UIColor*)endColor;
+ (UIImage*) gradientImageWithSize:(CGSize)size startColor:(UIColor*)startColor middleColor:(UIColor*)middleColor endColor:(UIColor*)endColor;
+ (UIImage*) gradientImageWithSize:(CGSize)size startColor1:(UIColor*)startColor1 endColor1:(UIColor*)endColor1 startColor2:(UIColor*)startColor2 endColor2:(UIColor*)endColor2;
+ (UIImage*) tiledImageWithSize:(CGSize)size fromTile:(UIImage*)tile;
+ (UIImage*) woodenBackgroundTileImage;
+ (UIImage*) iconForBoardPositionValuation:(enum GoBoardPositionValuation)boardPositionValuation;
+ (UIImage*) iconForMoveValuation:(enum GoMoveValuation)moveValuation;
+ (UIImage*) iconForScoreSummary:(enum GoScoreSummary)scoreSummary;
+ (UIImage*) iconForBoardPositionHotspotDesignation:(enum GoBoardPositionHotspotDesignation)boardPositionHotspotDesignation;
+ (UIImage*) editIcon;
+ (UIImage*) trashcanIcon;

@end
