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



// -----------------------------------------------------------------------------
/// @brief The BoardPositionViewMetrics class is responsible for providing pre-
/// calculated sizes and other values to BoardPositionView.
///
/// BoardPositionViewMetrics performs all calculations once, and only once,
/// when it is initialized. The current device is taken into account when values
/// are calculated.
///
/// @note Although there is no explicit link to PlayViewController,
/// BoardPositionViewMetrics has implicit knowledge of the way how
/// PlayViewController sets up the view hierarchy.
// -----------------------------------------------------------------------------
@interface BoardPositionViewMetrics : NSObject
{
}

/// @name Board position view properties
//@{
@property(nonatomic, assign) int boardPositionViewFontSize;
@property(nonatomic, assign) int labelWidth;
@property(nonatomic, assign) int labelHeight;
@property(nonatomic, assign) int labelNumberOfLines;
@property(nonatomic, assign) int labelOneLineHeight;
@property(nonatomic, assign) CGRect labelFrame;
@property(nonatomic, assign) int stoneImageWidthAndHeight;
@property(nonatomic, retain) UIImage* blackStoneImage;
@property(nonatomic, retain) UIImage* whiteStoneImage;
@property(nonatomic, assign) CGRect stoneImageViewFrame;
@property(nonatomic, assign) CGRect capturedStonesLabelFrame;
@property(nonatomic, assign) int boardPositionViewWidth;
@property(nonatomic, assign) int boardPositionViewHeight;
/// @brief Number of pixels to use for internal padding of a board position view
/// (i.e. how much space should be between the left view edge and the label,
/// and the right view edge and the stone image).
@property(nonatomic, assign) int boardPositionViewHorizontalPadding;
/// @brief Number of pixels to use for internal spacing of a board position view
/// (i.e. how much space should be between the label and the stone image).
@property(nonatomic, assign) int boardPositionViewHorizontalSpacing;
@property(nonatomic, assign) CGRect boardPositionViewBounds;
//@}

@end
