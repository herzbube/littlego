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
#import "BoardPositionViewMetrics.h"
#import "../../ui/UiUtilities.h"


@implementation BoardPositionViewMetrics

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionViewMetrics object.
///
/// @note This is the designated initializer of BoardPositionViewMetrics.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // The order in which these methods are invoked is important
  [self setupConstantProperties];
  [self setupLabelSize];
  [self setupStoneImageSize];
  [self setupStoneImages];
  [self setupCapturedStonesLabelFrame];
  [self setupBoardPositionViewSize];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionViewMetrics
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.blackStoneImage = nil;
  self.whiteStoneImage = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a number of properties whose values are constant.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupConstantProperties
{
  self.boardPositionViewFontSize = 11;
  self.labelNumberOfLines = 2;
  self.boardPositionViewHorizontalPadding = 2;
  self.boardPositionViewHorizontalSpacing = 2;
}

// -----------------------------------------------------------------------------
/// @brief Calculates the size of the label used in each board position view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupLabelSize
{
  // This must be the longest string that can possibly appear in the label of a
  // board position view
  NSString* textToDetermineLabelSize = @"K: 6½";
  for (int lineNumber = 1; lineNumber < self.labelNumberOfLines; ++lineNumber)
    textToDetermineLabelSize = [textToDetermineLabelSize stringByAppendingString:@"\nA"];
  UIFont* font = [UIFont systemFontOfSize:self.boardPositionViewFontSize];
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  CGSize labelSize = [textToDetermineLabelSize sizeWithFont:font
                                          constrainedToSize:constraintSize
                                              lineBreakMode:NSLineBreakByWordWrapping];
  self.labelWidth = labelSize.width;
  self.labelHeight = labelSize.height;
  self.labelOneLineHeight = self.labelHeight / self.labelNumberOfLines;
  self.labelFrame = CGRectMake(self.boardPositionViewHorizontalPadding,
                               0,
                               self.labelWidth,
                               self.labelHeight);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the size of the stone image used in each board position
/// view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupStoneImageSize
{
  self.stoneImageWidthAndHeight = floor(self.labelOneLineHeight * 0.75);

  CGFloat stoneImageViewX = (self.labelFrame.origin.x
                             + self.labelFrame.size.width
                             + self.boardPositionViewHorizontalSpacing);
  // Vertically center on the first line of the label.
  // Use floor() to prevent half-pixels, which would cause anti-aliasing when
  // drawing the image
  CGFloat stoneImageViewY = floor((self.labelOneLineHeight - self.stoneImageWidthAndHeight) / 2);
  self.stoneImageViewFrame = CGRectMake(stoneImageViewX,
                                        stoneImageViewY,
                                        self.stoneImageWidthAndHeight,
                                        self.stoneImageWidthAndHeight);
}

// -----------------------------------------------------------------------------
/// @brief Creates the stone images displayed in each board position view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupStoneImages
{
  self.blackStoneImage = [self stoneImageWithSize:self.stoneImageViewFrame.size
                                            color:[UIColor blackColor]];
  self.whiteStoneImage = [self stoneImageWithSize:self.stoneImageViewFrame.size
                                            color:[UIColor whiteColor]];
}

// -----------------------------------------------------------------------------
/// @brief Calculates the size of the label used to display the number of
/// captured stones.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupCapturedStonesLabelFrame
{
  NSString* textToDetermineLabelSize = @"99";
  UIFont* font = [UIFont systemFontOfSize:self.boardPositionViewFontSize];
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  CGSize size = [textToDetermineLabelSize sizeWithFont:font
                                     constrainedToSize:constraintSize
                                         lineBreakMode:NSLineBreakByWordWrapping];
  CGFloat x = self.stoneImageViewFrame.origin.x;
  CGFloat width = size.width;
  CGFloat height = size.height;
  CGFloat y = self.labelHeight - height;
  self.capturedStonesLabelFrame = CGRectMake(x, y, width, height);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the size of a board position view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionViewSize
{
  self.boardPositionViewWidth = ((2 * self.boardPositionViewHorizontalPadding)
                                 + self.labelWidth
                                 + self.boardPositionViewHorizontalSpacing
                                 + MAX(self.stoneImageWidthAndHeight, self.capturedStonesLabelFrame.size.width));
  self.boardPositionViewHeight = self.labelHeight;
  self.boardPositionViewBounds = CGRectMake(0, 0, self.boardPositionViewWidth, self.boardPositionViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for stoneImageViewForMove:().
// -----------------------------------------------------------------------------
- (UIImage*) stoneImageWithSize:(CGSize)size color:(UIColor*)color
{
  CGFloat diameter = size.width;
  // -1 because the center pixel does not count for drawing
  CGFloat radius = (diameter - 1) / 2;
  // -1 because center coordinates are zero-based, but diameter is a size (i.e.
  // 1-based)
  CGFloat centerXAndY = (diameter - 1) / 2.0;
  CGPoint center = CGPointMake(centerXAndY, centerXAndY);

  UIGraphicsBeginImageContext(size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, gHalfPixel, gHalfPixel);  // avoid anti-aliasing
  [UiUtilities drawCircleWithContext:context center:center radius:radius fill:true color:color];
  UIImage* stoneImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return stoneImage;
}

@end
