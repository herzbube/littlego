// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The BoardPositionListViewController class is responsible for managing
/// the "board position list view", which is a scroll view in #UIAreaPlay that
/// displays the board positions of the current game.
///
/// BoardPositionListViewController is a child view controller. It is used on
/// the iPhone only.
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
/// board position currently displayed by the Go board) is specially marked up.
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
/// @par Number of board positions changes
///
/// The content of the board position list view is updated whenever the number
/// of board positions changes in the game's GoBoardPosition instance. Usually
/// this does not result in an update of the scrolling position. There is,
/// however, one exception: If the board position list view currently displays
/// board positions that no longer exist. In this scenario,
/// BoardPositionListViewController places the new scrolling position so that
/// the next view update displays the last board position of the game (this
/// simple solution is possible because only board positions towards the end of
/// the game can be discarded).
///
///
/// @par Current board position chanages
///
/// The scroll position of the move list view is updated in response to a change
/// of the current board position in the game's GoBoardPosition instance. The
/// following rules apply:
/// - The scroll position is not updated if the subview for the new board
///   position is at least partially visible
/// - The scroll position is updated if the subview for the new board position
///   is not visible at all. The scroll position is set so that the subview is
///   fully in view, either on the left or on the right edge of the board
///   position list view. The scroll position update is made as if the user had
///   naturally scrolled to the new board position and then stopped when the new
///   board position came into view.
///
///
/// @par Delayed updates
///
/// BoardPositionListViewController utilizes long-running actions to delay
/// view updates.
///
/// Methods in BoardPositionListViewController that need to update something in
/// the board position list view should not trigger the update themselves,
/// instead they should do the following:
/// - Set one of several "needs update" flags to indicate what needs to be
///   updated. For each type of update there is a corresponding private bool
///   property (e.g @e numberOfItemsNeedsUpdate).
/// - Invoke the private helper delayedUpdate(). This helper will immediately
///   invoke updater methods if no long-running action is currently in progress,
///   otherwise it will do nothing.
///
/// When the last long-running action terminates, delayedUpdate() is invoked,
/// which in turn invokes all updater methods (since now no more actions are in
/// progress). An updater method will always check if its "needs update" flag
/// has been set.
// -----------------------------------------------------------------------------
@interface BoardPositionListViewController : UIViewController <ItemScrollViewDataSource, ItemScrollViewDelegate>
{
}

@end
