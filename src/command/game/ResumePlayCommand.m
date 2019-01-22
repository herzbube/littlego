// -----------------------------------------------------------------------------
// Copyright 2015-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "../ChangeUIAreaPlayModeCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameRules.h"
#import "../../go/GoScore.h"
#import "../../go/GoUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../utility/NSStringAdditions.h"


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

    // When play is resumed we obviously want to return to play mode. It's
    // important that we do this ***AFTER*** reverting the game state in case
    // we are disabling scoring mode, because we don't want GameActionManager
    // to react to our disabling scoring mode.
    [[[[ChangeUIAreaPlayModeCommand alloc] initWithUIAreayPlayMode:UIAreaPlayModePlay] autorelease] submit];
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
  NSString* blackColorName = [NSString stringWithGoColor:GoColorBlack];
  NSString* whiteColorName = [NSString stringWithGoColor:GoColorWhite];

  NSString* alertTitle = @"Choose side to play first";
  NSString* alertMessage = [NSString stringWithFormat:
                            @"\nYou have decided to resume play to resolve a life & death dispute.\n\n"
                            "Because the game rules allow non-alternating play you may now choose a side to play first. "
                            "With alternating play, %@ would play first.\n\n"
                            "Which side would you like to play first?", [alternatingColorName lowercaseString]];

  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  void (^blackColorActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithColor:GoColorBlack];
  };
  UIAlertAction* blackColorAction = [UIAlertAction actionWithTitle:blackColorName
                                                             style:UIAlertActionStyleDefault
                                                           handler:blackColorActionBlock];
  [alertController addAction:blackColorAction];

  void (^whiteColorActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithColor:GoColorWhite];
  };
  UIAlertAction* whiteColorAction = [UIAlertAction actionWithTitle:whiteColorName
                                                             style:UIAlertActionStyleDefault
                                                           handler:whiteColorActionBlock];
  [alertController addAction:whiteColorAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];

  [self retain];  // must survive until the handler method is invoked
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithColor:(enum GoColor)selectedColor
{
  [self autorelease];  // balance retain that is sent before an alert is shown

  GoGame* game = [GoGame sharedGame];
  enum GoColor alternatingColor = game.nextMoveColor;
  if (alternatingColor != selectedColor)
    [[GoGame sharedGame] switchNextMoveColor];

  [self resumePlay];
}

@end
