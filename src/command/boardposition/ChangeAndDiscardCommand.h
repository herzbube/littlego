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


// Project includes
#import "CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The ChangeAndDiscardCommand class is responsible for discarding the
/// current board position, possibly the position that precedes it, and all
/// positions that follow afterwards. As a side effect, the current board
/// position changes to the one preceding the ones that were just discarded.
///
/// If the user preference DiscardMyLastMove is turned on (the default) and the
/// current board position was created by a computer player's move, then all
/// preceding board positions that were created by a human player's move are
/// discarded as well. This can only occur in a computer vs. human game with
/// alternating moves. Usually two board positions will be discarded, but more
/// board positions can be discarded if there are several consecutive human
/// player moves.
///
/// If there is only one board position (i.e. no moves have been made yet),
/// ChangeAndDiscardCommand does nothing.
///
/// After it has made the discard, ChangeAndDiscardCommand performs a backup
/// of the current game.
///
/// @note The first board position represents the start of the game and cannot
/// be discarded. Therefore, if ChangeAndDiscardCommand is executed when the
/// current board position is the first board position, ChangeAndDiscardCommand
/// behaves as if the second board position were the current one.
///
/// @note In a computer vs. human game where the user preference
/// DiscardMyLastMove is turned off, executing this command may result in a
/// situation where it is now the computer's turn to play. The computer player
/// is not triggered in this situation, though, to give the user the flexibility
/// to further edit the game.
// -----------------------------------------------------------------------------
@interface ChangeAndDiscardCommand : CommandBase
{
}

@end
