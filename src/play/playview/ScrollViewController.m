// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "CoordinateLabelsView.h"
#import "PlayView.h"
#import "PlayViewController.h"
#import "../gesture/DoubleTapGestureController.h"
#import "../gesture/PanGestureController.h"
#import "../gesture/TwoFingerTapGestureController.h"
#import "../model/PlayViewModel.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ScrollViewController.
// -----------------------------------------------------------------------------
@interface ScrollViewController()
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
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureViewObjects];
  [self synchronizeZoomScale:self.scrollView.zoomScale
            minimumZoomScale:self.scrollView.minimumZoomScale
            maximumZoomScale:self.scrollView.maximumZoomScale];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectZero] autorelease];
  self.view = self.scrollView;
  [self.view addSubview:self.playViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  UIView* playView = self.playViewController.view;
  playView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:playView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViewObjects
{
  self.view.backgroundColor = [UIColor clearColor];

  self.scrollView.bouncesZoom = NO;
  self.scrollView.delegate = self;
  self.scrollView.zoomScale = 1.0f;
  self.scrollView.minimumZoomScale = 1.0f;
  self.scrollView.maximumZoomScale = [ApplicationDelegate sharedDelegate].playViewModel.maximumZoomScale;

  // Even though these scroll views do not scroll or zoom interactively, we
  // still need to become their delegate so that we can change their zoomScale
  // property. If we don't do this, then changing their zoomScale will have no
  // effect, i.e. the property will always remain at 1.0. This is because
  // UIScrollView requires a delegate that it can query with
  // viewForZoomingInScrollView: for all zoom-related operations (such as
  // changing the zoomScale).
  self.coordinateLabelsLetterViewScrollView.delegate = self;
  self.coordinateLabelsNumberViewScrollView.delegate = self;

  self.playViewController.panGestureController.scrollView = self.scrollView;
  self.doubleTapGestureController.scrollView = self.scrollView;
  self.twoFingerTapGestureController.scrollView = self.scrollView;
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

  // Updating the play view's intrinsic content size causes Auto Layout
  // to adjust the scroll view's content size
  // TODO xxx Check if the content offset is also adjusted. If not we need to
  // adjust it manually during zooming, possibly in scrollViewDidEndZooming
  CGSize newIntrinsicSizeOfPlayView = self.view.bounds.size;
  newIntrinsicSizeOfPlayView.width *= self.scrollView.zoomScale;
  newIntrinsicSizeOfPlayView.height *= self.scrollView.zoomScale;
  [self.playViewController.playView updateIntrinsicContentSize:newIntrinsicSizeOfPlayView];
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
  else if (scrollView == self.coordinateLabelsLetterViewScrollView)
    return self.coordinateLabelsLetterView;
  else if (scrollView == self.coordinateLabelsNumberViewScrollView)
    return self.coordinateLabelsNumberView;
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
  self.coordinateLabelsLetterViewScrollView.hidden = YES;
  self.coordinateLabelsNumberViewScrollView.hidden = YES;
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(float)scale
{
  DDLogVerbose(@"scrollViewDidEndZooming: new zoom scale = %f", scale);

  CGSize contentSize = scrollView.contentSize;
  DDLogVerbose(@"scrollViewDidEndZooming: new content size = %f / %f ",
               contentSize.width, contentSize.height);

  CGPoint contentOffset = scrollView.contentOffset;
  DDLogVerbose(@"scrollViewDidEndZooming: new content offset = %f / %f ",
               contentOffset.x, contentOffset.y);

  // TODO xxx Currently we assume that viewWillLayoutSubviews will always be
  // invoked after a zoom operation. Check if this is true, because we rely on
  // this mechanism to update the play view's intrinsic size. Possibly we should
  // update the intrinsic size already here.

  self.coordinateLabelsLetterViewScrollView.hidden = NO;
  self.coordinateLabelsNumberViewScrollView.hidden = NO;
  [self synchronizeZoomScale:self.scrollView.zoomScale
            minimumZoomScale:self.scrollView.minimumZoomScale
            maximumZoomScale:self.scrollView.maximumZoomScale];
  [self synchronizeContentOffset:contentOffset];
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
      if (self.scrollView.zoomScale < playViewModel.maximumZoomScale)
      {
        self.scrollView.maximumZoomScale = playViewModel.maximumZoomScale;
      }
      else
      {
        // The Play view is currently zoomed in more than the new maximum zoom
        // scale allows. The goal is to adjust the current zoom scale, and all
        // depending metrics, to the new maximum.
        // TODO xxx Currently we rely on UIScrollView to perform the proper
        // adjustments for us (e.g. downscale content size, content offset,
        // trigger viewWillLayoutSubviews so that the play view's intrinsic
        // size can be adjusted, trigger synchronizeContentOffset and
        // synchronizeZoomScale, and so on). Verify that the behaviour is
        // actually as desired.
        self.scrollView.maximumZoomScale = playViewModel.maximumZoomScale;
        CGPoint newContentOffset = self.scrollView.contentOffset;
        DDLogVerbose(@"%@: New content offset = %f / %f ",
                     self, newContentOffset.x, newContentOffset.y);
        CGSize newContentSize = self.scrollView.contentSize;
        DDLogVerbose(@"%@: New content size = %f / %f ",
                     self, newContentSize.width, newContentSize.height);
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
  CGPoint coordinateLabelsLetterViewScrollViewContentOffset = self.coordinateLabelsLetterViewScrollView.contentOffset;
  coordinateLabelsLetterViewScrollViewContentOffset.x = contentOffset.x;
  self.coordinateLabelsLetterViewScrollView.contentOffset = coordinateLabelsLetterViewScrollViewContentOffset;
  CGPoint coordinateLabelsNumberViewScrollViewContentOffset = self.coordinateLabelsNumberViewScrollView.contentOffset;
  coordinateLabelsNumberViewScrollViewContentOffset.y = contentOffset.y;
  self.coordinateLabelsNumberViewScrollView.contentOffset = coordinateLabelsNumberViewScrollViewContentOffset;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for synchronizing scroll view.
// -----------------------------------------------------------------------------
- (void) synchronizeZoomScale:(CGFloat)zoomScale
             minimumZoomScale:(CGFloat)minimumZoomScale
             maximumZoomScale:(CGFloat)maximumZoomScale
{
  self.coordinateLabelsLetterViewScrollView.zoomScale = zoomScale;
  self.coordinateLabelsLetterViewScrollView.minimumZoomScale = minimumZoomScale;
  self.coordinateLabelsLetterViewScrollView.maximumZoomScale = maximumZoomScale;
  self.coordinateLabelsNumberViewScrollView.zoomScale = zoomScale;
  self.coordinateLabelsNumberViewScrollView.minimumZoomScale = minimumZoomScale;
  self.coordinateLabelsNumberViewScrollView.maximumZoomScale = maximumZoomScale;
}

@end
