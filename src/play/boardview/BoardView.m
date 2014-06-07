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
#import "BoardView.h"
#import "BoardTileView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardView.
// -----------------------------------------------------------------------------
@interface BoardView()
@property(nonatomic, retain, readwrite) UIView* tileContainerView;
@property(nonatomic, retain) NSMutableSet* reusableTiles;
@property(nonatomic, assign) int firstVisibleRow;
@property(nonatomic, assign) int firstVisibleColumn;
@property(nonatomic, assign) int lastVisibleRow;
@property(nonatomic, assign) int lastVisibleColumn;
@end


@implementation BoardView

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardView object with frame rectangle @a rect.
///
/// @note This is the designated initializer of BoardView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIScrollView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  // Will be set to the correct size when the data source is configured
  self.contentSize = self.frame.size;

  self.dataSource = nil;

  // we will recycle tiles by removing them from the view and storing them here
  self.reusableTiles = [[[NSMutableSet alloc] init] autorelease];

  self.tileContainerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)] autorelease];
  [self addSubview:self.tileContainerView];

  // no rows or columns are visible at first; note this by making the firsts very high and the lasts very low
  self.firstVisibleRow = NSIntegerMax;
  self.firstVisibleColumn = NSIntegerMax;
  self.lastVisibleRow = NSIntegerMin;
  self.lastVisibleColumn  = NSIntegerMin;

  self.tileSize = CGSizeZero;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.dataSource = nil;
  self.reusableTiles = nil;
  self.tileContainerView = nil;
  [super dealloc];
}

- (BoardTileView*) dequeueReusableTile
{
  BoardTileView* tile = [self.reusableTiles anyObject];
  if (tile)
  {
    // the only object retaining the tile is our reusableTiles set, so we have to retain/autorelease it
    // before returning it so that it's not immediately deallocated when we remove it from the set
    [[tile retain] autorelease];
    [self.reusableTiles removeObject:tile];
  }
  return tile;
}

- (void) reloadData
{
  // recycle all tiles so that every tile will be replaced in the next layoutSubviews
  for (UIView* tile in [self.tileContainerView subviews])
  {
    [self.reusableTiles addObject:tile];
    [tile removeFromSuperview];
  }

  // no rows or columns are now visible; note this by making the firsts very high and the lasts very low
  self.firstVisibleRow = NSIntegerMax;
  self.firstVisibleColumn = NSIntegerMax;
  self.lastVisibleRow = NSIntegerMin;
  self.lastVisibleColumn  = NSIntegerMin;

  [self setNeedsLayout];
}

/***********************************************************************************/
/* Most of the work of tiling is done in layoutSubviews, which we override here.   */
/* We recycle the tiles that are no longer in the visible bounds of the scrollView */
/* and we add any tiles that should now be present but are missing.                */
/***********************************************************************************/
- (void) layoutSubviews
{
  [super layoutSubviews];

  CGRect visibleBounds = [self bounds];

  // first recycle all tiles that are no longer visible
  for (UIView* tile in [self.tileContainerView subviews])
  {
    // We want to see if the tiles intersect our (i.e. the scrollView's) bounds, so we need to convert their
    // frames to our own coordinate system
    CGRect scaledTileFrame = [self.tileContainerView convertRect:tile.frame toView:self];

    // If the tile doesn't intersect, it's not visible, so we can recycle it
    if (! CGRectIntersectsRect(scaledTileFrame, visibleBounds))
    {
      [self.reusableTiles addObject:tile];
      [tile removeFromSuperview];
    }
  }

  // calculate which rows and columns are visible by doing a bunch of math.
  float scaledTileWidth  = self.tileSize.width  * self.zoomScale;
  float scaledTileHeight = self.tileSize.height * self.zoomScale;
  int maxRow = floorf(self.tileContainerView.frame.size.height / scaledTileHeight); // this is the maximum possible row
  int maxCol = floorf(self.tileContainerView.frame.size.width / scaledTileWidth);  // and the maximum possible column
  int firstNeededRow = MAX(0, floorf(visibleBounds.origin.y / scaledTileHeight));
  int firstNeededCol = MAX(0, floorf(visibleBounds.origin.x / scaledTileWidth));
  int lastNeededRow  = MIN(maxRow, floorf(CGRectGetMaxY(visibleBounds) / scaledTileHeight));
  int lastNeededCol  = MIN(maxCol, floorf(CGRectGetMaxX(visibleBounds) / scaledTileWidth));

  // iterate through needed rows and columns, adding any tiles that are missing
  for (int row = firstNeededRow; row <= lastNeededRow; ++row)
  {
    for (int col = firstNeededCol; col <= lastNeededCol; ++col)
    {
      bool tileIsMissing = (self.firstVisibleRow > row || self.firstVisibleColumn > col ||
                            self.lastVisibleRow  < row || self.lastVisibleColumn  < col);
      if (tileIsMissing)
      {
        BoardTileView* tile = [self.dataSource boardView:self boardTileViewForRow:row column:col];

        // set the tile's frame so we insert it at the correct position
        CGRect tileFrame = CGRectMake(self.tileSize.width * col,
                                      self.tileSize.height * row,
                                      self.tileSize.width,
                                      self.tileSize.height);
        tile.frame = tileFrame;
        [self.tileContainerView addSubview:tile];

        // annotateTile draws green lines and tile numbers on the tiles for illustration purposes.
        [self annotateTile:tile];
      }
    }
  }

  // update our record of which rows/cols are visible
  self.firstVisibleRow = firstNeededRow;
  self.firstVisibleColumn = firstNeededCol;
  self.lastVisibleRow = lastNeededRow;
  self.lastVisibleColumn = lastNeededCol;
}

#define LABEL_TAG 3

- (void)annotateTile:(UIView*)tile
{
  return;
  static int totalTiles = 0;

  UILabel *label = (UILabel *)[tile viewWithTag:LABEL_TAG];
  if (!label) {
    totalTiles++;  // if we haven't already added a label to this tile, it's a new tile
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 80, 50)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTag:LABEL_TAG];
    [label setTextColor:[UIColor greenColor]];
    [label setShadowColor:[UIColor blackColor]];
    [label setShadowOffset:CGSizeMake(1.0, 1.0)];
    [label setFont:[UIFont boldSystemFontOfSize:40]];
    [label setText:[NSString stringWithFormat:@"%d", totalTiles]];
    [tile addSubview:label];
    [label release];
    [[tile layer] setBorderWidth:0.5];
    [[tile layer] setBorderColor:[[UIColor greenColor] CGColor]];
  }

  [tile bringSubviewToFront:label];
}


@end
