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
#import "NodeTreeViewController.h"
#import "NodeNumbersTileView.h"
#import "NodeTreeTileView.h"
#import "NodeTreeView.h"
#import "NodeTreeViewMetrics.h"
#import "NodeTreeViewTapGestureController.h"
#import "canvas/NodeTreeViewCanvas.h"
#import "layer/NodeTreeViewDrawingHelper.h"
#import "../gesture/DoubleTapGestureController.h"
#import "../gesture/TwoFingerTapGestureController.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/NSObjectAdditions.h"
// TODO xxx remove if no longer needed
//#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewController.
// -----------------------------------------------------------------------------
@interface NodeTreeViewController()
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
@property(nonatomic, retain) NodeTreeViewCanvas* nodeTreeViewCanvas;
@property(nonatomic, retain) NodeTreeViewMetrics* nodeTreeViewMetrics;
/// @brief Prevents unregistering by dealloc if registering hasn't happened
/// yet. Registering may not happen if the controller's view is never loaded.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, assign) bool viewDidLayoutSubviewsInProgress;
@property(nonatomic, retain) NodeTreeView* nodeTreeView;
@property(nonatomic, retain) TiledScrollView* nodeNumbersView;
@property(nonatomic, retain) NSArray* nodeNumbersViewConstraints;
@property(nonatomic, assign) bool visibleRectNeedsUpdate;
@property(nonatomic, retain) DoubleTapGestureController* doubleTapGestureController;
@property(nonatomic, retain) TwoFingerTapGestureController* twoFingerTapGestureController;
@property(nonatomic, retain) NodeTreeViewTapGestureController* nodeTreeViewTapGestureController;
@end


@implementation NodeTreeViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewController object.
///
/// @note This is the designated initializer of NodeTreeViewController.
// -----------------------------------------------------------------------------
- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.nodeTreeViewModel = nodeTreeViewModel;
  self.nodeTreeViewCanvas = nil;
  self.nodeTreeViewMetrics = nil;
  self.notificationRespondersAreSetup = false;
  self.viewDidLayoutSubviewsInProgress = false;
  self.nodeTreeView = nil;
  self.nodeNumbersView = nil;
  self.nodeNumbersViewConstraints = nil;
  self.visibleRectNeedsUpdate = false;
  [self setupChildControllers];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  self.nodeNumbersViewConstraints = nil;
  self.nodeTreeView = nil;
  self.nodeNumbersView = nil;
  self.doubleTapGestureController = nil;
  self.twoFingerTapGestureController = nil;
  self.nodeTreeViewTapGestureController = nil;

  NodeTreeViewMetrics* localReferenceMetrics = [_nodeTreeViewMetrics retain];
  NodeTreeViewCanvas* localReferenceCanvas = [_nodeTreeViewCanvas retain];

  self.nodeTreeViewMetrics = nil;
  self.nodeTreeViewCanvas = nil;
  self.nodeTreeViewModel = nil;

  // For unknown reasons NodeTreeView and its tiles are deallocated only when
  // super's dealloc is invoked. This means that at this point the
  // NodeTreeViewMetrics and NodeTreeViewCanvas objects must still live so that
  // tiles can remove their observer registrations. Explicitly setting
  // self.view to nil, or invoking [self.nodeTreeView removeFromSuperview],
  // did not help with deallocating NodeTreeView earlier.
  [super dealloc];

  // As per comment above: Deallocate the following two objects only after
  // views which depend on them have been deallocated. Deallocate the objects
  // in observer dependency order.
  [localReferenceMetrics release];
  [localReferenceCanvas release];
}

// -----------------------------------------------------------------------------
/// @brief Private helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.doubleTapGestureController = [[[DoubleTapGestureController alloc] init] autorelease];
  self.twoFingerTapGestureController = [[[TwoFingerTapGestureController alloc] init] autorelease];
  self.nodeTreeViewTapGestureController = [[[NodeTreeViewTapGestureController alloc] init] autorelease];
}

#pragma mark - loadView and helpers

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self createCanvasAndMetrics];
  [self createSubviews];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureViews];
  [self configureControllers];
  [self setupNotificationResponders];

  [self createOrDeallocNodeNumbersView];

  // Set the initial scroll position. Execution must be slightly delayed
  // (0.0 is not sufficient) if the node tree view is created later after the
  // app has already launched.
  [self performBlockOnMainThread:^{
    self.visibleRectNeedsUpdate = true;
    [self delayedUpdate];
  } afterDelay:0.1];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createCanvasAndMetrics
{
  self.nodeTreeViewCanvas = [[[NodeTreeViewCanvas alloc] initWithModel:self.nodeTreeViewModel] autorelease];
  [self.nodeTreeViewCanvas recalculateCanvas];
  self.nodeTreeViewMetrics = [[[NodeTreeViewMetrics alloc] initWithModel:self.nodeTreeViewModel canvas:self.nodeTreeViewCanvas] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createSubviews
{
  self.nodeTreeView = [[[NodeTreeView alloc] initWithFrame:CGRectZero nodeTreeViewMetrics:self.nodeTreeViewMetrics] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.nodeTreeView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.nodeTreeView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.nodeTreeView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  self.nodeTreeView.backgroundColor = [UIColor clearColor];
  self.nodeTreeView.delegate = self;
  self.nodeTreeView.minimumZoomScale = self.nodeTreeViewMetrics.minimumAbsoluteZoomScale / self.nodeTreeViewMetrics.absoluteZoomScale;
  self.nodeTreeView.maximumZoomScale = self.nodeTreeViewMetrics.maximumAbsoluteZoomScale / self.nodeTreeViewMetrics.absoluteZoomScale;
  self.nodeTreeView.dataSource = self;
  self.nodeTreeView.tileSize = self.nodeTreeViewMetrics.tileSize;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureControllers
{
  self.doubleTapGestureController.scrollView = self.nodeTreeView;
  self.twoFingerTapGestureController.scrollView = self.nodeTreeView;
  self.nodeTreeViewTapGestureController.nodeTreeView = self.nodeTreeView;
}

#pragma mark - viewDidLayoutSubviews

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This override exists to resize the scroll view content after a change to
/// the interface orientation.
// -----------------------------------------------------------------------------
- (void) viewDidLayoutSubviews
{
  self.viewDidLayoutSubviewsInProgress = true;
  [self updateContentSizeInScrollViews];
  self.viewDidLayoutSubviewsInProgress = false;
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  if (self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = true;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(currentBoardPositionDidChange:) name:currentBoardPositionDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];

  [self.nodeTreeViewMetrics addObserver:self forKeyPath:@"canvasSize" options:0 context:NULL];
  [self.nodeTreeViewMetrics addObserver:self forKeyPath:@"displayNodeNumbers" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  if (! self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = false;

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self.nodeTreeViewMetrics removeObserver:self forKeyPath:@"canvasSize"];
  [self.nodeTreeViewMetrics removeObserver:self forKeyPath:@"displayNodeNumbers"];
}

#pragma mark TiledScrollViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief TiledScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UIView*) tiledScrollView:(TiledScrollView*)tiledScrollView tileViewForRow:(int)row column:(int)column
{
  UIView<Tile>* tileView = (UIView<Tile>*)[tiledScrollView dequeueReusableTileView];
  if (! tileView)
  {
    // The scroll view will set the tile view frame, so we don't have to worry
    // about it
    if (tiledScrollView == self.nodeTreeView)
      tileView = [[[NodeTreeTileView alloc] initWithFrame:CGRectZero metrics:self.nodeTreeViewMetrics canvas:self.nodeTreeViewCanvas] autorelease];
    else if (tiledScrollView == self.nodeNumbersView)
      tileView = [[[NodeNumbersTileView alloc] initWithFrame:CGRectZero] autorelease];
  }
  tileView.row = row;
  tileView.column = column;
  return tileView;
}

// -----------------------------------------------------------------------------
/// @brief TiledScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tiledScrollViewZoomScaleAtZoomStart:(TiledScrollView*)tiledScrollView
{
  // When a zoom operation completes, this controllers always resets the scroll
  // view's zoom scale to 1.0. This means that a zoom will always start at zoom
  // scale 1.0.
  return 1.0;
}

#pragma mark UIScrollViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewDidScroll:(UIScrollView*)scrollView
{
  // The node number scroll view is not visible during zooming, so we don't
  // need to synchronize
  if (! scrollView.zooming)
    [self updateContentOffsetInNodeNumbersScrollView];
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
  return self.nodeTreeView.tileContainerView;
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewWillBeginZooming:(UIScrollView*)scrollView withView:(UIView*)view
{
  // Temporarily hide node numbers while a zoom operation is in progress.
  // Synchronizing the node numbers scroll view's zoom scale, content offset
  // and frame size while the zoom operation is in progress is a lot of effort,
  // and even though the view is zoomed formally correct the end result looks
  // like shit (because the numbers are not part of the NodeTreeView they zoom
  // differently). So instead of trying hard and failing we just dispense with
  // the effort.
  [self updateNodeNumbersVisibleState];
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(CGFloat)scale
{
  CGFloat oldAbsoluteZoomScale = self.nodeTreeViewMetrics.absoluteZoomScale;
  [self.nodeTreeViewMetrics updateWithRelativeZoomScale:scale];

  // updateWithRelativeZoomScale:() may have adjusted the absolute zoom scale
  // in a way that makes the original value of the scale parameter obsolete.
  // We therefore calculate a new, correct value.
  CGFloat newAbsoluteZoomScale = self.nodeTreeViewMetrics.absoluteZoomScale;
  scale = newAbsoluteZoomScale / oldAbsoluteZoomScale;

  // Remember content offset so that we can re-apply it after we reset the zoom
  // scale to 1.0. Note: The content size will be recalculated.
  CGPoint contentOffset = scrollView.contentOffset;

  // Big change here: This resets the scroll view's contentSize and
  // contentOffset, and also the tile container view's frame, bounds and
  // transform properties
  scrollView.zoomScale = 1.0f;
  // Adjust the minimum and maximum zoom scale so that the user cannot zoom
  // in/out more than originally intended
  scrollView.minimumZoomScale = scrollView.minimumZoomScale / scale;
  scrollView.maximumZoomScale = scrollView.maximumZoomScale / scale;

  // Restore properties that were changed when the zoom scale was reset to 1.0
  [self updateContentSizeInScrollViews];
  // TODO The content offset that we remembered above may no longer be
  // accurate because NodeTreeViewMetrics may have made some adjustments to the
  // zoom scale. To fix this we either need to record the contentOffset in
  // NodeTreeViewMetrics (so that the metrics can perform the adjustments on the
  // offset as well), or we need to adjust the content offset ourselves by
  // somehow calculating the difference between the original scale (scale
  // parameter) and the adjusted scale. In that case NodeTreeViewMetrics must
  // provide us with the adjusted scale (zoomScale is the absolute scale).
  scrollView.contentOffset = contentOffset;

  [self updateContentOffsetInNodeNumbersScrollView];

  // Show node numbers that were temporarily hidden when the zoom
  // operation started
  [self updateNodeNumbersVisibleState];
}

#pragma mark - Manage node numbers view

// -----------------------------------------------------------------------------
/// @brief Creates or deallocates the node numbers view depending on xxx
// -----------------------------------------------------------------------------
- (void) createOrDeallocNodeNumbersView
{
  if ([self nodeNumbersViewShouldExist])
  {
    if ([self nodeNumbersViewExists])
      return;
    Class nodeNumbersTileViewClass = [NodeNumbersTileView class];
    self.nodeNumbersView = [[[TiledScrollView alloc] initWithFrame:CGRectZero tileViewClass:nodeNumbersTileViewClass] autorelease];
    [self.view addSubview:self.nodeNumbersView];
    [self addNodeNumbersViewConstraints];
    [self configureNodeNumbersView:self.nodeNumbersView];
    [self updateContentSizeInNodeNumbersScrollView];
    [self updateContentOffsetInNodeNumbersScrollView];
  }
  else
  {
    if (! [self nodeNumbersViewExists])
      return;
    [self removeNodeNumbersViewConstraints];
    [self.nodeNumbersView removeFromSuperview];
    self.nodeNumbersView = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the node numbers view should exist.
// -----------------------------------------------------------------------------
- (bool) nodeNumbersViewShouldExist
{
  // TODO xxx remove
  return false;

  return self.nodeTreeViewMetrics.displayNodeNumbers;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the node numbers view currently exists.
// -----------------------------------------------------------------------------
- (bool) nodeNumbersViewExists
{
  return (self.nodeNumbersView != nil);
}

// -----------------------------------------------------------------------------
/// @brief Creates and adds auto layout constraints for layouting the node
/// numbers view.
// -----------------------------------------------------------------------------
- (void) addNodeNumbersViewConstraints
{
  self.nodeNumbersView.translatesAutoresizingMaskIntoConstraints = NO;
  self.nodeNumbersViewConstraints = [self createNodeNumbersViewConstraints];
  [self.view addConstraints:self.nodeNumbersViewConstraints];
}

// -----------------------------------------------------------------------------
/// @brief Removes and deallocates auto layout constraints for layouting the
/// node numbers view.
// -----------------------------------------------------------------------------
- (void) removeNodeNumbersViewConstraints
{
  if (! self.nodeNumbersViewConstraints)
    return;
  [self.view removeConstraints:self.nodeNumbersViewConstraints];
  self.nodeNumbersViewConstraints = nil;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns an array of auto layout constraints for
/// layouting coordinate labels views.
// -----------------------------------------------------------------------------
- (NSArray*) createNodeNumbersViewConstraints
{
  return [NSArray arrayWithObjects:
          [NSLayoutConstraint constraintWithItem:self.nodeNumbersView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.nodeNumbersView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.nodeNumbersView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.nodeNumbersView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.nodeTreeViewMetrics.tileSize.height],
          nil];
}

// -----------------------------------------------------------------------------
/// @brief Configures the specified coordinate labels view after it was created.
// -----------------------------------------------------------------------------
- (void) configureNodeNumbersView:(TiledScrollView*)nodeNumbersView
{
  nodeNumbersView.backgroundColor = [UIColor clearColor];
  nodeNumbersView.dataSource = self;
  nodeNumbersView.tileSize = self.nodeTreeViewMetrics.tileSize;
  nodeNumbersView.userInteractionEnabled = NO;
}

// -----------------------------------------------------------------------------
/// @brief Hides the nodenumbers view while a zoom operation is in progress.
/// Shows the view while no zooming is in progress. Does nothing if the view
/// currently does not exist.
// -----------------------------------------------------------------------------
- (void) updateNodeNumbersVisibleState
{
  if (! [self nodeNumbersViewExists])
    return;

  BOOL hidden = self.nodeTreeView.zooming;
  self.nodeNumbersView.hidden = hidden;
}

#pragma mark - Private helpers

// TODO xxx document
- (void) updateContentSizeInScrollViews
{
  // TODO xxx does changing the content size trigger a redraw?
  // If yes => this is bad because then we cannot optimize redrawing
  // If no => this is bad because no one triggers drawing
  [self updateContentSizeInMainScrollView];
  [self updateContentSizeInNodeNumbersScrollView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Updates the content size of all scroll views to match the current values in
/// NodeTreeViewMetrics.
// -----------------------------------------------------------------------------
- (void) updateContentSizeInMainScrollView
{
  CGSize contentSize = self.nodeTreeViewMetrics.canvasSize;
  CGRect tileContainerViewFrame = CGRectZero;
  tileContainerViewFrame.size = contentSize;

  self.nodeTreeView.contentSize = contentSize;
  self.nodeTreeView.tileContainerView.frame = tileContainerViewFrame;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Updates the node numbers scroll view's content size to match current
/// values from NodeTreeViewMetrics.
// -----------------------------------------------------------------------------
- (void) updateContentSizeInNodeNumbersScrollView
{
  if (! [self nodeNumbersViewExists])
    return;

  CGSize contentSize = self.nodeTreeViewMetrics.canvasSize;
  CGSize tileSize = self.nodeTreeViewMetrics.tileSize;
  CGRect tileContainerViewFrame = CGRectZero;

  self.nodeNumbersView.contentSize = CGSizeMake(contentSize.width, tileSize.height);
  tileContainerViewFrame.size = self.nodeNumbersView.contentSize;
  self.nodeNumbersView.tileContainerView.frame = tileContainerViewFrame;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Synchronizes the node numbers scroll view's content offset with the
/// master scroll view.
// -----------------------------------------------------------------------------
- (void) updateContentOffsetInNodeNumbersScrollView
{
  CGPoint nodeNumbersViewContentOffset = self.nodeNumbersView.contentOffset;
  nodeNumbersViewContentOffset.x = self.nodeTreeView.contentOffset.x;
  self.nodeNumbersView.contentOffset = nodeNumbersViewContentOffset;
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentBoardPositionDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentBoardPositionDidChange:(NSNotification*)notification
{
  self.visibleRectNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == self.nodeTreeViewMetrics)
  {
    if ([keyPath isEqualToString:@"canvasSize"])
    {
      if ([NSThread currentThread] != [NSThread mainThread])
      {
        // Make sure that our handler executes on the main thread because
        // changing the content size of views may trigger thread-unsafe UIKit
        // functions. A KVO notification can come in on a secondary thread when
        // a game is loaded from the archive, or when a game is restored during
        // app launch.
        [self performSelectorOnMainThread:@selector(updateContentSizeInScrollViews) withObject:nil waitUntilDone:NO];
      }
      else
      {
        if (self.viewDidLayoutSubviewsInProgress)
        {
          // TODO xxx review if this special handling during layouting is
          // necessary; cf. the origin of this in BoardViewController
          [self performSelector:@selector(updateContentSizeInScrollViews) withObject:nil afterDelay:0];
        }
        else
        {
          [self updateContentSizeInScrollViews];
        }
      }
    }
    else if ([keyPath isEqualToString:@"displayNodeNumbers"])
    {
      // TODO xxx review this entire branch => unlike the display coordinates
      // view in BoardView, the presence of the node numbers view is not
      // dependent on the content of GoGame, so it should be possible to
      // simplify the handling here
      if ([NSThread currentThread] != [NSThread mainThread])
      {
        // Make sure that our handler executes on the main thread because it
        // creates or deallocates views and generally calls thread-unsafe UIKit
        // functions. A KVO notification can come in on a secondary thread when
        // a game is loaded from the archive, or when a game is restored during
        // app launch.
        [self performSelectorOnMainThread:@selector(createOrDeallocNodeNumbersView) withObject:nil waitUntilDone:NO];
      }
      else
      {
        if (self.viewDidLayoutSubviewsInProgress)
        {
          // UIKit sometimes crashes if we add the node numbers view while a
          // layouting cycle is in progress. The crash happens if 1) the app
          // starts up and initially displays some other than the Play UI area,
          // then 2) the user switches to the Play UI area. At this moment
          // viewDidLayoutSubviews is executed, it invokes
          // updateBaseSizeInNodeTreeViewMetrics, which in turn triggers this
          // KVO observer. If we now add the node numbers view, the app crashes.
          // The exact reason for the crash is unknown, but probable causes are
          // either adding subviews, or adding constraints, in the middle of a
          // layouting cycle. The workaround is to add a bit of asynchrony.
          [self performSelector:@selector(createOrDeallocNodeNumbersView) withObject:nil afterDelay:0];
        }
        else
        {
          [self createOrDeallocNodeNumbersView];
        }
      }
    }
  }
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;

  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(delayedUpdate) withObject:nil waitUntilDone:YES];
    return;
  }

  [self updateVisibleRect];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
///
/// Programmatically scrolls the node tree view so that the canvas position that
/// displays the currently selected node becomes visible and centered within
/// the node tree view. Perfect centering may not possible because the desired
/// canvas position may be too close to the canvas edge(s) - if that happens
/// the node tree view is scrolled as best as possible.
// -----------------------------------------------------------------------------
- (void) updateVisibleRect
{
  if (! self.visibleRectNeedsUpdate)
    return;
  self.visibleRectNeedsUpdate = false;

  CGRect canvasRectOfAllSelectedNodePositions = CGRectZero;

  NSArray* selectedNodePositions = [self.nodeTreeViewCanvas selectedNodePositions];
  bool firstPosition = true;
  for (NodeTreeViewCellPosition* position in selectedNodePositions)
  {
    CGRect canvasRectOfPosition = [NodeTreeViewDrawingHelper canvasRectForCellAtPosition:position metrics:self.nodeTreeViewMetrics];
    if (firstPosition)
    {
      firstPosition = false;
      canvasRectOfAllSelectedNodePositions = canvasRectOfPosition;
    }
    else
    {
      canvasRectOfAllSelectedNodePositions = CGRectUnion(canvasRectOfAllSelectedNodePositions,
                                                         canvasRectOfPosition);
    }
  }

  CGRect scrollToRect = [UiUtilities rectWithSize:self.nodeTreeView.bounds.size
                                   centeredInRect:canvasRectOfAllSelectedNodePositions];

  [self.nodeTreeView scrollRectToVisible:scrollToRect animated:YES];
}

@end
