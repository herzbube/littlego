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
#import "GoBoardRegionTest.h"

// Application includes
#import <go/GoGame.h>
#import <go/GoBoard.h>
#import <go/GoBoardRegion.h>
#import <go/GoPoint.h>


@implementation GoBoardRegionTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the single GoBoardRegion object in
/// existence after a new GoGame has been created.
// -----------------------------------------------------------------------------
- (void) testNewGame
{
  int expectedBoardSize = 19;
  int expectedRegionSize = pow(expectedBoardSize, 2);
  NSUInteger expectedNumberOfPoints = expectedRegionSize;

  GoBoard* board = m_game.board;
  STAssertEquals(expectedBoardSize, board.size, nil);
  GoPoint* pointA1 = [board pointAtVertex:@"A1"];
  STAssertNotNil(pointA1, nil);
  GoBoardRegion* region = pointA1.region;
  STAssertNotNil(region, nil);

  STAssertEquals(expectedRegionSize, [region size], nil);
  STAssertFalse([region isStoneGroup], nil);
  STAssertNotNil(region.points, nil);
  STAssertEquals(expectedNumberOfPoints, region.points.count, nil);

  // All points must have a region, and it must be the same as the one for A1
  NSEnumerator* enumerator = [board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    STAssertEquals(region, point.region, nil);
  }
}

// -----------------------------------------------------------------------------
/// @brief Exercises the region() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testRegion
{
  NSUInteger expectedPointsCount = 0;
  NSUInteger expectedNumberOfAdjacentRegions = 0;

  GoBoardRegion* region = [GoBoardRegion region];
  STAssertNotNil(region.points, nil);
  STAssertEquals(expectedPointsCount, region.points.count, nil);
  STAssertEquals(0, [region size], nil);
  STAssertFalse([region isStoneGroup], nil);
  STAssertEquals(GoColorNone, [region color], nil);
  STAssertThrowsSpecificNamed([region liberties],
                              NSException, NSInternalInconsistencyException, @"region is not a stone group");
  STAssertNotNil([region adjacentRegions], nil);
  STAssertEquals(expectedNumberOfAdjacentRegions, [region adjacentRegions].count, nil);
  STAssertFalse(region.scoringMode, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the regionWithPoint() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testRegionWithPoint
{
  GoBoard* board = m_game.board;
  GoPoint* point = [board pointAtVertex:@"R17"];
  GoBoardRegion* mainRegion = point.region;
  int expectedBoardSize = 19;
  int expectedMainRegionSize = pow(expectedBoardSize, 2);
  STAssertEquals(expectedMainRegionSize, [mainRegion size], nil);

  int expectedRegionSize = 1;
  expectedMainRegionSize -= expectedRegionSize;

  GoBoardRegion* region = [GoBoardRegion regionWithPoint:point];
  STAssertNotNil(region.points, nil);
  STAssertEquals(expectedRegionSize, [region size], nil);
  STAssertEquals(region, point.region, nil);
  STAssertEquals(expectedMainRegionSize, [mainRegion size], nil);
  STAssertTrue(mainRegion != point.region, nil);

  STAssertThrowsSpecificNamed([GoBoardRegion regionWithPoint:nil],
                              NSException, NSInvalidArgumentException, @"point is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the addPoint:() method.
// -----------------------------------------------------------------------------
- (void) testAddPoint
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"F8"];
  GoPoint* point2 = [board pointAtVertex:@"F9"];
  GoPoint* point3 = [board pointAtVertex:@"M3"];
  GoBoardRegion* mainRegion = point1.region;
  int expectedBoardSize = 19;
  int expectedMainRegionSize = pow(expectedBoardSize, 2);
  STAssertEquals(expectedMainRegionSize, [mainRegion size], nil);
  NSUInteger expectedPointsCount = 0;

  GoBoardRegion* region = [GoBoardRegion region];
  STAssertNotNil(region.points, nil);
  STAssertEquals(expectedPointsCount, region.points.count, nil);
  STAssertEquals(0, [region size], nil);
  STAssertTrue(point1.region != region, nil);
  STAssertTrue(point2.region != region, nil);
  STAssertTrue(point3.region != region, nil);
  STAssertTrue(point1.region == mainRegion, nil);
  STAssertTrue(point2.region == mainRegion, nil);
  STAssertTrue(point3.region == mainRegion, nil);

  // Add first point
  expectedPointsCount = 1;
  [region addPoint:point1];
  STAssertEquals(expectedPointsCount, region.points.count, nil);
  STAssertEquals(1, [region size], nil);
  STAssertTrue(point1.region == region, nil);

  // Add second point that is a direct neighbour
  expectedPointsCount = 2;
  [region addPoint:point2];
  STAssertEquals(expectedPointsCount, region.points.count, nil);
  STAssertEquals(2, [region size], nil);
  STAssertTrue(point2.region == region, nil);


  // Add third point that is NOT a direct neighbour, and whose region reference
  // is nil
  expectedPointsCount = 3;
  point3.region = nil;
  [region addPoint:point3];
  STAssertEquals(expectedPointsCount, region.points.count, nil);
  STAssertEquals(3, [region size], nil);
  STAssertTrue(point3.region == region, nil);

  STAssertThrowsSpecificNamed([region addPoint:nil],
                              NSException, NSInvalidArgumentException, @"point is nil");
  // Add point that has already been added with addPoint:()
  STAssertThrowsSpecificNamed([region addPoint:point3],
                              NSException, NSInvalidArgumentException, @"point has already been added");
  // Add point that has NOT been added with addPoint:(), but whose region
  // reference we sneakily changed behind the back of GoBoardRegion (we do this
  // just for the sake of this test's completeness - not because this is
  // something that should be done in production code).
  GoPoint* point4 = [board pointAtVertex:@"L11"];
  point4.region = region;
  STAssertThrowsSpecificNamed([region addPoint:point3],
                              NSException, NSInvalidArgumentException, @"region reference already updated");
  // Add points with different stoneState property values
  GoPoint* point5 = [board pointAtVertex:@"N7"];
  point5.stoneState = GoColorBlack;
  STAssertThrowsSpecificNamed([region addPoint:point5],
                              NSException, NSInvalidArgumentException, @"stone state does not match 1");
  point5.stoneState = GoColorWhite;
  STAssertThrowsSpecificNamed([region addPoint:point5],
                              NSException, NSInvalidArgumentException, @"stone state does not match 2");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removePoint:() method.
// -----------------------------------------------------------------------------
- (void) testRemovePoint
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"Q17"];
  GoBoardRegion* mainRegion = point1.region;
  int expectedBoardSize = 19;
  int expectedMainRegionSize = pow(expectedBoardSize, 2);
  NSUInteger expectedMainRegionPointsCount = expectedMainRegionSize;
  STAssertEquals(expectedMainRegionSize, [mainRegion size], nil);
  STAssertEquals(expectedMainRegionPointsCount, mainRegion.points.count, nil);
  STAssertTrue(point1.region == mainRegion, nil);

  expectedMainRegionSize -= 1;
  expectedMainRegionPointsCount -= 1;
  [mainRegion removePoint:point1];
  STAssertEquals(expectedMainRegionSize, [mainRegion size], nil);
  STAssertEquals(expectedMainRegionPointsCount, mainRegion.points.count, nil);
  STAssertNil(point1.region, nil);

  STAssertThrowsSpecificNamed([mainRegion removePoint:nil],
                              NSException, NSInvalidArgumentException, @"point is nil");
  // Remove point that has already been removed with removePoint:()
  STAssertThrowsSpecificNamed([mainRegion removePoint:point1],
                              NSException, NSInvalidArgumentException, @"point has already been removed");
  // Remove point that has already been removed by adding it to another region
  GoPoint* point2 = [board pointAtVertex:@"B12"];
  GoBoardRegion* region = [GoBoardRegion regionWithPoint:point2];
  STAssertThrowsSpecificNamed([mainRegion removePoint:point2],
                              NSException, NSInvalidArgumentException, @"point has already been moved");
  // Remove point that has NOT been removed with removePoint:(), but whose
  // region reference we sneakily changed behind the back of GoBoardRegion (we
  // do this just for the sake of this test's completeness - not because this is
  // something that should be done in production code).
  GoPoint* point3 = [board pointAtVertex:@"K4"];
  point3.region = nil;
  STAssertThrowsSpecificNamed([region removePoint:point3],
                              NSException, NSInvalidArgumentException, @"region reference already updated");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the joinRegion:() method.
// -----------------------------------------------------------------------------
- (void) testJoinRegion
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"D10"];
  GoPoint* point2 = [board pointAtVertex:@"G2"];
  GoBoardRegion* mainRegion = point1.region;
  int expectedBoardSize = 19;
  int expectedMainRegionSize = pow(expectedBoardSize, 2);
  STAssertEquals(expectedMainRegionSize, [mainRegion size], nil);

  expectedMainRegionSize -= 2;
  GoBoardRegion* region1 = [GoBoardRegion regionWithPoint:point1];
  GoBoardRegion* region2 = [GoBoardRegion regionWithPoint:point2];
  GoBoardRegion* regionEmpty = [GoBoardRegion region];
  STAssertEquals(expectedMainRegionSize, [mainRegion size], nil);
  STAssertEquals(1, [region1 size], nil);
  STAssertEquals(1, [region2 size], nil);
  STAssertEquals(0, [regionEmpty size], nil);
  STAssertTrue(point1.region == region1, nil);
  STAssertTrue(point2.region == region2, nil);

  // Move region2 points to region1
  [region1 joinRegion:region2];
  STAssertEquals(2, [region1 size], nil);
  STAssertEquals(0, [region2 size], nil);
  STAssertTrue(point1.region == region1, nil);
  STAssertTrue(point2.region == region1, nil);

  // Joining an empty region is possible, although it does nothing
  [region1 joinRegion:regionEmpty];
  STAssertEquals(2, [region1 size], nil);

  // Joining an empty region with another empty region is silly but possible
  [region2 joinRegion:regionEmpty];

  // Moving points into an empty region
  [region2 joinRegion:region1];
  STAssertEquals(0, [region1 size], nil);
  STAssertEquals(2, [region2 size], nil);
  STAssertTrue(point1.region == region2, nil);
  STAssertTrue(point2.region == region2, nil);

  STAssertThrowsSpecificNamed([region2 joinRegion:nil],
                              NSException, NSInvalidArgumentException, @"region is nil");
  STAssertThrowsSpecificNamed([region2 joinRegion:region2],
                              NSException, NSInvalidArgumentException, @"join with itself");
  // Join regions whose points have different stoneState property values
  GoPoint* point3 = [board pointAtVertex:@"C5"];
  point3.stoneState = GoColorBlack;
  [region1 addPoint:point3];
  STAssertThrowsSpecificNamed([region2 joinRegion:region1],
                              NSException, NSInvalidArgumentException, @"stone state does not match 1");
  point3.stoneState = GoColorWhite;
  STAssertThrowsSpecificNamed([region2 joinRegion:region1],
                              NSException, NSInvalidArgumentException, @"stone state does not match 1");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isStoneGroup() method.
// -----------------------------------------------------------------------------
- (void) testIsStoneGroup
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"K10"];
  GoBoardRegion* mainRegion = point1.region;

  STAssertFalse([mainRegion isStoneGroup], nil);
  GoBoardRegion* region1 = [GoBoardRegion regionWithPoint:point1];
  STAssertFalse([region1 isStoneGroup], nil);
  point1.stoneState = GoColorBlack;
  STAssertTrue([region1 isStoneGroup], nil);
  point1.stoneState = GoColorNone;
  STAssertFalse([region1 isStoneGroup], nil);
  point1.stoneState = GoColorWhite;
  STAssertTrue([region1 isStoneGroup], nil);
  GoBoardRegion* regionEmpty = [GoBoardRegion region];
  STAssertFalse([regionEmpty isStoneGroup], nil);

  // We don't test nasty things like regions that contain points with different
  // stone states because isStoneGroup() won't catch those 
}

// -----------------------------------------------------------------------------
/// @brief Exercises the color() method.
// -----------------------------------------------------------------------------
- (void) testColor
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"K10"];
  GoBoardRegion* mainRegion = point1.region;

  STAssertEquals(GoColorNone, [mainRegion color], nil);
  GoBoardRegion* region1 = [GoBoardRegion regionWithPoint:point1];
  STAssertEquals(GoColorNone, [region1 color], nil);
  point1.stoneState = GoColorBlack;
  STAssertEquals(GoColorBlack, [region1 color], nil);
  point1.stoneState = GoColorNone;
  STAssertEquals(GoColorNone, [region1 color], nil);
  point1.stoneState = GoColorWhite;
  STAssertEquals(GoColorWhite, [region1 color], nil);
  GoBoardRegion* regionEmpty = [GoBoardRegion region];
  STAssertEquals(GoColorNone, [regionEmpty color], nil);

  // We don't test nasty things like regions that contain points with different
  // stone states because color() won't catch those 
}

// -----------------------------------------------------------------------------
/// @brief Exercises the liberties() method.
// -----------------------------------------------------------------------------
- (void) testLiberties
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"T19"];
  GoPoint* point2 = [board pointAtVertex:@"S19"];
  GoPoint* point3 = [board pointAtVertex:@"S18"];
  GoPoint* point4 = [board pointAtVertex:@"S17"];
  GoPoint* point5 = [board pointAtVertex:@"T17"];
  GoPoint* point6 = [board pointAtVertex:@"R19"];  // white placing adjacent stone
  GoPoint* point7 = [board pointAtVertex:@"T18"];  // white filling an eye
  GoBoardRegion* mainRegion = point1.region;

  // Build up black's formation stone by stone
  point1.stoneState = GoColorBlack;
  GoBoardRegion* region1 = [GoBoardRegion regionWithPoint:point1];
  STAssertEquals(2, [region1 liberties], nil);
  point2.stoneState = GoColorBlack;
  [region1 addPoint:point2];
  STAssertEquals(3, [region1 liberties], nil);
  point3.stoneState = GoColorBlack;
  [region1 addPoint:point3];
  STAssertEquals(4, [region1 liberties], nil);
  point4.stoneState = GoColorBlack;
  [region1 addPoint:point4];
  STAssertEquals(6, [region1 liberties], nil);
  point5.stoneState = GoColorBlack;
  [region1 addPoint:point5];
  STAssertEquals(6, [region1 liberties], nil);

  // White places an adjacent stone
  point6.stoneState = GoColorWhite;
  GoBoardRegion* region2 = [GoBoardRegion regionWithPoint:point6];
  STAssertEquals(2, [region2 liberties], nil);
  STAssertEquals(5, [region1 liberties], nil);

  // White fills an eye - this is suicide but at this level there are no checks
  // that prevent this
  point7.stoneState = GoColorWhite;
  GoBoardRegion* region3 = [GoBoardRegion regionWithPoint:point7];
  STAssertEquals(0, [region3 liberties], nil);
  STAssertEquals(4, [region1 liberties], nil);

  STAssertThrowsSpecificNamed([mainRegion liberties],
                              NSException, NSInternalInconsistencyException, @"region is no stone group");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the adjacentRegions() method.
// -----------------------------------------------------------------------------
- (void) testAdjacentRegions
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"A18"];
  GoPoint* point2 = [board pointAtVertex:@"B19"];
  GoPoint* point3 = [board pointAtVertex:@"A19"];
  GoBoardRegion* mainRegion = point1.region;

  NSUInteger expectedNumberOfAdjacentRegions = 0;
  NSArray* adjacentRegions = [mainRegion adjacentRegions];
  STAssertNotNil(adjacentRegions, nil);
  STAssertEquals(expectedNumberOfAdjacentRegions, adjacentRegions.count, nil);

  expectedNumberOfAdjacentRegions = 1;
  point1.stoneState = GoColorWhite;
  GoBoardRegion* region1 = [GoBoardRegion regionWithPoint:point1];
  adjacentRegions = [region1 adjacentRegions];
  STAssertEquals(expectedNumberOfAdjacentRegions, adjacentRegions.count, nil);
  STAssertTrue([adjacentRegions containsObject:mainRegion], nil);

  expectedNumberOfAdjacentRegions = 2;
  point2.stoneState = GoColorWhite;
  GoBoardRegion* region2 = [GoBoardRegion regionWithPoint:point2];
  GoBoardRegion* region3 = point3.region;
  STAssertNotNil(region3, nil);
  STAssertTrue(region3 != mainRegion, nil);
  STAssertTrue(region3 != region1, nil);
  STAssertTrue(region3 != region2, nil);
  adjacentRegions = [region2 adjacentRegions];
  STAssertEquals(expectedNumberOfAdjacentRegions, adjacentRegions.count, nil);
  STAssertTrue([adjacentRegions containsObject:mainRegion], nil);
  STAssertTrue([adjacentRegions containsObject:region3], nil);

  adjacentRegions = [region1 adjacentRegions];
  STAssertEquals(expectedNumberOfAdjacentRegions, adjacentRegions.count, nil);
  STAssertTrue([adjacentRegions containsObject:mainRegion], nil);
  STAssertTrue([adjacentRegions containsObject:region3], nil);

  adjacentRegions = [region3 adjacentRegions];
  STAssertEquals(expectedNumberOfAdjacentRegions, adjacentRegions.count, nil);
  STAssertTrue([adjacentRegions containsObject:region1], nil);
  STAssertTrue([adjacentRegions containsObject:region2], nil);

  // Removing the point makes its region empty; an empty region should simply
  // have no adjacent regions.
  point1.stoneState = GoColorNone;
  [region1 removePoint:point1];
  expectedNumberOfAdjacentRegions = 0;
  adjacentRegions = [region1 adjacentRegions];
  STAssertEquals(expectedNumberOfAdjacentRegions, adjacentRegions.count, nil);

  // Removing the point above did cause regions to be joinend, so region 2
  // still has two adjacent regions
  expectedNumberOfAdjacentRegions = 2;
  adjacentRegions = [region2 adjacentRegions];
  STAssertEquals(expectedNumberOfAdjacentRegions, adjacentRegions.count, nil);

  // point1 is still "in limbo" - it does not have a region reference, and
  // there is no region that has it as a member. So here the adjacent regions
  // calculation finds that 1) point1 is adjacent to the region, but 2) it has
  // a nil reference in its region property. Currently we expect that this
  // does not cause an error, and that the nil region is simply not counted.
  // However, it would also be OK if a future implementation wants to change
  // this and treat this as an error.
  expectedNumberOfAdjacentRegions = 1;
  adjacentRegions = [region3 adjacentRegions];
  STAssertEquals(expectedNumberOfAdjacentRegions, adjacentRegions.count, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e scoringMode property.
// -----------------------------------------------------------------------------
- (void) testScoringMode
{
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"F7"];
  GoPoint* point2 = [board pointAtVertex:@"F8"];
  GoPoint* point3 = [board pointAtVertex:@"F6"];

  NSUInteger expectedNumberOfAdjacentRegions = 1;

  point1.stoneState = GoColorWhite;
  GoBoardRegion* region1 = [GoBoardRegion regionWithPoint:point1];
  region1.scoringMode = true;
  STAssertEquals(1, [region1 size], nil);
  STAssertTrue([region1 isStoneGroup], nil);
  STAssertEquals(GoColorWhite, [region1 color], nil);
  STAssertEquals(4, [region1 liberties], nil);
  STAssertEquals(expectedNumberOfAdjacentRegions, [region1 adjacentRegions].count, nil);

  // Changes number of adjacent regions
  point2.stoneState = GoColorWhite;
  GoBoardRegion* region2 = [GoBoardRegion regionWithPoint:point2];
  STAssertEquals(1, [region2 size], nil);
  // Changes size, color and isStoneGroup, in addition liberties should now
  // throw an exception
  point1.stoneState = GoColorNone;
  point3.stoneState = GoColorNone;
  [region1 addPoint:point3];

  // Now check: Everything must still be the same, and we don't want an
  // exception
  STAssertEquals(1, [region1 size], nil);
  STAssertTrue([region1 isStoneGroup], nil);
  STAssertEquals(GoColorWhite, [region1 color], nil);
  STAssertNoThrow([region1 liberties], nil);
  STAssertEquals(4, [region1 liberties], nil);
  STAssertEquals(expectedNumberOfAdjacentRegions, [region1 adjacentRegions].count, nil);

  // Turning off scoring mode gets us the updated values
  expectedNumberOfAdjacentRegions = 2;
  region1.scoringMode = false;
  STAssertEquals(2, [region1 size], nil);
  STAssertFalse([region1 isStoneGroup], nil);
  STAssertEquals(GoColorNone, [region1 color], nil);
  STAssertThrowsSpecificNamed([region1 liberties],
                              NSException, NSInternalInconsistencyException, @"region is no stone group");
  STAssertEquals(expectedNumberOfAdjacentRegions, [region1 adjacentRegions].count, nil);
}

// -----------------------------------------------------------------------------
/// @brief Performs tests regarding deallocation of GoBoardRegion objects when
/// the last GoPoint object loses its reference to a GoBoardRegion.
///
/// We test the following scenarios:
/// - GoBoardRegion::addPoint:() deallocates the GoPoint's old GoBoardRegion
/// - Ditto for GoBoardRegion::regionWithPoints:()
/// - Ditto for GoBoardRegion::regionWithPoint:()
/// - GoBoardRegion::removePoint:() deallocates the GoBoardRegion that performs
///   the remove operation
/// - GoBoardRegion::joinRegion:() deallocates the GoBoardRegion passed as an
///   argument.
// -----------------------------------------------------------------------------
- (void) testDeallocation
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  GoBoard* board = m_game.board;
  GoPoint* point1 = [board pointAtVertex:@"J14"];
  GoPoint* point2 = [board pointAtVertex:@"J15"];
  point1.stoneState = GoColorBlack;
  point2.stoneState = GoColorBlack;
  GoBoardRegion* region1 = [GoBoardRegion regionWithPoint:point1];
  GoBoardRegion* region2 = [GoBoardRegion regionWithPoint:point2];
  STAssertEquals(region1, point1.region, nil);
  STAssertEquals(region2, point2.region, nil);
  [pool drain];

  // Test 1: Excercise GoBoardRegion::addPoint:(). This causes region1 to be
  // deallocated. At this point the only thing that keeps region1 alive is the
  // reference by point1.region. We are now going to destroy this balance...
  pool = [[NSAutoreleasePool alloc] init];
  [region2 addPoint:point1];
  [pool drain];
  // If code execution makes it to here then we can be sure that a single
  // GoBoardRegion::addPoint:() operation is not dangerous. Unfortunately there
  // is no way to observe object deallocation, so we have no choice but to
  // assume that region1 was properly deallocated.

  // Just a final, simple check, but still wrap it with an NSAutoReleasePool
  // to make sure that no uncontrolled autorelease messages are interfering
  // with the remainder of test execution.
  pool = [[NSAutoreleasePool alloc] init];
  STAssertEquals(region2, point1.region, nil);
  [pool drain];

  // Test 2: Excercise GoBoardRegion::regionWithPoint:(). This causes region3
  // to be deallocated.
  pool = [[NSAutoreleasePool alloc] init];
  GoBoardRegion* region4 = [GoBoardRegion regionWithPoint:point1];
  [pool drain];
  pool = [[NSAutoreleasePool alloc] init];
  GoBoardRegion* region5 = [GoBoardRegion regionWithPoint:point2];
  [pool drain];
  pool = [[NSAutoreleasePool alloc] init];
  STAssertEquals(region4, point1.region, nil);
  STAssertEquals(region5, point2.region, nil);
  [pool drain];

  // Test 3: Excercise GoBoardRegion::removePoint:(). This causes region4 to be
  // deallocated.
  pool = [[NSAutoreleasePool alloc] init];
  [region4 removePoint:point1];
  [pool drain];
  pool = [[NSAutoreleasePool alloc] init];
  STAssertNil(point1.region, nil);
  GoBoardRegion* region6 = [GoBoardRegion regionWithPoint:point1];
  STAssertEquals(region6, point1.region, nil);
  [pool drain];

  // Test 4: Excercise GoBoardRegion::joinRegion:(). This causes region5 to be
  // deallocated.
  pool = [[NSAutoreleasePool alloc] init];
  [region6 joinRegion:region5];
  [pool drain];
  pool = [[NSAutoreleasePool alloc] init];
  STAssertEquals(region6, point1.region, nil);
  STAssertEquals(region6, point2.region, nil);
  [pool drain];
}

@end
