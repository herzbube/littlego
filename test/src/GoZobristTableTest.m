// -----------------------------------------------------------------------------
// Copyright 2011-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import <go/GoNode.h>
#import <go/GoNodeModel.h>
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
/// @brief Exercises the hashForNode:inGame:() method.
// -----------------------------------------------------------------------------
- (void) testHashForNode
{
  GoBoard* board = m_game.board;
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoZobristTable* zobristTable = board.zobristTable;
  long long hashForEmptyBoard = 0;

  m_game.handicapPoints = @[[board pointAtVertex:@"A1"]];
  long long hashForHandicap = [zobristTable hashForNode:nodeModel.rootNode inGame:m_game];
  XCTAssertTrue(hashForHandicap != hashForEmptyBoard);
  XCTAssertTrue(hashForHandicap == m_game.zobristHashAfterHandicap);

  GoNode* rootNode = nodeModel.rootNode;
  long long hashForRootNode = [zobristTable hashForNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForRootNode == hashForHandicap);
  XCTAssertTrue(hashForRootNode == rootNode.zobristHash);

  [m_game play:[board pointAtVertex:@"B2"]];
  GoNode* nodeWithMove1 = nodeModel.leafNode;
  long long hashForFirstMove = [zobristTable hashForNode:nodeWithMove1 inGame:m_game];
  XCTAssertTrue(hashForFirstMove != hashForEmptyBoard);
  XCTAssertTrue(hashForFirstMove != hashForHandicap);
  XCTAssertTrue(hashForFirstMove == nodeWithMove1.zobristHash);

  [m_game play:[board pointAtVertex:@"Q14"]];
  GoNode* nodeWithMove2 = nodeModel.leafNode;
  long long hashForSecondMove = [zobristTable hashForNode:nodeWithMove2 inGame:m_game];
  XCTAssertTrue(hashForSecondMove != hashForEmptyBoard);
  XCTAssertTrue(hashForSecondMove != hashForHandicap);
  XCTAssertTrue(hashForSecondMove != hashForFirstMove);
  XCTAssertTrue(hashForSecondMove == nodeWithMove2.zobristHash);

  [m_game pass];
  GoNode* nodeWithMove3 = nodeModel.leafNode;
  long long hashForThirdMove = [zobristTable hashForNode:nodeWithMove3 inGame:m_game];
  XCTAssertTrue(hashForThirdMove == hashForSecondMove);
  XCTAssertTrue(hashForThirdMove == nodeWithMove3.zobristHash);

  // Test that hash for first move did not change
  long long hash = [zobristTable hashForNode:nodeWithMove1 inGame:m_game];
  XCTAssertEqual(hashForFirstMove, hash);

  // TODO xxx Add tests for game setup

  // Test that we cannot pass a nil object
  XCTAssertThrowsSpecificNamed([zobristTable hashForNode:nil inGame:m_game],
                              NSException, NSInvalidArgumentException, @"node is nil");
  XCTAssertThrowsSpecificNamed([zobristTable hashForNode:nodeWithMove1 inGame:nil],
                               NSException, NSInvalidArgumentException, @"game is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the
/// hashForBlackSetupStones:whiteSetupStones:noSetupStones:previousBlackSetupStones:previousWhiteSetupStones:afterNode:inGame:()
/// method.
// -----------------------------------------------------------------------------
- (void) testHashForSetup
{
  // TODO xxx Add tests
}

// -----------------------------------------------------------------------------
/// @brief Exercises the
/// hashForStonePlayedByColor:atPoint:capturingStones:afterNode:inGame:()
/// method.
// -----------------------------------------------------------------------------
- (void) testHashForStone
{
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;

  GoPoint* point = [board pointAtVertex:@"A1"];
  [m_game play:point];
  [m_game play:point.above];
  [m_game pass];
  GoNode* nodeWithPassMove = nodeModel.leafNode;
  XCTAssertEqual(nodeWithPassMove.goMove.type, GoMoveTypePass);
  [m_game play:point.right];
  GoNode* nodeWithLastMove = nodeModel.leafNode;
  XCTAssertEqual(nodeWithLastMove.goMove.type, GoMoveTypePlay);
  XCTAssertNotNil(nodeWithLastMove.goMove.capturedStones);
  XCTAssertTrue(nodeWithLastMove.goMove.capturedStones.count > 0);

  long long hashForStone = [zobristTable hashForStonePlayedByColor:nodeWithLastMove.goMove.player.color
                                                           atPoint:nodeWithLastMove.goMove.point
                                                   capturingStones:nodeWithLastMove.goMove.capturedStones
                                                         afterNode:nodeWithPassMove
                                                            inGame:m_game];
  long long hashForMove = [zobristTable hashForNode:nodeWithLastMove
                                             inGame:m_game];
  XCTAssertEqual(hashForStone, hashForMove);
  XCTAssertEqual(hashForStone, nodeWithLastMove.zobristHash);

  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:GoColorNone
                                                               atPoint:nodeWithLastMove.goMove.point
                                                       capturingStones:nodeWithLastMove.goMove.capturedStones
                                                             afterNode:nodeWithPassMove
                                                                inGame:m_game],
                               NSException, NSInvalidArgumentException, @"invalid GoColor argument");
  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:nodeWithLastMove.goMove.player.color
                                                               atPoint:nil
                                                       capturingStones:nodeWithLastMove.goMove.capturedStones
                                                             afterNode:nodeWithPassMove
                                                                inGame:m_game],
                               NSException, NSInvalidArgumentException, @"point is nil");
  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:nodeWithLastMove.goMove.player.color
                                                               atPoint:nodeWithLastMove.goMove.point
                                                       capturingStones:nodeWithLastMove.goMove.capturedStones
                                                             afterNode:nodeWithPassMove
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
  long long hashForLastMove = [zobristTable hashForNode:m_game.nodeModel.leafNode
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
  long long hashForFirstMove = [zobristTable hashForNode:m_game.nodeModel.leafNode
                                                  inGame:m_game];
  XCTAssertTrue(hashForFirstMove != hashForEmptyBoard);

  [m_game pass];
  long long hashForSecondMove = [zobristTable hashForNode:m_game.nodeModel.leafNode
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
  GoNode* nodeWithLastMove = m_game.nodeModel.leafNode;
  GoMove* lastMove = m_game.lastMove;

  XCTAssertThrowsSpecificNamed([zobristTable hashForBoard:board],
                               NSException, NSGenericException, @"hashForBoard:() accepts wrong board size");
  XCTAssertThrowsSpecificNamed([zobristTable hashForNode:nodeWithLastMove inGame:m_game],
                               NSException, NSGenericException, @"hashForMove:inGame:() accepts wrong board size");
  XCTAssertThrowsSpecificNamed([zobristTable hashForBlackSetupStones:nil
                                                    whiteSetupStones:nil
                                                       noSetupStones:nil
                                            previousBlackSetupStones:nil
                                            previousWhiteSetupStones:nil
                                                           afterNode:nil
                                                              inGame:m_game],
                               NSException, NSGenericException, @"hashForBlackSetupStones:whiteSetupStones:noSetupStones:previousBlackSetupStones:previousWhiteSetupStones:afterNode:inGame:() accepts wrong board size");
  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:lastMove.player.color
                                                               atPoint:lastMove.point
                                                       capturingStones:lastMove.capturedStones
                                                             afterNode:nil
                                                                inGame:m_game],
                               NSException, NSGenericException, @"hashForStonePlayedByColor:atPoint:capturingStones:afterMove:inGame:() accepts wrong board size");
}

@end
