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
/// | |                       |  | Intersection   | | Captured stones | | Info icon     | |
/// | | Stone image           |  +----------------+ +-----------------+ +---------------+ |
/// | | (vertically centered) |  +-UILabel----------------------------+ +-UIImageView---+ |
/// | |                       |  | Board position                     | | Hotspot icon  | |
/// | +-----------------------+  +------------------------------------+ +---------------+ |
/// +-------------------------------------------------------------------------------------+
/// @endverbatim
///
/// The size ratios depicted in the above scheme are incorrect because the
/// labels have different font sizes.
///
/// BoardPositionCollectionViewCell is used for #UITypePad (both Portrait
/// and Landscape) and #UITypePhone (Landscape only).
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
