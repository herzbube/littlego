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
@class GoNode;
@class GoNodeTimeData;
@class GoTimeSettings;


// -----------------------------------------------------------------------------
/// @brief The GoPlayerTimeData class stores time-related information for a
/// player. GoPlayerTimeData also provides methods for updating the information
/// in response to certain events (e.g. player makes a move). The parameters for
/// the updating logic are provided by the GoTimeSettings object that is
/// supplied to the GoPlayerTimeData initializer.
///
/// @ingroup go
///
/// GoPlayerTimeData has an internal clock to perform time-keeping for the
/// player. An external actor is responsible for starting, suspending and
/// stopping the clock.
///
/// Whenever the clock is suspended or stopped, the time that has elapsed since
/// the clock was started is deducted from the remaining time. When the
/// remaining time reaches zero the player loses on time (the property
/// @e didPlayerLoseOnTime becomes @e true and GoPlayerTimeData posts the
/// notification #playerLostOnTime), except in the following cases:
/// - If the clock is on main time and the time settings define an overtime
///   system, then GoPlayerTimeData switches from main time to overtime and
///   continues to keep time.
/// - If the overtime system that is in effect has more than one period left
///   (Japanese Timing), GoPlayerTimeData deducts a time period and continues
///   to keep time.
/// - If the overtime system that is in effect has the #GoUnusedTimeHandling
///   value #GoUnusedTimeHandlingUseForExtraMoves and the player has already
///   made the minimum number of moves per period, GoPlayerTimeData performs
///   a period reset and continues to keep time.
///
/// GoPlayerTimeData provides several methods with which further time-keeping
/// actions can be triggered. All of these method must be called while the clock
/// is not running.
/// - updateAfterMoveWasPlayed:(): This method must be invoked when the player
///   has made a move. This rounds up any fractional remaining time to the
///   nearest second (see NOTES.Design, section "Working with time data", for
///   details). If main time is in effect no other changes are made to the data
///   of GoPlayerTimeData. If overtime is in effect, the number of moves left
///   to play in the current period is decreased. The current data of
///   GoPlayerTimeData is then recorded in the supplied GoNodeTimeData. Finally,
///   if overtime is in effect, a period reset is performed if necessary.
/// - updateAfterNodeChanged:(): This method must be invoked when the currently
///   selected node changes. GoPlayerTimeData aligns its data to the data
///   recorded in the newly selected node's GoNodeTimeData, or to the game's
///   time settings if the newly selected node is before the first move.
///
/// GoPlayerTimeData posts the following notifications on the main thread:
/// - #playerTimeDataHasChanged: Whenever anything about the time data changes.
/// - #playerClockStateHasChanged: Whenever the state of the internal clock
///   changes.
/// - #playerLostOnTime: When the player loses on time.
///
/// Synchronization notes:
/// - All clock operations are guarded by a lock to make sure that only one
///   active source can change the clock state at a time.
/// - Sources are: 1) The timer that counts down the player clock. 2) The user
///   making a move, or suspending the clock. 3) The computer player making a
///   move.
/// - Other operations are not guarded by a lock because it is expected that
///   concurrency is prevented by other means. In particular, it is expected
///   that the clock is stopped or suspended before the data of GoPlayerTimeData
///   is manipulated in any way (e.g. before updateAfterMoveWasPlayed:() is
///   invoked). The central gatekeeper for this is TimedPlayController.
// -----------------------------------------------------------------------------
@interface GoPlayerTimeData : NSObject <NSSecureCoding>
{
}

- (id) initWithTimeSettings:(GoTimeSettings*)timeSettings
   isTimeDataForBlackPlayer:(bool)isTimeDataForBlackPlayer;

- (void) startClock;
- (void) suspendClockIfNotSuspended:(enum GoClockSuspendedReason)reason;
- (void) stopClockIfNotStopped;

- (bool) didPlayerLoseOnTime;

- (void) updateAfterMoveWasPlayed:(GoNodeTimeData*)nodeTimeData;
- (void) updateAfterNodeChanged:(GoNode*)node;
- (void) updateAfterPlayerLostOnTime;
- (unsigned long) remainingNumberOfMovesOrPeriods;
- (enum GoClockState) clockState;
- (enum GoClockSuspendedReason) clockSuspendedReason;
- (enum GoTimeSystemType) effectiveTimeSystemType;

/// @brief True if this GoPlayerTimeData object holds time data for the black
/// player, false if it holds time data for the white player.
@property(nonatomic, assign, readonly) bool isTimeDataForBlackPlayer;
/// @brief True if @e remainingTimeInSeconds refers to absolute time, false if
/// not.
///
/// The default value after initialization depends on the parameters in the
/// GoTimeSettings object that is supplied to the initializer.
@property(nonatomic, assign, readonly) bool isRemainingTimeAbsoluteTime;
/// @brief The time (in seconds) that the player has left after they played
/// their most recent move.
///
/// The default value after initialization depends on the parameters in the
/// GoTimeSettings object that is supplied to the initializer.
@property(nonatomic, assign, readonly) double remainingTimeInSeconds;
/// @brief The number of moves that the player still has to play in the current
/// time period after they played their most recent move.
///
/// The default value after initialization depends on the parameters in the
/// GoTimeSettings object that is supplied to the initializer.
///
/// The property type must be able to hold an SGFCNumber, to avoid mismatches
/// with the type of property @e remainingNumberOfMoves in GoNodeTimeData.
@property(nonatomic, assign, readonly) unsigned long remainingNumberOfMoves;
/// @brief The number of periods that the player has left after they played
/// their most recent move.
///
/// The default value after initialization depends on the parameters in the
/// GoTimeSettings object that is supplied to the initializer.
///
/// The property type must be able to hold an SGFCNumber, to avoid mismatches
/// with the type of property @e remainingNumberOfPeriods in GoNodeTimeData.
@property(nonatomic, assign, readonly) unsigned long remainingNumberOfPeriods;

@end
