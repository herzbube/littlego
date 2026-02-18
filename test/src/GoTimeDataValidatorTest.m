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
#import "GoTimeDataValidatorTest.h"

// Application includes
#import <go/GoTimeDataValidator.h>
#import <go/GoBoardPosition.h>
#import <go/GoGame.h>
#import <go/GoMove.h>
#import <go/GoNode.h>
#import <go/GoNodeAdditions.h>
#import <go/GoNodeModel.h>
#import <go/GoNodeTimeData.h>
#import <go/GoTimeSystem.h>
#import <go/GoTimeSettings.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoTimeDataValidatorTest.
// -----------------------------------------------------------------------------
@interface GoTimeDataValidatorTest()
@property(nonatomic, assign) GoNode* nodeA;
@property(nonatomic, assign) GoNode* nodeB;
@property(nonatomic, assign) GoNode* nodeC;
@property(nonatomic, assign) GoNode* nodeD;
@property(nonatomic, assign) GoNode* nodeE;
@property(nonatomic, assign) GoNode* nodeF;
@end


@implementation GoTimeDataValidatorTest

#pragma mark - Initializer tests

// -----------------------------------------------------------------------------
/// @brief Exercises the initWithTimeDataValidationMode:() initializer.
// -----------------------------------------------------------------------------
- (void) testInitWithTimeDataValidationMode
{
  GoTimeDataValidator* validator = [self strictValidator];
  XCTAssertEqual(validator.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

#pragma mark - Public method tests (superficial)

// -----------------------------------------------------------------------------
/// @brief Exercises the validateTimeDataInGameTree:() method.
// -----------------------------------------------------------------------------
- (void) testValidateTimeDataInGameTree
{
  [self setupGameWithMainTime:42.0];
  [self setupGameTreeWithoutMoves];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeA.isTimeDataValid);
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertFalse(self.nodeD.isTimeDataValid);
  XCTAssertFalse(self.nodeE.isTimeDataValid);
  XCTAssertFalse(self.nodeF.isTimeDataValid);

  XCTAssertThrowsSpecificNamed([validator validateTimeDataInGameTree:nil],
                               NSException, NSInvalidArgumentException, @"game is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the validateTimeDataInSubTree:game:() method.
// -----------------------------------------------------------------------------
- (void) testValidateTimeDataInSubTree
{
  [self setupGameWithMainTime:42.0];
  [self setupGameTreeWithoutMoves];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInSubTree:self.nodeB game:m_game];

  XCTAssertTrue(self.nodeA.isTimeDataValid);
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertFalse(self.nodeD.isTimeDataValid);
  XCTAssertFalse(self.nodeE.isTimeDataValid);
  XCTAssertTrue(self.nodeF.isTimeDataValid);

  XCTAssertThrowsSpecificNamed([validator validateTimeDataInSubTree:nil game:m_game],
                               NSException, NSInvalidArgumentException, @"node is nil");
  XCTAssertThrowsSpecificNamed([validator validateTimeDataInSubTree:self.nodeB game:nil],
                               NSException, NSInvalidArgumentException, @"game is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the validateTimeDataInCurrentGameVariation:() method.
// -----------------------------------------------------------------------------
- (void) testValidateTimeDataInCurrentGameVariation
{
  [self setupGameWithMainTime:42.0];
  [self setupGameTreeWithoutMoves];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInCurrentGameVariation:m_game];

  XCTAssertFalse(self.nodeA.isTimeDataValid);
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertFalse(self.nodeD.isTimeDataValid);
  XCTAssertTrue(self.nodeE.isTimeDataValid);
  XCTAssertTrue(self.nodeF.isTimeDataValid);

  XCTAssertThrowsSpecificNamed([validator validateTimeDataInCurrentGameVariation:nil],
                               NSException, NSInvalidArgumentException, @"game is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the validateTimeDataInCurrentGameVariation:untilNode:()
/// method.
// -----------------------------------------------------------------------------
- (void) testValidateTimeDataInCurrentGameVariationUntilNode
{
  [self setupGameWithMainTime:42.0];
  [self setupGameTreeWithoutMoves];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInCurrentGameVariation:m_game untilNode:self.nodeC];

  XCTAssertFalse(self.nodeA.isTimeDataValid);
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertTrue(self.nodeD.isTimeDataValid);
  XCTAssertTrue(self.nodeE.isTimeDataValid);
  XCTAssertTrue(self.nodeF.isTimeDataValid);

  XCTAssertThrowsSpecificNamed([validator validateTimeDataInCurrentGameVariation:nil untilNode:self.nodeC],
                               NSException, NSInvalidArgumentException, @"game is nil");
  XCTAssertThrowsSpecificNamed([validator validateTimeDataInCurrentGameVariation:m_game untilNode:nil],
                               NSException, NSInvalidArgumentException, @"node is nil");
  XCTAssertThrowsSpecificNamed([validator validateTimeDataInCurrentGameVariation:m_game untilNode:self.nodeE],
                               NSException, NSInvalidArgumentException, @"node not in current game variation");
}

#pragma mark - validateTimeSettings tests

// -----------------------------------------------------------------------------
/// @brief Exercises the time settings validation.
// -----------------------------------------------------------------------------
- (void) testValidateTimeSettings_DoesNotUseTimedPlay
{
  [self setupGameWithNoTimeSystems];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertFalse(rootNode.isTimeDataValid);
  XCTAssertEqual(rootNode.timeDataInvalidReason, GoTimeDataInvalidReasonGameDoesNotUseTimedPlay);
  XCTAssertEqual(rootNode.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time settings validation.
// -----------------------------------------------------------------------------
- (void) testValidateTimeSettings_CustomTimeSystem
{
  [self setupGameWithCustomTimeSystem:@"foo"];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertFalse(rootNode.isTimeDataValid);
  XCTAssertEqual(rootNode.timeDataInvalidReason, GoTimeDataInvalidReasonCustomTimeSystem);
  XCTAssertEqual(rootNode.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time settings validation.
// -----------------------------------------------------------------------------
- (void) testValidateTimeSettings_AbsoluteTimeDurationExceedsMaximum
{
  [self setupGameWithMainTime:gMaximumRemainingTimeInSeconds + 1.0];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertFalse(rootNode.isTimeDataValid);
  XCTAssertEqual(rootNode.timeDataInvalidReason, GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum);
  XCTAssertEqual(rootNode.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time settings validation.
// -----------------------------------------------------------------------------
- (void) testValidateTimeSettings_PeriodDurationExceedsMaximum
{
  [self setupGameWithCanadianTiming:gMaximumRemainingTimeInSeconds + 1.0
                    numberOfMoves:42];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertFalse(rootNode.isTimeDataValid);
  XCTAssertEqual(rootNode.timeDataInvalidReason, GoTimeDataInvalidReasonPeriodDurationExceedsMaximum);
  XCTAssertEqual(rootNode.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time settings validation.
// -----------------------------------------------------------------------------
- (void) testValidateTimeSettings_ExtraTimeDurationExceedsMaximum
{
  [self setupGameWithFischerTiming:42.0
                         extraTime:gMaximumRemainingTimeInSeconds + 1.0];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertFalse(rootNode.isTimeDataValid);
  XCTAssertEqual(rootNode.timeDataInvalidReason, GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum);
  XCTAssertEqual(rootNode.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time settings validation.
// -----------------------------------------------------------------------------
- (void) testValidateTimeSettings_MinimumNumberOfMovesPerPeriodExceedsMaximum
{
  [self setupGameWithCanadianTiming:42.0
                    numberOfMoves:gMaximumRemainingNumberOfMovesOrPeriods + 1];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertFalse(rootNode.isTimeDataValid);
  XCTAssertEqual(rootNode.timeDataInvalidReason, GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum);
  XCTAssertEqual(rootNode.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the time settings validation.
// -----------------------------------------------------------------------------
- (void) testValidateTimeSettings_NumberOfPeriodsExceedsMaximum
{
  [self setupGameWithJapaneseTiming:42.0
                    numberOfPeriods:gMaximumRemainingNumberOfMovesOrPeriods + 1];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertFalse(rootNode.isTimeDataValid);
  XCTAssertEqual(rootNode.timeDataInvalidReason, GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum);
  XCTAssertEqual(rootNode.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

#pragma mark - visitNode tests

// -----------------------------------------------------------------------------
/// @brief Exercises the node data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNode_EmptyNodeIsValid
{
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertTrue(rootNode.isTimeDataValid);
  XCTAssertEqual(rootNode.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(rootNode.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNode_InvalidTimeSettings_InvalidReasonPropagatesToAllNodes
{
  [self setupGameTreeWithOneMoveAndValidTimeData];
  [self setupGameWithNoTimeSystems];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeA.isTimeDataValid);
  XCTAssertEqual(self.nodeA.timeDataInvalidReason, GoTimeDataInvalidReasonGameDoesNotUseTimedPlay);
  XCTAssertEqual(self.nodeA.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonGameDoesNotUseTimedPlay);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNode_InvalidNode_StrictMode_InvalidReasonDoesNotPropagateToChildNode
{
  [self setupGameTreeWithTwoMovesAndPartiallyValidTimeData];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  // The root node is still valid
  XCTAssertTrue(self.nodeA.isTimeDataValid);
  XCTAssertEqual(self.nodeA.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeA.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // This is the node with the invalid time data
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonMoveNodeHasNoTimeData);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // Because mode is "only" strict the parent node's invalid reason does not
  // propagate to the child node
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNode_InvalidNode_PedanticMode_InvalidReasonPropagatesToChildNode
{
  [self setupGameTreeWithTwoMovesAndPartiallyValidTimeData];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self pedanticValidator];

  [validator validateTimeDataInGameTree:m_game];

  // The root node is still valid
  XCTAssertTrue(self.nodeA.isTimeDataValid);
  XCTAssertEqual(self.nodeA.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeA.timeDataValidationMode, GoTimeDataValidationModePedantic);

  // This is the node with the invalid time data
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonMoveNodeHasNoTimeData);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModePedantic);

  // Because mode is pedantic the parent node's invalid reason propagates to
  // the child node
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonMoveNodeHasNoTimeData);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModePedantic);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNode_MoveNodeHasNoTimeData
{
  [self setupGameTreeWithVisitNodeInvalidReasons];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonMoveNodeHasNoTimeData);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNode_NonMoveNodeHasTimeData
{
  [self setupGameTreeWithVisitNodeInvalidReasons];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonNonMoveNodeHasTimeData);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNode_MoveAndTimeDataPlayerMismatch
{
  [self setupGameTreeWithVisitNodeInvalidReasons];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeD.isTimeDataValid);
  XCTAssertEqual(self.nodeD.timeDataInvalidReason, GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch);
  XCTAssertEqual(self.nodeD.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

#pragma mark - visitNodeTimeData tests - general

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_InvalidNode_NoNodeTimeDataValidation
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  // Causes the time data validation to fail already on the node level
  self.nodeB.goNodeTimeData.isTimeDataForBlackPlayer = false;
  // A remaining time that exceeds the maximum is also invalid, but it will no
  // longer be considered because the validation already fails earlier.
  // Compare with the next test.
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = gMaximumRemainingTimeInSeconds + 1.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_RemainingTimeExceedsMaximum
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  // In comparison with the preceding test, in this test we don't have a
  // validation error already on the node level, so here the remaining time
  // exceeding the maximum is seen as the time data invalid reason
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = gMaximumRemainingTimeInSeconds + 1.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeExceedsMaximum);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // Repeat test for overtime => same result
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeExceedsMaximum);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_RemainingNumberOfMovesExceedsMaximum
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = gMaximumRemainingNumberOfMovesOrPeriods + 1;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // This is not a real-world scenario: If remainingNumberOfMoves is >0, then
  // the application logic will never set isRemainingTimeAbsoluteTime to true
  // => we still prove that exceeding the maximum value is checked regardless
  //    of the time system that is in effect
  [self setupGameWithMainTime:42.0];
  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = true;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_RemainingNumberOfPeriodsExceedsMaximum
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfPeriods = gMaximumRemainingNumberOfMovesOrPeriods + 1;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // This is not a real-world scenario: If remainingNumberOfPeriods is >0, then
  // the application logic will never set isRemainingTimeAbsoluteTime to true
  // => we still prove that exceeding the maximum value is checked regardless
  //    of the time system that is in effect
  [self setupGameWithMainTime:42.0];
  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = true;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_RemainingTimeNegative
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.remainingTimeInSeconds = -1.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeNegative);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // Repeat test for overtime => same result
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeNegative);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_RemainingNumberOfMovesNegative
{
  // remainingNumberOfMoves is unsigned in the app's data model
  // => invalid reason can never occur
  //
  // The OB/OW properties can have a negative value in the SGF data, but the
  // app handles this by converting the negative value to zero
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_RemainingNumberOfPeriodsNegative
{
  // remainingNumberOfPeriods is unsigned in the app's data model
  // => invalid reason can never occur
  //
  // The OB/OW properties can have a negative value in the SGF data, but the
  // app handles this by converting the negative value to zero
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_AbsoluteTimeDataFoundWithoutAbsoluteTimeSystem
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonAbsoluteTimeDataFoundWithoutAbsoluteTimeSystem);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_AbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTimeDuration:42.0 canadianTimingDuration:123.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonAbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the general node time data validation.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_PeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonPeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

#pragma mark - visitNodeTimeData tests - time system specific

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Absolute_RemainingTimeHigherThanAbsoluteTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 43.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Absolute_RemainingAbsoluteTimeIsIncreasing
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 1.0;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 2.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Canadian_RemainingTimeHigherThanPeriodTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 43.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 18;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesConstant
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 16;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 16;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesDecreasedButRemainingTimeIncreased
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 1.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 16;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 2.0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 15;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesIncreasedButRemainingTimeDecreased
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 2.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 15;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 1.0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 16;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Canadian_RemainingNumberOfMovesNotConstant
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:1];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 1;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // The issue exists only if the time system's minimum number of moves is != 1
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:2];
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // There is no problem if nodes always have the same number - can be either
  // 0 or 1
  [self setupGameWithCanadianTiming:42.0 numberOfMoves:1];
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 0;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 1;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 1;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Japanese_RemainingTimeHigherThanPeriodTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithJapaneseTiming:42.0 numberOfPeriods:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 43.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Japanese_RemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithJapaneseTiming:42.0 numberOfPeriods:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfPeriods = 18;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Japanese_RemainingNumberOfPeriodsIsIncreasing
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithJapaneseTiming:42.0 numberOfPeriods:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfPeriods = 16;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingNumberOfPeriods = 17;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfPeriodsIsIncreasing);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Fischer_RemainingTimeHigherThanPeriodTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithFischerTiming:42.0 extraTime:17.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 43.0;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 43.0;

  [validator validateTimeDataInGameTree:m_game];

  // The issue exists only for the first node
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // The second node can have a higher remaining time than the initial time
  // because the extra time was added
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Fischer_RemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithFischerTiming:42.0 extraTime:17.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 2;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Fischer_RemainingTimeHigherThanExtraTimeAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithFischerTiming:42.0 extraTime:17.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 41.0;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 59.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_Fischer_RemainingNumberOfMovesNotConstant
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithFischerTiming:42.0 extraTime:17.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 1;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // There is no problem if nodes always have the same number - can be either
  // 0 or 1
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 0;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 1;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 1;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_SteadyAverage_RemainingTimeHigherThanPeriodTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithSteadyAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 43.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithSteadyAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 18;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesConstant
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithSteadyAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 16;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 16;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // The problem does not exist when remainingNumberOfMoves stays at 0, because
  // Steady Average Timinig allows to use remaining time for extra moves
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 0;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesDecreasedButRemainingTimeIncreased
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithSteadyAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 1.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 16;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 2.0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 15;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // Remaining time is also not allowed to increase if the number of moves
  // stays at 0
  // => the enum value name is misleading in this case because the number of
  //    moves does not decrease
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 1.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 2.0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 0;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesIncreasedButRemainingTimeDecreased
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithSteadyAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 2.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 15;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 1.0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 16;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // Unlike in the previous test, remaining time is allowed to decrease if the
  // number of moves stays at 0
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 2.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 1.0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 0;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_SteadyAverage_RemainingNumberOfMovesNotConstant
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithSteadyAverageTiming:42.0 numberOfMoves:1];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 1;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // The issue exists only if the time system's minimum number of moves is != 1
  [self setupGameWithSteadyAverageTiming:42.0 numberOfMoves:2];
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // There is no problem if nodes always have the same number - can be either
  // 0 or 1
  [self setupGameWithSteadyAverageTiming:42.0 numberOfMoves:1];
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 0;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 1;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 1;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_TotalAverage_RemainingTimeHigherThanPeriodTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithTotalAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 43.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 16;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 43.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 15;

  [validator validateTimeDataInGameTree:m_game];

  // The issue exists only for the first node
  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // The second node can have a higher remaining time than the initial time
  // because the extra time was added
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_TotalAverage_RemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithTotalAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 18;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertFalse(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_TotalAverage_RemainingTimeHigherThanExtraTimeAllows
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithTotalAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 41.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 16;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 84.0;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 15;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_TotalAverage_RemainingNumberOfMovesConstant
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithTotalAverageTiming:42.0 numberOfMoves:17];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 16;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 16;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the node time data validation in respect to a specific
/// time system.
// -----------------------------------------------------------------------------
- (void) testVisitNodeTimeData_TotalAverage_RemainingNumberOfMovesNotConstant
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithTotalAverageTiming:42.0 numberOfMoves:1];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.isRemainingTimeAbsoluteTime = false;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 1;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);

  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // The issue exists only if the time system's minimum number of moves is != 1
  [self setupGameWithTotalAverageTiming:42.0 numberOfMoves:2];
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // There is no problem if nodes always have the same number - can be either
  // 0 or 1
  [self setupGameWithTotalAverageTiming:42.0 numberOfMoves:1];
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 0;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 0;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
  self.nodeB.goNodeTimeData.remainingNumberOfMoves = 1;
  self.nodeC.goNodeTimeData.remainingNumberOfMoves = 1;
  [validator validateTimeDataInGameTree:m_game];
  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertTrue(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

#pragma mark - Class method tests

// -----------------------------------------------------------------------------
/// @brief Exercises the validationStateOfCurrentGameVariation:() method.
// -----------------------------------------------------------------------------
- (void) testValidationStateOfCurrentGameVariation
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 41.0;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 42.0;
  self.nodeD.goNodeTimeData.remainingTimeInSeconds = 43.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertFalse(self.nodeD.isTimeDataValid);
  XCTAssertEqual(self.nodeD.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows);
  XCTAssertEqual(self.nodeD.timeDataValidationMode, GoTimeDataValidationModeStrict);

  // self.nodeD is the leaf node => validationState reflects the state of that
  // node
  GoTimeDataValidationResult validationState = [GoTimeDataValidator validationStateOfCurrentGameVariation:m_game];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
  // Gradually removing nodes => validation state reflects the state of the
  // new leaf node
  [self.nodeC removeChild:self.nodeD];
  [m_game.nodeModel changeToVariationContainingNode:self.nodeA];
  validationState = [GoTimeDataValidator validationStateOfCurrentGameVariation:m_game];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
  [self.nodeB removeChild:self.nodeC];
  [m_game.nodeModel changeToVariationContainingNode:self.nodeA];
  validationState = [GoTimeDataValidator validationStateOfCurrentGameVariation:m_game];
  XCTAssertTrue(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the validationStateOfCurrentNode:() method.
// -----------------------------------------------------------------------------
- (void) testValidationStateOfCurrentNode
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 41.0;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 42.0;
  self.nodeD.goNodeTimeData.remainingTimeInSeconds = 43.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertFalse(self.nodeD.isTimeDataValid);
  XCTAssertEqual(self.nodeD.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows);
  XCTAssertEqual(self.nodeD.timeDataValidationMode, GoTimeDataValidationModeStrict);

  m_game.boardPosition.currentBoardPosition = 3; // self.nodeD
  GoTimeDataValidationResult validationState = [GoTimeDataValidator validationStateOfCurrentNode:m_game];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
  m_game.boardPosition.currentBoardPosition = 2; // self.nodeC
  validationState = [GoTimeDataValidator validationStateOfCurrentNode:m_game];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
  m_game.boardPosition.currentBoardPosition = 1; // self.nodeB
  validationState = [GoTimeDataValidator validationStateOfCurrentNode:m_game];
  XCTAssertTrue(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the validationStateOfNode:() method.
// -----------------------------------------------------------------------------
- (void) testValidationStateOfNode
{
  [self setupGameTreeWithThreeMoveNodes];
  [self setupGameWithMainTime:42.0];
  GoTimeDataValidator* validator = [self strictValidator];

  self.nodeB.goNodeTimeData.remainingTimeInSeconds = 41.0;
  self.nodeC.goNodeTimeData.remainingTimeInSeconds = 42.0;
  self.nodeD.goNodeTimeData.remainingTimeInSeconds = 43.0;

  [validator validateTimeDataInGameTree:m_game];

  XCTAssertTrue(self.nodeB.isTimeDataValid);
  XCTAssertEqual(self.nodeB.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(self.nodeB.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertFalse(self.nodeC.isTimeDataValid);
  XCTAssertEqual(self.nodeC.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing);
  XCTAssertEqual(self.nodeC.timeDataValidationMode, GoTimeDataValidationModeStrict);
  XCTAssertFalse(self.nodeD.isTimeDataValid);
  XCTAssertEqual(self.nodeD.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows);
  XCTAssertEqual(self.nodeD.timeDataValidationMode, GoTimeDataValidationModeStrict);

  GoTimeDataValidationResult validationState = [GoTimeDataValidator validationStateOfNode:self.nodeD];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
  validationState = [GoTimeDataValidator validationStateOfNode:self.nodeC];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
  validationState = [GoTimeDataValidator validationStateOfNode:self.nodeB];
  XCTAssertTrue(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the validationStateOfNode:() method if the most recent
/// validation was done with pedantic mode.
// -----------------------------------------------------------------------------
- (void) testValidationStateOfNode_PedanticMode_TakesStateFromNode
{
  [self setupGameTreeWithThreeMoveNodes];

  // Simulate validation
  self.nodeB.isTimeDataValid = true;
  self.nodeB.timeDataInvalidReason = GoTimeDataValidationResultValid.timeDataInvalidReason;
  self.nodeB.timeDataValidationMode = GoTimeDataValidationModePedantic;
  self.nodeC.isTimeDataValid = false;
  self.nodeC.timeDataInvalidReason = GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows;
  self.nodeC.timeDataValidationMode = GoTimeDataValidationModePedantic;
  self.nodeD.isTimeDataValid = false;
  self.nodeD.timeDataInvalidReason = GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows;
  self.nodeD.timeDataValidationMode = GoTimeDataValidationModePedantic;

  // Remove both the move and the GoNodeTimeData object
  // => the validation state will still be taken from this node
  self.nodeD.goMove = nil;
  self.nodeD.goNodeTimeData = nil;

  GoTimeDataValidationResult validationState = [GoTimeDataValidator validationStateOfNode:self.nodeD];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModePedantic);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the validationStateOfNode:() method if the most recent
/// validation was done with a non-pedantic mode, and the node itself does not
/// have a move or time data, but another preceding node does.
// -----------------------------------------------------------------------------
- (void) testValidationStateOfNode_NonPedanticMode_TakesStateFromNodeWithMostRecentMoveOrTimeData
{
  [self setupGameTreeWithThreeMoveNodes];

  // Simulate validation
  self.nodeB.isTimeDataValid = true;
  self.nodeB.timeDataInvalidReason = GoTimeDataValidationResultValid.timeDataInvalidReason;
  self.nodeB.timeDataValidationMode = GoTimeDataValidationModeStrict;
  self.nodeC.isTimeDataValid = false;
  self.nodeC.timeDataInvalidReason = GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows;
  self.nodeC.timeDataValidationMode = GoTimeDataValidationModeStrict;
  self.nodeD.isTimeDataValid = false;
  self.nodeD.timeDataInvalidReason = GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows;
  self.nodeD.timeDataValidationMode = GoTimeDataValidationModeStrict;

  // Remove both the move and the GoNodeTimeData object
  // => the validation state will be taken from self.nodeC
  self.nodeD.goMove = nil;
  self.nodeD.goNodeTimeData = nil;

  GoTimeDataValidationResult validationState = [GoTimeDataValidator validationStateOfNode:self.nodeD];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
  
  // The validation state will now be taken from self.nodeB
  self.nodeC.goMove = nil;
  self.nodeC.goNodeTimeData = nil;
  validationState = [GoTimeDataValidator validationStateOfNode:self.nodeD];
  XCTAssertTrue(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataValidationResultValid.timeDataInvalidReason);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the validationStateOfNode:() method if the most recent
/// validation was done with a non-pedantic mode, and the node itself does not
/// have a move or time data, and there is also no other preceding node with a
/// move or time data.
// -----------------------------------------------------------------------------
- (void) testValidationStateOfNode_NonPedanticMode_NoNodeWithMostRecentMoveOrTimeData_TakesStateFromNode
{
  [self setupGameTreeWithThreeMoveNodes];

  // Simulate validation
  self.nodeB.isTimeDataValid = true;
  self.nodeB.timeDataInvalidReason = GoTimeDataValidationResultValid.timeDataInvalidReason;
  self.nodeB.timeDataValidationMode = GoTimeDataValidationModeStrict;
  self.nodeC.isTimeDataValid = false;
  self.nodeC.timeDataInvalidReason = GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows;
  self.nodeC.timeDataValidationMode = GoTimeDataValidationModeStrict;
  self.nodeD.isTimeDataValid = false;
  self.nodeD.timeDataInvalidReason = GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows;
  self.nodeD.timeDataValidationMode = GoTimeDataValidationModeStrict;

  // Remove both the move and the GoNodeTimeData object from all nodes
  // => the validation state will be taken from self.nodeD
  self.nodeD.goMove = nil;
  self.nodeD.goNodeTimeData = nil;
  self.nodeC.goMove = nil;
  self.nodeC.goNodeTimeData = nil;
  self.nodeB.goMove = nil;
  self.nodeB.goNodeTimeData = nil;

  GoTimeDataValidationResult validationState = [GoTimeDataValidator validationStateOfNode:self.nodeD];
  XCTAssertFalse(validationState.isTimeDataValid);
  XCTAssertEqual(validationState.timeDataInvalidReason, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows);
  XCTAssertEqual(validationState.timeDataValidationMode, GoTimeDataValidationModeStrict);
}

#pragma mark - Helper methods

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoTimeDataValidator object with
/// mode #GoTimeDataValidationModeStrict.
// -----------------------------------------------------------------------------
- (GoTimeDataValidator*) strictValidator
{
  return [self validatorWithMode:GoTimeDataValidationModeStrict];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoTimeDataValidator object with
/// mode #GoTimeDataValidationModePedantic.
// -----------------------------------------------------------------------------
- (GoTimeDataValidator*) pedanticValidator
{
  return [self validatorWithMode:GoTimeDataValidationModePedantic];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that creates a GoTimeDataValidator object with the
/// supplied mode.
// -----------------------------------------------------------------------------
- (GoTimeDataValidator*) validatorWithMode:(enum GoTimeDataValidationMode)mode
{
  GoTimeDataValidator* validator = [[GoTimeDataValidator alloc] initWithTimeDataValidationMode:mode];
  return validator;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up a relatively simple game tree with
/// characteristics that allow to verify whether the various tree iterators
/// work.
///
/// The tree looks like this, with A being the root node, and A-B-C-D being
/// the current game variation.
///
/// @verbatim
/// A
/// +-- B
/// |   +-- C
/// |   |   +-- D  validateTimeDataInCurrentGameVariation:untilNode:() does not touch this
/// |   +-- E      validateTimeDataInCurrentGameVariation:() does not touch this
/// |
/// +-- F          validateTimeDataInSubTree:game:() does not touch this when run with B as argument
/// @endverbatim
///
/// All nodes are set up so that they indicate valid time data and contain a
/// GoNodeTimeData object, but because they don't also contain a move their
/// time data is, in fact, invalid. If the validation routine touches a node,
/// it will set its time data validation members to indicate invalid time data.
// -----------------------------------------------------------------------------
- (void) setupGameTreeWithoutMoves
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  self.nodeA = nodeModel.rootNode;
  self.nodeB = [GoNode node];
  self.nodeC = [GoNode node];
  self.nodeD = [GoNode node];
  self.nodeE = [GoNode node];
  self.nodeF = [GoNode node];
  [self.nodeA setFirstChild:self.nodeB];
  [self.nodeA appendChild:self.nodeF];
  [self.nodeB setFirstChild:self.nodeC];
  [self.nodeB appendChild:self.nodeE];
  [self.nodeC setFirstChild:self.nodeD];
  [nodeModel changeToVariationContainingNode:nodeModel.rootNode];

  void (^makeNodePseudoValid)(GoNode*) = ^ void (GoNode* node)
  {
    GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
    nodeTimeData.isTimeDataForBlackPlayer = true;
    nodeTimeData.isRemainingTimeAbsoluteTime = true;
    nodeTimeData.remainingTimeInSeconds = 1.0;
    nodeTimeData.remainingNumberOfMoves = 0;
    nodeTimeData.remainingNumberOfPeriods = 1;

    node.goNodeTimeData = nodeTimeData;
    node.isTimeDataValid = GoTimeDataValidationResultValid.isTimeDataValid;
    node.timeDataInvalidReason = GoTimeDataValidationResultValid.timeDataInvalidReason;
    node.timeDataValidationMode = GoTimeDataValidationResultValid.timeDataValidationMode;
  };

  makeNodePseudoValid(self.nodeA);
  makeNodePseudoValid(self.nodeB);
  makeNodePseudoValid(self.nodeC);
  makeNodePseudoValid(self.nodeD);
  makeNodePseudoValid(self.nodeE);
  makeNodePseudoValid(self.nodeF);
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up a simple game tree consisting of one node
/// with a move.
///
/// The root node reference is stored in self.nodeA, the move node
/// reference is stored in self.nodeB.
///
/// The move node is set up so that it indicates valid time data. It is also
/// set up with a GoNodeTimeData object that indicates that the remaining time
/// is 1.0 and applies to main time.
// -----------------------------------------------------------------------------
- (void) setupGameTreeWithOneMoveAndValidTimeData
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  self.nodeA = nodeModel.rootNode;
  self.nodeB = [GoNode node];
  [self.nodeA setFirstChild:self.nodeB];
  [nodeModel changeToVariationContainingNode:nodeModel.rootNode];

  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  nodeTimeData.isTimeDataForBlackPlayer = true;
  nodeTimeData.isRemainingTimeAbsoluteTime = true;
  nodeTimeData.remainingTimeInSeconds = 1.0;
  nodeTimeData.remainingNumberOfMoves = 0;
  nodeTimeData.remainingNumberOfPeriods = 1;

  self.nodeB.goMove = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  self.nodeB.goNodeTimeData = nodeTimeData;
  self.nodeB.isTimeDataValid = GoTimeDataValidationResultValid.isTimeDataValid;
  self.nodeB.timeDataInvalidReason = GoTimeDataValidationResultValid.timeDataInvalidReason;
  self.nodeB.timeDataValidationMode = GoTimeDataValidationResultValid.timeDataValidationMode;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up a simple game tree consisting of two nodes
/// with a move.
///
/// The root node reference is stored in self.nodeA, the move node
/// references are stored in self.nodeB and self.nodeC.
///
/// The move nodes are set up as follows:
/// - self.nodeB indicates valid time data. It is not set up with a
///   GoNodeTimeData object.
/// - self.nodeC indicates valid time data. It is set up with a GoNodeTimeData
///   object that indicates that the remaining time is 1.0 and applies to main
///   time.
// -----------------------------------------------------------------------------
- (void) setupGameTreeWithTwoMovesAndPartiallyValidTimeData
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  self.nodeA = nodeModel.rootNode;
  self.nodeB = [GoNode node];
  self.nodeC = [GoNode node];
  [self.nodeA setFirstChild:self.nodeB];
  [self.nodeB setFirstChild:self.nodeC];
  [nodeModel changeToVariationContainingNode:nodeModel.rootNode];

  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  nodeTimeData.isTimeDataForBlackPlayer = true;
  nodeTimeData.isRemainingTimeAbsoluteTime = true;
  nodeTimeData.remainingTimeInSeconds = 1.0;
  nodeTimeData.remainingNumberOfMoves = 0;
  nodeTimeData.remainingNumberOfPeriods = 1;

  self.nodeB.goMove = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  self.nodeB.isTimeDataValid = GoTimeDataValidationResultValid.isTimeDataValid;
  self.nodeB.timeDataInvalidReason = GoTimeDataValidationResultValid.timeDataInvalidReason;
  self.nodeB.timeDataValidationMode = GoTimeDataValidationResultValid.timeDataValidationMode;

  self.nodeC.goMove = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  self.nodeC.goNodeTimeData = nodeTimeData;
  self.nodeC.isTimeDataValid = GoTimeDataValidationResultValid.isTimeDataValid;
  self.nodeC.timeDataInvalidReason = GoTimeDataValidationResultValid.timeDataInvalidReason;
  self.nodeC.timeDataValidationMode = GoTimeDataValidationResultValid.timeDataValidationMode;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up a simple game tree consisting of three
/// nodes, each of which has one problem that is detected by the visitNode
/// validation.
///
/// The root node reference is stored in self.nodeA, the remaining node
/// references are stored in self.nodeB, self.nodeC and self.nodeD.
///
/// The nodes after the root node are set up as follows:
/// - All of them indicate valid time data.
/// - self.nodeB is set up with a move, but without GoNodeTimeData object.
/// - self.nodeC is not set up with a move, but with a GoNodeTimeData
///   object that indicates that the remaining time is 1.0 and applies to main
///   time.
/// - self.nodeC is set up with both a move and a GoNodeTimeData object that
///   indicates that the remaining time is 1.0 and applies to main time.
///   The move and GoNodeTimeData object do not match in which player they
///   refer to.
// -----------------------------------------------------------------------------
- (void) setupGameTreeWithVisitNodeInvalidReasons
{
  [self setupGameTreeWithThreeMoveNodes];

  self.nodeB.goNodeTimeData = nil;
  self.nodeC.goMove = nil;
  self.nodeD.goNodeTimeData.isTimeDataForBlackPlayer = false;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up a simple game tree consisting of three
/// nodes, each of which has a move and a GoNodeTimeData object and indicates
/// valid time data. The calling test method can configure the GoNodeTimeData
/// objects to produce the expected validation result.
///
/// The root node reference is stored in self.nodeA, the remaining node
/// references are stored in self.nodeB, self.nodeC and self.nodeD.
///
/// The GoNodeTimeData objects indicate that the remaining time is 1.0, is for
/// the black player and applies to main time.
// -----------------------------------------------------------------------------
- (void) setupGameTreeWithThreeMoveNodes
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  self.nodeA = nodeModel.rootNode;
  self.nodeB = [GoNode node];
  self.nodeC = [GoNode node];
  self.nodeD = [GoNode node];
  [self.nodeA setFirstChild:self.nodeB];
  [self.nodeB setFirstChild:self.nodeC];
  [self.nodeC setFirstChild:self.nodeD];
  [nodeModel changeToVariationContainingNode:nodeModel.rootNode];

  void (^setupNode)(GoNode*) = ^ void (GoNode* node)
  {
    GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
    nodeTimeData.isTimeDataForBlackPlayer = true;
    nodeTimeData.isRemainingTimeAbsoluteTime = true;
    nodeTimeData.remainingTimeInSeconds = 1.0;
    nodeTimeData.remainingNumberOfMoves = 0;
    nodeTimeData.remainingNumberOfPeriods = 1;

    node.goMove = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
    node.goNodeTimeData = nodeTimeData;
    node.isTimeDataValid = GoTimeDataValidationResultValid.isTimeDataValid;
    node.timeDataInvalidReason = GoTimeDataValidationResultValid.timeDataInvalidReason;
    node.timeDataValidationMode = GoTimeDataValidationResultValid.timeDataValidationMode;
  };

  setupNode(self.nodeB);
  setupNode(self.nodeC);
  setupNode(self.nodeD);
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with no time systems.
// -----------------------------------------------------------------------------
- (void) setupGameWithNoTimeSystems
{
  GoTimeSettings* timeSettings = [[[GoTimeSettings alloc] init] autorelease];
  m_game.timeSettings = timeSettings;
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with a custom time system.
// -----------------------------------------------------------------------------
- (void) setupGameWithCustomTimeSystem:(NSString*)description
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:description] autorelease];
  [self setupGameWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with main time.
// -----------------------------------------------------------------------------
- (void) setupGameWithMainTime:(double)duration
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:duration] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  [self setupGameWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with Canadian Timing.
// -----------------------------------------------------------------------------
- (void) setupGameWithCanadianTiming:(double)duration numberOfMoves:(unsigned long)numberOfMoves
{
  [self setupGameWithTimeSystem:GoTimeSystemTypeCanadian duration:duration numberOfMoves:numberOfMoves];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with Japanese Timing.
// -----------------------------------------------------------------------------
- (void) setupGameWithJapaneseTiming:(double)duration
                     numberOfPeriods:(unsigned long)numberOfPeriods
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:numberOfPeriods
                                                                    periodDurationInSeconds:duration] autorelease];
  [self setupGameWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with Fischer Timing.
// -----------------------------------------------------------------------------
- (void) setupGameWithFischerTiming:(double)initialDuration
                          extraTime:(double)extraTimeDuration
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:initialDuration
                                                                         extraTimeDurationInSeconds:extraTimeDuration] autorelease];
  [self setupGameWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with Steady Average Timing.
// -----------------------------------------------------------------------------
- (void) setupGameWithSteadyAverageTiming:(double)duration numberOfMoves:(unsigned long)numberOfMoves
{
  [self setupGameWithTimeSystem:GoTimeSystemTypeSteadyAverage duration:duration numberOfMoves:numberOfMoves];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with Total Average Timing.
// -----------------------------------------------------------------------------
- (void) setupGameWithTotalAverageTiming:(double)duration numberOfMoves:(unsigned long)numberOfMoves
{
  [self setupGameWithTimeSystem:GoTimeSystemTypeTotalAverage duration:duration numberOfMoves:numberOfMoves];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with an overtime system with the
/// supplied characteristics.
// -----------------------------------------------------------------------------
- (void) setupGameWithTimeSystem:(enum GoTimeSystemType)timeSystemType
                        duration:(double)duration
                   numberOfMoves:(unsigned long)numberOfMoves
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:timeSystemType
                                                         periodDurationInSeconds:duration
                                                   minimumNumberOfMovesPerPeriod:numberOfMoves] autorelease];
  [self setupGameWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with main time and Canadian
/// Timing.
// -----------------------------------------------------------------------------
- (void) setupGameWithMainTimeDuration:(double)mainTimeDuration
                canadianTimingDuration:(double)canadianTimingDuration
                         numberOfMoves:(unsigned long)numberOfMoves
{
  GoTimeSystem* mainTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:mainTimeDuration] autorelease];
  GoTimeSystem* overTimeSystem = [[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeCanadian
                                                         periodDurationInSeconds:canadianTimingDuration
                                                   minimumNumberOfMovesPerPeriod:numberOfMoves] autorelease];
  [self setupGameWithMainTimeSystem:mainTimeSystem overTimeSystem:overTimeSystem];
}

// -----------------------------------------------------------------------------
/// @brief Helper method that sets up the game with the supplied time systems.
// -----------------------------------------------------------------------------
- (void) setupGameWithMainTimeSystem:(GoTimeSystem*)mainTimeSystem
                      overTimeSystem:(GoTimeSystem*)overTimeSystem
{
  GoTimeSettings* timeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:mainTimeSystem
                                                               periodBasedTimeSystem:overTimeSystem] autorelease];
  m_game.timeSettings = timeSettings;
}

@end
