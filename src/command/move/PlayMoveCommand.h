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
#import "../../diagnostics/SendBugReportController.h"

// Forward declarations
@class GoGame;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The PlayMoveCommand class is responsible for making a playing move
/// or a pass move for a human player.
///
/// PlayMoveCommand performs the following operations:
/// - If the game uses timed play: Stops the current player's clock (so as
///   not to waste the player's time while the app handles playing the move).
/// - Submits a "play" command to the GTP engine.
/// - Updates GoGame so that it generates a GoMove of type #GoMoveTypePlay or
///   #GoMoveTypePass for the human player whose turn it is. If the game uses
///   timed play, GoGame also updates the time data of the player who made the
///   move and adds time data to the generated move node.
/// - Writes a backup of the game state to disk.
/// - If it is the turn of a human player and the game uses timed play: Starts
///   the clock of the human player.
/// - If it is the turn of a computer player: Triggers the computer player.
///   If the game uses timed play, this includes starting the computer player's
///   clock.
// -----------------------------------------------------------------------------
@interface PlayMoveCommand : CommandBase <SendBugReportControllerDelegate>
{
}

- (id) initWithPoint:(GoPoint*)aPoint;
- (id) initPass;

@property(nonatomic, retain) GoGame* game;
@property(nonatomic, assign) enum GoMoveType moveType;
@property(nonatomic, retain) GoPoint* point;

@end
