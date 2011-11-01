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
#import "../../gtp/GtpResponse.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoUtilities.h"
#import "../../player/Player.h"
#import "../../player/GtpEngineSettings.h"
#import "../../newgame/NewGameModel.h"


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
- (void) setupGtpHandicapAndKomi;
- (void) setupComputerPlayer;
- (void) triggerComputerPlayer;
//@}
@end


@implementation NewGameCommand

@synthesize shouldSetupGtpBoard;
@synthesize shouldSetupGtpHandicapAndKomi;
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
  self.shouldSetupGtpHandicapAndKomi = true;
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
  if (self.shouldSetupGtpHandicapAndKomi)
    [self setupGtpHandicapAndKomi];
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
/// @brief Performs handicap and komi setup of the GTP engine using values
/// obtained from NewGameModel.
// -----------------------------------------------------------------------------
- (void) setupGtpHandicapAndKomi
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  NewGameModel* model = appDelegate.newGameModel;
  GoGame* game = [GoGame sharedGame];

  // Setup handicap only if there is one. The GTP command "fixed_handicap"
  // accepts only values >= 2.
  if (model.handicap >= 2)
  {
    GtpCommand* commandFixedHandicap = [GtpCommand command:[NSString stringWithFormat:@"fixed_handicap %d", model.handicap]];
    commandFixedHandicap.waitUntilDone = true;
    [commandFixedHandicap submit];
    if (commandFixedHandicap.response.status)
    {
      // The GTP specs say that "fixed_handicap" must return a vertex list, but
      // currently Fuego does not return such a list
      // -> therefore we have to get the handicap vertexes by issuing an
      //    explicit query
      NSString* handicapInfoFromGtp = commandFixedHandicap.response.parsedResponse;
      if (handicapInfoFromGtp.length == 0)
      {
        GtpCommand* commandListHandicap = [GtpCommand command:@"list_handicap"];
        commandListHandicap.waitUntilDone = true;
        [commandListHandicap submit];
        if (commandListHandicap.response.status)
          handicapInfoFromGtp = commandListHandicap.response.parsedResponse;
      }
      [GoUtilities setupNewGame:game withGtpHandicap:handicapInfoFromGtp];
    }
  }

  // There is no universal default value for komi, so to be on the sure side we
  // always have to setup komi.
  GtpCommand* commandKomi = [GtpCommand command:[NSString stringWithFormat:@"komi %.1f", model.komi]];
  commandKomi.waitUntilDone = true;
  [commandKomi submit];
  if (commandKomi.response.status)
    game.komi = model.komi;
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
