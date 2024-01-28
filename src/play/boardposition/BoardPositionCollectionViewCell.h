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
/// board position. A board position is how the Go board looks like after the
/// information in a game tree node has been applied to the board.
/// BoardPositionCollectionViewCell is therefore effectively a description of
/// the content of a game tree node.
///
/// There are two kinds of BoardPositionCollectionViewCell:
/// - A cell that represents board position 0, i.e. the root of the game tree
///   node, which is the start of the game in all branches of the tree.
/// - A cell that represents board positions >0.
///
/// All BoardPositionCollectionViewCell instances of the same type have the same
/// pre-calculated size. All BoardPositionCollectionViewCell instances,
/// regardless of their type, share the same Auto Layout constraints, with some
/// constraints being modified dynamically when the content of the cell changes,
/// resulting in substantially different view layouts. See the NOTES.Design
/// document for a detailed explanation of all constraints.
///
/// The basic view layout, when all subviews are visible at the same time, looks
/// like this:
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
/// Only the node symbol image and the main text label are visible at all times.
/// The other subviews are visible only if the content of the game tree node
/// requires it. The layout shown above changes when some subviews are not
/// visible.
///
/// Here are some more variants of the layout above if some subviews are not
/// visible:
///
/// @verbatim
/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+                   +-UILabel---------+ |
/// | |                       |  | Text           |                   | Captured stones | |
/// | | Node symbol image     |  +----------------+                   +-----------------+ |
/// | | (vertically centered) |  +-UILabel--------+                   +-UIImageView-----+ |
/// | |                       |  | Detail text    |                   | Hotspot icon    | |
/// | +-----------------------+  +----------------+                   +-----------------+ |
/// +-------------------------------------------------------------------------------------+
///
/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+                     +-UIImageView---+ |
/// | |                       |  | Text           |                     | Info icon     | |
/// | | Node symbol image     |  +----------------+                     +---------------+ |
/// | | (vertically centered) |  +-UILabel--------+                     +-UIImageView---+ |
/// | |                       |  | Detail text    |                     | Markup icon   | |
/// | +-----------------------+  +----------------+                     +---------------+ |
/// +-------------------------------------------------------------------------------------+
///
/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+ +-UILabel---------+ +-UIImageView---+ |
/// | |                       |  | Text           | | Captured stones | | Info icon     | |
/// | | Node symbol image     |  +----------------+ +-----------------+ +---------------+ |
/// | | (vertically centered) |  +-UILabel--------+                                       |
/// | |                       |  | Detail text    |                                       |
/// | +-----------------------+  +----------------+                                       |
/// +-------------------------------------------------------------------------------------+

/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+                                       |
/// | |                       |  | Text           |                                       |
/// | | Node symbol image     |  +----------------+                                       |
/// | | (vertically centered) |  +-UILabel--------+ +-UIImageView-----+ +-UIImageView---+ |
/// | |                       |  | Detail text    | | Hotspot icon    | | Markup icon   | |
/// | +-----------------------+  +----------------+ +-----------------+ +---------------+ |
/// +-------------------------------------------------------------------------------------+

/// @endverbatim
///
/// So far nothing surprising. The main change comes when the detail text label
/// is no longer shown. When that happens the main text label gets all the
/// vertical, with the text being vertically centered. The captured stones label
/// cannot appear in this layout because the detail text label is only then not
/// visible when the node does not contain a move.
///
/// As long as the info icon is visible, the info icon is placed in a top row
/// and one or both of the other two icons are placed in a bottom row:
///
/// @verbatim
/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+                     +-UIImageView---+ |
/// | |                       |  |                |                     | Info icon     | |
/// | | Node symbol image     |  | Text           |                     +---------------+ |
/// | |                       |  | (vertically    |                                       |
/// | | (vertically centered) |  | centered)      | +-UIImageView-----+ +-UIImageView---+ |
/// | |                       |  |                | | Hotspot icon    | | Markup icon   | |
/// | +-----------------------+  +----------------+ +-----------------+ +---------------+ |
/// +-------------------------------------------------------------------------------------+
///
/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+                     +-UIImageView---+ |
/// | |                       |  |                |                     | Info icon     | |
/// | | Node symbol image     |  | Text           |                     +---------------+ |
/// | |                       |  | (vertically    |                                       |
/// | | (vertically centered) |  | centered)      |                     +-UIImageView---+ |
/// | |                       |  |                |                     | Hotspot icon  | |
/// | +-----------------------+  +----------------+                     +---------------+ |
/// +-------------------------------------------------------------------------------------+
/// @endverbatim
///
/// When the info icon is not visible, the other two icons are placed in a
/// middle row, i.e. in a vertically centered location:
///
/// @verbatim
/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+                                       |
/// | |                       |  |                |                                       |
/// | | Node symbol image     |  | Text           |   +-UIImageView---+ +-UIImageView---+ |
/// | |                       |  | (vertically    |   | Hotspot icon  | | Markup icon   | |
/// | | (vertically centered) |  | centered)      |   +---------------+ +---------------+ |
/// | |                       |  |                |                                       |
/// | +-----------------------+  +----------------+                                       |
/// +-------------------------------------------------------------------------------------+
/// @endverbatim
///
/// Finally, if only one of the icons is visible it is placed in a vertically
/// centered location:
///
/// @verbatim
/// +-------------------------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel--------+                                       |
/// | |                       |  |                |                                       |
/// | | Node symbol image     |  | Text           |                     +-UIImageView---+ |
/// | |                       |  | (vertically    |                     | Info icon     | |
/// | | (vertically centered) |  | centered)      |                     +---------------+ |
/// | |                       |  |                |                      (can be any of   |
/// | +-----------------------+  +----------------+                       the 3 icons)    |
/// +-------------------------------------------------------------------------------------+
/// @endverbatim
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
