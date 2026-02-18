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


// Test includes
#import "GoTimeSystemTest.h"

// Application includes
#import <go/GoTimeSystem.h>


@implementation GoTimeSystemTest

// -----------------------------------------------------------------------------
/// @brief Excercises the init() initializer.
// -----------------------------------------------------------------------------
- (void) testInit
{
  GoTimeSystem* timeSystem = [[[GoTimeSystem alloc] init] autorelease];
  XCTAssertEqual(timeSystem.goTimeSystemType, GoTimeSystemTypeNone);
  XCTAssertNil(timeSystem.customTimeSystemDescription);
  XCTAssertFalse(timeSystem.supportsTimedPlay);
  XCTAssertEqual(timeSystem.numberOfPeriods, 0);
  XCTAssertEqual(timeSystem.periodDurationInSeconds, 0.0);
  XCTAssertFalse(timeSystem.hasMinimumNumberOfMovesPerPeriod);
  XCTAssertEqual(timeSystem.minimumNumberOfMovesPerPeriod, 0);
  XCTAssertEqual(timeSystem.goUnusedTimeHandling, GoUnusedTimeHandlingNone);
  XCTAssertEqual(timeSystem.extraTimeDurationInSeconds, 0.0);
}

// -----------------------------------------------------------------------------
/// @brief Excercises the initWithCustomTimeSystemDescription:() initializer.
// -----------------------------------------------------------------------------
- (void) testInitWithCustomTimeSystemDescription
{
  GoTimeSystem* timeSystem = [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:@"foo"] autorelease];
  XCTAssertEqual(timeSystem.goTimeSystemType, GoTimeSystemTypeCustom);
  XCTAssertNotNil(timeSystem.customTimeSystemDescription);
  XCTAssertTrue([timeSystem.customTimeSystemDescription isEqualToString:@"foo"]);
  XCTAssertFalse(timeSystem.supportsTimedPlay);
  XCTAssertEqual(timeSystem.numberOfPeriods, 0);
  XCTAssertEqual(timeSystem.periodDurationInSeconds, 0.0);
  XCTAssertFalse(timeSystem.hasMinimumNumberOfMovesPerPeriod);
  XCTAssertEqual(timeSystem.minimumNumberOfMovesPerPeriod, 0);
  XCTAssertEqual(timeSystem.goUnusedTimeHandling, GoUnusedTimeHandlingNone);
  XCTAssertEqual(timeSystem.extraTimeDurationInSeconds, 0.0);

  timeSystem = [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:@""] autorelease];
  XCTAssertEqual(timeSystem.customTimeSystemDescription.length, 0);

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:nil] autorelease],
                               NSException, NSInvalidArgumentException, @"time system description is nil");
}

// -----------------------------------------------------------------------------
/// @brief Excercises the initWithAbsoluteTimeDurationInSeconds:() initializer.
// -----------------------------------------------------------------------------
- (void) testInitWithAbsoluteTimeDurationInSeconds
{
  GoTimeSystem* timeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:42.0] autorelease];
  XCTAssertEqual(timeSystem.goTimeSystemType, GoTimeSystemTypeAbsolute);
  XCTAssertNil(timeSystem.customTimeSystemDescription);
  XCTAssertTrue(timeSystem.supportsTimedPlay);
  XCTAssertEqual(timeSystem.numberOfPeriods, 1);
  XCTAssertEqual(timeSystem.periodDurationInSeconds, 42.0);
  XCTAssertFalse(timeSystem.hasMinimumNumberOfMovesPerPeriod);
  XCTAssertEqual(timeSystem.minimumNumberOfMovesPerPeriod, 0);
  XCTAssertEqual(timeSystem.goUnusedTimeHandling, GoUnusedTimeHandlingNone);
  XCTAssertEqual(timeSystem.extraTimeDurationInSeconds, 0.0);

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:0.0] autorelease],
                               NSException, NSInvalidArgumentException, @"duration is zero");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:-42.0] autorelease],
                               NSException, NSInvalidArgumentException, @"duration is negative");
}

// -----------------------------------------------------------------------------
/// @brief Excercises the
/// initWithGoTimeSystemType:periodDurationInSeconds:minimumNumberOfMovesPerPeriod:()
/// initializer.
// -----------------------------------------------------------------------------
- (void) testInitWithGoTimeSystemType
{
  GoTimeSystem* timeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeCanadian
                                                     periodDurationInSeconds:42.0
                                               minimumNumberOfMovesPerPeriod:17] autorelease];
  XCTAssertEqual(timeSystem.goTimeSystemType, GoTimeSystemTypeCanadian);
  XCTAssertNil(timeSystem.customTimeSystemDescription);
  XCTAssertTrue(timeSystem.supportsTimedPlay);
  XCTAssertEqual(timeSystem.numberOfPeriods, 1);
  XCTAssertEqual(timeSystem.periodDurationInSeconds, 42.0);
  XCTAssertTrue(timeSystem.hasMinimumNumberOfMovesPerPeriod);
  XCTAssertEqual(timeSystem.minimumNumberOfMovesPerPeriod, 17);
  XCTAssertEqual(timeSystem.goUnusedTimeHandling, GoUnusedTimeHandlingRoundDown);
  XCTAssertEqual(timeSystem.extraTimeDurationInSeconds, 0.0);

  timeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeSteadyAverage
                                       periodDurationInSeconds:42.0
                                 minimumNumberOfMovesPerPeriod:17] autorelease];
  XCTAssertEqual(timeSystem.goTimeSystemType, GoTimeSystemTypeSteadyAverage);
  XCTAssertNil(timeSystem.customTimeSystemDescription);
  XCTAssertTrue(timeSystem.supportsTimedPlay);
  XCTAssertEqual(timeSystem.numberOfPeriods, 1);
  XCTAssertEqual(timeSystem.periodDurationInSeconds, 42.0);
  XCTAssertTrue(timeSystem.hasMinimumNumberOfMovesPerPeriod);
  XCTAssertEqual(timeSystem.minimumNumberOfMovesPerPeriod, 17);
  XCTAssertEqual(timeSystem.goUnusedTimeHandling, GoUnusedTimeHandlingUseForExtraMoves);
  XCTAssertEqual(timeSystem.extraTimeDurationInSeconds, 0.0);

  timeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeTotalAverage
                                       periodDurationInSeconds:42.0
                                 minimumNumberOfMovesPerPeriod:17] autorelease];
  XCTAssertEqual(timeSystem.goTimeSystemType, GoTimeSystemTypeTotalAverage);
  XCTAssertNil(timeSystem.customTimeSystemDescription);
  XCTAssertTrue(timeSystem.supportsTimedPlay);
  XCTAssertEqual(timeSystem.numberOfPeriods, 1);
  XCTAssertEqual(timeSystem.periodDurationInSeconds, 42.0);
  XCTAssertTrue(timeSystem.hasMinimumNumberOfMovesPerPeriod);
  XCTAssertEqual(timeSystem.minimumNumberOfMovesPerPeriod, 17);
  XCTAssertEqual(timeSystem.goUnusedTimeHandling, GoUnusedTimeHandlingAddPeriodDuration);
  XCTAssertEqual(timeSystem.extraTimeDurationInSeconds, 0.0);

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeNone
                                                       periodDurationInSeconds:42.0
                                                 minimumNumberOfMovesPerPeriod:17] autorelease],
                               NSException, NSInvalidArgumentException, @"time system type is None");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeCustom
                                                       periodDurationInSeconds:42.0
                                                 minimumNumberOfMovesPerPeriod:17] autorelease],
                               NSException, NSInvalidArgumentException, @"time system type is Custom");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeAbsolute
                                                       periodDurationInSeconds:42.0
                                                 minimumNumberOfMovesPerPeriod:17] autorelease],
                               NSException, NSInvalidArgumentException, @"time system type is Absolute");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeJapanese
                                                       periodDurationInSeconds:42.0
                                                 minimumNumberOfMovesPerPeriod:17] autorelease],
                               NSException, NSInvalidArgumentException, @"time system type is Japanese");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeFischer
                                                       periodDurationInSeconds:42.0
                                                 minimumNumberOfMovesPerPeriod:17] autorelease],
                               NSException, NSInvalidArgumentException, @"time system type is Fischer");

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeCanadian
                                                       periodDurationInSeconds:0.0
                                                 minimumNumberOfMovesPerPeriod:17] autorelease],
                               NSException, NSInvalidArgumentException, @"period duration is zero");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeCanadian
                                                       periodDurationInSeconds:-42.0
                                                 minimumNumberOfMovesPerPeriod:17] autorelease],
                               NSException, NSInvalidArgumentException, @"period duration is negative");

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeCanadian
                                                       periodDurationInSeconds:42.0
                                                 minimumNumberOfMovesPerPeriod:0] autorelease],
                               NSException, NSInvalidArgumentException, @"minimum number of moves is zero");
}

// -----------------------------------------------------------------------------
/// @brief Excercises the
/// initWithJapaneseTimeNumberOfPeriods:periodDurationInSeconds:() initializer.
// -----------------------------------------------------------------------------
- (void) testInitWithJapaneseTimeNumberOfPeriods
{
  GoTimeSystem* timeSystem = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:17
                                                                periodDurationInSeconds:42.0] autorelease];
  XCTAssertEqual(timeSystem.goTimeSystemType, GoTimeSystemTypeJapanese);
  XCTAssertNil(timeSystem.customTimeSystemDescription);
  XCTAssertTrue(timeSystem.supportsTimedPlay);
  XCTAssertEqual(timeSystem.numberOfPeriods, 17);
  XCTAssertEqual(timeSystem.periodDurationInSeconds, 42.0);
  XCTAssertTrue(timeSystem.hasMinimumNumberOfMovesPerPeriod);
  XCTAssertEqual(timeSystem.minimumNumberOfMovesPerPeriod, 1);
  XCTAssertEqual(timeSystem.goUnusedTimeHandling, GoUnusedTimeHandlingRoundDown);
  XCTAssertEqual(timeSystem.extraTimeDurationInSeconds, 0.0);

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:17
                                                                  periodDurationInSeconds:0.0] autorelease],
                               NSException, NSInvalidArgumentException, @"period duration is zero");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:17
                                                                  periodDurationInSeconds:-42.0] autorelease],
                               NSException, NSInvalidArgumentException, @"period duration is negative");

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:0
                                                                  periodDurationInSeconds:42.0] autorelease],
                               NSException, NSInvalidArgumentException, @"number of periods is zero");
}

// -----------------------------------------------------------------------------
/// @brief Excercises the
/// initWithFischerTimeInitialDurationInSeconds:extraTimeDurationInSeconds:()
/// initializer.
// -----------------------------------------------------------------------------
- (void) testInitWithFischerTimeInitialDurationInSeconds
{
  GoTimeSystem* timeSystem = [[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:42.0
                                                                     extraTimeDurationInSeconds:17.0] autorelease];
  XCTAssertEqual(timeSystem.goTimeSystemType, GoTimeSystemTypeFischer);
  XCTAssertNil(timeSystem.customTimeSystemDescription);
  XCTAssertTrue(timeSystem.supportsTimedPlay);
  XCTAssertEqual(timeSystem.numberOfPeriods, 1);
  XCTAssertEqual(timeSystem.periodDurationInSeconds, 42.0);
  XCTAssertTrue(timeSystem.hasMinimumNumberOfMovesPerPeriod);
  XCTAssertEqual(timeSystem.minimumNumberOfMovesPerPeriod, 1);
  XCTAssertEqual(timeSystem.goUnusedTimeHandling, GoUnusedTimeHandlingAddExtraTime);
  XCTAssertEqual(timeSystem.extraTimeDurationInSeconds, 17.0);

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:0.0
                                                                       extraTimeDurationInSeconds:17.0] autorelease],
                               NSException, NSInvalidArgumentException, @"initial duration is zero");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:-42.0
                                                                       extraTimeDurationInSeconds:17.0] autorelease],
                               NSException, NSInvalidArgumentException, @"initial duration is negative");

  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:42.0
                                                                       extraTimeDurationInSeconds:0.0] autorelease],
                               NSException, NSInvalidArgumentException, @"extra time duration is zero");
  XCTAssertThrowsSpecificNamed([[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:42.0
                                                                       extraTimeDurationInSeconds:-17.0] autorelease],
                               NSException, NSInvalidArgumentException, @"extra time duration is negative");
}

@end
