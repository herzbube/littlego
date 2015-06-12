// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "GtpUtilities.h"
#import "GtpCommand.h"
#import "../go/GoGame.h"
#import "../go/GoPlayer.h"
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"
#import "../player/Player.h"


@implementation GtpUtilities

// -----------------------------------------------------------------------------
/// @brief Returns the Player object that provides the current game's active
/// GTP engine profile.
///
/// The following rules are observed:
/// - Computer vs. human game: Returns the computer player
/// - Computer vs. computer game: Returns the black computer player
/// - Human vs. human game: Returns nil
///
/// @see GtpUtilities::setupComputerPlayer()
// -----------------------------------------------------------------------------
+ (Player*) playerProvidingActiveProfile
{
  GoGame* game = [GoGame sharedGame];
  if (GoGameTypeHumanVsHuman == game.type)
  {
    return nil;
  }
  else
  {
    Player* blackPlayer = game.playerBlack.player;
    if (! blackPlayer.isHuman)
      return blackPlayer;
    else
      return game.playerWhite.player;
  }
}

// -----------------------------------------------------------------------------
/// @brief Applies settings to the GTP engine that are obtained from the current
/// game's computer player in the form of a GtpEngineProfile object.
///
/// The following rules are observed:
/// - Computer vs. human game: Applies the settings obtained from the computer
///   player
/// - Computer vs. computer game: Applies the settings obtained from the black
///   computer player
/// - Human vs. human game: There is no computer player. As a fallback the
///   settings from the special "human vs. human games" GTP engine profile are
///   applied.
// -----------------------------------------------------------------------------
+ (void) setupComputerPlayer
{
  GtpEngineProfile* profileToActivate = nil;
  Player* player = [GtpUtilities playerProvidingActiveProfile];
  if (player)
    profileToActivate = [player gtpEngineProfile];
  else
    profileToActivate = [[ApplicationDelegate sharedDelegate].gtpEngineProfileModel fallbackProfile];

  // Invoking applyProfile makes the profile the active profile
  if (profileToActivate)
    [profileToActivate applyProfile];
  else
    DDLogError(@"GtpUtilities::setupComputerPlayer(): Unable to determine profile with computer player settings");
}

// -----------------------------------------------------------------------------
/// @brief Tells the GTP engine to start pondering.
// -----------------------------------------------------------------------------
+ (void) startPondering
{
  GtpCommand* command = [GtpCommand command:@"uct_param_player ponder 1"];
  command.waitUntilDone = false;
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Tells the GTP engine to stop pondering.
// -----------------------------------------------------------------------------
+ (void) stopPondering
{
  GtpCommand* command = [GtpCommand command:@"uct_param_player ponder 0"];
  command.waitUntilDone = false;
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Restores the GTP engine's "pondering" state to the state prescribed
/// by the active GTP engine profile.
// -----------------------------------------------------------------------------
+ (void) restorePondering
{
  GtpEngineProfile* profile = [[ApplicationDelegate sharedDelegate].gtpEngineProfileModel activeProfile];
  if (! profile)
    DDLogError(@"GtpUtilities::restorePondering(): Unable to determine profile with computer player settings");
  else if (profile.fuegoPondering)
    [GtpUtilities startPondering];
  else
    [GtpUtilities stopPondering];
}


@end
