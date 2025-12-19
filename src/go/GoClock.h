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
/// @brief The GoClock class is used to keep the time in games that use timed
/// play.
///
/// @ingroup go
///
/// GoClock starts out in state #GoClockStateStopped. It can then be started,
/// changing its state to #GoClockStateStarted.
///
/// A started GoClock can be suspended, changing its state to
/// #GoClockStateSuspended. GoClock keeps an internal record of how much time
/// has elapsed since it was last started. A suspended GoClock can be resumed,
/// changing its state back to #GoClockStateStarted. GoClock keeps track of
/// elapsed times across multiple suspend/resume cycles.
///
/// A started or suspended GoClock can be stopped, changing its state to
/// #GoClockStateStopped. When stopped, GoClock discards its internal record of
/// elapsed time.
///
/// As a convenience, a started or suspended GoClock can be restarted. This is
/// equivalent to stopping and then starting the GoClock.
// -----------------------------------------------------------------------------
@interface GoClock : NSObject <NSSecureCoding>
{
}

- (void) start;
- (void) suspend:(enum GoClockSuspendedReason)reason;
- (void) resume;
- (double) stop;
- (double) restart;

/// @brief The state of the clock (e.g. stopped, running, etc.).
///
/// The default value after initialization is #GoClockStateStopped.
@property(nonatomic, assign) enum GoClockState state;
/// @brief The reason why the clock is currently suspended.
///
/// This property has value #GoClockSuspendedReasonNotSuspended if the clock
/// is currently not suspended, i.e. if property @e state does not have the
/// value #GoClockStateSuspended.
@property(nonatomic, assign) enum GoClockSuspendedReason suspendedReason;
/// @brief Returns the total time in seconds that has elapsed since the
/// clock was last started (excluding time during which the clock was
/// suspended). Returns 0 if the clock is currently stopped.
///
/// This is a dynamically calculated property. Invoking it two times in a row
/// while the clock is running will return different values.
///
/// @attention This property @b cannot be observed with KVO.
@property(nonatomic, assign, readonly) double totalElapsedTimeInSecondsSinceClockWasStarted;

@end
