// -----------------------------------------------------------------------------
// Copyright 2012-2015 Patrick Näf (herzbube@herzbube.ch)
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
@class GoMove;


// -----------------------------------------------------------------------------
/// @brief The GoMoveModel class provides data related to the moves of the
/// current game to its clients.
///
/// All indexes in GoMoveModel are zero-based.
///
/// Invoking GoMoveModel methods that add or discard moves generally sets the
/// GoGameDocument dirty flag and, if alternating play is enabled, updates
/// GoGame's @e nextMoveColor property.
// -----------------------------------------------------------------------------
@interface GoMoveModel : NSObject <NSCoding>
{
}

- (id) initWithGame:(GoGame*)game;

- (void) appendMove:(GoMove*)move;
- (void) discardLastMove;
- (void) discardMovesFromIndex:(int)index;
- (void) discardAllMoves;
- (GoMove*) moveAtIndex:(int)index;

/// @brief Returns the number of moves in the current game. Returns 0 if there
/// are no moves.
@property(nonatomic, assign, readonly) int numberOfMoves;
/// @brief The GoMove object that represents the first move of the game. nil if
/// the game currently has no move.
@property(nonatomic, assign, readonly) GoMove* firstMove;
/// @brief The GoMove object that represents the last move of the game. nil if
/// the game currently has no move.
@property(nonatomic, assign, readonly) GoMove* lastMove;

@end
