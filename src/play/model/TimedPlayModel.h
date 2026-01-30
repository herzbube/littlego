// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The TimedPlayModel class provides user defaults data and other
/// values to its clients that are related to timed play.
// -----------------------------------------------------------------------------
@interface TimedPlayModel : NSObject
{
}

- (id) init;

- (void) readUserDefaults;
- (void) writeUserDefaults;

@property(nonatomic, assign) enum GoTimeDataValidationMode timeDataValidationMode;

/// @brief This setting controls what the player clock should show for
/// "remaining time" when a player has lost on time and the node with the last
/// move in the current game variation is currently selected. Value @e true (the
/// default) means, show the true remaining time according to the data stored in
/// GoNodeTimeData. Value @e false means, show zero remaining time, which is
/// fake but possibly more intuitive.
///
/// When the selected node changes (usually by user action), the player clock
/// shows how much time the player has left after the move in that node was
/// played (to be precise: the most recent move). This remaining time is always
/// non-zero, because a move could not have been played if there was no
/// remaining time.
///
/// However, if a player has lost on time and the node with the last move of the
/// current game variation is selected, it may seem strange that the clock still
/// shows a non-zero remaining time, because intuitively one would expect that
/// "losing on time" means "zero remaining time".
///
/// This is particularly true in the following scenarios:
/// - Scenario 1
///   - The player clock has been ticking down until the player lost on time.
///   - The player clock is now showing zero remaining time.
///   - The user selects an earlier node, then again selects the last node.
///   - The player clock now no longer shows zero remaining time.
/// - Scenario 2
///   - The user loads a game from the archive where a player has lost on time.
///   - The user is confronted with a state where the app says that a player
///     has lost on time, but the player clock shows a non-zero remaining time.
///
/// To be more intuitive (if this setting has value @e false) the app can
/// therefore set the losing player's clock to display zero remaining time. The
/// drawback is that the user will no longer be able to see how much time was
/// actually left after the last move. If the user performs the
/// "Undo lose on time" game action, the player clock will jump from zero
/// remaining time to non-zero remaining time.
@property(nonatomic, assign) bool showTrueRemainingTimeAfterLastMoveWhenLostOnTime;

@end
