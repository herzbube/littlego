// -----------------------------------------------------------------------------
// Copyright 2013-2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "ResetPlayersAndProfilesCommand.h"
#import "backup/CleanBackupSgfCommand.h"
#import "game/NewGameCommand.h"
#import "../main/ModelProvider.h"
#import "../main/Registry.h"
#import "../newgame/NewGameModel.h"
#import "../play/model/TimeSettingsModel.h"
#import "../player/PlayerModel.h"
#import "../player/GtpEngineProfileModel.h"


@implementation ResetPlayersAndProfilesCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center postNotificationName:playersAndProfilesWillReset object:nil];
  [self resetUserDefaultsToRegistrationDomainDefaults];
  [self startNewGame];
  [center postNotificationName:playersAndProfilesDidReset object:nil];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) resetUserDefaultsToRegistrationDomainDefaults
{
  id<ModelProvider> modelProvider = [Registry sharedRegistry].modelProvider;
  [modelProvider.playerModel resetToRegistrationDomainDefaults];
  [modelProvider.gtpEngineProfileModel resetToRegistrationDomainDefaults];

  // Preserve those user preferences in NewGameModel that are not related to
  // players and profiles
  NewGameModel* newGameModel = modelProvider.theNewGameModel;
  enum GoGameType gameType = newGameModel.gameType;
  enum GoGameType gameTypeLastSelected = newGameModel.gameTypeLastSelected;
  bool computerPlaysWhite = newGameModel.computerPlaysWhite;
  enum GoBoardSize boardSize = newGameModel.boardSize;
  int handicap = newGameModel.handicap;
  double komi = newGameModel.komi;
  enum GoKoRule koRule = newGameModel.koRule;
  enum GoScoringSystem scoringSystem = newGameModel.scoringSystem;
  enum GoLifeAndDeathSettlingRule lifeAndDeathSettlingRule = newGameModel.lifeAndDeathSettlingRule;
  enum GoDisputeResolutionRule disputeResolutionRule = newGameModel.disputeResolutionRule;
  enum GoFourPassesRule fourPassesRule = newGameModel.fourPassesRule;
  NSMutableDictionary* timeSettingsDictionary = [NSMutableDictionary dictionary];
  [newGameModel.timeSettingsModel writeToDictionary:timeSettingsDictionary];

  [newGameModel resetToRegistrationDomainDefaults];

  newGameModel.gameType = gameType;
  newGameModel.gameTypeLastSelected = gameTypeLastSelected;
  newGameModel.computerPlaysWhite = computerPlaysWhite;
  newGameModel.boardSize = boardSize;
  newGameModel.handicap = handicap;
  newGameModel.komi = komi;
  newGameModel.koRule = koRule;
  newGameModel.scoringSystem = scoringSystem;
  newGameModel.lifeAndDeathSettlingRule = lifeAndDeathSettlingRule;
  newGameModel.disputeResolutionRule = disputeResolutionRule;
  newGameModel.fourPassesRule = fourPassesRule;
  [newGameModel.timeSettingsModel readFromDictionary:timeSettingsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) startNewGame
{
  [[[[CleanBackupSgfCommand alloc] init] autorelease] submit];
  [[[[NewGameCommand alloc] init] autorelease] submit];
}

@end
