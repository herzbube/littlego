// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoGame.h"
#import "../../go/GoBoardPosition.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"


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
    alertMessage = [alertMessage stringByAppendingString:@"\n\nNote: Handicap stones will stay on the board."];

  alertMessage = [alertMessage stringByAppendingString:@"\n\nAre you sure you want to do this?"];


  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  void (^noActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeNo];
  };
  UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No"
                                                     style:UIAlertActionStyleDefault
                                                   handler:noActionBlock];
  [alertController addAction:noAction];

  void (^yesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeYes];
  };
  UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                      style:UIAlertActionStyleDefault
                                                    handler:yesActionBlock];
  [alertController addAction:yesAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];

  [self retain];  // must survive until the handler method is invoked
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType
{
  [self autorelease];  // balance retain that is sent before an alert is shown

  if (alertButtonType == AlertButtonTypeNo)
    return;

  GoGame* game = [GoGame sharedGame];

  if (game.boardPosition.currentBoardPosition != 0)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Current board position is %d, but should be 0", game.boardPosition.currentBoardPosition];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];

    if (game.boardPosition.numberOfBoardPositions > 0)
    {
      // Whoever invoked DiscardAllSetupStonesCommand must have previously
      // made sure that it's OK to discard future moves. We can therefore safely
      // submit ChangeAndDiscardCommand without user interaction. Note that
      // ChangeAndDiscardCommand reverts the game state to "in progress" if the
      // game is currently ended. The overall effect is that after executing
      // this command GoGame is in a state that allows us to perform changes to
      // the board setup.
      [[[[ChangeAndDiscardCommand alloc] init] autorelease] submit];
    }

    [game discardAllSetupStones];

    [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }
}

@end
