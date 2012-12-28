// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
@class GoMove;


// -----------------------------------------------------------------------------
/// @brief The BoardPositionModel class manages data related to the board
/// position displayed on the Play view.
// -----------------------------------------------------------------------------
@interface BoardPositionModel : NSObject
{
}

- (id) init;

/// @brief Returns the board position currently displayed by the Play view.
///
/// Board position 0 refers to the beginning of the game, i.e. no moves have
/// been played yet. If the game uses handicap, handicap stones have already
/// been placed.
///
/// Board positions 1, 2, etc. refer to the position after move 1, 2, etc. have
/// been played.
///
/// Raises @e NSRangeException if a new board position is set that is <0 or
/// exceeds the number of moves in the current game.
@property(nonatomic, assign) int currentBoardPosition;
/// @brief Returns the GoMove object that corresponds to
/// @e currentBoardPosition. Returns nil for board position 0.
@property(nonatomic, assign, readonly) GoMove* currentMove;
/// @brief Returns true if the current board position is the first position that
/// can possibly be displayed.
///
/// This is a convenience property that returns true if @e currentBoardPosition
/// equals 0.
@property(nonatomic, assign, readonly) bool isFirstPosition;
/// @brief Returns true if the current board position is the last position that
/// can possibly be displayed.
///
/// This is a convenience property that returns true if the current board
/// position displays the last move of the game.
@property(nonatomic, assign, readonly) bool isLastPosition;

@end
