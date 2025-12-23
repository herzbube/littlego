// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayerClockService.h"
#import "PlayerClockTimer.h"

// Forward declarations
@class Registry;


// -----------------------------------------------------------------------------
/// @brief The TimedPlayController class is responsible for managing the state
/// of player clocks when a game is in progress that uses timed play.
///
/// When a game that uses timed play is in progress, TimedPlayController handles
/// application-wide events that have an effect on player clocks and/or player
/// time data. For instance, it reacts to the UIKit scene being deactivated or
/// the Go board becoming inaccessible by suspending the clock of the player
/// whose turn it currently is.
///
/// TimedPlayController also implements the PlayerClockService protocol to
/// handle requests related to timed play. For instance, a command may request
/// that the current player's clock be stopped when a move is played, so that
/// the command can then update the model with the move (which will cause the
/// player's remaining time to be recorded in the move node, and may also cause
/// the player's remaining time to be reset if a period-based time system is in
/// effect). Another example is that a command may request that the current
/// player's clock be started when the player's turn begins.
///
/// TimedPlayController coordinates these events and requests to implement the
/// overarching timed play design of the app.
///
/// @note TimedPlayController is @b not a view controller, but it may display
/// popups in response to some events.
///
/// @par Timed play design
///
/// TODO xxx create proper documentation from the following notes
///
/// - The main problem with managing player clocks is that they can be
///   suspended. If this were not possible, then it would be as simple as in a
///   real world game of Go: when a player's turn starts the clock starts,
///   when a player's turn ends the clock stops.
/// - So the main problem that TimedPlayController must solve is when to suspend
///   clocks and when to resume or stop a suspended clock.
/// - The inputs are
///   - Application events (e.g. scene is deactivated or activated).
///   - Requests from other parts of the application (e.g. stop clock because
///     a player's turn ended).
///   - Direct user interaction with the clock (i.e. user wants to suspend or
///     resume a suspended clock).
/// - A number of basic invariants are:
///   - if the game that is currently in progress does not use timed play, then
///     ignore all events and requests and don't touch player clocks
///   - ditto if the time data for the current game variation is not valid
///   - ignore all attempts to change the state of the clock of the player who
///     is not next to move. this mainly is important for direct user interactions:
///     the controller who manages user interactions with the player clock in
///     the UI does not have to keep state, it can just forward the request
///     to TimedPlayController which will ignore the request if the interaction
///     was with the wrong player clock.
/// - The goals pursued by TimedPlayController are as follows:
///   - Let the user play a timed game, but in a relaxed non-tournament,
///     non-competitive environment where the user has the freedom to suspend
///     the clock whenever a distraction occurs or they choose to do so for any
///     other reason.
///   - To help with the above goal of a relaxed game, if the user performs an
///     action that would prevent them from playing a move in time,
///     TimedPlayController automatically suspends the clock. One obvious
///     example for this is when the user sends the entire app to the
///     background. Other examples, for when the app is still in the foreground,
///     are when the user switches to a different tab or calls up the Game Info
///     view and no longer sees the game board, or when the user calls up the
///     "More game actions" menu and is no longer able to interact with the
///     game board. When the situation "normalizes", TimedPlayController
///     resumes the clock.
/// - TimedPlayController also suspends and resumes the clock when it needs to
///   perform some internal housekeeping. The only example so far is when the
///   one-second timer fires that keeps the user interface clock counting down.
///
/// TODO xxx if it turns out that TimedPlayController really "only" manages the
/// player clocks, then consider renaming it
// -----------------------------------------------------------------------------
@interface TimedPlayController : NSObject <PlayerClockService, PlayerClockTimerDelegate>
{
}

- (id) initWithRegistry:(Registry*)registry;

@end
