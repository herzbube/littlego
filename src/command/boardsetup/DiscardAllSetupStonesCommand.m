// -----------------------------------------------------------------------------
// Copyright 2019-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "DiscardAllSetupStonesCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../boardposition/ChangeAndDiscardCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoBoardPosition.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UIViewControllerAdditions.h"


@implementation DiscardAllSetupStonesCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  [self showAlertToAskForConfirmation];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that asks the user for confirmation whether it's ok
/// to discard all setup stones.
// -----------------------------------------------------------------------------
- (void) showAlertToAskForConfirmation
{
  NSString* alertTitle = @"Discard all setup stones";
  NSString* alertMessage = @"\nYou are about to discard all stones that the board is currently set up with.";

  GoGame* game = [GoGame sharedGame];
  if (game.handicapPoints.count > 0)
    alertMessage = [alertMessage stringByAppendingString:@"\n\nHandicap stones will stay on the board."];

  alertMessage = [alertMessage stringByAppendingString:@"\n\nAre you sure you want to do this?"];

  void (^noActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeNo];
  };
  
  void (^yesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeYes];
  };

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentYesNoAlertWithTitle:alertTitle
                                                                                     message:alertMessage
                                                                                  yesHandler:yesActionBlock
                                                                                   noHandler:noActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType
{
  [self autorelease];  // balance retain that is sent before an alert is shown

  if (alertButtonType == AlertButtonTypeNo || alertButtonType == AlertButtonTypeOk)
    return;

  GoGame* game = [GoGame sharedGame];
  int currentBoardPosition = game.boardPosition.currentBoardPosition;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode != UIAreaPlayModeBoardSetup)
  {
    // Some rare scenarios have been found where this is possible - for details
    // see https://github.com/herzbube/littlego/issues/366. This block handles
    // case 4.
    [self showAlertNotInBoardSetupMode:currentBoardPosition];
    return;
  }

  if (currentBoardPosition != 0)
  {
    // Currently there is no known scenario for this. In the known scenarios
    // where the current board position is not 0 the app is also no longer in
    // board setup mode, and that case was already handled above. To be
    // waterproof error handling must also include this check.
    [self showAlertNotOnBoardPositionZero:currentBoardPosition];
    return;
  }

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    if (game.boardPosition.numberOfBoardPositions > 0 || game.state == GoGameStateGameHasEnded)
    {
      // Whoever invoked DiscardAllSetupStonesCommand must have previously
      // made sure that it's OK to discard future nodes. We can therefore safely
      // submit ChangeAndDiscardCommand without user interaction. Note that
      // ChangeAndDiscardCommand reverts the game state to "in progress" if the
      // game is currently ended. The overall effect is that after executing
      // this command GoGame is in a state that allows us to perform changes to
      // the board setup.
      [[[[ChangeAndDiscardCommand alloc] init] autorelease] submit];
    }

    [game discardAllSetup];

    SyncGTPEngineCommand* syncCommand = [[[SyncGTPEngineCommand alloc] init] autorelease];
    bool syncSuccess = [syncCommand submit];
    if (! syncSuccess)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Failed to synchronize the GTP engine state with the current GoGame state. GTP engine error message:\n\n%@", syncCommand.errorDescription];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }

    [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
    [[LongRunningActionCounter sharedCounter] decrement];
  }
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that discarding all setup stones
/// is not possible because the application is currently not in board setup
/// mode.
// -----------------------------------------------------------------------------
- (void) showAlertNotInBoardSetupMode:(int)currentBoardPosition
{
  NSString* alertTitle = @"Discard all setup stones canceled";
  NSString* alertMessage;
  // Try to find out why we are no longer in board setup mode so that we can
  // display a more informative alert message
  if (currentBoardPosition != 0)
    alertMessage = [NSString stringWithFormat:@"Discarding all setup stones was canceled because the board no longer shows board position 0 (instead it shows board position %d) and is no longer in setup mode.", currentBoardPosition];
  else
    alertMessage = @"Discarding all setup stones was canceled because the board is no longer in setup mode.";
  DDLogWarn(@"%@: %@", self, alertMessage);

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeOk];
  };

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle
                                                                                  message:alertMessage
                                                                                okHandler:okActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that discarding all setup stones
/// is not possible because the board is currently not showing board position 0.
// -----------------------------------------------------------------------------
- (void) showAlertNotOnBoardPositionZero:(int)currentBoardPosition
{
  NSString* alertTitle = @"Discard all setup stones canceled";
  NSString* alertMessage = [NSString stringWithFormat:@"Discarding all setup stones was canceled because the board no longer shows board position 0 (instead it shows board position %d).", currentBoardPosition];
  DDLogWarn(@"%@: %@", self, alertMessage);

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeOk];
  };

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle
                                                                                  message:alertMessage
                                                                                okHandler:okActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

@end
