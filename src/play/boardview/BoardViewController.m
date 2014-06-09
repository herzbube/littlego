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
#import "../gesture/PanGestureController.h"
#import "../model/PlayViewMetrics.h"
#import "../../main/ApplicationDelegate.h"
#import "../../utility/UIColorAdditions.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardViewController.
// -----------------------------------------------------------------------------
@interface BoardViewController()
@property(nonatomic, retain) BoardView* boardView;
@property(nonatomic, retain) PanGestureController* panGestureController;
@end


@implementation BoardViewController

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
  self.panGestureController = [[[PanGestureController alloc] init] autorelease];
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardView = nil;
  self.panGestureController = nil;
  [super dealloc];
}

- (void)loadView
{
  [super loadView];

  // TODO xxx use CGRectZero and use Auto Layout
  self.boardView = [[[BoardView alloc] initWithFrame:self.view.bounds] autorelease];
  [self.view addSubview:self.boardView];

  self.boardView.dataSource = self;
  self.boardView.tileSize = CGSizeMake(128, 128);
  self.boardView.backgroundColor = [UIColor blackColor];
  self.boardView.bouncesZoom = YES;

  self.boardView.delegate = self;
  self.boardView.minimumZoomScale = 1.0f;
  self.boardView.maximumZoomScale = 3.0f;

  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:woodenBackgroundImageResource]];
  self.boardView.backgroundColor = [UIColor clearColor];

  self.panGestureController.boardView = self.boardView;
}

- (void) viewDidLayoutSubviews
{
  self.boardView.frame = self.view.bounds;
  self.boardView.tileContainerView.frame = self.boardView.bounds;
  self.boardView.contentSize = self.boardView.bounds.size;
  [[ApplicationDelegate sharedDelegate].playViewMetrics updateWithRect:self.boardView.bounds];
  [ApplicationDelegate sharedDelegate].playViewMetrics.tileSize = self.boardView.tileSize;
  
  NSLog(@"viewDidLayoutSubviews, tileSize = %@", NSStringFromCGSize(self.boardView.tileSize));
}

#pragma mark TiledScrollViewDataSource method

- (UIView*) boardView:(BoardView*)boardView boardTileViewForRow:(int)row column:(int)column
{
  // re-use a tile rather than creating a new one, if possible
  BoardTileView* tile = [self.boardView dequeueReusableTile];
  if (! tile)
  {
    // the scroll view will handle setting the tile's frame, so we don't have to worry about it
    tile = [[[BoardTileView alloc] initWithFrame:CGRectZero] autorelease];

    // Some of the tiles won't be completely filled, because they're on the right or bottom edge.
    // By default, the image would be stretched to fill the frame of the image view, but we don't
    // want this. Setting the content mode to "top left" ensures that the images around the edge are
    // positioned properly in their tiles.
    // TODO xxx is this necessary?
    tile.contentMode = UIViewContentModeTopLeft;

    //NSLog(@"creating new tile - %@", tile);
  }
  else
  {
    //NSLog(@"reusing tile - %@", tile);
  }

  tile.row = row;
  tile.column = column;
  //tile.backgroundColor = [UIColor randomColor];
  [tile redraw];

  return tile;
}

#pragma mark UIScrollViewDelegate

- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
  return self.boardView.tileContainerView;
}

- (void) scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(float)scale
{
  // todo xxx we should not use the scale parameter after this line, because
  // playviewmetrics may have made some adjustments (snap-to, optimizing for
  // tile size, etc.)
  [[ApplicationDelegate sharedDelegate].playViewMetrics updateWithZoomScale:scale];
  NSLog(@"scrollViewDidEndZooming: new absolute zoom scale = %f", [ApplicationDelegate sharedDelegate].playViewMetrics.zoomScale);

  CGPoint contentOffset = scrollView.contentOffset;
  CGSize  contentSize   = scrollView.contentSize;
  CGSize  containerSize = self.boardView.tileContainerView.frame.size;

   NSLog(@"scrollViewDidEndZooming,\n content size w = %f, h = %f,\n content offset x = %f,\n y = %f, container view w = %f, h = %f, \n board view transform = %@,\n container view transform = %@,\n first subview transform = %@",
         contentSize.width, contentSize.height,
         contentOffset.x, contentOffset.y,
         containerSize.width, containerSize.height,
         NSStringFromCGAffineTransform(self.boardView.transform),
         NSStringFromCGAffineTransform(self.boardView.tileContainerView.transform),
         NSStringFromCGAffineTransform(((UIView*)[[self.boardView.tileContainerView subviews] objectAtIndex:0]).transform));

  // Big change here: This resets the scroll view's contentSize and
  // contentOffset, and also the tile container view's frame, bounds and
  // transform properties
  scrollView.zoomScale = 1.0f;
  // Adjust the minimum and maximum zoom scale so that the user cannot zoom
  // in/out more than originally intended
  scrollView.minimumZoomScale = scrollView.minimumZoomScale / scale;
  scrollView.maximumZoomScale = scrollView.maximumZoomScale / scale;

  // restore content offset, content size, and container size
  // todo xxx we should get contentSize and containerSize (they should be equal)
  // from playviewmetrics because playViewmetrics may have made some
  // adjustments to the zoom scale, which would mean that the sizes we
  // remembered above are no longer accurate. more difficult is the content
  // offset, which might also be no longer accurate. to fix this we either need
  // to record the contentOffset in playviewmetrics (so that the metrics can
  // perform the adjustments on the offset as well), or we need to adjust the
  // content offset ourselves by somehow calculating the difference between the
  // original scale (scale parameter) and the adjusted scale. in that case
  // playviewmetrics must provide us with the adjusted scale (zoomScale is
  // the absolute scale).
  scrollView.contentOffset = contentOffset;
  scrollView.contentSize = contentSize;
  self.boardView.tileContainerView.frame = CGRectMake(0, 0, containerSize.width, containerSize.height);

  // throw out all tiles so they'll reload at the new resolution
  [self.boardView reloadData];

  /*xxx
  if (scrollView == self.boardView)
  {
    // after a zoom, check to see if we should change the resolution of our tiles
    [self updateResolution];
  }
   */
}

#pragma mark UIScrollView overrides

/*xxx
// the scrollViewDidEndZooming: delegate method is only called after an *animated* zoom. We also need to update our
// resolution for non-animated zooms. So we also override the new setZoomScale:animated: method on UIScrollView
- (void) setZoomScale:(float)scale animated:(BOOL)animated
{
  [super setZoomScale:scale animated:animated];

  // the delegate callback will catch the animated case, so just cover the non-animated case
  if (!animated) {
    [self updateResolution];
  }
}
*/

/*****************************************************************************************/
/* The following method handles changing the resolution of our tiles when our zoomScale  */
/* gets below 50% or above 100%. When we fall below 50%, we lower the resolution 1 step, */
/* and when we get above 100% we raise it 1 step. The resolution is stored as a power of */
/* 2, so -1 represents 50%, and 0 represents 100%, and so on.                            */
/*****************************************************************************************/
- (void)updateResolution
{
/* xxx
  // delta will store the number of steps we should change our resolution by. If we've fallen below
  // a 25% zoom scale, for example, we should lower our resolution by 2 steps so delta will equal -2.
  // (Provided that lowering our resolution 2 steps stays within the limit imposed by minimumResolution.)
  int delta = 0;

  // check if we should decrease our resolution
  for (int thisResolution = minimumResolution; thisResolution < resolution; thisResolution++) {
    int thisDelta = thisResolution - resolution;
    // we decrease resolution by 1 step if the zoom scale is <= 0.5 (= 2^-1); by 2 steps if <= 0.25 (= 2^-2), and so on
    float scaleCutoff = pow(2, thisDelta);
    if ([self zoomScale] <= scaleCutoff) {
      delta = thisDelta;
      break;
    }
  }

  // if we didn't decide to decrease the resolution, see if we should increase it
  if (delta == 0) {
    for (int thisResolution = maximumResolution; thisResolution > resolution; thisResolution--) {
      int thisDelta = thisResolution - resolution;
      // we increase by 1 step if the zoom scale is > 1 (= 2^0); by 2 steps if > 2 (= 2^1), and so on
      float scaleCutoff = pow(2, thisDelta - 1);
      if ([self zoomScale] > scaleCutoff) {
        delta = thisDelta;
        break;
      }
    }
  }

  if (delta != 0) {
    resolution += delta;

    // if we're increasing resolution by 1 step we'll multiply our zoomScale by 0.5; up 2 steps multiply by 0.25, etc
    // if we're decreasing resolution by 1 step we'll multiply our zoomScale by 2.0; down 2 steps by 4.0, etc
    float zoomFactor = pow(2, delta * -1);

    // save content offset, content size, and tileContainer size so we can restore them when we're done
    // (contentSize is not equal to containerSize when the container is smaller than the frame of the scrollView.)
    CGPoint contentOffset = [self contentOffset];
    CGSize  contentSize   = [self contentSize];
    CGSize  containerSize = [tileContainerView frame].size;

    // adjust all zoom values (they double as we cut resolution in half)
    [self setMaximumZoomScale:[self maximumZoomScale] * zoomFactor];
    [self setMinimumZoomScale:[self minimumZoomScale] * zoomFactor];
    [super setZoomScale:[self zoomScale] * zoomFactor];

    // restore content offset, content size, and container size
    [self setContentOffset:contentOffset];
    [self setContentSize:contentSize];
    [tileContainerView setFrame:CGRectMake(0, 0, containerSize.width, containerSize.height)];

    // throw out all tiles so they'll reload at the new resolution
    [self reloadData];
  }
 */
}

- (void) goGameDidCreate:(NSNotification*)notification
{
  [[ApplicationDelegate sharedDelegate].playViewMetrics updateWithBoardSize:[GoGame sharedGame].board.size];
}

@end
