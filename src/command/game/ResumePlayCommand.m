// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "ResumePlayCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameRules.h"
#import "../../go/GoScore.h"
#import "../../go/GoUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../utility/NSStringAdditions.h"


/// @brief Enumerates the types of buttons used in alerts presented by this
/// command.
enum AlertButtonType
{
  AlertButtonTypeNonAlternatingColor,
  AlertButtonTypeAlternatingColor,
};


@implementation ResumePlayCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  GoGame* game = [GoGame sharedGame];
  if (GoDisputeResolutionRuleNonAlternatingPlay == game.rules.disputeResolutionRule)
    [self showAlertToSelectSideToPlay];
  else
    [self resumePlay];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Resumes play. Triggers the computer player if it is the computer
/// player's turn to move.
// -----------------------------------------------------------------------------
- (void) resumePlay
{
  GoGame* game = [GoGame sharedGame];
  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [game revertStateFromEndedToInProgress];

    // We don't want GameActionManager to react to our disabling scoring mode,
    // so we have to disable scoring mode ***AFTER*** reverting the game state
    if (game.score.scoringEnabled)
      game.score.scoringEnabled = false;
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }

  if (game.nextMovePlayerIsComputerPlayer)
    [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that allows the user to select the side to play first
/// after play is resumed.
// -----------------------------------------------------------------------------
- (void) showAlertToSelectSideToPlay
{
  GoGame* game = [GoGame sharedGame];
  NSString* alternatingColorName = [NSString stringWithGoColor:game.nextMoveColor];
  enum GoColor nonAlternatingColor = [GoUtilities alternatingColorForColor:game.nextMoveColor];
  NSString* nonAlternatingColorName = [NSString stringWithGoColor:nonAlternatingColor];

  NSString* alertTitle = @"Choose side to play first";
  NSString* alertMessage = [NSString stringWithFormat:
                            @"\nYou have decided to resume play to resolve a life & death dispute.\n\n"
                            "Because the game rules allow non-alternating play you may now choose a side to play first. "
                            "With alternating play,  %@ would play first.\n\n"
                            "Which side would you like to play first?", [alternatingColorName lowercaseString]];

  // TODO: When we still used UIAlertView, the alert showed the second button
  // with a bold font to indicate a "default choice". For this reason we display
  // the color that would move naturally, i.e. with alternating play, in the
  // second button. The consequence is that the alert sometimes shows the
  // buttons in the order Black/White, and sometimes in the order White/Black.
  // I would expect that a frequent user of the app is annoyed/confused by this
  // "unstable" UI. Since UIAlertView is no longer used, I suggest that the
  // order of buttons is made stable.
  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  void (^nonAlternatingColorActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeNonAlternatingColor];
  };
  UIAlertAction* nonAlternatingColorAction = [UIAlertAction actionWithTitle:nonAlternatingColorName
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:nonAlternatingColorActionBlock];
  [alertController addAction:nonAlternatingColorAction];

  void (^alternatingColorActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeAlternatingColor];
  };
  UIAlertAction* alternatingColorAction = [UIAlertAction actionWithTitle:alternatingColorName
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:alternatingColorActionBlock];
  [alertController addAction:alternatingColorAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];

  [self retain];  // must survive until the delegate method is invoked
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType
{
  [self autorelease];  // balance retain that is sent before an alert is shown

  switch (alertButtonType)
  {
    case AlertButtonTypeAlternatingColor:
      break;
    case AlertButtonTypeNonAlternatingColor:
      [[GoGame sharedGame] switchNextMoveColor];
      break;
    default:
      DDLogError(@"%@: Unexpected alert button %ld", self, (long)alertButtonType);
      assert(0);
      return;
  }
  [self resumePlay];
}

@end
