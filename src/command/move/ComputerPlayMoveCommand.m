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
#import "ComputerPlayMoveCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../backup/CleanBackupSgfCommand.h"
#import "../game/NewGameCommand.h"
#import "../game/SaveGameCommand.h"
#import "../playerinfluence/UpdateTerritoryStatisticsCommand.h"
#import "../../archive/ArchiveViewModel.h"
#import "../../diagnostics/LoggingModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../main/WindowRootViewController.h"
#import "../../shared/ApplicationStateManager.h"


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
  // It's important that we do not wait for the GTP command to complete. This
  // gives the UI the time to update (e.g. status view, activity indicator).
  NSString* commandString = @"genmove ";
  commandString = [commandString stringByAppendingString:self.game.nextMovePlayer.colorString];
  GtpCommand* command = [GtpCommand asynchronousCommand:commandString
                                         responseTarget:self
                                               selector:@selector(gtpResponseReceived:)];
  [command submit];
  self.game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonComputerPlay;
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is triggered when the GTP engine responds to the command submitted
/// in doIt().
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(GtpResponse*)response
{
  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];

    if (! response.status)
    {
      DDLogError(@"%@: Aborting due to failed GTP command", [self shortDescription]);
      assert(0);
      [self handleComputerFailedToPlay:response.parsedResponse];
      return;
    }

    bool success = [self playMoveInsideResponse:response];
    if (! success)
      return;
    // Don't check command execution result, it is irrelevant for us whether the
    // command succeeds or not. There is a known case where the command fails:
    // If statistics collection was enabled while the "genmove" command above
    // was still running. In that case, UpdateTerritoryStatisticsCommand will
    // try to acquire statistics data, but will fail because the GTP engine has
    // not yet collected any data.
    [[[[UpdateTerritoryStatisticsCommand alloc] init] autorelease] submit];
    [self continuePlayingIfNecessary];
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Instructs GoGame to play the move that is inside @a response. Returns
/// true on success, false on failure (e.g. if move was illegal).
///
/// This is a private helper for gtpResponseReceived.
// -----------------------------------------------------------------------------
- (bool) playMoveInsideResponse:(GtpResponse*)response
{
  NSString* responseString = [response.parsedResponse lowercaseString];
  if ([responseString isEqualToString:@"pass"])
    [self.game pass];
  else if ([responseString isEqualToString:@"resign"])
    [self.game resign];
  else
  {
    GoPoint* point = [self.game.board pointAtVertex:responseString];
    if (point)
    {
      enum GoMoveIsIllegalReason illegalReason;
      if ([self.game isLegalMove:point isIllegalReason:&illegalReason])
      {
        [self.game play:point];
      }
      else
      {
        self.illegalMove = point;
        [self handleComputerPlayedIllegalMove1:illegalReason];
        return false;
      }
    }
    else
    {
      DDLogError(@"%@: Invalid vertex %@", [self shortDescription], responseString);
      assert(0);
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
  bool loggingEnabled = [ApplicationDelegate sharedDelegate].loggingModel.loggingEnabled;
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

  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Unexpected error"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  void (^noActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeNo
                          alertType:alertType];
  };
  UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No"
                                                     style:UIAlertActionStyleCancel
                                                   handler:noActionBlock];
  [alertController addAction:noAction];

  void (^yesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeYes
                          alertType:alertType];
  };
  UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                      style:UIAlertActionStyleDefault
                                                    handler:yesActionBlock];
  [alertController addAction:yesAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];

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
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  NSString* uniqueGameName = [model uniqueGameNameForGame:[GoGame sharedGame]];
  [[[[SaveGameCommand alloc] initWithSaveGame:uniqueGameName] autorelease] submit];

  NSString* messageFormat = @"Until this bug is fixed, Little Go unfortunately cannot continue with the game in progress. The game has been saved to the archive under the name\n\n%@\n\nA new game is being started now to bring the app back into a good state.";
  NSString* message = [NSString stringWithFormat:messageFormat, uniqueGameName];

  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"New game about to begin"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeOk
                          alertType:AlertTypeNewGameAfterComputerPlayedIllegalMove];
  };
  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:okActionBlock];
  [alertController addAction:okAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];

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

  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Unexpected error"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    self.game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;
  };
  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:okActionBlock];
  [alertController addAction:okAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];
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
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  appDelegate.loggingModel.loggingEnabled = true;
  [appDelegate setupLogging];
}

// -----------------------------------------------------------------------------
/// @brief Triggers the sending of a bug report.
///
/// This method has been added to gather information in order to fix issue 90
/// on GitHub. This method can be removed as soon the issue has been fixed.
// -----------------------------------------------------------------------------
- (void) sendBugReport
{
  // Use the view controller that is currently selected - this may not
  // always be the UIAreaPlay root view controller, e.g. if the user has
  // switched to another UI area while the computer was thinking
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  UIViewController* modalViewControllerParent = appDelegate.windowRootViewController;
  SendBugReportController* controller = [SendBugReportController controller];
  controller.delegate = self;
  controller.bugReportDescription = [NSString stringWithFormat:@"Little Go claims that the computer player made an illegal move by playing on intersection %@.", self.illegalMove.vertex.string];
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
  switch (self.game.state)
  {
    case GoGameStateGameIsPaused:  // game has been paused while GTP was thinking about its last move
    case GoGameStateGameHasEnded:  // game has ended as a result of the last move (e.g. resign, 2x pass)
      break;
    default:
      if (self.game.nextMovePlayerIsComputerPlayer)
        computerGoesOnPlaying = true;
      break;
  }
  if (computerGoesOnPlaying)
    [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
  else
    self.game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;
}

@end
