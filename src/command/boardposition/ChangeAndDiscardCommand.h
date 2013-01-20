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
/// current board position and all positions that follow afterwards. As a side
/// effect, the current board position changes to the one before the one that
/// was just discarded.
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
/// @note In a computer vs. human game, executing this command may result in a
/// situation where it is now the computer's turn to play. The computer player
/// is not triggered in this situation, though, to give the user the flexibility
/// to further edit the game.
// -----------------------------------------------------------------------------
@interface ChangeAndDiscardCommand : CommandBase
{
}

@end
