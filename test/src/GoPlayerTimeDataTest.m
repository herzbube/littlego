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
#import "GoPlayerTimeDataTest.h"

// Application includes
#import <go/GoClockAdditions.h>
#import <go/GoNode.h>
#import <go/GoNodeTimeData.h>
#import <go/GoPlayerTimeData.h>
#import <go/GoPlayerTimeDataAdditions.h>
#import <go/GoTimeSettings.h>
#import <go/GoTimeSystem.h>


@implementation GoPlayerTimeDataTest

#pragma mark - Initializer tests

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoPlayerTimeData object when it is
/// initialized without any time systems.
// -----------------------------------------------------------------------------
- (void) testInitialState_NoTimeSystems
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithoutTimeSystems];

  XCTAssertTrue(playerTimeData.isTimeDataForBlackPlayer);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 0);

  XCTAssertThrowsSpecificNamed([[[GoPlayerTimeData alloc] initWithTimeSettings:nil
                                                      isTimeDataForBlackPlayer:true] autorelease],
                               NSException, NSInvalidArgumentException, @"GoTimeSettings is nil");
}

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoPlayerTimeData object when it is
/// initialized with a custom time system.
// -----------------------------------------------------------------------------
- (void) testInitialState_CustomTimeSystem
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCustomTimeSystem:@"foo"];

  XCTAssertTrue(playerTimeData.isTimeDataForBlackPlayer);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 0);
}

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoPlayerTimeData object when it is
/// initialized with a main time time system (Absolute Timing).
// -----------------------------------------------------------------------------
- (void) testInitialState_MainTime
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  XCTAssertTrue(playerTimeData.isTimeDataForBlackPlayer);
  XCTAssertTrue(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoPlayerTimeData object when it is
/// initialized with an overtime system.
// -----------------------------------------------------------------------------
- (void) testInitialState_Overtime
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0 numberOfMoves:17];

  XCTAssertTrue(playerTimeData.isTimeDataForBlackPlayer);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoPlayerTimeData object when it is
/// initialized with both a main time and an overtime system.
// -----------------------------------------------------------------------------
- (void) testInitialState_MainTimeAndOvertime
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTimeDuration:42.0
                                                       canadianTimingDuration:123.0
                                                                numberOfMoves:456];

  XCTAssertTrue(playerTimeData.isTimeDataForBlackPlayer);
  XCTAssertTrue(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

#pragma mark - Clock tests

// -----------------------------------------------------------------------------
/// @brief Exercises the startClock() method, the @e clockState property and
/// the @e clockSuspendedReason property.
// -----------------------------------------------------------------------------
- (void) testStartClock
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  XCTAssertEqual(playerTimeData.clockState, GoClockStateStopped);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);

  [playerTimeData startClock];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateStarted);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);

  [playerTimeData suspendClockIfNotSuspended:GoClockSuspendedReasonUserAction];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateSuspended);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonUserAction);

  [playerTimeData startClock];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateStarted);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);

  XCTAssertThrowsSpecificNamed([playerTimeData startClock],
                               NSException, NSInternalInconsistencyException, @"clock already started");

  playerTimeData = [self playerTimeDataWithoutTimeSystems];
  XCTAssertTrue(playerTimeData.didPlayerLoseOnTime);
  XCTAssertThrowsSpecificNamed([playerTimeData startClock],
                               NSException, NSInternalInconsistencyException, @"player lost on time");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the suspendClockIfNotSuspended:() method, the @e clockState
/// property and the @e clockSuspendedReason property.
///
/// This does @b NOT exercise the time deduction algorithm - for that see the
/// many testDeductTime... methods.
// -----------------------------------------------------------------------------
- (void) testSuspendClockIfNotSuspended
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  XCTAssertEqual(playerTimeData.clockState, GoClockStateStopped);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);

  [playerTimeData suspendClockIfNotSuspended:GoClockSuspendedReasonUserAction];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateSuspended);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonUserAction);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);

  [playerTimeData startClock];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateStarted);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);
  [NSThread sleepForTimeInterval:0.1];

  [playerTimeData suspendClockIfNotSuspended:GoClockSuspendedReasonUserAction];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateSuspended);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonUserAction);
  XCTAssertTrue(playerTimeData.remainingTimeInSeconds < 42.0);

  XCTAssertThrowsSpecificNamed([playerTimeData suspendClockIfNotSuspended:GoClockSuspendedReasonUserAction],
                               NSException, NSInternalInconsistencyException, @"clock already suspended");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the stopClockIfNotStopped() method, the @e clockState
/// property and the @e clockSuspendedReason property.
///
/// This does @b NOT exercise the time deduction algorithm - for that see the
/// many testDeductTime... methods.
// -----------------------------------------------------------------------------
- (void) testStopClockIfNotStopped
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  XCTAssertEqual(playerTimeData.clockState, GoClockStateStopped);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);

  [playerTimeData stopClockIfNotStopped];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateStopped);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);

  [playerTimeData suspendClockIfNotSuspended:GoClockSuspendedReasonUserAction];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateSuspended);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonUserAction);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);

  [playerTimeData stopClockIfNotStopped];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateStopped);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);

  [playerTimeData startClock];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateStarted);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);
  [NSThread sleepForTimeInterval:0.1];

  [playerTimeData stopClockIfNotStopped];
  XCTAssertEqual(playerTimeData.clockState, GoClockStateStopped);
  XCTAssertEqual(playerTimeData.clockSuspendedReason, GoClockSuspendedReasonNotSuspended);
  XCTAssertTrue(playerTimeData.remainingTimeInSeconds < 42.0);
}

#pragma mark - Updater tests

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterMoveWasPlayed:() method when main time is
/// in effect.
///
/// This does @b NOT exercise the period reset algorithm - for that see the
/// many testPeriodReset... methods.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterMoveWasPlayed_MainTime
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  XCTAssertTrue(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 0.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 0);

  [playerTimeData updateAfterMoveWasPlayed:nodeTimeData];
  XCTAssertTrue(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterMoveWasPlayed:() method when Japanese Timing
/// is in effect.
///
/// This does @b NOT exercise the period reset algorithm - for that see the
/// many testPeriodReset... methods.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterMoveWasPlayed_JapaneseTiming
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithJapaneseTiming:42.0 numberOfPeriods:17];

  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  XCTAssertTrue(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 0.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 0);

  [playerTimeData updateAfterMoveWasPlayed:nodeTimeData];
  XCTAssertFalse(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 17);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterMoveWasPlayed:() method when an overtime
/// system other than Japanese Timing is in effect.
///
/// This does @b NOT exercise the period reset algorithm - for that see the
/// many testPeriodReset... methods.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterMoveWasPlayed_NonJapaneseTiming
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0 numberOfMoves:17];

  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  XCTAssertTrue(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 0.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 0);

  [playerTimeData updateAfterMoveWasPlayed:nodeTimeData];
  XCTAssertFalse(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 16);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 1);

  // With GoUnusedTimeHandling other than GoUnusedTimeHandlingUseForExtraMoves
  // there is an exception when remaining moves is zero
  [playerTimeData setRemainingNumberOfMoves:0];
  nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  XCTAssertThrowsSpecificNamed([playerTimeData updateAfterMoveWasPlayed:nodeTimeData],
                               NSException, NSInternalInconsistencyException, @"remaining number of moves is zero");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterMoveWasPlayed:() method when an overtime
/// system is in effect that uses #GoUnusedTimeHandlingUseForExtraMoves.
///
/// This does @b NOT exercise the period reset algorithm - for that see the
/// many testPeriodReset... methods.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterMoveWasPlayed_GoUnusedTimeHandlingUseForExtraMoves
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithSteadyAverageTiming:42.0 numberOfMoves:17];

  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  XCTAssertTrue(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 0.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 0);

  [playerTimeData updateAfterMoveWasPlayed:nodeTimeData];
  XCTAssertFalse(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 16);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 1);

  // With GoUnusedTimeHandlingUseForExtraMoves there is no exception when
  // remaining moves is zero
  [playerTimeData setRemainingNumberOfMoves:0];
  nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  [playerTimeData updateAfterMoveWasPlayed:nodeTimeData];
  XCTAssertFalse(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterMoveWasPlayed:() method when the remaining
/// time is a fractional value.
///
/// This does @b NOT exercise the period reset algorithm - for that see the
/// many testPeriodReset... methods.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterMoveWasPlayed_FractionalSecondsRoundedUp
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  XCTAssertTrue(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 0.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 0);

  // Fractional seconds are rounded up
  [playerTimeData setRemainingTimeInSeconds:40.1];
  [playerTimeData updateAfterMoveWasPlayed:nodeTimeData];
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 41.0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterMoveWasPlayed:() method when it raises
/// an exception.
///
/// This does @b NOT exercise the period reset algorithm - for that see the
/// many testPeriodReset... methods.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterMoveWasPlayed_ExceptionCases
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  XCTAssertThrowsSpecificNamed([playerTimeData updateAfterMoveWasPlayed:nil],
                               NSException, NSInvalidArgumentException, @"GoNodeTimeData is nil");

  [playerTimeData startClock];
  XCTAssertThrowsSpecificNamed([playerTimeData updateAfterMoveWasPlayed:[[[GoNodeTimeData alloc] init] autorelease]],
                               NSException, NSInternalInconsistencyException, @"clock is started");

  playerTimeData = [self playerTimeDataWithoutTimeSystems];
  XCTAssertTrue(playerTimeData.didPlayerLoseOnTime);
  XCTAssertThrowsSpecificNamed([playerTimeData updateAfterMoveWasPlayed:[[[GoNodeTimeData alloc] init] autorelease]],
                               NSException, NSInternalInconsistencyException, @"player lost on time");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterNodeChanged:() method when the supplied
/// node is the root node and the GoPlayerTimeData is updated with data from
/// the time settings.
///
/// This does @b NOT exercise the period reset algorithm - for that see the
/// many testPeriodReset... methods.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterNodeChanged_RootNode
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0 numberOfMoves:17];

  playerTimeData.isRemainingTimeAbsoluteTime = true;
  playerTimeData.remainingTimeInSeconds = 123.0;
  playerTimeData.remainingNumberOfMoves = 456;
  playerTimeData.remainingNumberOfPeriods = 789;

  GoNode* node = [GoNode node];
  [playerTimeData updateAfterNodeChanged:node];

  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterNodeChanged:() method when the supplied
/// node has a GoNodeTimeData, and GoPlayerTimeData is updated with data from
/// that GoNodeTimeData.
///
/// This does @b NOT exercise the period reset algorithm - for that see the
/// many testPeriodReset... methods.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterNodeChanged_NodeWithTimeData
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0 numberOfMoves:17];

  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  nodeTimeData.isRemainingTimeAbsoluteTime = true;
  nodeTimeData.remainingTimeInSeconds = 123.0;
  nodeTimeData.remainingNumberOfMoves = 456;
  nodeTimeData.remainingNumberOfPeriods = 789;

  GoNode* node = [GoNode node];
  node.goNodeTimeData = nodeTimeData;
  [playerTimeData updateAfterNodeChanged:node];

  XCTAssertTrue(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 123.0);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 456);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 789);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the updateAfterPlayerLostOnTime() method.
// -----------------------------------------------------------------------------
- (void) testUpdateAfterPlayerLostOnTime
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0 numberOfMoves:17];

  [playerTimeData updateAfterPlayerLostOnTime];
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 0.0);
}

#pragma mark - Remaining method tests

// -----------------------------------------------------------------------------
/// @brief Exercises the didPlayerLoseOnTime() method.
///
/// This does @b NOT exercise the time deduction algorithm - for that see the
/// many testDeductTime... methods.
// -----------------------------------------------------------------------------
- (void) testDidPlayerLoseOnTime
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:0.1];

  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 0.1);
  XCTAssertFalse(playerTimeData.didPlayerLoseOnTime);

  [playerTimeData startClock];
  [NSThread sleepForTimeInterval:0.1];

  [playerTimeData stopClockIfNotStopped];
  XCTAssertTrue(playerTimeData.remainingTimeInSeconds <= 0.0);
  XCTAssertTrue(playerTimeData.didPlayerLoseOnTime);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the remainingNumberOfMovesOrPeriods() method.
// -----------------------------------------------------------------------------
- (void) testRemainingNumberOfMovesOrPeriods
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0 numberOfMoves:17];
  XCTAssertEqual([playerTimeData remainingNumberOfMovesOrPeriods], 17);

  playerTimeData = [self playerTimeDataWithJapaneseTiming:42.0 numberOfPeriods:123];
  XCTAssertEqual([playerTimeData remainingNumberOfMovesOrPeriods], 123);
}

#pragma mark - Time deduction tests

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_MainTimeOnly_GameContinues
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:41.9];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameContinues);
  XCTAssertTrue(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, (42.0 - 41.9)); // 0.1
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_MainTimeOnly_PlayerLoses
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:42.1];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameLostOnTime);
  XCTAssertTrue(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, (42.0 - 42.1)); // -0.1
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_SwitchFromMainTimeToJapaneseOvertime_GameContinues
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTimeDuration:42.0
                                                       japaneseTimingDuration:123.0
                                                              numberOfPeriods:456];

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:100.0];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameContinues);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, (42.0 - 100.0) + 123.0); // 65.0
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 1);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 456);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_SwitchFromMainTimeToNonJapaneseOvertime_GameContinues
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTimeDuration:42.0
                                                       canadianTimingDuration:123.0
                                                                numberOfMoves:456];

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:100.0];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameContinues);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, (42.0 - 100.0) + 123.0); // 65.0
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 456);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_PeriodResetBecauseOfGoUnusedTimeHandlingUseForExtraMoves_GameContinues
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithSteadyAverageTiming:42.0
                                                                   numberOfMoves:17];

  // Needed to trigger a period reset
  playerTimeData.remainingNumberOfMoves = 0;

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:83.9];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameContinues);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, (42.0 - 83.9) + 42.0); // 0.1
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_PeriodResetBecauseOfGoUnusedTimeHandlingUseForExtraMoves_PlayerLoses
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithSteadyAverageTiming:42.0
                                                                   numberOfMoves:17];

  // Needed to trigger a period reset
  playerTimeData.remainingNumberOfMoves = 0;

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:84.0];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameLostOnTime);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, (42.0 - 84.0) + 42.0); // 0.0
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_PeriodCountdownJapaneseTiming_GameContinues
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithJapaneseTiming:42.0
                                                            numberOfPeriods:17];

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:84.1];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameContinues);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, (42.0 - 84.1) + 84.0); // 41.9 (2 periods deducted, still some left after the second period)
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 1);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 15);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_PeriodCountdownJapaneseTiming_PlayerLoses
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithJapaneseTiming:42.0
                                                            numberOfPeriods:2];

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:84.1];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameLostOnTime);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, (42.0 - 84.1) + 42); // -0.1 (2 periods deducted, none left after the second period)
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 1);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time deduction algorithm.
// -----------------------------------------------------------------------------
- (void) testDeductTime_PeriodCountdownNonJapaneseTiming_PlayerLoses
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0
                                                              numberOfMoves:17];

  enum GoPeriodDurationElapsedResultType result = [playerTimeData deductElapsedTimeInSeconds:42.1];
  XCTAssertEqual(result, GoPeriodDurationElapsedResultTypeGameLostOnTime);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0 - 42.1); // -0.1
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 0);
}

#pragma mark - Period reset tests

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_MainTime_NoPeriodReset
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithMainTime:42.0];
  GoTimeSystem* effectiveTimeSystem = playerTimeData.goTimeSettings.absoluteTimeSystem;

  playerTimeData.remainingTimeInSeconds = 2.3;

  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:effectiveTimeSystem];
  XCTAssertFalse(dataHasChanged);
  XCTAssertTrue(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 2.3);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_NumberOfMovesNotYetZero_NoPeriodReset
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0
                                                              numberOfMoves:17];
  GoTimeSystem* effectiveTimeSystem = playerTimeData.goTimeSettings.periodBasedTimeSystem;

  playerTimeData.remainingTimeInSeconds = 2.3;

  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:effectiveTimeSystem];
  XCTAssertFalse(dataHasChanged);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 2.3);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_GoUnusedTimeHandlingRoundDown
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0
                                                              numberOfMoves:17];
  GoTimeSystem* effectiveTimeSystem = playerTimeData.goTimeSettings.periodBasedTimeSystem;

  playerTimeData.remainingTimeInSeconds = 2.3;

  // Needed to trigger a period reset
  playerTimeData.remainingNumberOfMoves = 0;

  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:effectiveTimeSystem];
  XCTAssertTrue(dataHasChanged);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 42.0);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_GoUnusedTimeHandlingUseForExtraMoves_NoPeriodReset
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithSteadyAverageTiming:42.0
                                                                   numberOfMoves:17];
  GoTimeSystem* effectiveTimeSystem = playerTimeData.goTimeSettings.periodBasedTimeSystem;

  playerTimeData.remainingTimeInSeconds = 2.3;

  // Needed to trigger a period reset, but because the time system has
  // GoUnusedTimeHandlingUseForExtraMoves the player can continue to play and
  // use the remaining time for additional moves
  playerTimeData.remainingNumberOfMoves = 0;

  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:effectiveTimeSystem];
  XCTAssertFalse(dataHasChanged);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 2.3);
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_GoUnusedTimeHandlingAddPeriodDuration
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithTotalAverageTiming:42.0
                                                                  numberOfMoves:17];
  GoTimeSystem* effectiveTimeSystem = playerTimeData.goTimeSettings.periodBasedTimeSystem;

  playerTimeData.remainingTimeInSeconds = 2.3;

  // Needed to trigger a period reset
  playerTimeData.remainingNumberOfMoves = 0;

  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:effectiveTimeSystem];
  XCTAssertTrue(dataHasChanged);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 2.3 + 42.0); // 44.3
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_GoUnusedTimeHandlingAddPeriodDuration_RemainingTimeCap
{
  double durationAlmostAtMaximum = gMaximumRemainingTimeInSeconds - 1.0;
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithTotalAverageTiming:durationAlmostAtMaximum
                                                                  numberOfMoves:17];
  GoTimeSystem* effectiveTimeSystem = playerTimeData.goTimeSettings.periodBasedTimeSystem;

  playerTimeData.remainingTimeInSeconds = 2.3;

  // Needed to trigger a period reset
  playerTimeData.remainingNumberOfMoves = 0;

  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:effectiveTimeSystem];
  XCTAssertTrue(dataHasChanged);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, gMaximumRemainingTimeInSeconds); // capped at maximum
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 17);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_GoUnusedTimeHandlingAddExtraTime
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithFischerTiming:42.0
                                                         extraTimeDuration:17.0];
  GoTimeSystem* effectiveTimeSystem = playerTimeData.goTimeSettings.periodBasedTimeSystem;

  playerTimeData.remainingTimeInSeconds = 2.3;

  // Needed to trigger a period reset
  playerTimeData.remainingNumberOfMoves = 0;

  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:effectiveTimeSystem];
  XCTAssertTrue(dataHasChanged);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, 2.3 + 17.0); // 19.3
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 1);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_GoUnusedTimeHandlingAddExtraTime_RemainingTimeCap
{
  double durationAlmostAtMaximum = gMaximumRemainingTimeInSeconds - 1.0;
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithFischerTiming:42.0
                                                         extraTimeDuration:durationAlmostAtMaximum];
  GoTimeSystem* effectiveTimeSystem = playerTimeData.goTimeSettings.periodBasedTimeSystem;

  playerTimeData.remainingTimeInSeconds = 2.3;

  // Needed to trigger a period reset
  playerTimeData.remainingNumberOfMoves = 0;

  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:effectiveTimeSystem];
  XCTAssertTrue(dataHasChanged);
  XCTAssertFalse(playerTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(playerTimeData.remainingTimeInSeconds, gMaximumRemainingTimeInSeconds); // capped at maximum
  XCTAssertEqual(playerTimeData.remainingNumberOfMoves, 1);
  XCTAssertEqual(playerTimeData.remainingNumberOfPeriods, 1);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the period reset algorithm.
// -----------------------------------------------------------------------------
- (void) testPeriodReset_GoUnusedTimeHandlingNone
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataWithCanadianTiming:42.0
                                                              numberOfMoves:17];

  // Needed to trigger a period reset
  playerTimeData.remainingNumberOfMoves = 0;

  // Time systems with GoUnusedTimeHandlingNone will cause an exception to be
  // raised, but all of these time systems also have value false for
  // hasMinimumNumberOfMovesPerPeriod, which means that
  // performPeriodResetIfNecessary:() aborts early and does not even get to the
  // GoUnusedTimeHandling case handling.
  // => The exception cases therefore cannot be triggered without fabricating a
  //    GoTimeSystem object with fake values

  GoTimeSystem* noTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  bool dataHasChanged = [playerTimeData performPeriodResetIfNecessary:noTimeSystem];
  XCTAssertFalse(dataHasChanged);

  GoTimeSystem* absoluteTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:123.0] autorelease];
  dataHasChanged = [playerTimeData performPeriodResetIfNecessary:absoluteTimeSystem];
  XCTAssertFalse(dataHasChanged);

  GoTimeSystem* customTimeSystem = [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:@"foo"] autorelease];
  dataHasChanged = [playerTimeData performPeriodResetIfNecessary:customTimeSystem];
  XCTAssertFalse(dataHasChanged);
}

#pragma mark - Helper methods

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object without
/// any time systems.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithoutTimeSystems
{
  GoTimeSettings* timeSettings = [[[GoTimeSettings alloc] init] autorelease];
  GoPlayerTimeData* playerTimeData = [[[GoPlayerTimeData alloc] initWithTimeSettings:timeSettings
                                                            isTimeDataForBlackPlayer:true] autorelease];

  return playerTimeData;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with a custom
/// time system.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithCustomTimeSystem:(NSString*)description
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:description] autorelease];
  return [self playerTimeDataWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with Absolute
/// Timing.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithMainTime:(double)duration
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:duration] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  return [self playerTimeDataWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with Canadian
/// Timing.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithCanadianTiming:(double)duration numberOfMoves:(unsigned long)numberOfMoves
{
  return [self playerTimeDataWithTimeSystem:GoTimeSystemTypeCanadian
                                   duration:duration
                              numberOfMoves:numberOfMoves];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with Japanese
/// Timing.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithJapaneseTiming:(double)duration numberOfPeriods:(unsigned long)numberOfPeriods
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:numberOfPeriods
                                                                    periodDurationInSeconds:duration] autorelease];
  return [self playerTimeDataWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with Steady
/// Average Timing.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithSteadyAverageTiming:(double)duration numberOfMoves:(unsigned long)numberOfMoves
{
  return [self playerTimeDataWithTimeSystem:GoTimeSystemTypeSteadyAverage
                                   duration:duration
                              numberOfMoves:numberOfMoves];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with Total
/// Average Timing.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithTotalAverageTiming:(double)duration numberOfMoves:(unsigned long)numberOfMoves
{
  return [self playerTimeDataWithTimeSystem:GoTimeSystemTypeTotalAverage
                                   duration:duration
                              numberOfMoves:numberOfMoves];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with Fischer
/// Timing.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithFischerTiming:(double)initialDuration extraTimeDuration:(double)extraTimeDuration
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:initialDuration
                                                                         extraTimeDurationInSeconds:extraTimeDuration] autorelease];
  return [self playerTimeDataWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with the
/// supplied overtime system type.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithTimeSystem:(enum GoTimeSystemType)timeSystemType
                                          duration:(double)duration
                                     numberOfMoves:(unsigned long)numberOfMoves
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:timeSystemType
                                                         periodDurationInSeconds:duration
                                                   minimumNumberOfMovesPerPeriod:numberOfMoves] autorelease];
  return [self playerTimeDataWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with Absolute
/// Timing and Canadian Timing.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithMainTimeDuration:(double)mainTimeDuration
                                  canadianTimingDuration:(double)canadianTimingDuration
                                           numberOfMoves:(unsigned long)numberOfMoves
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:mainTimeDuration] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeCanadian
                                                         periodDurationInSeconds:canadianTimingDuration
                                                   minimumNumberOfMovesPerPeriod:numberOfMoves] autorelease];
  return [self playerTimeDataWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with Absolute
/// Timing and Japanese Timing.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithMainTimeDuration:(double)mainTimeDuration
                                  japaneseTimingDuration:(double)japaneseTimingDuration
                                         numberOfPeriods:(unsigned long)numberOfPeriods
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:mainTimeDuration] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:numberOfPeriods
                                                                    periodDurationInSeconds:japaneseTimingDuration] autorelease];
  return [self playerTimeDataWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoPlayerTimeData object with the
/// supplied time systems.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataWithMainTimeSystem:(GoTimeSystem*)mainTimeSystem
                                        overTimeSystem:(GoTimeSystem*)overTimeSystem
{
  GoTimeSettings* timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:mainTimeSystem
                                                               periodBasedTimeSystem:overTimeSystem] autorelease];
  GoPlayerTimeData* playerTimeData = [[[GoPlayerTimeData alloc] initWithTimeSettings:timeSettings
                                                            isTimeDataForBlackPlayer:true] autorelease];
  return playerTimeData;
}

@end
