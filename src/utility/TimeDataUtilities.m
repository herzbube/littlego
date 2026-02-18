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
#import "TimeDataUtilities.h"
#import "NSStringAdditions.h"
#import "../play/timedplay/CompositeDuration.h"
#import "../play/model/TimeSettingsModel.h"


@implementation TimeDataUtilities

// -----------------------------------------------------------------------------
/// @brief Returns a string that is a summary of the values found in
/// @a timeSettingsModel.
// -----------------------------------------------------------------------------
+ (NSString*) timeSettingsModelSummary:(TimeSettingsModel*)timeSettingsModel
{
  NSString* (^periodBasedTimeSystemDescription) (void) = ^ NSString* (void)
  {
    if (timeSettingsModel.periodBasedTimeSystemType == GoTimeSystemTypeCustom)
      return [NSString stringWithFormat:@"custom time system '%@'", timeSettingsModel.customTimeSystemDescription];
    else
      return [NSString shortStringWithPeriodBasedTimeSystemType:timeSettingsModel.periodBasedTimeSystemType];
  };

  if (! timeSettingsModel.timedPlayEnabled)
    return @"No timed play";
  else if (! timeSettingsModel.absoluteTimingEnabled && ! timeSettingsModel.periodBasedTimeSystemEnabled)
    return @"No timed play";
  else if (timeSettingsModel.absoluteTimingEnabled && timeSettingsModel.periodBasedTimeSystemEnabled)
    return [NSString stringWithFormat:@"Main time + Overtime (%@)", periodBasedTimeSystemDescription()];
  else if (timeSettingsModel.absoluteTimingEnabled)
    return @"Main time";
  else if (timeSettingsModel.periodBasedTimeSystemEnabled)
    return [NSString stringWithFormat:@"Overtime (%@)", periodBasedTimeSystemDescription()];
  else
    return @"Unsupported values";
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that is a summary of the absolute time system
/// values found in @a timeSettingsModel.
// -----------------------------------------------------------------------------
+ (NSString*) absoluteTimeSystemSummary:(TimeSettingsModel*)timeSettingsModel
{
  return [TimeDataUtilities absoluteTimeSystemSummary:timeSettingsModel
                                withSecondsResolution:false];
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that is a summary of the absolute time system
/// values found in @a timeSettingsModel. If @a withSecondsResolution is @e true
/// the exact number of seconds is appended to any human-readable strings
/// representing a duration if the string's resolution is not seconds. If
/// @a withSecondsResolution is @e false the exact number of seconds is never
/// appended.
// -----------------------------------------------------------------------------
+ (NSString*) absoluteTimeSystemSummary:(TimeSettingsModel*)timeSettingsModel
                  withSecondsResolution:(bool)withSecondsResolution
{
  if (! timeSettingsModel.timedPlayEnabled)
    return @"No timed play";
  else if (! timeSettingsModel.absoluteTimingEnabled)
    return @"No main time";
  else
    return [CompositeDuration humanReadableStringWithDurationInSeconds:timeSettingsModel.absoluteTimingDurationInSeconds
                                                 withSecondsResolution:withSecondsResolution];
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that is a summary of the period-based time system
/// values found in @a timeSettingsModel.
// -----------------------------------------------------------------------------
+ (NSString*) periodBasedTimeSystemSummary:(TimeSettingsModel*)timeSettingsModel
{
  return [TimeDataUtilities periodBasedTimeSystemSummary:timeSettingsModel
                                   withSecondsResolution:false];
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that is a summary of the period-based time system
/// values found in @a timeSettingsModel. If @a withSecondsResolution is @e true
/// the exact number of seconds is appended to any human-readable strings
/// representing a duration if the string's resolution is not seconds. If
/// @a withSecondsResolution is @e false the exact number of seconds is never
/// appended.
// -----------------------------------------------------------------------------
+ (NSString*) periodBasedTimeSystemSummary:(TimeSettingsModel*)timeSettingsModel
                     withSecondsResolution:(bool)withSecondsResolution
{
  if (! timeSettingsModel.timedPlayEnabled)
    return @"No timed play";
  else if (! timeSettingsModel.periodBasedTimeSystemEnabled)
    return @"No overtime";

  NSString* (^stringWithNumberOfMoves) (unsigned long) = ^ NSString* (unsigned long numberOfMoves)
  {
    if (numberOfMoves == 1)
      return @"per move";
    else
      return [NSString stringWithFormat:@"for every %lu moves", numberOfMoves];
  };

  switch (timeSettingsModel.periodBasedTimeSystemType)
  {
    case GoTimeSystemTypeCanadian:
    {
      NSString* periodDurationString = [CompositeDuration humanReadableStringWithDurationInSeconds:timeSettingsModel.canadianTimingPeriodDurationInSeconds
                                                                             withSecondsResolution:withSecondsResolution];
      return [NSString stringWithFormat:@"Canadian Timing, %@ %@",
              periodDurationString,
              stringWithNumberOfMoves(timeSettingsModel.canadianTimingNumberOfMoves)];
    }
    case GoTimeSystemTypeJapanese:
    {
      NSString* periodDurationString = [CompositeDuration humanReadableStringWithDurationInSeconds:timeSettingsModel.japaneseTimingPeriodDurationInSeconds
                                                                             withSecondsResolution:withSecondsResolution];
      NSString* numberOfPeriodsString = (timeSettingsModel.japaneseTimingNumberOfPeriods == 1
                                         ? @"one period"
                                         : [NSString stringWithFormat:@"%lu periods", timeSettingsModel.japaneseTimingNumberOfPeriods]);
      return [NSString stringWithFormat:@"Japanese Timing, %@ per move, %@",
              periodDurationString,
              numberOfPeriodsString];
    }
    case GoTimeSystemTypeFischer:
    {
      NSString* initialTimeDurationString = [CompositeDuration humanReadableStringWithDurationInSeconds:timeSettingsModel.fischerTimingInitialTimeDurationInSeconds
                                                                                  withSecondsResolution:withSecondsResolution];
      NSString* extraTimeDurationString = [CompositeDuration humanReadableStringWithDurationInSeconds:timeSettingsModel.fischerTimingExtraTimeDurationInSeconds
                                                                                withSecondsResolution:withSecondsResolution];
      return [NSString stringWithFormat:@"Fischer Timing, %@ initial time, %@ extra time after each move",
              initialTimeDurationString,
              extraTimeDurationString];
    }
    case GoTimeSystemTypeSteadyAverage:
    {
      NSString* periodDurationString = [CompositeDuration humanReadableStringWithDurationInSeconds:timeSettingsModel.steadyAverageTimingPeriodDurationInSeconds
                                                                             withSecondsResolution:withSecondsResolution];
      return [NSString stringWithFormat:@"Steady Average Timing, %@ %@",
              periodDurationString,
              stringWithNumberOfMoves(timeSettingsModel.steadyAverageTimingNumberOfMoves)];
    }
    case GoTimeSystemTypeTotalAverage:
    {
      NSString* periodDurationString = [CompositeDuration humanReadableStringWithDurationInSeconds:timeSettingsModel.totalAverageTimingPeriodDurationInSeconds
                                                                             withSecondsResolution:withSecondsResolution];
      return [NSString stringWithFormat:@"Total Average Timing, %@ %@",
              periodDurationString,
              stringWithNumberOfMoves(timeSettingsModel.totalAverageTimingNumberOfMoves)];
    }
    case GoTimeSystemTypeCustom:
    {
      return [NSString stringWithFormat:@"Custom time system '%@'", timeSettingsModel.customTimeSystemDescription];
    }
    default:
    {
      return @"Unexpected time system type";
    }
  }
}

@end
