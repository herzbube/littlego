// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import <go/GoGame.h>


@implementation GoGameTest

// -----------------------------------------------------------------------------
/// @brief Exercises the sharedGame() class method.
// -----------------------------------------------------------------------------
- (void) testSharedGame
{
  STAssertEquals(m_game, [GoGame sharedGame], nil);
}

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of a GoGame object after it has been
/// created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  STAssertEquals(ComputerVsHumanGame, m_game.type, @"game type test failed");
  STAssertNotNil(m_game.board, nil);
  STAssertNotNil(m_game.playerBlack, nil);
  STAssertNotNil(m_game.playerWhite, nil);
  STAssertEquals(m_game.currentPlayer, m_game.playerBlack, nil);
  STAssertNil(m_game.firstMove, nil);
  STAssertNil(m_game.lastMove, nil);
  STAssertEquals(GameHasNotYetStarted, m_game.state, @"game state test failed");
  STAssertFalse(m_game.isComputerThinking, nil);
}

@end
