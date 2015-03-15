// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
/// The view layout is similar to table view cells with style
/// UITableViewCellStyleSubtitle. It looks like this:
///
/// @verbatim
/// +-------------------------------------------------------------------+
/// | +-UIImageView-----------+  +-UILabel----------------------------+ |
/// | |                       |  | Intersection                       | |
/// | | Stone image           |  +------------------------------------+ |
/// | | (vertically centered) |  +-UILabel--------+ +-UILabel---------+ |
/// | |                       |  | Board position | | Captured stones | |
/// | +-----------------------+  +----------------+ +-----------------+ |
/// +-------------------------------------------------------------------+
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
