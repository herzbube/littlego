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


// -----------------------------------------------------------------------------
/// @brief The TimeView class is a UIView subclass that displays time data for
/// one player.
// -----------------------------------------------------------------------------
@interface TimeView : UIView
{
}

- (id) initWithFrame:(CGRect)rect isTimeForBlackPlayer:(bool)isTimeForBlackPlayer;

/// @brief The pre-calculated size of a TimeView instance that displays all
/// subviews with their longest possible content.
///
/// When this method is invoked the first time, it performs the necessary size
/// calculations.
+ (CGSize) timeViewSize;

/// @brief True if this TimeView displays the time for the black player, false
/// if it displays the time for the white player.
@property(nonatomic, assign, readonly) bool isTimeForBlackPlayer;
/// @brief True if time data is valid and the player's time data can be
/// displayed. False if time data is not valid and the player's time data cannot
/// be displayed.
///
/// The default value after initialization is false.
@property(nonatomic, assign) bool isTimeDataValid;
/// @brief True if @e remainingTimeInSeconds refers to absolute time, false if
/// not.
///
/// When this is true, the value of @e remainingNumberOfMovesOrPeriods is not
/// displayed. In its stead a static string is displayed, indicating that
/// absolute time is in effect.
///
/// The default value after initialization is false.
@property(nonatomic, assign) bool isRemainingTimeAbsoluteTime;
/// @brief The time (in seconds) that the player has left.
///
/// Fractional seconds are rounded up. Rationale: If we would round down, 0.x
/// seconds would be displayed as 00:00, i.e. 00:00 would be displayed for up
/// to almost a second even though there still is time. It is better to display
/// 00:01 while there still is time, and only decrease to 00:00 when time has
/// completely run out.
///
/// Negative values are displayed as 00:00. This mitigates the problem that the
/// NSTimer that controls the clock may not fire at the exact time it is
/// supposed to, thus causing more time to elapse than strictly allowed. It is
/// expected, though, that this is only a small fraction of a second.
///
/// The default value after initialization is 0 (zero).
@property(nonatomic, assign) double remainingTimeInSeconds;
/// @brief Either the number of moves that the player still has to play in the
/// current time period, or the number of time periods that the player has left.
///
/// The value in this property is not displayed if
/// @e isRemainingTimeAbsoluteTime is true.
///
/// The default value after initialization is 0 (zero).
///
/// The property type must be able to hold an SGFCNumber, to avoid mismatches
/// with the type of property @e remainingNumberOfMoves in GoNodeTimeData.
@property(nonatomic, assign) unsigned long remainingNumberOfMovesOrPeriods;
/// @brief The state of the TimeView clock (e.g. stopped, running, etc.).
///
/// The default value after initialization is #GoClockStateStopped.
@property(nonatomic, assign) enum GoClockState clockState;

@end
