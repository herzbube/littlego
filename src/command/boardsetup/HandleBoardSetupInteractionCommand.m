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
#import "HandleBoardSetupInteractionCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../boardposition/ChangeAndDiscardCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../../play/model/BoardSetupModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// HandleBoardSetupInteractionCommand.
// -----------------------------------------------------------------------------
@interface HandleBoardSetupInteractionCommand()
@property(nonatomic, retain) GoPoint* point;
@end


@implementation HandleBoardSetupInteractionCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleBoardSetupInteractionCommand object.
///
/// @note This is the designated initializer of
/// HandleBoardSetupInteractionCommand.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)point
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.point = point;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// HandleBoardSetupInteractionCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.point = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
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

  if ([game.handicapPoints containsObject:self.point])
    [self showAlertToConfirmHandicapChange];
  else
    [self handleBoardSetupInteraction];

  return true;

}

// -----------------------------------------------------------------------------
/// @brief Performs the actual board setup interaction handling. Is called both
/// from doIt() and from the alert handler.
// -----------------------------------------------------------------------------
- (void) handleBoardSetupInteraction
{
  GoGame* game = [GoGame sharedGame];

  bool toggleHandicapPoint;
  enum GoColor newStoneState;
  if ([game.handicapPoints containsObject:self.point])
  {
    toggleHandicapPoint = true;
    newStoneState = GoColorNone;
  }
  else
  {
    toggleHandicapPoint = false;
    newStoneState = [self determineNewStoneStateForSetupPoint];

    if (newStoneState != GoColorNone)
    {
      enum GoBoardSetupIsIllegalReason isIllegalReason;
      GoPoint* illegalStoneOrGroupPoint;
      bool isLegalSetupStone = [game isLegalBoardSetupAt:self.point
                                          withStoneState:newStoneState
                                         isIllegalReason:&isIllegalReason
                              createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint];
      if (!isLegalSetupStone)
      {
        [self showAlertIllegalSetupStone:self.point
                              stoneColor:newStoneState
                      isIllegalForReason:isIllegalReason
              createsIllegalStoneOrGroup:illegalStoneOrGroupPoint];
        return;
      }
    }
  }

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    if (game.boardPosition.numberOfBoardPositions > 0)
    {
      // Whoever invoked HandleBoardSetupInteractionCommand must have previously
      // made sure that it's OK to discard future moves. We can therefore safely
      // submit ChangeAndDiscardCommand without user interaction. Note that
      // ChangeAndDiscardCommand reverts the game state to "in progress" if the
      // game is currently ended. The overall effect is that after executing
      // this command GoGame is in a state that allows us to perform changes to
      // the board setup.
      [[[[ChangeAndDiscardCommand alloc] init] autorelease] submit];
    }

    if (toggleHandicapPoint)
      [game toggleHandicapPoint:self.point];
    else
      [game changeSetupPoint:self.point toStoneState:newStoneState];

    bool syncSuccess = [[[[SyncGTPEngineCommand alloc] init] autorelease] submit];
    if (! syncSuccess)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Failed to synchronize the GTP engine state with the current GoGame state"];
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
/// @brief Private helper for handleBoardSetupInteraction.
// -----------------------------------------------------------------------------
- (enum GoColor) determineNewStoneStateForSetupPoint
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardSetupModel* boardSetupModel = appDelegate.boardSetupModel;

  if (self.point.stoneState == GoColorNone)
  {
    return boardSetupModel.boardSetupStoneColor;
  }
  else if (self.point.stoneState == boardSetupModel.boardSetupStoneColor)
  {
    if (self.point.stoneState == GoColorBlack)
      return GoColorWhite;
    else
      return GoColorBlack;
  }
  else
  {
    return GoColorNone;
  }
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that asks the user for confirmation whether she wants
/// to change the game's handicap.
// -----------------------------------------------------------------------------
- (void) showAlertToConfirmHandicapChange
{
  NSString* alertTitle = @"Change handicap";
  NSString* alertMessage = @"You have tapped on a handicap stone. If you proceed the stone will be removed so that you can place a setup stone on the empty intersection.\n\n"
                            "You cannot undo this action.\n\n"
                            "Are you sure you want to remove the handicap stone?";

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

  [self handleBoardSetupInteraction];
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that placing a setup stone
/// with stone color @a stoneColor on intersection @a point would create an
/// illegal board position. @a isIllegalReason specifies the kind of illegal
/// board position that would be created. If @a isIllegalReason specifies that
/// a stone or stone group would be made illegal by placing the setup stone,
/// then @a illegalStoneOrGroupPoint identifies the stone or stone group.
/// Otherwise @a illegalStoneOrGroupPoint is ignored and can be nil.
// -----------------------------------------------------------------------------
- (void) showAlertIllegalSetupStone:(GoPoint*)point
                         stoneColor:(enum GoColor)stoneColor
                 isIllegalForReason:(enum GoBoardSetupIsIllegalReason)isIllegalReason
         createsIllegalStoneOrGroup:(GoPoint*)illegalStoneOrGroupPoint
{
  NSString* alertTitle = @"Stone is not legal";
  NSString* alertMessage = [NSString stringWithBoardSetupIsIllegalReason:isIllegalReason
                                                              setupStone:point.vertex.string
                                                         setupStoneColor:stoneColor
                                              createsIllegalStoneOrGroup:illegalStoneOrGroupPoint.vertex.string];

  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeNo];
  };
  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:okActionBlock];
  [alertController addAction:okAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];

  [self retain];  // must survive until the handler method is invoked
}

@end
