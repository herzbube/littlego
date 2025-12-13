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
/// @brief The GoTimeSystem class represents a time system from the enumeration
/// #GoTimeSystemType. The values of a GoTimeSystem object's properties define
/// how time is to be kept when the time system represented by the GoTimeSystem
/// is in effect.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoTimeSystem : NSObject <NSSecureCoding>
{
}

- (id) init;
- (id) initWithAbsoluteTimeDurationInSeconds:(double)absoluteTimeDurationInSeconds;
- (id) initWithGoTimeSystemType:(enum GoTimeSystemType)goTimeSystemType
        periodDurationInSeconds:(double)periodDurationInSeconds
  minimumNumberOfMovesPerPeriod:(unsigned int)minimumNumberOfMovesPerPeriod
           goUnusedTimeHandling:(enum GoUnusedTimeHandling)goUnusedTimeHandling;
- (id) initWithJapaneseTimeNumberOfPeriods:(unsigned int)numberOfPeriods
                   periodDurationInSeconds:(double)periodDurationInSeconds;
- (id) initWithFischerTimeInitialDurationInSeconds:(double)initialDurationInSeconds
                        extraTimeDurationInSeconds:(double)extraTimeDurationInSeconds;

/// @brief The type of time system that this GoTimeSystem object represents.
///
/// The default value is #GoTimeSystemNone.
@property(nonatomic, assign, readonly) enum GoTimeSystemType goTimeSystemType;
/// @brief The number of time periods the time system has.
///
/// The default value after initialization is 0.
@property(nonatomic, assign, readonly) unsigned int numberOfPeriods;
/// @brief The duration of each time period in seconds.
///
/// The default value after initialization is 0.0.
@property(nonatomic, assign, readonly) double periodDurationInSeconds;
/// @brief Whether or not the time system requires the player to play a minimum
/// number of moves per time period.
///
/// The default value after initialization is false.
@property(nonatomic, assign, readonly) bool hasMinimumNumberOfMovesPerPeriod;
/// @brief The minimum number of moves a player has to make within each time
/// period.
///
/// This property can be ignored if @e hasMinimumNumberOfMovesPerPeriod is
/// false.
///
/// The default value after initialization is 0.
@property(nonatomic, assign, readonly) unsigned int minimumNumberOfMovesPerPeriod;
/// @brief Indicates what to do with the remaining unused time
/// after @e minimumNumberOfMovesPerPeriod have been played.
///
/// This property can be ignored if @e hasMinimumNumberOfMovesPerPeriod is
/// false.
///
/// The default value after initialization is #GoUnusedTimeHandlingNone.
@property(nonatomic, assign, readonly) enum GoUnusedTimeHandling goUnusedTimeHandling;
/// @brief The extra time duration in seconds to be added to the remaining
/// unused time after @e minimumNumberOfMovesPerPeriod have been played.
///
/// This property can be ignored if @e hasMinimumNumberOfMovesPerPeriod is
/// false, or if @e goUnusedTimeHandling is not
/// #GoUnusedTimeHandlingAddExtraTime.
///
/// The default value after initialization is 0.
@property(nonatomic, assign, readonly) double extraTimeDurationInSeconds;

@end
