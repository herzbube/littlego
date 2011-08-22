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
#import "GoBoardTest.h"

// Application includes
#import <go/GoGame.h>
#import <go/GoBoard.h>


@implementation GoBoardTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of a GoBoard object after it has been
/// created by GoGame.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  enum GoBoardSize expectedBoardSize = BoardSize19;
  int expectedBoardDimensions = 19;

  GoBoard* board = m_game.board;
  STAssertNotNil(board, nil);
  STAssertEquals(expectedBoardSize, board.size, nil);
  STAssertEquals(expectedBoardDimensions, board.dimensions, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pointEnumerator() method.
// -----------------------------------------------------------------------------
- (void) testPointEnumerator
{
  int expectedBoardDimensions = 19;
  int expectedNumberOfPoints = pow(expectedBoardDimensions, 2);

  int numberOfPoints = 0;
  NSEnumerator* enumerator = [m_game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    ++numberOfPoints;
    if (numberOfPoints > expectedNumberOfPoints)
      break;
  }
  STAssertEquals(expectedNumberOfPoints, numberOfPoints, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pointAtVertex:() method.
// -----------------------------------------------------------------------------
- (void) testPointAtVertex
{
  GoBoard* board = m_game.board;
  GoPoint* point;

  // A few valid vertexes
  point = [board pointAtVertex:@"A1"];
  STAssertNotNil(point, @"A1");
  point = [board pointAtVertex:@"F7"];
  STAssertNotNil(point, @"F7");
  point = [board pointAtVertex:@"R13"];
  STAssertNotNil(point, @"R13");
  point = [board pointAtVertex:@"T19"];
  STAssertNotNil(point, @"T19");

  // A few invalid vertexes
  STAssertThrowsSpecificNamed([board pointAtVertex:@"I4"],
                              NSException, NSRangeException, @"letter I used for vertex");
  STAssertThrowsSpecificNamed([board pointAtVertex:@"U1"],
                              NSException, NSRangeException, @"letter U used for vertex");
  STAssertThrowsSpecificNamed([board pointAtVertex:@"A0"],
                              NSException, NSRangeException, @"number 0 used for vertex");
  STAssertThrowsSpecificNamed([board pointAtVertex:nil],
                              NSException, NSInvalidArgumentException, @"nil used for vertex");
  STAssertThrowsSpecificNamed([board pointAtVertex:@""],
                              NSException, NSInvalidArgumentException, @"empty string used for vertex");
  STAssertThrowsSpecificNamed([board pointAtVertex:@"foobar"],
                              NSException, NSInvalidArgumentException, @"malformed string used for vertex");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the neighbourOf:inDirection() method.
// -----------------------------------------------------------------------------
- (void) testNeighbourOfInDirection
{
  int expectedBoardDimensions = 19;
  GoBoard* board = m_game.board;
  STAssertEquals(expectedBoardDimensions, board.dimensions, nil);

  enum GoBoardDirection direction = LeftDirection;
  for (; direction <= PreviousDirection; ++direction)
  {
    int expectedNumberOfPoints = pow(expectedBoardDimensions, 2);
    NSString* initialVertex;
    switch (direction)
    {
      case LeftDirection:
        expectedNumberOfPoints = expectedBoardDimensions;
        initialVertex = @"T8";
        break;
      case RightDirection:
        expectedNumberOfPoints = expectedBoardDimensions;
        initialVertex = @"A14";
        break;
      case UpDirection:
        expectedNumberOfPoints = expectedBoardDimensions;
        initialVertex = @"Q1";
        break;
      case DownDirection:
        expectedNumberOfPoints = expectedBoardDimensions;
        initialVertex = @"J19";
        break;
      case NextDirection:
        expectedNumberOfPoints = pow(expectedBoardDimensions, 2);
        initialVertex = @"A1";
        break;
      case PreviousDirection:
        expectedNumberOfPoints = pow(expectedBoardDimensions, 2);
        initialVertex = @"T19";
        break;
      default:
        STFail(nil);
        return;
    }
    GoPoint* point = [board pointAtVertex:initialVertex];
    STAssertNotNil(point, initialVertex);
    int numberOfPoints = 1;
    while (true)
    {
      point = [board neighbourOf:point inDirection:direction];
      if (! point)
        break;
      ++numberOfPoints;
      if (numberOfPoints > expectedNumberOfPoints)
        break;
    }
    STAssertEquals(expectedNumberOfPoints, numberOfPoints, initialVertex);
  }
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e starPoints property.
// -----------------------------------------------------------------------------
- (void) testStarPoints
{
  NSUInteger expectedNumberOfStarPoints = 9;

  // Star points are mostly a GUI feature, so we don't do more than a few
  // rudimentary tests here
  NSArray* starPoints = m_game.board.starPoints;
  STAssertNotNil(starPoints, nil);
  STAssertEquals(expectedNumberOfStarPoints, [starPoints count], nil);
}

@end
