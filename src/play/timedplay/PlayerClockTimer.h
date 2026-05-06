// -----------------------------------------------------------------------------
// Copyright 2025-2026 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class PlayerClockTimer;


// -----------------------------------------------------------------------------
/// @brief The PlayerClockTimerDelegate protocol defines operations that the
/// delegate of PlayerClockTimer must implement.
// -----------------------------------------------------------------------------
@protocol PlayerClockTimerDelegate

@required

/// @brief PlayerClockTimer invokes this method to obtain the time in seconds
/// until the next full second of the player's remaining time has elapsed.
///
/// PlayerClockTimer invokes this method whenever it needs to schedule a timer.
/// PlayerClockTimer uses the value that this method returns as the time when
/// the timer will fire. The exception is when this method returns 0 (zero),
/// in which case PlayerClockTimer will schedule the timer to fire in 1 (one)
/// second.
///
/// Even though the type of the return value is signed, this method should not
/// return a negative value. PlayerClockTimer treats a negative value as if
/// 0 (zero) had been returned.
///
/// @note This method is guaranteed to be invoked on the main thread.
- (double) timeInSecondsUntilNextFullSecond:(PlayerClockTimer*)playerClockTimer;

/// @brief PlayerClockTimer invokes this method when the timer fires. The
/// delegate can do whatever is needed to update the player's remaining time.
/// The return value indicates whether or not PlayerClockTimer should schedule
/// another timer.
///
/// If this method returns true, PlayerClockTimer assumes that the player still
/// has some remaining time and will schedule another timer. PlayerClockTimer
/// will invoke timeInSecondsUntilNextFullSecond:() to obtain the time for
/// scheduling the timer.
///
/// If this method returns false, PlayerClockTimer will not schedule another
/// timer. The typical reason is that the player has run out of time, but the
/// delegate may have other reasons to return false.
///
/// @note This method is guaranteed to be invoked on the main thread.
- (bool) timerDidFire:(PlayerClockTimer*)playerClockTimer;

@end

// -----------------------------------------------------------------------------
/// @brief The PlayerClockTimer class is responsible for managing a timer that,
/// when started, periodically triggers a decrease of a player's remaining time.
/// This has two effects: 1) The user interface can show a clock that is
/// counting down. 2) The application is notified when a player runs out of
/// time.
///
/// PlayerClockTimer collaborates with its delegate to trigger the decrease
/// of the remaining time whenever the next full second of the player's
/// remaining time has elapsed. The clock shown in the user interface is
/// therefore restricted to a resolution of at maximum one second.
///
/// Because the timer mechanism that PlayerClockTimer uses under the hood is
/// not fully accurate (i.e. it's not a real-time mechanism), the decrease of
/// the remaining time usually does not happen @b exactly at the full second.
/// PlayerClockTimer uses the following mitigation techniques:
/// - PlayerClockTimer guarantees that it triggers the decrease @b after (but
///   not @b before) a full second has elapsed.
/// - PlayerClockTimer "catches up" with the time it missed, i.e. it triggers
///   the next decrease as close as possible to the next full second.
///
/// @par Implementation note
///
/// The "catch up" mechanism is necessary because the model attempts to capture
/// the player's remaining time at full accuracy, i.e. with fractions of a
/// second.
///
/// If the model were to capture the player's remaining time only with a one
/// second resolution, the implementation of PlayerClockTimer would not need
/// the "catch up" mechanism, but could simply employ a repeating timer that
/// would trigger as close as possible to the original full second interval on
/// which it was scheduled.
///
/// If the model were to capture the player's remaining time with a specific
/// resolution (e.g. tenths of a second) instead of with full accuracy, the
/// implementation of PlayerClockTimer would also not need the "catch up"
/// mechanism - at least not technically. PlayerClockTimer could simply employ
/// a repeating timer with a timer interval that matches the model's resolution.
/// However, that would keep the system unnecessarily busy because the user
/// interface clock only has a one second resolution and cannot profit from the
/// higher timer resolution.
///
/// Conclusion: As long as the model accuracy is higher than the user interface
/// clock's resolution, PlayerClockTimer needs to run a timer with the user
/// interface clock's resolution, and it needs to implement the "catch up"
/// mechanism in order to not waste CPU cycles.
// -----------------------------------------------------------------------------
@interface PlayerClockTimer : NSObject
{
}

- (id) initWithDelegate:(id<PlayerClockTimerDelegate>)delegate;

- (void) scheduleTimer;
- (void) invalidateTimerIfOneIsScheduled;

@end
