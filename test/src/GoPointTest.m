// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoPointTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoGameAdditions.h>
#import <go/GoPoint.h>
#import <go/GoVertex.h>
#import <go/GoUtilities.h>


@implementation GoPointTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of a GoPoint object after a new GoGame has
/// been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  // Some arbitrary point in the middle of the board that is not a star point
  NSString* stringVertex = @"C13";

  int expectedLiberties = 4;
  NSUInteger expectedNumberOfNeighbours = 4;
  enum GoColor expectedStoneState = GoColorNone;

  GoBoard* board = m_game.board;
  GoPoint* point = [board pointAtVertex:stringVertex];
  XCTAssertNotNil(point);
  XCTAssertFalse([point hasStone]);
  XCTAssertFalse([point blackStone]);
  XCTAssertEqual(expectedLiberties, [point liberties]);
  XCTAssertTrue([point isEqualToPoint:point]);
  XCTAssertTrue([point.vertex.string isEqualToString:stringVertex]);
  XCTAssertEqual(board, point.board);
  XCTAssertNotNil(point.left);
  XCTAssertNotNil(point.right);
  XCTAssertNotNil(point.above);
  XCTAssertNotNil(point.below);
  XCTAssertEqual(expectedNumberOfNeighbours, point.neighbours.count);
  XCTAssertNotNil(point.next);
  XCTAssertNotNil(point.previous);
  XCTAssertFalse(point.isStarPoint);
  XCTAssertEqual(expectedStoneState, point.stoneState);
  XCTAssertNotNil(point.region);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pointAtVertex:onBoard:() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testPointAtVertexOnBoard
{
  NSString* stringVertex = @"O6";
  GoVertex* vertex = [GoVertex vertexFromString:stringVertex];
  GoBoard* board = m_game.board;

  GoPoint* point = [GoPoint pointAtVertex:vertex onBoard:board];
  XCTAssertNotNil(point);
  XCTAssertEqual(board, point.board);
  XCTAssertTrue([stringVertex isEqualToString:point.vertex.string]);
  // Don't test any more attributes, testInitialState() already checked those

  XCTAssertThrowsSpecificNamed([GoPoint pointAtVertex:vertex onBoard:nil],
                              NSException, NSInvalidArgumentException, @"test 1");
  XCTAssertThrowsSpecificNamed([GoPoint pointAtVertex:nil onBoard:board],
                              NSException, NSInvalidArgumentException, @"test 2");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e neighbours property, including all the other
/// properties that provide access to direct neighbours (@e left, @e next,
/// etc.).
// -----------------------------------------------------------------------------
- (void) testNeighbours
{
  int expectedBoardSize = 19;
  GoBoard* board = m_game.board;
  XCTAssertEqual(expectedBoardSize, board.size);

  NSString* stringVertexCorner = @"T1";  // a corner that is not the first or last point
  NSString* stringVertexEdge = @"A16";
  NSString* stringVertexCenter = @"C13";
  NSString* stringVertexFirstPoint = @"A1";
  NSString* stringVertexLastPoint = @"T19";
  GoPoint* pointCorner = [board pointAtVertex:stringVertexCorner];
  GoPoint* pointEdge = [board pointAtVertex:stringVertexEdge];
  GoPoint* pointCenter = [board pointAtVertex:stringVertexCenter];
  GoPoint* pointFirst = [board pointAtVertex:stringVertexFirstPoint];
  GoPoint* pointLast = [board pointAtVertex:stringVertexLastPoint];

  NSUInteger expectedNumberOfNeighboursCorner = 2;
  NSUInteger expectedNumberOfNeighboursEdge = 3;
  NSUInteger expectedNumberOfNeighboursCenter = 4;
  int expectedNumberOfPointsOnBoard = pow(expectedBoardSize, 2);

  XCTAssertEqual(expectedNumberOfNeighboursCorner, pointCorner.neighbours.count);
  XCTAssertNotNil(pointCorner.left);
  XCTAssertNil(pointCorner.right);
  XCTAssertNotNil(pointCorner.above);
  XCTAssertNil(pointCorner.below);
  XCTAssertNotNil(pointCorner.next);
  XCTAssertNotNil(pointCorner.previous);

  XCTAssertEqual(expectedNumberOfNeighboursEdge, pointEdge.neighbours.count);
  XCTAssertNil(pointEdge.left);
  XCTAssertNotNil(pointEdge.right);
  XCTAssertNotNil(pointEdge.above);
  XCTAssertNotNil(pointEdge.below);
  XCTAssertNotNil(pointEdge.next);
  XCTAssertNotNil(pointEdge.previous);

  XCTAssertEqual(expectedNumberOfNeighboursCenter, pointCenter.neighbours.count);
  XCTAssertNotNil(pointCenter.left);
  XCTAssertNotNil(pointCenter.right);
  XCTAssertNotNil(pointCenter.above);
  XCTAssertNotNil(pointCenter.below);
  XCTAssertNotNil(pointCenter.next);
  XCTAssertNotNil(pointCenter.previous);

  XCTAssertEqual(expectedNumberOfNeighboursCorner, pointFirst.neighbours.count);
  XCTAssertNil(pointFirst.previous);
  GoPoint* pointNext = pointFirst;
  int numberOfPointsNext = 1;
  while (true)
  {
    pointNext = pointNext.next;
    if (! pointNext)
      break;
    ++numberOfPointsNext;
    if (numberOfPointsNext > expectedNumberOfPointsOnBoard)
      break;
  }
  XCTAssertEqual(expectedNumberOfPointsOnBoard, numberOfPointsNext);

  XCTAssertEqual(expectedNumberOfNeighboursCorner, pointLast.neighbours.count);
  XCTAssertNil(pointLast.next);
  GoPoint* pointPrevious = pointLast;
  int numberOfPointsPrevious = 1;
  while (true)
  {
    pointPrevious = pointPrevious.previous;
    if (! pointPrevious)
      break;
    ++numberOfPointsPrevious;
    if (numberOfPointsPrevious > expectedNumberOfPointsOnBoard)
      break;
  }
  XCTAssertEqual(expectedNumberOfPointsOnBoard, numberOfPointsPrevious);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e starPoint property.
// -----------------------------------------------------------------------------
- (void) testStarPoint
{
  int expectedNumberOfStarPoints = 9;

  int numberOfStarPoints = 0;
  GoPoint* point = [m_game.board pointAtVertex:@"A1"];
  while (point)
  {
    if (point.isStarPoint)
      ++numberOfStarPoints;
    point = point.next;
  }
  XCTAssertEqual(expectedNumberOfStarPoints, numberOfStarPoints);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e stoneState property and those functions that
/// depend on it.
// -----------------------------------------------------------------------------
- (void) testStoneState
{
  GoPoint* point = [m_game.board pointAtVertex:@"F15"];
  XCTAssertEqual(GoColorNone, point.stoneState);
  XCTAssertFalse([point hasStone]);
  XCTAssertFalse([point blackStone]);

  point.stoneState = GoColorBlack;
  XCTAssertEqual(GoColorBlack, point.stoneState);
  XCTAssertTrue([point hasStone]);
  XCTAssertTrue([point blackStone]);

  point.stoneState = GoColorWhite;
  XCTAssertEqual(GoColorWhite, point.stoneState);
  XCTAssertTrue([point hasStone]);
  XCTAssertFalse([point blackStone]);

  point.stoneState = GoColorNone;
  XCTAssertEqual(GoColorNone, point.stoneState);
  XCTAssertFalse([point hasStone]);
  XCTAssertFalse([point blackStone]);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the liberties() method.
// -----------------------------------------------------------------------------
- (void) testLiberties
{
  GoBoard* board = m_game.board;
  NSString* stringVertexCorner = @"A19";
  NSString* stringVertexEdge = @"M1";
  NSString* stringVertexCenter = @"J4";
  GoPoint* pointCorner = [board pointAtVertex:stringVertexCorner];
  GoPoint* pointEdge = [board pointAtVertex:stringVertexEdge];
  GoPoint* pointCenter = [board pointAtVertex:stringVertexCenter];

  int expectedNumberOfLibertiesCorner = 2;
  int expectedNumberOfLibertiesEdge = 3;
  int expectedNumberOfLibertiesCenter = 4;
  int expectedNumberOfLibertiesNeighbour = 3;
  int expectedNumberOfLibertiesStoneGroup = 6;
  int expectedNumberOfLibertiesStoneGroupAttacked = 5;
  int expectedNumberOfLibertiesAttacker = 3;

  XCTAssertEqual(expectedNumberOfLibertiesCorner, [pointCorner liberties]);
  XCTAssertEqual(expectedNumberOfLibertiesEdge, [pointEdge liberties]);
  XCTAssertEqual(expectedNumberOfLibertiesCenter, [pointCenter liberties]);

  // Place a stone
  pointCenter.stoneState = GoColorBlack;
  [GoUtilities movePointToNewRegion:pointCenter];
  XCTAssertEqual(expectedNumberOfLibertiesCenter, [pointCenter liberties]);
  for (GoPoint* pointNeighbour in pointCenter.neighbours)
    XCTAssertEqual(expectedNumberOfLibertiesNeighbour, [pointNeighbour liberties]);

  // Add stone to group
  GoPoint* nextPoint = pointCenter.next;
  nextPoint.stoneState = GoColorBlack;
  [GoUtilities movePointToNewRegion:nextPoint];
  XCTAssertEqual(expectedNumberOfLibertiesStoneGroup, [pointCenter liberties]);
  XCTAssertEqual(expectedNumberOfLibertiesStoneGroup, [nextPoint liberties]);

  // Attack
  GoPoint* pointAttacker = pointCenter.previous;
  pointAttacker.stoneState = GoColorWhite;
  [GoUtilities movePointToNewRegion:pointAttacker];
  XCTAssertEqual(expectedNumberOfLibertiesStoneGroupAttacked, [pointCenter liberties]);
  XCTAssertEqual(expectedNumberOfLibertiesStoneGroupAttacked, [nextPoint liberties]);
  XCTAssertEqual(expectedNumberOfLibertiesAttacker, [pointAttacker liberties]);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isEqualToPoint() method.
// -----------------------------------------------------------------------------
- (void) testIsEqualToPoint
{
  NSString* stringVertex = @"O6";
  GoVertex* vertex = [GoVertex vertexFromString:stringVertex];
  GoBoard* board = m_game.board;
  GoPoint* pointFromBoard = [board pointAtVertex:stringVertex];

  XCTAssertTrue([pointFromBoard isEqualToPoint:pointFromBoard]);
  XCTAssertFalse([pointFromBoard isEqualToPoint:pointFromBoard.next]);

  GoPoint* point = [GoPoint pointAtVertex:vertex onBoard:board];
  XCTAssertNotNil(point);
  XCTAssertFalse(pointFromBoard == point);
  XCTAssertTrue([pointFromBoard isEqualToPoint:point]);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the neighbourRegionsWithColor() method.
// -----------------------------------------------------------------------------
- (void) testNeighbourRegionsWithColor
{
  GoBoard* board = m_game.board;
  GoPoint* point = [board pointAtVertex:@"B2"];
  GoBoardRegion* mainRegion = point.region;

  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:1
                         expectedNumberOfRegionsBlack:0
                         expectedNumberOfRegionsWhite:0];
  NSArray* neighbourRegionsEmpty = [point neighbourRegionsWithColor:GoColorNone];
  XCTAssertEqualObjects(mainRegion, [neighbourRegionsEmpty objectAtIndex:0]);
  [m_game play:point.left];
  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:1
                         expectedNumberOfRegionsBlack:1
                         expectedNumberOfRegionsWhite:0];
  [m_game play:point.right];
  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:1
                         expectedNumberOfRegionsBlack:1
                         expectedNumberOfRegionsWhite:1];
  [m_game play:point.above];
  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:1
                         expectedNumberOfRegionsBlack:2
                         expectedNumberOfRegionsWhite:1];
  [m_game play:point.below];
  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:0
                         expectedNumberOfRegionsBlack:2
                         expectedNumberOfRegionsWhite:2];
  [m_game play:point.left.above];
  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:0
                         expectedNumberOfRegionsBlack:1
                         expectedNumberOfRegionsWhite:2];
  [m_game play:point.right.below];
  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:0
                         expectedNumberOfRegionsBlack:1
                         expectedNumberOfRegionsWhite:1];
  point = point.left;
  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:2
                         expectedNumberOfRegionsBlack:1
                         expectedNumberOfRegionsWhite:0];
  NSArray* neighbourRegionsBlack = [point neighbourRegionsWithColor:GoColorBlack];
  XCTAssertEqualObjects(point.region, [neighbourRegionsBlack objectAtIndex:0]);
  point = point.right.right.below;
  [self verifyExpectedNumberOfNeighbourRegionsOfPoint:point
                         expectedNumberOfRegionsEmpty:1
                         expectedNumberOfRegionsBlack:0
                         expectedNumberOfRegionsWhite:1];
  NSArray* neighbourRegionsWhite = [point neighbourRegionsWithColor:GoColorWhite];
  XCTAssertEqualObjects(point.region, [neighbourRegionsWhite objectAtIndex:0]);

}

// -----------------------------------------------------------------------------
/// @brief Private helper method of testNeighbourRegionsWithColor().
// -----------------------------------------------------------------------------
- (void) verifyExpectedNumberOfNeighbourRegionsOfPoint:(GoPoint*)point
                          expectedNumberOfRegionsEmpty:(NSUInteger)expectedNumberOfRegionsEmpty
                          expectedNumberOfRegionsBlack:(NSUInteger)expectedNumberOfRegionsBlack
                          expectedNumberOfRegionsWhite:(NSUInteger)expectedNumberOfRegionsWhite
{
  NSArray* neighbourRegionsEmpty = [point neighbourRegionsWithColor:GoColorNone];
  XCTAssertEqual(neighbourRegionsEmpty.count, expectedNumberOfRegionsEmpty);
  NSArray* neighbourRegionsBlack = [point neighbourRegionsWithColor:GoColorBlack];
  XCTAssertEqual(neighbourRegionsBlack.count, expectedNumberOfRegionsBlack);
  NSArray* neighbourRegionsWhite = [point neighbourRegionsWithColor:GoColorWhite];
  XCTAssertEqual(neighbourRegionsWhite.count, expectedNumberOfRegionsWhite);
}

@end
