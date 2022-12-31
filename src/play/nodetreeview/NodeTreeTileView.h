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
#import "../../ui/Tile.h"

// Forward declarations
@class NodeTreeViewCanvas;
@class NodeTreeViewMetrics;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeTileView class is a custom view that is responsible for
/// drawing only a small part (called a "tile") of the visible part of the
/// tree of nodes.
///
/// The tree of nodes is split into rectangular sections called "tiles". Each
/// instance of NodeTreeTileView draws one tile. NodeTreeTileView identifies the
/// tile to draw by looking at the @e row and @e column properties defined by
/// the Tile protocol. The tile size is defined by NodeTreeViewMetrics, as well
/// as the sizes of the different node tree elements to draw.
///
/// The view content is drawn in multiple CALayers that are stacked on top of
/// each other. Separating the drawing of different node tree elements into
/// different layers has the advantage that when an event occurs only those
/// layers, or layer parts, that are actually affected by the event need to be
/// redrawn. The drawback, of course, is that additional memory is required.
///
/// Two counter-measures are in effect to prevent excessive memory usage:
/// - A tiling mechanism makes sure that memory usage stays roughly the same
///   regardless of how far the tree of nodes is zoomed in. See the
///   documentation of the TiledScrollView class for more details.
/// - Layers are dynamically added and removed depending on application events
///   that require certain node tree elements to be displayed / not to be
///   displayed. TODO xxx Mention an example similar to the BoardTileView docs.
///
/// The layers of NodeTreeTileView draw all node tree elements except node
/// numbers. See the documentation of the NodeNumbersTileView class for more
/// details.
///
///
/// @par Delayed updates
///
/// NodeTreeTileView utilizes long-running actions to delay view updates. Events
/// that would normally trigger drawing updates are processed as normal, but the
/// drawing itself is delayed. When the #longRunningActionEnds notification
/// is received, all drawing updates that have accumulated are now coalesced
/// into a single update.
///
/// As a consequence, clients that want to update the view must invoke
/// delayedDrawLayers() instead of setNeedsDisplay(). Using delayedDrawLayers()
/// makes sure that the update occurs at the right time, either immediately, or
/// after a long-running action has ended.
///
///
/// @par Auto Layout
///
/// NodeTreeTileView is not a container view, i.e. it does not consist of
/// subviews but draws its own content. For the purposes of Auto Layout it
/// therefore has an intrinsic content size - its size is not derived from the
/// size of any views that it contains, but from the size of the content that
/// it is supposed to draw.
///
/// The intrinsic content size of NodeTreeTileView is equal to the size of the
/// tile that it draws. There currently are no known events that change the tile
/// size.
// -----------------------------------------------------------------------------
@interface NodeTreeTileView : UIView <Tile>
{
}

- (id) initWithFrame:(CGRect)rect
             metrics:(NodeTreeViewMetrics*)nodeTreeViewMetrics
              canvas:(NodeTreeViewCanvas*)nodeTreeViewCanvas;

@end
