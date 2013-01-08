// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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


// Project references
#import "../../ui/ItemScrollView.h"


// -----------------------------------------------------------------------------
/// @brief The BoardPositionListController class is responsible for managing the
/// "board position list view", i.e. the scroll view on the Play tab that
/// displays the board positions of the current game.
///
/// The board position list view displays a series of small subviews, each of
/// which represents one of the board positions of the current game. A board
/// position subview displays information about the move that caused the
/// board position to come into existence. Even though a pass move does not
/// place a new stone on the board, it nevertheless creates a new board position
/// and is therefore listed by the board position list view.
///
/// A special subview is displayed for board position 0, i.e. the beginning of
/// the game. This subview displays a few bits of information about the game
/// itself (e.g. komi, handicap).
///
/// The board position in the current game's GoBoardPosition instance (i.e. the
/// board position displayed by the Play view) is specially marked up.
///
///
/// @par User interaction
///
/// The board position list view is a scroll view that lets the user browse
/// through the existing board positions.
///
/// The user can select a board position by tapping the subview that represents
/// it. This results in the Go board being updated to display the selected board
/// position.
///
///
/// @par Positioning and layout
///
/// Position and layout of the board position list view depends on the device
/// orientation:
/// - Portrait orientation: The view is displayed below the Go board, the
///   subviews are arranged horizontally, and scrolling occurs in a horizontal
///   direction. BoardPositionListController only determines the height of the
///   frame of the board position list view, the other frame characteristics are
///   set by the Play tab's main controller (who is responsible for the overall
///   layout of views on the Play tab).
/// - Landscape orientation: The view is displayed on the left of the Go board,
///   subviews are arranged vertically, scrolling occurs vertically, and
///   BoardPositionListController determines the width of the frame of the board
///   position list view.
///
///
/// @par Content and scroll position updates
///
/// The content of the board position list view is updated whenever a change
/// occurs in the game's GoMoveModel instance. Usually this does not result in
/// an update of the scrolling position, with one exception: If the board
/// position list view currently displays board positions for moves that no
/// longer exist in the GoMoveModel instance. In this scenario,
/// BoardPositionListController places the new scrolling position so that the
/// last board position of the game is displayed by the next view update (this
/// simple solution is possible because only moves towards the end of the game
/// can be discarded).
///
/// The scroll position of the move list view is updated in response to a change
/// of the board position in the game's GoBoardPosition instance. The following
/// rules apply:
/// - The scroll position is not updated if the subview for the new board
///   position is at least partially visible
/// - The scroll position is updated if the subview for the new board position
///   is not visible at all. The scroll position is set so that the subview is
///   fully in view, either on the left or on the right edge of the board
///   position list view. The scroll position update is made as if the user had
///   naturally scrolled to the new board position and then stopped when the new
///   board position came into view.
// -----------------------------------------------------------------------------
@interface BoardPositionListController : NSObject <ItemScrollViewDataSource, ItemScrollViewDelegate>
{
}

- (id) init;

/// @brief The board position list view.
@property(nonatomic, assign, readonly) ItemScrollView* boardPositionListView;

@end
