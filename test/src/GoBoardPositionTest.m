// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import <go/GoMoveModel.h>
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
  STAssertNotNil(boardPosition, nil);
  STAssertEquals(boardPosition.currentBoardPosition, 0, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 1, nil);
  STAssertTrue(boardPosition.isFirstPosition, nil);
  STAssertTrue(boardPosition.isLastPosition, nil);
  STAssertNil(boardPosition.currentMove, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerBlack , nil);
  STAssertFalse(boardPosition.isComputerPlayersTurn, nil);
}

// -----------------------------------------------------------------------------
/// @brief Checks the state of the GoBoardPosition object after a game with
/// handicap has been created.
// -----------------------------------------------------------------------------
- (void) testStateWithHandicap
{
  m_game.handicapPoints = [GoUtilities pointsForHandicap:5 inGame:m_game];

  GoBoardPosition* boardPosition = m_game.boardPosition;
  STAssertNotNil(boardPosition, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerWhite , nil);
}

// -----------------------------------------------------------------------------
/// @brief Checks the state of the GoBoardPosition object after a move has been
/// played.
// -----------------------------------------------------------------------------
- (void) testStateAfterPlay
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  STAssertNotNil(boardPosition, nil);
  STAssertEquals(boardPosition.currentBoardPosition, 0, nil);
  // Playing a move automatically advances the board position
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  STAssertEquals(boardPosition.currentBoardPosition, 1, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 2, nil);
  STAssertFalse(boardPosition.isFirstPosition, nil);
  STAssertTrue(boardPosition.isLastPosition, nil);
  STAssertNotNil(boardPosition.currentMove, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerWhite , nil);
  STAssertFalse(boardPosition.isComputerPlayersTurn, nil);
  // Position is also advanced for passing
  [m_game pass];
  STAssertEquals(boardPosition.currentBoardPosition, 2, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 3, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerBlack , nil);
  // Resigning is not a move, so no
  [m_game resign];
  STAssertEquals(boardPosition.currentBoardPosition, 2, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 3, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerBlack , nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises assigning a value to the @e currentBoardPosition property.
// -----------------------------------------------------------------------------
- (void) testPositionChange
{
  // Setup
  GoBoardPosition* boardPosition = m_game.boardPosition;
  STAssertNotNil(boardPosition, nil);
  STAssertEquals(boardPosition.currentBoardPosition, 0, nil);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game pass];
  STAssertEquals(boardPosition.currentBoardPosition, 2, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 3, nil);
  STAssertFalse(boardPosition.isFirstPosition, nil);
  STAssertTrue(boardPosition.isLastPosition, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerBlack , nil);
  // Backward, just one position
  boardPosition.currentBoardPosition--;
  STAssertEquals(boardPosition.currentBoardPosition, 1, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 3, nil);
  STAssertFalse(boardPosition.isFirstPosition, nil);
  STAssertFalse(boardPosition.isLastPosition, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerWhite , nil);
  // Backward, to the special position zero
  boardPosition.currentBoardPosition--;
  STAssertEquals(boardPosition.currentBoardPosition, 0, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 3, nil);
  STAssertTrue(boardPosition.isFirstPosition, nil);
  STAssertFalse(boardPosition.isLastPosition, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerBlack , nil);
  // Forward, more than one position, to the last position
  boardPosition.currentBoardPosition = (boardPosition.numberOfBoardPositions - 1);
  STAssertEquals(boardPosition.currentBoardPosition, 2, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 3, nil);
  STAssertFalse(boardPosition.isFirstPosition, nil);
  STAssertTrue(boardPosition.isLastPosition, nil);
  STAssertEquals(boardPosition.currentPlayer, m_game.playerBlack , nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises assigning a negative value to the @e currentBoardPosition
/// property.
// -----------------------------------------------------------------------------
- (void) testOutOfBoundsPositionNegative
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  STAssertNotNil(boardPosition, nil);
  STAssertThrowsSpecificNamed(boardPosition.currentBoardPosition = -1,
                              NSException, NSRangeException, @"negative board position");
}

// -----------------------------------------------------------------------------
/// @brief Exercises assigning a value to the @e currentBoardPosition property
/// that is higher than the maximum allowed value.
// -----------------------------------------------------------------------------
- (void) testOutOfBoundsPositionTooHigh
{
  GoBoardPosition* boardPosition = m_game.boardPosition;
  STAssertNotNil(boardPosition, nil);
  STAssertThrowsSpecificNamed(boardPosition.currentBoardPosition = boardPosition.numberOfBoardPositions,
                              NSException, NSRangeException, @"board position too high");
}

// -----------------------------------------------------------------------------
/// @brief Checks the state of the GoBoardPosition object after a move has been
/// discarded.
// -----------------------------------------------------------------------------
- (void) testStateAfterDiscard
{
  // Setup
  GoBoardPosition* boardPosition = m_game.boardPosition;
  STAssertNotNil(boardPosition, nil);
  STAssertEquals(boardPosition.currentBoardPosition, 0, nil);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game pass];
  STAssertEquals(boardPosition.currentBoardPosition, 2, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 3, nil);

  // Discarding automatically adjusts the board position
  GoMoveModel* moveModel = m_game.moveModel;
  STAssertNotNil(moveModel, nil);
  STAssertEquals(moveModel.numberOfMoves, 2, nil);
  [moveModel discardMovesFromIndex:1];
  STAssertEquals(boardPosition.currentBoardPosition, 1, nil);
  STAssertEquals(boardPosition.numberOfBoardPositions, 2, nil);
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
  STAssertEquals(GoColorBlack, point1.stoneState, nil);
  STAssertEquals(GoColorNone, point2.stoneState, nil);
  STAssertEquals(GoColorBlack, point3.stoneState, nil);
  expectedNumberOfRegions = 4;
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);

  // Take back capturing move
  GoBoardPosition* boardPosition = m_game.boardPosition;
  boardPosition.currentBoardPosition--;
  STAssertEquals(GoColorBlack, point1.stoneState, nil);
  STAssertEquals(GoColorWhite, point2.stoneState, nil);
  STAssertEquals(GoColorNone, point3.stoneState, nil);
  expectedNumberOfRegions = 3;
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);

  // Go back to the beginning of the game
  boardPosition.currentBoardPosition = 0;
  STAssertEquals(GoColorNone, point1.stoneState, nil);
  STAssertEquals(GoColorNone, point2.stoneState, nil);
  STAssertEquals(GoColorNone, point3.stoneState, nil);
  expectedNumberOfRegions = 1;
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);

  // Forward again to the last board position
  boardPosition.currentBoardPosition = (boardPosition.numberOfBoardPositions - 1);
  STAssertEquals(GoColorBlack, point1.stoneState, nil);
  STAssertEquals(GoColorNone, point2.stoneState, nil);
  STAssertEquals(GoColorBlack, point3.stoneState, nil);
  expectedNumberOfRegions = 4;
  STAssertEquals(expectedNumberOfRegions, m_game.board.regions.count, nil);
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
  STAssertEquals(0, self.receiveIndexOfNumberOfBoardPositionsNotification, nil);
  STAssertEquals(1, self.receiveIndexOfCurrentBoardPositionNotification, nil);
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
