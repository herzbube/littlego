// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
  STAssertNotNil(moveModel, nil);
  STAssertEquals(moveModel.numberOfMoves, 0, nil);
  STAssertNil(moveModel.firstMove, nil);
  STAssertNil(moveModel.lastMove, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the appendMove:() method.
// -----------------------------------------------------------------------------
- (void) testAppendMove
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePlay by:m_game.playerBlack after:nil];
  move1.point = [m_game.board pointAtVertex:@"A1"];
  STAssertEquals(moveModel.numberOfMoves, 0, nil);
  STAssertFalse(m_game.document.isDirty, nil);
  [moveModel appendMove:move1];
  STAssertEquals(moveModel.numberOfMoves, 1, nil);
  STAssertTrue(m_game.document.isDirty, nil);

  STAssertThrowsSpecificNamed([moveModel appendMove:nil],
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
  STAssertEquals(moveModel.numberOfMoves, 0, nil);
  [moveModel appendMove:move1];
  STAssertEquals(moveModel.numberOfMoves, 1, nil);
  [moveModel appendMove:move2];
  STAssertEquals(moveModel.numberOfMoves, 2, nil);
  STAssertTrue(m_game.document.isDirty, nil);
  m_game.document.dirty = false;

  [moveModel discardLastMove];
  STAssertEquals(moveModel.numberOfMoves, 1, nil);
  STAssertTrue(m_game.document.isDirty, nil);
  [moveModel discardLastMove];
  STAssertEquals(moveModel.numberOfMoves, 0, nil);

  STAssertThrowsSpecificNamed([moveModel discardLastMove],
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
  STAssertEquals(moveModel.numberOfMoves, 3, nil);
  STAssertTrue(m_game.document.isDirty, nil);
  m_game.document.dirty = false;

  STAssertThrowsSpecificNamed([moveModel discardMovesFromIndex:3],
                              NSException, NSRangeException, @"discardMovesFromIndex with index too high");
  STAssertEquals(moveModel.numberOfMoves, 3, nil);
  STAssertThrowsSpecificNamed([moveModel discardMovesFromIndex:-1],
                              NSException, NSRangeException, @"discardMovesFromIndex with negative index");
  STAssertEquals(moveModel.numberOfMoves, 3, nil);
  STAssertFalse(m_game.document.isDirty, nil);
  [moveModel discardMovesFromIndex:1];  // discard >1 moves
  STAssertEquals(moveModel.numberOfMoves, 1, nil);
  STAssertTrue(m_game.document.isDirty, nil);
  [moveModel discardMovesFromIndex:0];  // discard single move
  STAssertEquals(moveModel.numberOfMoves, 0, nil);

  STAssertThrowsSpecificNamed([moveModel discardMovesFromIndex:0],
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
  STAssertEquals(moveModel.numberOfMoves, 3, nil);
  STAssertTrue(m_game.document.isDirty, nil);
  m_game.document.dirty = false;

  [moveModel discardAllMoves];
  STAssertEquals(moveModel.numberOfMoves, 0, nil);
  STAssertTrue(m_game.document.isDirty, nil);

  STAssertThrowsSpecificNamed([moveModel discardAllMoves],
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
  STAssertEquals(moveModel.numberOfMoves, 3, nil);
  STAssertEquals(move1, [moveModel moveAtIndex:0], nil);
  STAssertEquals(move2, [moveModel moveAtIndex:1], nil);
  STAssertEquals(move3, [moveModel moveAtIndex:2], nil);
  STAssertThrowsSpecificNamed([moveModel moveAtIndex:3],
                              NSException, NSRangeException, @"moveAtIndex when model has moves");
  STAssertThrowsSpecificNamed([moveModel moveAtIndex:-1],
                              NSException, NSRangeException, @"moveAtIndex with negative index");
  [moveModel discardAllMoves];
  STAssertEquals(moveModel.numberOfMoves, 0, nil);
  STAssertThrowsSpecificNamed([moveModel moveAtIndex:0],
                              NSException, NSRangeException, @"moveAtIndex when model has no moves");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e numberOfMoves property.
// -----------------------------------------------------------------------------
- (void) testNumberOfMoves
{
  GoMoveModel* moveModel = m_game.moveModel;
  STAssertEquals(moveModel.numberOfMoves, 0, nil);
  GoMove* move1 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  [moveModel appendMove:move1];
  STAssertEquals(moveModel.numberOfMoves, 1, nil);
  [moveModel discardAllMoves];
  STAssertEquals(moveModel.numberOfMoves, 0, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e firstMove property.
// -----------------------------------------------------------------------------
- (void) testFirstMove
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  STAssertNil(moveModel.firstMove, nil);
  [moveModel appendMove:move1];
  STAssertEquals(move1, moveModel.firstMove, nil);
  [moveModel appendMove:move2];
  STAssertEquals(move1, moveModel.firstMove, nil);
  [moveModel discardLastMove];
  STAssertEquals(move1, moveModel.firstMove, nil);
  [moveModel discardAllMoves];
  STAssertNil(moveModel.firstMove, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e lastMove property.
// -----------------------------------------------------------------------------
- (void) testLastMove
{
  GoMoveModel* moveModel = m_game.moveModel;
  GoMove* move1 = [GoMove move:GoMoveTypePass by:m_game.playerBlack after:nil];
  GoMove* move2 = [GoMove move:GoMoveTypePass by:m_game.playerWhite after:move1];
  STAssertNil(moveModel.lastMove, nil);
  [moveModel appendMove:move1];
  STAssertEquals(move1, moveModel.lastMove, nil);
  [moveModel appendMove:move2];
  STAssertEquals(move2, moveModel.lastMove, nil);
  [moveModel discardAllMoves];
  STAssertNil(moveModel.firstMove, nil);
}

@end
