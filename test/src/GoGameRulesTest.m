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
#import "GoGameRulesTest.h"

// Application includes
#import <go/GoGame.h>
#import <go/GoGameRules.h>
#import <command/game/NewGameCommand.h>
#import <main/ApplicationDelegate.h>
#import <newgame/NewGameModel.h>


@implementation GoGameRulesTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of GoGameRules object after a new GoGame
/// has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  XCTAssertNotNil(m_game.rules);
  XCTAssertEqual(m_game.rules.koRule, GoKoRuleSimple);
  XCTAssertEqual(m_game.rules.scoringSystem, GoScoringSystemAreaScoring);
  XCTAssertEqual(m_game.rules.lifeAndDeathSettlingRule, GoLifeAndDeathSettlingRuleTwoPasses);
  XCTAssertEqual(m_game.rules.disputeResolutionRule, GoDisputeResolutionRuleAlternatingPlay);
  XCTAssertEqual(m_game.rules.fourPassesRule, GoFourPassesRuleFourPassesHaveNoSpecialMeaning);
}

// -----------------------------------------------------------------------------
/// @brief Checks that the GoGameRules object takes its rules from the settings
/// in NewGameModel.
// -----------------------------------------------------------------------------
- (void) testNonDefaultRules
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
  newGameModel.koRule = GoKoRuleSuperkoPositional;
  newGameModel.scoringSystem = GoScoringSystemTerritoryScoring;
  newGameModel.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleThreePasses;
  newGameModel.disputeResolutionRule = GoDisputeResolutionRuleNonAlternatingPlay;
  newGameModel.fourPassesRule = GoFourPassesRuleFourPassesEndTheGame;
  [[[[NewGameCommand alloc] init] autorelease] submit];
  m_game = m_delegate.game;
  XCTAssertEqual(m_game.rules.koRule, GoKoRuleSuperkoPositional);
  XCTAssertEqual(m_game.rules.scoringSystem, GoScoringSystemTerritoryScoring);
  XCTAssertEqual(m_game.rules.lifeAndDeathSettlingRule, GoLifeAndDeathSettlingRuleThreePasses);
  XCTAssertEqual(m_game.rules.disputeResolutionRule, GoDisputeResolutionRuleNonAlternatingPlay);
  XCTAssertEqual(m_game.rules.fourPassesRule, GoFourPassesRuleFourPassesEndTheGame);
}

@end
