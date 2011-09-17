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
#import "../move/ComputerPlayMoveCommand.h"
#import "../../ApplicationDelegate.h"
#import "../../gtp/GtpCommand.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../player/Player.h"
#import "../../player/GtpEngineSettings.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for NewGameCommand.
// -----------------------------------------------------------------------------
@interface NewGameCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Helpers
//@{
- (void) newGame;
- (void) setupGtpBoard;
- (void) setupComputerPlayer;
- (void) triggerComputerPlayer;
//@}
@end


@implementation NewGameCommand

@synthesize shouldSetupGtpBoard;
@synthesize shouldSetupComputerPlayer;
@synthesize shouldTriggerComputerPlayer;


// -----------------------------------------------------------------------------
/// @brief Initializes a NewGameCommand object.
///
/// @note This is the designated initializer of NewGameCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.shouldSetupGtpBoard = true;
  self.shouldSetupComputerPlayer = true;
  self.shouldTriggerComputerPlayer = true;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NewGameCommand object.
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
  [self newGame];
  if (self.shouldSetupGtpBoard)
    [self setupGtpBoard];
  if (self.shouldSetupComputerPlayer)
    [self setupComputerPlayer];
  if (self.shouldTriggerComputerPlayer)
    [self triggerComputerPlayer];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new GoGame instance (deallocates the old one first).
// -----------------------------------------------------------------------------
- (void) newGame
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  // De-allocate the old game *BEFORE* creating a new one. Go objects attached
  // to the old game need to be able to access their instance using GoGame's
  // class method sharedGame().
  // TODO: Remove this comment and statement as soon as Go objects no longer
  // rely on sharedGame().
  appDelegate.game = nil;
  if ([GoGame sharedGame])
  {
    NSException* exception = [NSException exceptionWithName:@"SharedGameException"
                                                     reason:@"The shared GoGame object was not deallocated as expected."
                                                   userInfo:nil];
    @throw exception;
  }

  // TODO: Prevent starting a new game if the defaults are somehow invalid
  // (currently known: player UUID may refer to a player that has been removed)
  GoGame* newGame = [GoGame newGame];
  appDelegate.game = newGame;
}

// -----------------------------------------------------------------------------
/// @brief Performs the board setup of the GTP engine using values obtained
/// from the current GoGame.
// -----------------------------------------------------------------------------
- (void) setupGtpBoard
{
  GoBoard* board = [GoGame sharedGame].board;
  [[GtpCommand command:@"clear_board"] submit];
  [[GtpCommand command:[NSString stringWithFormat:@"boardsize %d", board.dimensions]] submit];
}

// -----------------------------------------------------------------------------
/// @brief Configures the GTP engine with settings obtained from the current
/// game's computer player.
///
/// Prefers the black computer player if both players are computer players.
// -----------------------------------------------------------------------------
- (void) setupComputerPlayer
{
  GoGame* game = [GoGame sharedGame];
  if (HumanVsHumanGame != game.type)
  {
    Player* computerPlayerWithGtpSettings = game.playerBlack.player;
    if (computerPlayerWithGtpSettings.isHuman)
    {
      computerPlayerWithGtpSettings = game.playerWhite.player;
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
}

// -----------------------------------------------------------------------------
/// @brief Triggers the computer player to make a move, if it is his turn.
// -----------------------------------------------------------------------------
- (void) triggerComputerPlayer
{
  if ([[GoGame sharedGame] isComputerPlayersTurn])
  {
    ComputerPlayMoveCommand* command = [[ComputerPlayMoveCommand alloc] init];
    [command submit];
  }
}

@end
