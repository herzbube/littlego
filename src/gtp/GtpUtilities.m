// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Applies settings to the GTP engine that are obtained from the current
/// game's computer player in the form of a GtpEngineProfile object.
///
/// The following rules are observed:
/// - Computer vs. human game: Applies the settings obtained from the computer
///   player
/// - Computer vs. computer game: Applies the settings obtained from the black
///   computer player
/// - Human vs. human game: There is no computer player. As a fallback the
///   settings from the default GTP engine profile are applied.
// -----------------------------------------------------------------------------
+ (void) setupComputerPlayer
{
  GtpEngineProfile* profileToActivate = nil;
  GoGame* game = [GoGame sharedGame];
  if (GoGameTypeHumanVsHuman == game.type)
    profileToActivate = [[ApplicationDelegate sharedDelegate].gtpEngineProfileModel defaultProfile];
  else
  {
    Player* blackPlayer = game.playerBlack.player;
    if (! blackPlayer.isHuman)
      profileToActivate = [blackPlayer gtpEngineProfile];
    else
      profileToActivate = [game.playerWhite.player gtpEngineProfile];
  }

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
