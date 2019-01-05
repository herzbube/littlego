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
#import <go/GoPlayer.h>
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
/// @brief Exercises the hashForBoard:() method.
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

  // Test that we cannot pass a nil object
  XCTAssertThrowsSpecificNamed([zobristTable hashForBoard:nil],
                               NSException, NSInvalidArgumentException, @"board is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the hashForBoard:blackStones:whiteStones:() method.
// -----------------------------------------------------------------------------
- (void) testHashForBoardBlackStonesWhiteStones
{
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;
  long long hashForEmptyBoard = 0;

  long long hash = [zobristTable hashForBoard:board blackStones:@[] whiteStones:@[]];
  XCTAssertEqual(hash, hashForEmptyBoard);

  GoPoint* pointWithBlackStone = [board pointAtVertex:@"B2"];
  [m_game play:pointWithBlackStone];
  long long hashAfterBlackStoneIsPlayed = m_game.lastMove.zobristHash;
  GoPoint* pointWithWhiteStone = [board pointAtVertex:@"C5"];
  [m_game play:pointWithWhiteStone];
  long long hashAfterWhiteStoneIsPlayed = m_game.lastMove.zobristHash;

  // Current board position represented by the GoBoard object is ignored, only
  // the supplied black and white stones matter
  hash = [zobristTable hashForBoard:board blackStones:@[] whiteStones:@[]];
  XCTAssertEqual(hash, hashForEmptyBoard);

  // Hash calculation has the same result, regardless of whether it's performed
  // by the function under test or by playing a move
  hash = [zobristTable hashForBoard:board blackStones:@[pointWithBlackStone] whiteStones:@[]];
  XCTAssertTrue(hash != hashForEmptyBoard);
  XCTAssertEqual(hash, hashAfterBlackStoneIsPlayed);
  hash = [zobristTable hashForBoard:board blackStones:@[pointWithBlackStone] whiteStones:@[pointWithWhiteStone]];
  XCTAssertTrue(hash != hashForEmptyBoard);
  XCTAssertEqual(hash, hashAfterWhiteStoneIsPlayed);

  hash = [zobristTable hashForBoard:board blackStones:@[] whiteStones:@[pointWithWhiteStone]];
  XCTAssertTrue(hash != hashForEmptyBoard);
  XCTAssertTrue(hash != hashAfterBlackStoneIsPlayed);
  XCTAssertTrue(hash != hashAfterWhiteStoneIsPlayed);

  // Test that we cannot pass a nil object
  XCTAssertThrowsSpecificNamed([zobristTable hashForBoard:nil blackStones:@[] whiteStones:@[]],
                               NSException, NSInvalidArgumentException, @"board is nil");
  XCTAssertThrowsSpecificNamed([zobristTable hashForBoard:board blackStones:nil whiteStones:@[]],
                               NSException, NSInvalidArgumentException, @"black stones list is nil");
  XCTAssertThrowsSpecificNamed([zobristTable hashForBoard:board blackStones:@[] whiteStones:nil],
                               NSException, NSInvalidArgumentException, @"white stones list is nil");
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
  long long hashForFirstMove = [zobristTable hashForMove:m_game.lastMove inGame:m_game];
  XCTAssertTrue(hashForFirstMove != hashForEmptyBoard);

  [m_game play:[board pointAtVertex:@"Q14"]];
  long long hashForSecondMove = [zobristTable hashForMove:m_game.lastMove inGame:m_game];
  XCTAssertTrue(hashForSecondMove != hashForEmptyBoard);
  XCTAssertTrue(hashForFirstMove != hashForSecondMove);

  // Test that hash for first move did not change
  long long hash = [zobristTable hashForMove:m_game.firstMove inGame:m_game];
  XCTAssertEqual(hashForFirstMove, hash);

  // Test that we cannot pass a nil object
  XCTAssertThrowsSpecificNamed([zobristTable hashForMove:nil inGame:m_game],
                              NSException, NSInvalidArgumentException, @"move is nil");
  XCTAssertThrowsSpecificNamed([zobristTable hashForMove:m_game.lastMove inGame:nil],
                               NSException, NSInvalidArgumentException, @"game is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the
/// hashForStonePlayedByColor:atPoint:capturingStones:afterMove:() method.
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

  long long hashForStone = [zobristTable hashForStonePlayedByColor:lastMove.player.color
                                                           atPoint:lastMove.point
                                                   capturingStones:lastMove.capturedStones
                                                         afterMove:passMove
                                                            inGame:m_game];
  long long hashForMove = [zobristTable hashForMove:lastMove
                                             inGame:m_game];
  XCTAssertEqual(hashForStone, hashForMove);
  XCTAssertEqual(hashForStone, lastMove.zobristHash);

  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:GoColorNone
                                                               atPoint:lastMove.point
                                                       capturingStones:lastMove.capturedStones
                                                             afterMove:passMove
                                                                inGame:m_game],
                               NSException, NSInvalidArgumentException, @"invalid GoColor argument");
  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:lastMove.player.color
                                                               atPoint:nil
                                                       capturingStones:lastMove.capturedStones
                                                             afterMove:passMove
                                                                inGame:m_game],
                               NSException, NSInvalidArgumentException, @"point is nil");
  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:lastMove.player.color
                                                               atPoint:lastMove.point
                                                       capturingStones:lastMove.capturedStones
                                                             afterMove:passMove
                                                                inGame:nil],
                               NSException, NSInvalidArgumentException, @"game is nil");
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
  long long hashForLastMove = [zobristTable hashForMove:m_game.lastMove
                                                 inGame:m_game];
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
  long long hashForFirstMove = [zobristTable hashForMove:m_game.lastMove
                                                  inGame:m_game];
  XCTAssertTrue(hashForFirstMove != hashForEmptyBoard);

  [m_game pass];
  long long hashForSecondMove = [zobristTable hashForMove:m_game.lastMove
                                                   inGame:m_game];
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

// -----------------------------------------------------------------------------
/// @brief Check that all hash functions validate the board size
// -----------------------------------------------------------------------------
- (void) testValidateBoardSize
{
  GoBoard* board = m_game.board;

  enum GoBoardSize zobristTableBoardSize;
  if (board.size == GoBoardSize7)
    zobristTableBoardSize = GoBoardSize9;
  else
    zobristTableBoardSize = GoBoardSize7;

  GoZobristTable* zobristTable = [[[GoZobristTable alloc] initWithBoardSize:zobristTableBoardSize] autorelease];

  [m_game play:[board pointAtVertex:@"B2"]];
  GoMove* lastMove = m_game.lastMove;

  XCTAssertThrowsSpecificNamed([zobristTable hashForBoard:board],
                               NSException, NSGenericException, @"hashForBoard:() accepts wrong board size");
  XCTAssertThrowsSpecificNamed([zobristTable hashForBoard:board blackStones:@[] whiteStones:@[]],
                               NSException, NSGenericException, @"hashForBoard:blackStones:whiteStones:() accepts wrong board size");
  XCTAssertThrowsSpecificNamed([zobristTable hashForMove:lastMove inGame:m_game],
                               NSException, NSGenericException, @"hashForMove:inGame:() accepts wrong board size");
  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:lastMove.player.color
                                                               atPoint:lastMove.point
                                                       capturingStones:lastMove.capturedStones
                                                             afterMove:nil
                                                                inGame:m_game],
                               NSException, NSGenericException, @"hashForStonePlayedByColor:atPoint:capturingStones:afterMove:inGame:() accepts wrong board size");
}

@end
