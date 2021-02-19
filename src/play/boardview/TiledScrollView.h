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


// Forward declarations
@class TiledScrollView;


// -----------------------------------------------------------------------------
/// @brief The data source of TiledScrollView must adopt the
/// TiledScrollViewDataSource protocol.
// -----------------------------------------------------------------------------
@protocol TiledScrollViewDataSource <NSObject>
- (UIView*) tiledScrollView:(TiledScrollView*)tiledScrollView tileViewForRow:(int)row column:(int)column;
- (CGFloat) tiledScrollViewZoomScaleAtZoomStart:(TiledScrollView*)tiledScrollView;
@end


// -----------------------------------------------------------------------------
/// @brief The TiledScrollView class decomposes its content into tiles that all
/// have the same fixed size. When the user zooms in or out, each tile draws its
/// part of the content at the new resolution.
///
/// The purpose of tiling is to keep memory usage at a low level regardless of
/// the current zoom scale. This is achieved because TiledScrollView displays
/// only those tiles that are currently visible in its bounds rectangle. Given
/// a constant bounds size, TiledScrollView therefore never requires more than
/// a certain maximum number of tiles - which directly translates into a certain
/// maximum amount of memory to draw these tiles. Without tiling, at higher zoom
/// scales a single content view requires a large amount of memory to draw the
/// entire content, even those content parts that are currently not visible.
///
/// As tradeoff, tiling requires more CPU performance when the content is
/// scrolled, because tiles constantly need to be swapped in/out while the
/// visible bounds rectangle of TiledScrollView scrolls over the zoomed content.
/// TiledScrollView tries to strike a balance between memory and CPU usage by
/// placing tiles that are no longer visible into a "reusable queue" from where
/// they can be taken by TiledScrollViewDataSource when a new tile is requested.
/// This is the same mechanism as in the well-known class UITableView.
///
///
/// @par Maximum number of tiles
///
/// The maximum number of tiles is a function of
/// - The bounds size of TiledScrollView
/// - The tile size
///
/// The formula for calculating the maximum number of tiles is this:
///   ceilf(boundsSize.width / tileSize.width) * ceilf(boundsSize.height / tileSize.height)
///
///
/// @par Credits
///
/// This class is a complete rewrite of the TiledScrollView class from the
/// Tiling example in the ScrollViewSuite sample code project provided by
/// Apple. The original code included handling for switching between different
/// resolutions of an image, this handling is not present in this implementation
/// because the content displayed is not an image but a Go board drawn by
/// CoreGraphics.
///
/// The original demo code can be found here:
/// https://developer.apple.com/legacy/library/samplecode/ScrollViewSuite/Introduction/Intro.html
// -----------------------------------------------------------------------------
@interface TiledScrollView : UIScrollView
{
}

- (id) initWithFrame:(CGRect)rect tileViewClass:(Class)tileViewClass;

- (UIView*) dequeueReusableTileView;
- (void) reloadData;

/// @brief The data source for the TiledScrollView.
@property(nonatomic, assign) id<TiledScrollViewDataSource> dataSource;
/// @brief The view that is the superview of all tile views.
///
/// This property is exposed to facilitate zooming by a controller.
@property(nonatomic, retain, readonly) UIView* tileContainerView;
/// @brief The size of tile views.
///
/// A client that changes this property must invoke reloadData().
@property(nonatomic, assign) CGSize tileSize;
/// @brief Is false by default. Set this to true if tile views should be drawn
/// with a border and annotated with a label that shows the tile view's
/// creation "ID" (i.e. when a tile view is created, it is the n'th tile view).
///
/// This is a debugging aid to make tile boundaries visible, and to give an
/// indicator of how tiles are reused.
@property(nonatomic, assign) bool annotateTiles;

@end
