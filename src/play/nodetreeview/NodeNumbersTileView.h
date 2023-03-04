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
#import "layer/NodeTreeViewLayerDelegate.h"
#import "../../ui/Tile.h"

// Forward declarations
@class NodeTreeViewCanvas;
@class NodeTreeViewMetrics;
@class NodeTreeViewModel;


// -----------------------------------------------------------------------------
/// @brief The NodeNumbersTileView class is a custom view that is responsible
/// for drawing only a small part (called a "tile") of the visible part of
/// the strip with node numbers.
///
/// Most of what is said in the documentation of the NodeTreeTileView class also
/// applies to the NodeNumbersTileView class. The difference is that
/// NodeNumbersTileView has only one layer and therefore does not need to
/// dynamically add/remove layers. Instead, an outside force is responsible for
/// adding/removing NodeNumbersTileView instances depending on whether node
/// numbers should be displayed, or not.
///
///
/// @par Implementation note
///
/// Node numbers must be drawn independently from the remaining node tree
/// elements so that the user can always see the numbers even if the node tree
/// is zoomed in and scrolled to a position where the node tree's main edge is
/// no longer visible.
///
/// The way to achieve this is to display node numbers in an additional scroll
/// view that scrolls independently from the main scroll view that displays the
/// tree of nodes.
///
/// It would have been possible to add NodeTreeTileView instances to those
/// additional scroll views, and to let NodeTreeTileView manage an additional
/// node number layer that is only active when NodeTreeTileView is in
/// "node numbers" mode. However, this would have bloated NodeTreeTileView
/// and made the class even more complicated than it already is.
// -----------------------------------------------------------------------------
@interface NodeNumbersTileView : UIView <Tile>
{
}

- (id) initWithFrame:(CGRect)rect
             metrics:(NodeTreeViewMetrics*)nodeTreeViewMetrics
              canvas:(NodeTreeViewCanvas*)nodeTreeViewCanvas
               model:(NodeTreeViewModel*)nodeTreeViewModel;

- (void) notifyLayerDelegate:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo;
- (void) delayedDrawLayer;
- (void) removeNotificationResponders;

@end
