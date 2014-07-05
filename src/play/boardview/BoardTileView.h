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
#import "Tile.h"
#import "layer/BoardViewLayerDelegate.h"


// -----------------------------------------------------------------------------
/// @brief The BoardTileView class is a custom view that is responsible for
/// drawing only a small part (called a "tile") of the visible part of the Go
/// board.
///
/// The Go board is split into rectangular sections called "tiles". Each
/// instance of BoardTileView draws one tile. BoardTileView identifies the tile
/// to draw by looking at the @e row and @e column properties defined by the
/// Tile protocol. The tile size is defined by BoardViewMetrics, as well as the
/// sizes of the different board elements to draw.
///
/// The view content is drawn in multiple CALayers that are stacked on top of
/// each other. Separating the drawing of different board elements into
/// different layers has the advantage that when an event occurs only those
/// layers, or layer parts, that are actually affected by the event need to be
/// redrawn. The drawback, of course, is that additional memory is required.
///
/// Two counter-measures are in effect to prevent excessive memory usage:
/// - A tiling mechanism makes sure that memory usage stays roughly the same
///   regardless of how far the board is zoomed in. See the documentation of
///   the TiledScrollView class for more details.
/// - Layers are dynamically added and removed depending on application events
///   that require certain board elements to be displayed / not to be displayed.
///   For instance, when the user starts the gesture to place a stone, layers
///   are created and added that will draw the cross-hair that visually aids the
///   user with placing the stone. When the user ends the gesture to place a
///   stone, the cross-hair layers are removed and deallocated.
///
/// The layers of BoardTileView draw all board elements except coordinate
/// labels. See the documentation of the CoordinateLabelsTileView class for
/// more details.
///
///
/// @par Delayed updates
///
/// BoardTileView utilizes long-running actions to delay view updates. Events
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
/// BoardTileView is not a container view, i.e. it does not consist of subviews
/// but draws its own content. For the purposes of Auto Layout it therefore has
/// an intrinsic content size - its size is not derived from the size of any
/// views that it contains, but from the size of the content that it is supposed
/// to draw.
///
/// The intrinsic content size of BoardTileView is equal to the size of the tile
/// that it draws. There currently are no known events that change the tile
/// size.
// -----------------------------------------------------------------------------
@interface BoardTileView : UIView <Tile>
{
}

- (id) initWithFrame:(CGRect)rect;

- (void) notifyLayerDelegates:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo;
- (void) delayedDrawLayers;

@end
