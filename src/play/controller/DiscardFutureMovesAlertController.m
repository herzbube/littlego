// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "DiscardFutureMovesAlertController.h"
#import "../model/BoardPositionModel.h"
#import "../../command/CommandBase.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../main/ApplicationDelegate.h"

// System includes
#import <objc/runtime.h>

// Constants
NSString* associatedCommandObjectKey = @"AssociatedCommandObject";

// Enums
enum ActionType
{
  ActionTypePlay,
  ActionTypeDiscard
};


@implementation DiscardFutureMovesAlertController

// -----------------------------------------------------------------------------
/// @brief NavigationBarControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) navigationBarController:(NavigationBarController*)controller playOrAlertWithCommand:(CommandBase*)command
{
  [self alertOrAction:ActionTypePlay withCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief NavigationBarControllerDelegateDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) navigationBarController:(NavigationBarController*)controller discardOrAlertWithCommand:(CommandBase*)command
{
  [self alertOrAction:ActionTypeDiscard withCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief PanGestureControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) panGestureController:(PanGestureController*)controller playOrAlertWithCommand:(CommandBase*)command
{
  [self alertOrAction:ActionTypePlay withCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief UIAlertViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  CommandBase* command = objc_getAssociatedObject(alertView, associatedCommandObjectKey);
  // objc_setAssociatedObject() will invoke release, so we must make sure that
  // the command survives until it is submitted
  [[command retain] autorelease];
  objc_setAssociatedObject(alertView, associatedCommandObjectKey, nil, OBJC_ASSOCIATION_RETAIN);
  switch (buttonIndex)
  {
    case AlertViewButtonTypeYes:
    {
      [command submit];
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Executes @a command, or displays an alert and delays execution until
/// the alert is dismissed by the user.
///
/// @a actionType is used to tweak the alert message so that contains a useful
/// description of what the user tries to do.
///
/// If the Go board currently displays the last board position of the game,
/// @a command is executed immediately.
///
/// If the Go board displays a board position in the middle of the game, an
/// alert is shown that warns the user that discarding now will discard all
/// future board positions. If the user confirms that this is OK, @a command is
/// executed. If the user cancels the operation, @a command is not executed.
/// Handling of the user's response happens in
/// alertView:didDismissWithButtonIndex:().
///
/// The user can suppress the alert in the user preferences. In this case
/// @a command is immediately executed.
// -----------------------------------------------------------------------------
- (void) alertOrAction:(enum ActionType)actionType withCommand:(CommandBase*)command
{
  DDLogVerbose(@"%@: Displaying alert for action type %d", self, actionType);
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  if (boardPosition.isLastPosition || ! boardPositionModel.discardFutureMovesAlert)
  {
    [command submit];
  }
  else
  {
    NSString* actionDescription;
    if (ActionTypePlay == actionType)
    {
      if (GoGameTypeComputerVsComputer == [GoGame sharedGame].type)
        actionDescription = @"If you let the computer play now,";
      else
      {
        // Use a generic expression because we don't know which user interaction
        // triggered the alert (could be a pass move, a play move (via panning),
        // or the "computer play" function).
        actionDescription = @"If you play now,";
      }
    }
    else
    {
      if (boardPosition.isFirstPosition)
        actionDescription = @"If you proceed,";
      else
        actionDescription = @"If you proceed not only this move, but";
    }
    NSString* formatString;
    if (boardPosition.isFirstPosition)
      formatString = @"You are looking at the board position at the beginning of the game. %@ all moves of the entire game will be discarded.\n\nDo you want to continue?";
    else
      formatString = @"You are looking at a board position in the middle of the game. %@ all moves that have been made after this position will be discarded.\n\nDo you want to continue?";
    NSString* messageString = [NSString stringWithFormat:formatString, actionDescription];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Future moves will be discarded"
                                                    message:messageString
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = AlertViewTypeActionWillDiscardAllFutureMoves;
    [alert show];
    [alert release];
    // Store command object for later use by the alert handler
    objc_setAssociatedObject(alert, associatedCommandObjectKey, command, OBJC_ASSOCIATION_RETAIN);
  }
}

@end
