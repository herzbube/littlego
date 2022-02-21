// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import <go/GoNode.h>
#import <go/GoNodeModel.h>
#import <go/GoPoint.h>
#import <go/GoUtilities.h>

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoBoardPositionTest.
// -----------------------------------------------------------------------------
@interface GoBoardPositionTest()
@property(nonatomic, assign) int numberOfNotificationsReceived;
@property(nonatomic, assign) int receiveIndexOfNumberOfBoardPositionsNotification;
@property(nonatomic, assign) int receiveIndexOfCurrentBoardPositionNotification;
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
  XCTAssertNil(boardPosition.currentNode.goMove);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  XCTAssertFalse(m_game.nextMovePlayerIsComputerPlayer);
}

// -----------------------------------------------------------------------------
/// @brief Checks the state of the GoBoardPosition object after a game with
/// handicap has been created.
// -----------------------------------------------------------------------------
- (void) testStateWithHandicap
{
  m_game.handicapPoints = [GoUtilities pointsForHandicap:5 inGame:m_game];

  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertNotNil(boardPosition);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
}

// -----------------------------------------------------------------------------
/// @brief Checks the state of the GoBoardPosition object after a move has been
/// played.
// -----------------------------------------------------------------------------
- (void) testStateAfterPlay
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertNotNil(boardPosition);
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);
  // Playing a move automatically advances the board position
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  XCTAssertEqual(boardPosition.currentBoardPosition, 1);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 2);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertTrue(boardPosition.isLastPosition);
  XCTAssertNotNil(boardPosition.currentNode);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  XCTAssertFalse(m_game.nextMovePlayerIsComputerPlayer);
  // Position is also advanced for passing
  [m_game pass];
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  // Resigning is not a move, so no
  [m_game resign];
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
}

// -----------------------------------------------------------------------------
/// @brief Exercises assigning a value to the @e currentBoardPosition property.
// -----------------------------------------------------------------------------
- (void) testPositionChange
{
  // Setup
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertNotNil(boardPosition);
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game pass];
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertTrue(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  // Backward, just one position
  boardPosition.currentBoardPosition--;
  XCTAssertEqual(boardPosition.currentBoardPosition, 1);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertFalse(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.nextMoveColor, GoColorWhite);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerWhite);
  // Backward, to the special position zero
  boardPosition.currentBoardPosition--;
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertTrue(boardPosition.isFirstPosition);
  XCTAssertFalse(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
  // Forward, more than one position, to the last position
  boardPosition.currentBoardPosition = (boardPosition.numberOfBoardPositions - 1);
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);
  XCTAssertFalse(boardPosition.isFirstPosition);
  XCTAssertTrue(boardPosition.isLastPosition);
  XCTAssertEqual(m_game.nextMoveColor, GoColorBlack);
  XCTAssertEqual(m_game.nextMovePlayer, m_game.playerBlack);
}

// -----------------------------------------------------------------------------
/// @brief Exercises assigning a negative value to the @e currentBoardPosition
/// property.
// -----------------------------------------------------------------------------
- (void) testOutOfBoundsPositionNegative
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertNotNil(boardPosition);
  XCTAssertThrowsSpecificNamed(boardPosition.currentBoardPosition = -1,
                              NSException, NSRangeException, @"negative board position");
}

// -----------------------------------------------------------------------------
/// @brief Exercises assigning a value to the @e currentBoardPosition property
/// that is higher than the maximum allowed value.
// -----------------------------------------------------------------------------
- (void) testOutOfBoundsPositionTooHigh
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertNotNil(boardPosition);
  XCTAssertThrowsSpecificNamed(boardPosition.currentBoardPosition = boardPosition.numberOfBoardPositions,
                              NSException, NSRangeException, @"board position too high");
}

// -----------------------------------------------------------------------------
/// @brief Checks the state of the GoBoardPosition object after a node has been
/// discarded.
// -----------------------------------------------------------------------------
- (void) testStateAfterDiscard
{
  // Setup
  GoBoardPosition* boardPosition = m_game.boardPosition;
  XCTAssertNotNil(boardPosition);
  XCTAssertEqual(boardPosition.currentBoardPosition, 0);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game pass];
  XCTAssertEqual(boardPosition.currentBoardPosition, 2);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 3);

  // Discarding automatically adjusts the board position
  GoNodeModel* nodeModel = m_game.nodeModel;
  XCTAssertNotNil(nodeModel);
  XCTAssertEqual(nodeModel.numberOfNodes, 3);
  XCTAssertEqual(nodeModel.numberOfMoves, 2);
  [nodeModel discardNodesFromIndex:2];
  XCTAssertEqual(boardPosition.currentBoardPosition, 1);
  XCTAssertEqual(boardPosition.numberOfBoardPositions, 2);
}

// -----------------------------------------------------------------------------
/// @brief Checks the state of GoPoint and other Go objects after the current
/// board position changes.
// -----------------------------------------------------------------------------
- (void) testBoardStateAfterPositionChange
{
  NSUInteger expectedNumberOfRegions;
  GoPoint* point1 = [m_game.board pointAtVertex:@"A2"];
  GoPoint* point2 = [m_game.board pointAtVertex:@"A1"];
  GoPoint* point3 = [m_game.board pointAtVertex:@"B1"];
  [m_game play:point1];
  [m_game play:point2];
  [m_game play:point3];  // captures W on A1
  XCTAssertEqual(GoColorBlack, point1.stoneState);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(GoColorBlack, point3.stoneState);
  expectedNumberOfRegions = 4;
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);

  // Take back capturing move
  GoBoardPosition* boardPosition = m_game.boardPosition;
  boardPosition.currentBoardPosition--;
  XCTAssertEqual(GoColorBlack, point1.stoneState);
  XCTAssertEqual(GoColorWhite, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);
  expectedNumberOfRegions = 3;
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);

  // Go back to the beginning of the game
  boardPosition.currentBoardPosition = 0;
  XCTAssertEqual(GoColorNone, point1.stoneState);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(GoColorNone, point3.stoneState);
  expectedNumberOfRegions = 1;
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);

  // Forward again to the last board position
  boardPosition.currentBoardPosition = (boardPosition.numberOfBoardPositions - 1);
  XCTAssertEqual(GoColorBlack, point1.stoneState);
  XCTAssertEqual(GoColorNone, point2.stoneState);
  XCTAssertEqual(GoColorBlack, point3.stoneState);
  expectedNumberOfRegions = 4;
  XCTAssertEqual(expectedNumberOfRegions, m_game.board.regions.count);
}

// -----------------------------------------------------------------------------
/// @brief Checks that KVO notifications are sent, and that they are sent in
/// the order that they are documented.
// -----------------------------------------------------------------------------
- (void) testKVONotifications
{
  self.numberOfNotificationsReceived = 0;
  self.receiveIndexOfNumberOfBoardPositionsNotification = -1;
  self.receiveIndexOfCurrentBoardPositionNotification = -1;

  GoBoardPosition* boardPosition = m_game.boardPosition;
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [m_game pass];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  XCTAssertEqual(0, self.receiveIndexOfNumberOfBoardPositionsNotification);
  XCTAssertEqual(1, self.receiveIndexOfCurrentBoardPositionNotification);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for testKVONotifications().
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"numberOfBoardPositions"])
  {
    self.receiveIndexOfNumberOfBoardPositionsNotification = self.numberOfNotificationsReceived;
    self.numberOfNotificationsReceived++;
  }
  else if ([keyPath isEqualToString:@"currentBoardPosition"])
  {
    self.receiveIndexOfCurrentBoardPositionNotification = self.numberOfNotificationsReceived;
    self.numberOfNotificationsReceived++;
  }
}

@end
