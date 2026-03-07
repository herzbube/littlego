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


// Forward declarations
@class GoGame;
@class GoNode;

// -----------------------------------------------------------------------------
/// @brief The CompositeDuration class stores a duration value in whole seconds
/// and provides access to the value in the form of hours, minutes and seconds.
/// Fractional seconds are rounded up to the nearest whole second number on
/// initialization. CompositeDuration is immutable.
// -----------------------------------------------------------------------------
@interface CompositeDuration : NSObject
{
}

+ (NSString*) humanReadableStringWithDurationInSeconds:(double)durationInSeconds;
+ (NSString*) humanReadableStringWithDurationInSeconds:(double)durationInSeconds
                                 withSecondsResolution:(bool)withSecondsResolution;

- (id) initWithDurationInSeconds:(double)durationInSeconds;
- (id) initWithHours:(long)numberOfHours
             minutes:(short)numberOfMinutes
             seconds:(short)numberOfSeconds;

@property(nonatomic, assign, readonly) double durationInSeconds;
@property(nonatomic, assign, readonly) long numberOfHours;
@property(nonatomic, assign, readonly) short numberOfMinutes;
@property(nonatomic, assign, readonly) short numberOfSeconds;

/// @brief A human-readable string representation of the duration value stored
/// by this CompositeDuration.
///
/// The resolution that the string representation uses depends on the duration
/// value:
/// - The resolution is "seconds" if the duration is less than 60 seconds
///   (1 minute). The string representation in this case always reads as
///   "<s> seconds".
/// - The resolution is "minutes" if the duration is 60 seconds or more but
///   less than 3600 seconds (1 hour). The string representation in this case
///   reads either as "<m>:<ss> minutes", or as "<m> minutes" if the duration
///   is a whole number of minutes.
/// - The resolution is "hours" if the duration is 3600 seconds (1 hour) or
///   more. The string representation in this case reads either as
///   "<h>:<mm> minutes", or as "<h> hours" if the duration is a whole number
///   of hours. Any surplus number of seconds are truncated, assuming that the
///   number is irrelevant.
///
/// Additional notes:
/// - For whole-minute and whole-hour durations, the string representation
///   uses singular/plural, e.g. "1 minute" or "2 minutes".
/// - If the exact number of seconds is relevant, the class method
///   humanReadableStringWithDurationInSeconds:withSecondsResolution:() can be
///   used to obtain a human-readable string where the exact number of seconds
///   is appended to the usual human-readable string.
@property(nonatomic, retain, readonly) NSString* humanReadableString;

@end
