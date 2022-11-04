// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNodeSetupTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoNodeSetup.h>
#import <go/GoPoint.h>


@implementation GoNodeSetupTest


// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoNodeSetup object after a new
/// instance has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoNodeSetup* testee = [[[GoNodeSetup alloc] init] autorelease];

  XCTAssertTrue(testee.isEmpty);
  XCTAssertNil(testee.blackSetupStones);
  XCTAssertNil(testee.whiteSetupStones);
  XCTAssertNil(testee.noSetupStones);
  XCTAssertEqual(testee.setupFirstMoveColor, GoColorNone);
  XCTAssertNil(testee.previousBlackSetupStones);
  XCTAssertNil(testee.previousWhiteSetupStones);
  XCTAssertEqual(testee.previousSetupFirstMoveColor, GoColorNone);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the nodeSetupWithPreviousSetupCapturedFromGame:()
/// convenience constructor.
// -----------------------------------------------------------------------------
- (void) testNodeSetupWithPreviousSetupCapturedFromGame
{
  GoNodeSetup* testeeEmptyBoard = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertTrue(testeeEmptyBoard.isEmpty);
  XCTAssertNil(testeeEmptyBoard.blackSetupStones);
  XCTAssertNil(testeeEmptyBoard.whiteSetupStones);
  XCTAssertNil(testeeEmptyBoard.noSetupStones);
  XCTAssertEqual(testeeEmptyBoard.setupFirstMoveColor, GoColorNone);
  XCTAssertNil(testeeEmptyBoard.previousBlackSetupStones);
  XCTAssertNil(testeeEmptyBoard.previousWhiteSetupStones);
  XCTAssertEqual(testeeEmptyBoard.previousSetupFirstMoveColor, GoColorNone);

  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  point1.stoneState = GoColorBlack;
  point2.stoneState = GoColorWhite;
  enum GoColor setupFirstMoveColor = GoColorWhite;
  m_game.setupFirstMoveColor = setupFirstMoveColor;
  GoNodeSetup* testeeNonEmptyBoard = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertTrue(testeeNonEmptyBoard.isEmpty);
  XCTAssertNil(testeeNonEmptyBoard.blackSetupStones);
  XCTAssertNil(testeeNonEmptyBoard.whiteSetupStones);
  XCTAssertNil(testeeNonEmptyBoard.noSetupStones);
  XCTAssertEqual(testeeNonEmptyBoard.setupFirstMoveColor, GoColorNone);
  XCTAssertNotNil(testeeNonEmptyBoard.previousBlackSetupStones);
  XCTAssertTrue([testeeNonEmptyBoard.previousBlackSetupStones isEqualToArray:@[point1]]);
  XCTAssertNotNil(testeeNonEmptyBoard.previousWhiteSetupStones);
  XCTAssertTrue([testeeNonEmptyBoard.previousWhiteSetupStones isEqualToArray:@[point2]]);
  XCTAssertEqual(testeeNonEmptyBoard.previousSetupFirstMoveColor, setupFirstMoveColor);

  XCTAssertThrowsSpecificNamed([GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:nil],
                               NSException, NSInvalidArgumentException, @"nodeSetupWithPreviousSetupCapturedFromGame: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setupValidatedBlackStones:() method.
// -----------------------------------------------------------------------------
- (void) testSetupValidatedBlackStones
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];

  GoNodeSetup* testee = [[[GoNodeSetup alloc] init] autorelease];
  XCTAssertNil(testee.blackSetupStones);

  NSArray* newBlackSetupStones = @[point1];
  [testee setupValidatedBlackStones:newBlackSetupStones];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);

  newBlackSetupStones = @[point1, point2];
  [testee setupValidatedBlackStones:newBlackSetupStones];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);

  newBlackSetupStones = @[];
  [testee setupValidatedBlackStones:newBlackSetupStones];
  XCTAssertNil(testee.blackSetupStones);

  // Duplicates are possible
  newBlackSetupStones = @[point1, point1];
  [testee setupValidatedBlackStones:newBlackSetupStones];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);

  XCTAssertThrowsSpecificNamed([testee setupValidatedBlackStones:nil],
                               NSException, NSInvalidArgumentException, @"setupValidatedBlackStones: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setupValidatedWhiteStones:() method.
// -----------------------------------------------------------------------------
- (void) testSetupValidatedWhiteStones
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];

  GoNodeSetup* testee = [[[GoNodeSetup alloc] init] autorelease];
  XCTAssertNil(testee.whiteSetupStones);

  NSArray* newWhiteSetupStones = @[point1];
  [testee setupValidatedWhiteStones:newWhiteSetupStones];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);

  newWhiteSetupStones = @[point1, point2];
  [testee setupValidatedWhiteStones:newWhiteSetupStones];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);

  newWhiteSetupStones = @[];
  [testee setupValidatedWhiteStones:newWhiteSetupStones];
  XCTAssertNil(testee.whiteSetupStones);

  // Duplicates are possible
  newWhiteSetupStones = @[point1, point1];
  [testee setupValidatedWhiteStones:newWhiteSetupStones];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);

  XCTAssertThrowsSpecificNamed([testee setupValidatedWhiteStones:nil],
                               NSException, NSInvalidArgumentException, @"setupValidatedWhiteStones: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setupValidatedNoStones:() method.
// -----------------------------------------------------------------------------
- (void) testSetupValidatedNoStones
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];

  GoNodeSetup* testee = [[[GoNodeSetup alloc] init] autorelease];
  XCTAssertNil(testee.noSetupStones);

  NSArray* newNoSetupStones = @[point1];
  [testee setupValidatedNoStones:newNoSetupStones];
  XCTAssertNotNil(testee.noSetupStones);
  XCTAssertNotIdentical(testee.noSetupStones, newNoSetupStones);
  XCTAssertEqualObjects(testee.noSetupStones, newNoSetupStones);

  newNoSetupStones = @[point1, point2];
  [testee setupValidatedNoStones:newNoSetupStones];
  XCTAssertNotNil(testee.noSetupStones);
  XCTAssertNotIdentical(testee.noSetupStones, newNoSetupStones);
  XCTAssertEqualObjects(testee.noSetupStones, newNoSetupStones);

  newNoSetupStones = @[];
  [testee setupValidatedNoStones:newNoSetupStones];
  XCTAssertNil(testee.noSetupStones);

  // Duplicates are possible
  newNoSetupStones = @[point1, point1];
  [testee setupValidatedNoStones:newNoSetupStones];
  XCTAssertNotNil(testee.noSetupStones);
  XCTAssertNotIdentical(testee.noSetupStones, newNoSetupStones);
  XCTAssertEqualObjects(testee.noSetupStones, newNoSetupStones);

  XCTAssertThrowsSpecificNamed([testee setupValidatedNoStones:nil],
                               NSException, NSInvalidArgumentException, @"setupValidatedBlackStones: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the applySetup() method.
// -----------------------------------------------------------------------------
- (void) testApplySetup
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoBoardRegion* mainRegion = point1.region;
  XCTAssertEqual(mainRegion, point2.region);

  GoNodeSetup* testee = [[[GoNodeSetup alloc] init] autorelease];

  // Applying no setup information succeeds
  [testee applySetup];

  [testee setupValidatedBlackStones:@[point1]];
  [testee setupValidatedWhiteStones:@[]];
  [testee setupValidatedNoStones:@[]];
  [testee applySetup];
  XCTAssertEqual(GoColorBlack, point1.stoneState);
  XCTAssertNotEqual(mainRegion, point1.region);

  [testee setupValidatedBlackStones:@[]];
  [testee setupValidatedWhiteStones:@[point1]];
  [testee setupValidatedNoStones:@[]];
  [testee applySetup];
  XCTAssertEqual(GoColorWhite, point1.stoneState);
  XCTAssertNotEqual(mainRegion, point1.region);

  [testee setupValidatedBlackStones:@[]];
  [testee setupValidatedWhiteStones:@[]];
  [testee setupValidatedNoStones:@[point1]];
  [testee applySetup];
  XCTAssertEqual(GoColorNone, point1.stoneState);
  XCTAssertEqual(mainRegion, point1.region);

  [testee setupValidatedBlackStones:@[point1]];
  [testee setupValidatedWhiteStones:@[point2]];
  [testee setupValidatedNoStones:@[]];
  [testee applySetup];
  XCTAssertEqual(GoColorBlack, point1.stoneState);
  XCTAssertEqual(GoColorWhite, point2.stoneState);
  XCTAssertNotEqual(mainRegion, point1.region);
  XCTAssertNotEqual(mainRegion, point2.region);
  XCTAssertNotEqual(point1.region, point2.region);

  [testee setupValidatedBlackStones:@[]];
  [testee setupValidatedWhiteStones:@[]];
  [testee setupValidatedNoStones:@[point1, point2]];
  [testee applySetup];
  XCTAssertEqual(GoColorNone, point1.stoneState);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(mainRegion, point1.region);
  XCTAssertEqual(mainRegion, point2.region);

  XCTAssertEqual(GoColorNone, m_game.setupFirstMoveColor);
  [testee setupValidatedBlackStones:@[]];
  [testee setupValidatedWhiteStones:@[]];
  [testee setupValidatedNoStones:@[]];
  testee.setupFirstMoveColor = GoColorBlack;
  [testee applySetup];
  XCTAssertEqual(GoColorBlack, m_game.setupFirstMoveColor);

  [testee setupValidatedBlackStones:@[point1]];
  [testee setupValidatedWhiteStones:@[]];
  [testee setupValidatedNoStones:@[]];
  point1.stoneState = GoColorBlack;
  XCTAssertThrowsSpecificNamed([testee applySetup],
                               NSException, NSInternalInconsistencyException, @"applySetup failed, black stone already exists");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the revertSetup() method.
// -----------------------------------------------------------------------------
- (void) testRevertSetup
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoPoint* point3 = [board pointAtVertex:@"C1"];
  GoBoardRegion* mainRegion = point1.region;
  XCTAssertEqual(mainRegion, point2.region);

  // Reverting with no setup information succeeds
  GoNodeSetup* testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  [testee applySetup];
  [testee revertSetup];

  // Revert setup with black and white setup stones
  // => back to no stones
  [testee setupValidatedBlackStones:@[point1]];
  [testee setupValidatedWhiteStones:@[point2, point3]];
  [testee setupValidatedNoStones:@[]];
  [testee applySetup];
  XCTAssertEqual(GoColorBlack, point1.stoneState);
  XCTAssertEqual(GoColorWhite, point2.stoneState);
  XCTAssertEqual(GoColorWhite, point3.stoneState);
  XCTAssertNotEqual(mainRegion, point1.region);
  XCTAssertNotEqual(mainRegion, point2.region);
  XCTAssertNotEqual(mainRegion, point3.region);
  XCTAssertNotEqual(point1.region, point2.region);
  XCTAssertNotEqual(point1.region, point3.region);
  XCTAssertEqual(point2.region, point3.region);
  [testee revertSetup];
  XCTAssertEqual(GoColorNone, point1.stoneState);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);
  XCTAssertEqual(mainRegion, point1.region);
  XCTAssertEqual(mainRegion, point2.region);
  XCTAssertEqual(mainRegion, point3.region);

  // Revert setup with black and white setup stones, and clearing a handicap
  // stone
  // => back to handicap stone
  m_game.handicapPoints = @[point1];
  testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  [testee setupValidatedBlackStones:@[point2]];
  [testee setupValidatedWhiteStones:@[point3]];
  [testee setupValidatedNoStones:@[point1]];
  [testee applySetup];
  XCTAssertEqual(GoColorNone, point1.stoneState);
  XCTAssertEqual(GoColorBlack, point2.stoneState);
  XCTAssertEqual(GoColorWhite, point3.stoneState);
  XCTAssertEqual(mainRegion, point1.region);
  XCTAssertNotEqual(mainRegion, point2.region);
  XCTAssertNotEqual(mainRegion, point3.region);
  XCTAssertNotEqual(point2.region, point3.region);
  [testee revertSetup];
  XCTAssertEqual(GoColorBlack, point1.stoneState);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);
  XCTAssertNotEqual(mainRegion, point1.region);
  XCTAssertEqual(mainRegion, point2.region);
  XCTAssertEqual(mainRegion, point3.region);

  // Revert setup with setupFirstMoveColor
  // => back to no color
  testee.setupFirstMoveColor = GoColorBlack;
  [testee applySetup];
  XCTAssertEqual(GoColorBlack, m_game.setupFirstMoveColor);
  [testee revertSetup];
  XCTAssertEqual(GoColorNone, m_game.setupFirstMoveColor);

  // Revert setup with setupFirstMoveColor
  // => back to previously set color
  m_game.setupFirstMoveColor = GoColorBlack;
  testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  testee.setupFirstMoveColor = GoColorWhite;
  [testee applySetup];
  XCTAssertEqual(GoColorWhite, m_game.setupFirstMoveColor);
  [testee revertSetup];
  XCTAssertEqual(GoColorBlack, m_game.setupFirstMoveColor);

  testee = [[[GoNodeSetup alloc] init] autorelease];
  XCTAssertThrowsSpecificNamed([testee revertSetup],
                               NSException, NSInternalInconsistencyException, @"revertSetup failed, applySetup not invoked");

  m_game.handicapPoints = @[point1];
  testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  [testee setupValidatedNoStones:@[point1]];
  point1.stoneState = GoColorBlack;
  XCTAssertThrowsSpecificNamed([testee revertSetup],
                               NSException, NSInternalInconsistencyException, @"revertSetup failed, black stone already exists");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setupBlackStone:() method.
// -----------------------------------------------------------------------------
- (void) testSetupBlackStone
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoPoint* point3 = [board pointAtVertex:@"C1"];

  GoNodeSetup* testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];

  NSArray* newBlackSetupStones = @[point1];
  [testee setupBlackStone:point1];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqual(GoColorNone, point1.stoneState);

  // Point already in list can be set up again => no change
  [testee setupBlackStone:point1];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqual(GoColorNone, point1.stoneState);

  // Point is removed from whiteSetupStones
  NSArray* newWhiteSetupStones = @[point2];
  [testee setupValidatedWhiteStones:@[point2]];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);
  newBlackSetupStones = @[point1, point2];
  [testee setupBlackStone:point2];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertNil(testee.whiteSetupStones);
  XCTAssertEqual(GoColorNone, point2.stoneState);

  // Point is removed from noSetupStones
  NSArray* newNoSetupStones = @[point3];
  [testee setupValidatedNoStones:@[point3]];
  XCTAssertNotNil(testee.noSetupStones);
  XCTAssertNotIdentical(testee.noSetupStones, newNoSetupStones);
  XCTAssertEqualObjects(testee.noSetupStones, newNoSetupStones);
  newBlackSetupStones = @[point1, point2, point3];
  [testee setupBlackStone:point3];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertNil(testee.noSetupStones);
  XCTAssertEqual(GoColorNone, point3.stoneState);

  // Point is not added when it is already in the previous setup
  NSArray* newPreviousBlackSetupStones = @[point1];
  point1.stoneState = GoColorBlack;
  testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertNotNil(testee.previousBlackSetupStones);
  XCTAssertNotIdentical(testee.previousBlackSetupStones, newPreviousBlackSetupStones);
  XCTAssertEqualObjects(testee.previousBlackSetupStones, newPreviousBlackSetupStones);
  [testee setupBlackStone:point1];
  XCTAssertNil(testee.blackSetupStones);

  XCTAssertThrowsSpecificNamed([testee setupBlackStone:nil],
                               NSException, NSInvalidArgumentException, @"setupBlackStone: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setupWhiteStone:() method.
// -----------------------------------------------------------------------------
- (void) testSetupWhiteStone
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoPoint* point3 = [board pointAtVertex:@"C1"];

  GoNodeSetup* testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];

  NSArray* newWhiteSetupStones = @[point1];
  [testee setupWhiteStone:point1];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqual(GoColorNone, point1.stoneState);

  // Point already in list can be set up again => no change
  [testee setupWhiteStone:point1];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqual(GoColorNone, point1.stoneState);

  // Point is removed from blackSetupStones
  NSArray* newBlackSetupStones = @[point2];
  [testee setupValidatedBlackStones:@[point2]];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);
  newWhiteSetupStones = @[point1, point2];
  [testee setupWhiteStone:point2];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertNil(testee.blackSetupStones);
  XCTAssertEqual(GoColorNone, point2.stoneState);

  // Point is removed from noSetupStones
  NSArray* newNoSetupStones = @[point3];
  [testee setupValidatedNoStones:@[point3]];
  XCTAssertNotNil(testee.noSetupStones);
  XCTAssertNotIdentical(testee.noSetupStones, newNoSetupStones);
  XCTAssertEqualObjects(testee.noSetupStones, newNoSetupStones);
  newWhiteSetupStones = @[point1, point2, point3];
  [testee setupWhiteStone:point3];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertNil(testee.noSetupStones);
  XCTAssertEqual(GoColorNone, point3.stoneState);

  // Point is not added when it is already in the previous setup
  NSArray* newPreviousWhiteSetupStones = @[point1];
  point1.stoneState = GoColorWhite;
  testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertNotNil(testee.previousWhiteSetupStones);
  XCTAssertNotIdentical(testee.previousWhiteSetupStones, newPreviousWhiteSetupStones);
  XCTAssertEqualObjects(testee.previousWhiteSetupStones, newPreviousWhiteSetupStones);
  [testee setupWhiteStone:point1];
  XCTAssertNil(testee.whiteSetupStones);

  XCTAssertThrowsSpecificNamed([testee setupWhiteStone:nil],
                               NSException, NSInvalidArgumentException, @"setupWhiteStone: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setupNoStone:() method.
// -----------------------------------------------------------------------------
- (void) testSetupNoStone
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];

  GoNodeSetup* testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];

  // No setup point cannot be set up if point was already empty
  [testee setupNoStone:point1];
  XCTAssertNil(testee.noSetupStones);
  XCTAssertEqual(GoColorNone, point1.stoneState);

  // Point is removed from blackSetupStones
  NSArray* newBlackSetupStones = @[point1];
  [testee setupValidatedBlackStones:@[point1]];
  XCTAssertNotNil(testee.blackSetupStones);
  XCTAssertNotIdentical(testee.blackSetupStones, newBlackSetupStones);
  XCTAssertEqualObjects(testee.blackSetupStones, newBlackSetupStones);
  [testee setupNoStone:point1];
  XCTAssertNil(testee.noSetupStones);
  XCTAssertNil(testee.blackSetupStones);
  XCTAssertEqual(GoColorNone, point1.stoneState);

  // Point is removed from whiteSetupStones
  NSArray* newWhiteSetupStones = @[point1];
  [testee setupValidatedWhiteStones:@[point1]];
  XCTAssertNotNil(testee.whiteSetupStones);
  XCTAssertNotIdentical(testee.whiteSetupStones, newWhiteSetupStones);
  XCTAssertEqualObjects(testee.whiteSetupStones, newWhiteSetupStones);
  [testee setupNoStone:point1];
  XCTAssertNil(testee.noSetupStones);
  XCTAssertNil(testee.whiteSetupStones);
  XCTAssertEqual(GoColorNone, point1.stoneState);

  // Point is added when it is in the previous setup
  NSArray* newPreviousBlackSetupStones = @[point1];
  NSArray* newPreviousWhiteSetupStones = @[point2];
  point1.stoneState = GoColorBlack;
  point2.stoneState = GoColorWhite;
  testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertNotNil(testee.previousBlackSetupStones);
  XCTAssertNotIdentical(testee.previousBlackSetupStones, newPreviousBlackSetupStones);
  XCTAssertEqualObjects(testee.previousBlackSetupStones, newPreviousBlackSetupStones);
  XCTAssertNotNil(testee.previousWhiteSetupStones);
  XCTAssertNotIdentical(testee.previousWhiteSetupStones, newPreviousWhiteSetupStones);
  XCTAssertEqualObjects(testee.previousWhiteSetupStones, newPreviousWhiteSetupStones);
  NSArray* newNoSetupStones = @[point1, point2];
  [testee setupNoStone:point1];
  [testee setupNoStone:point2];
  XCTAssertNotNil(testee.noSetupStones);
  XCTAssertNotIdentical(testee.noSetupStones, newNoSetupStones);
  XCTAssertEqualObjects(testee.noSetupStones, newNoSetupStones);

  XCTAssertThrowsSpecificNamed([testee setupNoStone:nil],
                               NSException, NSInvalidArgumentException, @"setupNoStone: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the
/// updatePreviousSetupInformationAfterHandicapStonesDidChange:() method.
// -----------------------------------------------------------------------------
- (void) testUpdatePreviousSetupInformationAfterHandicapStonesDidChange
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];

  GoNodeSetup* testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertNil(testee.previousBlackSetupStones);

  [testee updatePreviousSetupInformationAfterHandicapStonesDidChange:m_game];
  XCTAssertNil(testee.previousBlackSetupStones);

  NSArray* newPreviousBlackSetupStones = @[point1];
  m_game.handicapPoints = @[point1];
  [testee updatePreviousSetupInformationAfterHandicapStonesDidChange:m_game];
  XCTAssertNotNil(testee.previousBlackSetupStones);
  XCTAssertNotIdentical(testee.previousBlackSetupStones, newPreviousBlackSetupStones);
  XCTAssertEqualObjects(testee.previousBlackSetupStones, newPreviousBlackSetupStones);

  [testee updatePreviousSetupInformationAfterHandicapStonesDidChange:m_game];
  XCTAssertNotNil(testee.previousBlackSetupStones);
  XCTAssertNotIdentical(testee.previousBlackSetupStones, newPreviousBlackSetupStones);
  XCTAssertEqualObjects(testee.previousBlackSetupStones, newPreviousBlackSetupStones);

  newPreviousBlackSetupStones = @[point2];
  m_game.handicapPoints = @[point2];
  [testee updatePreviousSetupInformationAfterHandicapStonesDidChange:m_game];
  XCTAssertNotNil(testee.previousBlackSetupStones);
  XCTAssertNotIdentical(testee.previousBlackSetupStones, newPreviousBlackSetupStones);
  XCTAssertEqualObjects(testee.previousBlackSetupStones, newPreviousBlackSetupStones);

  m_game.handicapPoints = @[];
  [testee updatePreviousSetupInformationAfterHandicapStonesDidChange:m_game];
  XCTAssertNil(testee.previousBlackSetupStones);

  testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  [testee setupBlackStone:point1];
  m_game.handicapPoints = @[point1];
  XCTAssertThrowsSpecificNamed([testee updatePreviousSetupInformationAfterHandicapStonesDidChange:m_game],
                               NSException, NSInternalInconsistencyException, @"updatePreviousSetupInformationAfterHandicapStonesDidChange: with handicap stone intersection already occupied by black setup stone");
  m_game.handicapPoints = @[];

  m_game.handicapPoints = @[point1];
  testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  [testee setupNoStone:point1];
  m_game.handicapPoints = @[];
  XCTAssertThrowsSpecificNamed([testee updatePreviousSetupInformationAfterHandicapStonesDidChange:m_game],
                               NSException, NSInternalInconsistencyException, @"updatePreviousSetupInformationAfterHandicapStonesDidChange: with handicap stone intersection already occupied by black setup stone");

  testee = [[[GoNodeSetup alloc] init] autorelease];
  XCTAssertThrowsSpecificNamed([testee updatePreviousSetupInformationAfterHandicapStonesDidChange:nil],
                               NSException, NSInvalidArgumentException, @"updatePreviousSetupInformationAfterHandicapStonesDidChange: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the stoneStateAfterSetup:() method.
// -----------------------------------------------------------------------------
- (void) testStoneStateAfterSetup
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoPoint* point3 = [board pointAtVertex:@"C1"];
  GoPoint* point4 = [board pointAtVertex:@"D1"];
  GoPoint* point5 = [board pointAtVertex:@"E1"];
  GoPoint* point6 = [board pointAtVertex:@"F1"];

  point1.stoneState = GoColorBlack;
  point2.stoneState = GoColorBlack;
  point3.stoneState = GoColorWhite;
  point4.stoneState = GoColorWhite;

  GoNodeSetup* testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertEqual([testee stoneStateAfterSetup:point1], GoColorBlack);
  XCTAssertEqual([testee stoneStateAfterSetup:point2], GoColorBlack);
  XCTAssertEqual([testee stoneStateAfterSetup:point3], GoColorWhite);
  XCTAssertEqual([testee stoneStateAfterSetup:point4], GoColorWhite);
  XCTAssertEqual([testee stoneStateAfterSetup:point5], GoColorNone);
  XCTAssertEqual([testee stoneStateAfterSetup:point6], GoColorNone);

  [testee setupWhiteStone:point1];
  [testee setupNoStone:point2];
  [testee setupBlackStone:point3];
  [testee setupNoStone:point4];
  [testee setupBlackStone:point5];
  [testee setupWhiteStone:point6];
  XCTAssertEqual([testee stoneStateAfterSetup:point1], GoColorWhite);
  XCTAssertEqual([testee stoneStateAfterSetup:point2], GoColorNone);
  XCTAssertEqual([testee stoneStateAfterSetup:point3], GoColorBlack);
  XCTAssertEqual([testee stoneStateAfterSetup:point4], GoColorNone);
  XCTAssertEqual([testee stoneStateAfterSetup:point5], GoColorBlack);
  XCTAssertEqual([testee stoneStateAfterSetup:point6], GoColorWhite);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the stoneStatePreviousToSetup:() method.
// -----------------------------------------------------------------------------
- (void) testStoneStatePreviousToSetup
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoPoint* point3 = [board pointAtVertex:@"C1"];
  GoPoint* point4 = [board pointAtVertex:@"D1"];
  GoPoint* point5 = [board pointAtVertex:@"E1"];
  GoPoint* point6 = [board pointAtVertex:@"F1"];

  point1.stoneState = GoColorBlack;
  point2.stoneState = GoColorBlack;
  point3.stoneState = GoColorWhite;
  point4.stoneState = GoColorWhite;

  GoNodeSetup* testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertEqual([testee stoneStatePreviousToSetup:point1], GoColorBlack);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point2], GoColorBlack);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point3], GoColorWhite);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point4], GoColorWhite);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point5], GoColorNone);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point6], GoColorNone);

  [testee setupWhiteStone:point1];
  [testee setupNoStone:point2];
  [testee setupBlackStone:point3];
  [testee setupNoStone:point4];
  [testee setupBlackStone:point5];
  [testee setupWhiteStone:point6];
  XCTAssertEqual([testee stoneStatePreviousToSetup:point1], GoColorBlack);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point2], GoColorBlack);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point3], GoColorWhite);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point4], GoColorWhite);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point5], GoColorNone);
  XCTAssertEqual([testee stoneStatePreviousToSetup:point6], GoColorNone);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e empty property.
// -----------------------------------------------------------------------------
- (void) testEmpty
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"B1"];
  GoPoint* point3 = [board pointAtVertex:@"C1"];

  point2.stoneState = GoColorBlack;
  point3.stoneState = GoColorWhite;
  m_game.setupFirstMoveColor = GoColorWhite;

  GoNodeSetup* testee = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFromGame:m_game];
  XCTAssertTrue(testee.isEmpty);

  [testee setupBlackStone:point1];
  XCTAssertFalse(testee.isEmpty);
  [testee setupNoStone:point1];
  XCTAssertTrue(testee.isEmpty);

  [testee setupWhiteStone:point1];
  XCTAssertFalse(testee.isEmpty);
  [testee setupNoStone:point1];
  XCTAssertTrue(testee.isEmpty);

  [testee setupNoStone:point2];
  XCTAssertFalse(testee.isEmpty);
  [testee setupBlackStone:point2];
  XCTAssertTrue(testee.isEmpty);

  [testee setupNoStone:point3];
  XCTAssertFalse(testee.isEmpty);
  [testee setupWhiteStone:point3];
  XCTAssertTrue(testee.isEmpty);

  testee.setupFirstMoveColor = GoColorBlack;
  XCTAssertFalse(testee.isEmpty);
  testee.setupFirstMoveColor = GoColorWhite;
  XCTAssertFalse(testee.isEmpty);
  testee.setupFirstMoveColor = GoColorNone;
  XCTAssertTrue(testee.isEmpty);
}

@end
