// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "../ChangeUIAreaPlayModeCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../gtp/GtpUtilities.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameRules.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoScore.h"
#import "../../go/GoUtilities.h"
#import "../../play/model/BoardSetupModel.h"
#import "../../player/Player.h"
#import "../../player/PlayerModel.h"
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
  self.shouldResetUIAreaPlayMode = true;
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
  if (self.shouldResetUIAreaPlayMode)
    [self resetUIAreaPlayMode];
  [self newGame];
  [self setupGtpRules];
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
/// @brief Resets the UI area "Play" to #UIAreaPlayModePlay.
// -----------------------------------------------------------------------------
- (void) resetUIAreaPlayMode
{
  // When a new game is started it is especially important to disable scoring
  // mode while the old GoGame is still around because scoring mode affects the
  // state of some Go model objects.
  enum UIAreaPlayMode uiAreaPlayMode;
  if ([ApplicationDelegate sharedDelegate].boardSetupModel.autoEnableBoardSetupMode)
    uiAreaPlayMode = UIAreaPlayModeBoardSetup;
  else
    uiAreaPlayMode = UIAreaPlayModePlay;

  [[[[ChangeUIAreaPlayModeCommand alloc] initWithUIAreayPlayMode:uiAreaPlayMode] autorelease] submit];
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

  // Configure the new GoGame object. A pre-fabricated game must be configured
  // by the client.
  if (! self.prefabricatedGame)
  {
    NewGameModel* newGameModel = appDelegate.theNewGameModel;
    newGame.board = [GoBoard boardWithDefaultSize];
    newGame.komi = newGameModel.komi;
    newGame.handicapPoints = [GoUtilities pointsForHandicap:newGameModel.handicap inGame:newGame];
    newGame.playerBlack = [GoPlayer defaultBlackPlayer];
    if (! newGame.playerBlack)
    {
      [self createEmergencyPlayerUsingColor:GoColorBlack];
      newGame.playerBlack = [GoPlayer defaultBlackPlayer];
    }
    newGame.playerWhite = [GoPlayer defaultWhitePlayer];
    if (! newGame.playerWhite)
    {
      [self createEmergencyPlayerUsingColor:GoColorWhite];
      newGame.playerWhite = [GoPlayer defaultWhitePlayer];
    }
    newGame.type = newGameModel.gameType;
    newGame.rules.koRule = newGameModel.koRule;
    newGame.rules.scoringSystem = newGameModel.scoringSystem;
    if (newGameModel.gameType == GoGameTypeComputerVsComputer)
    {
      newGame.rules.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleTwoPasses;
      newGame.rules.disputeResolutionRule = GoDisputeResolutionRuleAlternatingPlay;
      newGame.rules.fourPassesRule = GoFourPassesRuleFourPassesHaveNoSpecialMeaning;
    }
    else
    {
      newGame.rules.lifeAndDeathSettlingRule = newGameModel.lifeAndDeathSettlingRule;
      newGame.rules.disputeResolutionRule = newGameModel.disputeResolutionRule;
      newGame.rules.fourPassesRule = newGameModel.fourPassesRule;
    }
  }
  DDLogVerbose((@"%@: Game object configuration: board = %@, "
                "komi = %.1f, handicapPoints = %@, "
                "playerBlack = %@ (uuid = %@), playerWhite = %@ (uuid = %@), "
                "type = %d, "
                "koRule = %d, scoringSystem = %d, "
                "lifeAndDeathSettlingRule = %d, disputeResolutionRule = %d, fourPassesRule = %d"),
               [self shortDescription],
               newGame.board,
               newGame.komi,
               newGame.handicapPoints,
               newGame.playerBlack,
               newGame.playerBlack.player.uuid,
               newGame.playerWhite,
               newGame.playerWhite.player.uuid,
               newGame.type,
               newGame.rules.koRule,
               newGame.rules.scoringSystem,
               newGame.rules.lifeAndDeathSettlingRule,
               newGame.rules.disputeResolutionRule,
               newGame.rules.fourPassesRule);

  // Send this only after GoGame and its dependents have been fully configured.
  // Receivers will probably want to know stuff like the board size and what
  // game type this is.
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameDidCreate object:newGame];
}

// -----------------------------------------------------------------------------
/// @brief Creates a new Player object that matches the characteristics in
/// NewGameModel for color @a color.
///
/// This is a private helper for newGame().
///
/// This method is designed to be invoked as an emergency (e.g. during
/// application launch) when the user preferences in NewGameModel refer to a
/// Player that does not exist in the user preferences in PlayerModel. This
/// method fixes the inconsistency in the user preferences data by creating a
/// new Player object.
///
/// When this method returns, the caller can expect that invoking either
/// GoPlayer::defaultBlackPlayer() or GoPlayer::defaultWhitePlayer() (which it
/// is depends on @a color) will return a valid GoPlayer object.
// -----------------------------------------------------------------------------
- (void) createEmergencyPlayerUsingColor:(enum GoColor)color
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  NewGameModel* newGameModel = appDelegate.theNewGameModel;
  PlayerModel* playerModel = appDelegate.playerModel;

  NSString* playerUUID = nil;
  bool playerIsBlack;
  switch (color)
  {
    case GoColorBlack:
    {
      playerUUID = [newGameModel blackPlayerUUID];
      playerIsBlack = true;
      break;
    }
    case GoColorWhite:
    {
      playerUUID = [newGameModel whitePlayerUUID];
      playerIsBlack = false;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Illegal GoColor value %d", color];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }

  Player* newPlayer = [[[Player alloc] initWithUUID:playerUUID] autorelease];
  bool newPlayerIsHuman;
  switch (newGameModel.gameType)
  {
    case GoGameTypeHumanVsHuman:
    {
      newPlayerIsHuman = true;
      break;
    }
    case GoGameTypeComputerVsComputer:
    {
      newPlayerIsHuman = false;
      break;
    }
    case GoGameTypeComputerVsHuman:
    {
      if (newGameModel.computerPlaysWhite)
        newPlayerIsHuman = playerIsBlack;
      else
        newPlayerIsHuman = !playerIsBlack;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Illegal GoGameType value %d", newGameModel.gameType];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
  newPlayer.human = newPlayerIsHuman;
  newPlayer.name = @"Auto-created player";
  [playerModel add:newPlayer];

  NSString* errorMessage = [NSString stringWithFormat:@"Auto-created new Player object, UUID = %@, name = %@, human = %d",
                            newPlayer.uuid,
                            newPlayer.name,
                            newPlayer.human];
  DDLogError(@"%@: %@", [self shortDescription], errorMessage);
}

// -----------------------------------------------------------------------------
/// @brief Configures the GTP engine with a number of rules how to play the
/// game.
// -----------------------------------------------------------------------------
- (void) setupGtpRules
{
  [self setupKoRule];
  [self setupScoringSystem];
  [self setupHandicapCompensation];
}

// -----------------------------------------------------------------------------
/// @brief Configures the GTP engine with the ko rule to use.
// -----------------------------------------------------------------------------
- (void) setupKoRule
{
  enum GoKoRule koRule = [GoGame sharedGame].rules.koRule;
  NSString* gtpKoRuleName;
  switch (koRule)
  {
    case GoKoRuleSimple:
      gtpKoRuleName = @"simple";
      break;
    case GoKoRuleSuperkoPositional:
      gtpKoRuleName = @"pos_superko";
      break;
    case GoKoRuleSuperkoSituational:
      gtpKoRuleName = @"superko";
      break;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Illegal GoKoRule value %d", koRule];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
  NSString* commandString = [NSString stringWithFormat:@"go_param_rules ko_rule %@", gtpKoRuleName];
  [[GtpCommand command:commandString] submit];
}

// -----------------------------------------------------------------------------
/// @brief Configures the GTP engine with the scoring system to use.
// -----------------------------------------------------------------------------
- (void) setupScoringSystem
{
  enum GoScoringSystem scoringSystem = [GoGame sharedGame].rules.scoringSystem;
  int japaneseScoring;
  switch (scoringSystem)
  {
    case GoScoringSystemAreaScoring:
      japaneseScoring = 0;
      break;
    case GoScoringSystemTerritoryScoring:
      japaneseScoring = 1;
      break;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Illegal GoScoringSystem value %d", scoringSystem];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
  NSString* commandString = [NSString stringWithFormat:@"go_param_rules japanese_scoring %d", japaneseScoring];
  [[GtpCommand command:commandString] submit];
  
}

// -----------------------------------------------------------------------------
/// @brief Configures the GTP engine with the handicap compensation rule to use.
// -----------------------------------------------------------------------------
- (void) setupHandicapCompensation
{
  enum GoScoringSystem scoringSystem = [GoGame sharedGame].rules.scoringSystem;
  int handicapCompensation;
  switch (scoringSystem)
  {
    case GoScoringSystemAreaScoring:
      handicapCompensation = 1;
      break;
    case GoScoringSystemTerritoryScoring:
      handicapCompensation = 0;
      break;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Illegal GoScoringSystem value %d", scoringSystem];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
  NSString* commandString = [NSString stringWithFormat:@"go_param_rules extra_handicap_komi %d", handicapCompensation];
  [[GtpCommand command:commandString] submit];
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

  // The previously sent GTP command "clear_board" has left Fuego without a
  // handicap, so we need to setup handicap only if there is one. The GTP
  // command "set_free_handicap" accepts only a list with more than 2 vertices.
  // This should not be a problem since our own handicap selection screen does
  // not offer to select handicap 1.
  NSUInteger handicap = game.handicapPoints.count;
  if (handicap >= 2)
  {
    NSString* verticesString = [GoUtilities verticesStringForPoints:game.handicapPoints];
    NSString* commandString = [@"set_free_handicap " stringByAppendingString:verticesString];
    GtpCommand* commandFixedHandicap = [GtpCommand command:commandString];
    [commandFixedHandicap submit];
    assert(commandFixedHandicap.response.status);
  }

  // The previously sent GTP command "clear_board" has caused Fuego to reset
  // komi to the last value that was explicitly set with the GTP command "komi"
  // (or to the built-in default komi value, in case no "komi" command was ever
  // sent). Therefore, unlike handicap we always have to setup komi.
  GtpCommand* commandKomi = [GtpCommand command:[NSString stringWithFormat:@"komi %.1f", game.komi]];
  [commandKomi submit];
  assert(commandKomi.response.status);
}

// -----------------------------------------------------------------------------
/// @brief Triggers the computer player to make a move, if it is his turn.
// -----------------------------------------------------------------------------
- (void) triggerComputerPlayer
{
  if ([GoGame sharedGame].nextMovePlayerIsComputerPlayer)
    [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
}

@end
