// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
@class GoPlayer;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The GoMove class represents a move made by one of the players.
///
/// @ingroup go
///
/// A GoMove object always has a type(); the different types of moves are
/// enumerated by #GoMoveType. A GoMove object is always associated with the
/// player who made the move. The player object can be queried for the color of
/// the move.
///
/// If a GoMove object is of type #GoMoveTypePlay it also has an associated
/// GoPoint object which registers where the stone was placed. The GoPoint
/// object is assigned (soon) after construction.
///
/// GoMove objects are interlinked with their predecessor (previous()) and
/// successor (next()) GoMove object. This represents the fact that a game
/// can be seen as a series of moves.
///
///
/// @par Playing/undoing a move
///
/// For a GoMove object that is of type #GoMoveTypePlay, invoking the doIt()
/// method triggers the mechanism for placing a stone. This is a comparatively
/// expensive operation, as doIt() manipulates the entire board to reflect the
/// position that exists after the stone has been placed.
///
/// For a GoMove object that is of type #GoMoveTypePass, invoking the doIt()
/// method has no effect.
///
/// Invoking undo() reverts whatever operations were performed by doIt(). For
/// GoMove objects of type #GoMoveTypePass this resolves to nothing. For GoMove
/// objects of type #GoMoveTypePlay, the board is reverted to the state it had
/// before the move's stone was placed.
///
/// @note doIt() and undo() must never be invoked twice in a row. They can be
/// invoked in alternation any number of times.
// -----------------------------------------------------------------------------
@interface GoMove : NSObject <NSCoding>
{
}

+ (GoMove*) move:(enum GoMoveType)type by:(GoPlayer*)player after:(GoMove*)move;
- (void) doIt;
- (void) undo;

/// @brief The type of this GoMove object.
@property(nonatomic, assign, readonly) enum GoMoveType type;
/// @brief The player who made this GoMove.
@property(nonatomic, retain, readonly) GoPlayer* player;
/// @brief The GoPoint object registering where the stone was placed for this
/// GoMove. Is nil if this GoMove is @e not a #GoMoveTypePlay.
@property(nonatomic, assign) GoPoint* point;
/// @brief The predecessor to this GoMove object. nil if this is the first move
/// of the game.
@property(nonatomic, assign, readonly) GoMove* previous;
/// @brief The successor to this GoMove object. nil if this is the last move
/// of the game.
@property(nonatomic, assign, readonly) GoMove* next;
/// @brief Keeps track of stones that were captured by this move.
///
/// If not empty, the array contains an unordered list of GoPoint objects. Also,
/// if several stone groups were captured, the GoPoint objects do not form a
/// single contiguous region.
@property(nonatomic, retain, readonly) NSArray* capturedStones;

@end
