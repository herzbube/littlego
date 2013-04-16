// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "CommandProcessor.h"
#import "Command.h"
#import "../main/ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for CommandProcessor.
// -----------------------------------------------------------------------------
@interface CommandProcessor()
@property(nonatomic, retain) NSThread* thread;
@property(nonatomic, retain) MBProgressHUD* progressHUD;
@end


@implementation CommandProcessor

// -----------------------------------------------------------------------------
/// @brief Shared instance of CommandProcessor.
// -----------------------------------------------------------------------------
static CommandProcessor* sharedProcessor = nil;


// -----------------------------------------------------------------------------
/// @brief Returns the shared command processor object.
// -----------------------------------------------------------------------------
+ (CommandProcessor*) sharedProcessor
{
  if (! sharedProcessor)
    sharedProcessor = [[CommandProcessor alloc] init];
  return sharedProcessor;
}

// -----------------------------------------------------------------------------
/// @brief Releases the shared command processor object.
// -----------------------------------------------------------------------------
+ (void) releaseSharedProcessor
{
  if (sharedProcessor)
  {
    [sharedProcessor release];
    sharedProcessor = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Initializes a CommandProcessor object.
///
/// @note This is the designated initializer of CommandProcessor.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  [self setupThread];
  self.progressHUD = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CommandProcessor object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.progressHUD = nil;
  self.thread = nil;
  if (sharedProcessor == self)
    sharedProcessor = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupThread
{
  self.shouldExit = false;
  self.thread = [[[NSThread alloc] initWithTarget:self
                                         selector:@selector(mainLoop:)
                                           object:nil] autorelease];
  [self.thread start];
}

// -----------------------------------------------------------------------------
/// @brief Getter for the progressHUD property. Implements lazy initialization.
// -----------------------------------------------------------------------------
- (MBProgressHUD*) progressHUD
{
  if (! _progressHUD)
  {
    UIView* superview = [ApplicationDelegate sharedDelegate].window;
    _progressHUD = [[MBProgressHUD alloc] initWithView:superview];
    [superview addSubview:_progressHUD];
    _progressHUD.mode = MBProgressHUDModeAnnularDeterminate;
    _progressHUD.dimBackground = YES;
  }
  return _progressHUD;
}

// -----------------------------------------------------------------------------
/// @brief Submits @a command for synchronous or asynchronous execution. Invokes
/// doIt() on @a command to execute the encapsulated command.
///
/// This method is usually (but not always) executed in the main thread's
/// context. One notable example is when an asynchronous command, which is
/// already executed in a secondary thread's context, submits another command.
/// Submission then occurs in the secondary thread's context.
///
/// If the command's property @e asynchronous is false, the command is executed
/// immediately in the context of the caller's thread (which may or may not be
/// the main thread).
///
/// If the command's property @e asynchronous is true, what happens next depends
/// on the current thread context:
/// - If the current thread already is the secondary thread in which all
///   asynchronous commands are executed, then the command is executed
///   synchronously. This occurs if an asynchronous command submits another
///   command.
/// - If the current thread is the main thread (or any other secondary thread
///   that is not the command execution thread), then control immediately
///   returns to the caller and the command is executed in the context of the
///   command execution secondary thread.
///
/// If @a command is executed synchronously, this method returns whatever value
/// the command's doIt() method returns. True means the command executed
/// successfully, false means the command failed. Exceptions raised while
/// executing the command are passed back to the caller.
///
/// If @a command is executed asynchronously, the return value of this method
/// is always true. The caller has no way to determine whether command execution
/// was successful or not. Exceptions raised while executing the command are
/// handled by the command execution secondary thread. Handling consists of
/// logging the exception, then rethrowing it and thus crashing the application.
// -----------------------------------------------------------------------------
- (bool) submitCommand:(id<Command>)command
{
  bool executionResult = true;
  if ([command conformsToProtocol:@protocol(AsynchronousCommand)])
  {
    ((id<AsynchronousCommand>)command).asynchronousCommandDelegate = self;
    if ([NSThread currentThread] == self.thread)
      executionResult = [self executeCommand:command];
    else
      [self submitAsynchronousCommand:command];
  }
  else
  {
    executionResult = [self executeCommand:command];
  }
  return executionResult;
}

// -----------------------------------------------------------------------------
/// @brief Initializes the HUD, then submits @a command to the command execution
/// secondary thread. Returns immediately before command execution begins.
///
/// This helper method can be executed in arbitrary thread contexts (except for
/// the context of the command execution secondary thread).
// -----------------------------------------------------------------------------
- (void) submitAsynchronousCommand:(id<Command>)command
{
  BOOL animated = YES;
  [self.progressHUD show:animated];

  // Retain to make sure that object is still alive when it "arrives" in
  // the secondary thread
  [command retain];
  [self performSelector:@selector(executeCommandAsynchronously:)
               onThread:self.thread
             withObject:command
          waitUntilDone:NO];
}

// -----------------------------------------------------------------------------
/// @brief Invokes executeCommand:() to execute the asynchronous @a command.
///
/// This helper method is always executed in the command execution secondary
/// thread.
// -----------------------------------------------------------------------------
- (void) executeCommandAsynchronously:(id<Command>)command
{
  // Undo retain message sent to the command object by
  // submitAsynchronousCommand:()
  [command autorelease];
  [self executeCommand:command];
  [self.progressHUD removeFromSuperview];
  self.progressHUD = nil;
}

// -----------------------------------------------------------------------------
/// @brief Invokes doIt() on @a command to execute the encapsulated command.
/// Returns true if execution was successful.
///
/// This is the backend method that actually executes a command. It is used both
/// for synchronous and asynchronous command execution, thus it can be executed
/// in arbitrary thread contexts.
///
/// @see submitCommand:()
// -----------------------------------------------------------------------------
- (bool) executeCommand:(id<Command>)command
{
  DDLogInfo(@"Executing %@", command);
  bool result;
  @try
  {
    result = [command doIt];
  }
  @catch (NSException* exception)
  {
    result = false;
    DDLogError(@"Exception raised while executing command, exception reason: %@, exception stack trace %@", exception, [exception callStackSymbols]);
    @throw;
  }
  @finally
  {
    if (result)
      DDLogVerbose(@"Command execution succeeded (%@)", command);
    else
      DDLogError(@"Command execution failed (%@)", command);
  }
  return result;
}

// -----------------------------------------------------------------------------
/// @brief The command execution secondary thread's main loop method. Returns
/// only after the @e shouldExit property has been set to true.
// -----------------------------------------------------------------------------
- (void) mainLoop:(id)object
{
  // Create an autorelease pool as the very first thing in this thread
  NSAutoreleasePool* mainPool = [[NSAutoreleasePool alloc] init];

  // The timer is required because otherwise the run loop has no input source
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

  // Deallocate the autorelease pool as the very last thing in this thread
  [mainPool drain];
}

// -----------------------------------------------------------------------------
/// @brief AsynchronousCommandDelegate method
// -----------------------------------------------------------------------------
- (void) asynchronousCommand:(id<AsynchronousCommand>)command didProgress:(float)progress nextStepMessage:(NSString*)message
{
  self.progressHUD.progress = progress;
  if (message)
    self.progressHUD.labelText = message;
}

@end
