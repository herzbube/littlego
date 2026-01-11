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
@property(nonatomic, assign, readwrite) int numberOfHours;
@property(nonatomic, assign, readwrite) int numberOfMinutes;
@property(nonatomic, assign, readwrite) int numberOfSeconds;
@property(nonatomic, retain, readwrite) NSString* humanReadableString;
//@}
@end


@implementation CompositeDuration

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Returns a human-readable string representation of
/// @a durationInSeconds.
// -----------------------------------------------------------------------------
+ (NSString*) humanReadableStringWithDurationInSeconds:(double)durationInSeconds
{
  CompositeDuration* compositeDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:durationInSeconds] autorelease];
  return compositeDuration.humanReadableString;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a CompositeDuration object that holds the value
/// @a durationInSeconds.
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
// -----------------------------------------------------------------------------
- (id) initWithHours:(int)numberOfHours
             minutes:(int)numberOfMinutes
             seconds:(int)numberOfSeconds
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.durationInSeconds = numberOfHours * 3600 + numberOfMinutes * 60 + numberOfSeconds;
  self.numberOfHours = numberOfHours;
  self.numberOfMinutes = numberOfMinutes;
  self.numberOfSeconds = numberOfSeconds;
  self.humanReadableString = [CompositeDuration stringWithDurationInHours:self.numberOfHours
                                                                  minutes:self.numberOfMinutes
                                                                  seconds:self.numberOfSeconds];

  return self;
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
+ (NSString*) stringWithDurationInHours:(int)numberOfHours
                                minutes:(int)numberOfMinutes
                                seconds:(int)numberOfSeconds
{
  NSString* (^stringWithDuration) (int, NSString*, NSString*) = ^ NSString* (int duration, NSString* singularUnitName, NSString* pluralUnitName)
  {
    if (duration == 0)
      return nil;
    else
      return [NSString stringWithFormat:@"%d %@", duration, (duration == 1 ? singularUnitName : pluralUnitName)];
  };

  if (numberOfHours == 0)
  {
    if (numberOfMinutes == 0)
      return stringWithDuration(numberOfSeconds, @"second", @"seconds");
    else if (numberOfSeconds == 0)
      return stringWithDuration(numberOfMinutes, @"minute", @"minutes");
    else
      return [NSString stringWithFormat:@"%d:%02d minutes", numberOfMinutes, numberOfSeconds];
  }
  else
  {
    if (numberOfMinutes == 0)
      return stringWithDuration(numberOfHours, @"hour", @"hours");
    else
      return [NSString stringWithFormat:@"%d:%02d hours", numberOfHours, numberOfMinutes];
  }
}

@end
