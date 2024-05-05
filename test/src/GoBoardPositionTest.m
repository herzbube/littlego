// -----------------------------------------------------------------------------
// Copyright 2013-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoBoardPositionTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoBoardPosition.h>
#import <go/GoGame.h>
#import <go/GoGameAdditions.h>
#import <go/GoNode.h>
#import <go/GoNodeModel.h>
#import <go/GoPoint.h>
#import <go/GoUtilities.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoBoardPositionTest.
// -----------------------------------------------------------------------------
@interface GoBoardPositionTest()
@property(nonatomic, assign) int numberOfNotificationsReceived;
@end


@implementation GoBoardPositionTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoBoardPosition object after a new
/// GoGame has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertNotNil(boardPosition);
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 1);
  XCTAssertTrue(boardPosition.isFirstPosition);
  XCTAssertTrue(boardPosition.isLastPosition);
  XCTAssertNotNil(boardPosition.currentNode);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  XCTAssertFalse(m_game.nextMovePlayerIsComputerPlayer);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the changeToLastBoardPositionWithoutUpdatingGoObjects()
/// class method.
// -----------------------------------------------------------------------------
- (void) testChangeToLastBoardPositionWithoutUpdatingGoObjects
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 1);

  // Increase number of board positions
  int newNumberOfBoardPositions = 42;
  int expectedNewCurrentBoardPosition = newNumberOfBoardPositions - 1;
  boardPosition.numberOfBoardPositions = newNumberOfBoardPositions;
  [boardPosition changeToLastBoardPositionWithoutUpdatingGoObjects];
  XCTAssertEqual(boardPosition.currentBoardPosition, expectedNewCurrentBoardPosition);

  // Decrease number of board positions
  newNumberOfBoardPositions = 5;
  expectedNewCurrentBoardPosition = newNumberOfBoardPositions - 1;
  boardPosition.numberOfBoardPositions = newNumberOfBoardPositions;
  [boardPosition changeToLastBoardPositionWithoutUpdatingGoObjects];
  XCTAssertEqual(boardPosition.currentBoardPosition, expectedNewCurrentBoardPosition);

  // No change in number of board positions
  [boardPosition changeToLastBoardPositionWithoutUpdatingGoObjects];
  XCTAssertEqual(boardPosition.currentBoardPosition, expectedNewCurrentBoardPosition);

  // Impossible number of board positions (in practice there always is at least
  // 1 board position, because the root node cannot be discarded)
  newNumberOfBoardPositions = 0;
  expectedNewCurrentBoardPosition = newNumberOfBoardPositions - 1;
  boardPosition.numberOfBoardPositions = newNumberOfBoardPositions;
  [boardPosition changeToLastBoardPositionWithoutUpdatingGoObjects];
  XCTAssertEqual(boardPosition.currentBoardPosition, expectedNewCurrentBoardPosition);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e currentBoardPosition property.
// -----------------------------------------------------------------------------
- (void) testCurrentBoardPosition
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);

  // Setup
  GoPoint* setupStonePoint1 = [m_game.board pointAtVertex:@"A2"];
  GoPoint* setupStonePoint2 = [m_game.board pointAtVertex:@"A1"];
  GoPoint* setupStonePoint3 = [m_game.board pointAtVertex:@"G3"];
  enum GoColor setupFirstMoveColor = GoColorWhite;
  enum GoColor opponentColor = GoColorBlack;
  [m_game changeSetupPoint:setupStonePoint1 toStoneState:setupFirstMoveColor];
  [m_game changeSetupPoint:setupStonePoint2 toStoneState:opponentColor];
  enum GoColor setupStoneColor1 = GoColorBlack;
  [m_game changeSetupPoint:setupStonePoint3 toStoneState:setupStoneColor1];
  [m_game addEmptyNodeToCurrentGameVariation];
  [m_game changeSetupFirstMoveColor:setupFirstMoveColor];
  enum GoColor setupStoneColor2 = GoColorWhite;
  [m_game changeSetupPoint:setupStonePoint3 toStoneState:GoColorWhite];
  GoPoint* moveStonePoint = [m_game.board pointAtVertex:@"B1"];  // captures B on A1
  [m_game play:moveStonePoint];
  [m_game pass];
  XCTAssertEqual(boardPosition.currentBoardPosition, 3);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertTrue(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  XCTAssertEqual(setupStonePoint1.stoneState, setupFirstMoveColor);
  XCTAssertEqual(setupStonePoint2.stoneState, GoColorNone);
  XCTAssertEqual(setupStonePoint3.stoneState, setupStoneColor2);
  XCTAssertEqual(moveStonePoint.stoneState, setupFirstMoveColor);
  XCTAssertEqual(m_game.board.regions.count, 5);

  // Backward, just one position => take back pass move
  boardPosition.currentBoardPosition--;
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertFalse(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  XCTAssertEqual(setupStonePoint1.stoneState, setupFirstMoveColor);
  XCTAssertEqual(setupStonePoint2.stoneState, GoColorNone);
  XCTAssertEqual(setupStonePoint3.stoneState, setupStoneColor2);
  XCTAssertEqual(moveStonePoint.stoneState, setupFirstMoveColor);
  XCTAssertEqual(m_game.board.regions.count, 5);

  // Backward, just one position => take back capturing move
  boardPosition.currentBoardPosition--;
  XCTAssertEqual(boardPosition.currentBoardPosition, 1);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertFalse(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  XCTAssertEqual(setupStonePoint1.stoneState, setupFirstMoveColor);
  XCTAssertEqual(setupStonePoint2.stoneState, opponentColor);
  XCTAssertEqual(setupStonePoint3.stoneState, setupStoneColor2);
  XCTAssertEqual(moveStonePoint.stoneState, GoColorNone);
  XCTAssertEqual(m_game.board.regions.count, 4);

  // Backward, more than one position, to the first position
  boardPosition.currentBoardPosition = 0;
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertTrue(boardPosition.isFirstPosition);
  XCTAssertFalse(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorNone);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  XCTAssertEqual(setupStonePoint1.stoneState, setupFirstMoveColor);
  XCTAssertEqual(setupStonePoint2.stoneState, opponentColor);
  XCTAssertEqual(setupStonePoint3.stoneState, setupStoneColor1);
  XCTAssertEqual(moveStonePoint.stoneState, GoColorNone);
  XCTAssertEqual(m_game.board.regions.count, 4);

  // Forward, just one position
  boardPosition.currentBoardPosition++;
  XCTAssertEqual(boardPosition.currentBoardPosition, 1);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertFalse(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  XCTAssertEqual(setupStonePoint1.stoneState, setupFirstMoveColor);
  XCTAssertEqual(setupStonePoint2.stoneState, opponentColor);
  XCTAssertEqual(setupStonePoint3.stoneState, setupStoneColor2);
  XCTAssertEqual(moveStonePoint.stoneState, GoColorNone);
  XCTAssertEqual(m_game.board.regions.count, 4);

  // Forward, more than one position, to the last position
  boardPosition.currentBoardPosition = (boardPosition.numberOfBoardPositions - 1);
  XCTAssertEqual(boardPosition.currentBoardPosition, 3);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 4);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertTrue(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.setupFirstMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  XCTAssertEqual(setupStonePoint1.stoneState, setupFirstMoveColor);
  XCTAssertEqual(setupStonePoint2.stoneState, GoColorNone);
  XCTAssertEqual(setupStonePoint3.stoneState, setupStoneColor2);
  XCTAssertEqual(moveStonePoint.stoneState, setupFirstMoveColor);
  XCTAssertEqual(m_game.board.regions.count, 5);

  // Same position => does not update state of Go model objects
  m_game.nextMoveColor = GoColorBlack;
  boardPosition.currentBoardPosition = boardPosition.currentBoardPosition;
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);

  XCTAssertThrowsSpecificNamed(boardPosition.currentBoardPosition = -1,
                              NSException, NSRangeException, @"negative board position");
  XCTAssertThrowsSpecificNamed(boardPosition.currentBoardPosition = boardPosition.numberOfBoardPositions,
                              NSException, NSRangeException, @"board position too high");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e currentNode property.
// -----------------------------------------------------------------------------
- (void) testCurrentNode
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  GoNode* nodeBoardPosition0 = boardPosition.currentNode;
  XCTAssertNotNil(nodeBoardPosition0);
  XCTAssertEqual(nodeBoardPosition0, m_game.nodeModel.rootNode);

  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  GoNode* nodeBoardPosition1 = boardPosition.currentNode;
  XCTAssertNotNil(nodeBoardPosition1);
  XCTAssertNotEqual(nodeBoardPosition1, m_game.nodeModel.rootNode);
  XCTAssertEqual(nodeBoardPosition1, m_game.nodeModel.leafNode);

  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  GoNode* nodeBoardPosition2 = boardPosition.currentNode;
  XCTAssertNotNil(nodeBoardPosition2);
  XCTAssertNotEqual(nodeBoardPosition2, m_game.nodeModel.rootNode);
  XCTAssertNotEqual(nodeBoardPosition2, nodeBoardPosition1);
  XCTAssertEqual(nodeBoardPosition2, m_game.nodeModel.leafNode);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e isFirstPosition property.
// -----------------------------------------------------------------------------
- (void) testIsFirstPosition
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertTrue(boardPosition.isFirstPosition);

  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertFalse(boardPosition.isFirstPosition);

  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertFalse(boardPosition.isFirstPosition);

  boardPosition.currentBoardPosition--;
  XCTAssertFalse(boardPosition.isFirstPosition);

  boardPosition.currentBoardPosition--;
  XCTAssertTrue(boardPosition.isFirstPosition);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e isLastPosition property.
// -----------------------------------------------------------------------------
- (void) testIsLastPosition
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertTrue(boardPosition.isLastPosition);

  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertTrue(boardPosition.isLastPosition);

  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertTrue(boardPosition.isLastPosition);

  boardPosition.currentBoardPosition--;
  XCTAssertFalse(boardPosition.isLastPosition);

  boardPosition.currentBoardPosition--;
  XCTAssertFalse(boardPosition.isLastPosition);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e numberOfBoardPositions property.
// -----------------------------------------------------------------------------
- (void) testNumberOfBoardPositions
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 1);

  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 2);

  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);

  // Tests from here on are slightly pointless because the property setter has
  // no logic => arbitrary values can be set even if they do not make sense. The
  // reason is that it must be possible to adjust the number of board positions
  // before nodes are discarded from the node model.

  // More board positions than there are nodes
  boardPosition.numberOfBoardPositions = 42;

  // Less board positions than there are nodes
  boardPosition.numberOfBoardPositions = 1;

  // Impossible number of board positions (in practice there always is at least
  // 1 board position, because the root node cannot be discarded)
  boardPosition.numberOfBoardPositions = 0;

  // Even a negative number can be set
  boardPosition.numberOfBoardPositions = -1;
}

// -----------------------------------------------------------------------------
/// @brief Verifies that the notification #boardPositionChangeProgress is sent
/// when the property @e currentBoardPosition is changed.
// -----------------------------------------------------------------------------
- (void) testBoardPositionChangeProgress
{
  GoBoardPosition* boardPosition = m_game.boardPosition;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(boardPositionChangeProgress:) name:boardPositionChangeProgress object:nil];

  self.numberOfNotificationsReceived = 0;
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertEqual(1, self.numberOfNotificationsReceived);

  self.numberOfNotificationsReceived = 0;
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  XCTAssertEqual(1, self.numberOfNotificationsReceived);

  self.numberOfNotificationsReceived = 0;
  boardPosition.currentBoardPosition--;
  XCTAssertEqual(1, self.numberOfNotificationsReceived);

  self.numberOfNotificationsReceived = 0;
  boardPosition.currentBoardPosition = 0;
  XCTAssertEqual(1, self.numberOfNotificationsReceived);

  self.numberOfNotificationsReceived = 0;
  boardPosition.currentBoardPosition = (boardPosition.numberOfBoardPositions - 1);
  XCTAssertEqual(2, self.numberOfNotificationsReceived);

  self.numberOfNotificationsReceived = 0;
  XCTAssertThrowsSpecificNamed(boardPosition.currentBoardPosition = -1,
                              NSException, NSRangeException, @"negative board position");
  XCTAssertEqual(0, self.numberOfNotificationsReceived);

  [center removeObserver:self];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardPositionChangeProgress notification. This is
/// a private helper for testBoardPositionChangeProgress().
// -----------------------------------------------------------------------------
- (void) boardPositionChangeProgress:(NSNotification*)notification
{
  self.numberOfNotificationsReceived++;
}

@end
