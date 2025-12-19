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


// Forward declarations
@class GoClock;
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
/// TODO xxx document how clients are responsible for managing the clock.
/// Ideally they should not even have access, but this may not be feasible
/// without mirroring the GoClock interface.
// -----------------------------------------------------------------------------
@interface GoPlayerTimeData : NSObject <NSSecureCoding>
{
}

- (id) initWithTimeSettings:(GoTimeSettings*)timeSettings
   isTimeDataForBlackPlayer:(bool)isTimeDataForBlackPlayer;

- (void) startClock;
- (void) suspendClock:(enum GoClockSuspendedReason)reason;

- (enum GoPeriodDurationElapsedResultType) updateAfterNodeChanged:(GoNode*)Node
                                                        forPlayer:(enum GoColor)goColor;
- (enum GoPeriodDurationElapsedResultType) updateAfterMoveWasPlayed:(double)timeUsedForMoveInSeconds
                                                     goNodeTimeData:(GoNodeTimeData*)goNodeTimeData;
- (double) timeWithoutMoveUntilGameIsLostOnTime;
- (int) remainingNumberOfMovesOrPeriods;
- (enum GoClockState) clockState;

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
@property(nonatomic, assign, readonly) unsigned int remainingNumberOfMoves;
/// @brief The number of periods that the player has left after they played
/// their most recent move.
///
/// The default value after initialization depends on the parameters in the
/// GoTimeSettings object that is supplied to the initializer.
@property(nonatomic, assign, readonly) unsigned int remainingNumberOfPeriods;

@end
