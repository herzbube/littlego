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
#import "TwoFingerTapGestureController.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// TwoFingerTapGestureController.
// -----------------------------------------------------------------------------
@interface TwoFingerTapGestureController()
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
@end


@implementation TwoFingerTapGestureController

// -----------------------------------------------------------------------------
/// @brief Initializes a TwoFingerTapGestureController object.
///
/// @note This is the designated initializer of TwoFingerTapGestureController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.scrollView = nil;
  [self setupTapGestureRecognizer];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TwoFingerTapGestureController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scrollView = nil;
  self.tapRecognizer = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupTapGestureRecognizer
{
  self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)] autorelease];
  self.tapRecognizer.numberOfTapsRequired = 1;
  self.tapRecognizer.numberOfTouchesRequired = 2;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setScrollView:(UIScrollView*)scrollView
{
  if (_scrollView == scrollView)
    return;
  if (_scrollView && self.tapRecognizer)
    [_scrollView removeGestureRecognizer:self.tapRecognizer];
  _scrollView = scrollView;
  if (_scrollView && self.tapRecognizer)
    [_scrollView addGestureRecognizer:self.tapRecognizer];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a double-tapping gesture.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;
  CGFloat newZoomScale = self.scrollView.zoomScale / 1.5f;
  newZoomScale = MAX(newZoomScale, self.scrollView.minimumZoomScale);
  [self.scrollView setZoomScale:newZoomScale animated:YES];
}

@end
