// -----------------------------------------------------------------------------
// Copyright 2019-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "SetupFirstMoveColorCommand.h"
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


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// SetupFirstMoveColorCommand.
// -----------------------------------------------------------------------------
@interface SetupFirstMoveColorCommand()
@property(nonatomic, assign) enum GoColor firstMoveColor;
@end


@implementation SetupFirstMoveColorCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a SetupFirstMoveColorCommand object.
///
/// @note This is the designated initializer of
/// SetupFirstMoveColorCommand.
// -----------------------------------------------------------------------------
- (id) initWithFirstMoveColor:(enum GoColor)firstMoveColor
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.firstMoveColor = firstMoveColor;

  return self;
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
    // case 3.
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

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    if (game.boardPosition.numberOfBoardPositions > 0)
    {
      // Whoever invoked SetupFirstMoveColorCommand must have previously
      // made sure that it's OK to discard future moves. We can therefore safely
      // submit ChangeAndDiscardCommand without user interaction. Note that
      // ChangeAndDiscardCommand reverts the game state to "in progress" if the
      // game is currently ended. The overall effect is that after executing
      // this command GoGame is in a state that allows us to perform changes to
      // the board setup.
      [[[[ChangeAndDiscardCommand alloc] init] autorelease] submit];
    }

    // The setter of setupFirstMoveColor may change the GoGame property
    // nextMoveColor. We don't want this to happen while the game already has
    // moves. That's why we discard future moves further up.
    game.setupFirstMoveColor = self.firstMoveColor;

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

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that discarding all setup stones
/// is not possible because the application is currently not in board setup
/// mode.
// -----------------------------------------------------------------------------
- (void) showAlertNotInBoardSetupMode:(int)currentBoardPosition
{
  NSString* alertTitle = @"Setting up a side to play first canceled";
  NSString* alertMessage;
  // Try to find out why we are no longer in board setup mode so that we can
  // display a more informative alert message
  if (currentBoardPosition != 0)
    alertMessage = [NSString stringWithFormat:@"Setting up a side to play first was canceled because the board no longer shows board position 0 (instead it shows board position %d) and is no longer in setup mode.", currentBoardPosition];
  else
    alertMessage = @"Setting up a side to play first was canceled because the board is no longer in setup mode.";
  DDLogWarn(@"%@: %@", self, alertMessage);

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self autorelease];  // balance retain that is sent before an alert is shown
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
  NSString* alertTitle = @"Setting up a side to play first canceled";
  NSString* alertMessage = [NSString stringWithFormat:@"Setting up a side to play first was canceled because the board no longer shows board position 0 (instead it shows board position %d).", currentBoardPosition];
  DDLogWarn(@"%@: %@", self, alertMessage);

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self autorelease];  // balance retain that is sent before an alert is shown
  };

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle
                                                                                  message:alertMessage
                                                                                okHandler:okActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

@end
