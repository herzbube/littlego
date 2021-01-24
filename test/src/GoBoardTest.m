// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import <go/GoPoint.h>
#import <go/GoVertex.h>
#import <main/ApplicationDelegate.h>
#import <newgame/NewGameModel.h>
#import <command/game/NewGameCommand.h>


@implementation GoBoardTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of a GoBoard object after after a new GoGame
/// has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  enum GoBoardSize expectedBoardSize = GoBoardSize19;
  [self checkBoardState:m_game.board expectedBoardSize:expectedBoardSize];
  XCTAssertNotNil(m_game.board.zobristTable);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the boardWithDefaultSize() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testBoardWithDefaultSize
{
  enum GoBoardSize expectedBoardSize = GoBoardSize13;

  NewGameModel* newGameModel = m_delegate.theNewGameModel;
  newGameModel.boardSize = expectedBoardSize;
  GoBoard* board = [GoBoard boardWithDefaultSize];

  [self checkBoardState:board expectedBoardSize:expectedBoardSize];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the boardWithSize:() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testBoardWithSize
{
  enum GoBoardSize expectedBoardSize = GoBoardSize9;
  GoBoard* board = [GoBoard boardWithSize:expectedBoardSize];
  [self checkBoardState:board expectedBoardSize:expectedBoardSize];

  XCTAssertThrowsSpecificNamed([GoBoard boardWithSize:GoBoardSizeUndefined],
                              NSException, NSInvalidArgumentException, @"GoBoardSizeUndefined");
  XCTAssertThrowsSpecificNamed([GoBoard boardWithSize:(enum GoBoardSize)42],
                              NSException, NSInvalidArgumentException, @"evil cast");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the stringForSize:() class method.
// -----------------------------------------------------------------------------
- (void) testStringForSize
{
  static const int numberOfBoardSizes = (GoBoardSizeMax - GoBoardSizeMin) / 2 + 1;
  static const int arraySize = numberOfBoardSizes + 1;
  static const int boardSizes[arraySize] = {GoBoardSize7, GoBoardSize9, GoBoardSize11, GoBoardSize13, GoBoardSize15, GoBoardSize17, GoBoardSize19, GoBoardSizeUndefined};
  static NSString* expectedBoardSizeStrings[arraySize] = {@"7", @"9", @"11", @"13", @"15", @"17", @"19", @"Undefined"};

  for (int index = 0; index < arraySize; ++index)
    XCTAssertTrue([expectedBoardSizeStrings[index] isEqualToString:[GoBoard stringForSize:boardSizes[index]]], @"%@", expectedBoardSizeStrings[index]);

  XCTAssertThrowsSpecificNamed([GoBoard stringForSize:(enum GoBoardSize)42],
                              NSException, NSInvalidArgumentException, @"evil cast");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pointEnumerator() method.
// -----------------------------------------------------------------------------
- (void) testPointEnumerator
{
  int expectedBoardSize = 19;
  int expectedNumberOfPoints = pow(expectedBoardSize, 2);

  int numberOfPoints = 0;
  NSEnumerator* enumerator = [m_game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    ++numberOfPoints;
    if (numberOfPoints > expectedNumberOfPoints)
      break;
  }
  XCTAssertEqual(expectedNumberOfPoints, numberOfPoints);
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
  XCTAssertNotNil(point, @"A1");
  point = [board pointAtVertex:@"F7"];
  XCTAssertNotNil(point, @"F7");
  point = [board pointAtVertex:@"R13"];
  XCTAssertNotNil(point, @"R13");
  point = [board pointAtVertex:@"T19"];
  XCTAssertNotNil(point, @"T19");

  // A lower-case string must also work
  point = [board pointAtVertex:@"c3"];
  XCTAssertNotNil(point, @"c3");

  // A few invalid vertexes
  point = [board pointAtVertex:@"I4"];
  XCTAssertNil(point, @"letter I used for vertex");
  point = [board pointAtVertex:@"U1"];
  XCTAssertNil(point, @"letter U used for vertex");
  point = [board pointAtVertex:@"A0"];
  XCTAssertNil(point, @"number 0 used for vertex");
  point = [board pointAtVertex:@""];
  XCTAssertNil(point, @"empty string used for vertex");
  point = [board pointAtVertex:@"foobar"];
  XCTAssertNil(point, @"malformed string used for vertex");
  XCTAssertThrowsSpecificNamed([board pointAtVertex:nil],
                              NSException, NSInvalidArgumentException, @"nil used for vertex");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the neighbourOf:inDirection() method.
// -----------------------------------------------------------------------------
- (void) testNeighbourOfInDirection
{
  int expectedBoardSize = 19;
  GoBoard* board = m_game.board;
  XCTAssertEqual(expectedBoardSize, board.size);

  enum GoBoardDirection direction = GoBoardDirectionLeft;
  for (; direction <= GoBoardDirectionPrevious; ++direction)
  {
    int expectedNumberOfPoints = pow(expectedBoardSize, 2);
    NSString* initialVertex;
    switch (direction)
    {
      case GoBoardDirectionLeft:
        expectedNumberOfPoints = expectedBoardSize;
        initialVertex = @"T8";
        break;
      case GoBoardDirectionRight:
        expectedNumberOfPoints = expectedBoardSize;
        initialVertex = @"A14";
        break;
      case GoBoardDirectionUp:
        expectedNumberOfPoints = expectedBoardSize;
        initialVertex = @"Q1";
        break;
      case GoBoardDirectionDown:
        expectedNumberOfPoints = expectedBoardSize;
        initialVertex = @"J19";
        break;
      case GoBoardDirectionNext:
        expectedNumberOfPoints = pow(expectedBoardSize, 2);
        initialVertex = @"A1";
        break;
      case GoBoardDirectionPrevious:
        expectedNumberOfPoints = pow(expectedBoardSize, 2);
        initialVertex = @"T19";
        break;
      default:
        XCTFail();
        return;
    }
    GoPoint* point = [board pointAtVertex:initialVertex];
    XCTAssertNotNil(point, @"%@", initialVertex);
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
    XCTAssertEqual(expectedNumberOfPoints, numberOfPoints, @"%@", initialVertex);
  }
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pointAtCorner:() method.
// -----------------------------------------------------------------------------
- (void) testPointAtCorner
{
  GoBoard* board = m_game.board;
  GoPoint* point;

  point = [board pointAtCorner:GoBoardCornerBottomLeft];
  XCTAssertNotNil(point);
  XCTAssert([@"A1" isEqualToString:point.vertex.string]);
  point = [board pointAtCorner:GoBoardCornerBottomRight];
  XCTAssertNotNil(point);
  XCTAssert([@"T1" isEqualToString:point.vertex.string]);
  point = [board pointAtCorner:GoBoardCornerTopLeft];
  XCTAssertNotNil(point);
  XCTAssert([@"A19" isEqualToString:point.vertex.string]);
  point = [board pointAtCorner:GoBoardCornerTopRight];
  XCTAssertNotNil(point);
  XCTAssert([@"T19" isEqualToString:point.vertex.string]);

  XCTAssertThrowsSpecificNamed([board pointAtCorner:(enum GoBoardCorner)42],
                               NSException, NSInvalidArgumentException, @"evil cast");
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
  XCTAssertNotNil(starPoints);
  XCTAssertEqual(expectedNumberOfStarPoints, starPoints.count);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e regions property.
// -----------------------------------------------------------------------------
- (void) testRegions
{
  NSUInteger expectedNumberOfRegions = 1;

  NSArray* regions = m_game.board.regions;
  XCTAssertNotNil(regions);
  XCTAssertEqual(expectedNumberOfRegions, regions.count);

  NewGameModel* newGameModel = m_delegate.theNewGameModel;
  newGameModel.boardSize = GoBoardSize9;
  newGameModel.handicap = 5;
  expectedNumberOfRegions = 1 + newGameModel.handicap;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that checks the initial state of @a board after
/// its creation.
// -----------------------------------------------------------------------------
- (void) checkBoardState:(GoBoard*)board expectedBoardSize:(enum GoBoardSize)expectedBoardSize
{
  int expectedNumberOfPoints = pow(expectedBoardSize, 2);

  XCTAssertNotNil(board);
  XCTAssertEqual(expectedBoardSize, board.size);

  int numberOfPoints = 0;
  NSEnumerator* enumerator = [board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    ++numberOfPoints;
    if (numberOfPoints > expectedNumberOfPoints)
      break;
  }
  XCTAssertEqual(expectedNumberOfPoints, numberOfPoints);
}

@end
