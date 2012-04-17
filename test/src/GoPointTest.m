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
#import "GoPointTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoGame.h>
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
  STAssertNotNil(point, nil);
  STAssertFalse([point hasStone], nil);
  STAssertFalse([point blackStone], nil);
  STAssertEquals(expectedLiberties, [point liberties], nil);
  STAssertTrue([point isEqualToPoint:point], nil);
  STAssertTrue([point.vertex.string isEqualToString:stringVertex], nil);
  STAssertEquals(board, point.board, nil);
  STAssertNotNil(point.left, nil);
  STAssertNotNil(point.right, nil);
  STAssertNotNil(point.above, nil);
  STAssertNotNil(point.below, nil);
  STAssertEquals(expectedNumberOfNeighbours, point.neighbours.count, nil);
  STAssertNotNil(point.next, nil);
  STAssertNotNil(point.previous, nil);
  STAssertFalse(point.isStarPoint, nil);
  STAssertEquals(expectedStoneState, point.stoneState, nil);
  STAssertNotNil(point.region, nil);
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
  STAssertNotNil(point, nil);
  STAssertEquals(board, point.board, nil);
  STAssertTrue([stringVertex isEqualToString:point.vertex.string], nil);
  // Don't test any more attributes, testInitialState() already checked those

  STAssertThrowsSpecificNamed([GoPoint pointAtVertex:vertex onBoard:nil],
                              NSException, NSInvalidArgumentException, @"test 1");
  STAssertThrowsSpecificNamed([GoPoint pointAtVertex:nil onBoard:board],
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
  STAssertEquals(expectedBoardSize, board.size, nil);

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

  STAssertEquals(expectedNumberOfNeighboursCorner, pointCorner.neighbours.count, nil);
  STAssertNotNil(pointCorner.left, nil);
  STAssertNil(pointCorner.right, nil);
  STAssertNotNil(pointCorner.above, nil);
  STAssertNil(pointCorner.below, nil);
  STAssertNotNil(pointCorner.next, nil);
  STAssertNotNil(pointCorner.previous, nil);

  STAssertEquals(expectedNumberOfNeighboursEdge, pointEdge.neighbours.count, nil);
  STAssertNil(pointEdge.left, nil);
  STAssertNotNil(pointEdge.right, nil);
  STAssertNotNil(pointEdge.above, nil);
  STAssertNotNil(pointEdge.below, nil);
  STAssertNotNil(pointEdge.next, nil);
  STAssertNotNil(pointEdge.previous, nil);

  STAssertEquals(expectedNumberOfNeighboursCenter, pointCenter.neighbours.count, nil);
  STAssertNotNil(pointCenter.left, nil);
  STAssertNotNil(pointCenter.right, nil);
  STAssertNotNil(pointCenter.above, nil);
  STAssertNotNil(pointCenter.below, nil);
  STAssertNotNil(pointCenter.next, nil);
  STAssertNotNil(pointCenter.previous, nil);

  STAssertEquals(expectedNumberOfNeighboursCorner, pointFirst.neighbours.count, nil);
  STAssertNil(pointFirst.previous, nil);
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
  STAssertEquals(expectedNumberOfPointsOnBoard, numberOfPointsNext, nil);

  STAssertEquals(expectedNumberOfNeighboursCorner, pointLast.neighbours.count, nil);
  STAssertNil(pointLast.next, nil);
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
  STAssertEquals(expectedNumberOfPointsOnBoard, numberOfPointsPrevious, nil);
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
  STAssertEquals(expectedNumberOfStarPoints, numberOfStarPoints, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e stoneState property and those functions that
/// depend on it.
// -----------------------------------------------------------------------------
- (void) testStoneState
{
  GoPoint* point = [m_game.board pointAtVertex:@"F15"];
  STAssertEquals(GoColorNone, point.stoneState, nil);
  STAssertFalse([point hasStone], nil);
  STAssertFalse([point blackStone], nil);

  point.stoneState = GoColorBlack;
  STAssertEquals(GoColorBlack, point.stoneState, nil);
  STAssertTrue([point hasStone], nil);
  STAssertTrue([point blackStone], nil);

  point.stoneState = GoColorWhite;
  STAssertEquals(GoColorWhite, point.stoneState, nil);
  STAssertTrue([point hasStone], nil);
  STAssertFalse([point blackStone], nil);

  point.stoneState = GoColorNone;
  STAssertEquals(GoColorNone, point.stoneState, nil);
  STAssertFalse([point hasStone], nil);
  STAssertFalse([point blackStone], nil);
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

  STAssertEquals(expectedNumberOfLibertiesCorner, [pointCorner liberties], nil);
  STAssertEquals(expectedNumberOfLibertiesEdge, [pointEdge liberties], nil);
  STAssertEquals(expectedNumberOfLibertiesCenter, [pointCenter liberties], nil);

  // Place a stone
  pointCenter.stoneState = GoColorBlack;
  [GoUtilities movePointToNewRegion:pointCenter];
  STAssertEquals(expectedNumberOfLibertiesCenter, [pointCenter liberties], nil);
  for (GoPoint* pointNeighbour in pointCenter.neighbours)
    STAssertEquals(expectedNumberOfLibertiesNeighbour, [pointNeighbour liberties], nil);

  // Add stone to group
  GoPoint* nextPoint = pointCenter.next;
  nextPoint.stoneState = GoColorBlack;
  [GoUtilities movePointToNewRegion:nextPoint];
  STAssertEquals(expectedNumberOfLibertiesStoneGroup, [pointCenter liberties], nil);
  STAssertEquals(expectedNumberOfLibertiesStoneGroup, [nextPoint liberties], nil);

  // Attack
  GoPoint* pointAttacker = pointCenter.previous;
  pointAttacker.stoneState = GoColorWhite;
  [GoUtilities movePointToNewRegion:pointAttacker];
  STAssertEquals(expectedNumberOfLibertiesStoneGroupAttacked, [pointCenter liberties], nil);
  STAssertEquals(expectedNumberOfLibertiesStoneGroupAttacked, [nextPoint liberties], nil);
  STAssertEquals(expectedNumberOfLibertiesAttacker, [pointAttacker liberties], nil);
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

  STAssertTrue([pointFromBoard isEqualToPoint:pointFromBoard], nil);
  STAssertFalse([pointFromBoard isEqualToPoint:pointFromBoard.next], nil);

  GoPoint* point = [GoPoint pointAtVertex:vertex onBoard:board];
  STAssertNotNil(point, nil);
  STAssertFalse(pointFromBoard == point, nil);
  STAssertTrue([pointFromBoard isEqualToPoint:point], nil);
}

@end
