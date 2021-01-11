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


// Project includes
#import "../CommandBase.h"
#import "../../diagnostics/SendBugReportController.h"

// Forward declarations
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The ComputerPlayMoveCommand class is responsible for letting the
/// computer player make a move (even if it is not his turn).
///
/// ComputerPlayMoveCommand submits a "genmove" command to the GTP engine, then
/// updates GoGame so that it generates a GoMove of the appropriate type for
/// the player whose turn it is (not necessarily a computer player).
///
/// Another ComputerPlayMoveCommand is submitted automatically if it is now
/// the computer player's turn to move.
///
/// @note The GTP command is executed asynchronously, i.e. control returns to
/// the submitter of ComputerPlayMoveCommand before the computer player's move
/// has actually been generated. This allows the GUI to remain responsive. When
/// the GTP response finally arrives, it triggers a callback to the code in
/// ComputerPlayMoveCommand.
// -----------------------------------------------------------------------------
@interface ComputerPlayMoveCommand : CommandBase <SendBugReportControllerDelegate>
{
}

- (id) init;

@property(nonatomic, retain) GoGame* game;

@end
