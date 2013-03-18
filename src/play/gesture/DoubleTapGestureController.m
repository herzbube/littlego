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
#import "DoubleTapGestureController.h"


// -----------------------------------------------------------------------------
/// @brief Class extension for DoubleTapGestureController.
// -----------------------------------------------------------------------------
@interface DoubleTapGestureController()
@property(nonatomic, assign) UIScrollView* scrollView;
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
@end


@implementation DoubleTapGestureController

// -----------------------------------------------------------------------------
/// @brief Initializes a DoubleTapGestureController object that handles
/// double-tap gestures in the screen area occupied by @a scrollView.
///
/// @note This is the designated initializer of DoubleTapGestureController.
// -----------------------------------------------------------------------------
- (id) initWithScrollView:(UIScrollView*)scrollView
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.scrollView = scrollView;
  [self setupTapGestureRecognizer];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DoubleTapGestureController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.tapRecognizer = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupTapGestureRecognizer
{
  self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)] autorelease];
  self.tapRecognizer.numberOfTapsRequired = 2;
  self.tapRecognizer.numberOfTouchesRequired = 1;
  [self.scrollView addGestureRecognizer:self.tapRecognizer];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a double-tapping gesture.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;
  CGFloat newZoomScale = self.scrollView.zoomScale * 1.5f;
  newZoomScale = MIN(newZoomScale, self.scrollView.maximumZoomScale);
  CGPoint pointToZoomTo = [gestureRecognizer locationInView:self.scrollView];
  CGRect rectToZoomTo = [self rectForPointToZoomTo:pointToZoomTo zoomScale:newZoomScale];
  [self.scrollView zoomToRect:rectToZoomTo animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Returns the rectangle to zoom in on / zoom out to. The rectangle's
/// center is @a point, the rectangle represents the new zoom scale
/// @a zoomScale.
// -----------------------------------------------------------------------------
- (CGRect) rectForPointToZoomTo:(CGPoint)point zoomScale:(CGFloat)zoomScale
{
  // The implementation of this method comes from
  // http://www.raywenderlich.com/10518/how-to-use-uiscrollview-to-scroll-and-zoom-content
  CGSize scrollViewSize = self.scrollView.bounds.size;
  CGFloat width = scrollViewSize.width / zoomScale;
  CGFloat height = scrollViewSize.height / zoomScale;
  CGFloat x = point.x - (width / 2.0f);
  CGFloat y = point.y - (height / 2.0f);
  return CGRectMake(x, y, width, height);
}

@end
