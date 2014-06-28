// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardTileView.h"
#import "BoardView.h"
#import "CoordinateLabelsTileView.h"
#import "../gesture/DoubleTapGestureController.h"
#import "../gesture/PanGestureController.h"
#import "../gesture/TapGestureController.h"
#import "../gesture/TwoFingerTapGestureController.h"
#import "../model/PlayViewMetrics.h"
#import "../model/PlayViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardViewController.
// -----------------------------------------------------------------------------
@interface BoardViewController()
@property(nonatomic, retain) BoardView* boardView;
@property(nonatomic, retain) TiledScrollView* coordinateLabelsLetterView;
@property(nonatomic, retain) TiledScrollView* coordinateLabelsNumberView;
@property(nonatomic, retain) PanGestureController* panGestureController;
@property(nonatomic, retain) TapGestureController* tapGestureController;
@property(nonatomic, retain) DoubleTapGestureController* doubleTapGestureController;
@property(nonatomic, retain) TwoFingerTapGestureController* twoFingerTapGestureController;
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
  self.boardView = nil;
  self.coordinateLabelsLetterView = nil;
  self.coordinateLabelsNumberView = nil;
  [self setupChildControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.boardView = nil;
  self.coordinateLabelsLetterView = nil;
  self.coordinateLabelsNumberView = nil;
  self.panGestureController = nil;
  self.tapGestureController = nil;
  self.doubleTapGestureController = nil;
  self.twoFingerTapGestureController = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.panGestureController = [[[PanGestureController alloc] init] autorelease];
  self.tapGestureController = [[[TapGestureController alloc] init] autorelease];
  self.doubleTapGestureController = [[[DoubleTapGestureController alloc] init] autorelease];
  self.twoFingerTapGestureController = [[[TwoFingerTapGestureController alloc] init] autorelease];
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
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createSubviews
{
  self.boardView = [[[BoardView alloc] initWithFrame:CGRectZero] autorelease];
  self.coordinateLabelsLetterView = [[[TiledScrollView alloc] initWithFrame:CGRectZero] autorelease];
  self.coordinateLabelsNumberView = [[[TiledScrollView alloc] initWithFrame:CGRectZero] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.boardView];
  [self.view addSubview:self.coordinateLabelsLetterView];
  [self.view addSubview:self.coordinateLabelsNumberView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;

  self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
  self.coordinateLabelsLetterView.translatesAutoresizingMaskIntoConstraints = NO;
  self.coordinateLabelsNumberView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.boardView];

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.coordinateLabelsLetterView, @"coordinateLabelsLetterView",
                                   self.coordinateLabelsNumberView, @"coordinateLabelsNumberView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-0-[coordinateLabelsLetterView]-0-|",
                            [NSString stringWithFormat:@"V:|-0-[coordinateLabelsLetterView(==%f)]", metrics.tileSize.height],
                            @"V:|-0-[coordinateLabelsNumberView]-0-|",
                            [NSString stringWithFormat:@"H:|-0-[coordinateLabelsNumberView(==%f)]", metrics.tileSize.width],
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  // The background image is quite large, so we don't use UIImage namedImage:()
  // because that method caches the image in the background. We don't need
  // caching because we only load the image once, so not using namedImage:()
  // saves us quite a bit of valuable memory.
  NSString* imagePath = [[NSBundle mainBundle] pathForResource:woodenBackgroundImageResource
                                                        ofType:nil];
  NSData* imageData = [NSData dataWithContentsOfFile:imagePath];
  UIImage* image = [UIImage imageWithData:imageData];
  self.view.backgroundColor = [UIColor colorWithPatternImage:image];

  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;

  self.boardView.backgroundColor = [UIColor clearColor];
  // TODO xxx should this really be YES? the no-tiling implementation used NO
  self.boardView.bouncesZoom = YES;
  self.boardView.delegate = self;
  self.boardView.minimumZoomScale = 1.0f;
  self.boardView.maximumZoomScale = 3.0f;
  self.boardView.dataSource = self;
  self.boardView.tileSize = metrics.tileSize;

  self.coordinateLabelsLetterView.backgroundColor = [UIColor clearColor];
  self.coordinateLabelsLetterView.dataSource = self;
  self.coordinateLabelsLetterView.tileSize = metrics.tileSize;
  self.coordinateLabelsLetterView.userInteractionEnabled = NO;

  self.coordinateLabelsNumberView.backgroundColor = [UIColor clearColor];
  self.coordinateLabelsNumberView.dataSource = self;
  self.coordinateLabelsNumberView.tileSize = metrics.tileSize;
  self.coordinateLabelsNumberView.userInteractionEnabled = NO;

  [self updateCoordinateLabelsVisibleState];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureControllers
{
  self.panGestureController.boardView = self.boardView;
  self.tapGestureController.boardView = self.boardView;
  self.doubleTapGestureController.scrollView = self.boardView;
  self.twoFingerTapGestureController.scrollView = self.boardView;
}

#pragma mark - viewWillLayoutSubviews

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This override exists to resize the scroll view content after a change to
/// the interface orientation.
// -----------------------------------------------------------------------------
- (void) viewDidLayoutSubviews
{
  // First prepare the new board geometry. This triggers a re-draw of all tiles.
  [self updatePlayViewMetricsRect];
  // Now prepare all scroll views with the new content size. The content size
  // is taken from the values in PlayViewMetrics.
  [self updateContentSize];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
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
  [tileView updateWithRow:row column:column];
  return tileView;
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
    [self synchronizeContentOffset];
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
- (void) scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(float)scale
{
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  // todo xxx we should not use the scale parameter after this line, because
  // playviewmetrics may have made some adjustments (snap-to, optimizing for
  // tile size, etc.)
  [metrics updateWithZoomScale:scale];

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
  [self updateContentSize];
  // todo xxx the content offset that we remembered above may no longer be
  // accurate because playViewmetrics may have made some adjustments to the
  // zoom scale. to fix this we either need to record the contentOffset in
  // playviewmetrics (so that the metrics can perform the adjustments on the
  // offset as well), or we need to adjust the content offset ourselves by
  // somehow calculating the difference between the original scale (scale
  // parameter) and the adjusted scale. in that case playviewmetrics must
  // provide us with the adjusted scale (zoomScale is the absolute scale).
  scrollView.contentOffset = contentOffset;

  [self synchronizeContentOffset];

  // Show coordinate labels that were temporarily hidden when the zoom
  // operation started
  [self updateCoordinateLabelsVisibleState];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) updateCoordinateLabelsVisibleState
{
  BOOL hidden;
  if (self.boardView.zooming)
  {
    hidden = YES;
  }
  else
  {
    PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
    hidden = playViewModel.displayCoordinates ? NO : YES;
  }
  self.coordinateLabelsLetterView.hidden = hidden;
  self.coordinateLabelsNumberView.hidden = hidden;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Updates the play view metrics rectangle, triggering a redraw in all tiles.
// -----------------------------------------------------------------------------
- (void) updatePlayViewMetricsRect
{
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  CGRect newPlayViewMetricsRect = CGRectZero;
  newPlayViewMetricsRect.size = self.view.bounds.size;
  newPlayViewMetricsRect.size.width *= metrics.zoomScale;
  newPlayViewMetricsRect.size.height *= metrics.zoomScale;
  [metrics updateWithRect:newPlayViewMetricsRect];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
///
/// Updates the content size of all scroll views to match the current values in
/// PlayViewMetrics.
// -----------------------------------------------------------------------------
- (void) updateContentSize
{
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  CGSize contentSize = metrics.rect.size;
  CGSize tileSize = metrics.tileSize;
  CGRect tileContainerViewFrame = CGRectZero;

  self.boardView.contentSize = contentSize;
  tileContainerViewFrame.size = self.boardView.contentSize;
  self.boardView.tileContainerView.frame = tileContainerViewFrame;

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
/// Synchronizes the coordinate label scroll views with the master scroll view.
// -----------------------------------------------------------------------------
- (void) synchronizeContentOffset
{
  CGPoint coordinateLabelsLetterViewContentOffset = self.coordinateLabelsLetterView.contentOffset;
  coordinateLabelsLetterViewContentOffset.x = self.boardView.contentOffset.x;
  self.coordinateLabelsLetterView.contentOffset = coordinateLabelsLetterViewContentOffset;
  CGPoint coordinateLabelsNumberViewContentOffset = self.coordinateLabelsNumberView.contentOffset;
  coordinateLabelsNumberViewContentOffset.y = self.boardView.contentOffset.y;
  self.coordinateLabelsNumberView.contentOffset = coordinateLabelsNumberViewContentOffset;
}

@end
