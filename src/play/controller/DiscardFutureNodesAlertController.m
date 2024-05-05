// -----------------------------------------------------------------------------
// Copyright 2013-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "DiscardFutureNodesAlertController.h"
#import "../model/BoardPositionModel.h"
#import "../../command/CommandBase.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/model/GameVariationModel.h"
#import "../../ui/UIViewControllerAdditions.h"

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


@implementation DiscardFutureNodesAlertController

#pragma mark - GameActionManagerCommandDelegate overrides

// -----------------------------------------------------------------------------
/// @brief GameActionManagerCommandDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager playOrAlertWithCommand:(CommandBase*)command
{
  [self alertOrAction:ActionTypePlay withCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerCommandDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager discardOrAlertWithCommand:(CommandBase*)command
{
  [self alertOrAction:ActionTypeDiscard withCommand:command];
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType
{
  CommandBase* command = objc_getAssociatedObject(self, associatedCommandObjectKey);
  // objc_setAssociatedObject() will invoke release, so we must make sure that
  // the command survives until it is submitted
  [[command retain] autorelease];
  objc_setAssociatedObject(self, associatedCommandObjectKey, nil, OBJC_ASSOCIATION_RETAIN);

  switch (alertButtonType)
  {
    case AlertButtonTypeYes:
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
/// @a actionType is used to tweak the alert message so that it contains a
/// useful description of what the user tries to do.
///
/// @a command is executed immediately if the Go board currently displays the
/// last board position of the game. If @a actionType is #ActionTypePlay, then
/// the new move being played will be appended to the current game variation
/// and no nodes will be discarded, so no alert is needed. If @a actionType is
/// #ActionTypeDiscard there are no nodes to discard, so no alert is needed
/// either.
///
/// @a command is also executed immediately, even if the Go board currently
/// displays a board position that is not the last board position, if
/// @a actionType is #ActionTypePlay and the "new move insert policy" user
/// preference is set to #GoNewMoveInsertPolicyRetainFutureBoardPositions. The
/// new move being played in this case will be added to a new game variation
/// and no nodes will be discarded, so no alert is needed.
///
/// In all other cases where the Go board displays a board position that is not
/// the last board position, an alert is shown that warns the user that playing
/// or discarding now will discard all future nodes. If the user confirms that
/// this is OK, @a command is executed. If the user cancels the operation,
/// @a command is not executed. Handling of the user's response happens in
/// didDismissAlertWithButton:().
///
/// The user can suppress the alert in the user preferences. In this case
/// @a command is immediately executed.
// -----------------------------------------------------------------------------
- (void) alertOrAction:(enum ActionType)actionType withCommand:(CommandBase*)command
{
  DDLogVerbose(@"%@: Displaying alert for action type %d", self, actionType);
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  GameVariationModel* gameVariationModel = appDelegate.gameVariationModel;

  if (boardPosition.isLastPosition ||
      (ActionTypePlay == actionType && gameVariationModel.newMoveInsertPolicy == GoNewMoveInsertPolicyRetainFutureBoardPositions) ||
      ! boardPositionModel.discardFutureNodesAlert)
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
        actionDescription = @"If you proceed not only this node, but";
    }
    NSString* formatString;
    if (boardPosition.isFirstPosition)
      formatString = @"You are viewing the board position at the beginning of the game. %@ all nodes in all game variations will be discarded.\n\nDo you want to continue?";
    else
      formatString = @"You are viewing a board position in the middle of the game. %@ all nodes in the current game variation after this position will be discarded.\n\nDo you want to continue?";
    NSString* messageString = [NSString stringWithFormat:formatString, actionDescription];

    void (^noActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
    {
      [self didDismissAlertWithButton:AlertButtonTypeNo];
    };

    void (^yesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
    {
      [self didDismissAlertWithButton:AlertButtonTypeYes];
    };

    [[ApplicationDelegate sharedDelegate].window.rootViewController presentYesNoAlertWithTitle:@"Future nodes will be discarded"
                                                                                       message:messageString
                                                                                    yesHandler:yesActionBlock
                                                                                     noHandler:noActionBlock];

    // Store command object for later use by the alert handler
    objc_setAssociatedObject(self, associatedCommandObjectKey, command, OBJC_ASSOCIATION_RETAIN);
  }
}

@end
