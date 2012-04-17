// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Creates and submits a GTP command using @a commandString.
///
/// If @a wait is true, the command is executed synchronously. This method does
/// not return, instead it waits until the response for the command has been
/// received, then it invokes @a aSelector on @a aTarget with the response
/// object as the single argument.
///
/// If @a wait is false, the command is executed asynchronously and this method
/// returns immediately. When the response for the command has been received,
/// @a selector will be invoked on @a aTarget.
// -----------------------------------------------------------------------------
+ (void) submitCommand:(NSString*)commandString target:(id)aTarget selector:(SEL)aSelector waitUntilDone:(bool)wait
{
  GtpCommand* command;
  if (wait)
  {
    command = [GtpCommand command:commandString];
    command.waitUntilDone = true;
  }
  else
  {
    command = [GtpCommand command:commandString
                   responseTarget:aTarget
                         selector:aSelector];
  }
  [command submit];
  if (wait)
  {
    [aTarget performSelector:aSelector withObject:command.response];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the GtpEngineProfile object that is active for the game that
/// is currently in progress.
///
/// The following rules are observed:
/// - Computer vs. human game: Returns the profile of the computer player
/// - Human vs. human game: Returns the default profile
/// - Computer vs. computer game: Returns the profile of the black computer
///   player
// -----------------------------------------------------------------------------
+ (GtpEngineProfile*) activeProfile
{
  GoGame* game = [GoGame sharedGame];
  if (GoGameTypeHumanVsHuman == game.type)
    return [[ApplicationDelegate sharedDelegate].gtpEngineProfileModel defaultProfile];
  else
  {
    Player* blackPlayer = game.playerBlack.player;
    if (! blackPlayer.isHuman)
      return [blackPlayer gtpEngineProfile];
    else
      return [game.playerWhite.player gtpEngineProfile];
  }
}

// -----------------------------------------------------------------------------
/// @brief Configures the GTP engine with settings obtained from the current
/// game's computer player.
///
/// Prefers the black computer player if both players are computer players.
/// If neither player is a computer player, the settings obtained from the
/// default GTP engine profile are applied.
// -----------------------------------------------------------------------------
+ (void) setupComputerPlayer
{
  GtpEngineProfile* profile = [GtpUtilities activeProfile];
  if (profile)
    [profile applyProfile];
  else
    DDLogError(@"GtpUtilities::setupComputerPlayer(): Unable to determine profile with computer player settings");
}

// -----------------------------------------------------------------------------
/// @brief Tells the GTP engine to start pondering.
// -----------------------------------------------------------------------------
+ (void) startPondering
{
  NSString* commandString = @"uct_param_player ponder 1";
  [[GtpCommand command:commandString] submit];
}

// -----------------------------------------------------------------------------
/// @brief Tells the GTP engine to stop pondering.
// -----------------------------------------------------------------------------
+ (void) stopPondering
{
  NSString* commandString = @"uct_param_player ponder 0";
  [[GtpCommand command:commandString] submit];
}

// -----------------------------------------------------------------------------
/// @brief Restores the GTP engine's "pondering" state to the state prescribed
/// by the active GTP engine profile (see activeProfile:()).
// -----------------------------------------------------------------------------
+ (void) restorePondering
{
  GtpEngineProfile* profile = [GtpUtilities activeProfile];
  if (! profile)
    DDLogError(@"GtpUtilities::restorePondering(): Unable to determine profile with computer player settings");
  else if (profile.fuegoPondering)
    [GtpUtilities startPondering];
  else
    [GtpUtilities stopPondering];
}


@end
