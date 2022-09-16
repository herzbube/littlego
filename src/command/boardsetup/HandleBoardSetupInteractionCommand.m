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
#import "HandleBoardSetupInteractionCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../boardposition/ChangeAndDiscardCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../../play/model/BoardSetupModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UIViewControllerAdditions.h"
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
  int currentBoardPosition = game.boardPosition.currentBoardPosition;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode != UIAreaPlayModeBoardSetup)
  {
    // Some rare scenarios have been found where this is possible - for details
    // see https://github.com/herzbube/littlego/issues/366. This block handles
    // case 2.
    [self showAlertNotInBoardSetupMode:currentBoardPosition];
    return false;
  }

  if (currentBoardPosition != 0)
  {
    // Currently there is no known scenario for this. In the known scenarios
    // where the current board position is not 0 the app is also no longer in
    // board setup mode, and that case was already handled above. To be
    // waterproof error handling must also include this check.
    [self showAlertNotOnBoardPositionZero:currentBoardPosition];
    return false;
  }

  if ([game.handicapPoints containsObject:self.point] && appDelegate.boardSetupModel.changeHandicapAlert)
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
        if ([ApplicationDelegate sharedDelegate].boardSetupModel.tryNotToPlaceIllegalStones)
        {
          newStoneState = [self determineAlternativeNewStoneStateForSetupPoint:newStoneState];
          if (newStoneState != GoColorNone)
          {
            isLegalSetupStone = [game isLegalBoardSetupAt:self.point
                                           withStoneState:newStoneState
                                          isIllegalReason:&isIllegalReason
                               createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint];
          }
          else
          {
            isLegalSetupStone = true;
          }
        }

        if (! isLegalSetupStone)
        {
          [self showAlertIllegalSetupStone:self.point
                                stoneColor:newStoneState
                        isIllegalForReason:isIllegalReason
                createsIllegalStoneOrGroup:illegalStoneOrGroupPoint];
          return;
        }
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
/// @brief Private helper for handleBoardSetupInteraction.
// -----------------------------------------------------------------------------
- (enum GoColor) determineNewStoneStateForSetupPoint
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardSetupModel* boardSetupModel = appDelegate.boardSetupModel;

  // The cycle is: Empty > Default Color > Alternate color > Empty
  if (self.point.stoneState == GoColorNone)
    return boardSetupModel.boardSetupStoneColor;
  else if (self.point.stoneState == boardSetupModel.boardSetupStoneColor)
    return [GoUtilities alternatingColorForColor:boardSetupModel.boardSetupStoneColor];
  else
    return GoColorNone;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for handleBoardSetupInteraction.
// -----------------------------------------------------------------------------
- (enum GoColor) determineAlternativeNewStoneStateForSetupPoint:(enum GoColor)previousStoneState
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardSetupModel* boardSetupModel = appDelegate.boardSetupModel;

  // The cycle is: Empty > Alternate color > Default Color > Empty
  if (self.point.stoneState == GoColorNone)
    return [GoUtilities alternatingColorForColor:boardSetupModel.boardSetupStoneColor];
  else if (self.point.stoneState == boardSetupModel.boardSetupStoneColor)
    return GoColorNone;
  else
    return boardSetupModel.boardSetupStoneColor;
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
/// @brief Shows an alert that informs the user that the board setup interaction
/// is not possible because the application is currently not in board setup
/// mode.
// -----------------------------------------------------------------------------
- (void) showAlertNotInBoardSetupMode:(int)currentBoardPosition
{
  NSString* alertTitle = @"Board setup action canceled";
  NSString* alertMessage;
  // Try to find out why we are no longer in board setup mode so that we can
  // display a more informative alert message
  if (currentBoardPosition != 0)
    alertMessage = [NSString stringWithFormat:@"The board setup action was canceled because the board no longer shows board position 0 (instead it shows board position %d) and is no longer in setup mode.", currentBoardPosition];
  else
    alertMessage = @"The board setup action was canceled because the board is no longer in setup mode.";
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
/// @brief Shows an alert that informs the user that the board setup interaction
/// is not possible because the board is currently not showing board position 0.
// -----------------------------------------------------------------------------
- (void) showAlertNotOnBoardPositionZero:(int)currentBoardPosition
{
  NSString* alertTitle = @"Board setup action canceled";
  NSString* alertMessage = [NSString stringWithFormat:@"The board setup action was canceled because the board no longer shows board position 0 (instead it shows board position %d).", currentBoardPosition];
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
