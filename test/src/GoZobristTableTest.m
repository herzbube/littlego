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
#import "GoZobristTableTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoMove.h>
#import <go/GoPoint.h>
#import <go/GoZobristTable.h>


@implementation GoZobristTableTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of GoZobristTable object after a new GoGame
/// has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  XCTAssertNotNil(m_game.board.zobristTable);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the hashForBoard() method.
// -----------------------------------------------------------------------------
- (void) testHashForBoard
{
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;
  long long hashForEmptyBoard = 0;

  long long hash = [zobristTable hashForBoard:board];
  XCTAssertEqual(hash, hashForEmptyBoard);

  GoPoint* point = [board pointAtVertex:@"B2"];
  [m_game play:point];
  hash = [zobristTable hashForBoard:board];
  XCTAssertTrue(hash != hashForEmptyBoard);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the hashForMove() method.
// -----------------------------------------------------------------------------
- (void) testHashForMove
{
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;
  long long hashForEmptyBoard = 0;

  [m_game play:[board pointAtVertex:@"B2"]];
  long long hashForFirstMove = [zobristTable hashForMove:m_game.lastMove];
  XCTAssertTrue(hashForFirstMove != hashForEmptyBoard);

  [m_game play:[board pointAtVertex:@"Q14"]];
  long long hashForSecondMove = [zobristTable hashForMove:m_game.lastMove];
  XCTAssertTrue(hashForSecondMove != hashForEmptyBoard);
  XCTAssertTrue(hashForFirstMove != hashForSecondMove);

  // Test that hash for first move did not change
  long long hash = [zobristTable hashForMove:m_game.firstMove];
  XCTAssertEqual(hashForFirstMove, hash);

  // Test that we cannot pass a nil object
  XCTAssertThrowsSpecificNamed([zobristTable hashForMove:nil],
                              NSException, NSGenericException, @"move is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the
/// hashForStonePlayedBy:atPoint:capturingStones:afterMove:() method.
// -----------------------------------------------------------------------------
- (void) testHashForStone
{
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;

  GoPoint* point = [board pointAtVertex:@"A1"];
  [m_game play:point];
  [m_game play:point.above];
  [m_game pass];
  GoMove* passMove = m_game.lastMove;
  XCTAssertEqual(passMove.type, GoMoveTypePass);
  [m_game play:point.right];
  GoMove* lastMove = m_game.lastMove;
  XCTAssertEqual(lastMove.type, GoMoveTypePlay);
  XCTAssertNotNil(lastMove.capturedStones);
  XCTAssertTrue(lastMove.capturedStones.count > 0);

  long long hashForStone = [zobristTable hashForStonePlayedBy:lastMove.player
                                                      atPoint:lastMove.point
                                              capturingStones:lastMove.capturedStones
                                                    afterMove:passMove];
  long long hashForMove = [zobristTable hashForMove:lastMove];
  XCTAssertEqual(hashForStone, hashForMove);
  XCTAssertEqual(hashForStone, lastMove.zobristHash);
}

// -----------------------------------------------------------------------------
/// @brief Check that the hash for the last move is the same as the hash for
/// the entire board.
// -----------------------------------------------------------------------------
- (void) testHashForLastMoveEqualsHashForBoard
{
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;

  GoPoint* point = [board pointAtVertex:@"B2"];
  [m_game play:point];
  [m_game play:point.right];
  [m_game play:point.left];
  [m_game play:point.above];
  [m_game play:point.below];

  long long hashForBoard = [zobristTable hashForBoard:board];
  long long hashForLastMove = [zobristTable hashForMove:m_game.lastMove];
  XCTAssertEqual(hashForBoard, hashForLastMove);
}

// -----------------------------------------------------------------------------
/// @brief Check that a pass move does not change the hash.
// -----------------------------------------------------------------------------
- (void) testHashAfterPass
{
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;
  long long hashForEmptyBoard = 0;

  [m_game play:[board pointAtVertex:@"B2"]];
  long long hashForFirstMove = [zobristTable hashForMove:m_game.lastMove];
  XCTAssertTrue(hashForFirstMove != hashForEmptyBoard);

  [m_game pass];
  long long hashForSecondMove = [zobristTable hashForMove:m_game.lastMove];
  XCTAssertTrue(hashForSecondMove != hashForEmptyBoard);
  XCTAssertEqual(hashForFirstMove, hashForSecondMove);
}

// -----------------------------------------------------------------------------
/// @brief Check that the board hash reverts to the previous value after an
/// undo.
// -----------------------------------------------------------------------------
- (void) testHashAfterUndoAndRedo
{
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;
  long long hashForEmptyBoard = 0;

  GoPoint* point = [board pointAtVertex:@"B2"];
  [m_game play:point];
  long long hashForFirstMove = [zobristTable hashForBoard:board];
  XCTAssertTrue(hashForFirstMove != hashForEmptyBoard);
  [m_game play:point.right];
  long long hashForSecondMove = [zobristTable hashForBoard:board];
  XCTAssertTrue(hashForSecondMove != hashForEmptyBoard);
  XCTAssertTrue(hashForFirstMove != hashForSecondMove);
  [m_game.lastMove undo];
  long long hash = [zobristTable hashForBoard:board];
  XCTAssertEqual(hashForFirstMove, hash);
  [m_game.lastMove doIt];
  hash = [zobristTable hashForBoard:board];
  XCTAssertEqual(hashForSecondMove, hash);
}

@end
