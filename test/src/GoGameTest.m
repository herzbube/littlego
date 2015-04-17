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
#import "GoGameTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoBoardRegion.h>
#import <go/GoGame.h>
#import <go/GoGameDocument.h>
#import <go/GoMove.h>
#import <go/GoMoveModel.h>
#import <go/GoPoint.h>
#import <go/GoUtilities.h>
#import <main/ApplicationDelegate.h>
#import <command/game/NewGameCommand.h>
#import <newGame/NewGameModel.h>


@implementation GoGameTest

// -----------------------------------------------------------------------------
/// @brief Exercises the sharedGame() class method.
// -----------------------------------------------------------------------------
- (void) testSharedGame
{
  XCTAssertEqual(m_game, [GoGame sharedGame]);
}

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of a GoGame object after it has been
/// created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  XCTAssertEqual(GoGameTypeHumanVsHuman, m_game.type, @"game type test failed");
  XCTAssertNotNil(m_game.board);
  NSUInteger handicapCount = 0;
  XCTAssertEqual(m_game.handicapPoints.count, handicapCount);
  XCTAssertEqual(m_game.komi, gDefaultKomiAreaScoring);
  XCTAssertNotNil(m_game.playerBlack);
  XCTAssertNotNil(m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  XCTAssertEqual(m_game.alternatingPlay, true);
  XCTAssertNil(m_game.firstMove);
  XCTAssertNil(m_game.lastMove);
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state, @"game state test failed");
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  XCTAssertFalse(m_game.isComputerThinking);
  XCTAssertEqual(GoGameComputerIsThinkingReasonIsNotThinking, m_game.reasonForComputerIsThinking);
  XCTAssertFalse(m_game.document.isDirty);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e type property.
// -----------------------------------------------------------------------------
- (void) testType
{
  XCTAssertEqual(GoGameTypeHumanVsHuman, m_game.type);
  // Nothing else that we can test for the moment
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e board property.
// -----------------------------------------------------------------------------
- (void) testBoard
{
  XCTAssertNotNil(m_game.board);
  // The only test that currently comes to mind is whether we can replace an
  // already existing GoBoard instance
  GoBoard* board = [GoBoard boardWithSize:GoBoardSize7];
  m_game.board = board;
  XCTAssertEqual(board, m_game.board);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e handicapPoints property.
// -----------------------------------------------------------------------------
- (void) testHandicapPoints
{
  NSUInteger handicapCount = 0;
  XCTAssertEqual(m_game.handicapPoints.count, handicapCount);

  NSMutableArray* handicapPoints = [NSMutableArray arrayWithCapacity:0];
  [handicapPoints setArray:[GoUtilities pointsForHandicap:5 inGame:m_game]];
  for (GoPoint* point in handicapPoints)
    XCTAssertEqual(GoColorNone, point.stoneState);
  // Setting the handicap points changes the GoPoint's stoneState
  m_game.handicapPoints = handicapPoints;
  // Changing handicapPoints now must not have any influence on the game's
  // handicap points, i.e. we expect that GoGame made a copy of handicapPoints
  [handicapPoints addObject:[m_game.board pointAtVertex:@"A1"]];
  // If GoGame made a copy, A1 will not be in the list that we get and the test
  // will succeed. If GoGame didn't make a copy, A1 will be in the list, but its
  // stoneState will still be GoColorNone, thus causing our test to fail.
  for (GoPoint* point in m_game.handicapPoints)
    XCTAssertEqual(GoColorBlack, point.stoneState);
  [handicapPoints removeObject:[m_game.board pointAtVertex:@"A1"]];

  // Must be possible to 1) set an empty array, and 2) change a previously set
  // handicap list
  m_game.handicapPoints = [NSArray array];
  // GoPoint object's that were previously set must have their stoneState reset
  for (GoPoint* point in handicapPoints)
    XCTAssertEqual(GoColorNone, point.stoneState);

  XCTAssertThrowsSpecificNamed(m_game.handicapPoints = nil,
                              NSException, NSInvalidArgumentException, @"point list is nil");
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertThrowsSpecificNamed(m_game.handicapPoints = handicapPoints,
                              NSException, NSInternalInconsistencyException, @"handicap set after first move");
  // Can set handicap if there are no moves
  [m_game.moveModel discardLastMove];
  m_game.handicapPoints = handicapPoints;
  [m_game resign];
  XCTAssertThrowsSpecificNamed(m_game.handicapPoints = handicapPoints,
                              NSException, NSInternalInconsistencyException, @"handicap set after game has ended");
  // Can set handicap if game has not ended
  [m_game revertStateFromEndedToInProgress];
  m_game.handicapPoints = handicapPoints;
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e nextMoveColor property.
///
/// Tests are almost equivalent to those in testSwitchNextMoveColor().
// -----------------------------------------------------------------------------
- (void) testNextMoveColor
{
  XCTAssertEqual(m_game.alternatingPlay, true);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  // We can force the first move to be by white
  m_game.nextMoveColor = GoColorWhite;
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  // We can force two consecutive moves by the same color
  m_game.nextMoveColor = GoColorWhite;
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  m_game.alternatingPlay = false;
  // Pass moves also work
  m_game.nextMoveColor = GoColorWhite;
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game pass];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  // Now that alternating play is disabled, we have full control over the
  // property
  m_game.nextMoveColor = GoColorBlack;
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  [m_game play:[m_game.board pointAtVertex:@"C1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  XCTAssertThrowsSpecificNamed(m_game.nextMoveColor = GoColorNone,
                               NSException, NSInvalidArgumentException, @"invalid color");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e nextMovePlayerIsComputerPlayer property.
// -----------------------------------------------------------------------------
- (void) testNextMovePlayerIsComputerPlayer
{
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertFalse(m_game.nextMovePlayerIsComputerPlayer);
  [m_game pass];
  XCTAssertFalse(m_game.nextMovePlayerIsComputerPlayer);
  [m_game.moveModel discardLastMove];
  XCTAssertFalse(m_game.nextMovePlayerIsComputerPlayer);
  [m_game pass];
  [m_game pass];
  XCTAssertFalse(m_game.nextMovePlayerIsComputerPlayer);

  // Currently no more tests possible because we can't simulate
  // computer vs. human games
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e nextMoveColor and @e nextMovePlayer properties while
/// the @e alternatingPlay property is true.
// -----------------------------------------------------------------------------
- (void) testAlternatingPlayEnabled
{
  XCTAssertEqual(m_game.alternatingPlay, true);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  m_game.handicapPoints = [GoUtilities pointsForHandicap:2 inGame:m_game];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  m_game.handicapPoints = [NSArray array];
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  [m_game pass];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game play:[m_game.board pointAtVertex:@"C1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  [m_game.moveModel discardLastMove];  // discard play move C1
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game.moveModel discardLastMove];  // discard pass move
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  // The current value of nextMoveColor is not relevant when discarding a move
  [m_game switchNextMoveColor];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game.moveModel discardLastMove];  // discard play move B1 made by white
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);

  // The color that made the last move is not relevant when playing a move
  [m_game switchNextMoveColor];
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  [m_game play:[m_game.board pointAtVertex:@"D1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e nextMoveColor and @e nextMovePlayer properties while
/// the @e alternatingPlay property is false.
// -----------------------------------------------------------------------------
- (void) testAlternatingPlayDisabled
{
  XCTAssertEqual(m_game.alternatingPlay, true);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  m_game.alternatingPlay = false;

  // Alternating play and handicap do not interact, i.e. after setting a
  // handicap the next move color is always white, after removing the handicap
  // the next move color is always black
  m_game.handicapPoints = [GoUtilities pointsForHandicap:3 inGame:m_game];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  m_game.handicapPoints = [NSArray array];
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  // Regular moves respect the disabled alternatingPlay property: the next move
  // color stays black
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  [m_game pass];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  // Switch to white, then test again that the disabled alternatingPlay property
  // is respected: the next move color stays white
  m_game.alternatingPlay = true;
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  m_game.alternatingPlay = false;
  [m_game play:[m_game.board pointAtVertex:@"C1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game pass];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);

  // Discards also respect the disabled alternatingPlay property: the next move
  // color stays white, even if it means going back to the start of the game
  [m_game.moveModel discardLastMove];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game.moveModel discardLastMove];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game.moveModel discardAllMoves];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e firstMove property.
// -----------------------------------------------------------------------------
- (void) testFirstMove
{
  XCTAssertNil(m_game.firstMove);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertNotNil(m_game.firstMove);
  [m_game.moveModel discardLastMove];
  XCTAssertNil(m_game.firstMove);
  // More detailed checks in testLastMove()
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e lastMove property.
// -----------------------------------------------------------------------------
- (void) testLastMove
{
  XCTAssertNil(m_game.lastMove);

  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  GoMove* move1 = m_game.lastMove;
  XCTAssertNotNil(move1);
  XCTAssertEqual(m_game.firstMove, move1);
  XCTAssertNil(move1.previous);
  XCTAssertNil(move1.next);

  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  GoMove* move2 = m_game.lastMove;
  XCTAssertNotNil(move2);
  XCTAssertTrue(m_game.firstMove != move2);
  XCTAssertNil(move1.previous);
  XCTAssertEqual(move2, move1.next);
  XCTAssertEqual(move1, move2.previous);
  XCTAssertNil(move2.next);

  [m_game.moveModel discardLastMove];
  XCTAssertEqual(move1, m_game.firstMove);
  XCTAssertEqual(move1, m_game.lastMove);

  [m_game.moveModel discardLastMove];
  XCTAssertNil(m_game.firstMove);
  XCTAssertNil(m_game.lastMove);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e state property.
// -----------------------------------------------------------------------------
- (void) testState
{
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  // There's no point in setting the state property directly because the
  // implementation does not check for correctness of the state machine, so
  // instead we manipulate the state indirectly by invoking other methods
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  [m_game.moveModel discardLastMove];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  [m_game resign];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e reasonForGameHasEnded property.
// -----------------------------------------------------------------------------
- (void) testReasonForGameHasEnded
{
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game resign];
  XCTAssertEqual(GoGameHasEndedReasonResigned, m_game.reasonForGameHasEnded);

  // Cannot undo a "resign", and we don't want to fiddle with game state, so
  // we must create a new game
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the play() method.
// -----------------------------------------------------------------------------
- (void) testPlay
{
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertFalse(m_game.document.isDirty);

  GoPoint* point1 = [m_game.board pointAtVertex:@"T19"];
  [m_game play:point1];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  GoMove* move1 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePlay, move1.type);
  XCTAssertEqual(m_game.playerBlack, move1.player);
  XCTAssertEqual(point1, move1.point);
  XCTAssertTrue(m_game.document.isDirty);

  GoPoint* point2 = [m_game.board pointAtVertex:@"S19"];
  [m_game play:point2];
  GoMove* move2 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePlay, move2.type);
  XCTAssertEqual(m_game.playerWhite, move2.player);
  XCTAssertEqual(point2, move2.point);

  [m_game pass];

  GoPoint* point3 = [m_game.board pointAtVertex:@"T18"];
  [m_game play:point3];
  GoMove* move3 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePlay, move3.type);
  XCTAssertEqual(m_game.playerWhite, move3.player);
  XCTAssertEqual(point3, move3.point);
  NSUInteger expectedNumberOfCapturedStones = 1;
  XCTAssertEqual(expectedNumberOfCapturedStones, move3.capturedStones.count);

  XCTAssertThrowsSpecificNamed([m_game play:nil],
                              NSException, NSInvalidArgumentException, @"point is nil");
  XCTAssertThrowsSpecificNamed([m_game play:point1],
                              NSException, NSInvalidArgumentException, @"point is not legal");
  [m_game resign];
  XCTAssertThrowsSpecificNamed([m_game play:[m_game.board pointAtVertex:@"B1"]],
                              NSException, NSInternalInconsistencyException, @"play after game end");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pass() method.
// -----------------------------------------------------------------------------
- (void) testPass
{
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertFalse(m_game.document.isDirty);

  // Can start game with a pass
  [m_game pass];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  GoMove* move1 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePass, move1.type);
  XCTAssertEqual(m_game.playerBlack, move1.player);
  XCTAssertNil(move1.point);
  XCTAssertTrue(m_game.document.isDirty);

  [m_game play:[m_game.board pointAtVertex:@"B13"]];

  [m_game pass];
  GoMove* move2 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePass, move2.type);
  XCTAssertEqual(m_game.playerBlack, move2.player);
  XCTAssertNil(move2.point);

  // End the game with two passes in a row
  [m_game pass];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
  GoMove* move3 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePass, move3.type);
  XCTAssertEqual(m_game.playerWhite, move3.player);
  XCTAssertNil(move3.point);

  XCTAssertThrowsSpecificNamed([m_game pass],
                              NSException, NSInternalInconsistencyException, @"pass after game end");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the resign() method.
// -----------------------------------------------------------------------------
- (void) testResign
{
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertFalse(m_game.document.isDirty);

  // Can start game with resign
  [m_game resign];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
  XCTAssertTrue(m_game.document.isDirty);
  // Resign in other situations already tested

  XCTAssertThrowsSpecificNamed([m_game resign],
                              NSException, NSInternalInconsistencyException, @"resign after game end");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pause() method.
// -----------------------------------------------------------------------------
- (void) testPause
{
  [m_game pass];
  XCTAssertThrowsSpecificNamed([m_game pause],
                              NSException, NSInternalInconsistencyException, @"no computer vs. computer game");
  [m_game pass];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
  XCTAssertThrowsSpecificNamed([m_game pause],
                              NSException, NSInternalInconsistencyException, @"pause after game end");
  
  // Currently no more tests possible because we can't simulate
  // computer vs. computer games
}

// -----------------------------------------------------------------------------
/// @brief Exercises the continue() method.
// -----------------------------------------------------------------------------
- (void) testContinue
{
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertThrowsSpecificNamed([m_game continue],
                              NSException, NSInternalInconsistencyException, @"continue before game start");
  [m_game pass];
  XCTAssertThrowsSpecificNamed([m_game continue],
                              NSException, NSInternalInconsistencyException, @"no computer vs. computer game");
  [m_game pass];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
  XCTAssertThrowsSpecificNamed([m_game continue],
                              NSException, NSInternalInconsistencyException, @"continue after game end");

  // Currently no more tests possible because we can't simulate
  // computer vs. computer games
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isLegalMove() method (including simple ko scenarios).
// -----------------------------------------------------------------------------
- (void) testIsLegalMove
{
  enum GoMoveIsIllegalReason illegalReason;

  // Unoccupied point is legal for both players
  GoPoint* point1 = [m_game.board pointAtVertex:@"T1"];
  XCTAssertTrue([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  [m_game pass];
  XCTAssertTrue([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);

  // Play it with black
  [m_game.moveModel discardLastMove];
  [m_game play:point1];

  // Point occupied by black is not legal for either player
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonIntersectionOccupied);
  [m_game pass];
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonIntersectionOccupied);

  // Play stone with white
  [m_game.moveModel discardLastMove];
  GoPoint* point2 = [m_game.board pointAtVertex:@"S1"];
  [m_game play:point2];

  // Point occupied by white is not legal for either player
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonIntersectionOccupied);
  [m_game pass];
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonIntersectionOccupied);

  // Play capturing stone stone with white
  GoPoint* point3 = [m_game.board pointAtVertex:@"T2"];
  [m_game play:point3];

  // Original point not legal for black, is suicide
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSuicide);
  // But legal for white, just a fill
  [m_game pass];
  XCTAssertTrue([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);

  // Counter-attack by black to create Ko situation
  [m_game.moveModel discardLastMove];
  GoPoint* point4 = [m_game.board pointAtVertex:@"R1"];
  [m_game play:point4];
  [m_game pass];
  GoPoint* point5 = [m_game.board pointAtVertex:@"S2"];
  [m_game play:point5];
  [m_game pass];

  // Original point now legal for black, is no longer suicide
  XCTAssertTrue([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  [m_game play:point1];

  // Not legal for white because of Ko
  XCTAssertFalse([m_game isLegalMove:point2 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSimpleKo);

  // White passes, black plays somewhere else
  [m_game pass];
  GoPoint* point6 = [m_game.board pointAtVertex:@"A19"];
  [m_game play:point6];

  // Again legal for white because Ko has gone
  XCTAssertTrue([m_game isLegalMove:point2 isIllegalReason:&illegalReason]);
  [m_game play:point2];
  // Not legal for black, again because of Ko
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSimpleKo);

  // Black passes, white connects
  [m_game pass];
  [m_game play:point1];


  // Setup situation that resembles Ko, but is not, because it allows to
  // capture back more than 1 stone
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game play:[m_game.board pointAtVertex:@"A2"]];
  [m_game play:[m_game.board pointAtVertex:@"D1"]];
  [m_game play:[m_game.board pointAtVertex:@"B2"]];
  [m_game play:[m_game.board pointAtVertex:@"C2"]];
  GoPoint* point7 = [m_game.board pointAtVertex:@"C1"];
  [m_game play:point7];
  // Is legal for black, captures C1
  GoPoint* point8 = [m_game.board pointAtVertex:@"B1"];
  XCTAssertTrue([m_game isLegalMove:point8 isIllegalReason:&illegalReason]);
  [m_game play:point8];
  // Is legal for white, captures back A1 and B1 (no Ko!)
  XCTAssertTrue([m_game isLegalMove:point7 isIllegalReason:&illegalReason]);
  [m_game play:point7];

  // Setup situation that resembles Ko, but is not, because it's not a
  // repetition of the board position: Black first captures two white stones,
  // then recaptures only one white stone
  [m_game play:[m_game.board pointAtVertex:@"Q18"]];
  [m_game play:[m_game.board pointAtVertex:@"R18"]];
  [m_game play:[m_game.board pointAtVertex:@"R17"]];
  [m_game play:[m_game.board pointAtVertex:@"S18"]];
  [m_game play:[m_game.board pointAtVertex:@"S17"]];
  [m_game pass];
  [m_game play:[m_game.board pointAtVertex:@"R19"]];
  [m_game pass];
  [m_game play:[m_game.board pointAtVertex:@"S19"]];
  [m_game pass];
  // Black captures two white stones
  [m_game play:[m_game.board pointAtVertex:@"T18"]];
  // White plays inside the black enclosure, with only one liberty
  [m_game play:[m_game.board pointAtVertex:@"R18"]];
  // Is legal for black, recaptures white stone on R18
  GoPoint* point9 = [m_game.board pointAtVertex:@"S18"];
  XCTAssertTrue([m_game isLegalMove:point9 isIllegalReason:&illegalReason]);
  [m_game play:point9];

  XCTAssertThrowsSpecificNamed([m_game isLegalMove:nil isIllegalReason:&illegalReason],
                              NSException, NSInvalidArgumentException, @"point is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isLegalMove() method (only positional superko
/// scenarios).
// -----------------------------------------------------------------------------
- (void) testIsLegalMovePositionalSuperko
{
  NewGameModel* newGameModel = m_delegate.theNewGameModel;
  newGameModel.koRule = GoKoRuleSuperkoPositional;
  enum GoMoveIsIllegalReason illegalReason;

  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  [self playUntilAlmostPositionalSuperko];
  GoPoint* point1 = [m_game.board pointAtVertex:@"B1"];
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSuperko);

  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  [self playUntilAlmostSituationalSuperko];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  XCTAssertFalse([m_game isLegalMove:point2 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSuperko);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isLegalMove() method (only situational superko
/// scenarios).
// -----------------------------------------------------------------------------
- (void) testIsLegalMoveSituationalSuperko
{
  NewGameModel* newGameModel = m_delegate.theNewGameModel;
  newGameModel.koRule = GoKoRuleSuperkoSituational;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  enum GoMoveIsIllegalReason illegalReason;

  [self playUntilAlmostPositionalSuperko];
  GoPoint* point1 = [m_game.board pointAtVertex:@"B1"];
  // Positional superko does not trigger situational superko
  XCTAssertTrue([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);

  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  [self playUntilAlmostSituationalSuperko];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  XCTAssertFalse([m_game isLegalMove:point2 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSuperko);
}

// -----------------------------------------------------------------------------
/// @brief Private helper method of testIsLegalMovePositionalSuperko() and
/// testIsLegalMoveSituationalSuperko().
// -----------------------------------------------------------------------------
- (void) playUntilAlmostPositionalSuperko
{
  [m_game play:[m_game.board pointAtVertex:@"B1"]];  // move 1
  [m_game play:[m_game.board pointAtVertex:@"A2"]];  // move 2
  [m_game play:[m_game.board pointAtVertex:@"C2"]];  // move 3
  [m_game play:[m_game.board pointAtVertex:@"B2"]];  // move 4
  [m_game play:[m_game.board pointAtVertex:@"D1"]];  // move 5
  // White does NOT pass, i.e. white contributes to the board position.
  [m_game play:[m_game.board pointAtVertex:@"D2"]];  // move 6
  [m_game play:[m_game.board pointAtVertex:@"A1"]];  // move 7
  [m_game play:[m_game.board pointAtVertex:@"C1"]];  // move 8, capture A1+A2
  // Black's next move at B1 captures C1 and recreates the board position after
  // move 6. This triggers positional superko. This does NOT trigger situational
  // superko because it was white - not black - who created the board position
  // in move 6.
}

// -----------------------------------------------------------------------------
/// @brief Private helper method of testIsLegalMovePositionalSuperko() and
/// testIsLegalMoveSituationalSuperko().
// -----------------------------------------------------------------------------
- (void) playUntilAlmostSituationalSuperko
{
  [m_game play:[m_game.board pointAtVertex:@"B1"]];  // move 1
  [m_game play:[m_game.board pointAtVertex:@"A2"]];  // move 2
  [m_game play:[m_game.board pointAtVertex:@"C2"]];  // move 3
  [m_game play:[m_game.board pointAtVertex:@"B2"]];  // move 4
  [m_game play:[m_game.board pointAtVertex:@"D1"]];  // move 5
  // White passes, i.e. white does NOT contribute to the board position
  [m_game pass];                                     // move 6
  [m_game play:[m_game.board pointAtVertex:@"A1"]];  // move 7
  [m_game play:[m_game.board pointAtVertex:@"C1"]];  // move 8, capture A1+A2
  // Black's next move at B1 captures C1 and recreates the board position after
  // move 5. This triggers situational superko because it was also black who
  // created the board position in move 5. This also triggers positional superko
  // because positional superko is less strict than situational superko and does
  // not care who creates board positions.
}

// -----------------------------------------------------------------------------
/// @brief Exercises the revertStateFromEndedToInProgress() method.
// -----------------------------------------------------------------------------
- (void) testRevertStateFromEndedToInProgress
{
  XCTAssertEqual(GoGameTypeHumanVsHuman, m_game.type);
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  [m_game pass];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  [m_game pass];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
  XCTAssertTrue(m_game.document.isDirty);
  m_game.document.dirty = false;
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertFalse(m_game.document.isDirty);

  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertFalse(m_game.document.isDirty);
  [m_game resign];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
  XCTAssertTrue(m_game.document.isDirty);
  m_game.document.dirty = false;
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertTrue(m_game.document.isDirty);

  XCTAssertThrowsSpecificNamed([m_game revertStateFromEndedToInProgress],
                              NSException, NSInternalInconsistencyException, @"game already reverted");

  // Currently no more tests possible because we can't simulate
  // computer vs. computer games
}

// -----------------------------------------------------------------------------
/// @brief Exercises the switchNextMoveColor() method.
///
/// Tests are almost equivalent to those in testNextMoveColor().
// -----------------------------------------------------------------------------
- (void) testSwitchNextMoveColor
{
  XCTAssertEqual(m_game.alternatingPlay, true);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  // We can force the first move to be by white
  [m_game switchNextMoveColor];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  // We can force two consecutive moves by the same color
  [m_game switchNextMoveColor];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  m_game.alternatingPlay = false;
  // Pass moves also work
  [m_game switchNextMoveColor];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game pass];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  // Now that alternating play is disabled, we have full control over the
  // property
  [m_game switchNextMoveColor];
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  [m_game play:[m_game.board pointAtVertex:@"C1"]];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
}

// -----------------------------------------------------------------------------
/// @brief Regression test for bug 137.
///
/// Set up a position where 4 regions, each consisting of a single stone, are
/// merged into a new single region, by placing a single connecting stone. The
/// connecting stone is then removed by discarding the move, which must result
/// in the same 4 regions being re-created.
/// - Single stone regions: A2, B1, B3, C2
/// - Connecting stone: B2
// -----------------------------------------------------------------------------
- (void) testDiscardCausesRegionToFragment
{
  GoPoint* point1 = [m_game.board pointAtVertex:@"A2"];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  GoPoint* point3 = [m_game.board pointAtVertex:@"B3"];
  GoPoint* point4 = [m_game.board pointAtVertex:@"C2"];
  GoPoint* point5 = [m_game.board pointAtVertex:@"B2"];
  GoPoint* pointInMainRegion = [m_game.board pointAtVertex:@"A3"];

  // Set up the initial position
  [m_game play:point1];
  [m_game pass];
  [m_game play:point2];
  [m_game pass];
  [m_game play:point3];
  [m_game pass];
  [m_game play:point4];
  [m_game pass];
  [self verifyFragmentedRegionsOfTestDiscardCausesRegionToFragment:@"initial setup"];

  // Play the connecting stone
  [m_game play:point5];
  XCTAssertEqual(GoColorBlack, point5.stoneState);
  NSUInteger expectedNumberOfRegionsWhenMerged = 3;
  XCTAssertEqual(expectedNumberOfRegionsWhenMerged, m_game.board.regions.count);
  GoBoardRegion* mergedRegion = point1.region;
  GoBoardRegion* mainRegion = pointInMainRegion.region;
  XCTAssertTrue(mergedRegion == point2.region);
  XCTAssertTrue(mergedRegion == point3.region);
  XCTAssertTrue(mergedRegion == point4.region);
  XCTAssertTrue(mergedRegion == point5.region);
  XCTAssertTrue(mergedRegion != mainRegion);
  int expectedSizeOfRegionWhenMerged = 5;
  XCTAssertEqual(expectedSizeOfRegionWhenMerged, [mergedRegion size]);

  // Remove the connecting stone
  GoMove* lastMove = m_game.lastMove;
  [lastMove undo];
  [self verifyFragmentedRegionsOfTestDiscardCausesRegionToFragment:@"after undoing"];
}

// -----------------------------------------------------------------------------
/// @brief Private helper method of testDiscardCausesRegionToFragment(). Verifies
/// the correctness of region fragmentation twice: Once before the connecting
/// move is made, and and once after the connecting move has been discarded.
// -----------------------------------------------------------------------------
- (void) verifyFragmentedRegionsOfTestDiscardCausesRegionToFragment:(NSString*)failureDescription
{
  GoPoint* point1 = [m_game.board pointAtVertex:@"A2"];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  GoPoint* point3 = [m_game.board pointAtVertex:@"B3"];
  GoPoint* point4 = [m_game.board pointAtVertex:@"C2"];
  GoPoint* point5 = [m_game.board pointAtVertex:@"B2"];
  GoPoint* pointInMainRegion = [m_game.board pointAtVertex:@"A3"];

  XCTAssertEqual(GoColorBlack, point1.stoneState, @"%@", failureDescription);
  XCTAssertEqual(GoColorBlack, point2.stoneState, @"%@", failureDescription);
  XCTAssertEqual(GoColorBlack, point3.stoneState, @"%@", failureDescription);
  XCTAssertEqual(GoColorBlack, point4.stoneState, @"%@", failureDescription);
  XCTAssertEqual(GoColorNone, point5.stoneState, @"%@", failureDescription);
  NSUInteger expectedNumberOfRegionsWhenFragmented = 7;
  XCTAssertEqual(expectedNumberOfRegionsWhenFragmented, m_game.board.regions.count, @"%@", failureDescription);
  GoBoardRegion* point1Region = point1.region;
  GoBoardRegion* point2Region = point2.region;
  GoBoardRegion* point3Region = point3.region;
  GoBoardRegion* point4Region = point4.region;
  GoBoardRegion* point5Region = point5.region;
  GoBoardRegion* mainRegion = pointInMainRegion.region;
  XCTAssertTrue(point1Region != point2Region, @"%@", failureDescription);
  XCTAssertTrue(point1Region != point3Region, @"%@", failureDescription);
  XCTAssertTrue(point1Region != point4Region, @"%@", failureDescription);
  XCTAssertTrue(point1Region != point5Region, @"%@", failureDescription);
  XCTAssertTrue(point1Region != mainRegion, @"%@", failureDescription);
  XCTAssertTrue(point2Region != point3Region, @"%@", failureDescription);
  XCTAssertTrue(point2Region != point4Region, @"%@", failureDescription);
  XCTAssertTrue(point2Region != point5Region, @"%@", failureDescription);
  XCTAssertTrue(point2Region != mainRegion, @"%@", failureDescription);
  XCTAssertTrue(point3Region != point4Region, @"%@", failureDescription);
  XCTAssertTrue(point3Region != point5Region, @"%@", failureDescription);
  XCTAssertTrue(point3Region != mainRegion, @"%@", failureDescription);
  XCTAssertTrue(point4Region != point5Region, @"%@", failureDescription);
  XCTAssertTrue(point4Region != mainRegion, @"%@", failureDescription);
  XCTAssertTrue(point5Region != mainRegion, @"%@", failureDescription);
  int expectedSizeOfRegionsWhenFragmented = 1;
  XCTAssertEqual(expectedSizeOfRegionsWhenFragmented, [point1Region size], @"%@", failureDescription);
  XCTAssertEqual(expectedSizeOfRegionsWhenFragmented, [point2Region size], @"%@", failureDescription);
  XCTAssertEqual(expectedSizeOfRegionsWhenFragmented, [point3Region size], @"%@", failureDescription);
  XCTAssertEqual(expectedSizeOfRegionsWhenFragmented, [point4Region size], @"%@", failureDescription);
  XCTAssertEqual(expectedSizeOfRegionsWhenFragmented, [point5Region size], @"%@", failureDescription);
}

// -----------------------------------------------------------------------------
/// @brief Regression test for GitHub issue 2 ("Ko is erroneously detected
/// (again)"). Exercises the isLegalMove().
// -----------------------------------------------------------------------------
- (void) testIssue2
{
  [m_game play:[m_game.board pointAtVertex:@"A2"]];
  [m_game play:[m_game.board pointAtVertex:@"B2"]];
  [m_game pass];
  [m_game play:[m_game.board pointAtVertex:@"C1"]];
  [m_game pass];
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  // Black captures a single white stone that was played in the previous move
  GoPoint* point1 = [m_game.board pointAtVertex:@"B1"];
  enum GoMoveIsIllegalReason illegalReason;
  XCTAssertTrue([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  [m_game play:point1];
}


@end
