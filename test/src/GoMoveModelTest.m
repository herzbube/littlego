// -----------------------------------------------------------------------------
// Copyright 2012-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoMoveModelTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoGame.h>
#import <go/GoGameDocument.h>
#import <go/GoMove.h>
#import <go/GoMoveModel.h>
#import <go/GoPoint.h>


@implementation GoMoveModelTest


// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoMoveModel object after a new
/// GoGame has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoMoveModel* moveModel = m_game.moveModel;
  XCTAssertNotNil(moveModel);
  XCTAssertEqual(moveModel.numberOfMoves, 0);
  XCTAssertNil(moveModel.firstMove);
  XCTAssertNil(moveModel.lastMove);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the appendMove:() method.
// -----------------------------------------------------------------------------
- (void) testAppendMove
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move1.point = [m_game.board pointAtVertex:@"A1"];
  XCTAssertEqual(moveModel.numberOfMoves, 0);
  XCTAssertFalse(m_game.document.isDirty);
  [moveModel appendMove:move1];
  XCTAssertEqual(moveModel.numberOfMoves, 1);
  XCTAssertTrue(m_game.document.isDirty);

  XCTAssertThrowsSpecificNamed([moveModel appendMove:nil],
                              NSException, NSInvalidArgumentException, @"appendMove with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardLastMove() method.
// -----------------------------------------------------------------------------
- (void) testDiscardLastMove
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move1.point = [m_game.board pointAtVertex:@"A1"];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  XCTAssertEqual(moveModel.numberOfMoves, 0);
  [moveModel appendMove:move1];
  XCTAssertEqual(moveModel.numberOfMoves, 1);
  [moveModel appendMove:move2];
  XCTAssertEqual(moveModel.numberOfMoves, 2);
  XCTAssertTrue(m_game.document.isDirty);
  m_game.document.dirty = false;

  [moveModel discardLastMove];
  XCTAssertEqual(moveModel.numberOfMoves, 1);
  XCTAssertTrue(m_game.document.isDirty);
  [moveModel discardLastMove];
  XCTAssertEqual(moveModel.numberOfMoves, 0);

  XCTAssertThrowsSpecificNamed([moveModel discardLastMove],
                              NSException, NSRangeException, @"discardLastMove with no moves");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardMovesFromIndex:() method.
// -----------------------------------------------------------------------------
- (void) testDiscardMovesFromIndex
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move1.point = [m_game.board pointAtVertex:@"A1"];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  GoMove* move3 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:move2];
  [moveModel appendMove:move1];
  [moveModel appendMove:move2];
  [moveModel appendMove:move3];
  XCTAssertEqual(moveModel.numberOfMoves, 3);
  XCTAssertTrue(m_game.document.isDirty);
  m_game.document.dirty = false;

  XCTAssertThrowsSpecificNamed([moveModel discardMovesFromIndex:3],
                              NSException, NSRangeException, @"discardMovesFromIndex with index too high");
  XCTAssertEqual(moveModel.numberOfMoves, 3);
  XCTAssertThrowsSpecificNamed([moveModel discardMovesFromIndex:-1],
                              NSException, NSRangeException, @"discardMovesFromIndex with negative index");
  XCTAssertEqual(moveModel.numberOfMoves, 3);
  XCTAssertFalse(m_game.document.isDirty);
  [moveModel discardMovesFromIndex:1];  // discard >1 moves
  XCTAssertEqual(moveModel.numberOfMoves, 1);
  XCTAssertTrue(m_game.document.isDirty);
  [moveModel discardMovesFromIndex:0];  // discard single move
  XCTAssertEqual(moveModel.numberOfMoves, 0);

  XCTAssertThrowsSpecificNamed([moveModel discardMovesFromIndex:0],
                              NSException, NSRangeException, @"discardMovesFromIndex when model has no moves");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardAllMoves() method.
// -----------------------------------------------------------------------------
- (void) testDiscardAllMoves
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move1.point = [m_game.board pointAtVertex:@"A1"];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  GoMove* move3 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:move2];
  [moveModel appendMove:move1];
  [moveModel appendMove:move2];
  [moveModel appendMove:move3];
  XCTAssertEqual(moveModel.numberOfMoves, 3);
  XCTAssertTrue(m_game.document.isDirty);
  m_game.document.dirty = false;

  [moveModel discardAllMoves];
  XCTAssertEqual(moveModel.numberOfMoves, 0);
  XCTAssertTrue(m_game.document.isDirty);

  XCTAssertThrowsSpecificNamed([moveModel discardAllMoves],
                              NSException, NSRangeException, @"discardAllMoves with no moves");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the moveAtIndex:() method.
// -----------------------------------------------------------------------------
- (void) testMoveAtIndex
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  GoMove* move3 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:move2];
  [moveModel appendMove:move1];
  [moveModel appendMove:move2];
  [moveModel appendMove:move3];
  XCTAssertEqual(moveModel.numberOfMoves, 3);
  XCTAssertEqual(move1, [moveModel moveAtIndex:0]);
  XCTAssertEqual(move2, [moveModel moveAtIndex:1]);
  XCTAssertEqual(move3, [moveModel moveAtIndex:2]);
  XCTAssertThrowsSpecificNamed([moveModel moveAtIndex:3],
                              NSException, NSRangeException, @"moveAtIndex when model has moves");
  XCTAssertThrowsSpecificNamed([moveModel moveAtIndex:-1],
                              NSException, NSRangeException, @"moveAtIndex with negative index");
  [moveModel discardAllMoves];
  XCTAssertEqual(moveModel.numberOfMoves, 0);
  XCTAssertThrowsSpecificNamed([moveModel moveAtIndex:0],
                              NSException, NSRangeException, @"moveAtIndex when model has no moves");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e numberOfMoves property.
// -----------------------------------------------------------------------------
- (void) testNumberOfMoves
{
  GoMoveModel* moveModel = m_game.moveModel;
  XCTAssertEqual(moveModel.numberOfMoves, 0);
  GoMove* move1 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  [moveModel appendMove:move1];
  XCTAssertEqual(moveModel.numberOfMoves, 1);
  [moveModel discardAllMoves];
  XCTAssertEqual(moveModel.numberOfMoves, 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e firstMove property.
// -----------------------------------------------------------------------------
- (void) testFirstMove
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  XCTAssertNil(moveModel.firstMove);
  [moveModel appendMove:move1];
  XCTAssertEqual(move1, moveModel.firstMove);
  [moveModel appendMove:move2];
  XCTAssertEqual(move1, moveModel.firstMove);
  [moveModel discardLastMove];
  XCTAssertEqual(move1, moveModel.firstMove);
  [moveModel discardAllMoves];
  XCTAssertNil(moveModel.firstMove);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e lastMove property.
// -----------------------------------------------------------------------------
- (void) testLastMove
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  XCTAssertNil(moveModel.lastMove);
  [moveModel appendMove:move1];
  XCTAssertEqual(move1, moveModel.lastMove);
  [moveModel appendMove:move2];
  XCTAssertEqual(move2, moveModel.lastMove);
  [moveModel discardAllMoves];
  XCTAssertNil(moveModel.firstMove);
}

@end
