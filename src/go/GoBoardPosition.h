// -----------------------------------------------------------------------------
// Copyright 2013-2022 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoGame;
@class GoNode;


// -----------------------------------------------------------------------------
/// @brief The GoBoardPosition class defines which position of the Go board is
/// currently described by the GoPoint and GoBoardRegion objects attached to a
/// given GoGame.
///
/// A board position is how the Go board looks like after the information in a
/// game tree node has been applied to the board. This can be a move made by a
/// player, a series of stones set or cleared by board setup, markup being
/// drawn on one or more intersections, etc. Although in some cases the Go
/// board does not look differently after a node's information has been applied
/// (e.g. a pass move that does not play a stone, a node that only contains a
/// comment, etc.), the board before and after such a node is considered to be
/// in a different position.
///
/// In the course of a game, a new board position is created by each node
/// created by user interaction (e.g. a move made by a player). GoBoardPosition
/// provides a simple way how to refer to a board position: The reference is
/// made with a numeric value:
/// - Board position 0 refers to the game tree's root node, the beginning of the
///   game when no board setup has been made yet and no moves have been played
///   yet. If the game uses handicap, the handicap stones have already been
///   placed in this position.
/// - Board positions 1, 2, etc. refer to the position after the information in
///   node 1, 2, etc. have been applied to the board.
///
/// Note that this linear sequencing of board positions / nodes refers to the
/// board positions / nodes that are in the game variation that is currently
/// active in GoNodeModel.
///
///
/// @par Synchronization of current board position and object states
///
/// At any given time, the combined state of all the GoPoint and GoBoardRegion
/// objects attached to a GoGame instance describes how the Go board looks like
/// at that time.
///
/// Upon initialization, GoBoardPosition is associated with a GoGame instance.
/// When the value of GoBoardPosition's @e currentBoardPosition property is
/// changed, the property setter automatically updates the current state of the
/// GoPoint and GoBoardRegion objects attached to the GoGame instance. To
/// achieve this it invokes the GoNode methods modifyBoard() and revertBoard(),
/// depending on whether the value of @e currentBoardPosition is increased or
/// decreased.
///
///
/// @par Notifications
///
/// Do @b not use KVO to observe @e currentBoardPosition and
/// @e numberOfBoardPositions for changes. Instead react to the notifications
/// #currentBoardPositionDidChange and #numberOfBoardPositionsDidChange being
/// posted to the default notification center. The reason is that at the time
/// when KVO triggers the state of other objects besides GoPoint and
/// GoBoardRegion might not yet be up-to-date. Only the use of notifications
/// guarantees that an observer will see the correct state of all Go model
/// objects.
///
/// Clients that modify @e currentBoardPosition and/or @e numberOfBoardPositions
/// are responsible for posting the notifications #currentBoardPositionDidChange
/// and/or #numberOfBoardPositionsDidChange to the global notification center
/// once they have finished updating the state of all Go model objects.
///
/// Clients that plan to decrease the value of @e numberOfBoardPositions are
/// furthermore responsible to make sure that @e currentBoardPosition does not
/// refer to an invalid board position. This means that they may have first to
/// decrease the value of @e currentBoardPosition before they can decrease the
/// value of @e numberOfBoardPositions.
///
/// Because changing the current board position can be a lengthy operation,
/// the client that triggers the change may wish to display a progress meter to
/// indicate to the user that the operation is still running. The client in this
/// case can observe the default notification center for the notification
/// #boardPositionChangeProgress. The setter of @e currentBoardPosition posts
/// this notification (B-A) times for a board position change from A to B.
// -----------------------------------------------------------------------------
@interface GoBoardPosition : NSObject
{
}

- (id) initWithGame:(GoGame*)game;

- (void) changeToLastBoardPositionWithoutUpdatingGoObjects;

/// @brief The current board position as described in the GoBoardPosition class
/// documentation.
///
/// Raises @e NSRangeException if a new board position is set that is <0 or
/// exceeds the number of nodes in the GoGame associated with this
/// GoBoardPosition.
@property(nonatomic, assign) int currentBoardPosition;
/// @brief Returns the GoNode object that corresponds to
/// @e currentBoardPosition. Returns the game tree's root node for board
/// position 0.
@property(nonatomic, assign, readonly) GoNode* currentNode;
/// @brief Returns true if the current board position is the first position of
/// the GoGame associated with this GoBoardPosition.
///
/// This is a convenience property that returns true if @e currentBoardPosition
/// equals 0.
@property(nonatomic, assign, readonly) bool isFirstPosition;
/// @brief Returns true if the current board position is the last position of
/// the GoGame associated with this GoBoardPosition.
///
/// This is a convenience property that returns true if the current board
/// position displays the last node of the game.
@property(nonatomic, assign, readonly) bool isLastPosition;
/// @brief The number of board positions in the GoGame associated with this
/// GoBoardPosition.
@property(nonatomic, assign) int numberOfBoardPositions;

@end
