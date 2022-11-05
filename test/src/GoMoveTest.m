// -----------------------------------------------------------------------------
// Copyright 2011-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoMoveTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoMove.h>
#import <go/GoPlayer.h>
#import <go/GoPoint.h>


@implementation GoMoveTest

// -----------------------------------------------------------------------------
/// @brief Exercises the move:by:after:() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testMoveByAfter
{
  enum GoMoveType expectedMoveType = GoMoveTypePlay;
  GoPlayer* expectedPlayer = m_game.playerBlack;
  GoMove* expectedMovePrevious = nil;

  GoMove* move1 = [GoMove move:expectedMoveType by:expectedPlayer after:expectedMovePrevious];
  XCTAssertEqual(expectedMoveType, move1.type);
  XCTAssertEqual(expectedPlayer, move1.player);
  XCTAssertEqual(expectedMovePrevious, move1.previous);

  expectedMoveType = GoMoveTypePass;
  expectedMovePrevious = move1;
  GoMove* move2 = [GoMove move:expectedMoveType by:expectedPlayer after:expectedMovePrevious];
  XCTAssertEqual(expectedMoveType, move2.type);
  XCTAssertEqual(expectedPlayer, move2.player);
  XCTAssertEqual(expectedMovePrevious, move2.previous);

  XCTAssertThrowsSpecificNamed([GoMove move:(enum GoMoveType)42 by:expectedPlayer after:nil],
                              NSException, NSInvalidArgumentException, @"evil cast");
  XCTAssertThrowsSpecificNamed([GoMove move:expectedMoveType by:nil after:nil],
                              NSException, NSInvalidArgumentException, @"player is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e point property.
// -----------------------------------------------------------------------------
- (void) testPoint
{
  GoPlayer* expectedPlayer = m_game.playerWhite;

  GoMove* move1 = [GoMove move:GoMoveTypePlay by:expectedPlayer after:nil];
  XCTAssertNil(move1.point);

  // Test 1: Set arbitrary point
  GoPoint* point1 = [m_game.board pointAtVertex:@"A1"];
  move1.point = point1;
  XCTAssertEqual(point1, move1.point);

  // Test 2: Set a different point
  GoPoint* point2 = [m_game.board pointAtVertex:@"Q14"];
  move1.point = point2;
  XCTAssertEqual(point2, move1.point);

  // Test 3: Provide a nil argument
  move1.point = nil;
  XCTAssertNil(move1.point);

  // Test 4: Pass move cannot have a point
  GoMove* move2 = [GoMove move:GoMoveTypePass by:expectedPlayer after:nil];
  XCTAssertThrowsSpecificNamed(move2.point = point1,
                              NSException, NSInternalInconsistencyException, @"pass move");
  XCTAssertNil(move2.point);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e capturedStones property with regular play stones
/// being captured.
// -----------------------------------------------------------------------------
- (void) testCapturedStones
{
  NSUInteger expectedNumberOfCapturedStones = 0;

  // White plays stone that is going to be captured
  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  GoPoint* point1 = [m_game.board pointAtVertex:@"A1"];
  move1.point = point1;
  [move1 doIt];
  XCTAssertNotNil(move1.capturedStones);
  XCTAssertEqual(expectedNumberOfCapturedStones, move1.capturedStones.count);
  XCTAssertEqual(GoColorWhite, point1.stoneState);

  // Black plays preparation move
  GoMove* move2 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  move2.point = point2;
  [move2 doIt];
  XCTAssertNotNil(move2.capturedStones);
  XCTAssertEqual(expectedNumberOfCapturedStones, move2.capturedStones.count);

  // Black plays capturing move
  expectedNumberOfCapturedStones = 1;
  GoMove* move3 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  GoPoint* point3 = [m_game.board pointAtVertex:@"A2"];
  move3.point = point3;
  [move3 doIt];
  XCTAssertNotNil(move3.capturedStones);
  XCTAssertEqual(expectedNumberOfCapturedStones, move3.capturedStones.count);
  XCTAssertTrue([move3.capturedStones containsObject:point1]);
  XCTAssertEqual(GoColorNone, point1.stoneState);
  
  // White plays preparation moves for counter attack
  GoMove* move4 = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  GoPoint* point4 = [m_game.board pointAtVertex:@"C1"];
  move4.point = point4;
  [move4 doIt];
  GoMove* move5 = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  GoPoint* point5 = [m_game.board pointAtVertex:@"B2"];
  move5.point = point5;
  [move5 doIt];
  GoMove* move6 = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  GoPoint* point6 = [m_game.board pointAtVertex:@"A3"];
  move6.point = point6;
  [move6 doIt];

  // White plays capturing move, capturing two stones in different regions
  expectedNumberOfCapturedStones = 2;
  GoMove* move7 = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  move7.point = point1;
  [move7 doIt];
  XCTAssertNotNil(move7.capturedStones);
  XCTAssertEqual(expectedNumberOfCapturedStones, move7.capturedStones.count);
  XCTAssertTrue([move7.capturedStones containsObject:point2]);
  XCTAssertTrue([move7.capturedStones containsObject:point3]);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);

  NSUInteger expectedNumberOfRegions = 7;
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e capturedStones property with handicap and setup
/// stones being captured.
// -----------------------------------------------------------------------------
- (void) testCapturedStonesHandicapAndSetup
{
  GoPoint* handicapPoint = [m_game.board pointAtVertex:@"A1"];
  m_game.handicapPoints = @[handicapPoint];

  GoPoint* blackSetupPoint1 = [m_game.board pointAtVertex:@"A2"];
  GoPoint* blackSetupPoint2 = [m_game.board pointAtVertex:@"B1"];
  [m_game changeSetupPoint:blackSetupPoint1 toStoneState:GoColorBlack];
  [m_game changeSetupPoint:blackSetupPoint2 toStoneState:GoColorBlack];

  GoPoint* whiteSetupPoint1 = [m_game.board pointAtVertex:@"A3"];
  GoPoint* whiteSetupPoint2 = [m_game.board pointAtVertex:@"B2"];
  [m_game changeSetupPoint:whiteSetupPoint1 toStoneState:GoColorWhite];
  [m_game changeSetupPoint:whiteSetupPoint2 toStoneState:GoColorWhite];

  int expectedNumberOfCapturedStones = 3;
  GoMove* move = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  move.point = [m_game.board pointAtVertex:@"C1"];
  [move doIt];
  XCTAssertNotNil(move.capturedStones);
  XCTAssertEqual(expectedNumberOfCapturedStones, move.capturedStones.count);
  XCTAssertTrue([move.capturedStones containsObject:handicapPoint]);
  XCTAssertTrue([move.capturedStones containsObject:blackSetupPoint1]);
  XCTAssertTrue([move.capturedStones containsObject:blackSetupPoint2]);
  XCTAssertEqual(GoColorNone, handicapPoint.stoneState);
  XCTAssertEqual(GoColorNone, blackSetupPoint1.stoneState);
  XCTAssertEqual(GoColorNone, blackSetupPoint2.stoneState);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the doIt() method.
// -----------------------------------------------------------------------------
- (void) testDoIt
{
  GoPlayer* expectedPlayer = m_game.playerWhite;
  enum GoColor expectedStoneState = expectedPlayer.isBlack ? GoColorBlack : GoColorWhite;
  NSUInteger expectedNumberOfRegions = 2;

  GoMove* move1 = [GoMove move:GoMoveTypePlay by:expectedPlayer after:nil];
  XCTAssertNil(move1.point);

  // Test 1: Play arbitrary stone
  GoPoint* point1 = [m_game.board pointAtVertex:@"A1"];
  GoBoardRegion* mainRegion = point1.region;
  XCTAssertNotNil(mainRegion);
  XCTAssertEqual(GoColorNone, point1.stoneState);
  move1.point = point1;
  XCTAssertEqual(point1, move1.point);
  [move1 doIt];
  XCTAssertEqual(expectedStoneState, point1.stoneState);
  XCTAssertTrue(point1.region != mainRegion);
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);

  // Test 2: Play neighbouring stone
  GoMove* move2 = [GoMove move:GoMoveTypePlay by:expectedPlayer after:nil];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  move2.point = point2;
  XCTAssertEqual(point2, move2.point);
  [move2 doIt];
  XCTAssertEqual(expectedStoneState, point2.stoneState);
  XCTAssertTrue(point2.region != mainRegion);
  XCTAssertEqual(point1.region, point2.region);
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);

  // No more regular tests required, capturing is exercised in
  // testCapturedStones()

  // Test 3: Play without providing an intersection
  GoMove* move3 = [GoMove move:GoMoveTypePlay by:expectedPlayer after:nil];
  move3.point = nil;
  XCTAssertThrowsSpecificNamed([move3 doIt],
                              NSException, NSInternalInconsistencyException, @"point is nil");

  // Test 4: Play on intersection that already has a stone
  move3.point = point1;
  XCTAssertThrowsSpecificNamed([move3 doIt],
                              NSException, NSInternalInconsistencyException, @"intersection already has stone");

  // Test 5: GoMove object should be able to play on a legal intersection even
  // after exceptions occurred and were caught
  GoPoint* point3 = [m_game.board pointAtVertex:@"C1"];
  move3.point = point3;
  XCTAssertEqual(point3, move3.point);
  [move3 doIt];
  XCTAssertEqual(expectedStoneState, point3.stoneState);
  XCTAssertTrue(point3.region != mainRegion);
  XCTAssertEqual(point1.region, point3.region);
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);

  // Test 6: Make same move twice without an undo in between
  XCTAssertThrowsSpecificNamed([move3 doIt],
                              NSException, NSInternalInconsistencyException, @"make same move twice without undo in between");

  // Test 7: Pass move (no post-condition to check, doIt() must simply run
  // without exceptions)
  GoMove* move4 = [GoMove move:GoMoveTypePass by:expectedPlayer after:nil];
  [move4 doIt];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the undo() method.
// -----------------------------------------------------------------------------
- (void) testUndo
{
  // Set up a position with 4 moves which we are then going to undo one by one.
  // - White playing A1
  // - Black playing B1
  // - White passing
  // - Black playing A2 and capturing A1
  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  GoPoint* point1 = [m_game.board pointAtVertex:@"A1"];
  GoBoardRegion* mainRegion = point1.region;
  XCTAssertNotNil(mainRegion);
  move1.point = point1;
  [move1 doIt];
  GoMove* move2 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:move1];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  move2.point = point2;
  [move2 doIt];
  GoMove* move3 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move2];
  // Black plays capturing move
  GoMove* move4 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:move3];
  GoPoint* point3 = [m_game.board pointAtVertex:@"A2"];
  move4.point = point3;
  [move4 doIt];

  // First check whether everything has been set up correctly
  NSUInteger expectedNumberOfRegions = 4;
  NSUInteger expectedNumberOfCapturedStones = 1;
  XCTAssertEqual(GoColorNone, point1.stoneState);
  XCTAssertEqual(GoColorBlack, point2.stoneState);
  XCTAssertEqual(GoColorBlack, point3.stoneState);
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);
  XCTAssertTrue(point1.region != mainRegion);
  XCTAssertTrue(point2.region != mainRegion);
  XCTAssertTrue(point3.region != mainRegion);
  XCTAssertEqual(expectedNumberOfCapturedStones, move4.capturedStones.count);
  XCTAssertTrue([move4.capturedStones containsObject:point1]);
  XCTAssertNil(move1.previous);
  XCTAssertEqual(move1, move2.previous);
  XCTAssertEqual(move2, move3.previous);
  XCTAssertEqual(move3, move4.previous);
  XCTAssertEqual(m_game.playerWhite, move1.player);
  XCTAssertEqual(m_game.playerBlack, move2.player);
  XCTAssertEqual(m_game.playerWhite, move3.player);
  XCTAssertEqual(m_game.playerBlack, move4.player);
  XCTAssertEqual(point1, move1.point);
  XCTAssertEqual(point2, move2.point);
  XCTAssertNil(move3.point);
  XCTAssertEqual(point3, move4.point);

  // Undo move 4
  [move4 undo];
  expectedNumberOfRegions = 3;
  expectedNumberOfCapturedStones = 1;
  XCTAssertEqual(GoColorWhite, point1.stoneState);
  XCTAssertEqual(GoColorBlack, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);
  XCTAssertTrue(point1.region != mainRegion);
  XCTAssertTrue(point2.region != mainRegion);
  XCTAssertEqual(mainRegion, point3.region);
  XCTAssertEqual(expectedNumberOfCapturedStones, move4.capturedStones.count);
  XCTAssertEqual(move3, move4.previous);
  XCTAssertEqual(move2, move3.previous);
  XCTAssertEqual(m_game.playerBlack, move4.player);
  XCTAssertEqual(point3, move4.point);

  // Undo move 3
  [move3 undo];
  expectedNumberOfCapturedStones = 0;
  XCTAssertEqual(GoColorWhite, point1.stoneState);
  XCTAssertEqual(GoColorBlack, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);
  XCTAssertTrue(point1.region != mainRegion);
  XCTAssertTrue(point2.region != mainRegion);
  XCTAssertEqual(mainRegion, point3.region);
  XCTAssertEqual(expectedNumberOfCapturedStones, move3.capturedStones.count);
  XCTAssertEqual(move2, move3.previous);
  XCTAssertEqual(move1, move2.previous);
  XCTAssertEqual(m_game.playerWhite, move3.player);
  XCTAssertNil(move3.point);

  // Undo move 2
  [move2 undo];
  expectedNumberOfRegions = 2;
  XCTAssertEqual(GoColorWhite, point1.stoneState);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);
  XCTAssertTrue(point1.region != mainRegion);
  XCTAssertEqual(mainRegion, point2.region);
  XCTAssertEqual(mainRegion, point3.region);
  XCTAssertEqual(expectedNumberOfCapturedStones, move2.capturedStones.count);
  XCTAssertEqual(move1, move2.previous);
  XCTAssertNil(move1.previous);
  XCTAssertEqual(m_game.playerBlack, move2.player);
  XCTAssertEqual(point2, move2.point);

  // Undo move 1
  [move1 undo];
  expectedNumberOfRegions = 1;
  XCTAssertEqual(GoColorNone, point1.stoneState);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);
  XCTAssertEqual(mainRegion, point1.region);
  XCTAssertEqual(mainRegion, point2.region);
  XCTAssertEqual(mainRegion, point3.region);
  XCTAssertEqual(expectedNumberOfCapturedStones, move1.capturedStones.count);
  XCTAssertNil(move1.previous);
  XCTAssertEqual(m_game.playerWhite, move1.player);
  XCTAssertEqual(point1, move1.point);

  // Undo twice in a row without invoking doIt() in between
  XCTAssertThrowsSpecificNamed([move1 undo],
                              NSException, NSInternalInconsistencyException, @"undo same move twice without doIt in between");

  // Undo with intersection having the wrong color
  [move1 doIt];
  move1.point = point2;
  XCTAssertThrowsSpecificNamed([move1 undo],
                              NSException, NSInternalInconsistencyException, @"undo with wrong intersection color");

  // Undo with no associated GoPoint
  GoMove* move5 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  XCTAssertThrowsSpecificNamed([move5 undo],
                              NSException, NSInternalInconsistencyException, @"no associated GoPoint");

  // Undo a pass move (no post-condition to check, undo() must simply run
  // without exceptions)
  GoMove* move6 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  [move6 doIt];
  [move6 undo];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e moveNumber property
// -----------------------------------------------------------------------------
- (void) testMoveNumber
{
  enum GoMoveType moveType = GoMoveTypePlay;
  GoPlayer* player = m_game.playerBlack;
  GoMove* movePrevious = nil;

  int expectedMoveNumber = 1;
  GoMove* move1 = [GoMove move:moveType by:player after:movePrevious];
  XCTAssertEqual(expectedMoveNumber, move1.moveNumber);

  moveType = GoMoveTypePass;
  movePrevious = move1;
  expectedMoveNumber = 2;
  GoMove* move2 = [GoMove move:moveType by:player after:movePrevious];
  XCTAssertEqual(expectedMoveNumber, move2.moveNumber);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e goMoveValuation property
// -----------------------------------------------------------------------------
- (void) testGoMoveValuation
{
  enum GoMoveType moveType = GoMoveTypePlay;
  GoPlayer* player = m_game.playerBlack;
  GoMove* movePrevious = nil;
  GoMove* move = [GoMove move:moveType by:player after:movePrevious];

  XCTAssertEqual(move.goMoveValuation, GoMoveValuationNone);

  move.goMoveValuation = GoMoveValuationInteresting;
  XCTAssertEqual(move.goMoveValuation, GoMoveValuationInteresting);
}

@end
