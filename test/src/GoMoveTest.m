// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
  GoMove* expectedMoveNext = nil;

  GoMove* move1 = [GoMove move:expectedMoveType by:expectedPlayer after:expectedMovePrevious];
  STAssertEquals(expectedMoveType, move1.type, nil);
  STAssertEquals(expectedPlayer, move1.player, nil);
  STAssertEquals(expectedMovePrevious, move1.previous, nil);
  STAssertEquals(expectedMoveNext, move1.next, nil);

  expectedMoveType = GoMoveTypePass;
  expectedMovePrevious = move1;
  GoMove* move2 = [GoMove move:expectedMoveType by:expectedPlayer after:expectedMovePrevious];
  STAssertEquals(expectedMoveType, move2.type, nil);
  STAssertEquals(expectedPlayer, move2.player, nil);
  STAssertEquals(expectedMovePrevious, move2.previous, nil);
  STAssertEquals(expectedMoveNext, move2.next, nil);
  // Move 1 must now have it's "next" property set up
  STAssertEquals(move2, move1.next, nil);

  STAssertThrowsSpecificNamed([GoMove move:(enum GoMoveType)42 by:expectedPlayer after:nil],
                              NSException, NSInvalidArgumentException, @"evil cast");
  STAssertThrowsSpecificNamed([GoMove move:expectedMoveType by:nil after:nil],
                              NSException, NSInvalidArgumentException, @"player is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e point property.
// -----------------------------------------------------------------------------
- (void) testPoint
{
  GoPlayer* expectedPlayer = m_game.playerWhite;

  GoMove* move1 = [GoMove move:GoMoveTypePlay by:expectedPlayer after:nil];
  STAssertNil(move1.point, nil);

  // Test 1: Set arbitrary point
  GoPoint* point1 = [m_game.board pointAtVertex:@"A1"];
  move1.point = point1;
  STAssertEquals(point1, move1.point, nil);

  // Test 2: Set a different point
  GoPoint* point2 = [m_game.board pointAtVertex:@"Q14"];
  move1.point = point2;
  STAssertEquals(point2, move1.point, nil);

  // Test 3: Provide a nil argument
  move1.point = nil;
  STAssertNil(move1.point, nil);

  // Test 4: Pass move cannot have a point
  GoMove* move2 = [GoMove move:GoMoveTypePass by:expectedPlayer after:nil];
  STAssertThrowsSpecificNamed(move2.point = point1,
                              NSException, NSInternalInconsistencyException, @"pass move");
  STAssertNil(move2.point, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e capturedStones property.
// -----------------------------------------------------------------------------
- (void) testCapturedStones
{
  NSUInteger expectedNumberOfCapturedStones = 0;

  // White plays stone that is going to be captured
  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerWhite after:nil];
  GoPoint* point1 = [m_game.board pointAtVertex:@"A1"];
  move1.point = point1;
  [move1 doIt];
  STAssertNotNil(move1.capturedStones, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move1.capturedStones.count, nil);
  STAssertEquals(GoColorWhite, point1.stoneState, nil);

  // Black plays preparation move
  GoMove* move2 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  move2.point = point2;
  [move2 doIt];
  STAssertNotNil(move2.capturedStones, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move2.capturedStones.count, nil);

  // Black plays capturing move
  expectedNumberOfCapturedStones = 1;
  GoMove* move3 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  GoPoint* point3 = [m_game.board pointAtVertex:@"A2"];
  move3.point = point3;
  [move3 doIt];
  STAssertNotNil(move3.capturedStones, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move3.capturedStones.count, nil);
  STAssertTrue([move3.capturedStones containsObject:point1], nil);
  STAssertEquals(GoColorNone, point1.stoneState, nil);
  
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
  STAssertNotNil(move7.capturedStones, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move7.capturedStones.count, nil);
  STAssertTrue([move7.capturedStones containsObject:point2], nil);
  STAssertTrue([move7.capturedStones containsObject:point3], nil);
  STAssertEquals(GoColorNone, point2.stoneState, nil);
  STAssertEquals(GoColorNone, point3.stoneState, nil);

  NSUInteger expectedNumberOfRegions = 7;
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);
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
  STAssertNil(move1.point, nil);

  // Test 1: Play arbitrary stone
  GoPoint* point1 = [m_game.board pointAtVertex:@"A1"];
  GoBoardRegion* mainRegion = point1.region;
  STAssertNotNil(mainRegion, nil);
  STAssertEquals(GoColorNone, point1.stoneState, nil);
  move1.point = point1;
  STAssertEquals(point1, move1.point, nil);
  [move1 doIt];
  STAssertEquals(expectedStoneState, point1.stoneState, nil);
  STAssertTrue(point1.region != mainRegion, nil);
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);

  // Test 2: Play neighbouring stone
  GoMove* move2 = [GoMove move:GoMoveTypePlay by:expectedPlayer after:nil];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  move2.point = point2;
  STAssertEquals(point2, move2.point, nil);
  [move2 doIt];
  STAssertEquals(expectedStoneState, point2.stoneState, nil);
  STAssertTrue(point2.region != mainRegion, nil);
  STAssertEquals(point1.region, point2.region, nil);
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);

  // No more regular tests required, capturing is exercised in
  // testCapturedStones()

  // Test 3: Play without providing an intersection
  GoMove* move3 = [GoMove move:GoMoveTypePlay by:expectedPlayer after:nil];
  move3.point = nil;
  STAssertThrowsSpecificNamed([move3 doIt],
                              NSException, NSInternalInconsistencyException, @"point is nil");

  // Test 4: Play on intersection that already has a stone
  move3.point = point1;
  STAssertThrowsSpecificNamed([move3 doIt],
                              NSException, NSInternalInconsistencyException, @"intersection already has stone");

  // Test 5: GoMove object should be able to play on a legal intersection even
  // after exceptions occurred and were caught
  GoPoint* point3 = [m_game.board pointAtVertex:@"C1"];
  move3.point = point3;
  STAssertEquals(point3, move3.point, nil);
  [move3 doIt];
  STAssertEquals(expectedStoneState, point3.stoneState, nil);
  STAssertTrue(point3.region != mainRegion, nil);
  STAssertEquals(point1.region, point3.region, nil);
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);

  // Test 6: Make same move twice without an undo in between
  STAssertThrowsSpecificNamed([move3 doIt],
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
  STAssertNotNil(mainRegion, nil);
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
  STAssertEquals(GoColorNone, point1.stoneState, nil);
  STAssertEquals(GoColorBlack, point2.stoneState, nil);
  STAssertEquals(GoColorBlack, point3.stoneState, nil);
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);
  STAssertTrue(point1.region != mainRegion, nil);
  STAssertTrue(point2.region != mainRegion, nil);
  STAssertTrue(point3.region != mainRegion, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move4.capturedStones.count, nil);
  STAssertTrue([move4.capturedStones containsObject:point1], nil);
  STAssertNil(move1.previous, nil);
  STAssertEquals(move2, move1.next, nil);
  STAssertEquals(move1, move2.previous, nil);
  STAssertEquals(move3, move2.next, nil);
  STAssertEquals(move2, move3.previous, nil);
  STAssertEquals(move4, move3.next, nil);
  STAssertEquals(move3, move4.previous, nil);
  STAssertNil(move4.next, nil);
  STAssertEquals(m_game.playerWhite, move1.player, nil);
  STAssertEquals(m_game.playerBlack, move2.player, nil);
  STAssertEquals(m_game.playerWhite, move3.player, nil);
  STAssertEquals(m_game.playerBlack, move4.player, nil);
  STAssertEquals(point1, move1.point, nil);
  STAssertEquals(point2, move2.point, nil);
  STAssertNil(move3.point, nil);
  STAssertEquals(point3, move4.point, nil);

  // Undo move 4
  [move4 undo];
  expectedNumberOfRegions = 3;
  expectedNumberOfCapturedStones = 0;
  STAssertEquals(GoColorWhite, point1.stoneState, nil);
  STAssertEquals(GoColorBlack, point2.stoneState, nil);
  STAssertEquals(GoColorNone, point3.stoneState, nil);
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);
  STAssertTrue(point1.region != mainRegion, nil);
  STAssertTrue(point2.region != mainRegion, nil);
  STAssertEquals(mainRegion, point3.region, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move4.capturedStones.count, nil);
  STAssertNil(move4.next, nil);
  STAssertEquals(move3, move4.previous, nil);
  STAssertEquals(move4, move3.next, nil);
  STAssertEquals(move2, move3.previous, nil);
  STAssertEquals(m_game.playerBlack, move4.player, nil);
  STAssertEquals(point3, move4.point, nil);

  // Undo move 3
  [move3 undo];
  STAssertEquals(GoColorWhite, point1.stoneState, nil);
  STAssertEquals(GoColorBlack, point2.stoneState, nil);
  STAssertEquals(GoColorNone, point3.stoneState, nil);
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);
  STAssertTrue(point1.region != mainRegion, nil);
  STAssertTrue(point2.region != mainRegion, nil);
  STAssertEquals(mainRegion, point3.region, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move3.capturedStones.count, nil);
  STAssertEquals(move4, move3.next, nil);
  STAssertEquals(move2, move3.previous, nil);
  STAssertEquals(move3, move2.next, nil);
  STAssertEquals(move1, move2.previous, nil);
  STAssertEquals(m_game.playerWhite, move3.player, nil);
  STAssertNil(move3.point, nil);

  // Undo move 2
  [move2 undo];
  expectedNumberOfRegions = 2;
  STAssertEquals(GoColorWhite, point1.stoneState, nil);
  STAssertEquals(GoColorNone, point2.stoneState, nil);
  STAssertEquals(GoColorNone, point3.stoneState, nil);
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);
  STAssertTrue(point1.region != mainRegion, nil);
  STAssertEquals(mainRegion, point2.region, nil);
  STAssertEquals(mainRegion, point3.region, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move2.capturedStones.count, nil);
  STAssertEquals(move3, move2.next, nil);
  STAssertEquals(move1, move2.previous, nil);
  STAssertEquals(move2, move1.next, nil);
  STAssertNil(move1.previous, nil);
  STAssertEquals(m_game.playerBlack, move2.player, nil);
  STAssertEquals(point2, move2.point, nil);

  // Undo move 1
  [move1 undo];
  expectedNumberOfRegions = 1;
  STAssertEquals(GoColorNone, point1.stoneState, nil);
  STAssertEquals(GoColorNone, point2.stoneState, nil);
  STAssertEquals(GoColorNone, point3.stoneState, nil);
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);
  STAssertEquals(mainRegion, point1.region, nil);
  STAssertEquals(mainRegion, point2.region, nil);
  STAssertEquals(mainRegion, point3.region, nil);
  STAssertEquals(expectedNumberOfCapturedStones, move1.capturedStones.count, nil);
  STAssertEquals(move2, move1.next, nil);
  STAssertNil(move1.previous, nil);
  STAssertEquals(m_game.playerWhite, move1.player, nil);
  STAssertEquals(point1, move1.point, nil);

  // Undo twice in a row without invoking doIt() in between
  STAssertThrowsSpecificNamed([move1 undo],
                              NSException, NSInternalInconsistencyException, @"undo same move twice without doIt in between");

  // Undo with intersection having the wrong color
  [move1 doIt];
  move1.point = point2;
  STAssertThrowsSpecificNamed([move1 undo],
                              NSException, NSInternalInconsistencyException, @"undo with wrong intersection color");

  // Undo with no associated GoPoint
  GoMove* move5 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  STAssertThrowsSpecificNamed([move5 undo],
                              NSException, NSInternalInconsistencyException, @"no associated GoPoint");

  // Undo a pass move (no post-condition to check, undo() must simply run
  // without exceptions)
  GoMove* move6 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  [move6 doIt];
  [move6 undo];
}

@end
