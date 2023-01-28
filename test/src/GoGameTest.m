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
#import "GoGameTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoBoardPosition.h>
#import <go/GoBoardRegion.h>
#import <go/GoGame.h>
#import <go/GoGameDocument.h>
#import <go/GoMove.h>
#import <go/GoMoveAdditions.h>
#import <go/GoMoveNodeCreationOptions.h>
#import <go/GoNode.h>
#import <go/GoNodeAdditions.h>
#import <go/GoNodeModel.h>
#import <go/GoNodeSetup.h>
#import <go/GoPoint.h>
#import <go/GoUtilities.h>
#import <main/ApplicationDelegate.h>
#import <command/game/NewGameCommand.h>
#import <newgame/NewGameModel.h>
#import <utility/NSArrayAdditions.h>


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
  XCTAssertFalse(m_game.nextMovePlayerIsComputerPlayer);
  XCTAssertEqual(m_game.alternatingPlay, true);
  XCTAssertNotNil(m_game.nodeModel);
  XCTAssertNil(m_game.firstMove);
  XCTAssertNil(m_game.lastMove);
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state, @"game state test failed");
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  XCTAssertFalse(m_game.isComputerThinking);
  XCTAssertEqual(GoGameComputerIsThinkingReasonIsNotThinking, m_game.reasonForComputerIsThinking);
  XCTAssertNotNil(m_game.boardPosition);
  XCTAssertNotNil(m_game.rules);
  XCTAssertNotNil(m_game.document);
  XCTAssertFalse(m_game.document.isDirty);
  XCTAssertNotNil(m_game.score);
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorNone);
  long long hashForEmptyBoard = 0;
  XCTAssertEqual(m_game.zobristHashAfterHandicap, hashForEmptyBoard);
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
  XCTAssertEqual(m_game.zobristHashAfterHandicap, 0);
  XCTAssertEqual(m_game.zobristHashAfterHandicap, m_game.nodeModel.rootNode.zobristHash);

  NSMutableArray* handicapPoints = [NSMutableArray arrayWithCapacity:0];
  [handicapPoints setArray:[GoUtilities pointsForHandicap:5 inGame:m_game]];
  for (GoPoint* point in handicapPoints)
    XCTAssertEqual(GoColorNone, point.stoneState);
  // Setting the handicap points changes the GoPoint's stoneState
  m_game.handicapPoints = handicapPoints;
  XCTAssertNotEqual(m_game.zobristHashAfterHandicap, 0);
  XCTAssertEqual(m_game.zobristHashAfterHandicap, m_game.nodeModel.rootNode.zobristHash);
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
  m_game.handicapPoints = @[];
  XCTAssertEqual(m_game.zobristHashAfterHandicap, 0);
  XCTAssertEqual(m_game.zobristHashAfterHandicap, m_game.nodeModel.rootNode.zobristHash);
  // GoPoint object's that were previously set must have their stoneState reset
  for (GoPoint* point in handicapPoints)
    XCTAssertEqual(GoColorNone, point.stoneState);

  XCTAssertThrowsSpecificNamed(m_game.handicapPoints = nil,
                              NSException, NSInvalidArgumentException, @"point list is nil");
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertThrowsSpecificNamed(m_game.handicapPoints = handicapPoints,
                              NSException, NSInternalInconsistencyException, @"handicap set after first move");
  // Can set handicap if there are no moves
  [self discardLeafNodeAndSyncBoardPosition];
  m_game.handicapPoints = handicapPoints;
  XCTAssertNotEqual(m_game.zobristHashAfterHandicap, 0);
  XCTAssertEqual(m_game.zobristHashAfterHandicap, m_game.nodeModel.rootNode.zobristHash);
  [m_game resign];
  XCTAssertThrowsSpecificNamed(m_game.handicapPoints = handicapPoints,
                              NSException, NSInternalInconsistencyException, @"handicap set after game has ended");
  // Can set handicap if game has not ended
  [m_game revertStateFromEndedToInProgress];
  m_game.handicapPoints = handicapPoints;
  XCTAssertNotEqual(m_game.zobristHashAfterHandicap, 0);
  XCTAssertEqual(m_game.zobristHashAfterHandicap, m_game.nodeModel.rootNode.zobristHash);

  GoPoint* point = [m_game.board pointAtVertex:@"A1"];
  point.stoneState = GoColorBlack;
  [handicapPoints setArray:[GoUtilities pointsForHandicap:5 inGame:m_game]];
  [handicapPoints addObject:point];
  XCTAssertThrowsSpecificNamed(m_game.handicapPoints = handicapPoints,
                               NSException, NSInvalidArgumentException, @"handicap points are already occupied");

  // We allocate a new game now, as recommended by the docs of the
  // handicapPoints property, because the damage after the
  // NSInvalidArgumentException from the previous test is too difficult to
  // repair.
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  [handicapPoints setArray:[GoUtilities pointsForHandicap:5 inGame:m_game]];

  m_game.handicapPoints = handicapPoints;
  GoPoint* firstHandicapPoint = handicapPoints.firstObject;
  firstHandicapPoint.stoneState = GoColorNone;
  XCTAssertThrowsSpecificNamed(m_game.handicapPoints = @[],
                              NSException, NSInternalInconsistencyException, @"previous handicap points are not occupied with black stone");

  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  [handicapPoints setArray:[GoUtilities pointsForHandicap:5 inGame:m_game]];

  // Setting the same list of handicap points must have no effect. The order in
  // which handicap points appear in the list must not be relevant. We test this
  // by setting up a board state that would cause an exception to be thrown if
  // the setter were not performing the equality check correctly. The setup
  // consists of removing the black stone from one of the handicap points - this
  // normally causes an NSInternalInconsistencyException.
  m_game.handicapPoints = handicapPoints;
  firstHandicapPoint = handicapPoints.firstObject;
  firstHandicapPoint.stoneState = GoColorNone;
  NSArray* reversedHandicapPoints = [NSArray arrayWithArrayInReverseOrder:handicapPoints];
  m_game.handicapPoints = reversedHandicapPoints;
  firstHandicapPoint.stoneState = GoColorBlack;
  m_game.handicapPoints = @[];

  // Setting a handicap / no handicap changes nextMoveColor when the normal
  // game rules are in effect (i.e. when setupFirstMoveColor is not set)
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorNone);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  m_game.handicapPoints = handicapPoints;
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  m_game.handicapPoints = @[];
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);

  // Setting a handicap / no handicap does not change nextMoveColor if
  // setupFirstMoveColor overrides the normal game rules
  [m_game changeSetupFirstMoveColor:GoColorWhite];
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  m_game.handicapPoints = handicapPoints;
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  m_game.handicapPoints = @[];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  [m_game changeSetupFirstMoveColor:GoColorNone];  // removes GoNodeSetup for the next test

  // If a GoNodeSetup object exists its previous setup information must be
  // updated when a new list of handicap stones is set. Error cases of this are
  // tested in GoNodeSetupTest.
  GoNode* rootNode = m_game.nodeModel.rootNode;
  XCTAssertNil(rootNode.goNodeSetup);
  [m_game changeSetupFirstMoveColor:GoColorBlack];
  XCTAssertNotNil(rootNode.goNodeSetup);
  XCTAssertNil(rootNode.goNodeSetup.previousBlackSetupStones);
  m_game.handicapPoints = handicapPoints;
  XCTAssertTrue([rootNode.goNodeSetup.previousBlackSetupStones isEqualToArrayIgnoringOrder:handicapPoints]);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e nextMoveColor and @e nextMovePlayer properties. The
/// two properties are tested in conjunction because @e nextMovePlayer is a
/// calculated property based entirely on the value of @e nextMoveColor.
///
/// Tests are almost equivalent to those in testSwitchNextMoveColor().
// -----------------------------------------------------------------------------
- (void) testNextMoveColorAndNextMovePlayer
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
  // Because alternating play is enabled the value of nextMoveColor changes on
  // every move
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
  // Because alternating play is disabled the value of nextMoveColor no longer
  // changes on every move => we have full control over the property
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
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
  [self discardLeafNodeAndSyncBoardPosition];
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
  m_game.handicapPoints = @[];
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
  [self discardLeafNodeAndSyncBoardPosition];  // discard play move C1
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [self discardLeafNodeAndSyncBoardPosition];  // discard pass move
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);

  // The current value of nextMoveColor is not relevant when discarding a move
  [m_game switchNextMoveColor];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [self discardLeafNodeAndSyncBoardPosition];  // discard play move B1 made by white
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
  m_game.handicapPoints = @[];
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
  [self discardLeafNodeAndSyncBoardPosition];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [self discardLeafNodeAndSyncBoardPosition];
  XCTAssertEqual(m_game.lastMove.player, m_game.playerBlack);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  [m_game.nodeModel discardAllNodes];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e firstMove property.
// -----------------------------------------------------------------------------
- (void) testFirstMove
{
  XCTAssertNil(m_game.firstMove);
  [m_game addEmptyNodeToCurrentGameVariation];
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertNotNil(m_game.firstMove);
  [self discardLeafNodeAndSyncBoardPosition];
  XCTAssertNil(m_game.firstMove);
  // More detailed checks in testLastMove()
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e lastMove property.
// -----------------------------------------------------------------------------
- (void) testLastMove
{
  [m_game addEmptyNodeToCurrentGameVariation];
  XCTAssertNil(m_game.lastMove);

  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game addEmptyNodeToCurrentGameVariation];
  GoMove* move1 = m_game.lastMove;
  XCTAssertNotNil(move1);
  XCTAssertEqual(m_game.firstMove, move1);
  XCTAssertNil(move1.previous);

  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  [m_game addEmptyNodeToCurrentGameVariation];
  GoMove* move2 = m_game.lastMove;
  XCTAssertNotNil(move2);
  XCTAssertTrue(m_game.firstMove != move2);
  XCTAssertNil(move1.previous);
  XCTAssertEqual(move1, move2.previous);

  [self discardLeafNodeAndSyncBoardPosition];
  [self discardLeafNodeAndSyncBoardPosition];
  XCTAssertEqual(move1, m_game.firstMove);
  XCTAssertEqual(move1, m_game.lastMove);

  [self discardLeafNodeAndSyncBoardPosition];
  [self discardLeafNodeAndSyncBoardPosition];
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
  [self discardLeafNodeAndSyncBoardPosition];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  [m_game resign];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e reasonForGameHasEnded property.
///
/// Tests are almost identical to those in
/// testEndGameDueToPassMovesIfGameRulesRequireIt().
// -----------------------------------------------------------------------------
- (void) testReasonForGameHasEnded
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;

  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game resign];
  XCTAssertEqual(GoGameHasEndedReasonWhiteWinsByResignation, m_game.reasonForGameHasEnded);

  // Can resume play an arbitrary number of times; each time two passes are made
  // the game ends GoGameHasEndedReasonTwoPasses
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);

  // If GoFourPassesRuleFourPassesEndTheGame is active it will cause the game
  // to end with reason GoGameHasEndedReasonFourPasses when the second pair of
  // pass moves is made
  newGameModel.fourPassesRule = GoFourPassesRuleFourPassesEndTheGame;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  // If the game has ended with reason GoGameHasEndedReasonFourPasses, the UI
  // forces the user to discard the last pass move if he wants to continue
  // playing. In other words, in the UI there is no way to resume play as we
  // do where, so this test is somewhat contrived.
  XCTAssertEqual(GoGameHasEndedReasonFourPasses, m_game.reasonForGameHasEnded);
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);

  // The UI does not allow GoLifeAndDeathSettlingRuleThreePasses and
  // GoFourPassesRuleFourPassesEndTheGame to be active at the same time, so this
  // test may seem a bit contrived. On the other hand, GoGame is perfectly
  // capable of handling these two rules, so let's test away...
  newGameModel.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleThreePasses;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonThreePasses, m_game.reasonForGameHasEnded);
  [m_game revertStateFromEndedToInProgress];
  [m_game pass];
  // GoGameHasEndedReasonFourPasses
  XCTAssertEqual(GoGameHasEndedReasonFourPasses, m_game.reasonForGameHasEnded);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e zobristHashAfterHandicap property.
// -----------------------------------------------------------------------------
- (void) testZobristHashAfterHandicap
{
  GoNode* rootNode = m_game.nodeModel.rootNode;

  long long hashForEmptyBoard = 0;
  XCTAssertEqual(m_game.zobristHashAfterHandicap, hashForEmptyBoard);
  XCTAssertEqual(m_game.zobristHashAfterHandicap, rootNode.zobristHash);

  m_game.handicapPoints = @[[m_game.board pointAtVertex:@"C3"]];
  XCTAssertTrue(m_game.zobristHashAfterHandicap != hashForEmptyBoard);
  XCTAssertEqual(m_game.zobristHashAfterHandicap, rootNode.zobristHash);

  m_game.handicapPoints = @[];
  XCTAssertEqual(m_game.zobristHashAfterHandicap, hashForEmptyBoard);
  XCTAssertEqual(m_game.zobristHashAfterHandicap, rootNode.zobristHash);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the play() method.
// -----------------------------------------------------------------------------
- (void) testPlay
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  GoNodeModel* nodeModel = m_game.nodeModel;

  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertFalse(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 1);
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);

  GoPoint* point1 = [m_game.board pointAtVertex:@"T19"];
  [m_game play:point1];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  GoMove* move1 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePlay, move1.type);
  XCTAssertEqual(m_game.playerBlack, move1.player);
  XCTAssertEqual(point1, move1.point);
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 2);
  XCTAssertEqual(boardPosition.currentBoardPosition, 1);

  GoPoint* point2 = [m_game.board pointAtVertex:@"S19"];
  [m_game play:point2];
  GoMove* move2 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePlay, move2.type);
  XCTAssertEqual(m_game.playerWhite, move2.player);
  XCTAssertEqual(point2, move2.point);
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);

  [m_game pass];
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertEqual(boardPosition.currentBoardPosition, 3);

  GoPoint* point3 = [m_game.board pointAtVertex:@"T18"];
  [m_game play:point3];
  GoMove* move3 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePlay, move3.type);
  XCTAssertEqual(m_game.playerWhite, move3.player);
  XCTAssertEqual(point3, move3.point);
  NSUInteger expectedNumberOfCapturedStones = 1;
  XCTAssertEqual(expectedNumberOfCapturedStones, move3.capturedStones.count);
  XCTAssertEqual(nodeModel.numberOfNodes, 5);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 5);
  XCTAssertEqual(boardPosition.currentBoardPosition, 4);

  XCTAssertThrowsSpecificNamed([m_game play:nil],
                              NSException, NSInvalidArgumentException, @"point is nil");
  XCTAssertThrowsSpecificNamed([m_game play:point1],
                              NSException, NSInvalidArgumentException, @"point is not legal");
  [m_game resign];
  XCTAssertThrowsSpecificNamed([m_game play:[m_game.board pointAtVertex:@"B1"]],
                              NSException, NSInternalInconsistencyException, @"play after game end");

  // GoMoveAdditions lets us write the moveNumber property - actually generating
  // the maximum number of moves would be rather slow
  [m_game revertStateFromEndedToInProgress];
  GoMove* lastMove = m_game.lastMove;
  lastMove.moveNumber = maximumNumberOfMoves;
  XCTAssertThrowsSpecificNamed([m_game play:[m_game.board pointAtVertex:@"B1"]],
                              NSException, NSInvalidArgumentException, @"play after maximum number of moves");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the play:withMoveNodeCreationOptions:() method with
/// insert policy #GoNewMoveInsertPolicyRetainFutureBoardPositions.
// -----------------------------------------------------------------------------
- (void) testPlayWithMoveNodeCreationOptions_GoNewMoveInsertPolicyRetainFutureBoardPositions
{
  [self testPlayOrPassWithMoveNodeCreationOptions_GoNewMoveInsertPolicyRetainFutureBoardPositions_MoveType:GoMoveTypePlay];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the play:withMoveNodeCreationOptions:() method with
/// insert policy #GoNewMoveInsertPolicyReplaceFutureBoardPositions.
// -----------------------------------------------------------------------------
- (void) testPlayWithMoveNodeCreationOptions_GoNewMoveInsertPolicyReplaceFutureBoardPositionss
{
  [self testPlayOrPassWithMoveNodeCreationOptions_GoNewMoveInsertPolicyReplaceFutureBoardPositions_MoveType:GoMoveTypePlay];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pass() method.
// -----------------------------------------------------------------------------
- (void) testPass
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  GoNodeModel* nodeModel = m_game.nodeModel;

  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  XCTAssertFalse(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.numberOfNodes, 1);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 1);
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);

  // Can start game with a pass
  [m_game pass];
  XCTAssertEqual(GoGameStateGameHasStarted, m_game.state);
  GoMove* move1 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePass, move1.type);
  XCTAssertEqual(m_game.playerBlack, move1.player);
  XCTAssertNil(move1.point);
  XCTAssertTrue(m_game.document.isDirty);
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 2);
  XCTAssertEqual(boardPosition.currentBoardPosition, 1);

  [m_game play:[m_game.board pointAtVertex:@"B13"]];
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);

  [m_game pass];
  GoMove* move2 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePass, move2.type);
  XCTAssertEqual(m_game.playerBlack, move2.player);
  XCTAssertNil(move2.point);
  XCTAssertEqual(nodeModel.numberOfNodes, 4);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertEqual(boardPosition.currentBoardPosition, 3);

  // End the game with two passes in a row
  [m_game pass];
  XCTAssertEqual(GoGameStateGameHasEnded, m_game.state);
  GoMove* move3 = m_game.lastMove;
  XCTAssertEqual(GoMoveTypePass, move3.type);
  XCTAssertEqual(m_game.playerWhite, move3.player);
  XCTAssertNil(move3.point);
  XCTAssertEqual(nodeModel.numberOfNodes, 5);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 5);
  XCTAssertEqual(boardPosition.currentBoardPosition, 4);

  XCTAssertThrowsSpecificNamed([m_game pass],
                              NSException, NSInternalInconsistencyException, @"pass after game end");

  // GoMoveAdditions lets us write the moveNumber property - actually generating
  // the maximum number of moves would be rather slow
  [m_game revertStateFromEndedToInProgress];
  GoMove* lastMove = m_game.lastMove;
  lastMove.moveNumber = maximumNumberOfMoves;
  XCTAssertThrowsSpecificNamed([m_game pass],
                               NSException, NSInvalidArgumentException, @"pass after maximum number of moves");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the passWithMoveNodeCreationOptions:() method  with
/// insert policy #GoNewMoveInsertPolicyRetainFutureBoardPositions.
// -----------------------------------------------------------------------------
- (void) testPassWithMoveNodeCreationOptions_GoNewMoveInsertPolicyRetainFutureBoardPositions
{
  [self testPlayOrPassWithMoveNodeCreationOptions_GoNewMoveInsertPolicyRetainFutureBoardPositions_MoveType:GoMoveTypePass];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the passWithMoveNodeCreationOptions:() method with
/// insert policy #GoNewMoveInsertPolicyReplaceFutureBoardPositions.
// -----------------------------------------------------------------------------
- (void) testPassWithMoveNodeCreationOptions_GoNewMoveInsertPolicyReplaceFutureBoardPositions
{
  [self testPlayOrPassWithMoveNodeCreationOptions_GoNewMoveInsertPolicyReplaceFutureBoardPositions_MoveType:GoMoveTypePlay];
}

// -----------------------------------------------------------------------------
/// @brief Exercises either the play:withMoveNodeCreationOptions:() or the
/// passWithMoveNodeCreationOptions:() method with insert policy
/// #GoNewMoveInsertPolicyRetainFutureBoardPositions. The value of @a moveType
/// determines which of the two methods is exercised.
///
/// This is a private helper.
// -----------------------------------------------------------------------------
- (void) testPlayOrPassWithMoveNodeCreationOptions_GoNewMoveInsertPolicyRetainFutureBoardPositions_MoveType:(enum GoMoveType)moveType
{
  NSArray* insertPositions = @[@((int)GoNewMoveInsertPositionNewVariationAtTop),
                               @((int)GoNewMoveInsertPositionNewVariationAtBottom),
                               @((int)GoNewMoveInsertPositionNewVariationBeforeCurrentVariation),
                               @((int)GoNewMoveInsertPositionNewVariationAfterCurrentVariation)];
  for (NSNumber* insertPositionAsNumber in insertPositions)
  {
    // Arrange
    if (! self.testSetupHasBeenDone)
      [self setUp];

    enum GoNewMoveInsertPosition insertPosition = insertPositionAsNumber.intValue;
    GoMoveNodeCreationOptions* options = [GoMoveNodeCreationOptions moveNodeCreationOptionsWithInsertPolicyRetainFutureBoardPositionsAndInsertPosition:insertPosition];

    GoGame* testee = m_game;
    GoNodeModel* nodeModel = testee.nodeModel;
    GoBoardPosition* boardPosition = testee.boardPosition;
    GoNode* rootNode = nodeModel.rootNode;
    GoPoint* point1 = [testee.board pointAtVertex:@"A1"];
    GoPoint* point2 = [testee.board pointAtVertex:@"A2"];

    [self registerForNotification:numberOfBoardPositionsDidChange];
    [self registerForNotification:currentBoardPositionDidChange];
    [self registerForNotification:currentGameVariationWillChange];
    [self registerForNotification:currentGameVariationDidChange];

    // Set up a node tree that allows to distinguish the possible insert
    // positions and the effects of the current game variation change
    //     +-- current board position
    //     v
    // o---A---B---C
    //     +---D---E   <--- current game variation
    //     +---F---G
    GoNode* nodeA = [GoNode node];
    GoNode* nodeB = [GoNode node];
    GoNode* nodeC = [GoNode node];
    GoNode* nodeD = [GoNode node];
    GoNode* nodeE = [GoNode node];
    GoNode* nodeF = [GoNode node];
    GoNode* nodeG = [GoNode node];
    rootNode.firstChild = nodeA;  // replaces all child nodes from the previous iteration
    nodeA.firstChild = nodeB;
    nodeB.firstChild = nodeC;
    nodeB.nextSibling = nodeD;
    nodeD.firstChild = nodeE;
    nodeD.nextSibling = nodeF;
    nodeF.firstChild = nodeG;
    [nodeModel changeToVariationContainingNode:nodeE];
    boardPosition.numberOfBoardPositions = nodeModel.numberOfNodes;
    boardPosition.currentBoardPosition = [nodeModel indexOfNode:nodeA];

    XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
    XCTAssertEqual(boardPosition.currentBoardPosition, 1);
    XCTAssertEqualObjects(boardPosition.currentNode, nodeA);
    XCTAssertNil(testee.firstMove);
    XCTAssertNil(testee.lastMove);
    XCTAssertEqual(point1.stoneState, GoColorNone);

    // Act 1 - create a new game variation because the current board position
    // is not the last board position
    if (moveType == GoMoveTypePlay)
      [testee play:point1 withMoveNodeCreationOptions:options];
    else
      [testee passWithMoveNodeCreationOptions:options];

    // Assert 1
    GoMove* move1 = testee.firstMove;
    XCTAssertEqualObjects(testee.lastMove, move1);
    XCTAssertEqual(moveType, move1.type);
    XCTAssertEqualObjects(testee.playerBlack, move1.player);
    if (moveType == GoMoveTypePlay)
    {
      XCTAssertEqualObjects(point1, move1.point);
      XCTAssertEqual(point1.stoneState, GoColorBlack);
    }

    XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
    XCTAssertEqual(boardPosition.currentBoardPosition, 2);
    GoNode* nodeMove1 = boardPosition.currentNode;
    XCTAssertEqualObjects(nodeMove1.goMove, move1);
    XCTAssertEqualObjects(nodeMove1.parent, nodeA);
    switch (insertPosition)
    {
      case GoNewMoveInsertPositionNewVariationAtTop:
        XCTAssertNil(nodeMove1.previousSibling);
        XCTAssertEqualObjects(nodeMove1.nextSibling, nodeB);
        break;
      case GoNewMoveInsertPositionNewVariationAtBottom:
        XCTAssertEqualObjects(nodeMove1.previousSibling, nodeF);
        XCTAssertNil(nodeMove1.nextSibling);
        break;
      case GoNewMoveInsertPositionNewVariationBeforeCurrentVariation:
        XCTAssertEqualObjects(nodeMove1.previousSibling, nodeB);
        XCTAssertEqualObjects(nodeMove1.nextSibling, nodeD);
        break;
      case GoNewMoveInsertPositionNewVariationAfterCurrentVariation:
        XCTAssertEqualObjects(nodeMove1.previousSibling, nodeD);
        XCTAssertEqualObjects(nodeMove1.nextSibling, nodeF);
        break;
      default:
        break;
    }

    XCTAssertEqual([self numberOfNotificationsReceived:numberOfBoardPositionsDidChange], 1);
    XCTAssertEqual([self numberOfNotificationsReceived:currentBoardPositionDidChange], 1);
    XCTAssertEqual([self numberOfNotificationsReceived:currentGameVariationWillChange], 1);
    XCTAssertEqual([self numberOfNotificationsReceived:currentGameVariationDidChange], 1);

    // Act 2 - append to the current game variation because the current board
    // position is the last board position
    if (moveType == GoMoveTypePlay)
      [testee play:point2 withMoveNodeCreationOptions:options];
    else
      [testee passWithMoveNodeCreationOptions:options];

    // Assert 2
    GoMove* move2 = testee.lastMove;
    XCTAssertNotEqualObjects(move1, move2);
    XCTAssertNotEqualObjects(testee.firstMove, move2);
    XCTAssertEqual(moveType, move2.type);
    XCTAssertEqualObjects(testee.playerWhite, move2.player);
    if (moveType == GoMoveTypePlay)
    {
      XCTAssertEqualObjects(point2, move2.point);
      XCTAssertEqual(point2.stoneState, GoColorWhite);
    }

    XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
    XCTAssertEqual(boardPosition.currentBoardPosition, 3);
    GoNode* nodeMove2 = boardPosition.currentNode;
    XCTAssertEqualObjects(nodeMove2.goMove, move2);
    XCTAssertEqualObjects(nodeMove2.parent, nodeMove1);
    XCTAssertNil(nodeMove2.previousSibling);
    XCTAssertNil(nodeMove2.nextSibling);

    XCTAssertEqual([self numberOfNotificationsReceived:numberOfBoardPositionsDidChange], 2);
    XCTAssertEqual([self numberOfNotificationsReceived:currentBoardPositionDidChange], 2);
    XCTAssertEqual([self numberOfNotificationsReceived:currentGameVariationWillChange], 1);
    XCTAssertEqual([self numberOfNotificationsReceived:currentGameVariationDidChange], 1);

    // Post-assert: Cleanup for next iteration
    [self tearDown];
  }
}

// -----------------------------------------------------------------------------
/// @brief Exercises either the play:withMoveNodeCreationOptions:() or the
/// passWithMoveNodeCreationOptions:() method with insert policy
/// #GoNewMoveInsertPolicyReplaceFutureBoardPositions. The value of @a moveType
/// determines which of the two methods is exercised.
///
/// This is a private helper.
// -----------------------------------------------------------------------------
- (void) testPlayOrPassWithMoveNodeCreationOptions_GoNewMoveInsertPolicyReplaceFutureBoardPositions_MoveType:(enum GoMoveType)moveType
{
  // Arrange
  GoMoveNodeCreationOptions* options = [GoMoveNodeCreationOptions moveNodeCreationOptionsWithInsertPolicyReplaceFutureBoardPositions];

  GoGame* testee = m_game;
  GoNodeModel* nodeModel = testee.nodeModel;
  GoBoardPosition* boardPosition = testee.boardPosition;
  GoNode* rootNode = nodeModel.rootNode;
  GoPoint* point1 = [testee.board pointAtVertex:@"A1"];
  GoPoint* point2 = [testee.board pointAtVertex:@"A2"];

  [self registerForNotification:numberOfBoardPositionsDidChange];
  [self registerForNotification:currentBoardPositionDidChange];
  [self registerForNotification:currentGameVariationWillChange];
  [self registerForNotification:currentGameVariationDidChange];

  // Set up a node tree that allows to make sure that only the nodes in the
  // current game variation are discarded.
  //     +-- current board position
  //     v
  // o---A---B---C
  //     +---D---E   <--- current game variation
  //     +---F---G
  GoNode* nodeA = [GoNode node];
  GoNode* nodeB = [GoNode node];
  GoNode* nodeC = [GoNode node];
  GoNode* nodeD = [GoNode node];
  GoNode* nodeE = [GoNode node];
  GoNode* nodeF = [GoNode node];
  GoNode* nodeG = [GoNode node];
  rootNode.firstChild = nodeA;  // replaces all child nodes from the previous iteration
  nodeA.firstChild = nodeB;
  nodeB.firstChild = nodeC;
  nodeB.nextSibling = nodeD;
  nodeD.firstChild = nodeE;
  nodeD.nextSibling = nodeF;
  nodeF.firstChild = nodeG;
  [nodeModel changeToVariationContainingNode:nodeE];
  boardPosition.numberOfBoardPositions = nodeModel.numberOfNodes;
  boardPosition.currentBoardPosition = [nodeModel indexOfNode:nodeA];

  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertEqual(boardPosition.currentBoardPosition, 1);
  XCTAssertEqualObjects(boardPosition.currentNode, nodeA);
  XCTAssertNil(testee.firstMove);
  XCTAssertNil(testee.lastMove);
  XCTAssertEqual(point1.stoneState, GoColorNone);

  // Act 1 - discard nodes in the current game variation because the current
  // board position is not the last board position
  if (moveType == GoMoveTypePlay)
    [testee play:point1 withMoveNodeCreationOptions:options];
  else
    [testee passWithMoveNodeCreationOptions:options];

  // Assert 1
  GoMove* move1 = testee.firstMove;
  XCTAssertEqualObjects(testee.lastMove, move1);
  XCTAssertEqual(moveType, move1.type);
  XCTAssertEqualObjects(testee.playerBlack, move1.player);
  if (moveType == GoMoveTypePlay)
  {
    XCTAssertEqualObjects(point1, move1.point);
    XCTAssertEqual(point1.stoneState, GoColorBlack);
  }

  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);
  GoNode* nodeMove1 = boardPosition.currentNode;
  XCTAssertEqualObjects(nodeMove1.goMove, move1);
  XCTAssertEqualObjects(nodeMove1.parent, nodeA);
  XCTAssertEqualObjects(nodeMove1.previousSibling, nodeB);
  XCTAssertEqualObjects(nodeMove1.nextSibling, nodeF);
  XCTAssertNil(nodeD.parent);

  XCTAssertEqual([self numberOfNotificationsReceived:numberOfBoardPositionsDidChange], 1);
  XCTAssertEqual([self numberOfNotificationsReceived:currentBoardPositionDidChange], 1);
  XCTAssertEqual([self numberOfNotificationsReceived:currentGameVariationWillChange], 0);
  XCTAssertEqual([self numberOfNotificationsReceived:currentGameVariationDidChange], 0);

  // Act 2 - append to the current game variation because the current board
  // position is the last board position
  if (moveType == GoMoveTypePlay)
    [testee play:point2 withMoveNodeCreationOptions:options];
  else
    [testee passWithMoveNodeCreationOptions:options];

  // Assert 2
  GoMove* move2 = testee.lastMove;
  XCTAssertNotEqualObjects(move1, move2);
  XCTAssertNotEqualObjects(testee.firstMove, move2);
  XCTAssertEqual(moveType, move2.type);
  XCTAssertEqualObjects(testee.playerWhite, move2.player);
  if (moveType == GoMoveTypePlay)
  {
    XCTAssertEqualObjects(point2, move2.point);
    XCTAssertEqual(point2.stoneState, GoColorWhite);
  }

  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertEqual(boardPosition.currentBoardPosition, 3);
  GoNode* nodeMove2 = boardPosition.currentNode;
  XCTAssertEqualObjects(nodeMove2.goMove, move2);
  XCTAssertEqualObjects(nodeMove2.parent, nodeMove1);
  XCTAssertNil(nodeMove2.previousSibling);
  XCTAssertNil(nodeMove2.nextSibling);

  XCTAssertEqual([self numberOfNotificationsReceived:numberOfBoardPositionsDidChange], 2);
  XCTAssertEqual([self numberOfNotificationsReceived:currentBoardPositionDidChange], 2);
  XCTAssertEqual([self numberOfNotificationsReceived:currentGameVariationWillChange], 0);
  XCTAssertEqual([self numberOfNotificationsReceived:currentGameVariationDidChange], 0);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the play:withMoveNodeCreationOptions:() and
/// passWithMoveNodeCreationOptions:() methods with an GoMoveNodeCreationOptions
/// argument that holds invalid values.
// -----------------------------------------------------------------------------
- (void) testPlayWithMoveNodeCreationOptions_PassWithMoveNodeCreationOptions_InvalidOptions
{
  GoGame* testee = m_game;
  GoPoint* point = [testee.board pointAtVertex:@"A1"];

  NSArray* insertPositions = @[@((int)GoNewMoveInsertPositionNewVariationAtTop),
                               @((int)GoNewMoveInsertPositionNewVariationAtBottom),
                               @((int)GoNewMoveInsertPositionNewVariationBeforeCurrentVariation),
                               @((int)GoNewMoveInsertPositionNewVariationAfterCurrentVariation),
                               @((int)GoNewMoveInsertPositionNextBoardPosition)];
  for (NSNumber* insertPositionAsNumber in insertPositions)
  {
    enum GoNewMoveInsertPosition insertPosition = insertPositionAsNumber.intValue;
    GoMoveNodeCreationOptions* options;
    if (insertPosition == GoNewMoveInsertPositionNextBoardPosition)
      options = [GoMoveNodeCreationOptions moveNodeCreationOptions];
    else
      options = [GoMoveNodeCreationOptions moveNodeCreationOptionsWithInsertPolicyReplaceFutureBoardPositions];

    // GoMoveNodeCreationOptions provides no way to create an instance with
    // invalid values, so to fabricate an invalid combination of values we use
    // NSKeyValueCoding to circumvent the safeguards built into the class.
    [options setValue:[NSNumber numberWithInt:insertPosition] forKey:@"newMoveInsertPosition"];

    XCTAssertThrowsSpecificNamed([testee play:point withMoveNodeCreationOptions:options],
                                 NSException, NSInternalInconsistencyException,
                                 @"play must fail when GoMoveNodeCreationOptions is supplied with an invalid combination of values");
    XCTAssertThrowsSpecificNamed([testee passWithMoveNodeCreationOptions:options],
                                 NSException, NSInternalInconsistencyException,
                                 @"pass must fail when GoMoveNodeCreationOptions is supplied with an invalid combination of values");
  }
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
/// @brief Exercises the
/// isLegalBoardSetupAt:withStoneState:isIllegalReason:createsIllegalStoneOrGroup:()
/// method.
// -----------------------------------------------------------------------------
- (void) testIsLegalBoardSetupAt
{
  enum GoBoardSetupIsIllegalReason reason;
  GoPoint* illegalStoneOrGroupPoint;

  GoPoint* pointA1 = [m_game.board pointAtVertex:@"A1"];
  GoPoint* pointB1 = [m_game.board pointAtVertex:@"B1"];
  GoPoint* pointA2 = [m_game.board pointAtVertex:@"A2"];
  GoPoint* pointB2 = [m_game.board pointAtVertex:@"B2"];
  GoPoint* pointA3 = [m_game.board pointAtVertex:@"A3"];

  // Empty intersection is allowed for both colors
  XCTAssertTrue([m_game isLegalBoardSetupAt:pointA1 withStoneState:GoColorBlack isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  XCTAssertTrue([m_game isLegalBoardSetupAt:pointA1 withStoneState:GoColorWhite isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);

  [m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack];

  // Occupied intersection with no neighbours is allowed for both colors.
  // Placing stone of the same color does not make much sense but is allowed
  XCTAssertTrue([m_game isLegalBoardSetupAt:pointA1 withStoneState:GoColorBlack isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  XCTAssertTrue([m_game isLegalBoardSetupAt:pointA1 withStoneState:GoColorWhite isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);

  [m_game changeSetupPoint:pointB1 toStoneState:GoColorWhite];

  // Capturing a single opposing stone
  // 3
  // 2  O*
  // 1  X   O
  //    A   B
  XCTAssertFalse([m_game isLegalBoardSetupAt:pointA2 withStoneState:GoColorWhite isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  XCTAssertEqual(reason, GoBoardSetupIsIllegalReasonSuicideOpposingStone);

  [m_game changeSetupPoint:pointA2 toStoneState:GoColorBlack];
  [m_game changeSetupPoint:pointB2 toStoneState:GoColorWhite];

  // Capturing an opposing stone group 1: Regular case where the stone is
  // placed on an empty intersection.
  // 3  O*
  // 2  X   O
  // 1  X   O
  //    A   B
  XCTAssertFalse([m_game isLegalBoardSetupAt:pointA3 withStoneState:GoColorWhite isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  XCTAssertEqual(reason, GoBoardSetupIsIllegalReasonSuicideOpposingStoneGroup);

  [m_game changeSetupPoint:pointA3 toStoneState:GoColorBlack];

  // Capturing an opposing stone group 2: Special case where the stone is
  // placed on an intersection that is already occupied. An initial naive
  // implementation of the isLegal... logic interpreted this as splitting the
  // black stone group A1/A2/A3 into a group 1, consisting of A1/A2, and a
  // group 2, consisting of no stones. The final implementation must recognize
  // that this is not a split, but a regular capture.
  // 3  O*
  // 2  X   O
  // 1  X   O
  //    A   B
  XCTAssertFalse([m_game isLegalBoardSetupAt:pointA3 withStoneState:GoColorWhite isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  XCTAssertEqual(reason, GoBoardSetupIsIllegalReasonSuicideOpposingStoneGroup);

  // Splitting an opposing stone group and capturing a sub-group
  // 3  X
  // 2  O*  O
  // 1  X   O
  //    A   B
  XCTAssertFalse([m_game isLegalBoardSetupAt:pointA2 withStoneState:GoColorWhite isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  XCTAssertEqual(reason, GoBoardSetupIsIllegalReasonSuicideOpposingColorSubgroup);

  [m_game changeSetupPoint:pointA2 toStoneState:GoColorNone];
  [m_game changeSetupPoint:pointA3 toStoneState:GoColorWhite];

  // Suiciding a friendly stone group
  // 3  O
  // 2  X*  O
  // 1  X   O
  //    A   B
  XCTAssertFalse([m_game isLegalBoardSetupAt:pointA2 withStoneState:GoColorBlack isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  XCTAssertEqual(reason, GoBoardSetupIsIllegalReasonSuicideFriendlyStoneGroup);

  [m_game changeSetupPoint:pointA1 toStoneState:GoColorNone];
  [m_game changeSetupPoint:pointA2 toStoneState:GoColorWhite];

  // Suiciding the stone itself
  // 3  O
  // 2  O   O
  // 1  X*  O
  //    A   B
  XCTAssertFalse([m_game isLegalBoardSetupAt:pointA1 withStoneState:GoColorBlack isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  XCTAssertEqual(reason, GoBoardSetupIsIllegalReasonSuicideSetupStone);

  // Testing for GoColorNone always returns true
  XCTAssertTrue([m_game isLegalBoardSetupAt:pointB1 withStoneState:GoColorNone isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);
  // ... even if no stone actually exists on the point
  XCTAssertTrue([m_game isLegalBoardSetupAt:pointA1 withStoneState:GoColorNone isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint]);

  XCTAssertThrowsSpecificNamed([m_game isLegalBoardSetupAt:nil withStoneState:GoColorNone isIllegalReason:&reason createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint],
                               NSException, NSInvalidArgumentException, @"point is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isLegalBoardSetup:() method.
// -----------------------------------------------------------------------------
- (void) testIsLegalBoardSetup
{
  NSString* suicidalIntersectionsString;

  GoPoint* pointA1 = [m_game.board pointAtVertex:@"A1"];
  GoPoint* pointB1 = [m_game.board pointAtVertex:@"B1"];
  GoPoint* pointA2 = [m_game.board pointAtVertex:@"A2"];

  // Empty board is always legal
  XCTAssertTrue([m_game isLegalBoardSetup:&suicidalIntersectionsString]);

  // Cannot use changeSetupPoint:toStoneState:() because that already checks
  // whether the board setup is legal
  pointA1.stoneState = GoColorBlack;
  [GoUtilities movePointToNewRegion:pointA1];
  pointB1.stoneState = GoColorWhite;
  [GoUtilities movePointToNewRegion:pointB1];

  // Board with some stones, but everything is still legal
  XCTAssertTrue([m_game isLegalBoardSetup:&suicidalIntersectionsString]);

  // Black stone on A1 now no longer has liberties
  pointA2.stoneState = GoColorWhite;
  [GoUtilities movePointToNewRegion:pointA2];
  XCTAssertFalse([m_game isLegalBoardSetup:&suicidalIntersectionsString]);
  XCTAssertTrue([suicidalIntersectionsString isEqualToString:@"A1"]);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isLegalMove:isIllegalReason:() method (including simple
/// ko scenarios).
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
  [self discardLeafNodeAndSyncBoardPosition];
  [m_game play:point1];

  // Point occupied by black is not legal for either player
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonIntersectionOccupied);
  [m_game pass];
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonIntersectionOccupied);

  // Play stone with white
  [self discardLeafNodeAndSyncBoardPosition];
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
  [self discardLeafNodeAndSyncBoardPosition];
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

  // GoMoveAdditions lets us write the moveNumber property - actually generating
  // the maximum number of moves would be rather slow
  GoMove* lastMove = m_game.lastMove;
  lastMove.moveNumber = maximumNumberOfMoves;
  XCTAssertFalse([m_game isLegalPassMoveIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonTooManyMoves);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isLegalMove:isIllegalReason:() method (only positional
/// superko scenarios).
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
/// @brief Exercises the isLegalMove:isIllegalReason() method (only situational
/// superko scenarios).
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
/// @brief Exercises the isLegalPassMoveIllegalReason:() method.
// -----------------------------------------------------------------------------
- (void) testIsLegalPassMoveIllegalReason
{
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  GoMove* lastMove = m_game.lastMove;

  // GoMoveAdditions lets us write the moveNumber property - actually generating
  // the maximum number of moves would be rather slow
  lastMove.moveNumber = maximumNumberOfMoves;

  enum GoMoveIsIllegalReason illegalReason;
  XCTAssertFalse([m_game isLegalPassMoveIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonTooManyMoves);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the endGameDueToPassMovesIfGameRulesRequireIt() method.
///
/// Tests are almost identical to those in testReasonForGameHasEnded().
// -----------------------------------------------------------------------------
- (void) testEndGameDueToPassMovesIfGameRulesRequireIt
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;

  // Can resume play an arbitrary number of times; each time two passes are made
  // the game ends GoGameHasEndedReasonTwoPasses
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);

  // If GoFourPassesRuleFourPassesEndTheGame is active it will cause the game
  // to end with reason GoGameHasEndedReasonFourPasses when the second pair of
  // pass moves is made
  newGameModel.fourPassesRule = GoFourPassesRuleFourPassesEndTheGame;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  // If the game has ended with reason GoGameHasEndedReasonFourPasses, the UI
  // forces the user to discard the last pass move if he wants to continue
  // playing. In other words, in the UI there is no way to resume play as we
  // do where, so this test is somewhat contrived.
  XCTAssertEqual(GoGameHasEndedReasonFourPasses, m_game.reasonForGameHasEnded);
  [m_game revertStateFromEndedToInProgress];
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded);

  // The UI does not allow GoLifeAndDeathSettlingRuleThreePasses and
  // GoFourPassesRuleFourPassesEndTheGame to be active at the same time, so this
  // test may seem a bit contrived. On the other hand, GoGame is perfectly
  // capable of handling these two rules, so let's test away...
  newGameModel.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleThreePasses;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  XCTAssertEqual(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded);
  [m_game pass];
  [m_game pass];
  [m_game pass];
  XCTAssertEqual(GoGameHasEndedReasonThreePasses, m_game.reasonForGameHasEnded);
  [m_game revertStateFromEndedToInProgress];
  [m_game pass];
  // GoGameHasEndedReasonFourPasses
  XCTAssertEqual(GoGameHasEndedReasonFourPasses, m_game.reasonForGameHasEnded);

  XCTAssertThrowsSpecificNamed([m_game endGameDueToPassMovesIfGameRulesRequireIt],
                              NSException, NSInternalInconsistencyException, @"attempt to end game after game is already ended");
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

  // The public API of GoGame does not provide a means to set nextMoveColor to
  // GoColorNone (the setter raises an exception), so we cannot test whether
  // switchNextMoveColor really raises NSInternalInconsistencyException if it
  // encounters GoColorNone
}

// -----------------------------------------------------------------------------
/// @brief Exercises the toggleHandicapPoint() method.
// -----------------------------------------------------------------------------
- (void) testToggleHandicapPoint
{
  XCTAssertEqual(m_game.handicapPoints.count, 0);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorNone);

  GoPoint* pointA1 = [m_game.board pointAtVertex:@"A1"];

  // Place handicap stone
  [m_game toggleHandicapPoint:pointA1];
  NSArray* handicapPoints = m_game.handicapPoints;
  XCTAssertEqual(handicapPoints.count, 1);
  XCTAssertEqual(handicapPoints.firstObject, pointA1);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);

  // Remove handicap stone
  [m_game toggleHandicapPoint:pointA1];
  handicapPoints = m_game.handicapPoints;
  XCTAssertEqual(handicapPoints.count, 0);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);

  // Place handicap stone, but don't change nextMoveColor
  [m_game changeSetupFirstMoveColor:GoColorBlack];
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  [m_game toggleHandicapPoint:pointA1];
  handicapPoints = m_game.handicapPoints;
  XCTAssertEqual(handicapPoints.count, 1);
  XCTAssertEqual(handicapPoints.firstObject, pointA1);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);

  // Remove handicap stone, but don't revert nextMoveColor
  [m_game changeSetupFirstMoveColor:GoColorWhite];
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  [m_game toggleHandicapPoint:pointA1];
  handicapPoints = m_game.handicapPoints;
  XCTAssertEqual(handicapPoints.count, 0);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);

  XCTAssertThrowsSpecificNamed([m_game toggleHandicapPoint:nil],
                               NSException, NSInvalidArgumentException, @"point is nil");

  // Various attempts to illegally toggle the point when the stone state is not
  // correct
  pointA1.stoneState = GoColorWhite;
  XCTAssertThrowsSpecificNamed([m_game toggleHandicapPoint:pointA1],
                               NSException, NSInternalInconsistencyException, @"point has white stone on it");
  pointA1.stoneState = GoColorBlack;
  XCTAssertThrowsSpecificNamed([m_game toggleHandicapPoint:pointA1],
                               NSException, NSInternalInconsistencyException, @"point has black stone on it, but is not in handicapPoints");
  pointA1.stoneState = GoColorNone;

  [m_game toggleHandicapPoint:pointA1];
  XCTAssertEqual(pointA1.stoneState, GoColorBlack);
  pointA1.stoneState = GoColorNone;
  XCTAssertThrowsSpecificNamed([m_game toggleHandicapPoint:pointA1],
                               NSException, NSInternalInconsistencyException, @"point has no black stone on it, but is in handicapPoints");
  pointA1.stoneState = GoColorBlack;
  [m_game toggleHandicapPoint:pointA1];

  // Various attempts to illegally toggle the point when the game state is not
  // correct
  [m_game pass];
  XCTAssertThrowsSpecificNamed([m_game toggleHandicapPoint:pointA1],
                               NSException, NSInternalInconsistencyException, @"game aleady has moves");
  [self discardLeafNodeAndSyncBoardPosition];
  [m_game toggleHandicapPoint:pointA1];
  [m_game resign];
  XCTAssertThrowsSpecificNamed([m_game toggleHandicapPoint:pointA1],
                               NSException, NSInternalInconsistencyException, @"game aleady has ended");
  [m_game revertStateFromEndedToInProgress];

  // Toggle is allowed for computer vs. computer games in paused state
  m_game.type = GoGameTypeComputerVsComputer;
  [m_game pause];
  [m_game toggleHandicapPoint:pointA1];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the addEmptyNodeToCurrentGameVariation() method.
// -----------------------------------------------------------------------------
- (void) testAddEmptyNodeToCurrentGameVariation
{
  GoNodeModel* nodeModel = m_game.nodeModel;

  XCTAssertEqual(nodeModel.numberOfNodes, 1);

  [m_game addEmptyNodeToCurrentGameVariation];
  XCTAssertEqual(nodeModel.numberOfNodes, 2);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the changeSetupFirstMoveColor:() method.
// -----------------------------------------------------------------------------
- (void) testChangeSetupFirstMoveColor
{
  XCTAssertEqual(GoColorNone, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorBlack, m_game.nextMoveColor);
  XCTAssertNil(m_game.nodeModel.leafNode.goNodeSetup);

  // Unsetting side to move first when side to move first is already not set
  // => no effect
  [m_game changeSetupFirstMoveColor:GoColorNone];
  XCTAssertEqual(GoColorNone, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorBlack, m_game.nextMoveColor);
  XCTAssertNil(m_game.nodeModel.leafNode.goNodeSetup);

  // Setting side to move first when side to move first is not set
  // => changes both setupFirstMoveColor and nextMoveColor, but nextMoveColor
  //    already had the same value, so no observable change
  // => creates a GoNodeSetup object
  [m_game changeSetupFirstMoveColor:GoColorBlack];
  XCTAssertEqual(GoColorBlack, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorBlack, m_game.nextMoveColor);
  XCTAssertNotNil(m_game.nodeModel.leafNode.goNodeSetup);
  XCTAssertEqual(GoColorBlack, m_game.nodeModel.leafNode.goNodeSetup.setupFirstMoveColor);
  XCTAssertEqual(GoColorNone, m_game.nodeModel.leafNode.goNodeSetup.previousSetupFirstMoveColor);

  // Setting side to move first when side to move first is already set with a
  // different color
  // => changes both setupFirstMoveColor and nextMoveColor; this time change
  //    to nextMoveColor can be observed.
  [m_game changeSetupFirstMoveColor:GoColorWhite];
  XCTAssertEqual(GoColorWhite, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorWhite, m_game.nextMoveColor);
  XCTAssertNotNil(m_game.nodeModel.leafNode.goNodeSetup);
  XCTAssertEqual(GoColorWhite, m_game.nodeModel.leafNode.goNodeSetup.setupFirstMoveColor);
  XCTAssertEqual(GoColorNone, m_game.nodeModel.leafNode.goNodeSetup.previousSetupFirstMoveColor);

  // Unsetting side to move first when side to move first is set
  // => changes both setupFirstMoveColor and nextMoveColor
  // => removes GoNodeSetup object
  [m_game changeSetupFirstMoveColor:GoColorNone];
  XCTAssertEqual(GoColorNone, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorBlack, m_game.nextMoveColor);
  XCTAssertNil(m_game.nodeModel.leafNode.goNodeSetup);

  // Set up side to move first in board position 0
  // => preparation for tests when more than just one board position exists
  [m_game changeSetupFirstMoveColor:GoColorWhite];
  XCTAssertEqual(GoColorWhite, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorWhite, m_game.nextMoveColor);
  XCTAssertNotNil(m_game.nodeModel.leafNode.goNodeSetup);
  XCTAssertEqual(GoColorWhite, m_game.nodeModel.leafNode.goNodeSetup.setupFirstMoveColor);
  XCTAssertEqual(GoColorNone, m_game.nodeModel.leafNode.goNodeSetup.previousSetupFirstMoveColor);

  // Adding a new setup node creates a node without GoNodeSetup object
  // => both setupFirstMoveColor and nextMoveColor keep their values from the
  //    previous board position
  [m_game addEmptyNodeToCurrentGameVariation];
  XCTAssertEqual(GoColorWhite, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorWhite, m_game.nextMoveColor);
  XCTAssertNil(m_game.nodeModel.leafNode.goNodeSetup);

  // Setting side to move first when side to move first was set in previous
  // board position
  // => changes both setupFirstMoveColor and nextMoveColor
  // => creates a GoNodeSetup object with previousSetupFirstMoveColor set to
  //    the setupFirstMoveColor value from the previous board position
  [m_game changeSetupFirstMoveColor:GoColorBlack];
  XCTAssertEqual(GoColorBlack, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorBlack, m_game.nextMoveColor);
  XCTAssertNotNil(m_game.nodeModel.leafNode.goNodeSetup);
  XCTAssertEqual(GoColorBlack, m_game.nodeModel.leafNode.goNodeSetup.setupFirstMoveColor);
  XCTAssertEqual(GoColorWhite, m_game.nodeModel.leafNode.goNodeSetup.previousSetupFirstMoveColor);

  // Unsetting side to move first when side to move first is set
  // => changes both setupFirstMoveColor and nextMoveColor; setupFirstMoveColor
  //    value is restored from the previous board position
  // => removes GoNodeSetup object
  [m_game changeSetupFirstMoveColor:GoColorNone];
  XCTAssertEqual(GoColorWhite, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorWhite, m_game.nextMoveColor);
  XCTAssertNil(m_game.nodeModel.leafNode.goNodeSetup);

  // Adding a new setup node creates a node without GoNodeSetup object
  // => both setupFirstMoveColor and nextMoveColor keep their values from the
  //    previous board position
  [m_game addEmptyNodeToCurrentGameVariation];
  XCTAssertEqual(GoColorWhite, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorWhite, m_game.nextMoveColor);
  XCTAssertNil(m_game.nodeModel.leafNode.goNodeSetup);

  // Setting side to move first when side to move first was set in previous
  // board position
  // => changes both setupFirstMoveColor and nextMoveColor
  // => creates a GoNodeSetup object with previousSetupFirstMoveColor set to
  //    the setupFirstMoveColor value from the previous board position (even
  //    though there was no GoNodeSetup in that board position)
  [m_game changeSetupFirstMoveColor:GoColorBlack];
  XCTAssertEqual(GoColorBlack, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorBlack, m_game.nextMoveColor);
  XCTAssertNotNil(m_game.nodeModel.leafNode.goNodeSetup);
  XCTAssertEqual(GoColorBlack, m_game.nodeModel.leafNode.goNodeSetup.setupFirstMoveColor);
  XCTAssertEqual(GoColorWhite, m_game.nodeModel.leafNode.goNodeSetup.previousSetupFirstMoveColor);

  // Unsetting side to move first when side to move first is set
  // => changes both setupFirstMoveColor and nextMoveColor; setupFirstMoveColor
  //    value is restored from the previous board position (even though there
  //    was no GoNodeSetup in that board position)
  // => removes GoNodeSetup object
  [m_game changeSetupFirstMoveColor:GoColorNone];
  XCTAssertEqual(GoColorWhite, m_game.setupFirstMoveColor);
  XCTAssertEqual(GoColorWhite, m_game.nextMoveColor);
  XCTAssertNil(m_game.nodeModel.leafNode.goNodeSetup);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the changeSetupPoint() method.
// -----------------------------------------------------------------------------
- (void) testChangeSetupPoint
{
  GoPoint* pointA1 = [m_game.board pointAtVertex:@"A1"];
  GoPoint* pointB1 = [m_game.board pointAtVertex:@"B1"];
  GoPoint* pointA2 = [m_game.board pointAtVertex:@"A2"];

  GoNodeSetup* nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  long long previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Empty > Empty
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorNone];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Empty > Black
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNotNil(nodeSetup);
  XCTAssertNotNil(nodeSetup.blackSetupStones);
  XCTAssertNil(nodeSetup.whiteSetupStones);
  XCTAssertNil(nodeSetup.noSetupStones);
  XCTAssertEqual(nodeSetup.blackSetupStones.count, 1);
  XCTAssertEqual(nodeSetup.blackSetupStones.firstObject, pointA1);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Black > Black
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNotNil(nodeSetup);
  XCTAssertNotNil(nodeSetup.blackSetupStones);
  XCTAssertNil(nodeSetup.whiteSetupStones);
  XCTAssertNil(nodeSetup.noSetupStones);
  XCTAssertEqual(nodeSetup.blackSetupStones.count, 1);
  XCTAssertEqual(nodeSetup.blackSetupStones.firstObject, pointA1);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  XCTAssertEqual(previousZobristHash, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Black > White
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorWhite];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNotNil(nodeSetup);
  XCTAssertNil(nodeSetup.blackSetupStones);
  XCTAssertNotNil(nodeSetup.whiteSetupStones);
  XCTAssertNil(nodeSetup.noSetupStones);
  XCTAssertEqual(nodeSetup.whiteSetupStones.count, 1);
  XCTAssertEqual(nodeSetup.whiteSetupStones.firstObject, pointA1);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  XCTAssertNotEqual(previousZobristHash, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // White > White
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorWhite];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNotNil(nodeSetup);
  XCTAssertNil(nodeSetup.blackSetupStones);
  XCTAssertNotNil(nodeSetup.whiteSetupStones);
  XCTAssertNil(nodeSetup.noSetupStones);
  XCTAssertEqual(nodeSetup.whiteSetupStones.count, 1);
  XCTAssertEqual(nodeSetup.whiteSetupStones.firstObject, pointA1);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  XCTAssertEqual(previousZobristHash, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // White > Empty
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorNone];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Set up black and white stones in first board position so that they can be
  // changed in the second board position
  m_game.handicapPoints = @[pointB1];
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack];
  [m_game changeSetupPoint:pointA2 toStoneState:GoColorWhite];
  [m_game addEmptyNodeToCurrentGameVariation];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Black > Empty
  // White > Empty
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorNone];
  [m_game changeSetupPoint:pointA2 toStoneState:GoColorNone];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNotNil(nodeSetup);
  XCTAssertNil(nodeSetup.blackSetupStones);
  XCTAssertNil(nodeSetup.whiteSetupStones);
  XCTAssertNotNil(nodeSetup.noSetupStones);
  XCTAssertEqual(nodeSetup.noSetupStones.count, 2);
  XCTAssertEqual(nodeSetup.noSetupStones.firstObject, pointA1);
  XCTAssertEqual(nodeSetup.noSetupStones.lastObject, pointA2);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  XCTAssertNotEqual(previousZobristHash, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Empty > Black
  // Empty > White
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack];
  [m_game changeSetupPoint:pointA2 toStoneState:GoColorWhite];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  XCTAssertNotEqual(previousZobristHash, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Black (handicap) > Empty
  // This is only allowed in nodes beyond the root node. Below is a another test
  // that verifies that changing a handicap stone in the root node fails
  [m_game changeSetupPoint:pointB1 toStoneState:GoColorNone];
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  XCTAssertNotEqual(previousZobristHash, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  [self discardLeafNodeAndSyncBoardPosition];
  m_game.handicapPoints = @[];

  // Illegal board setup
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointB1 toStoneState:GoColorWhite],
                               NSException, NSInvalidArgumentException, @"illegal board setup");
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorNone];
  [m_game changeSetupPoint:pointA2 toStoneState:GoColorNone];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);

  // point is nil
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:nil toStoneState:GoColorBlack],
                               NSException, NSInvalidArgumentException, @"point is nil");

  // Various attempts to illegally change the stone state when the point is
  // already a handicap point or a white setup point
  m_game.handicapPoints = @[pointA1];
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA1 toStoneState:GoColorWhite],
                               NSException, NSInternalInconsistencyException, @"point already in handicapPoints and current node is root node");
  m_game.handicapPoints = @[];

  pointA1.stoneState = GoColorBlack;
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA1 toStoneState:GoColorWhite],
                               NSException, NSInternalInconsistencyException, @"point has black stone on it but is not in GoNodeSetup.blackSetupStones");

  pointA1.stoneState = GoColorWhite;
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack],
                               NSException, NSInternalInconsistencyException, @"point has white stone on it but is not in GoNodeSetup.whiteSetupStones");
  pointA1.stoneState = GoColorNone;

  [m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack];
  [m_game changeSetupPoint:pointA2 toStoneState:GoColorWhite];
  [m_game addEmptyNodeToCurrentGameVariation];

  pointA1.stoneState = GoColorNone;
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack],
                               NSException, NSInternalInconsistencyException, @"point has no stone on it but is not in GoNodeSetup.noSetupStones");
  pointA1.stoneState = GoColorBlack;

  [m_game changeSetupPoint:pointA2 toStoneState:GoColorBlack];
  pointA2.stoneState = GoColorNone;
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA2 toStoneState:GoColorWhite],
                               NSException, NSInternalInconsistencyException, @"point has no black stone on it, but is in GoNodeSetup.blackSetupStones");
  pointA2.stoneState = GoColorBlack;

  [m_game changeSetupPoint:pointA1 toStoneState:GoColorWhite];
  pointA1.stoneState = GoColorNone;
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack],
                               NSException, NSInternalInconsistencyException, @"point has no white stone on it, but is in GoNodeSetup.whiteSetupStones");
  pointA1.stoneState = GoColorWhite;

  [m_game changeSetupPoint:pointA1 toStoneState:GoColorNone];
  pointA1.stoneState = GoColorBlack;
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA1 toStoneState:GoColorWhite],
                               NSException, NSInternalInconsistencyException, @"point has a stone on it, but is in GoNodeSetup.noSetupStones");
  pointA1.stoneState = GoColorNone;

  // Various attempts to illegally change the stone state when the game state is
  // not correct
  [m_game pass];
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack],
                               NSException, NSInternalInconsistencyException, @"game aleady has moves");
  [self discardLeafNodeAndSyncBoardPosition];
  [m_game resign];
  XCTAssertThrowsSpecificNamed([m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack],
                               NSException, NSInternalInconsistencyException, @"game aleady has ended");
  [m_game revertStateFromEndedToInProgress];

  // Change is allowed for computer vs. computer games in paused state
  m_game.type = GoGameTypeComputerVsComputer;
  [m_game pause];
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack];
}

// -----------------------------------------------------------------------------
/// @brief Exercises the discardAllSetupStones() method.
// -----------------------------------------------------------------------------
- (void) testDiscardAllSetupStones
{
  GoPoint* pointA1 = [m_game.board pointAtVertex:@"A1"];
  GoPoint* pointB1 = [m_game.board pointAtVertex:@"B1"];
  GoPoint* pointA2 = [m_game.board pointAtVertex:@"A2"];

  GoNodeSetup* nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  long long previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Discard when no setup stones exist
  [m_game discardAllSetup];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Discard when no setup stones exist, but handicap
  [m_game toggleHandicapPoint:pointA2];
  [m_game discardAllSetup];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;
  [m_game toggleHandicapPoint:pointA2];
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Discard when setup stones exists
  [m_game changeSetupPoint:pointA1 toStoneState:GoColorBlack];
  [m_game changeSetupPoint:pointB1 toStoneState:GoColorWhite];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNotNil(nodeSetup);
  XCTAssertNotNil(nodeSetup.blackSetupStones);
  XCTAssertNotNil(nodeSetup.whiteSetupStones);
  XCTAssertNil(nodeSetup.noSetupStones);
  XCTAssertEqual(nodeSetup.blackSetupStones.count, 1);
  XCTAssertEqual(nodeSetup.blackSetupStones.firstObject, pointA1);
  XCTAssertEqual(nodeSetup.whiteSetupStones.count, 1);
  XCTAssertEqual(nodeSetup.whiteSetupStones.firstObject, pointB1);
  XCTAssertNotEqual(0, m_game.nodeModel.leafNode.zobristHash);
  XCTAssertNotEqual(previousZobristHash, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;
  [m_game discardAllSetup];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Discard when setupFirstMoveColor is set
  [m_game changeSetupFirstMoveColor:GoColorBlack];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNotNil(nodeSetup);
  XCTAssertEqual(GoColorBlack, nodeSetup.setupFirstMoveColor);
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;
  [m_game discardAllSetup];
  nodeSetup = m_game.nodeModel.leafNode.goNodeSetup;
  XCTAssertNil(nodeSetup);
  XCTAssertEqual(0, m_game.nodeModel.leafNode.zobristHash);
  previousZobristHash = m_game.nodeModel.leafNode.zobristHash;

  // Various attempts to illegally discard setup stones when the game state is
  // not correct
  [m_game pass];
  XCTAssertThrowsSpecificNamed([m_game discardAllSetup],
                               NSException, NSInternalInconsistencyException, @"game aleady has moves");
  [self discardLeafNodeAndSyncBoardPosition];
  [m_game resign];
  XCTAssertThrowsSpecificNamed([m_game discardAllSetup],
                               NSException, NSInternalInconsistencyException, @"game aleady has ended");
  [m_game revertStateFromEndedToInProgress];

  // Discard is allowed for computer vs. computer games in paused state
  m_game.type = GoGameTypeComputerVsComputer;
  [m_game pause];
  [m_game discardAllSetup];
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
/// (again)"). Exercises the isLegalMove() method.
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

// -----------------------------------------------------------------------------
/// @brief Regression test for GitHub issue 289 ("Ko detection does not work
/// correctly if old board position is viewed"). Exercises the isLegalMove()
/// method.
// -----------------------------------------------------------------------------
- (void) testIssue289
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
  newGameModel.koRule = GoKoRuleSuperkoPositional;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;

  [m_game play:[m_game.board pointAtVertex:@"A2"]];
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  m_game.boardPosition.currentBoardPosition -= 1;

  GoPoint* point = [m_game.board pointAtVertex:@"B1"];
  enum GoMoveIsIllegalReason illegalReason;
  XCTAssertTrue([m_game isLegalMove:point isIllegalReason:&illegalReason]);
}

// -----------------------------------------------------------------------------
/// @brief Regression test for GitHub issue 307 ("Ko not detected if old board
/// position is viewed"). Exercises the isLegalMove() method.
// -----------------------------------------------------------------------------
- (void) testIssue307
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
  newGameModel.koRule = GoKoRuleSimple;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;

  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game play:[m_game.board pointAtVertex:@"A2"]];
  [m_game play:[m_game.board pointAtVertex:@"B2"]];
  [m_game pass];
  [m_game play:[m_game.board pointAtVertex:@"C1"]];
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  // Black playing on A1 would be illegal, but black does not do that. Instead
  // Black plays E5, or anywhere else on the board that is not related to the
  // ko situation.
  [m_game play:[m_game.board pointAtVertex:@"E5"]];
  // Go back one position. Black playing on A1 is still illegal
  m_game.boardPosition.currentBoardPosition -= 1;

  GoPoint* point = [m_game.board pointAtVertex:@"A1"];
  enum GoMoveIsIllegalReason illegalReason;
  XCTAssertFalse([m_game isLegalMove:point isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSimpleKo);
}

// -----------------------------------------------------------------------------
/// @brief Tests whether a simple ko is found when some of the stones are
/// placed via stone setup and the first player to move is set up prior to the
/// first move. Exercises the isLegalMove() method.
// -----------------------------------------------------------------------------
- (void) testSetupAndSimpleKo
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
  newGameModel.koRule = GoKoRuleSimple;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;

  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"A2"] toStoneState:GoColorBlack];
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"B1"] toStoneState:GoColorBlack];

  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"B2"] toStoneState:GoColorWhite];
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"C1"] toStoneState:GoColorWhite];

  [m_game changeSetupFirstMoveColor:GoColorWhite];

  // White captures the black stone on B1
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  // Black cannot immediately capture back
  GoPoint* point = [m_game.board pointAtVertex:@"B1"];
  enum GoMoveIsIllegalReason illegalReason;
  XCTAssertFalse([m_game isLegalMove:point isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSimpleKo);
}

// -----------------------------------------------------------------------------
/// @brief Tests whether a positional ko is found when some of the stones are
/// placed via stone setup and the first player to move is set up prior to the
/// first move. Exercises the isLegalMove() method.
// -----------------------------------------------------------------------------
- (void) testSetupAndPositionalSuperko;
{
  NewGameModel* newGameModel = m_delegate.theNewGameModel;
  newGameModel.koRule = GoKoRuleSuperkoPositional;
  enum GoMoveIsIllegalReason illegalReason;

  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  [self setupAndPlayUntilAlmostPositionalSuperko];
  GoPoint* point1 = [m_game.board pointAtVertex:@"B1"];
  XCTAssertFalse([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSuperko);

  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  [self setupAndPlayUntilAlmostSituationalSuperko];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  XCTAssertFalse([m_game isLegalMove:point2 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSuperko);
}

// -----------------------------------------------------------------------------
/// @brief Tests whether a situational ko is found when some of the stones are
/// placed via stone setup and the first player to move is set up prior to the
/// first move. Exercises the isLegalMove() method.
// -----------------------------------------------------------------------------
- (void) testSetupAndSituationalSuperko
{
  NewGameModel* newGameModel = m_delegate.theNewGameModel;
  newGameModel.koRule = GoKoRuleSuperkoSituational;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  enum GoMoveIsIllegalReason illegalReason;

  [self setupAndPlayUntilAlmostPositionalSuperko];
  GoPoint* point1 = [m_game.board pointAtVertex:@"B1"];
  // Positional superko does not trigger situational superko
  XCTAssertTrue([m_game isLegalMove:point1 isIllegalReason:&illegalReason]);

  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  [self setupAndPlayUntilAlmostSituationalSuperko];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  XCTAssertFalse([m_game isLegalMove:point2 isIllegalReason:&illegalReason]);
  XCTAssertEqual(illegalReason, GoMoveIsIllegalReasonSuperko);
}

// -----------------------------------------------------------------------------
/// @brief Private helper method of testSetupAndPositionalSuperko() and
/// testSetupAndSituationalSuperko().
// -----------------------------------------------------------------------------
- (void) setupAndPlayUntilAlmostPositionalSuperko
{
  // This re-creates the position achieved in
  // playUntilAlmostPositionalSuperko() - see the comments in that method
  // for explanations.
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"B1"] toStoneState:GoColorBlack];
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"C2"] toStoneState:GoColorBlack];
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"D1"] toStoneState:GoColorBlack];

  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"A2"] toStoneState:GoColorWhite];
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"B2"] toStoneState:GoColorWhite];

  [m_game changeSetupFirstMoveColor:GoColorWhite];

  [m_game play:[m_game.board pointAtVertex:@"D2"]];
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game play:[m_game.board pointAtVertex:@"C1"]];
}

// -----------------------------------------------------------------------------
/// @brief Private helper method of testSetupAndPositionalSuperko() and
/// testSetupAndSituationalSuperko().
// -----------------------------------------------------------------------------
- (void) setupAndPlayUntilAlmostSituationalSuperko
{
  // This re-creates the position achieved in
  // playUntilAlmostSituationalSuperko() - see the comments in that method
  // for explanations.
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"B1"] toStoneState:GoColorBlack];
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"C2"] toStoneState:GoColorBlack];
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"D1"] toStoneState:GoColorBlack];

  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"A2"] toStoneState:GoColorWhite];
  [m_game changeSetupPoint:[m_game.board pointAtVertex:@"B2"] toStoneState:GoColorWhite];

  [m_game changeSetupFirstMoveColor:GoColorWhite];

  [m_game pass];
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game play:[m_game.board pointAtVertex:@"C1"]];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for various test methods. Discards the leaf node in
/// the current game's GoNodeModel and adjusts the current game's
/// GoBoardPosition accordingly.
// -----------------------------------------------------------------------------
- (void) discardLeafNodeAndSyncBoardPosition
{
  m_game.boardPosition.currentBoardPosition--;
  m_game.boardPosition.numberOfBoardPositions--;
  [m_game.nodeModel discardLeafNode];
}

@end
