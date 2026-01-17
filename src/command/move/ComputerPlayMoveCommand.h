// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../diagnostics/SendBugReportController.h"

// Forward declarations
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The ComputerPlayMoveCommand class is responsible for letting the
/// computer player make a move (even if it is not its turn).
///
/// ComputerPlayMoveCommand performs the following operations:
/// - Submits TimeLeftCommand. That command will determine on its own whether
///   or not the GTP engine needs to be configured with time/moves left.
/// - If the game uses timed play: Starts the clock of the player on whose
///   behalf the computer will play a move.
/// - Submits a "genmove" command to the GTP engine (see note below).
/// - If the game uses timed play: Stops the clock of the player on whose
///   behalf the computer played a move (so as not to waste the player's time
///   while the app handles playing the move).
/// - Updates GoGame so that it generates a GoMove of the appropriate type for
///   the player whose turn it is (not necessarily a computer player).
/// - If it is the turn of a human player and the game uses timed play: Starts
///   the clock of the human player.
/// - If it is the turn of a computer player: Submits another
///   ComputerPlayMoveCommand. If the game uses timed play, this includes
///   starting the computer player's clock (see above).
///
/// @note The GTP command is executed asynchronously, i.e. control returns to
/// the submitter of ComputerPlayMoveCommand before the computer player's move
/// has actually been generated. This allows the GUI to remain responsive. When
/// the GTP response finally arrives, it triggers a callback to the code in
/// ComputerPlayMoveCommand. The callback is executed in the context of the
/// thread in which ComputerPlayMoveCommand was submitted (expected to be the
/// main thread).
// -----------------------------------------------------------------------------
@interface ComputerPlayMoveCommand : CommandBase <SendBugReportControllerDelegate>
{
}

- (id) init;

@property(nonatomic, retain) GoGame* game;

@end
