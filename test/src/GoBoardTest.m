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
#import "GoBoardTest.h"

// Application includes
#import <go/GoGame.h>
#import <go/GoBoard.h>
#import <main/ApplicationDelegate.h>
#import <newGame/NewGameModel.h>
#import <command/game/NewGameCommand.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoBoard.
// -----------------------------------------------------------------------------
@interface GoBoardTest()
- (void) checkBoardState:(GoBoard*)board expectedBoardSize:(enum GoBoardSize)expectedBoardSize;
@end


@implementation GoBoardTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of a GoBoard object after after a new GoGame
/// has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  enum GoBoardSize expectedBoardSize = GoBoardSize19;
  [self checkBoardState:m_game.board expectedBoardSize:expectedBoardSize];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the newGameBoard() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testNewGameBoard
{
  enum GoBoardSize expectedBoardSize = GoBoardSize13;

  NewGameModel* newGameModel = m_delegate.theNewGameModel;
  newGameModel.boardSize = expectedBoardSize;
  GoBoard* board = [GoBoard newGameBoard];

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

  STAssertThrowsSpecificNamed([GoBoard boardWithSize:GoBoardSizeUndefined],
                              NSException, NSInvalidArgumentException, @"GoBoardSizeUndefined");
  STAssertThrowsSpecificNamed([GoBoard boardWithSize:(enum GoBoardSize)42],
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
    STAssertTrue([expectedBoardSizeStrings[index] isEqualToString:[GoBoard stringForSize:boardSizes[index]]], expectedBoardSizeStrings[index]);

  STAssertThrowsSpecificNamed([GoBoard stringForSize:(enum GoBoardSize)42],
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

  // A lower-case string must also work
  point = [board pointAtVertex:@"c3"];
  STAssertNotNil(point, @"c3");

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
  int expectedBoardSize = 19;
  GoBoard* board = m_game.board;
  STAssertEquals(expectedBoardSize, board.size, nil);

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
  STAssertEquals(expectedNumberOfStarPoints, starPoints.count, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e regions property.
// -----------------------------------------------------------------------------
- (void) testRegions
{
  NSUInteger expectedNumberOfRegions = 1;

  NSArray* regions = m_game.board.regions;
  STAssertNotNil(regions, nil);
  STAssertEquals(expectedNumberOfRegions, regions.count, nil);

  NewGameModel* newGameModel = m_delegate.theNewGameModel;
  newGameModel.boardSize = GoBoardSize9;
  newGameModel.handicap = 5;
  expectedNumberOfRegions = 1 + newGameModel.handicap;
  [[[NewGameCommand alloc] init] submit];
  m_game = m_delegate.game;
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that checks the initial state of @a board after
/// its creation.
// -----------------------------------------------------------------------------
- (void) checkBoardState:(GoBoard*)board expectedBoardSize:(enum GoBoardSize)expectedBoardSize
{
  int expectedNumberOfPoints = pow(expectedBoardSize, 2);

  STAssertNotNil(board, nil);
  STAssertEquals(expectedBoardSize, board.size, nil);

  int numberOfPoints = 0;
  NSEnumerator* enumerator = [board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    ++numberOfPoints;
    if (numberOfPoints > expectedNumberOfPoints)
      break;
  }
  STAssertEquals(expectedNumberOfPoints, numberOfPoints, nil);
}

@end
