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
#import "PlayMoveCommand.h"
#import "ComputerPlayMoveCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../../diagnostics/LoggingModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../main/MainTabBarController.h"
#import "../../shared/ApplicationStateManager.h"


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
  // Must get this before updating the game model
  NSString* colorForMove = self.game.currentPlayer.colorString;

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

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];

    switch (self.moveType)
    {
      case GoMoveTypePlay:
      {
        [self.game play:self.point];
        break;
      }
      case GoMoveTypePass:
      {
        [self.game pass];
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
  }

  [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];

  // Let computer continue playing if the game state allows it and it is
  // actually a computer player's turn
  switch (self.game.state)
  {
    case GoGameStateGameHasEnded:
    {
      // Game has ended as a result of the last move (e.g. 2x pass)
      break;
    }
    default:
    {
      if ([self.game isComputerPlayersTurn])
        [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
      break;
    }
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
  enum AlertViewType alertViewType;
  bool loggingEnabled = [ApplicationDelegate sharedDelegate].loggingModel.loggingEnabled;
  if (loggingEnabled)
  {
    message = [message stringByAppendingString:@"\n\nWould you like to report this incident now so that we can fix the bug?"];
    alertViewType = AlertViewTypePlayMoveRejectedLoggingEnabled;
  }
  else
  {
    message = [message stringByAppendingString:@"You should enable logging now so that you can report the bug when it occurs the next time.\n\nWould you like to enable logging now?"];
    alertViewType = AlertViewTypePlayMoveRejectedLoggingDisabled;
  }
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Unexpected error"
                                                  message:message
                                                 delegate:self
                                        cancelButtonTitle:@"No"
                                        otherButtonTitles:@"Yes", nil];
  alert.tag = alertViewType;
  [alert show];
  [alert release];

  [self retain];  // must survive until the delegate method is invoked
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert view for which this controller
/// is the delegate.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  [self autorelease];  // balance retain that is sent before an alert is shown

  switch (alertView.tag)
  {
    case AlertViewTypePlayMoveRejectedLoggingDisabled:
    {
      switch (buttonIndex)
      {
        case AlertViewButtonTypeYes:
          [self enableLogging];
          break;
        default:
          break;
      }
      break;
    }
    case AlertViewTypePlayMoveRejectedLoggingEnabled:
    {
      switch (buttonIndex)
      {
        case AlertViewButtonTypeYes:
          [self sendBugReport];
          break;
        default:
          break;
      }
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Enables logging.
// -----------------------------------------------------------------------------
- (void) enableLogging
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  appDelegate.loggingModel.loggingEnabled = true;
  [appDelegate setupLogging];
}

// -----------------------------------------------------------------------------
/// @brief Triggers the sending of a bug report.
// -----------------------------------------------------------------------------
- (void) sendBugReport
{
  // Use the view controller that is currently selected - this may not
  // always be the Play tab controller, e.g. if the user has switched to
  // another tab while the computer was thinking
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  UIViewController* modalViewControllerParent = appDelegate.tabBarController.selectedViewController;
  SendBugReportController* controller = [SendBugReportController controller];
  controller.delegate = self;
  controller.bugReportDescription = [NSString stringWithFormat:@"Fuego rejected the move %@ played by me. The reason given was: %@.", self.point.vertex.string, self.failedGtpResponse];
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

@end
