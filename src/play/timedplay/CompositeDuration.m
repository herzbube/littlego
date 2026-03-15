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


// Project includes
#import "CompositeDuration.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for CompositeDuration.
// -----------------------------------------------------------------------------
@interface CompositeDuration()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) double durationInSeconds;
@property(nonatomic, assign, readwrite) long numberOfHours;
@property(nonatomic, assign, readwrite) short numberOfMinutes;
@property(nonatomic, assign, readwrite) short numberOfSeconds;
@property(nonatomic, retain, readwrite) NSString* humanReadableString;
//@}
@end


@implementation CompositeDuration

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Returns a human-readable string representation of
/// @a durationInSeconds (rounded up to the nearest whole second).
///
/// See the documentation of property @e humanReadableString for details about
/// how the human-readable string looks like.
// -----------------------------------------------------------------------------
+ (NSString*) humanReadableStringWithDurationInSeconds:(double)durationInSeconds
{
  return [CompositeDuration humanReadableStringWithDurationInSeconds:durationInSeconds
                                               withSecondsResolution:false];
}

// -----------------------------------------------------------------------------
/// @brief Returns a human-readable string representation of
/// @a durationInSeconds (rounded up to the nearest whole second). The value
/// of @a withSecondsResolution depends whether or not the exact number of
/// seconds is appended to the human-readable string.
///
/// If @a withSecondsResolution is @e true the exact number of seconds is
/// appended to the human-readable string, but only if the string's resolution
/// is @b not seconds. The appended string looks like this: " (<s> seconds)".
/// Examples:
/// - "2:34 minutes (154 seconds)"
/// - "2:34 hours (9240 seconds)"
/// - "2:34 hours (9290 seconds)" (because @a durationInSeconds is not a whole
///    number of minutes, the 50 surplus seconds become visible in the appended
///    string)
/// - "23 seconds" (because @a durationInSeconds is less than 60 seconds the
///   human-readable string's resolution is seconds and no string is appended)
///
/// If @a withSecondsResolution is @e false the exact number of seconds is
/// never appended.
///
/// See the documentation of property @e humanReadableString for details about
/// how the human-readable string looks like.
// -----------------------------------------------------------------------------
+ (NSString*) humanReadableStringWithDurationInSeconds:(double)durationInSeconds
                                 withSecondsResolution:(bool)withSecondsResolution;
{
  CompositeDuration* compositeDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:durationInSeconds] autorelease];

  // Use compositeDuration.durationInSeconds to make sure to use the rounded-up
  // value
  if (withSecondsResolution && fabs(compositeDuration.durationInSeconds) >= 60.0)
    return [NSString stringWithFormat:@"%@ (%@ seconds)", compositeDuration.humanReadableString, [CompositeDuration formattedDurationInSecondsString:compositeDuration.durationInSeconds]];
  else
    return compositeDuration.humanReadableString;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a CompositeDuration object that holds the value
/// @a durationInSeconds (rounded up to the nearest whole second). The value
/// of @a durationInSeconds is decomposed into hours, minutes and seconds
/// which are then available in the properties @e numberOfHours,
/// @e numberOfMinutes and/or @e numberOfSeconds of the initialized
/// CompositeDuration object.
///
/// @note This is the designated initializer of CompositeDuration.
// -----------------------------------------------------------------------------
- (id) initWithDurationInSeconds:(double)durationInSeconds
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  durationInSeconds = ceil(durationInSeconds);

  self.durationInSeconds = durationInSeconds;
  self.numberOfHours = durationInSeconds / 3600;
  durationInSeconds -= self.numberOfHours * 3600;
  self.numberOfMinutes = durationInSeconds / 60;
  self.numberOfSeconds = durationInSeconds - self.numberOfMinutes * 60;
  self.humanReadableString = [CompositeDuration stringWithDurationInHours:self.numberOfHours
                                                                  minutes:self.numberOfMinutes
                                                                  seconds:self.numberOfSeconds];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a CompositeDuration object that holds a duration in
/// seconds that corresponds to the sum of @a numberOfHours, @a numberOfMinutes
/// and @a numberOfSeconds.
///
/// The supplied parameters are used to calculate the total duration in seconds,
/// which is then used to invoke the designated initializer. This means that if
/// you supply values for @a numberOfMinutes and/or @a numberOfSeconds that are
/// greater than 60, then the properties @e numberOfHours, @e numberOfMinutes
/// and/or @e numberOfSeconds of the initialized CompositeDuration object may
/// be different than the values you supply to this initializer.
// -----------------------------------------------------------------------------
- (id) initWithHours:(long)numberOfHours
             minutes:(short)numberOfMinutes
             seconds:(short)numberOfSeconds
{
  double durationInSeconds = numberOfHours * 3600 + numberOfMinutes * 60 + numberOfSeconds;
  return [self initWithDurationInSeconds:durationInSeconds];
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CompositeDuration object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.humanReadableString = nil;
  
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a human-readable string representation of the duration
/// represented by @a numberOfHours, @a numberOfMinutes and @a numberOfSeconds.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithDurationInHours:(long)numberOfHours
                                minutes:(int)numberOfMinutes
                                seconds:(int)numberOfSeconds
{
  NSString* (^stringWithDuration) (long, NSString*, NSString*) = ^ NSString* (long duration, NSString* singularUnitName, NSString* pluralUnitName)
  {
    return [NSString stringWithFormat:@"%ld %@", duration, (duration == 1 ? singularUnitName : pluralUnitName)];
  };

  if (numberOfHours == 0)
  {
    if (numberOfMinutes == 0)
      return stringWithDuration(numberOfSeconds, @"second", @"seconds");
    else if (numberOfSeconds == 0)
      return stringWithDuration(numberOfMinutes, @"minute", @"minutes");
    else
      return [NSString stringWithFormat:@"%d:%02d minutes", numberOfMinutes, abs(numberOfSeconds)];
  }
  else
  {
    if (numberOfMinutes == 0)
      return stringWithDuration(numberOfHours, @"hour", @"hours");
    else
      return [NSString stringWithFormat:@"%ld:%02d hours", numberOfHours, abs(numberOfMinutes)];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a formatted string representation of @a durationInSeconds.
/// @a durationInSeconds is expected to be in whole seconds.
// -----------------------------------------------------------------------------
+ (NSString*) formattedDurationInSecondsString:(double)durationInSeconds
{
  // This implementation uses NSNumberFormatter because of its capability of
  // inserting thousands separators when we use NSNumberFormatterDecimalStyle.
  NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
  // Setting the decimal style also sets the formatter's maximumFractionDigits
  // property to value 3, but we don't care because we always get a whole
  // number of seconds.
  formatter.numberStyle = NSNumberFormatterDecimalStyle;
  return [formatter stringFromNumber:[NSNumber numberWithDouble:durationInSeconds]];
}

@end
