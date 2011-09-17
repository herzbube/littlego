// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "../CommandBase.h"

// Forward declarations
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The UndoMoveCommand class is responsible for taking back the last
/// move made by a human player, including any computer player moves that were
/// made in response.
///
/// Undoing moves is not possible in a computer vs. computer game.
///
/// UndoMoveCommand submits an "undo" command to the GTP engine, then updates
/// GoGame so that discards the last GoMove of type #PlayMove or #PassMove that
/// has been made by any player. Resigning the game cannot be undone.
///
/// If the move that was discarded was made by a computer player, it is assumed
/// that this move was a response to a move made by a human player (this
/// assumption must be true by definition because at least one human player
/// must be engaged in a game that supports undo). The human player move is
/// then also discarded, in the same way as the computer player move.
// -----------------------------------------------------------------------------
@interface UndoMoveCommand : CommandBase
{
}

- (id) init;

@property(retain) GoGame* game;

@end
