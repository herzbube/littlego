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
#import "NewGameCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../gtp/GtpUtilities.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoUtilities.h"
#import "../../player/Player.h"
#import "../../newgame/NewGameModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NewGameCommand.
// -----------------------------------------------------------------------------
@interface NewGameCommand()
@property(nonatomic, assign) GoGame* prefabricatedGame;
@end


@implementation NewGameCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a NewGameCommand object that creates its own GoGame
/// instance.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithGame:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a NewGameCommand object. If @a game is not nil,
/// NewGameCommand will use this pre-fabricated GoGame object for its operation.
/// If @a game is nil, NewGameCommand will create its own GoGame instance.
///
/// @note This is the designated initializer of NewGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)game
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;
  self.prefabricatedGame = game;
  self.shouldSetupGtpBoard = true;
  self.shouldSetupGtpHandicapAndKomi = true;
  self.shouldSetupComputerPlayer = true;
  self.shouldTriggerComputerPlayer = true;
  return self;
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
    [GtpUtilities setupComputerPlayer];
  if (self.shouldTriggerComputerPlayer)
    [self triggerComputerPlayer];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new GoGame instance (deallocates the old one first).
// -----------------------------------------------------------------------------
- (void) newGame
{
  // Send this while the old GoGame object is still around and fully functional
  // (the old game is nil if this happens during application startup)
  GoGame* oldGame = [GoGame sharedGame];
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameWillCreate object:oldGame];

  // Create the new GoGame object (unless a pre-fabricated object was supplied)
  // TODO: Prevent starting a new game if the defaults are somehow invalid
  // (currently known: player UUID may refer to a player that has been removed)
  GoGame* newGame;
  if (! self.prefabricatedGame)
  {
    newGame = [[[GoGame alloc] init] autorelease];
    DDLogVerbose(@"%@: Created new game %@", [self shortDescription], newGame);
  }
  else
  {
    newGame = self.prefabricatedGame;
    DDLogVerbose(@"%@: Using pre-fabricated game %@", [self shortDescription], newGame);
  }

  // Replace the delegate's reference; an old GoGame object is now deallocated
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  appDelegate.game = newGame;
  DDLogVerbose(@"%@: Assigned game object to app delegate", [self shortDescription]);

  // Configure the new GoGame object (not necessary for pre-fabricated games)
  if (! self.prefabricatedGame)
  {
    NewGameModel* newGameModel = appDelegate.theNewGameModel;
    newGame.board = [GoBoard boardWithDefaultSize];
    newGame.komi = newGameModel.komi;
    newGame.handicapPoints = [GoUtilities pointsForHandicap:newGameModel.handicap inGame:newGame];
    newGame.playerBlack = [GoPlayer defaultBlackPlayer];
    newGame.playerWhite = [GoPlayer defaultWhitePlayer];
    newGame.type = newGameModel.gameType;
  }
  DDLogVerbose(@"%@: Game object configuration: board = %@, komi = %.1f, handicapPoints = %@, playerBlack = %@ (uuid = %@), playerWhite = %@ (uuid = %@), type = %d",
               [self shortDescription],
               newGame.board,
               newGame.komi,
               newGame.handicapPoints,
               newGame.playerBlack,
               newGame.playerBlack.player.uuid,
               newGame.playerWhite,
               newGame.playerWhite.player.uuid,
               newGame.type);

  // Send this only after GoGame and its dependents have been fully configured.
  // Receivers will probably want to know stuff like the board size and what
  // game type this is.
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameDidCreate object:newGame];
}

// -----------------------------------------------------------------------------
/// @brief Performs the board setup of the GTP engine using values obtained
/// from the current GoGame.
// -----------------------------------------------------------------------------
- (void) setupGtpBoard
{
  GoBoard* board = [GoGame sharedGame].board;
  [[GtpCommand command:@"clear_board"] submit];
  [[GtpCommand command:[NSString stringWithFormat:@"boardsize %d", board.size]] submit];
}

// -----------------------------------------------------------------------------
/// @brief Performs handicap and komi setup of the GTP engine using values
/// obtained from the current GoGame.
// -----------------------------------------------------------------------------
- (void) setupGtpHandicapAndKomi
{
  GoGame* game = [GoGame sharedGame];

  // Setup handicap only if there is one. The GTP command "fixed_handicap"
  // accepts only values >= 2. This should not be a problem since our own
  // handicap selection screen does not offer to select handicap 1.
  int handicap = game.handicapPoints.count;
  if (handicap >= 2)
  {
    GtpCommand* commandFixedHandicap = [GtpCommand command:[NSString stringWithFormat:@"fixed_handicap %d", handicap]];
    [commandFixedHandicap submit];
    assert(commandFixedHandicap.response.status);
  }

  // There is no universal default value for komi, so to be on the sure side we
  // always have to setup komi.
  GtpCommand* commandKomi = [GtpCommand command:[NSString stringWithFormat:@"komi %.1f", game.komi]];
  [commandKomi submit];
  assert(commandKomi.response.status);
}

// -----------------------------------------------------------------------------
/// @brief Triggers the computer player to make a move, if it is his turn.
// -----------------------------------------------------------------------------
- (void) triggerComputerPlayer
{
  if ([[GoGame sharedGame] isComputerPlayersTurn])
    [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
}

@end
