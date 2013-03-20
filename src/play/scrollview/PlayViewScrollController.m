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
#import "../PlayViewModel.h"
#import "../../main/ApplicationDelegate.h"

#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewScrollController.
// -----------------------------------------------------------------------------
@interface PlayViewScrollController()

@property(nonatomic, assign) UIScrollView* scrollView;
@property(nonatomic, assign) PlayView* playView;
/// @brief The overall zoom scale currently in use for drawing the Play view.
/// At zoom scale value 1.0 the entire board is visible.
@property(nonatomic, assign) CGFloat currentAbsoluteZoomScale;
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
  [self setupScrollView];

  PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  [playViewModel addObserver:self forKeyPath:@"maximumZoomScale" options:0 context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewScrollController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  [playViewModel removeObserver:self forKeyPath:@"maximumZoomScale"];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupScrollView
{
  self.scrollView.delegate = self;

  PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  self.scrollView.minimumZoomScale = 1.0f;
  self.scrollView.maximumZoomScale = playViewModel.maximumZoomScale;
  self.scrollView.zoomScale = 1.0f;

  self.currentAbsoluteZoomScale = 1.0f;
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
  self.currentAbsoluteZoomScale *= scale;
  DDLogVerbose(@"scrollViewDidEndZooming: new overall zoom scale = %f", self.currentAbsoluteZoomScale);

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

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  if (object == playViewModel)
  {
    if ([keyPath isEqualToString:@"maximumZoomScale"])
    {
      if (self.currentAbsoluteZoomScale <= playViewModel.maximumZoomScale)
      {
        CGFloat newRelativeMaximumZoomScale = playViewModel.maximumZoomScale / self.currentAbsoluteZoomScale;
        self.scrollView.maximumZoomScale = newRelativeMaximumZoomScale;
      }
      else
      {
        // The Play view is currently zoomed in more than the new maximum zoom
        // scale allows. The goal is to adjust the current zoom scale, and all
        // depending metrics, to the new maximum.
        CGFloat newAbsoluteZoomScale = playViewModel.maximumZoomScale;
        CGFloat factor = self.currentAbsoluteZoomScale / newAbsoluteZoomScale;
        CGFloat oldAbsoluteZoomScale = self.currentAbsoluteZoomScale;
        self.currentAbsoluteZoomScale = newAbsoluteZoomScale;

        // Make sure that after we are finished the user cannot zoom in any
        // further
        if (self.scrollView.maximumZoomScale > 1.0f)
          self.scrollView.maximumZoomScale = 1.0f;

        // Adjust the relative minimum zoom scale
        CGFloat oldRelativeMinimumZoomScale = self.scrollView.minimumZoomScale;
        self.scrollView.minimumZoomScale = factor * oldRelativeMinimumZoomScale;

        // Adjust content offset, content size and Play view frame size
        CGPoint newContentOffset = self.scrollView.contentOffset;
        newContentOffset.x /= factor;
        newContentOffset.y /= factor;
        self.scrollView.contentOffset = newContentOffset;
        CGSize newContentSize = self.scrollView.contentSize;
        newContentSize.width /= factor;
        newContentSize.height /= factor;
        self.scrollView.contentSize = newContentSize;
        self.playView.frame = CGRectMake(0, 0, newContentSize.width, newContentSize.height);

        DDLogInfo(@"%@: Adjusting old zoom scale %f to new maximum %f",
                  self, oldAbsoluteZoomScale, newAbsoluteZoomScale);
        DDLogVerbose(@"%@: Old/new relative minimum zoom scale = %f / %f",
                     self, oldRelativeMinimumZoomScale, self.scrollView.minimumZoomScale);
        DDLogVerbose(@"%@: New content offset = %f / %f ",
                     self, newContentOffset.x, newContentOffset.y);
        DDLogVerbose(@"%@: New content size = %f / %f ",
                     self, newContentSize.width, newContentSize.height);

        [self.playView setNeedsLayout];
      }
    }
  }
}

@end
