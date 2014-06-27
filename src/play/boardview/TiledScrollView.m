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
#import "TiledScrollView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TiledScrollView.
// -----------------------------------------------------------------------------
@interface TiledScrollView()
// Public property is readonly, we re-declare it here as readwrite
@property(nonatomic, retain, readwrite) UIView* tileContainerView;
/// @brief Tile views that are no longer visible are placed into this container.
@property(nonatomic, retain) NSMutableSet* reusableTiles;
@property(nonatomic, assign) int indexOfFirstVisibleRow;
@property(nonatomic, assign) int indexOfFirstVisibleColumn;
@property(nonatomic, assign) int indexOfLastVisibleRow;
@property(nonatomic, assign) int indexOfLastVisibleColumn;
@end


@implementation TiledScrollView

// -----------------------------------------------------------------------------
/// @brief Initializes a TiledScrollView object with frame rectangle @a rect.
///
/// @note This is the designated initializer of TiledScrollView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIScrollView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;
  self.dataSource = nil;
  self.contentSize = self.frame.size;
  self.tileContainerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)] autorelease];
  [self addSubview:self.tileContainerView];
  self.tileSize = CGSizeZero;
  self.annotateTiles = false;
  self.reusableTiles = [[[NSMutableSet alloc] init] autorelease];
  self.indexOfFirstVisibleRow = NSIntegerMax;
  self.indexOfFirstVisibleColumn = NSIntegerMax;
  self.indexOfLastVisibleRow = NSIntegerMin;
  self.indexOfLastVisibleColumn  = NSIntegerMin;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TiledScrollView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.dataSource = nil;
  self.reusableTiles = nil;
  self.tileContainerView = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a tile view from the pool of reusable tile views. The caller
/// becomes responsible for the tile view. Returns nil if the pool of reusable
/// tile views is currently empty.
// -----------------------------------------------------------------------------
- (UIView*) dequeueReusableTileView
{
  UIView* tile = [self.reusableTiles anyObject];
  if (tile)
  {
    // For all that we know, self.reusableTiles is the only thing that still
    // retains the tile view. We must therefore make sure that the tile view
    // stays alive when we remove it from self.reusableTiles.
    [[tile retain] autorelease];
    [self.reusableTiles removeObject:tile];
  }
  return tile;
}

// -----------------------------------------------------------------------------
/// @brief Removes all visible tile views from the tile container view and
/// places them into the pool of reusable tile views. Content size and offset
/// remain the same. When the next layout cycle runs a full set of tile views
/// will be requested from the data source.
// -----------------------------------------------------------------------------
- (void) reloadData
{
  for (UIView* tile in [self.tileContainerView subviews])
  {
    [self.reusableTiles addObject:tile];
    [tile removeFromSuperview];
  }
  self.indexOfFirstVisibleRow = NSIntegerMax;
  self.indexOfFirstVisibleColumn = NSIntegerMax;
  self.indexOfLastVisibleRow = NSIntegerMin;
  self.indexOfLastVisibleColumn  = NSIntegerMin;
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// This override of layoutSubviews implements the actual tiling mechanism:
/// - Tile views for tiles that are no longer in the visible bounds
///   (self.bounds) are removed from the tile container view and placed into the
///   pool of reusable tile views.
/// - Tile views for tiles that are now in the visible bounds but that are
///   currently missing are requested from the data source.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [super layoutSubviews];

  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  // REMINDERS
  // - layoutSubviews is constantly invoked during zooming and scrolling
  // - While zoomed a transform is in effect on self.tileContainerView which
  //   causes the frame of the container view and of its tile views to be
  //   enlarged by the current zoom scale
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  // The bounds rectangle is the visible part of the (possibly zoomed) content
  // of the scroll view
  CGRect visibleBounds = self.bounds;

  // Check if any tiles are no longer visible
  for (UIView* tile in [self.tileContainerView subviews])
  {
    // In order to compare the tile view frame with our own visible bounds, we
    // must first convert the tile view frame into our own coordinate system.
    // Important: The tile view frame takes the current zoom scale into account
    // because of the transform that is in effect on self.tileContainerView.
    CGRect scaledTileFrame = [self.tileContainerView convertRect:tile.frame toView:self];
    if (! CGRectIntersectsRect(scaledTileFrame, visibleBounds))
    {
      [self.reusableTiles addObject:tile];
      [tile removeFromSuperview];
    }
  }

  // In order to compare the tile size with the transformed frame of
  // self.tileContainerView, we need to take the zoom scale into account
  CGFloat scaledTileWidth  = self.tileSize.width  * self.zoomScale;
  CGFloat scaledTileHeight = self.tileSize.height * self.zoomScale;

  // We take the container view size from its frame, not from its bounds, to
  // get the transformed size that takes the zoom scale into account
  CGSize tileContainerViewSize = self.tileContainerView.frame.size;
  int totalNumberOfRows = ceilf(tileContainerViewSize.height / scaledTileHeight);
  int totalNumberOfColumns = ceilf(tileContainerViewSize.width / scaledTileWidth);
  int maximumRowIndex = totalNumberOfRows - 1;
  int maximumColumnIndex = totalNumberOfColumns - 1;

  // Calculate the 0-based indexes of the tiles that we need
  int indexOfFirstNeededRow = MAX(0, floorf(visibleBounds.origin.y / scaledTileHeight));
  int indexOfFirstNeededCol = MAX(0, floorf(visibleBounds.origin.x / scaledTileWidth));
  // The -1.0f adjustment makes sure that we don't get one tile too many if the
  // right and/or bottom edge of visibleBounds is exactly aligned with the right
  // and/or bottom edge of a tile. Example:
  // - Tile size = 128,128
  // - visibleBounds = 0,0,128,128
  // - In other words: The visible bounds displays exactly 1 tile
  // - The value for indexOfLastNeededRow and indexOfLastNeededColumn is
  //   therefore expected to be 0 (because they hold 0-based index values)
  // - CGRectGetMaxX(visibleBounds) and CGRectGetMaxY(visibleBounds) will both
  //   give us 128
  // - Without the -1.0f adjustment, the division would be floorf(128 / 128) = 1
  // - In other words: indexOfLastNeededRow and indexOfLastNeededColumn would
  //   get values that are 1 too high
  // - With the -1.0f adjustment, the division is floorf(127 / 128) = 0
  // - The -1.0f adjustment therefore compensates for the results of
  //   CGRectGetMaxX and CGRectGetMaxY
  int indexOfLastNeededRow = MIN(maximumRowIndex, floorf((CGRectGetMaxY(visibleBounds) - 1.0f) / scaledTileHeight));
  int indexOfLastNeededColumn = MIN(maximumColumnIndex, floor((CGRectGetMaxX(visibleBounds) - 1.0f) / scaledTileWidth));


  // Acquire any tiles that are missing from the data source and add them to
  // self.tileContainerView
  for (int rowIndex = indexOfFirstNeededRow; rowIndex <= indexOfLastNeededRow; ++rowIndex)
  {
    for (int columnIndex = indexOfFirstNeededCol; columnIndex <= indexOfLastNeededColumn; ++columnIndex)
    {
      bool tileIsMissing = (self.indexOfFirstVisibleRow > rowIndex || self.indexOfFirstVisibleColumn > columnIndex ||
                            self.indexOfLastVisibleRow  < rowIndex || self.indexOfLastVisibleColumn  < columnIndex);
      if (tileIsMissing)
      {
        UIView* tileView = [self.dataSource tiledScrollView:self
                                             tileViewForRow:rowIndex
                                                     column:columnIndex];
        // Use the unscaled tile size to construct the tile view frame. The
        // transform on self.tileContainerView will take care of any scaling.
        CGRect tileViewFrame = CGRectMake(self.tileSize.width * columnIndex,
                                          self.tileSize.height * rowIndex,
                                          self.tileSize.width,
                                          self.tileSize.height);
        tileView.frame = tileViewFrame;
        [self.tileContainerView addSubview:tileView];
        if (self.annotateTiles)
          [self annotateTileView:tileView];
      }
    }
  }

  // Remember which tiles are visible
  self.indexOfFirstVisibleRow = indexOfFirstNeededRow;
  self.indexOfFirstVisibleColumn = indexOfFirstNeededCol;
  self.indexOfLastVisibleRow = indexOfLastNeededRow;
  self.indexOfLastVisibleColumn = indexOfLastNeededColumn;
}


// -----------------------------------------------------------------------------
/// @brief Annotates the specified tile view to make it visible. This is a
/// debugging aid. See the @e annotateTiles property documentation.
// -----------------------------------------------------------------------------
- (void) annotateTileView:(UIView*)tileView
{
  static int totalTiles = 0;
  static const int labelTag = 999;

  // The presence of an annotation label indicates that this is not a new tile
  UILabel* label = (UILabel*)[tileView viewWithTag:labelTag];
  if (! label)
  {
    totalTiles++;
    UILabel* label = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 80, 50)] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.tag = labelTag;
    label.textColor = [UIColor greenColor];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(1.0f, 1.0f);
    label.font = [UIFont boldSystemFontOfSize:40];
    label.text = [NSString stringWithFormat:@"%d", totalTiles];
    [tileView addSubview:label];
    tileView.layer.borderWidth = 0.5f;
    tileView.layer.borderColor = [[UIColor greenColor] CGColor];
  }
  [tileView bringSubviewToFront:label];
}

@end
