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


// -----------------------------------------------------------------------------
/// @brief The GoPlayerTimeDataTest class contains unit tests that exercise the
/// GoPlayerTimeData class.
// -----------------------------------------------------------------------------
@interface GoPlayerTimeDataTest : XCTestCase
{
}

- (void) testInitialState_NoTimeSystems;
- (void) testInitialState_CustomTimeSystem;
- (void) testInitialState_MainTime;
- (void) testInitialState_Overtime;
- (void) testInitialState_MainTimeAndOvertime;
- (void) testStartClock;
- (void) testSuspendClockIfNotSuspended;
- (void) testStopClockIfNotStopped;
- (void) testDidPlayerLoseOnTime;
- (void) testUpdateAfterMoveWasPlayed_MainTime;
- (void) testUpdateAfterMoveWasPlayed_JapaneseTiming;
- (void) testUpdateAfterMoveWasPlayed_NonJapaneseTiming;
- (void) testUpdateAfterMoveWasPlayed_GoUnusedTimeHandlingUseForExtraMoves;
- (void) testUpdateAfterMoveWasPlayed_FractionalSecondsRoundedUp;
- (void) testUpdateAfterMoveWasPlayed_ExceptionCases;
- (void) testUpdateAfterNodeChanged_RootNode;
- (void) testUpdateAfterNodeChanged_NodeWithTimeData;
- (void) testUpdateAfterPlayerLostOnTime;
- (void) testRemainingNumberOfMovesOrPeriods;
- (void) testDeductTime_MainTimeOnly_GameContinues;
- (void) testDeductTime_MainTimeOnly_PlayerLoses;
- (void) testDeductTime_SwitchFromMainTimeToJapaneseOvertime_GameContinues;
- (void) testDeductTime_SwitchFromMainTimeToNonJapaneseOvertime_GameContinues;
- (void) testDeductTime_PeriodResetBecauseOfGoUnusedTimeHandlingUseForExtraMoves_GameContinues;
- (void) testDeductTime_PeriodResetBecauseOfGoUnusedTimeHandlingUseForExtraMoves_PlayerLoses;
- (void) testDeductTime_PeriodCountdownJapaneseTiming_GameContinues;
- (void) testDeductTime_PeriodCountdownJapaneseTiming_PlayerLoses;
- (void) testDeductTime_PeriodCountdownNonJapaneseTiming_PlayerLoses;
- (void) testPeriodReset_MainTime_NoPeriodReset;
- (void) testPeriodReset_NumberOfMovesNotYetZero_NoPeriodReset;
- (void) testPeriodReset_GoUnusedTimeHandlingRoundDown;
- (void) testPeriodReset_GoUnusedTimeHandlingUseForExtraMoves_NoPeriodReset;
- (void) testPeriodReset_GoUnusedTimeHandlingAddPeriodDuration;
- (void) testPeriodReset_GoUnusedTimeHandlingAddPeriodDuration_RemainingTimeCap;
- (void) testPeriodReset_GoUnusedTimeHandlingAddExtraTime;
- (void) testPeriodReset_GoUnusedTimeHandlingAddExtraTime_RemainingTimeCap;
- (void) testPeriodReset_GoUnusedTimeHandlingNone;

@end
