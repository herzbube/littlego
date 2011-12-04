// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
  int expectedBoardDimensions = 19;
  int expectedRegionSize = pow(expectedBoardDimensions, 2);
  NSUInteger expectedNumberOfPoints = expectedRegionSize;
  
  GoBoard* board = m_game.board;
  STAssertEquals(expectedBoardDimensions, board.dimensions, nil);
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
    STAssertTrue([region hasPoint:point], nil);
  }
}

// -----------------------------------------------------------------------------
/// @brief Exercises the regionWithPoints:() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testNewRegionWithPoints;
{
  GoBoard* board = m_game.board;
  GoPoint* pointA1 = [board pointAtVertex:@"A1"];
  GoPoint* pointF9 = [board pointAtVertex:@"F9"];
  GoPoint* pointK13 = [board pointAtVertex:@"K13"];

  NSMutableArray* inputArray = [NSMutableArray arrayWithObjects:pointA1, pointF9, pointK13, nil];
  NSArray* expectedArray = [inputArray copy];
  int expectedRegionSize = inputArray.count;

  GoBoardRegion* region = [GoBoardRegion regionWithPoints:inputArray];
  // Changing inputArray now must not have any influence on the region's
  // content, i.e. we expect that GoBoardRegion made a copy of inputArray
  [inputArray addObject:[board pointAtVertex:@"S17"]];
  
  STAssertNotNil(region.points, nil);
  STAssertEquals(expectedRegionSize, [region size], nil);
  STAssertTrue([expectedArray isEqualToArray:region.points], nil);
}

@end
