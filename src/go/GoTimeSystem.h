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
- (id) initWithCustomTimeSystemDescription:(NSString*)customTimeSystemDescription;
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
@property(nonatomic, assign, readonly) enum GoTimeSystemType goTimeSystemType;
/// @brief A string describing the time system when @e goTimeSystemType has
/// the type #GoTimeSystemTypeCustom. Is @e nil if @e goTimeSystemType has some
/// other type.
///
/// This property corresponds to the SGF time property OT. It is used when the
/// app fails to parse the value of the OT property.
@property(nonatomic, retain, readonly) NSString* customTimeSystemDescription;
/// @brief True if the app supports timed play with the time system represented
/// by this GoTimeSystem object. False if not.
///
/// The app does not support timed play for time systems #GoTimeSystemTypeNone
/// and #GoTimeSystemTypeCustom. The app supports timed play for all other time
/// systems.
@property(nonatomic, assign, readonly) bool supportsTimedPlay;
/// @brief The number of time periods the time system has.
@property(nonatomic, assign, readonly) unsigned int numberOfPeriods;
/// @brief The duration of each time period in seconds.
@property(nonatomic, assign, readonly) double periodDurationInSeconds;
/// @brief Whether or not the time system requires the player to play a minimum
/// number of moves per time period.
@property(nonatomic, assign, readonly) bool hasMinimumNumberOfMovesPerPeriod;
/// @brief The minimum number of moves a player has to make within each time
/// period.
///
/// This property can be ignored if @e hasMinimumNumberOfMovesPerPeriod is
/// false.
@property(nonatomic, assign, readonly) unsigned int minimumNumberOfMovesPerPeriod;
/// @brief Indicates what to do with the remaining unused time
/// after @e minimumNumberOfMovesPerPeriod have been played.
///
/// This property can be ignored if @e hasMinimumNumberOfMovesPerPeriod is
/// false.
@property(nonatomic, assign, readonly) enum GoUnusedTimeHandling goUnusedTimeHandling;
/// @brief The extra time duration in seconds to be added to the remaining
/// unused time after @e minimumNumberOfMovesPerPeriod have been played.
///
/// This property can be ignored if @e hasMinimumNumberOfMovesPerPeriod is
/// false, or if @e goUnusedTimeHandling is not
/// #GoUnusedTimeHandlingAddExtraTime.
@property(nonatomic, assign, readonly) double extraTimeDurationInSeconds;

@end
