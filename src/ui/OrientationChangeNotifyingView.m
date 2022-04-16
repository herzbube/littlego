// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "OrientationChangeNotifyingView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// OrientationChangeNotifyingView.
// -----------------------------------------------------------------------------
@interface OrientationChangeNotifyingView()
@property(nonatomic, assign) bool didNotifyDelegateAtLeastOnce;
@property(nonatomic, assign) UILayoutConstraintAxis currentLargerDimension;
@end


@implementation OrientationChangeNotifyingView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an OrientationChangeNotifyingView object.
///
/// @note This is the designated initializer of OrientationChangeNotifyingView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;
  self.didNotifyDelegateAtLeastOnce = false;
  self.currentLargerDimension = UILayoutConstraintAxisVertical;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this OrientationChangeNotifyingView
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  [super dealloc];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [super layoutSubviews];

  CGSize viewSize = self.bounds.size;

  UILayoutConstraintAxis newLargerDimension;
  UILayoutConstraintAxis newSmallerDimension;
  if (viewSize.height >= viewSize.width)
  {
    newLargerDimension = UILayoutConstraintAxisVertical;
    newSmallerDimension = UILayoutConstraintAxisHorizontal;
  }
  else
  {
    newLargerDimension = UILayoutConstraintAxisHorizontal;
    newSmallerDimension = UILayoutConstraintAxisVertical;
  }

  bool orientationDidChange = self.currentLargerDimension != newLargerDimension;
  self.currentLargerDimension = newLargerDimension;

  if (! orientationDidChange && self.didNotifyDelegateAtLeastOnce)
    return;

  if (! self.delegate)
    return;

  SEL selector = @selector(orientationChangeNotifyingView:didChangeToLargerDimension:smallerDimension:);
  if (! [self.delegate respondsToSelector:selector])
    return;

  [self.delegate orientationChangeNotifyingView:self
                     didChangeToLargerDimension:newLargerDimension
                               smallerDimension:newSmallerDimension];
  self.didNotifyDelegateAtLeastOnce = true;
}

@end
