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
#import "PlayViewScrollController.h"
#import "../PlayView.h"

#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewScrollController.
// -----------------------------------------------------------------------------
@interface PlayViewScrollController()

@property(nonatomic, assign) UIScrollView* scrollView;
@property(nonatomic, assign) PlayView* playView;
/// @brief The overall zoom scale currently in use for drawing the Play view.
/// At zoom scale value 1.0 the entire board is visible.
///
/// Currently we don't use this anywhere, the Play view layers redraw their
/// content solely based on the view/layer size.
@property(nonatomic, assign) CGFloat zoomScale;
@end



@implementation PlayViewScrollController

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewScrollController object that manages
/// @a scrollView and @a playView.
///
/// @note This is the designated initializer of PlayViewScrollController.
// -----------------------------------------------------------------------------
- (id) initWithScrollView:(UIScrollView*)scrollView playView:(PlayView*)playView
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.scrollView = scrollView;
  self.playView = playView;
  self.scrollView.delegate = self;
  self.zoomScale = self.scrollView.zoomScale;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
  return self.playView;
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(float)scale
{
  self.zoomScale *= scale;
  DDLogVerbose(@"scrollViewDidEndZooming: new overall zoom scale = %f", self.zoomScale);

  // Remember content offset and size so that we can re-apply them after we
  // reset the zoom scale to 1.0
  CGPoint contentOffset = scrollView.contentOffset;
  CGSize contentSize = scrollView.contentSize;
  DDLogVerbose(@"scrollViewDidEndZooming: new content size = %f / %f ",
               contentSize.width, contentSize.height);

  // Big change here: This resets the scroll view's contentSize and
  // contentOffset, and also the LayerView's frame, bounds and transform
  // properties
  scrollView.zoomScale = 1.0f;
  // Adjust the minimum and maximum zoom scale so that the user cannot zoom
  // in/out more than originally intended
  scrollView.minimumZoomScale = scrollView.minimumZoomScale / scale;
  scrollView.maximumZoomScale = scrollView.maximumZoomScale / scale;
  DDLogVerbose(@"scrollViewDidEndZooming: new minimumZoomScale = %f, maximumZoomScale = %f",
               scrollView.minimumZoomScale, scrollView.maximumZoomScale);

  // Re-apply some property values that were changed when the zoom scale was
  // reset to 1.0
  scrollView.contentSize = contentSize;
  [scrollView setContentOffset:contentOffset animated:NO];
  self.playView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);

  // Finally, trigger the view/layer to redraw their content
  [self.playView setNeedsLayout];
}

@end
