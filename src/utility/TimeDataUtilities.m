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
/// @brief Returns a string that is a summary of the period-based time system
/// values found in @a timeSettingsModel.
// -----------------------------------------------------------------------------
+ (NSString*) periodBasedTimeSystemSummary:(TimeSettingsModel*)timeSettingsModel
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
      CompositeDuration* periodDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:timeSettingsModel.canadianTimingPeriodDurationInSeconds] autorelease];
      return [NSString stringWithFormat:@"Canadian Timing, %@ %@",
              periodDuration.humanReadableString,
              stringWithNumberOfMoves(timeSettingsModel.canadianTimingNumberOfMoves)];
    }
    case GoTimeSystemTypeJapanese:
    {
      CompositeDuration* periodDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:timeSettingsModel.japaneseTimingPeriodDurationInSeconds] autorelease];
      NSString* numberOfPeriodsString = (timeSettingsModel.japaneseTimingNumberOfPeriods == 1
                                         ? @"one period"
                                         : [NSString stringWithFormat:@"%lu periods", timeSettingsModel.japaneseTimingNumberOfPeriods]);
      return [NSString stringWithFormat:@"Japanese Timing, %@ per move, %@",
              periodDuration.humanReadableString,
              numberOfPeriodsString];
    }
    case GoTimeSystemTypeFischer:
    {
      CompositeDuration* initialTimeDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:timeSettingsModel.fischerTimingInitialTimeDurationInSeconds] autorelease];
      CompositeDuration* extraTimeDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:timeSettingsModel.fischerTimingExtraTimeDurationInSeconds] autorelease];
      return [NSString stringWithFormat:@"Fischer Timing, %@ initial time, %@ extra time after each move",
              initialTimeDuration.humanReadableString,
              extraTimeDuration.humanReadableString];
    }
    case GoTimeSystemTypeSteadyAverage:
    {
      CompositeDuration* periodDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:timeSettingsModel.steadyAverageTimingPeriodDurationInSeconds] autorelease];
      return [NSString stringWithFormat:@"Steady Average Timing, %@ %@",
              periodDuration.humanReadableString,
              stringWithNumberOfMoves(timeSettingsModel.steadyAverageTimingNumberOfMoves)];
    }
    case GoTimeSystemTypeTotalAverage:
    {
      CompositeDuration* periodDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:timeSettingsModel.totalAverageTimingPeriodDurationInSeconds] autorelease];
      return [NSString stringWithFormat:@"Total Average Timing, %@ %@",
              periodDuration.humanReadableString,
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
