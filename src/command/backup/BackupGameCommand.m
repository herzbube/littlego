// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "BackupGameCommand.h"
#import "../../go/GoGame.h"
#import "../../gtp/GtpCommand.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for BackupGameCommand.
// -----------------------------------------------------------------------------
@interface BackupGameCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation BackupGameCommand

@synthesize game;
@synthesize backgroundTask;


// -----------------------------------------------------------------------------
/// @brief Initializes a BackupGameCommand object.
///
/// @note This is the designated initializer of BackupGameCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  GoGame* sharedGame = [GoGame sharedGame];
  assert(sharedGame);
  if (! sharedGame)
    return nil;

  self.game = sharedGame;
  self.backgroundTask = UIBackgroundTaskInvalid;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BackupGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  UIDevice* device = [UIDevice currentDevice];
  bool backgroundSupported = false;
  if ([device respondsToSelector:@selector(isMultitaskingSupported)])  
    backgroundSupported = device.multitaskingSupported;
  if (! backgroundSupported)
    return false;

  // This block is invoked a certain amount of time after the background task
  // has been started. An experiment with the iOS 4.2 simulator has shown the
  // time to be approximately 10 minutes. In the experiment, the main background
  // task did nothing and put its thread asleep.
  // The job of the expiration handler is to end the background task in an
  // orderly fashion. If the handler does not return quickly, the application
  // will be killed by the OS. Note that it is *NOT* possible for the expiration
  // handler to request more time by starting another background task (if it
  // tries, the application is killed). Requesting more time is the job of the
  // background task itself. UIApplication.backgroundTimeRemaining helps to
  // find out when this is necessary.
  void (^expirationHandler) (void) =
  ^(void)
  {
    NSLog(@"BackupGameCommand: Background task expiration handler invoked");
    if (UIBackgroundTaskInvalid != self.backgroundTask)
    {
      UIApplication* app = [UIApplication sharedApplication];
      [app endBackgroundTask:self.backgroundTask];
    }
  };

  // Make sure that this command object survives until the task is complete
  [self retain];

  // Tell the OS that we need to run a little while longer.
  UIApplication* app = [UIApplication sharedApplication];
  self.backgroundTask = [app beginBackgroundTaskWithExpirationHandler:expirationHandler];

  void (^theTask) (void) =
  ^(void)
  {
    NSLog(@"BackupGameCommand: Background task invoked");

    // Secretly and heinously change the working directory so that the .sgf
    // file goes to a directory that the user cannot look into
    BOOL expandTilde = YES;
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
    NSString* appSupportDirectory = [paths objectAtIndex:0];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
    [fileManager changeCurrentDirectoryPath:appSupportDirectory];

    // Make the backup
    NSString* commandString = [NSString stringWithFormat:@"savesgf %@", sgfBackupFileName];
    GtpCommand* gtpCommand = [GtpCommand command:commandString];
    gtpCommand.waitUntilDone = true;  // synchronous execution
    [gtpCommand submit];

    // Switch back to the original directory
    [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];

    // Tell the OS that we are done
    UIApplication* app = [UIApplication sharedApplication];
    [app endBackgroundTask:self.backgroundTask];
    // Make sure that the expiration handler does not do anything stupid,
    // should it be called unexpectedly.
    self.backgroundTask = UIBackgroundTaskInvalid;

    // Balance the call of [self retain] further up
    [self autorelease];
  };
  NSOperationQueue* aQueue = [[NSOperationQueue alloc] init];
  [aQueue addOperationWithBlock:theTask];

  return true;
}

@end
