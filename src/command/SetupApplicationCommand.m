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
#import "LoadOpeningBookCommand.h"
#import "backup/RestoreGameCommand.h"
#import "diagnostics/RestoreBugReportApplicationState.h"
#import "../main/ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for SetupApplicationCommand.
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
  self.totalSteps = 11;
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
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                            didProgress:0.0
                                        nextStepMessage:@"Starting up..."];

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];

  [delegate setupLogging];
  [self increaseProgressAndNotifyDelegate];

  [delegate setupApplicationLaunchMode];
  [self increaseProgressAndNotifyDelegate];

  [delegate setupFolders];
  [self increaseProgressAndNotifyDelegate];

  [delegate setupResourceBundle];
  [self increaseProgressAndNotifyDelegate];

  [delegate setupRegistrationDomain];
  [self increaseProgressAndNotifyDelegate];

  [delegate setupUserDefaults];
  [self increaseProgressAndNotifyDelegate];

  [delegate setupSound];
  [self increaseProgressAndNotifyDelegate];

  [delegate setupFuego];
  [self increaseProgressAndNotifyDelegate];

  [delegate setupTabBarController];
  [self increaseProgressAndNotifyDelegate];

  delegate.applicationReadyForAction = true;
  [[NSNotificationCenter defaultCenter] postNotificationName:applicationIsReadyForAction object:nil];
  [self increaseProgressAndNotifyDelegate];

  [[[LoadOpeningBookCommand alloc] init] submit];
  [self increaseProgressAndNotifyDelegate];

  // At this point the progress in self.asynchronousCommandDelegate is at 100%.
  // From now on, other commands will take over and manage the progress, with
  // an initial resetting to 0% and display of a different message.

  if (ApplicationLaunchModeDiagnostics == delegate.applicationLaunchMode)
  {
    RestoreBugReportApplicationState* command = [[RestoreBugReportApplicationState alloc] init];
    bool success = [command submit];
    if (! success)
    {
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:[NSString stringWithFormat:@"Failed to restore in-memory objects while launching in mode ApplicationLaunchModeDiagnostics"]
                                                     userInfo:nil];
      @throw exception;
    }
  }
  else
  {
    // Important: We must execute this command in the context of a thread that
    // survives the entire command execution - see the class documentation of
    // RestoreGameCommand for the reason why.
    [[[RestoreGameCommand alloc] init] submit];
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
