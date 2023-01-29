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
#import <go/GoGameAdditions.h>
#import <go/GoMove.h>
#import <go/GoNode.h>
#import <go/GoNodeModel.h>
#import <go/GoNodeSetup.h>
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

  [m_game play:[board pointAtVertex:@"B2"]];
  hash = [zobristTable hashForBoard:board];
  XCTAssertTrue(hash != hashForEmptyBoard);

  [m_game play:[board pointAtVertex:@"F7"]];
  long long previousHash = hash;
  hash = [zobristTable hashForBoard:board];
  XCTAssertTrue(hash != hashForEmptyBoard);
  XCTAssertTrue(hash != previousHash);

  XCTAssertThrowsSpecificNamed([zobristTable hashForBoard:nil],
                               NSException, NSInvalidArgumentException, @"board is nil");

  GoZobristTable* zobristTableWithDifferentBoardSize = [self zobristTableWithBoardSizeDifferentFromGame:m_game];
  XCTAssertThrowsSpecificNamed([zobristTableWithDifferentBoardSize hashForBoard:board],
                               NSException, NSGenericException, @"hashForBoard:() accepts wrong board size");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the hashForHandicapStonesInGame:() method.
// -----------------------------------------------------------------------------
- (void) testHashForHandicapStonesInGame
{
  GoBoard* board = m_game.board;
  GoZobristTable* zobristTable = board.zobristTable;
  long long hashForEmptyBoard = 0;

  long long hash = [zobristTable hashForBoard:board];
  XCTAssertEqual(hash, hashForEmptyBoard);

  m_game.handicapPoints = @[[board pointAtVertex:@"A1"]];
  hash = [zobristTable hashForHandicapStonesInGame:m_game];
  XCTAssertTrue(hash != hashForEmptyBoard);

  m_game.handicapPoints = @[[board pointAtVertex:@"A1"], [board pointAtVertex:@"A2"]];
  long long previousHash = hash;
  hash = [zobristTable hashForHandicapStonesInGame:m_game];
  XCTAssertTrue(hash != hashForEmptyBoard);
  XCTAssertTrue(hash != previousHash);

  // Board state does not affect the calculation
  GoPoint* point = [board pointAtVertex:@"B2"];
  [m_game play:point];
  previousHash = hash;
  hash = [zobristTable hashForHandicapStonesInGame:m_game];
  XCTAssertTrue(hash == previousHash);

  GoZobristTable* zobristTableWithDifferentBoardSize = [self zobristTableWithBoardSizeDifferentFromGame:m_game];
  XCTAssertThrowsSpecificNamed([zobristTableWithDifferentBoardSize hashForHandicapStonesInGame:m_game],
                               NSException, NSGenericException, @"hashForHandicapStonesInGame:() accepts wrong board size");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the hashForNode:inGame:() method.
// -----------------------------------------------------------------------------
- (void) testHashForNodeInGame
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

  // Hash does not change when setupFirstMoveColor is set
  [m_game addEmptyNodeToCurrentGameVariation];
  [m_game changeSetupFirstMoveColor:GoColorBlack];
  GoNode* nodeWithSetupFirstMoveColor = nodeModel.leafNode;
  long long hashForSetupFirstMoveColor = [zobristTable hashForNode:nodeWithSetupFirstMoveColor inGame:m_game];
  XCTAssertTrue(hashForSetupFirstMoveColor == hashForHandicap);
  XCTAssertTrue(hashForSetupFirstMoveColor == nodeWithSetupFirstMoveColor.zobristHash);

  [m_game addEmptyNodeToCurrentGameVariation];
  [m_game changeSetupPoint:[board pointAtVertex:@"B2"] toStoneState:GoColorWhite];
  GoNode* nodeWithSetup1 = nodeModel.leafNode;
  long long hashForSetup1 = [zobristTable hashForNode:nodeWithSetup1 inGame:m_game];
  XCTAssertTrue(hashForSetup1 != hashForEmptyBoard);
  XCTAssertTrue(hashForSetup1 != hashForHandicap);
  XCTAssertTrue(hashForSetup1 == nodeWithSetup1.zobristHash);

  // Hash reverts to hash from previous node when setup removes a stone
  [m_game addEmptyNodeToCurrentGameVariation];
  [m_game changeSetupPoint:[board pointAtVertex:@"B2"] toStoneState:GoColorNone];
  GoNode* nodeWithSetup2 = nodeModel.leafNode;
  long long hashForSetup2 = [zobristTable hashForNode:nodeWithSetup2 inGame:m_game];
  XCTAssertTrue(hashForSetup2 != hashForEmptyBoard);
  XCTAssertTrue(hashForSetup2 == hashForHandicap);
  XCTAssertTrue(hashForSetup2 == nodeWithSetup2.zobristHash);

  // Hash reverts to hash for empty board when setup removes all stones
  [m_game addEmptyNodeToCurrentGameVariation];
  [m_game changeSetupPoint:[board pointAtVertex:@"A1"] toStoneState:GoColorNone];
  GoNode* nodeWithSetup3 = nodeModel.leafNode;
  long long hashForSetup3 = [zobristTable hashForNode:nodeWithSetup3 inGame:m_game];
  XCTAssertTrue(hashForSetup3 == hashForEmptyBoard);
  XCTAssertTrue(hashForSetup3 == nodeWithSetup3.zobristHash);

  // Hash is the same regardless of whether a stone was placed by handicap or by
  // a move
  [m_game play:[board pointAtVertex:@"A1"]];
  GoNode* nodeWithMove1 = nodeModel.leafNode;
  long long hashForMove1 = [zobristTable hashForNode:nodeWithMove1 inGame:m_game];
  XCTAssertTrue(hashForMove1 != hashForEmptyBoard);
  XCTAssertTrue(hashForMove1 == hashForHandicap);
  XCTAssertTrue(hashForMove1 != hashForSetup1);
  XCTAssertTrue(hashForMove1 == nodeWithMove1.zobristHash);

  // Hash is the same regardless of whether a stone was placed by setup or by
  // a move
  [m_game play:[board pointAtVertex:@"B2"]];
  GoNode* nodeWithMove2 = nodeModel.leafNode;
  long long hashForMove2 = [zobristTable hashForNode:nodeWithMove2 inGame:m_game];
  XCTAssertTrue(hashForMove2 != hashForEmptyBoard);
  XCTAssertTrue(hashForMove2 != hashForHandicap);
  XCTAssertTrue(hashForMove2 == hashForSetup1);
  XCTAssertTrue(hashForMove2 != hashForMove1);
  XCTAssertTrue(hashForMove2 == nodeWithMove2.zobristHash);

  [m_game play:[board pointAtVertex:@"Q14"]];
  GoNode* nodeWithMove3 = nodeModel.leafNode;
  long long hashForMove3 = [zobristTable hashForNode:nodeWithMove3 inGame:m_game];
  XCTAssertTrue(hashForMove3 != hashForEmptyBoard);
  XCTAssertTrue(hashForMove3 != hashForHandicap);
  XCTAssertTrue(hashForMove3 != hashForSetup1);
  XCTAssertTrue(hashForMove3 != hashForMove1);
  XCTAssertTrue(hashForMove3 != hashForMove2);
  XCTAssertTrue(hashForMove3 == nodeWithMove3.zobristHash);

  // Hash does not change for pass moves
  [m_game pass];
  GoNode* nodeWithMove4 = nodeModel.leafNode;
  long long hashForMove4 = [zobristTable hashForNode:nodeWithMove4 inGame:m_game];
  XCTAssertTrue(hashForMove4 == hashForMove3);
  XCTAssertTrue(hashForMove4 == nodeWithMove4.zobristHash);

  // Test that hash for first move did not change
  long long hash = [zobristTable hashForNode:nodeWithMove1 inGame:m_game];
  XCTAssertEqual(hashForMove1, hash);

  XCTAssertThrowsSpecificNamed([zobristTable hashForNode:nil inGame:m_game],
                              NSException, NSInvalidArgumentException, @"node is nil");
  XCTAssertThrowsSpecificNamed([zobristTable hashForNode:nodeWithMove1 inGame:nil],
                               NSException, NSInvalidArgumentException, @"game is nil");

  [nodeWithSetup1.goNodeSetup setupValidatedNoStones:@[[board pointAtVertex:@"E1"]]];
  XCTAssertThrowsSpecificNamed([zobristTable hashForNode:nodeWithSetup1 inGame:m_game],
                               NSException, NSInternalInconsistencyException, @"setup information is inconsistent");

  GoZobristTable* zobristTableWithDifferentBoardSize = [self zobristTableWithBoardSizeDifferentFromGame:m_game];
  XCTAssertThrowsSpecificNamed([zobristTableWithDifferentBoardSize hashForNode:nodeWithMove1 inGame:m_game],
                               NSException, NSGenericException, @"hashForMove:inGame:() accepts wrong board size");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the
/// hashForBlackSetupStones:whiteSetupStones:noSetupStones:previousBlackSetupStones:previousWhiteSetupStones:afterNode:inGame:()
/// method.
// -----------------------------------------------------------------------------
- (void) testHashForSetup
{
  GoBoard* board = m_game.board;
  GoNodeModel* nodeModel = m_game.nodeModel;
  GoZobristTable* zobristTable = board.zobristTable;
  GoNode* rootNode = nodeModel.rootNode;
  long long hashForEmptyBoard = 0;

  GoPoint* point1 = [board pointAtVertex:@"A1"];
  GoPoint* point2 = [board pointAtVertex:@"A2"];
  GoPoint* point3 = [board pointAtVertex:@"B1"];
  GoPoint* point4 = [board pointAtVertex:@"B2"];

  NSMutableArray* blackSetupStones = [NSMutableArray array];
  NSMutableArray* whiteSetupStones = [NSMutableArray array];
  NSMutableArray* noSetupStones = [NSMutableArray array];
  NSMutableArray* previousBlackSetupStones = [NSMutableArray array];
  NSMutableArray* previousWhiteSetupStones = [NSMutableArray array];

  void (^clearArrays) (void) = ^()
  {
    [blackSetupStones removeAllObjects];
    [whiteSetupStones removeAllObjects];
    [noSetupStones removeAllObjects];
    [previousBlackSetupStones removeAllObjects];
    [previousWhiteSetupStones removeAllObjects];
  };

  clearArrays();
  long long hash = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hash == hashForEmptyBoard);

  // Single black setup stone
  clearArrays();
  [blackSetupStones addObject:point1];
  long long hashForBlackSetupStone1 = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForBlackSetupStone1 != hashForEmptyBoard);

  // Multiple black setup stones
  clearArrays();
  [blackSetupStones addObject:point1];
  [blackSetupStones addObject:point2];
  [blackSetupStones addObject:point3];
  long long hashForThreeBlackSetupStones = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForThreeBlackSetupStones != hashForEmptyBoard);
  XCTAssertTrue(hashForThreeBlackSetupStones != hashForBlackSetupStone1);

  // Single white setup stone
  clearArrays();
  [whiteSetupStones addObject:point1];
  long long hashForWhiteSetupStone1 = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForWhiteSetupStone1 != hashForEmptyBoard);
  XCTAssertTrue(hashForWhiteSetupStone1 != hashForBlackSetupStone1);

  // Multiple white setup stones
  clearArrays();
  [whiteSetupStones addObject:point1];
  [whiteSetupStones addObject:point2];
  [whiteSetupStones addObject:point3];
  long long hashForThreeWhiteSetupStones = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForThreeWhiteSetupStones != hashForEmptyBoard);
  XCTAssertTrue(hashForThreeWhiteSetupStones != hashForWhiteSetupStone1);

  // Both black and white setup stones
  clearArrays();
  [blackSetupStones addObject:point1];
  [whiteSetupStones addObject:point2];
  long long hashForBlackAndWhiteSetupStone = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForBlackAndWhiteSetupStone != hashForEmptyBoard);
  XCTAssertTrue(hashForBlackAndWhiteSetupStone != hashForBlackSetupStone1);
  XCTAssertTrue(hashForBlackAndWhiteSetupStone != hashForWhiteSetupStone1);

  // Replace white setup stone with black setup stone
  clearArrays();
  rootNode.zobristHash = hashForWhiteSetupStone1;
  [previousWhiteSetupStones addObject:point1];
  [blackSetupStones addObject:point1];
  long long hashForBlackSetupStone2 = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForBlackSetupStone2 == hashForBlackSetupStone1);

  // Remove black setup stones
  clearArrays();
  rootNode.zobristHash = hashForThreeBlackSetupStones;
  [previousBlackSetupStones addObject:point1];
  [previousBlackSetupStones addObject:point2];
  [previousBlackSetupStones addObject:point3];
  [noSetupStones addObject:point2];
  [noSetupStones addObject:point3];
  long long hashForBlackSetupStone3 = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForBlackSetupStone3 == hashForBlackSetupStone1);

  // Replace black setup stone with white setup stone
  clearArrays();
  rootNode.zobristHash = hashForBlackSetupStone1;
  [previousBlackSetupStones addObject:point1];
  [whiteSetupStones addObject:point1];
  long long hashForWhiteSetupStone2 = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForWhiteSetupStone2 == hashForWhiteSetupStone1);

  // Remove white setup stones
  clearArrays();
  rootNode.zobristHash = hashForThreeWhiteSetupStones;
  [previousWhiteSetupStones addObject:point1];
  [previousWhiteSetupStones addObject:point2];
  [previousWhiteSetupStones addObject:point3];
  [noSetupStones addObject:point2];
  [noSetupStones addObject:point3];
  long long hashForWhiteSetupStone3 = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForWhiteSetupStone3 == hashForWhiteSetupStone1);

  // Test that we can go back to an empty board by removing all stones. All
  // other use cases for noSetupStones have already been tested above.
  clearArrays();
  rootNode.zobristHash = hashForBlackAndWhiteSetupStone;
  [previousBlackSetupStones addObject:point1];
  [previousWhiteSetupStones addObject:point2];
  [noSetupStones addObject:point1];
  [noSetupStones addObject:point2];
  long long hashAfterRemovingAllStones = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashAfterRemovingAllStones == hashForEmptyBoard);

  // Test that nil can be specified for the previous node
  clearArrays();
  rootNode.zobristHash = 12345;
  [blackSetupStones addObject:point1];
  long long hashForBlackSetupStone4 = [zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:nil inGame:m_game];
  XCTAssertTrue(hashForBlackSetupStone4 == hashForBlackSetupStone1);

  clearArrays();
  [noSetupStones addObject:point4];
  XCTAssertThrowsSpecificNamed([zobristTable hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game],
                               NSException, NSInternalInconsistencyException, @"setup information is inconsistent");

  clearArrays();
  GoZobristTable* zobristTableWithDifferentBoardSize = [self zobristTableWithBoardSizeDifferentFromGame:m_game];
  XCTAssertThrowsSpecificNamed([zobristTableWithDifferentBoardSize hashForBlackSetupStones:blackSetupStones whiteSetupStones:whiteSetupStones noSetupStones:noSetupStones previousBlackSetupStones:previousBlackSetupStones previousWhiteSetupStones:previousWhiteSetupStones afterNode:rootNode inGame:m_game],
                               NSException, NSGenericException, @"hashForBlackSetupStones:whiteSetupStones:noSetupStones:previousBlackSetupStones:previousWhiteSetupStones:afterNode:inGame:() accepts wrong board size");
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
  GoNode* rootNode = nodeModel.rootNode;
  long long hashForEmptyBoard = 0;

  GoPoint* handicapPoint = [board pointAtVertex:@"A1"];
  GoPoint* whitePoint1 = [board pointAtVertex:@"A2"];
  GoPoint* whitePoint2 = [board pointAtVertex:@"B1"];
  long long hashForHandicapStoneAndOneWhiteStone = [zobristTable hashForBlackSetupStones:@[handicapPoint] whiteSetupStones:@[whitePoint1] noSetupStones:nil previousBlackSetupStones:nil previousWhiteSetupStones:nil afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForHandicapStoneAndOneWhiteStone != hashForEmptyBoard);
  long long hashForTwoWhiteStones = [zobristTable hashForBlackSetupStones:nil whiteSetupStones:@[whitePoint1, whitePoint2] noSetupStones:nil previousBlackSetupStones:nil previousWhiteSetupStones:nil afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForTwoWhiteStones != hashForEmptyBoard);

  m_game.handicapPoints = @[handicapPoint];
  long long hashForHandicap = [zobristTable hashForNode:nodeModel.rootNode inGame:m_game];
  XCTAssertTrue(hashForHandicap != hashForEmptyBoard);
  XCTAssertTrue(hashForHandicap == m_game.zobristHashAfterHandicap);
  XCTAssertTrue(hashForHandicap == rootNode.zobristHash);

  long long hashForWhiteMove1 = [zobristTable hashForStonePlayedByColor:GoColorWhite atPoint:whitePoint1 capturingStones:@[] afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForWhiteMove1 != hashForEmptyBoard);
  XCTAssertTrue(hashForWhiteMove1 != hashForHandicap);
  XCTAssertTrue(hashForWhiteMove1 == hashForHandicapStoneAndOneWhiteStone);

  rootNode.zobristHash = hashForWhiteMove1;
  long long hashForWhiteMove2 = [zobristTable hashForStonePlayedByColor:GoColorWhite atPoint:whitePoint2 capturingStones:@[handicapPoint] afterNode:rootNode inGame:m_game];
  XCTAssertTrue(hashForWhiteMove2 != hashForEmptyBoard);
  XCTAssertTrue(hashForWhiteMove2 != hashForHandicap);
  XCTAssertTrue(hashForWhiteMove2 != hashForWhiteMove1);
  XCTAssertTrue(hashForWhiteMove2 == hashForTwoWhiteStones);
  rootNode.zobristHash = hashForHandicap;

  rootNode.zobristHash = 12345;
  long long hashForWhiteMove3 = [zobristTable hashForStonePlayedByColor:GoColorWhite atPoint:whitePoint1 capturingStones:@[] afterNode:nil inGame:m_game];
  XCTAssertTrue(hashForWhiteMove3 == hashForHandicapStoneAndOneWhiteStone);

  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:GoColorNone atPoint:whitePoint1 capturingStones:@[] afterNode:rootNode inGame:m_game],
                               NSException, NSInvalidArgumentException, @"invalid GoColor argument");
  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:GoColorWhite atPoint:nil capturingStones:@[] afterNode:rootNode inGame:m_game],
                               NSException, NSInvalidArgumentException, @"point is nil");
  XCTAssertThrowsSpecificNamed([zobristTable hashForStonePlayedByColor:GoColorWhite atPoint:whitePoint1 capturingStones:@[] afterNode:rootNode inGame:nil],
                               NSException, NSInvalidArgumentException, @"game is nil");

  GoZobristTable* zobristTableWithDifferentBoardSize = [self zobristTableWithBoardSizeDifferentFromGame:m_game];
  XCTAssertThrowsSpecificNamed([zobristTableWithDifferentBoardSize hashForStonePlayedByColor:GoColorWhite atPoint:whitePoint1 capturingStones:@[] afterNode:nil inGame:m_game],
                               NSException, NSGenericException, @"hashForStonePlayedByColor:atPoint:capturingStones:afterMove:inGame:() accepts wrong board size");
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
  long long hashForMove1 = [zobristTable hashForNode:m_game.nodeModel.leafNode
                                              inGame:m_game];
  XCTAssertTrue(hashForMove1 != hashForEmptyBoard);

  [m_game pass];
  long long hashForMove2 = [zobristTable hashForNode:m_game.nodeModel.leafNode
                                              inGame:m_game];
  XCTAssertTrue(hashForMove2 != hashForEmptyBoard);
  XCTAssertEqual(hashForMove1, hashForMove2);
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
  long long hashForMove1 = [zobristTable hashForBoard:board];
  XCTAssertTrue(hashForMove1 != hashForEmptyBoard);
  [m_game play:point.right];
  long long hashForMove2 = [zobristTable hashForBoard:board];
  XCTAssertTrue(hashForMove2 != hashForEmptyBoard);
  XCTAssertTrue(hashForMove1 != hashForMove2);
  [m_game.lastMove undo];
  long long hash = [zobristTable hashForBoard:board];
  XCTAssertEqual(hashForMove1, hash);
  [m_game.lastMove doIt];
  hash = [zobristTable hashForBoard:board];
  XCTAssertEqual(hashForMove2, hash);
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated GoZobristTable object that was initialized
/// with a board size that is different from the size of the board in @a game.
///
/// Private helper for all the other test methods in this unit test class.
// -----------------------------------------------------------------------------
- (GoZobristTable*) zobristTableWithBoardSizeDifferentFromGame:(GoGame*)game
{
  GoBoard* board = m_game.board;

  enum GoBoardSize zobristTableBoardSize;
  if (board.size == GoBoardSize7)
    zobristTableBoardSize = GoBoardSize9;
  else
    zobristTableBoardSize = GoBoardSize7;

  return [[[GoZobristTable alloc] initWithBoardSize:zobristTableBoardSize] autorelease];
}

@end
