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
#import "SetupApplicationCommand.h"
#import "HandleDocumentInteractionCommand.h"
#import "diagnostics/RestoreBugReportApplicationStateCommand.h"
#import "gtp/LoadOpeningBookCommand.h"
#import "gtp/SetAdditiveKnowledgeTypeCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../shared/ApplicationStateManager.h"
#import "../shared/LongRunningActionCounter.h"


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
