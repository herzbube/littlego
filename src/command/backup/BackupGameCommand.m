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
/// @name Private helpers
//@{
- (void) mainLoop;
- (void) savesgf;
- (void) savesgfCommandResponseReceived:(GtpResponse*)response;
- (void) endBackgroundSubTask;
//@}
/// @name Privately declared properties
//@{
@property(retain) GoGame* game;
@property(assign) UIBackgroundTaskIdentifier backgroundTask;
@property(assign) bool savesgfCommandExecuted;
@property(assign) bool savesgfCommandResponseReceived;
@property(assign) bool shouldExit;
//@}
@end


@implementation BackupGameCommand

@synthesize game;
@synthesize backgroundTask;
@synthesize savesgfCommandExecuted;
@synthesize savesgfCommandResponseReceived;
@synthesize shouldExit;


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
  self.savesgfCommandExecuted = false;
  self.savesgfCommandResponseReceived = false;
  self.shouldExit = false;

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
  // Standard code block to test for the device's multitasking capability. This
  // block exists mainly for demonstration purposes, the application is
  // expected to always run on multitasking capable devices.
  UIDevice* device = [UIDevice currentDevice];
  bool backgroundSupported = false;
  if ([device respondsToSelector:@selector(isMultitaskingSupported)])
    backgroundSupported = device.multitaskingSupported;
  if (! backgroundSupported)
    return false;

  // No need to backup if there are no moves. All the other game characteristics
  // (komi, handicap, players) are backed up separately by the "new game"
  // subsystem and will be picked by when the application restarts and a new
  // game is started.
  if (! self.game.firstMove)
    return true;

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
    DDLogInfo(@"BackupGameCommand: Background task expiration handler invoked");
    if (UIBackgroundTaskInvalid != self.backgroundTask)
    {
      UIApplication* app = [UIApplication sharedApplication];
      [app endBackgroundTask:self.backgroundTask];
    }
  };

  // Tell the OS that we need to run a little while longer.
  UIApplication* app = [UIApplication sharedApplication];
  self.backgroundTask = [app beginBackgroundTaskWithExpirationHandler:expirationHandler];

  // Launch the secondary thread, then trigger the background task immediately
  NSThread* backgroundThread = [[NSThread alloc] initWithTarget:self
                                                       selector:@selector(mainLoop)
                                                         object:nil];
  [backgroundThread start];
  [self performSelector:@selector(savesgf)
               onThread:backgroundThread
             withObject:nil
          waitUntilDone:NO];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief The secondary thread's main loop method. Returns only after the
/// @e shouldExit property has been set to true.
// -----------------------------------------------------------------------------
- (void) mainLoop
{
  NSAutoreleasePool* mainPool = [[NSAutoreleasePool alloc] init];
  NSDate* distantFuture = [NSDate distantFuture];
  NSTimer* distantFutureTimer = [[NSTimer alloc] initWithFireDate:distantFuture
                                                         interval:1.0
                                                           target:self
                                                         selector:@selector(dealloc:)   // pseudo selector
                                                         userInfo:nil
                                                          repeats:NO];
  [[NSRunLoop currentRunLoop] addTimer:distantFutureTimer forMode:NSDefaultRunLoopMode];
  [distantFutureTimer autorelease];
  while (true)
  {
    NSAutoreleasePool* loopPool = [[NSAutoreleasePool alloc] init];
    bool hasInputSources = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                                    beforeDate:distantFuture];
    [loopPool drain];
    if (! hasInputSources)  // always true, see timer input source above
      break;
    if (self.shouldExit)
      break;
  }
  [mainPool drain];
}

// -----------------------------------------------------------------------------
/// @brief Submits the "savesgf" command to the GTP engine. This method is
/// executed in the secondary thread's context.
///
/// This is one of the subtasks of the main background task.
// -----------------------------------------------------------------------------
- (void) savesgf
{
  DDLogInfo(@"BackupGameCommand: Background task invoked");

  // Secretly and heinously change the working directory so that the .sgf
  // file goes to a directory that the user cannot look into
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* appSupportDirectory = [paths objectAtIndex:0];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:appSupportDirectory];

  NSString* commandString = [NSString stringWithFormat:@"savesgf %@", sgfBackupFileName];
  GtpCommand* gtpCommand = [GtpCommand command:commandString
                                responseTarget:self
                                      selector:@selector(savesgfCommandResponseReceived:)];
  // Synchronous execution because we must be sure that the GTP engine really
  // writes its file into appSupportDirectory. If we were doing this
  // asynchronously, we would probably change the current directory back to the
  // original folder before the backup file could be written.
  gtpCommand.waitUntilDone = true;
  [gtpCommand submit];

  // Switch back to the original directory
  [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];

  self.savesgfCommandExecuted = true;
  [self endBackgroundSubTask];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "savesgf" GTP command
/// was received. This method is executed in the secondary thread's context.
///
/// This is one of the subtasks of the main background task.
// -----------------------------------------------------------------------------
- (void) savesgfCommandResponseReceived:(GtpResponse*)response
{
  self.savesgfCommandResponseReceived = true;
  [self endBackgroundSubTask];
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when one of the subtasks of the main background task has
/// finished. The main task is ended when the last subtask invokes this method.
///
/// See class documentation for details.
// -----------------------------------------------------------------------------
- (void) endBackgroundSubTask
{
  // Do nothing if one or more of the subtasks have not yet finished
  if (! self.savesgfCommandExecuted || ! self.savesgfCommandResponseReceived)
    return;

  // Tell the thread that it can finish
  self.shouldExit = true;

  // Tell the OS that we are done
  UIApplication* app = [UIApplication sharedApplication];
  [app endBackgroundTask:self.backgroundTask];

  // Make sure that the expiration handler does not do anything stupid,
  // should it be called unexpectedly.
  self.backgroundTask = UIBackgroundTaskInvalid;
}

@end
