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
@property(nonatomic, retain, readonly) NSString* humanReadableString;

@end
