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
#import "SetupFirstMoveColorCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../boardposition/ChangeAndDiscardCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoBoardPosition.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"


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

  return true;
}

@end
