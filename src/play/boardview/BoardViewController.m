// -----------------------------------------------------------------------------
// Copyright 2014-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewController.h"
#import "BoardAnimationController.h"
#import "BoardTileView.h"
#import "BoardView.h"
#import "CoordinateLabelsTileView.h"
#import "../gesture/BoardViewTapGestureController.h"
#import "../gesture/DoubleTapGestureController.h"
#import "../gesture/PanGestureController.h"
#import "../gesture/TwoFingerTapGestureController.h"
#import "../model/BoardSetupModel.h"
#import "../model/BoardViewMetrics.h"
#import "../model/BoardViewModel.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiSettingsModel.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardViewController.
// -----------------------------------------------------------------------------
@interface BoardViewController()
/// @brief Prevents unregistering by dealloc if registering hasn't happened
/// yet. Registering may not happen if the controller's view is never loaded.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, assign) bool viewDidLayoutSubviewsInProgress;
@property(nonatomic, retain) BoardView* boardView;
@property(nonatomic, retain) TiledScrollView* coordinateLabelsLetterView;
@property(nonatomic, retain) TiledScrollView* coordinateLabelsNumberView;
@property(nonatomic, retain) NSArray* coordinateLabelsViewConstraints;
@property(nonatomic, retain) PanGestureController* panGestureController;
@property(nonatomic, retain) BoardViewTapGestureController* boardViewTapGestureController;
@property(nonatomic, retain) DoubleTapGestureController* doubleTapGestureController;
@property(nonatomic, retain) TwoFingerTapGestureController* twoFingerTapGestureController;
@property(nonatomic, retain) BoardAnimationController* boardAnimationController;
@end


@implementation BoardViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardViewController object.
///
/// @note This is the designated initializer of BoardViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.notificationRespondersAreSetup = false;
  self.viewDidLayoutSubviewsInProgress = false;
  self.boardView = nil;
  self.coordinateLabelsLetterView = nil;
  self.coordinateLabelsNumberView = nil;
  self.coordinateLabelsViewConstraints = nil;
  [self setupChildControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.coordinateLabelsViewConstraints = nil;
  self.boardView = nil;
  self.coordinateLabelsLetterView = nil;
  self.coordinateLabelsNumberView = nil;
  self.panGestureController = nil;
  self.boardViewTapGestureController = nil;
  self.doubleTapGestureController = nil;
  self.twoFingerTapGestureController = nil;
  self.boardAnimationController = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.panGestureController = [[[PanGestureController alloc] init] autorelease];
  self.boardViewTapGestureController = [[[BoardViewTapGestureController alloc] init] autorelease];
  self.doubleTapGestureController = [[[DoubleTapGestureController alloc] init] autorelease];
  self.twoFingerTapGestureController = [[[TwoFingerTapGestureController alloc] init] autorelease];
  self.boardAnimationController = [[[BoardAnimationController alloc] init ] autorelease];
}

#pragma mark - loadView and helpers

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self createSubviews];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureViews];
  [self configureControllers];
  [self setupNotificationResponders];
  [self updateDoubleTapToZoomEnabled];

  [self createOrDeallocCoordinateLabelsViews];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createSubviews
{
  self.boardView = [[[BoardView alloc] initWithFrame:CGRectZero] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.boardView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.boardView];

  CGFloat minimumBoardViewHeight = [ApplicationDelegate sharedDelegate].boardViewModel.minimumBoardViewHeight;
  [AutoLayoutUtility setMinimumConstraint:self.boardView
                                attribute:NSLayoutAttributeHeight
                             withConstant:minimumBoardViewHeight
                         constraintHolder:self.boardView.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;

  self.boardView.backgroundColor = [UIColor clearColor];
  self.boardView.delegate = self;
  // After an interface orientation change the board may already be zoomed
  // (e.g. iPhone 6+), so we have to take the current absolute zoom scale into
  // account
  self.boardView.minimumZoomScale = metrics.minimumAbsoluteZoomScale / metrics.absoluteZoomScale;
  self.boardView.maximumZoomScale = metrics.maximumAbsoluteZoomScale / metrics.absoluteZoomScale;
  self.boardView.dataSource = self;
  self.boardView.tileSize = metrics.tileSize;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureControllers
{
  self.panGestureController.boardView = self.boardView;
  self.boardViewTapGestureController.boardView = self.boardView;
  self.doubleTapGestureController.scrollView = self.boardView;
  self.twoFingerTapGestureController.scrollView = self.boardView;
  self.boardAnimationController.boardView = self.boardView;
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
  // First prepare the new board geometry. This triggers a re-draw of all tiles.
  [self updateBaseSizeInBoardViewMetrics];
  // Now prepare all scroll views with the new content size. The content size
  // is taken from the values in BoardViewMetrics.
  [self updateContentSizeInMainScrollView];
  [self updateContentSizeInCoordinateLabelsScrollViews];
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
  [center addObserver:self selector:@selector(uiAreaPlayModeDidChange:) name:uiAreaPlayModeDidChange object:nil];

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardViewMetrics* metrics = appDelegate.boardViewMetrics;
  [metrics addObserver:self forKeyPath:@"canvasSize" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"boardSize" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"displayCoordinates" options:0 context:NULL];
  [appDelegate.boardSetupModel addObserver:self forKeyPath:@"doubleTapToZoom" options:0 context:NULL];
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

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardViewMetrics* metrics = appDelegate.boardViewMetrics;
  [metrics removeObserver:self forKeyPath:@"canvasSize"];
  [metrics removeObserver:self forKeyPath:@"boardSize"];
  [metrics removeObserver:self forKeyPath:@"displayCoordinates"];
  [appDelegate.boardSetupModel removeObserver:self forKeyPath:@"doubleTapToZoom"];
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
    if (tiledScrollView == self.boardView)
      tileView = [[[BoardTileView alloc] initWithFrame:CGRectZero] autorelease];
    else if (tiledScrollView == self.coordinateLabelsLetterView)
      tileView = [[[CoordinateLabelsTileView alloc] initWithFrame:CGRectZero axis:CoordinateLabelAxisLetter] autorelease];
    else if (tiledScrollView == self.coordinateLabelsNumberView)
      tileView = [[[CoordinateLabelsTileView alloc] initWithFrame:CGRectZero axis:CoordinateLabelAxisNumber] autorelease];
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
  // Coordinate label scroll views are not visible during zooming, so we don't
  // need to synchronize
  if (! scrollView.zooming)
    [self updateContentOffsetInCoordinateLabelsScrollViews];
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
  return self.boardView.tileContainerView;
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewWillBeginZooming:(UIScrollView*)scrollView withView:(UIView*)view
{
  // Temporarily hide coordinate labels while a zoom operation is in progress.
  // Synchronizing coordinate label scroll views' zoom scale, content offset
  // and frame size while the zoom operation is in progress is a lot of effort,
  // and even though the views are zoomed formally correct the end result looks
  // like shit (because the labels are not part of the BoardView they zoom
  // differently). So instead of trying hard and failing we just dispense with
  // the effort.
  [self updateCoordinateLabelsVisibleState];
}

// -----------------------------------------------------------------------------
/// @brief UIScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(CGFloat)scale
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  CGFloat oldAbsoluteZoomScale = metrics.absoluteZoomScale;
  [metrics updateWithRelativeZoomScale:scale];

  // updateWithRelativeZoomScale:() may have adjusted the absolute zoom scale
  // in a way that makes the original value of the scale parameter obsolete.
  // We therefore calculate a new, correct value.
  CGFloat newAbsoluteZoomScale = metrics.absoluteZoomScale;
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
  [self updateContentSizeInMainScrollView];
  [self updateContentSizeInCoordinateLabelsScrollViews];
  // TODO The content offset that we remembered above may no longer be
  // accurate because BoardViewMetrics may have made some adjustments to the
  // zoom scale. To fix this we either need to record the contentOffset in
  // BoardViewMetrics (so that the metrics can perform the adjustments on the
  // offset as well), or we need to adjust the content offset ourselves by
  // somehow calculating the difference between the original scale (scale
  // parameter) and the adjusted scale. In that case BoardViewMetrics must
  // provide us with the adjusted scale (zoomScale is the absolute scale).
  scrollView.contentOffset = contentOffset;

  [self updateContentOffsetInCoordinateLabelsScrollViews];

  // Show coordinate labels that were temporarily hidden when the zoom
  // operation started
  [self updateCoordinateLabelsVisibleState];
}

#pragma mark - Manage coordinate labels views

// -----------------------------------------------------------------------------
/// @brief Creates or deallocates coordinate labels views depending on the value
/// of the "display coordinates" user preference, and depending on whether the
/// current board geometry allows coordinate labels to be displayed.
///
/// On devices with small screens, coordinate labels are not displayed for
/// large board sizes, unless the board is zoomed in.
// -----------------------------------------------------------------------------
- (void) createOrDeallocCoordinateLabelsViews
{
  if ([self coordinateLabelsViewsShouldExist])
  {
    if ([self coordinateLabelsViewsExist])
      return;
    Class coordinateLabelsTileViewClass = [CoordinateLabelsTileView class];
    self.coordinateLabelsLetterView = [[[TiledScrollView alloc] initWithFrame:CGRectZero tileViewClass:coordinateLabelsTileViewClass] autorelease];
    self.coordinateLabelsNumberView = [[[TiledScrollView alloc] initWithFrame:CGRectZero tileViewClass:coordinateLabelsTileViewClass] autorelease];
    [self.view addSubview:self.coordinateLabelsLetterView];
    [self.view addSubview:self.coordinateLabelsNumberView];
    [self addCoordinateLabelsViewConstraints];
    [self configureCoordinateLabelsView:self.coordinateLabelsLetterView];
    [self configureCoordinateLabelsView:self.coordinateLabelsNumberView];
    [self updateContentSizeInCoordinateLabelsScrollViews];
    [self updateContentOffsetInCoordinateLabelsScrollViews];
  }
  else
  {
    if (! [self coordinateLabelsViewsExist])
      return;
    [self removeCoordinateLabelsViewConstraints];
    [self.coordinateLabelsLetterView removeFromSuperview];
    [self.coordinateLabelsNumberView removeFromSuperview];
    self.coordinateLabelsLetterView = nil;
    self.coordinateLabelsNumberView = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if coordinate labels views should exist.
// -----------------------------------------------------------------------------
- (bool) coordinateLabelsViewsShouldExist
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  if (! metrics.displayCoordinates)
    return false;
  return (metrics.coordinateLabelStripWidth > 0.0f);
}

// -----------------------------------------------------------------------------
/// @brief Returns true if coordinate labels views currently exist.
// -----------------------------------------------------------------------------
- (bool) coordinateLabelsViewsExist
{
  return (self.coordinateLabelsLetterView != nil);
}

// -----------------------------------------------------------------------------
/// @brief Creates and adds auto layout constraints for layouting coordinate
/// labels views.
// -----------------------------------------------------------------------------
- (void) addCoordinateLabelsViewConstraints
{
  self.coordinateLabelsLetterView.translatesAutoresizingMaskIntoConstraints = NO;
  self.coordinateLabelsNumberView.translatesAutoresizingMaskIntoConstraints = NO;
  self.coordinateLabelsViewConstraints = [self createCoordinateLabelsViewConstraints];
  [self.view addConstraints:self.coordinateLabelsViewConstraints];
}

// -----------------------------------------------------------------------------
/// @brief Removes and deallocates auto layout constraints for layouting
/// coordinate labels views.
// -----------------------------------------------------------------------------
- (void) removeCoordinateLabelsViewConstraints
{
  if (! self.coordinateLabelsViewConstraints)
    return;
  [self.view removeConstraints:self.coordinateLabelsViewConstraints];
  self.coordinateLabelsViewConstraints = nil;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns an array of auto layout constraints for
/// layouting coordinate labels views.
// -----------------------------------------------------------------------------
- (NSArray*) createCoordinateLabelsViewConstraints
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  return [NSArray arrayWithObjects:
          [NSLayoutConstraint constraintWithItem:self.coordinateLabelsLetterView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.coordinateLabelsLetterView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.coordinateLabelsLetterView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.coordinateLabelsLetterView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:metrics.tileSize.height],

          [NSLayoutConstraint constraintWithItem:self.coordinateLabelsNumberView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.coordinateLabelsNumberView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:metrics.tileSize.width],
          [NSLayoutConstraint constraintWithItem:self.coordinateLabelsNumberView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.coordinateLabelsNumberView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
          nil];
}

// -----------------------------------------------------------------------------
/// @brief Configures the specified coordinate labels view after it was created.
// -----------------------------------------------------------------------------
- (void) configureCoordinateLabelsView:(TiledScrollView*)coordinateLabelsView
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  coordinateLabelsView.backgroundColor = [UIColor clearColor];
  coordinateLabelsView.dataSource = self;
  coordinateLabelsView.tileSize = metrics.tileSize;
  coordinateLabelsView.userInteractionEnabled = NO;
}

// -----------------------------------------------------------------------------
/// @brief Hides coordinate labels views while a zoom operation is in progress.
/// Shows the views while no zooming is in progress. Does nothing if the views
/// currently do not exist.
// -----------------------------------------------------------------------------
- (void) updateCoordinateLabelsVisibleState
{
  if (! [self coordinateLabelsViewsExist])
    return;
  BOOL hidden = self.boardView.zooming;
  self.coordinateLabelsLetterView.hidden = hidden;
  self.coordinateLabelsNumberView.hidden = hidden;
}

#pragma mark - Private helpers - Manage double-tap to zoom

// -----------------------------------------------------------------------------
/// @brief Updates whether the double-tap gesture to zoom is enabled.
// -----------------------------------------------------------------------------
- (void) updateDoubleTapToZoomEnabled
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];

  if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeBoardSetup)
    self.doubleTapGestureController.tappingEnabled = appDelegate.boardSetupModel.doubleTapToZoom;
  else
    self.doubleTapGestureController.tappingEnabled = true;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Updates the BoardViewMetrics object's content size, triggering a redraw in
/// all tiles.
// -----------------------------------------------------------------------------
- (void) updateBaseSizeInBoardViewMetrics
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  [metrics updateWithBaseSize:self.view.bounds.size];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Updates the content size of all scroll views to match the current values in
/// BoardViewMetrics.
// -----------------------------------------------------------------------------
- (void) updateContentSizeInMainScrollView
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  CGSize contentSize = metrics.canvasSize;
  CGRect tileContainerViewFrame = CGRectZero;
  tileContainerViewFrame.size = contentSize;

  self.boardView.contentSize = contentSize;
  self.boardView.tileContainerView.frame = tileContainerViewFrame;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Updates the coordinate label scroll views's content size to match current
/// values from BoardViewMetrics.
// -----------------------------------------------------------------------------
- (void) updateContentSizeInCoordinateLabelsScrollViews
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  CGSize contentSize = metrics.canvasSize;
  CGSize tileSize = metrics.tileSize;
  CGRect tileContainerViewFrame = CGRectZero;

  self.coordinateLabelsLetterView.contentSize = CGSizeMake(contentSize.width, tileSize.height);
  tileContainerViewFrame.size = self.coordinateLabelsLetterView.contentSize;
  self.coordinateLabelsLetterView.tileContainerView.frame = tileContainerViewFrame;

  self.coordinateLabelsNumberView.contentSize = CGSizeMake(tileSize.width, contentSize.height);
  tileContainerViewFrame.size = self.coordinateLabelsNumberView.contentSize;
  self.coordinateLabelsNumberView.tileContainerView.frame = tileContainerViewFrame;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Synchronizes the coordinate label scroll views' content offset with the
/// master scroll view.
// -----------------------------------------------------------------------------
- (void) updateContentOffsetInCoordinateLabelsScrollViews
{
  CGPoint coordinateLabelsLetterViewContentOffset = self.coordinateLabelsLetterView.contentOffset;
  coordinateLabelsLetterViewContentOffset.x = self.boardView.contentOffset.x;
  self.coordinateLabelsLetterView.contentOffset = coordinateLabelsLetterViewContentOffset;
  CGPoint coordinateLabelsNumberViewContentOffset = self.coordinateLabelsNumberView.contentOffset;
  coordinateLabelsNumberViewContentOffset.y = self.boardView.contentOffset.y;
  self.coordinateLabelsNumberView.contentOffset = coordinateLabelsNumberViewContentOffset;
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #uiAreaPlayModeDidChange notification.
// -----------------------------------------------------------------------------
- (void) uiAreaPlayModeDidChange:(NSNotification*)notification
{
  [self updateDoubleTapToZoomEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];

  if (object == appDelegate.boardViewMetrics)
  {
    if ([keyPath isEqualToString:@"canvasSize"] ||
        [keyPath isEqualToString:@"boardSize"] ||
        [keyPath isEqualToString:@"displayCoordinates"])
    {
      // Coordinate labels views depend on the coordinate label strip width,
      // which may change significantly when the board geometry changes (rect
      // and boardSize properties). Obviously, the displayCoordinates property
      // is als important.
      if ([NSThread currentThread] != [NSThread mainThread])
      {
        // Make sure that our handler executes on the main thread because it
        // creates or deallocates views and generally calls thread-unsafe UIKit
        // functions. A KVO notification can come in on a secondary thread when
        // a game is loaded from the archive, or when a game is restored during
        // app launch.
        [self performSelectorOnMainThread:@selector(createOrDeallocCoordinateLabelsViews) withObject:nil waitUntilDone:NO];
      }
      else
      {
        if (self.viewDidLayoutSubviewsInProgress)
        {
          // UIKit sometimes crashes if we add coordinate labels while a
          // layouting cycle is in progress. The crash happens if 1) the app
          // starts up and initially displays some other than the Play UI area,
          // the 2) the user switches to the Play UI area. At this moment
          // viewDidLayoutSubviews is executed, it invokes
          // updateBaseSizeInBoardViewMetrics, which in turn triggers this
          // KVO observer. If we now add coordinate labels, the app crashes. The
          // exact reason for the crash is unknown, but probable causes are
          // either adding subviews, or adding constraints, in the middle of a
          // layouting cycle. The workaround is to add a bit of asynchrony.
          [self performSelector:@selector(createOrDeallocCoordinateLabelsViews) withObject:nil afterDelay:0];
        }
        else
        {
          [self createOrDeallocCoordinateLabelsViews];
        }
      }
    }
  }
  else if (object == appDelegate.boardSetupModel)
  {
    if ([keyPath isEqualToString:@"doubleTapToZoom"])
      [self updateDoubleTapToZoomEnabled];
  }
}

@end
