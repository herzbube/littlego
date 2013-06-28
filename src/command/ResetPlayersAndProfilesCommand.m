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


// Project includes
#import "ResetPlayersAndProfilesCommand.h"
#import "backup/CleanBackupSgfCommand.h"
#import "game/NewGameCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../newgame/NewGameModel.h"
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
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  [applicationDelegate.playerModel resetToRegistrationDomainDefaults];
  [applicationDelegate.gtpEngineProfileModel resetToRegistrationDomainDefaults];
  // Preserve those user preferences in NewGameModel that are not related to
  // players and profiles
  NewGameModel* newGameModel = applicationDelegate.theNewGameModel;
  enum GoGameType gameType = newGameModel.gameType;
  enum GoGameType gameTypeLastSelected = newGameModel.gameTypeLastSelected;
  bool computerPlaysWhite = newGameModel.computerPlaysWhite;
  enum GoBoardSize boardSize = newGameModel.boardSize;
  int handicap = newGameModel.handicap;
  double komi = newGameModel.komi;
  [newGameModel resetToRegistrationDomainDefaults];
  newGameModel.gameType = gameType;
  newGameModel.gameTypeLastSelected = gameTypeLastSelected;
  newGameModel.computerPlaysWhite = computerPlaysWhite;
  newGameModel.boardSize = boardSize;
  newGameModel.handicap = handicap;
  newGameModel.komi = komi;
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
