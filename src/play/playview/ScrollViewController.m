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
#import "ScrollViewController.h"
#import "PlayView.h"
#import "PlayViewController.h"
#import "../gesture/DoubleTapGestureController.h"
#import "../gesture/PanGestureController.h"
#import "../gesture/TwoFingerTapGestureController.h"
#import "../model/PlayViewModel.h"
#import "../../main/ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ScrollViewController.
// -----------------------------------------------------------------------------
@interface ScrollViewController()
/// @brief The overall zoom scale currently in use for drawing the Play view.
/// At zoom scale value 1.0 the entire board is visible.
@property(nonatomic, assign) CGFloat currentAbsoluteZoomScale;
@property(nonatomic, retain) DoubleTapGestureController* doubleTapGestureController;
@property(nonatomic, retain) TwoFingerTapGestureController* twoFingerTapGestureController;
@end


@implementation ScrollViewController

// -----------------------------------------------------------------------------
/// @brief Initializes a ScrollViewController object.
///
/// @note This is the designated initializer of ScrollViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupChildControllers];
  PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  [playViewModel addObserver:self forKeyPath:@"maximumZoomScale" options:0 context:NULL];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ScrollViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  [playViewModel removeObserver:self forKeyPath:@"maximumZoomScale"];
  self.playViewController = nil;
  self.doubleTapGestureController = nil;
  self.twoFingerTapGestureController = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.playViewController = [[[PlayViewController alloc] init] autorelease];
  self.doubleTapGestureController = [[[DoubleTapGestureController alloc] init] autorelease];
  self.twoFingerTapGestureController = [[[TwoFingerTapGestureController alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setPlayViewController:(PlayViewController*)playViewController
{
  if (_playViewController == playViewController)
    return;
  if (_playViewController)
  {
    [_playViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_playViewController removeFromParentViewController];
    [_playViewController release];
    _playViewController = nil;
  }
  if (playViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:playViewController];
    [_playViewController didMoveToParentViewController:self];
    [playViewController retain];
    _playViewController = playViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectZero] autorelease];
  self.view = self.scrollView;
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.view.backgroundColor = [UIColor clearColor];
  self.scrollView.bouncesZoom = NO;
  self.scrollView.delegate = self;

  [self.view addSubview:self.playViewController.view];

  // Even though these scroll views do not scroll or zoom interactively, we
  // still need to become their delegate so that we can change their zoomScale
  // property. If we don't do this, then changing their zoomScale will have no
  // effect, i.e. the property will always remain at 1.0. This is because
  // UIScrollView requires a delegate that it can query with
  // viewForZoomingInScrollView: for all zoom-related operations (such as
  // changing the zoomScale).
  self.playViewController.playView.coordinateLabelsLetterViewScrollView.delegate = self;
  self.playViewController.playView.coordinateLabelsNumberViewScrollView.delegate = self;

  PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  self.scrollView.zoomScale = 1.0f;
  self.scrollView.minimumZoomScale = 1.0f;
  self.scrollView.maximumZoomScale = playViewModel.maximumZoomScale;
  [self synchronizeZoomScale:self.scrollView.zoomScale
            minimumZoomScale:self.scrollView.minimumZoomScale
            maximumZoomScale:self.scrollView.maximumZoomScale];

  self.currentAbsoluteZoomScale = 1.0f;

  self.playViewController.panGestureController.scrollView = self.scrollView;
  self.doubleTapGestureController.scrollView = self.scrollView;
  self.twoFingerTapGestureController.scrollView = self.scrollView;
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (void) viewWillUnload
{
  [super viewWillUnload];
  self.playViewController.panGestureController.scrollView = nil;
  self.doubleTapGestureController.scrollView = nil;
  self.twoFingerTapGestureController.scrollView = nil;
  self.scrollView = nil;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method. This override properly resizes the scroll
/// view content using self.currentAbsoluteZoomScale.
///
/// Under normal circumstances, the Play view (which is the content of the
/// scroll view) would be resized automatically by way of a properly set
/// autoresizingMask. For some unknown reason the automatic resize does not work
/// in this scenario:
/// - The device is iPad, i.e. the scroll view (and with it the Play view) is
///   embedded in a split view controller
/// - The Play view is zoomed in
/// - The UI is rotated
///
/// Because of the split view controller, which shows/hides its master view
/// depending on the UI orientation, the resize of the scroll view during UI
/// rotation is dis-proportional. If the rotation happens while the Play view is
/// zoomed in, the automatic resize of the Play view does not use the same
/// dis-proportional factor as the resize of the scroll view. Why this is the
/// case is unknown, but this override of viewWillLayoutSubviews has been
/// implemented to work around the problem.
///
/// Due to this override's existence, the Play view is no longer fitted with an
/// autoresizingMask. This means that this override not only must handle UI
/// orientation changes, but also initial resizing when the Play view is shown
/// for the first time after the app is launched, or after the Play view is
/// reloaded due to a view purge in iOS 5.
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  // super's implementation of viewWillLayoutSubviews is documented to be a
  // no-op, so there's no need to invoke it.

  // viewWillLayoutSubviews is also called continuously while the user is
  // zooming in/out, or is scrolling. In these cases we must not perform any
  // resizes
  if (self.scrollView.zooming || self.scrollView.isDragging)
    return;

  CGRect newFrame = self.playViewController.view.frame;
  newFrame.size = self.scrollView.bounds.size;
  newFrame.size.width *= self.currentAbsoluteZoomScale;
  newFrame.size.height *= self.currentAbsoluteZoomScale;
  self.playViewController.view.frame = newFrame;
  self.scrollView.contentSize = newFrame.size;
}

#pragma mark - UIScrollViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewDidScroll:(UIScrollView*)scrollView
{
  // Only synchronize if the Play view scroll is the trigger. Coordinate label
  // scroll views are the trigger when their content offset is synchronized
  // because changing the content offset counts as scrolling.
  if (scrollView != self.scrollView)
    return;
  // Coordinate label scroll views are not visible during zooming, so we don't
  // need to synchronize
  if (! scrollView.zooming)
    [self synchronizeContentOffset:scrollView.contentOffset];
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
  if (scrollView == self.scrollView)
    return self.playViewController.view;
  else if (scrollView == self.playViewController.playView.coordinateLabelsLetterViewScrollView)
    return self.playViewController.playView.coordinateLabelsLetterView;
  else if (scrollView == self.playViewController.playView.coordinateLabelsNumberViewScrollView)
    return self.playViewController.playView.coordinateLabelsNumberView;
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewWillBeginZooming:(UIScrollView*)scrollView withView:(UIView*)view
{
  // Temporarily hide coordinate label views while a zoom operation is in
  // progress. Synchronizing coordinate label views' zoom scale, content offset
  // and frame size while the zoom operation is in progress is a lot of effort,
  // and even though the views are zoomed formally correct the end result looks
  // like shit (because the labels are not part of the Play view they zoom
  // differently). So instead of trying hard and failing we just dispense with
  // the effort.
  self.playViewController.playView.coordinateLabelsLetterViewScrollView.hidden = YES;
  self.playViewController.playView.coordinateLabelsNumberViewScrollView.hidden = YES;
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
  // contentOffset, and also the PlayView's frame, bounds and transform
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
  self.playViewController.view.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);

  [self synchronizeZoomScale:self.scrollView.zoomScale
            minimumZoomScale:self.scrollView.minimumZoomScale
            maximumZoomScale:self.scrollView.maximumZoomScale];
  [self synchronizeContentOffset:contentOffset];
  // At this point we should also update content size and frame changes. We
  // don't do so because PlayView already takes care of all this for us.
  self.playViewController.playView.coordinateLabelsLetterViewScrollView.hidden = NO;
  self.playViewController.playView.coordinateLabelsNumberViewScrollView.hidden = NO;

  // Finally, trigger the view/layer to redraw their content
  [self.playViewController.playView delayedUpdate];
}

#pragma mark - KVO notification

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
        self.playViewController.view.frame = CGRectMake(0, 0, newContentSize.width, newContentSize.height);

        DDLogInfo(@"%@: Adjusting old zoom scale %f to new maximum %f",
                  self, oldAbsoluteZoomScale, newAbsoluteZoomScale);
        DDLogVerbose(@"%@: Old/new relative minimum zoom scale = %f / %f",
                     self, oldRelativeMinimumZoomScale, self.scrollView.minimumZoomScale);
        DDLogVerbose(@"%@: New content offset = %f / %f ",
                     self, newContentOffset.x, newContentOffset.y);
        DDLogVerbose(@"%@: New content size = %f / %f ",
                     self, newContentSize.width, newContentSize.height);

        [self.playViewController.playView delayedUpdate];
      }
    }
  }
}

#pragma mark - Internal helpers

// -----------------------------------------------------------------------------
/// @brief Internal helper for synchronizing scroll view.
// -----------------------------------------------------------------------------
- (void) synchronizeContentOffset:(CGPoint)contentOffset
{
  CGPoint coordinateLabelsLetterViewScrollViewContentOffset = self.playViewController.playView.coordinateLabelsLetterViewScrollView.contentOffset;
  coordinateLabelsLetterViewScrollViewContentOffset.x = contentOffset.x;
  self.playViewController.playView.coordinateLabelsLetterViewScrollView.contentOffset = coordinateLabelsLetterViewScrollViewContentOffset;
  CGPoint coordinateLabelsNumberViewScrollViewContentOffset = self.playViewController.playView.coordinateLabelsNumberViewScrollView.contentOffset;
  coordinateLabelsNumberViewScrollViewContentOffset.y = contentOffset.y;
  self.playViewController.playView.coordinateLabelsNumberViewScrollView.contentOffset = coordinateLabelsNumberViewScrollViewContentOffset;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for synchronizing scroll view.
// -----------------------------------------------------------------------------
- (void) synchronizeZoomScale:(CGFloat)zoomScale
             minimumZoomScale:(CGFloat)minimumZoomScale
             maximumZoomScale:(CGFloat)maximumZoomScale
{
  self.playViewController.playView.coordinateLabelsLetterViewScrollView.zoomScale = zoomScale;
  self.playViewController.playView.coordinateLabelsLetterViewScrollView.minimumZoomScale = minimumZoomScale;
  self.playViewController.playView.coordinateLabelsLetterViewScrollView.maximumZoomScale = maximumZoomScale;
  self.playViewController.playView.coordinateLabelsNumberViewScrollView.zoomScale = zoomScale;
  self.playViewController.playView.coordinateLabelsNumberViewScrollView.minimumZoomScale = minimumZoomScale;
  self.playViewController.playView.coordinateLabelsNumberViewScrollView.maximumZoomScale = maximumZoomScale;
}

@end
