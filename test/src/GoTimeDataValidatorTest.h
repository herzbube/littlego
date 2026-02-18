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
#import "BaseTestCase.h"


// -----------------------------------------------------------------------------
/// @brief The GoTimeDataValidatorTest class contains unit tests that exercise
/// the GoTimeDataValidator class.
// -----------------------------------------------------------------------------
@interface GoTimeDataValidatorTest : BaseTestCase
{
}

- (void) testInitWithTimeDataValidationMode;
- (void) testValidateTimeDataInGameTree;
- (void) testValidateTimeDataInSubTree;
- (void) testValidateTimeDataInCurrentGameVariation;
- (void) testValidateTimeDataInCurrentGameVariationUntilNode;

- (void) testValidateTimeSettings_DoesNotUseTimedPlay;
- (void) testValidateTimeSettings_CustomTimeSystem;
- (void) testValidateTimeSettings_AbsoluteTimeDurationExceedsMaximum;
- (void) testValidateTimeSettings_PeriodDurationExceedsMaximum;
- (void) testValidateTimeSettings_ExtraTimeDurationExceedsMaximum;
- (void) testValidateTimeSettings_MinimumNumberOfMovesPerPeriodExceedsMaximum;
- (void) testValidateTimeSettings_NumberOfPeriodsExceedsMaximum;

- (void) testVisitNode_EmptyNodeIsValid;
- (void) testVisitNode_InvalidTimeSettings_InvalidReasonPropagatesToAllNodes;
- (void) testVisitNode_InvalidNode_StrictMode_InvalidReasonDoesNotPropagateToChildNode;
- (void) testVisitNode_InvalidNode_PedanticMode_InvalidReasonPropagatesToChildNode;
- (void) testVisitNode_MoveNodeHasNoTimeData;
- (void) testVisitNode_NonMoveNodeHasTimeData;
- (void) testVisitNode_MoveAndTimeDataPlayerMismatch;

- (void) testVisitNodeTimeData_InvalidNode_NoNodeTimeDataValidation;
- (void) testVisitNodeTimeData_RemainingTimeExceedsMaximum;
- (void) testVisitNodeTimeData_RemainingNumberOfMovesExceedsMaximum;
- (void) testVisitNodeTimeData_RemainingNumberOfPeriodsExceedsMaximum;
- (void) testVisitNodeTimeData_RemainingTimeNegative;
- (void) testVisitNodeTimeData_RemainingNumberOfMovesNegative;
- (void) testVisitNodeTimeData_RemainingNumberOfPeriodsNegative;
- (void) testVisitNodeTimeData_AbsoluteTimeDataFoundWithoutAbsoluteTimeSystem;
- (void) testVisitNodeTimeData_AbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData;
- (void) testVisitNodeTimeData_PeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem;

- (void) testVisitNodeTimeData_Absolute_RemainingTimeHigherThanAbsoluteTimeSystemAllows;
- (void) testVisitNodeTimeData_Absolute_RemainingAbsoluteTimeIsIncreasing;
- (void) testVisitNodeTimeData_Canadian_RemainingTimeHigherThanPeriodTimeSystemAllows;
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows;
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesConstant;
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesDecreasedButRemainingTimeIncreased;
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesIncreasedButRemainingTimeDecreased;
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesNotConstant;
- (void) testVisitNodeTimeData_Japanese_RemainingTimeHigherThanPeriodTimeSystemAllows;
- (void) testVisitNodeTimeData_Japanese_RemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows;
- (void) testVisitNodeTimeData_Japanese_RemainingNumberOfPeriodsIsIncreasing;
- (void) testVisitNodeTimeData_Fischer_RemainingTimeHigherThanPeriodTimeSystemAllows;
- (void) testVisitNodeTimeData_Fischer_RemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows;
- (void) testVisitNodeTimeData_Fischer_RemainingTimeHigherThanExtraTimeAllows;
- (void) testVisitNodeTimeData_Fischer_RemainingNumberOfMovesNotConstant;
- (void) testVisitNodeTimeData_SteadyAverage_RemainingTimeHigherThanPeriodTimeSystemAllows;
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows;
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesConstant;
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesDecreasedButRemainingTimeIncreased;
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesIncreasedButRemainingTimeDecreased;
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesNotConstant;
- (void) testVisitNodeTimeData_TotalAverage_RemainingTimeHigherThanPeriodTimeSystemAllows;
- (void) testVisitNodeTimeData_TotalAverage_RemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows;
- (void) testVisitNodeTimeData_TotalAverage_RemainingTimeHigherThanExtraTimeAllows;
- (void) testVisitNodeTimeData_TotalAverage_RemainingNumberOfMovesConstant;
- (void) testVisitNodeTimeData_TotalAverage_RemainingNumberOfMovesNotConstant;

- (void) testValidationStateOfCurrentGameVariation;
- (void) testValidationStateOfCurrentNode;
- (void) testValidationStateOfNode;
- (void) testValidationStateOfNode_PedanticMode_TakesStateFromNode;
- (void) testValidationStateOfNode_NonPedanticMode_TakesStateFromNodeWithMostRecentMoveOrTimeData;
- (void) testValidationStateOfNode_NonPedanticMode_NoNodeWithMostRecentMoveOrTimeData_TakesStateFromNode;

@end
