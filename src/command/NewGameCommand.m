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


// Project includes
#import "NewGameCommand.h"
#import "move/ComputerPlayMoveCommand.h"
#import "../ApplicationDelegate.h"
#import "../go/GoGame.h"
#import "../go/GoPlayer.h"
#import "../player/Player.h"
#import "../player/GtpEngineSettings.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for NewGameCommand.
// -----------------------------------------------------------------------------
@interface NewGameCommand()
- (void) dealloc;
@end


@implementation NewGameCommand

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CommandBase object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  // De-allocate the old game *BEFORE* creating a new one. Go objects attached
  // to the old game need to be able to access their instance using GoGame's
  // class method sharedGame().
  // TODO: Remove this comment and statement as soon as Go objects no longer
  // rely on sharedGame().
  appDelegate.game = nil;
  // TODO: Prevent starting a new game if the defaults are somehow invalid
  // (currently known: player UUID may refer to a player that has been removed)
  GoGame* newGame = [GoGame newGame];
  appDelegate.game = newGame;

  // Configure the GTP engine with settings from the computer player (preferring
  // the black computer player if both players are computer players)
  if (HumanVsHumanGame != newGame.type)
  {
    Player* computerPlayerWithGtpSettings = newGame.playerBlack.player;
    if (computerPlayerWithGtpSettings.isHuman)
    {
      computerPlayerWithGtpSettings = newGame.playerWhite.player;
      assert(! computerPlayerWithGtpSettings.isHuman);
    }
    else
    {
      // TODO notify user that we ignore the white player's settings;
      // alternatively let the user choose which player's settings should be
      // used
    }
    [computerPlayerWithGtpSettings.gtpEngineSettings applySettings];
  }

  if ([newGame isComputerPlayersTurn])
    [[[ComputerPlayMoveCommand alloc] init] submit];

  return true;
}

@end
