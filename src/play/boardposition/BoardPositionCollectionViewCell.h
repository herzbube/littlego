// -----------------------------------------------------------------------------
// Copyright 2015-2022 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The BoardPositionCollectionViewCell class shows information about a
/// board position.
///
/// All BoardPositionCollectionViewCell instances have the same pre-calculated
/// size.
///
/// The view layout looks like this:
///
/// @verbatim
/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+ +-UILabel---------+ +-UIImageView---+ |
/// | |                       |  | Text           | | Captured stones | | Info icon     | |
/// | | Node symbol image     |  +----------------+ +-----------------+ +---------------+ |
/// | | (vertically centered) |  +-UILabel--------+ +-UIImageView-----+ +-UIImageView---+ |
/// | |                       |  | Detail text    | | Hotspot icon    | | Markup icon   | |
/// | +-----------------------+  +----------------+ +-----------------+ +---------------+ |
/// +-------------------------------------------------------------------------------------+
/// @endverbatim
///
/// The size ratios depicted in the above scheme are incorrect because the
/// labels have different font sizes.
///
/// What is shown by the individual subviews?
/// - Node symbol image: A board position corresponds to a node in the tree of
///   nodes. The board position therefore can be represented by the same node
///   symbol that is also used in the node tree view. In general, the node
///   symbol attempts to describe the content of the node. For example, for
///   nodes that contain a move the node symbol is a stone image whose color
///   matches the color of the player who made the move. For the detailed
///   rules how the node symbol is determined, see the GoNode_NodeTreeView
///   category property @e nodeSymbol.
/// - Text label: A text that succinctly describes the content of the board
///   position/node. For example, for nodes that contain a move this displays
///   the intersection on which the stone was placed, or the string "Pass" if
///   the move was a pass move. The text label uses a larger font and is
///   therefore more prominent than the detail text label.
/// - Detail text label: A text that provides additional information about the
///   content of the board position/node. For example, for nodes that contain a
///   move this displays the text "Move <n>", where <n> is the move number in
///   the current game variation. The detail text label uses a smaller font and
///   is therefore less prominent than the text label.
/// - Captured stones label: This is displayed only for nodes that contain a
///   move, and then only if the move captured stones. The label displays the
///   number of stones that were captured in a prominent text color.
/// - Info icon: This is displayed only for nodes that contain annotations other
///   than a hotspot indicator. This icon is useful because most of the time
///   the node symbol will reflect that the node contains a move or setup, so
///   with this additional icon the user can still see that annotations are
///   present in the node.
/// - Hotspot icon: This is displayed only for nodes that contain a hotspot
///   indicator annotation. Hotspots mark important nodes, therefore the user
///   should always be able to see when a hotspot is present even if the node
///   symbol or info icon convey information about other node content.
/// - Markup icon: This is displayed only for nodes that contain markup. This
///   icon is useful for the same reasons as the Info icon.
// -----------------------------------------------------------------------------
@interface BoardPositionCollectionViewCell : UICollectionViewCell
{
}

+ (CGSize) boardPositionCollectionViewCellSizePositionZero;
+ (CGSize) boardPositionCollectionViewCellSizePositionNonZero;

/// @brief The board position that this cell represents. The default value is
/// -1, which causes the cell to display nothing.
@property(nonatomic, assign) int boardPosition;

@end
