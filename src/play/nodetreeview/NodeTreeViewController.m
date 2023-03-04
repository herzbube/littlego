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
#import "NodeNumbersView.h"
#import "NodeTreeTileView.h"
#import "NodeTreeView.h"
#import "NodeTreeViewMetrics.h"
#import "NodeTreeViewTapGestureController.h"
#import "canvas/NodeTreeViewCanvas.h"
#import "layer/NodeTreeViewDrawingHelper.h"
#import "../gesture/DoubleTapGestureController.h"
#import "../gesture/TwoFingerTapGestureController.h"
#import "../model/NodeTreeViewModel.h"
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
@property(nonatomic, assign) bool darkBackground;
@property(nonatomic, retain) NodeTreeViewCanvas* nodeTreeViewCanvas;
@property(nonatomic, retain) NodeTreeViewMetrics* nodeTreeViewMetrics;
/// @brief Prevents unregistering by dealloc if registering hasn't happened
/// yet. Registering may not happen if the controller's view is never loaded.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, retain) NodeTreeView* nodeTreeView;
@property(nonatomic, retain) NodeNumbersView* nodeNumbersView;
@property(nonatomic, retain) NSArray* autoLayoutConstraintsWithoutNodeNumbersView;
@property(nonatomic, retain) NSArray* autoLayoutConstraintsWithNodeNumbersView;
@property(nonatomic, retain) NSLayoutConstraint* autoLayoutConstraintNodeNumbersViewHeight;
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
      darkBackground:(bool)darkBackground
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.nodeTreeViewModel = nodeTreeViewModel;
  self.darkBackground = darkBackground;
  self.nodeTreeViewCanvas = nil;
  self.nodeTreeViewMetrics = nil;
  self.notificationRespondersAreSetup = false;
  self.nodeTreeView = nil;
  self.nodeNumbersView = nil;
  self.autoLayoutConstraintsWithoutNodeNumbersView = nil;
  self.autoLayoutConstraintsWithNodeNumbersView = nil;
  self.autoLayoutConstraintNodeNumbersViewHeight = nil;
  self.visibleRectNeedsUpdate = false;
  [self setupChildControllers];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self.view removeFromSuperview];

  [self removeNotificationResponders];

  // We can't wait for dealloc to happen in NodeTreeView and NodeNumbersView
  // and their respective tile objects - dealloc will be invoked on these
  // objects long after NodeTreeViewMetrics and NodeTreeViewCanvas objects have
  // been deallocated (in fact long after super's dealloc has completed its
  // work), which would cause the removal of observer registrations to crash
  // the app. A previous attempt at keeping NodeTreeViewMetrics and
  // NodeTreeViewCanvas alive until observer registrations are removed via
  // dealloc failed, so the current solution is to explicitly perform unregister
  // here when we can guarantee that NodeTreeViewMetrics and NodeTreeViewCanvas
  // are still around.
  [self.nodeTreeViewMetrics removeNotificationResponders];
  [self.nodeTreeView removeNotificationResponders];
  [self.nodeNumbersView removeNotificationResponders];

  self.autoLayoutConstraintsWithoutNodeNumbersView = nil;
  self.autoLayoutConstraintsWithNodeNumbersView = nil;
  self.autoLayoutConstraintNodeNumbersViewHeight = nil;
  self.nodeTreeView = nil;
  self.nodeNumbersView = nil;
  self.doubleTapGestureController = nil;
  self.twoFingerTapGestureController = nil;
  self.nodeTreeViewTapGestureController = nil;

  self.nodeTreeViewMetrics = nil;
  self.nodeTreeViewCanvas = nil;
  self.nodeTreeViewModel = nil;

  [super dealloc];
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
  [self setupAutoLayoutConstraintsWithoutNodeNumbersView];
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
  self.nodeTreeViewMetrics = [[[NodeTreeViewMetrics alloc] initWithModel:self.nodeTreeViewModel
                                                                  canvas:self.nodeTreeViewCanvas
                                                         traitCollection:self.traitCollection
                                                          darkBackground:self.darkBackground] autorelease];
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
/// @brief Creates and adds auto layout constraints for layouting the controller
/// view's subviews when the node numbers view is not visible.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsWithoutNodeNumbersView
{
  self.nodeTreeView.translatesAutoresizingMaskIntoConstraints = NO;
  self.autoLayoutConstraintsWithoutNodeNumbersView = [AutoLayoutUtility fillSuperview:self.view withSubview:self.nodeTreeView];
}

// -----------------------------------------------------------------------------
/// @brief Removes and deallocates auto layout constraints for layouting the
/// controller view's subviews when the node numbers view is not visible.
// -----------------------------------------------------------------------------
- (void) removeAutoLayoutConstraintsWithoutNodeNumbersView
{
  if (! self.autoLayoutConstraintsWithoutNodeNumbersView)
    return;
  [self.view removeConstraints:self.autoLayoutConstraintsWithoutNodeNumbersView];
  self.autoLayoutConstraintsWithoutNodeNumbersView = nil;
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
  [self updateContentSizeInScrollViews];
}

#pragma mark - traitCollectionDidChange

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (@available(iOS 12.0, *))
  {
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
      [self updateColors];
  }
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
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(currentBoardPositionDidChange:) name:currentBoardPositionDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];

  [self.nodeTreeViewMetrics addObserver:self forKeyPath:@"canvasSize" options:0 context:NULL];
  [self.nodeTreeViewMetrics addObserver:self forKeyPath:@"displayNodeNumbers" options:0 context:NULL];
  [self.nodeTreeViewMetrics addObserver:self forKeyPath:@"condenseMoveNodes" options:0 context:NULL];
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
  [self.nodeTreeViewMetrics removeObserver:self forKeyPath:@"condenseMoveNodes"];
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
      tileView = [[[NodeTreeTileView alloc] initWithFrame:CGRectZero metrics:self.nodeTreeViewMetrics canvas:self.nodeTreeViewCanvas model:self.nodeTreeViewModel] autorelease];
    else if (tiledScrollView == self.nodeNumbersView)
      tileView = [[[NodeNumbersTileView alloc] initWithFrame:CGRectZero metrics:self.nodeTreeViewMetrics canvas:self.nodeTreeViewCanvas model:self.nodeTreeViewModel] autorelease];
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
/// @brief Creates or deallocates the node numbers view depending on the value
/// of the "display node numbers" user preference, and depending on whether the
/// current node tree view geometry allows node numbers to be displayed.
// -----------------------------------------------------------------------------
- (void) createOrDeallocNodeNumbersView
{
  if ([self nodeNumbersViewShouldExist])
  {
    if ([self nodeNumbersViewExists])
      return;
    Class nodeNumbersTileViewClass = [NodeNumbersTileView class];
    self.nodeNumbersView = [[[NodeNumbersView alloc] initWithFrame:CGRectZero tileViewClass:nodeNumbersTileViewClass] autorelease];
    [self.view addSubview:self.nodeNumbersView];
    [self removeAutoLayoutConstraintsWithoutNodeNumbersView];
    [self setupAutoLayoutConstraintsWithNodeNumbersView];
    [self configureNodeNumbersView:self.nodeNumbersView];
    [self updateContentSizeInNodeNumbersScrollView];
    [self updateContentOffsetInNodeNumbersScrollView];
  }
  else
  {
    if (! [self nodeNumbersViewExists])
      return;
    [self removeAutoLayoutConstraintsWithNodeNumbersView];
    [self setupAutoLayoutConstraintsWithoutNodeNumbersView];
    [self.nodeNumbersView removeFromSuperview];
    self.nodeNumbersView = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the node numbers view should exist.
// -----------------------------------------------------------------------------
- (bool) nodeNumbersViewShouldExist
{
  return self.nodeTreeViewMetrics.displayNodeNumbers && self.nodeTreeViewMetrics.nodeNumberStripHeight > 0.0f;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the node numbers view currently exists.
// -----------------------------------------------------------------------------
- (bool) nodeNumbersViewExists
{
  return (self.nodeNumbersView != nil);
}

// -----------------------------------------------------------------------------
/// @brief Creates and adds auto layout constraints for layouting the controller
/// view's subviews when the node numbers view is visible.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsWithNodeNumbersView
{
  self.nodeNumbersView.translatesAutoresizingMaskIntoConstraints = NO;

  NSArray* constraintsTuple = [self createNodeNumbersViewConstraints];
  self.autoLayoutConstraintsWithNodeNumbersView = constraintsTuple.firstObject;
  self.autoLayoutConstraintNodeNumbersViewHeight = constraintsTuple.lastObject;

  [self.view addConstraints:self.autoLayoutConstraintsWithNodeNumbersView];
  [self.view addConstraint:self.autoLayoutConstraintNodeNumbersViewHeight];
}

// -----------------------------------------------------------------------------
/// @brief Removes and deallocates auto layout constraints for layouting the
/// controller view's subviews when the node numbers view is visible.
// -----------------------------------------------------------------------------
- (void) removeAutoLayoutConstraintsWithNodeNumbersView
{
  if (! self.autoLayoutConstraintsWithNodeNumbersView)
    return;

  [self.view removeConstraints:self.autoLayoutConstraintsWithNodeNumbersView];
  [self.view removeConstraint:self.autoLayoutConstraintNodeNumbersViewHeight];

  self.autoLayoutConstraintsWithNodeNumbersView = nil;
  self.autoLayoutConstraintNodeNumbersViewHeight = nil;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns an array of auto layout constraints for
/// layouting coordinate labels views.
// -----------------------------------------------------------------------------
- (NSArray*) createNodeNumbersViewConstraints
{
  NSLayoutConstraint* nodeNumbersViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.nodeNumbersView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.nodeTreeViewMetrics.nodeNumberViewHeight];

  NSArray* otherConstraints;
  if (self.nodeTreeViewModel.nodeNumberViewIsOverlay)
  {
    NSArray* autoLayoutConstraintsNodeTreeView = [AutoLayoutUtility fillSuperview:self.view withSubview:self.nodeTreeView];
    NSArray* autoLayoutConstraintsNodeNumbersView = @[
      [NSLayoutConstraint constraintWithItem:self.nodeNumbersView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
      [NSLayoutConstraint constraintWithItem:self.nodeNumbersView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0],
      [NSLayoutConstraint constraintWithItem:self.nodeNumbersView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0],
    ];
    otherConstraints = [autoLayoutConstraintsNodeTreeView arrayByAddingObjectsFromArray:autoLayoutConstraintsNodeNumbersView];
  }
  else
  {
    NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
    NSMutableArray* visualFormats = [NSMutableArray array];

    viewsDictionary[@"nodeTreeView"] = self.nodeTreeView;
    viewsDictionary[@"nodeNumbersView"] = self.nodeNumbersView;

    [visualFormats addObject:@"H:|-0-[nodeNumbersView]-0-|"];
    [visualFormats addObject:@"H:|-0-[nodeTreeView]-0-|"];
    [visualFormats addObject:@"V:|-0-[nodeNumbersView]-0-[nodeTreeView]-0-|"];

    otherConstraints = [AutoLayoutUtility createConstraintsWithVisualFormats:visualFormats
                                                                       views:viewsDictionary];
  }

  return @[otherConstraints, nodeNumbersViewHeightConstraint];
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

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// If the node numbers view is visible, updates the Auto Layout constraint that
/// governs the view's height to match the height provided by
/// NodeTreeViewMetrics.
// -----------------------------------------------------------------------------
- (void) updateNodeNumbersHeightIfNecessary
{
  if (self.autoLayoutConstraintNodeNumbersViewHeight)
    self.autoLayoutConstraintNodeNumbersViewHeight.constant = self.nodeTreeViewMetrics.nodeNumberViewHeight;
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  self.visibleRectNeedsUpdate = true;
  [self delayedUpdate];
}

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
        [self performSelectorOnMainThread:@selector(updateContentSizeInScrollViews) withObject:nil waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(updateNodeNumbersHeightIfNecessary) withObject:nil waitUntilDone:YES];
      }
      else
      {
        [self updateContentSizeInScrollViews];
        [self updateNodeNumbersHeightIfNecessary];
      }
    }
    else if ([keyPath isEqualToString:@"displayNodeNumbers"] ||
             [keyPath isEqualToString:@"condenseMoveNodes"])
    {
      // The cell size in the node number view depends on the cell size of the
      // main view, which changes significantly when the the user preference
      // "condense move nodes" is toggled. Obviously, the user preference
      // "display node numbers" is also important.
      [self createOrDeallocNodeNumbersView];
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

  if (self.nodeTreeViewModel.focusMode == NodeTreeViewFocusModeDisabled)
    return;

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

  CGRect bounds = self.nodeTreeView.bounds;
  if (self.nodeTreeViewModel.focusMode != NodeTreeViewFocusModeMakeSelectedNodeCentered)
  {
    if (CGRectContainsRect(bounds, canvasRectOfAllSelectedNodePositions))
      return;
  }

  CGRect scrollToRect;
  if (self.nodeTreeViewModel.focusMode == NodeTreeViewFocusModeMakeSelectedNodeVisible)
  {
    CGFloat xOffset;
    CGFloat yOffset;

    CGFloat leftEdgeBoundsRect = CGRectGetMinX(bounds);
    CGFloat leftEdgeCanvasRect = CGRectGetMinX(canvasRectOfAllSelectedNodePositions);
    if (leftEdgeCanvasRect < leftEdgeBoundsRect)
    {
      xOffset = leftEdgeCanvasRect - leftEdgeBoundsRect;
    }
    else
    {
      CGFloat rightEdgeBoundsRect = CGRectGetMaxX(bounds);
      CGFloat rightEdgeCanvasRect = CGRectGetMaxX(canvasRectOfAllSelectedNodePositions);
      if (rightEdgeCanvasRect > rightEdgeBoundsRect)
        xOffset = rightEdgeCanvasRect - rightEdgeBoundsRect;
      else
        xOffset = 0.0f;
    }

    CGFloat topEdgeBoundsRect = CGRectGetMinY(bounds);
    CGFloat topEdgeCanvasRect = CGRectGetMinY(canvasRectOfAllSelectedNodePositions);
    if (topEdgeCanvasRect < topEdgeBoundsRect)
    {
      yOffset = topEdgeCanvasRect - topEdgeBoundsRect;
    }
    else
    {
      CGFloat bottomEdgeBoundsRect = CGRectGetMaxY(bounds);
      CGFloat bottomEdgeCanvasRect = CGRectGetMaxY(canvasRectOfAllSelectedNodePositions);
      if (bottomEdgeCanvasRect > bottomEdgeBoundsRect)
        yOffset = bottomEdgeCanvasRect - bottomEdgeBoundsRect;
      else
        yOffset = 0.0f;
    }

    scrollToRect = CGRectOffset(self.nodeTreeView.bounds, xOffset, yOffset);
  }
  else
  {
    scrollToRect = [UiUtilities rectWithSize:self.nodeTreeView.bounds.size
                              centeredInRect:canvasRectOfAllSelectedNodePositions];
  }

  [self.nodeTreeView scrollRectToVisible:scrollToRect animated:YES];
}

#pragma mark - User interface style handling (light/dark mode)

// -----------------------------------------------------------------------------
/// @brief Updates all kinds of colors to match the current
/// UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateColors
{
  [self.nodeTreeViewMetrics updateWithTraitCollection:self.traitCollection];

  [self.nodeTreeView updateColors];
  [self.nodeNumbersView updateColors];
}

@end
