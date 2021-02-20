// -----------------------------------------------------------------------------
// Copyright 2013-2019 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The BoardPositionView class shows information about a board position.
///
/// All BoardPositionView instances have the same pre-calculated size.
///
/// The view layout is this:
///
/// @verbatim
/// +-----------------------------------------------+
/// | +-UILabel----------+  +-UIImageView---------+ |
/// | | Board position   |  | Stone image         | |
/// | +------------------+  +---------------------+ |
/// | +-UILabel----------+  +-UILabel-------------+ |
/// | | Intersection     |  | Captured stones     | |
/// | +------------------+  +---------------------+ |
/// +-----------------------------------------------+
/// @endverbatim
// -----------------------------------------------------------------------------
@interface BoardPositionView : UICollectionViewCell
{
}

+ (CGSize) boardPositionViewSize;

/// @brief The board position that this view represents. A value of -1 for this
/// property causes the BoardPositionView to display nothing.
@property(nonatomic, assign) int boardPosition;
/// @brief True if this view should render itself with a different background,
/// indicating that it represents the current board position.
///
/// This property must be assigned externally because BoardPositionView is used
/// not only inside a collection view, so it's not possible to use the
/// @e selectedBackgroundView property.
@property(nonatomic, assign) bool currentBoardPosition;

@end
