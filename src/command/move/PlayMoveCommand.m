// -----------------------------------------------------------------------------
// Copyright 2011-2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayMoveCommand.h"
#import "ComputerPlayMoveCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../../diagnostics/LoggingModel.h"
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


/// @brief Enumerates the types of alerts presented by this command.
enum AlertType
{
  AlertTypePlayMoveRejectedLoggingEnabled,
  AlertTypePlayMoveRejectedLoggingDisabled,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayMoveCommand.
// -----------------------------------------------------------------------------
@interface PlayMoveCommand()
@property(nonatomic, retain) NSString* failedGtpResponse;
@end


@implementation PlayMoveCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayMoveCommand object that will make a play move at
/// @a point.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)aPoint
{
  assert(aPoint);
  if (! aPoint)
  {
    DDLogError(@"%@: GoPoint object is nil", [self shortDescription]);
    return nil;
  }
  self = [self initWithMoveType:GoMoveTypePlay];
  self.point = aPoint;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayMoveCommand object that will make a pass move.
// -----------------------------------------------------------------------------
- (id) initPass
{
  return [self initWithMoveType:GoMoveTypePass];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayMoveCommand object that will make a move of type
/// @a aMoveType.
///
/// @note This is the designated initializer of PlayMoveCommand.
// -----------------------------------------------------------------------------
- (id) initWithMoveType:(enum GoMoveType)aMoveType
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
    return nil;
  }
  enum GoGameState gameState = sharedGame.state;
  assert(GoGameStateGameHasEnded != gameState);
  if (GoGameStateGameHasEnded == gameState)
  {
    DDLogError(@"%@: Unexpected game state %d", [self shortDescription], gameState);
    return nil;
  }

  self.game = sharedGame;
  self.moveType = aMoveType;
  self.point = nil;
  self.failedGtpResponse = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayMoveCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  self.point = nil;
  self.failedGtpResponse = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool success;

  // Abort and don't try to play the move if the player has lost on time. We
  // expect that someone else reacts to the notification that is posted when
  // a player loses on time.
  success = [self stopPlayerClockIfGameUsesTimedPlay];
  if (! success)
    return false;

  success = [self submitPlayCommandToGtpEngine];
  if (! success)
    return false;

  success = [self updateGoGame];
  if (! success)
    return false;

  // Game may have ended as a result of the last move (e.g. 2x pass)
  if (self.game.state != GoGameStateGameHasEnded)
  {
    if (self.game.nextMovePlayerIsComputerPlayer)
      success = [self triggerComputerPlayer];
    else
      success = [self startPlayerClockIfGameUsesTimedPlay];
  }

  return success;
}

// -----------------------------------------------------------------------------
/// @brief If the game uses timed play, stops the clock of the player who is
/// playing a move. Returns false if the player lost on time, otherwise returns
/// true. Does not do anything and returns true if the game does not use timed
/// play.
///
/// A return value false is unexpected - the user should no longer be able to
/// play a move once they have lost. There is a chance, though, that it happens,
/// because time runs out between the moment when the user submits the move and
/// the time we stop the clock in this method.
///
/// Private helper of doIt().
// -----------------------------------------------------------------------------
- (bool) stopPlayerClockIfGameUsesTimedPlay
{
  id<PlayerClockService> playerClockService = [Registry sharedRegistry].playerClockService;
  enum PlayerClockServiceOperationResult result = [playerClockService stopClockOfPlayer:self.game.nextMovePlayer
                                                                                 reason:PlayerClockStopReasonPlayerTurnEnds];
  return (result == PlayerClockServiceOperationResultGameContinues);
}

// -----------------------------------------------------------------------------
/// @brief Private helper of doIt().
// -----------------------------------------------------------------------------
- (bool) submitPlayCommandToGtpEngine
{
  // Must get this before updating the game model
  NSString* colorForMove = self.game.nextMovePlayer.colorString;

  NSString* commandString = @"play ";
  commandString = [commandString stringByAppendingString:colorForMove];
  commandString = [commandString stringByAppendingString:@" "];
  switch (self.moveType)
  {
    case GoMoveTypePlay:
      commandString = [commandString stringByAppendingString:self.point.vertex.string];
      break;
    case GoMoveTypePass:
      commandString = [commandString stringByAppendingString:@"pass"];
      break;
    default:
      DDLogError(@"%@: Unexpected move type %d", [self shortDescription], self.moveType);
      assert(0);
      return false;
  }
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  if (! command.response.status)
  {
    assert(0);
    DDLogError(@"%@: GTP engine failed to process command '%@', response was: %@", [self shortDescription], commandString, command.response.parsedResponse);
    self.failedGtpResponse = command.response.parsedResponse;
    [self handleGtpEngineRejectedCommand];
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when the GTP engine rejects the play move made by this
/// command. Offers the user a chance to submit a bug report, or to enable
/// logging if logging is currently turned off.
// -----------------------------------------------------------------------------
- (void) handleGtpEngineRejectedCommand
{
  NSString* message = @"Your move was rejected by Fuego. The reason given was:\n\n";
  message = [message stringByAppendingString:self.failedGtpResponse];
  message = [message stringByAppendingString:@"\n\nThis is almost certainly a bug in Little Go. "];
  enum AlertType alertType;
  bool loggingEnabled = [Registry sharedRegistry].modelProvider.loggingModel.loggingEnabled;
  if (loggingEnabled)
  {
    message = [message stringByAppendingString:@"\n\nWould you like to report this incident now so that we can try to find and fix the bug?"];
    alertType = AlertTypePlayMoveRejectedLoggingEnabled;
  }
  else
  {
    message = [message stringByAppendingString:@"You should enable logging now so that you can report the bug when it occurs the next time.\n\nWould you like to enable logging now?"];
    alertType = AlertTypePlayMoveRejectedLoggingDisabled;
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

  [self retain];  // must survive until the delegate method is invoked
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert that was triggered by this
/// command.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType alertType:(enum AlertType)alertType
{
  [self autorelease];  // balance retain that is sent before an alert is shown

  switch (alertType)
  {
    case AlertTypePlayMoveRejectedLoggingDisabled:
    {
      switch (alertButtonType)
      {
        case AlertButtonTypeYes:
          [self enableLogging];
          break;
        default:
          break;
      }
      break;
    }
    case AlertTypePlayMoveRejectedLoggingEnabled:
    {
      switch (alertButtonType)
      {
        case AlertButtonTypeYes:
          [self sendBugReport];
          break;
        default:
          break;
      }
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
// -----------------------------------------------------------------------------
- (void) enableLogging
{
  [Registry sharedRegistry].modelProvider.loggingModel.loggingEnabled = true;
  [[ApplicationDelegate sharedDelegate] setupLogging];
}

// -----------------------------------------------------------------------------
/// @brief Triggers the sending of a bug report.
// -----------------------------------------------------------------------------
- (void) sendBugReport
{
  UIViewController* modalViewControllerParent = [Registry sharedRegistry].windowProvider.window.rootViewController;
  SendBugReportController* controller = [SendBugReportController controller];
  controller.delegate = self;
  if (self.moveType == GoMoveTypePlay)
    controller.bugReportDescription = [NSString stringWithFormat:@"Fuego rejected the move %@ played by me. The reason given was: %@.", self.point.vertex.string, self.failedGtpResponse];
  else
    controller.bugReportDescription = [NSString stringWithFormat:@"Fuego rejected the pass move played by me. The reason given was: %@.", self.failedGtpResponse];
  [controller sendBugReport:modalViewControllerParent];
  [self retain];  // must survive until the delegate method is invoked
}

// -----------------------------------------------------------------------------
/// @brief SendBugReportControllerDelegate method
// -----------------------------------------------------------------------------
- (void) sendBugReportDidFinish:(SendBugReportController*)sendBugReportController
{
  [self autorelease];  // balance retain that is sent before bug report controller runs
}

// -----------------------------------------------------------------------------
/// @brief Private helper of doIt().
// -----------------------------------------------------------------------------
- (bool) updateGoGame
{
  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    GoMoveNodeCreationOptions* options;
    GameVariationModel* gameVariationModel = [Registry sharedRegistry].modelProvider.gameVariationModel;
    if (gameVariationModel.newMoveInsertPolicy == GoNewMoveInsertPolicyRetainFutureBoardPositions)
      options = [GoMoveNodeCreationOptions moveNodeCreationOptionsWithInsertPolicyRetainFutureBoardPositionsAndInsertPosition:gameVariationModel.newMoveInsertPosition];
    else
      options = [GoMoveNodeCreationOptions moveNodeCreationOptionsWithInsertPolicyReplaceFutureBoardPositions];

    switch (self.moveType)
    {
      case GoMoveTypePlay:
      {
        [self.game play:self.point withMoveNodeCreationOptions:options];
        break;
      }
      case GoMoveTypePass:
      {
        [self.game passWithMoveNodeCreationOptions:options];
        break;
      }
      default:
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Unexpected move type %d", self.moveType];
        DDLogError(@"%@: %@", [self shortDescription], errorMessage);
        NSException* exception = [NSException exceptionWithName:NSGenericException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }
    }
  }
  @catch (NSException* exception)
  {
    DDLogError(@"%@: Exception name: %@. Exception reason: %@.", [self shortDescription], [exception name], [exception reason]);
    [[[[SyncGTPEngineCommand alloc] init] autorelease] submit];
    return false;
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
    [[LongRunningActionCounter sharedCounter] decrement];
  }

  [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper of doIt().
// -----------------------------------------------------------------------------
- (bool) triggerComputerPlayer
{
  return [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Private helper of doIt().
// -----------------------------------------------------------------------------
- (bool) startPlayerClockIfGameUsesTimedPlay
{
  id<PlayerClockService> playerClockService = [Registry sharedRegistry].playerClockService;
  [playerClockService startClockOfPlayer:self.game.nextMovePlayer
                                  reason:PlayerClockStartReasonHumanPlayerTurnBegins];

  return true;
}

@end
