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
#import "TimeSettingsModel.h"
#import "../../go/GoTimeSettings.h"
#import "../../go/GoTimeSystem.h"
#import "../../utility/ExceptionUtility.h"


@implementation TimeSettingsModel

// -----------------------------------------------------------------------------
/// @brief Initializes a TimeSettingsModel object with default values.
///
/// @note This is the designated initializer of TimeSettingsModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.timedPlayEnabled = false;
  self.absoluteTimingEnabled = true;
  self.absoluteTimingDurationInSeconds = 600.0;
  self.periodBasedTimeSystemEnabled = true;
  self.periodBasedTimeSystemType = GoTimeSystemTypeCanadian;
  self.canadianTimingPeriodDurationInSeconds = 600.0;
  self.canadianTimingNumberOfMoves = 25;
  self.japaneseTimingPeriodDurationInSeconds = 60.0;
  self.japaneseTimingNumberOfPeriods = 30;
  self.fischerTimingInitialTimeDurationInSeconds = 300.0;
  self.fischerTimingExtraTimeDurationInSeconds = 15.0;
  self.steadyAverageTimingPeriodDurationInSeconds = 600.0;
  self.steadyAverageTimingNumberOfMoves = 25;
  self.totalAverageTimingPeriodDurationInSeconds = 600.0;
  self.totalAverageTimingNumberOfMoves = 25.0;
  self.customTimeSystemDescription = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimeSettingsModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets the values of all properties with values read from
/// @a dictionary.
// -----------------------------------------------------------------------------
- (void) readFromDictionary:(NSDictionary*)dictionary
{
  self.timedPlayEnabled = [[dictionary valueForKey:timedPlayEnabledKey] boolValue];
  self.absoluteTimingEnabled = [[dictionary valueForKey:absoluteTimingEnabledKey] boolValue];
  self.absoluteTimingDurationInSeconds = [(NSNumber*)[dictionary valueForKey:absoluteTimingDurationInSecondsKey] doubleValue];
  self.periodBasedTimeSystemEnabled = [[dictionary valueForKey:periodBasedTimeSystemEnabledKey] boolValue];
  self.periodBasedTimeSystemType = [[dictionary valueForKey:periodBasedTimeSystemTypeKey] intValue];
  self.canadianTimingPeriodDurationInSeconds = [(NSNumber*)[dictionary valueForKey:canadianTimingPeriodDurationInSecondsKey] doubleValue];
  self.canadianTimingNumberOfMoves = [[dictionary valueForKey:canadianTimingNumberOfMovesKey] unsignedLongValue];
  self.japaneseTimingPeriodDurationInSeconds = [(NSNumber*)[dictionary valueForKey:japaneseTimingPeriodDurationInSecondsKey] doubleValue];
  self.japaneseTimingNumberOfPeriods = [[dictionary valueForKey:japaneseTimingNumberOfPeriodsKey] unsignedLongValue];
  self.fischerTimingInitialTimeDurationInSeconds = [(NSNumber*)[dictionary valueForKey:fischerTimingInitialTimeDurationInSecondsKey] doubleValue];
  self.fischerTimingExtraTimeDurationInSeconds = [(NSNumber*)[dictionary valueForKey:fischerTimingExtraTimeDurationInSecondsKey] doubleValue];
  self.steadyAverageTimingPeriodDurationInSeconds = [(NSNumber*)[dictionary valueForKey:steadyAverageTimingPeriodDurationInSecondsKey] doubleValue];
  self.steadyAverageTimingNumberOfMoves = [[dictionary valueForKey:steadyAverageTimingNumberOfMovesKey] unsignedLongValue];
  self.totalAverageTimingPeriodDurationInSeconds = [(NSNumber*)[dictionary valueForKey:totalAverageTimingPeriodDurationInSecondsKey] doubleValue];
  self.totalAverageTimingNumberOfMoves = [[dictionary valueForKey:totalAverageTimingNumberOfMovesKey] unsignedLongValue];

  // Property is not part of user defaults, it exists only to convert from/to
  // GoTimeSettings
  self.customTimeSystemDescription = nil;
}

// -----------------------------------------------------------------------------
/// @brief Writes the values of all properties into @a dictionary.
// -----------------------------------------------------------------------------
- (void) writeToDictionary:(NSMutableDictionary*)dictionary
{
  [dictionary setValue:[NSNumber numberWithBool:self.timedPlayEnabled] forKey:timedPlayEnabledKey];
  [dictionary setValue:[NSNumber numberWithBool:self.absoluteTimingEnabled] forKey:absoluteTimingEnabledKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.absoluteTimingDurationInSeconds] forKey:absoluteTimingDurationInSecondsKey];
  [dictionary setValue:[NSNumber numberWithBool:self.periodBasedTimeSystemEnabled] forKey:periodBasedTimeSystemEnabledKey];
  [dictionary setValue:[NSNumber numberWithInt:self.periodBasedTimeSystemType] forKey:periodBasedTimeSystemTypeKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.canadianTimingPeriodDurationInSeconds] forKey:canadianTimingPeriodDurationInSecondsKey];
  [dictionary setValue:[NSNumber numberWithUnsignedLong:self.canadianTimingNumberOfMoves] forKey:canadianTimingNumberOfMovesKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.japaneseTimingPeriodDurationInSeconds] forKey:japaneseTimingPeriodDurationInSecondsKey];
  [dictionary setValue:[NSNumber numberWithUnsignedLong:self.japaneseTimingNumberOfPeriods] forKey:japaneseTimingNumberOfPeriodsKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.fischerTimingInitialTimeDurationInSeconds] forKey:fischerTimingInitialTimeDurationInSecondsKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.fischerTimingExtraTimeDurationInSeconds] forKey:fischerTimingExtraTimeDurationInSecondsKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.steadyAverageTimingPeriodDurationInSeconds] forKey:steadyAverageTimingPeriodDurationInSecondsKey];
  [dictionary setValue:[NSNumber numberWithUnsignedLong:self.steadyAverageTimingNumberOfMoves] forKey:steadyAverageTimingNumberOfMovesKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.totalAverageTimingPeriodDurationInSeconds] forKey:totalAverageTimingPeriodDurationInSecondsKey];
  [dictionary setValue:[NSNumber numberWithUnsignedLong:self.totalAverageTimingNumberOfMoves] forKey:totalAverageTimingNumberOfMovesKey];

  // Don't write self.customTimeSystemDescription to user defaults. The property
  // exists only to convert from/to GoTimeSettings
}

// -----------------------------------------------------------------------------
/// @brief Sets the values of selected properties with values represented by
/// @a goTimeSettings. Only those properties are touched that correspond to the
/// time systems found in @a goTimeSettings.
///
/// @exception InvalidArgumentException Is raised if @a goTimeSettings is
/// @e nil, or if the period-based GoTimeSystem object's time system type has
/// an unexpected value.
// -----------------------------------------------------------------------------
- (void) updateWithGoTimeSettings:(GoTimeSettings*)goTimeSettings
{
  if (! goTimeSettings)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"updateWithGoTimeSettings: goTimeSettings is nil"];

  GoTimeSystem* absoluteTimeSystem = goTimeSettings.absoluteTimeSystem;
  GoTimeSystem* periodBasedTimeSystem = goTimeSettings.periodBasedTimeSystem;

  if (absoluteTimeSystem.goTimeSystemType == GoTimeSystemTypeNone)
    self.absoluteTimingEnabled = false;
  else
    self.absoluteTimingDurationInSeconds = absoluteTimeSystem.periodDurationInSeconds;

  self.periodBasedTimeSystemType = periodBasedTimeSystem.goTimeSystemType;
  switch (periodBasedTimeSystem.goTimeSystemType)
  {
    case GoTimeSystemTypeNone:
      self.periodBasedTimeSystemEnabled = false;
      break;
    case GoTimeSystemTypeCanadian:
      self.canadianTimingPeriodDurationInSeconds = periodBasedTimeSystem.periodDurationInSeconds;
      self.canadianTimingNumberOfMoves = periodBasedTimeSystem.minimumNumberOfMovesPerPeriod;
      break;
    case GoTimeSystemTypeJapanese:
      self.japaneseTimingPeriodDurationInSeconds = periodBasedTimeSystem.periodDurationInSeconds;
      self.japaneseTimingNumberOfPeriods = periodBasedTimeSystem.numberOfPeriods;
      break;
    case GoTimeSystemTypeFischer:
      self.fischerTimingInitialTimeDurationInSeconds = periodBasedTimeSystem.periodDurationInSeconds;
      self.fischerTimingExtraTimeDurationInSeconds = periodBasedTimeSystem.extraTimeDurationInSeconds;
      break;
    case GoTimeSystemTypeSteadyAverage:
      self.steadyAverageTimingPeriodDurationInSeconds = periodBasedTimeSystem.periodDurationInSeconds;
      self.steadyAverageTimingNumberOfMoves = periodBasedTimeSystem.minimumNumberOfMovesPerPeriod;
      break;
    case GoTimeSystemTypeTotalAverage:
      self.totalAverageTimingPeriodDurationInSeconds = periodBasedTimeSystem.periodDurationInSeconds;
      self.totalAverageTimingNumberOfMoves = periodBasedTimeSystem.minimumNumberOfMovesPerPeriod;
      break;
    case GoTimeSystemTypeCustom:
      self.customTimeSystemDescription = periodBasedTimeSystem.customTimeSystemDescription;
      break;
    default:
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:[NSString stringWithFormat:@"updateWithGoTimeSettings: Invalid period-based time system type %d", periodBasedTimeSystem.goTimeSystemType]];
      break;
  }

  self.timedPlayEnabled = (self.absoluteTimingEnabled ||
                           self.periodBasedTimeSystemEnabled);
}

// -----------------------------------------------------------------------------
/// @brief Captures the current settings and returns them as a newly allocated
/// GoTimeSettings object.
///
/// @exception NSInternalInconsistencyException Is raised if
/// @e periodBasedTimeSystemEnabled is true and @e periodBasedTimeSystemType has
/// an unexpected value.
///
/// @exception InvalidArgumentException Is raised if any property value of this
/// TimeSettingsModel is invalid for constructing a GoTimeSystem object.
// -----------------------------------------------------------------------------
- (GoTimeSettings*) goTimeSettingsRepresentation
{
  if (! self.timedPlayEnabled)
    return [[[GoTimeSettings alloc] init] autorelease];

  GoTimeSystem* absoluteTimeSystem;
  if (self.absoluteTimingEnabled)
    absoluteTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:self.absoluteTimingDurationInSeconds] autorelease];
  else
    absoluteTimeSystem = [[[GoTimeSystem alloc] init] autorelease];

  GoTimeSystem* periodBasedTimeSystem;
  if (self.periodBasedTimeSystemEnabled)
  {
    switch (self.periodBasedTimeSystemType)
    {
      case GoTimeSystemTypeCanadian:
      {
        periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:self.periodBasedTimeSystemType
                                                        periodDurationInSeconds:self.canadianTimingPeriodDurationInSeconds
                                                  minimumNumberOfMovesPerPeriod:self.canadianTimingNumberOfMoves] autorelease];
        break;
      }
      case GoTimeSystemTypeJapanese:
      {
        periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:self.japaneseTimingNumberOfPeriods
                                                                   periodDurationInSeconds:self.japaneseTimingPeriodDurationInSeconds] autorelease];
        break;
      }
      case GoTimeSystemTypeFischer:
      {
        periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:self.fischerTimingInitialTimeDurationInSeconds
                                                                        extraTimeDurationInSeconds:self.fischerTimingExtraTimeDurationInSeconds] autorelease];
        break;
      }
      case GoTimeSystemTypeSteadyAverage:
      {
        periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:self.periodBasedTimeSystemType
                                                        periodDurationInSeconds:self.steadyAverageTimingPeriodDurationInSeconds
                                                  minimumNumberOfMovesPerPeriod:self.steadyAverageTimingNumberOfMoves] autorelease];
        break;
      }
      case GoTimeSystemTypeTotalAverage:
      {
        periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:self.periodBasedTimeSystemType
                                                        periodDurationInSeconds:self.totalAverageTimingPeriodDurationInSeconds
                                                  minimumNumberOfMovesPerPeriod:self.totalAverageTimingNumberOfMoves] autorelease];
        break;
      }
      case GoTimeSystemTypeCustom:
      {
        periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:self.customTimeSystemDescription] autorelease];
        break;
      }
      default:
      {
        NSString* errorMessage = [NSString stringWithFormat:@"goTimeSettingsRepresentation: Invalid period-based time system type %d", self.periodBasedTimeSystemType];
        [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];

        // Dummy assign to make compiler happy (compiler does not see that an
        // exception is thrown)
        periodBasedTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
        break;
      }
    }
  }
  else
  {
    periodBasedTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  }

  return [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                       periodBasedTimeSystem:periodBasedTimeSystem] autorelease];
}

@end
