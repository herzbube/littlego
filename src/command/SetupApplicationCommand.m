// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "SetupApplicationCommand.h"
#import "ChangeUIAreaPlayModeCommand.h"
#import "HandleDocumentInteractionCommand.h"
#import "diagnostics/RestoreBugReportApplicationStateCommand.h"
#import "gtp/LoadOpeningBookCommand.h"
#import "gtp/SetAdditiveKnowledgeTypeCommand.h"
#import "../go/GoBoardPosition.h"
#import "../go/GoGame.h"
#import "../go/GoScore.h"
#import "../main/ApplicationDelegate.h"
#import "../shared/ApplicationStateManager.h"
#import "../shared/LongRunningActionCounter.h"
#import "../ui/UiSettingsModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SetupApplicationCommand.
// -----------------------------------------------------------------------------
@interface SetupApplicationCommand()
@property(nonatomic, assign) int totalSteps;
@property(nonatomic, assign) float stepIncrease;
@property(nonatomic, assign) float progress;
@end


@implementation SetupApplicationCommand

@synthesize asynchronousCommandDelegate;


// -----------------------------------------------------------------------------
/// @brief Initializes a SetupApplicationCommand object.
///
/// @note This is the designated initializer of SetupApplicationCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;
  self.totalSteps = 1;
  self.stepIncrease = 1.0 / self.totalSteps;
  self.progress = 0.0;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SetupApplicationCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  @try
  {
    [self.asynchronousCommandDelegate asynchronousCommand:self
                                              didProgress:0.0
                                          nextStepMessage:@"Starting up..."];

    [[LongRunningActionCounter sharedCounter] increment];

    // Here we are sending the very first GTP command to the GTP engine. The
    // engine is probably still in the process of setting itself up, so there
    // will be a delay in executing the command.
    [[[[LoadOpeningBookCommand alloc] init] autorelease] submit];
    [self increaseProgressAndNotifyDelegate];

    // At this point the progress in self.asynchronousCommandDelegate is at
    // 100%. From now on, other commands may take over the progress HUD, with
    // an initial resetting to 0% and display of a different message.

    ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
    if (ApplicationLaunchModeDiagnostics == delegate.applicationLaunchMode)
    {
      RestoreBugReportApplicationStateCommand* command = [[[RestoreBugReportApplicationStateCommand alloc] init] autorelease];
      bool success = [command submit];
      if (! success)
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Failed to restore in-memory objects while launching in mode ApplicationLaunchModeDiagnostics"];
        DDLogError(@"%@: %@", [self shortDescription], errorMessage);
        NSException* exception = [NSException exceptionWithName:NSGenericException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }
    }
    else
    {
      [[ApplicationStateManager sharedManager] restoreApplicationState];

      // Board position vs. UIAreaPlayMode
      // - The documentation block below describes, with relevance to scoring,
      //   how app state and user preferences can get out of sync when the app
      //   crashes.
      // - The same out-of-sync problem can affect board position vs.
      //   UIAreaPlayMode: Board setup mode is allowed only when board position
      //   0 is viewed, so if after app restore the current board position
      //   is != 0, we have a problem.
      // - We can either change the board position or change UIAreaPlayMode to
      //   resolve the situation.
      // - Because changing board positions is non-trivial and may take
      //   considerable time to execute, the solution is to change the
      //   UIAreaPlayMode value.
      if (delegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeBoardSetup)
      {
        if ([GoGame sharedGame].boardPosition.currentBoardPosition != 0)
          [[[[ChangeUIAreaPlayModeCommand alloc] initWithUIAreaPlayMode:UIAreaPlayModePlay] autorelease] submit];
      }

      // Special scoring mode considerations:
      // - Go model objects store scoring-related information. This information
      //   is saved to the NSCoding archive when the app state is saved.
      // - UiSettingsModel stores whether or not scoring is enabled, in the form
      //   of an UIAreaPlayMode value. This information is saved when the user
      //   preferences are saved.
      // - The app state and the user preferences are not necessarily saved at the
      //   same time. For instance, the app state is changed whenever a move is
      //   played, or whenever anything about the Go model objects changes. The
      //   user preferences on the other hand are saved when the user switches
      //   tabs.
      // - When the app is suspended all this does not matter, because at that
      //   moment both app state and user preferences are saved again, so that the
      //   two information sets on disk are in sync.
      // - However, if the app crashes the result may be that the two information
      //   sets on disk do not match.
      // - A possible solution that was considered is to save both app state and
      //   user preferences in ChangeUIAreaPlayModeCommand. The problem with
      //   this is that the two information sets cannot be saved
      //   atomically - the app may crash after the user preferences were saved,
      //   but before the app state is saved, again resulting in the data on
      //   disk not being in sync. This may seem far-fetched, but keep in mind
      //   that enabling or disabling scoring mode triggers many reactions in
      //   the application, any one of which might cause the app to crash.
      // - The final solution chosen is that when the app is restored, the value
      //   of UiSettingsModel.uiAreaPlayMode takes precedence over what is in the
      //   Go model objects. The consequence of this decision is that the score
      //   from the previous app session may be lost.
      if (delegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
          [[GoGame sharedGame].score enableScoringOnAppLaunch];
      else
          [[GoGame sharedGame].score disableScoringOnAppLaunch];

      if (delegate.documentInteractionURL)
      {
        // Control returns while an alert is still being displayed
        [[[[HandleDocumentInteractionCommand alloc] init] autorelease] submit];
      }
    }

    // Run this command *AFTER* the initial "uct_max_memory" GTP command has
    // been submitted to the GTP engine. See the command's class documentation
    // for details.
    [[[[SetAdditiveKnowledgeTypeCommand alloc] init] autorelease] submit];
  }
  @finally
  {
    [[LongRunningActionCounter sharedCounter] decrement];
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) increaseProgressAndNotifyDelegate
{
  self.progress += self.stepIncrease;
  [self.asynchronousCommandDelegate asynchronousCommand:self didProgress:self.progress nextStepMessage:nil];
}

@end
