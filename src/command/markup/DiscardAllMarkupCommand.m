// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "DiscardAllMarkupCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeMarkup.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UIViewControllerAdditions.h"


@implementation DiscardAllMarkupCommand

#pragma mark - CommandBase methods

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
/// to discard all markup.
// -----------------------------------------------------------------------------
- (void) showAlertToAskForConfirmation
{
  NSString* alertTitle = @"Discard all markup";
  NSString* alertMessage = @"\nYou are about to discard all markup (symbols, markers, labels, lines and arrows) that exists for the current board position.";

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
  GoBoardPosition* boardPosition = game.boardPosition;
  int currentBoardPosition = boardPosition.currentBoardPosition;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode != UIAreaPlayModeEditMarkup)
  {
    // Alas, defensive programming. Cf. HandleBoardSetupInteractionCommand,
    // although the scenarios handled there should not be possible for markup
    // editing because markup editing does not involve showing an alert.
    [self showAlertNotInMarkupEditingMode:currentBoardPosition];
    return;
  }

  bool applicationStateDidChange = false;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];

    GoNode* currentNode = boardPosition.currentNode;
    GoNodeMarkup* nodeMarkup = currentNode.goNodeMarkup;
    if (nodeMarkup)
    {
      applicationStateDidChange = nodeMarkup.hasMarkup;
      currentNode.goNodeMarkup = nil;
    }

    if (applicationStateDidChange)
    {
      [[NSNotificationCenter defaultCenter] postNotificationName:allMarkupDidDiscard object:currentNode];
      [[NSNotificationCenter defaultCenter] postNotificationName:nodeMarkupDataDidChange object:currentNode];
      [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
    }
  }
  @finally
  {
    if (applicationStateDidChange)
      [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that discarding all markup is
/// not possible because the application is currently not in markup editing
/// mode.
// -----------------------------------------------------------------------------
- (void) showAlertNotInMarkupEditingMode:(int)currentBoardPosition
{
  NSString* alertTitle = @"Discard all markup canceled";
  NSString* alertMessage;
  // Try to find out why we are no longer in markup editing mode so that we can
  // display a more informative alert message
  if (currentBoardPosition == 0)
    alertMessage = @"Discarding all markup was canceled because the board shows board position 0 and is no longer in markup editing mode. Markup can only be edited on board positions greater than zero.";
  else
    alertMessage = @"Discarding all markup was canceled because the board is no longer in markup editing mode.";
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
