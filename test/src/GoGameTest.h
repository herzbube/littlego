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


// Project includes
#import "BaseTestCase.h"


// -----------------------------------------------------------------------------
/// @brief The GoGameTest class contains unit tests that exercise the GoGame
/// class.
// -----------------------------------------------------------------------------
@interface GoGameTest : BaseTestCase
{
}

- (void) testSharedGame;
- (void) testInitialState;
- (void) testType;
- (void) testBoard;
- (void) testHandicapPoints;
- (void) testNextMoveColorAndNextMovePlayer;
- (void) testNextMovePlayerIsComputerPlayer;
- (void) testAlternatingPlayEnabled;
- (void) testAlternatingPlayDisabled;
- (void) testFirstMove;
- (void) testLastMove;
- (void) testState;
- (void) testReasonForGameHasEnded;
- (void) testZobristHashAfterHandicap;
- (void) testPlay;
- (void) testPass;
- (void) testResign;
- (void) testPause;
- (void) testContinue;
- (void) testIsLegalBoardSetupAt;
- (void) testIsLegalBoardSetup;
- (void) testIsLegalMove;
- (void) testIsLegalMovePositionalSuperko;
- (void) testIsLegalMoveSituationalSuperko;
- (void) testIsLegalPassMoveIllegalReason;
- (void) testEndGameDueToPassMovesIfGameRulesRequireIt;
- (void) testRevertStateFromEndedToInProgress;
- (void) testSwitchNextMoveColor;
- (void) testToggleHandicapPoint;
- (void) testAddEmptyNodeToCurrentGameVariation;
- (void) testChangeSetupFirstMoveColor;
- (void) testChangeSetupPoint;
- (void) testDiscardAllSetupStones;
- (void) testDiscardCausesRegionToFragment;
- (void) testIssue2;
- (void) testIssue289;
- (void) testIssue307;
- (void) testSetupAndSimpleKo;
- (void) testSetupAndPositionalSuperko;
- (void) testSetupAndSituationalSuperko;

@end
