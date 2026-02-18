// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "ComputerPlayMoveCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../backup/CleanBackupSgfCommand.h"
#import "../game/NewGameCommand.h"
#import "../game/SaveGameCommand.h"
#import "../playerinfluence/UpdateTerritoryStatisticsCommand.h"
#import "../timedplay/TimeLeftCommand.h"
#import "../../archive/ArchiveViewModel.h"
#import "../../diagnostics/LoggingModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoMoveNodeCreationOptions.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
#import "../../main/WindowProvider.h"
#import "../../play/model/GameVariationModel.h"
#import "../../play/timedplay/PlayerClockService.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/UIViewControllerAdditions.h"


/// @brief Enumerates the types of moves that the computer player can generate
enum GtpResponseType
{
  GtpResponseTypePlayStone,
  GtpResponseTypePass,
  GtpResponseTypeResign,
  GtpResponseTypeGtpCommandFailed,
  GtpResponseTypePlayStoneInvalidVertex,
};

/// @brief Enumerates the types of alerts presented by this command.
enum AlertType
{
  AlertTypeComputerPlayedIllegalMoveLoggingEnabled,
  AlertTypeComputerPlayedIllegalMoveLoggingDisabled,
  AlertTypeNewGameAfterComputerPlayedIllegalMove,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ComputerPlayMoveCommand.
// -----------------------------------------------------------------------------
@interface ComputerPlayMoveCommand()
@property(nonatomic, retain) GoPoint* illegalMove;
@end


@implementation ComputerPlayMoveCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a ComputerPlayMoveCommand.
///
/// @note This is the designated initializer of ComputerPlayMoveCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  GoGame* sharedGame = [GoGame sharedGame];
  assert(sharedGame);
  if (! sharedGame)
  {
    DDLogError(@"%@: GoGame object is nil", [self shortDescription]);
    [self release];
    return nil;
  }
  enum GoGameState gameState = sharedGame.state;
  assert(GoGameStateGameHasEnded != gameState);
  if (GoGameStateGameHasEnded == gameState)
  {
    DDLogError(@"%@: Unexpected game state %d", [self shortDescription], gameState);
    [self release];
    return nil;
  }

  self.game = sharedGame;
  self.illegalMove = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ComputerPlayMoveCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  self.illegalMove = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool success;

  success = [self submitTimeLeftCommandToGtpEngine];
  if (! success)
    return false;

  enum PlayerClockStartReason playerClockStartReason = (self.game.nextMovePlayerIsComputerPlayer
                                                        ? PlayerClockStartReasonComputerPlayerTurnBegins
                                                        : PlayerClockStartReasonComputerPlayerStartsThinkingOnBehalfOfHumanPlayer);
  success = [self startPlayerClockIfGameUsesTimedPlay:playerClockStartReason];
  if (! success)
    return false;

  success = [self submitGenmoveCommandToGtpEngine];
  if (! success)
    return false;

  return success;
}

// -----------------------------------------------------------------------------
/// @brief Submits a "time_left" command to the GTP engine. This informs the
/// GTP engine how much time it is allowed to use to calculate a move.
///
/// This is a private helper for doIt.
// -----------------------------------------------------------------------------
- (bool) submitTimeLeftCommandToGtpEngine
{
  // Must be invoked before the player clock is started. See class
  // documentation.
  bool success = [[[[TimeLeftCommand alloc] init] autorelease] submit];
  return success;
}

// -----------------------------------------------------------------------------
/// @brief Submits a "genmove" command to the GTP engine. The response to the
/// command is received and processed asynchronously, i.e. after control returns
/// to the caller. Always returns true.
///
/// This is a private helper for doIt.
// -----------------------------------------------------------------------------
- (bool) submitGenmoveCommandToGtpEngine
{
  self.game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonComputerPlay;

  // It's important that we do not wait for the GTP command to complete. This
  // gives the UI the time to update (e.g. status view, activity indicator).
  NSString* commandString = @"genmove ";
  commandString = [commandString stringByAppendingString:self.game.nextMovePlayer.colorString];
  GtpCommand* command = [GtpCommand asynchronousCommand:commandString
                                         responseTarget:self
                                               selector:@selector(gtpResponseReceived:)];
  [command submit];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is triggered when the GTP engine responds to the command submitted
/// in submitGenmoveCommandToGtpEngine().
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(GtpResponse*)response
{
  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    GoPoint* point;
    enum GtpResponseType responseType = [self evaluateGtpResponse:response point:&point];

    // Abort and don't try to play the move if the player has lost on time. We
    // expect that someone else reacts to the notification that is posted when
    // a player loses on time.
    bool gameContinues = [self stopPlayerClockIfGameUsesTimedPlay:responseType];
    if (! gameContinues)
    {
      self.game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;
      return;
    }

    if (responseType == GtpResponseTypeGtpCommandFailed)
    {
      DDLogError(@"%@: Aborting due to failed GTP command", [self shortDescription]);
      assert(0);
      [self handleComputerFailedToPlay:response.parsedResponse];
      return;
    }
    else if (responseType == GtpResponseTypePlayStoneInvalidVertex)
    {
      DDLogError(@"%@: Invalid vertex %@", [self shortDescription], response.parsedResponse);
      assert(0);
      return;
    }

    bool success = [self playMoveForResponseType:responseType point:point];
    if (! success)
      return;

    // Don't check command execution result, it is irrelevant for us whether the
    // command succeeds or not. There is a known case where the command fails:
    // If statistics collection was enabled while the "genmove" command above
    // was still running. In that case, UpdateTerritoryStatisticsCommand will
    // try to acquire statistics data, but will fail because the GTP engine has
    // not yet collected any data.
    [[[[UpdateTerritoryStatisticsCommand alloc] init] autorelease] submit];

    // If another ComputerPlayMoveCommand is submitted, this returns after the
    // next ComputerPlayMoveCommand has submitted its GTP command
    [self continuePlayingIfNecessary];
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
    [[LongRunningActionCounter sharedCounter] decrement];
  }
}

// -----------------------------------------------------------------------------
/// @brief Evaluates the content of @a response and returns the result. If
/// the result is #GtpResponseTypePlayStone, then the out parameter @a point is
/// filled with a reference to the GoPoint object where the stone should be
/// played. If the result is not #GtpResponseTypePlayStone, then the value of
/// the out parameter @a point is @e nil.
///
/// This is a private helper for gtpResponseReceived.
// -----------------------------------------------------------------------------
- (enum GtpResponseType) evaluateGtpResponse:(GtpResponse*)response point:(GoPoint**)point
{
  *point = nil;

  if (! response.status)
    return GtpResponseTypeGtpCommandFailed;

  NSString* responseString = [response.parsedResponse lowercaseString];
  if ([responseString isEqualToString:@"pass"])
  {
    return GtpResponseTypePass;
  }
  else if ([responseString isEqualToString:@"resign"])
  {
    return GtpResponseTypeResign;
  }
  else
  {
    GoPoint* pointAtVertex = [self.game.board pointAtVertex:responseString];
    if (pointAtVertex)
    {
      *point = pointAtVertex;
      return GtpResponseTypePlayStone;
    }
    else
    {
      return GtpResponseTypePlayStoneInvalidVertex;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief If the game uses timed play, stops the clock of the player on whose
/// behalf the computer played a move. Returns false if the player lost on time,
/// otherwise returns true. Does not do anything and returns true if the game
/// does not use timed play.
///
/// A return value false is unexpected - the computer player is expected to
/// always generate a move within the remaining time. There is a chance, though,
/// that it happens, because the app and the computer player use different
/// clocks.
///
/// This is a private helper for gtpResponseReceived.
// -----------------------------------------------------------------------------
- (bool) stopPlayerClockIfGameUsesTimedPlay:(enum GtpResponseType)responseType
{
  enum PlayerClockStopReason stopReason = (responseType == GtpResponseTypeResign
                                           ? PlayerClockStopReasonPlayerResigns
                                           : PlayerClockStopReasonPlayerTurnEnds);

  id<PlayerClockService> playerClockService = [Registry sharedRegistry].playerClockService;
  enum PlayerClockServiceOperationResult result = [playerClockService stopClockOfPlayer:self.game.nextMovePlayer
                                                                                 reason:stopReason];
  return (result == PlayerClockServiceOperationResultGameContinues);
}

// -----------------------------------------------------------------------------
/// @brief Instructs GoGame to play the move that corresponds to
/// @a responseType. If @a responseType is #GtpResponseTypePlayStone, then
/// @a point is expected to contain the intersection on which to place the
/// stone. Returns true on success, false on failure (e.g. if move was illegal).
///
/// This is a private helper for gtpResponseReceived.
// -----------------------------------------------------------------------------
- (bool) playMoveForResponseType:(enum GtpResponseType)responseType point:(GoPoint*)point
{
  GoMoveNodeCreationOptions* options;
  GameVariationModel* gameVariationModel = [Registry sharedRegistry].modelProvider.gameVariationModel;
  if (gameVariationModel.newMoveInsertPolicy == GoNewMoveInsertPolicyRetainFutureBoardPositions)
    options = [GoMoveNodeCreationOptions moveNodeCreationOptionsWithInsertPolicyRetainFutureBoardPositionsAndInsertPosition:gameVariationModel.newMoveInsertPosition];
  else
    options = [GoMoveNodeCreationOptions moveNodeCreationOptionsWithInsertPolicyReplaceFutureBoardPositions];

  if (responseType == GtpResponseTypePass)
  {
    enum GoMoveIsIllegalReason illegalReason;
    if ([self.game isLegalPassMoveIllegalReason:&illegalReason])
    {
      [self.game passWithMoveNodeCreationOptions:options];
    }
    else
    {
      [self handleComputerPlayedIllegalMove1:illegalReason];
      return false;
    }
  }
  else if (responseType == GtpResponseTypeResign)
  {
    [self.game resign];
  }
  else
  {
    enum GoMoveIsIllegalReason illegalReason;
    if ([self.game isLegalMove:point isIllegalReason:&illegalReason])
    {
      [self.game play:point withMoveNodeCreationOptions:options];
    }
    else
    {
      self.illegalMove = point;
      [self handleComputerPlayedIllegalMove1:illegalReason];
      return false;
    }
  }

  [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when the GTP engine plays a move that Little Go thinks
/// is illegal. Part 1: Offers the user a chance to submit a bug report before
/// the app crashes, or to enable logging if logging is currently turned off.
///
/// This method has been added to gather information in order to fix issue 90
/// on GitHub. This method can be removed as soon the issue has been fixed.
// -----------------------------------------------------------------------------
- (void) handleComputerPlayedIllegalMove1:(enum GoMoveIsIllegalReason)illegalReason
{
  NSString* message = @"The computer played an illegal move. This is almost certainly a bug in Little Go. ";
  enum AlertType alertType;
  bool loggingEnabled = [Registry sharedRegistry].modelProvider.loggingModel.loggingEnabled;
  if (loggingEnabled)
  {
    message = [message stringByAppendingString:@"\n\nWould you like to report this incident now so that we can try to find and fix the bug?"];
    alertType = AlertTypeComputerPlayedIllegalMoveLoggingEnabled;
  }
  else
  {
    message = [message stringByAppendingString:@"You should enable logging now so that you can report the bug when it occurs the next time.\n\nWould you like to enable logging now?"];
    alertType = AlertTypeComputerPlayedIllegalMoveLoggingDisabled;
  }

  void (^noActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeNo
                          alertType:alertType];
  };

  void (^yesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeYes
                          alertType:alertType];
  };

  [[Registry sharedRegistry].windowProvider.window.rootViewController presentYesNoAlertWithTitle:@"Unexpected error"
                                                                                         message:message
                                                                                      yesHandler:yesActionBlock
                                                                                       noHandler:noActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when the GTP engine plays a move that Little Go thinks
/// is illegal. Part 2: Saves the game in progress and informs the user that a
/// new game needs to be started.
///
/// This method has been added to gather information in order to fix issue 90
/// on GitHub. This method can be removed as soon the issue has been fixed.
// -----------------------------------------------------------------------------
- (void) handleComputerPlayedIllegalMove2;
{
  ArchiveViewModel* model = [Registry sharedRegistry].modelProvider.archiveViewModel;
  NSString* uniqueGameName = [model uniqueGameNameForGame:[GoGame sharedGame]];
  [[[[SaveGameCommand alloc] initWithSaveGame:uniqueGameName gameAlreadyExists:false] autorelease] submit];

  NSString* messageFormat = @"Until this bug is fixed, Little Go unfortunately cannot continue with the game in progress. The game has been saved to the archive under the name\n\n%@\n\nA new game is being started now to bring the app back into a good state.";
  NSString* message = [NSString stringWithFormat:messageFormat, uniqueGameName];

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeOk
                          alertType:AlertTypeNewGameAfterComputerPlayedIllegalMove];
  };

  [[Registry sharedRegistry].windowProvider.window.rootViewController presentOkAlertWithTitle:@"New game about to begin"
                                                                                      message:message
                                                                                    okHandler:okActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when the GTP engine is unable to play a move for some
/// reason. This method displays an alert and brings the app back into a sane
/// state.
// -----------------------------------------------------------------------------
- (void) handleComputerFailedToPlay:(NSString*)gtpResponseString;
{
  NSString* message = [NSString stringWithFormat:@"The computer failed to play. The technical reason is this:\n\n%@", gtpResponseString];

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    self.game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;
  };

  [[Registry sharedRegistry].windowProvider.window.rootViewController presentOkAlertWithTitle:@"Unexpected error"
                                                                                      message:message
                                                                                    okHandler:okActionBlock];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert that was triggered by this
/// command.
///
/// This method has been added to gather information in order to fix issue 90
/// on GitHub. This method can be removed as soon the issue has been fixed.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType alertType:(enum AlertType)alertType
{
  [self autorelease];  // balance retain that is sent before an alert is shown

  switch (alertType)
  {
    case AlertTypeComputerPlayedIllegalMoveLoggingDisabled:
    {
      switch (alertButtonType)
      {
        case AlertButtonTypeYes:
          [self enableLogging];
          break;
        default:
          break;
      }
      [self handleComputerPlayedIllegalMove2];
      break;
    }
    case AlertTypeComputerPlayedIllegalMoveLoggingEnabled:
    {
      switch (alertButtonType)
      {
        case AlertButtonTypeNo:
          [self handleComputerPlayedIllegalMove2];
          break;
        case AlertButtonTypeYes:
          [self sendBugReport];
          break;
        default:
          break;
      }
      break;
    }
    case AlertTypeNewGameAfterComputerPlayedIllegalMove:
    {
      [self startNewGame];
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Enables logging.
///
/// This method has been added to gather information in order to fix issue 90
/// on GitHub. This method can be removed as soon the issue has been fixed.
// -----------------------------------------------------------------------------
- (void) enableLogging
{
  [Registry sharedRegistry].modelProvider.loggingModel.loggingEnabled = true;
  [[ApplicationDelegate sharedDelegate] setupLogging];
}

// -----------------------------------------------------------------------------
/// @brief Triggers the sending of a bug report.
///
/// This method has been added to gather information in order to fix issue 90
/// on GitHub. This method can be removed as soon the issue has been fixed.
// -----------------------------------------------------------------------------
- (void) sendBugReport
{
  UIViewController* modalViewControllerParent = [Registry sharedRegistry].windowProvider.window.rootViewController;
  SendBugReportController* controller = [SendBugReportController controller];
  controller.delegate = self;
  if (self.illegalMove)
    controller.bugReportDescription = [NSString stringWithFormat:@"Little Go claims that the computer player made an illegal move by playing on intersection %@.", self.illegalMove.vertex.string];
  else
    controller.bugReportDescription = @"Little Go claims that the computer player made an illegal move by passing.";
  [controller sendBugReport:modalViewControllerParent];
  [self retain];  // must survive until the delegate method is invoked
}

// -----------------------------------------------------------------------------
/// @brief SendBugReportControllerDelegate method
///
/// This method has been added to gather information in order to fix issue 90
/// on GitHub. This method can be removed as soon the issue has been fixed.
// -----------------------------------------------------------------------------
- (void) sendBugReportDidFinish:(SendBugReportController*)sendBugReportController
{
  [self autorelease];  // balance retain that is sent before bug report controller runs
  [self handleComputerPlayedIllegalMove2];
}

// -----------------------------------------------------------------------------
/// @brief Starts a new game.
///
/// This method has been added to gather information in order to fix issue 90
/// on GitHub. This method can be removed as soon the issue has been fixed.
// -----------------------------------------------------------------------------
- (void) startNewGame
{
  [[[[CleanBackupSgfCommand alloc] init] autorelease] submit];
  [[[[NewGameCommand alloc] init] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Lets the computer continue playing if it is still its turn, otherwise
/// updates the "computer is thinking" state in GoGame.
///
/// This is a private helper for gtpResponseReceived.
// -----------------------------------------------------------------------------
- (void) continuePlayingIfNecessary
{
  bool computerGoesOnPlaying = false;
  bool startHumanPlayerClock = false;
  switch (self.game.state)
  {
    case GoGameStateGameIsPaused:  // game has been paused while GTP was thinking about its last move
    case GoGameStateGameHasEnded:  // game has ended as a result of the last move (e.g. resign, 2x pass)
      break;
    default:
      if (self.game.nextMovePlayerIsComputerPlayer)
        computerGoesOnPlaying = true;
      else
        startHumanPlayerClock = true;
      break;
  }

  if (computerGoesOnPlaying)
  {
    [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
  }
  else
  {
    self.game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;
    if (startHumanPlayerClock)
      [self startPlayerClockIfGameUsesTimedPlay:PlayerClockStartReasonHumanPlayerTurnBegins];
  }
}

// -----------------------------------------------------------------------------
/// @brief If the game uses timed play, starts the clock of the player whose
/// turn it is to play next. Always returns true. Does not do anything and
/// returns true if the game does not use timed play.
///
/// Which player's clock is started depends on when this method is invoked:
/// - If a "genmove" is about to be submitted: Starts the clock of the player
///   on whose behalf the computer will play a move. This can be the computer
///   player itself, or a human player
/// - Once the move generated by "genmove" has been processed, and it is now the
///   human player's turn: Starts the clock of the human player.
// -----------------------------------------------------------------------------
- (bool) startPlayerClockIfGameUsesTimedPlay:(enum PlayerClockStartReason)startReason
{
  id<PlayerClockService> playerClockService = [Registry sharedRegistry].playerClockService;
  [playerClockService startClockOfPlayer:self.game.nextMovePlayer
                                  reason:startReason];

  return true;
}

@end
