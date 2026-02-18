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
#import "GoTimeSettingsTest.h"

// Application includes
#import <go/GoTimeSettings.h>
#import <go/GoTimeSystem.h>


@implementation GoTimeSettingsTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoTimeSettings object.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoTimeSettings* timeSettings = [[[GoTimeSettings alloc] init] autorelease];
  XCTAssertNotNil(timeSettings.absoluteTimeSystem);
  XCTAssertEqual(GoTimeSystemTypeNone, timeSettings.absoluteTimeSystem.goTimeSystemType);
  XCTAssertNotNil(timeSettings.periodBasedTimeSystem);
  XCTAssertEqual(GoTimeSystemTypeNone, timeSettings.periodBasedTimeSystem.goTimeSystemType);
  XCTAssertTrue(timeSettings.hasNoTimeSystems);
  XCTAssertFalse(timeSettings.isGameUsingTimedPlay);
  XCTAssertFalse(timeSettings.isTimeDataValid);
  XCTAssertEqual(-1, timeSettings.timeDataInvalidReason);
  XCTAssertEqual(-1, timeSettings.timeDataValidationMode);
}

// -----------------------------------------------------------------------------
/// @brief Excercises the initWithAbsoluteTimeSystem:periodBasedTimeSystem:()
/// initializer.
// -----------------------------------------------------------------------------
- (void) testInitializerWithTimeSystems
{
  GoTimeSettings* timeSettings;

  GoTimeSystem* absoluteTimeSystemNil = nil;
  GoTimeSystem* absoluteTimeSystemNone = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* absoluteTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:42] autorelease];
  GoTimeSystem* absoluteTimeSystemActuallyNotAbsolute = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:42 periodDurationInSeconds:17] autorelease];

  GoTimeSystem* periodBasedTimeSystemNil = nil;
  GoTimeSystem* periodBasedTimeSystemNone = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:42 periodDurationInSeconds:17] autorelease];
  GoTimeSystem* periodBasedTimeSystemActuallyAbsolute = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:42] autorelease];

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNone
                                               periodBasedTimeSystem:periodBasedTimeSystemNone] autorelease];
  XCTAssertEqual(absoluteTimeSystemNone, timeSettings.absoluteTimeSystem);
  XCTAssertEqual(periodBasedTimeSystemNone, timeSettings.periodBasedTimeSystem);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                               periodBasedTimeSystem:periodBasedTimeSystemNone] autorelease];
  XCTAssertEqual(absoluteTimeSystem, timeSettings.absoluteTimeSystem);
  XCTAssertEqual(periodBasedTimeSystemNone, timeSettings.periodBasedTimeSystem);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNone
                                               periodBasedTimeSystem:periodBasedTimeSystem] autorelease];
  XCTAssertEqual(absoluteTimeSystemNone, timeSettings.absoluteTimeSystem);
  XCTAssertEqual(periodBasedTimeSystem, timeSettings.periodBasedTimeSystem);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                               periodBasedTimeSystem:periodBasedTimeSystem] autorelease];
  XCTAssertEqual(absoluteTimeSystem, timeSettings.absoluteTimeSystem);
  XCTAssertEqual(periodBasedTimeSystem, timeSettings.periodBasedTimeSystem);

  XCTAssertThrowsSpecificNamed([[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNil
                                                             periodBasedTimeSystem:periodBasedTimeSystemNil] autorelease],
                               NSException, NSInvalidArgumentException, @"both GoTimeSystem objects are nil");
  XCTAssertThrowsSpecificNamed([[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNil
                                                             periodBasedTimeSystem:periodBasedTimeSystem] autorelease],
                               NSException, NSInvalidArgumentException, @"absoluteTimeSystem object is nil");
  XCTAssertThrowsSpecificNamed([[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                                             periodBasedTimeSystem:periodBasedTimeSystemNil] autorelease],
                               NSException, NSInvalidArgumentException, @"periodBasedTimeSystem object is nil");
  XCTAssertThrowsSpecificNamed([[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemActuallyNotAbsolute
                                                             periodBasedTimeSystem:periodBasedTimeSystem] autorelease],
                               NSException, NSInvalidArgumentException, @"absoluteTimeSystem object does not have the time system type GoTimeSystemTypeAbsolute");
  XCTAssertThrowsSpecificNamed([[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                                             periodBasedTimeSystem:periodBasedTimeSystemActuallyAbsolute] autorelease],
                               NSException, NSInvalidArgumentException, @"periodBasedTimeSystem object has the time system type GoTimeSystemTypeAbsolute");
}

// -----------------------------------------------------------------------------
/// @brief Excercises the @e hasNoTimeSystems property.
// -----------------------------------------------------------------------------
- (void) testHasNoTimeSystems
{
  GoTimeSettings* timeSettings;

  GoTimeSystem* absoluteTimeSystemNone = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* absoluteTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:42] autorelease];

  GoTimeSystem* periodBasedTimeSystemNone = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:42 periodDurationInSeconds:17] autorelease];

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNone
                                               periodBasedTimeSystem:periodBasedTimeSystemNone] autorelease];
  XCTAssertTrue(timeSettings.hasNoTimeSystems);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                               periodBasedTimeSystem:periodBasedTimeSystemNone] autorelease];
  XCTAssertFalse(timeSettings.hasNoTimeSystems);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNone
                                               periodBasedTimeSystem:periodBasedTimeSystem] autorelease];
  XCTAssertFalse(timeSettings.hasNoTimeSystems);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                               periodBasedTimeSystem:periodBasedTimeSystem] autorelease];
  XCTAssertFalse(timeSettings.hasNoTimeSystems);
}

// -----------------------------------------------------------------------------
/// @brief Excercises the @e isGameUsingTimedPlay property.
// -----------------------------------------------------------------------------
- (void) testIsGameUsingTimedPlay
{
  GoTimeSettings* timeSettings;

  GoTimeSystem* absoluteTimeSystemNone = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* absoluteTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:42] autorelease];

  GoTimeSystem* periodBasedTimeSystemNone = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* periodBasedTimeSystem = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:42 periodDurationInSeconds:17] autorelease];
  GoTimeSystem* periodBasedTimeSystemCustom = [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:@"foo"] autorelease];

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNone
                                               periodBasedTimeSystem:periodBasedTimeSystemNone] autorelease];
  XCTAssertFalse(timeSettings.isGameUsingTimedPlay);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNone
                                               periodBasedTimeSystem:periodBasedTimeSystem] autorelease];
  XCTAssertTrue(timeSettings.isGameUsingTimedPlay);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystemNone
                                               periodBasedTimeSystem:periodBasedTimeSystemCustom] autorelease];
  XCTAssertFalse(timeSettings.isGameUsingTimedPlay);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                               periodBasedTimeSystem:periodBasedTimeSystemNone] autorelease];
  XCTAssertTrue(timeSettings.isGameUsingTimedPlay);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                               periodBasedTimeSystem:periodBasedTimeSystem] autorelease];
  XCTAssertTrue(timeSettings.isGameUsingTimedPlay);

  timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                               periodBasedTimeSystem:periodBasedTimeSystemCustom] autorelease];
  XCTAssertFalse(timeSettings.isGameUsingTimedPlay);
}

@end
