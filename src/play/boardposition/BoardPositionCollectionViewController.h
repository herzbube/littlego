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
/// @brief The BoardPositionCollectionViewController class is responsible for
/// managing a collection view that displays a list of all board positions.
///
/// BoardPositionCollectionViewController is used in all UITypes.
///
/// @par Cell content and display
///
/// Each collection view cell represents a board position. Since every board
/// position represents a GoNode, each collection view cell also represents
/// a GoNode. Cells display the information present in the GoNode that they
/// represent.
///
/// Typically the information that a cell displays is about the move that
/// created the board position (played by black or white, play or pass move,
/// intersection played on, number of captured stones). In addition a cell also
/// displays indicators if the GoNode contains node or move annotations, or is
/// marked as a hotspot. If a GoNode does not contain a move, the cell only
/// displays the indicators.
///
/// A special cell is displayed for board position 0, i.e. the beginning of
/// the game. This cell displays a few bits of information about the game
/// itself (e.g. komi, handicap).
///
/// The cell for the board position that is currently displayed by the Go board
/// is specially marked up.
///
///
/// @par User interaction
///
/// The collection view lets the user browse through the existing board
/// positions by scrolling.
///
/// The user can select a board position by tapping the cell that represents
/// it. This results in the Go board being updated to display the selected board
/// position.
///
///
/// @par Number of board positions changes
///
/// The content of the collection view is updated whenever the number of board
/// positions changes in the game's GoBoardPosition instance. Usually this does
/// not result in an update of the scrolling position. There is, however, one
/// exception: If the collection view currently displays board positions that no
/// longer exist. In this scenario, BoardPositionCollectionViewController places
/// the new scrolling position so that the next view update displays the last
/// board position of the game (this simple solution is possible because only
/// board positions towards the end of the game can be discarded).
///
///
/// @par Current board position changes
///
/// The scroll position of the collection view is updated in response to a
/// change of the current board position in the game's GoBoardPosition instance.
/// The following rules apply:
/// - The scroll position is not updated if the cell for the new board position
///   is at least partially visible
/// - The scroll position is updated if the cell for the new board position is
///   not visible at all. The scroll position is set so that the cell is fully
///   in view, either centered in the collection view (if there are other cells
///   both on the left and the right) or on the left or on the right edge of
///   the collection view (if there are no more cells to the left or to the
///   right).
///
///
/// @par Delayed updates
///
/// BoardPositionCollectionViewController utilizes long-running actions to delay
/// view updates.
///
/// Methods in BoardPositionCollectionViewController that need to update
/// something in the collection view should not trigger the update themselves,
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
@interface BoardPositionCollectionViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout>
{
}

- (id) initWithScrollDirection:(UICollectionViewScrollDirection)scrollDirection;

- (CGSize) boardPositionCollectionViewMaximumCellSize;

@end
