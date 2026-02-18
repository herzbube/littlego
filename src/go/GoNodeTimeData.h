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
/// @brief The GoNodeTimeData class extends a game tree node that also contains
/// a move with time-related properties that refer to the move.
///
/// @ingroup go
///
/// @e remainingTimeInSeconds is always used, regardless of which time system is
/// in effect. @e isRemainingTimeAbsoluteTime indicates whether or not
/// @e remainingTimeInSeconds refers to absolute time.
///
/// @e remainingNumberOfMoves is not used, i.e. it always stores the value
/// 0 (zero), if @e isRemainingTimeAbsoluteTime is true. The reason is that
/// Absolute Timing has no minimum number of moves per period limit.
///
/// @e remainingNumberOfPeriods can never be 0 (zero) because if a player has
/// no time period left they lose and cannot play another move.
///
/// @e remainingNumberOfMoves on the other hand can and will be 0 (zero) when a
/// player has played their minimum number of moves per time period. In time
/// systems where the player is allowed to use the unused time to play extra
/// moves, the value of @e remainingNumberOfMoves may remain 0 (zero) for
/// several turns.
///
///
/// @par Japanese Timing notes
///
/// The data model represented by GoNodeTimeData is capable of storing values
/// for both @e remainingNumberOfMoves and @e remainingNumberOfPeriods at the
/// same time. So in theory the app is able to support a custom time system
/// that resembles Japanese Timing, i.e. has a variable number of time periods,
/// but at the same time also has a variable minimum number of moves per period.
///
/// In practice, though, such a time system cannot be supported, because the
/// SGF specification provides only one time property to hold the data for
/// either @e remainingNumberOfMoves or @e remainingNumberOfPeriods (OB or OW,
/// depending on whether the data is for the black or the white player).
///
/// If we were to strictly adhere to the SGF specification, we would not even
/// be allowed to store @e remainingNumberOfPeriods, because the specification
/// defines OB/OW as the "Number of black/white moves left (after the move of
/// this node was played) to play in this byo-yomi period.", thus restricting
/// OB/OW to @e remainingNumberOfMoves. It was found, though, that KGS and
/// online-go.com use OB/OW to store the number of time periods when Japanese
/// Timing is used, so this app follows the example of these Go servers.
// -----------------------------------------------------------------------------
@interface GoNodeTimeData : NSObject <NSSecureCoding>
{
}

/// @brief True if this GoNodeTimeData object holds time data for the black
/// player, false if it holds time data for the white player.
@property(nonatomic, assign) bool isTimeDataForBlackPlayer;

/// @brief True if @e remainingTimeInSeconds refers to absolute time, false if
/// not.
///
/// The default value after initialization is false.
@property(nonatomic, assign) bool isRemainingTimeAbsoluteTime;
/// @brief The time (in seconds) that the player has left after they played the
/// move in the game tree node that this GoNodeTimeData is associated with.
///
/// The default value after initialization is 0 (zero).
///
/// This property corresponds to the SGF time properties BL and WL.
@property(nonatomic, assign) double remainingTimeInSeconds;
/// @brief The number of moves that the player still has to play in the current
/// time period after they played the move in the game tree node that this
/// GoNodeTimeData is associated with.
///
/// This property can be ignored if @e isRemainingTimeAbsoluteTime is true.
///
/// The default value after initialization is 0 (zero).
///
/// This property corresponds to the SGF time properties OB and OW. The property
/// type must be able to hold an SGFCNumber. See the GoNodeTimeData class
/// documentation for details.
@property(nonatomic, assign) unsigned long remainingNumberOfMoves;
/// @brief The number of time periods that the player has left after they played
/// the move in the game tree node that this GoNodeTimeData is associated with.
///
/// This property can be ignored if @e isRemainingTimeAbsoluteTime is true.
///
/// The default value after initialization is 0 (zero).
///
/// This property corresponds to the SGF time properties OB and OW. The property
/// type must be able to hold an SGFCNumber. See the GoNodeTimeData class
/// documentation for details.
@property(nonatomic, assign) unsigned long remainingNumberOfPeriods;

@end
