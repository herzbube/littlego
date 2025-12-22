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
/// of player clocks, and for updating player time data, when a game is in
/// progress that uses timed play.
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
// -----------------------------------------------------------------------------
@interface TimedPlayController : NSObject <PlayerClockService, PlayerClockTimerDelegate>
{
}

- (id) initWithRegistry:(Registry*)registry;

@end
