// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @defgroup gtp GTP module
///
/// Classes in this module are associated with GTP, the Go Text Protocol.
// -----------------------------------------------------------------------------


// Project includes
#import "GtpClient.h"
#import "GtpCommand.h"
#import "GtpResponse.h"

// System includes
#include <istream>
#include <ostream>
#include <streambuf>

// It would be much nicer to make these variables members of the GtpClient
// class, but they are C++ and GtpClient.h is also #import'ed by pure
// Objective-C implementations.
static std::ostream* commandStream = nullptr;
static std::istream* responseStream = nullptr;

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GtpClient.
// -----------------------------------------------------------------------------
@interface GtpClient()
@property(retain) NSThread* thread;
@end


@implementation GtpClient

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpClient instance which will use
/// C++ Standard Library I/O streams to communicate with its counterpart
/// GtpEngine. The I/O streams are constructed with the stream buffers in the
/// specified array.
// -----------------------------------------------------------------------------
+ (GtpClient*) clientWithStreamBuffers:(NSArray*)streamBuffers
{
  return [[[GtpClient alloc] initWithStreamBuffers:streamBuffers] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpClient object.
///
/// @note This is the designated initializer of GtpClient.
// -----------------------------------------------------------------------------
- (id) initWithStreamBuffers:(NSArray*)streamBuffers
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.shouldExit = false;

  // Create and start the thread
  self.thread = [[[NSThread alloc] initWithTarget:self selector:@selector(mainLoop:) object:streamBuffers] autorelease];
  [self.thread start];

  // TODO: Clients that work with self returned here will invoke methods in
  // the context of the main thread. Find a clever/elegant solution so that
  // there is an automatic context switch. We don't want clients to worry about
  // calling NSObject's performSelector:onThread:withObject:waitUntilDone.
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpClient object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // TODO implement stuff
  self.thread = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief The secondary thread's main loop method. Returns only after the
/// @e shouldExit property has been set to true.
// -----------------------------------------------------------------------------
- (void) mainLoop:(NSArray*)streamBuffers
{
  // Create an autorelease pool as the very first thing in this thread
  NSAutoreleasePool* mainPool = [[NSAutoreleasePool alloc] init];

  // Stream to write commands for the GTP engine
  NSValue* inputStreamBufferAsNSValue = [streamBuffers objectAtIndex:0];
  std::streambuf* inputStreamBuffer = reinterpret_cast<std::streambuf*>([inputStreamBufferAsNSValue pointerValue]);
  std::ostream inputStream(inputStreamBuffer);
  commandStream = &inputStream;

  // Stream to read responses from the GTP engine
  NSValue* outputStreamBufferAsNSValue = [streamBuffers objectAtIndex:1];
  std::streambuf* outputStreamBuffer = reinterpret_cast<std::streambuf*>([outputStreamBufferAsNSValue pointerValue]);
  std::istream outputStream(outputStreamBuffer);
  responseStream = &outputStream;

  // The timer is required because otherwise the run loop has no input source
  NSDate* distantFuture = [NSDate distantFuture];
  NSTimer* distantFutureTimer = [[NSTimer alloc] initWithFireDate:distantFuture
                                                         interval:1.0
                                                           target:self
                                                         selector:@selector(dealloc)   // pseudo selector
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

  // The local objects are auto-destroyed when they go out of scope. Here we
  // forget the global references to these local objects
  commandStream = nullptr;
  responseStream = nullptr;

  // Deallocate the autorelease pool as the very last thing in this thread
  [mainPool drain];
}

// -----------------------------------------------------------------------------
/// @brief Processes the GTP command @a command. This method is executed in the
/// secondary thread's context.
///
/// Performs the following operations:
/// - Pass @a command to the GtpEngine
/// - Wait for the response from the GtpEngine (blocks)
/// - Creates a GtpResponse object using the response received from the
///   GtpEngine
/// - If requested, invokes notifyResponseTarget:() to notify an observer
///   object that the response has been received; the notification occurs in
///   the context of the thread that submitted the command
// -----------------------------------------------------------------------------
- (void) processCommand:(GtpCommand*)command
{
  // Undo retain message sent to the command object by submit:()
  [command autorelease];

  // Notify observers in the secondary thread context
  [[NSNotificationCenter defaultCenter] postNotificationName:gtpCommandWillBeSubmittedNotification
                                                      object:command];

  // Send the command to the engine
  if (nil == command.command || 0 == [command.command length])
    return;
  const char* pchCommand = [command.command cStringUsingEncoding:[NSString defaultCStringEncoding]];
  (*commandStream) << pchCommand << std::endl;  // this wakes up the engine
  
  // Read the engine's response (blocking if necessary)
  std::string fullResponse;
  std::string singleLineResponse;
  while (true)
  {
    getline(*responseStream, singleLineResponse);
    if (singleLineResponse.empty())
      break;
    if (! fullResponse.empty())
      fullResponse += "\n";
    fullResponse += singleLineResponse;
  }

  // Create the response object
  NSString* nsResponse = [NSString stringWithCString:fullResponse.c_str()
                                            encoding:[NSString defaultCStringEncoding]];
  GtpResponse* response = [GtpResponse response:nsResponse toCommand:command];
  command.response = response;

  if (response.command.responseTarget)
  {
    // Retain to make sure that object is still alive when it "arrives" in
    // the submitting thread
    [command retain];
    // It's important to call back the submitting thread asynchronously (i.e.
    // waitUntilDone must be NO). If we were to call back synchronously we would
    // get a deadlock when command.waitUntilDone is true.
    [self performSelector:@selector(notifyResponseTarget:)
                 onThread:command.submittingThread
               withObject:command
            waitUntilDone:NO];
  }

  // Notify observers in the secondary thread context
  [[NSNotificationCenter defaultCenter] postNotificationName:gtpResponseWasReceivedNotification
                                                      object:response];

  if (NSOrderedSame == [command.command compare:@"quit"])
  {
    // After the current method is executed, the thread's run loop will wake
    // up, the main loop will find that the flag is true and stop running
    self.shouldExit = true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Submits @a command to the GtpEngine.
///
/// This method is usually (but not always) executed in the main thread's
/// context. One notable example where this is executed in a secondary thread's
/// context is the backup task just before the application is suspended.
///
/// If @a command.waitUntilDone is false, this method returns immediately and
/// does not wait for the GtpEngine's response.
// -----------------------------------------------------------------------------
- (void) submit:(GtpCommand*)command
{
  command.submittingThread = [NSThread currentThread];
  // Retain to make sure that object is still alive when it "arrives" in
  // the secondary thread
  [command retain];
  [self performSelector:@selector(processCommand:)
               onThread:self.thread
             withObject:command
          waitUntilDone:command.waitUntilDone];
}

// -----------------------------------------------------------------------------
/// @brief Notifies the observer object @e command.responseTarget that a
/// response to @a command has been received from the GtpEngine.
///
/// The method invoked is @e command.responseTargetSelector, the argument
/// passed is the GtpResponse object.
///
/// This method is executed in the context of the thread that submitted
/// @a command.
// -----------------------------------------------------------------------------
- (void) notifyResponseTarget:(GtpCommand*)command
{
  // Undo retain message sent to the command object by processCommand:()
  [command autorelease];
  id responseTarget = command.responseTarget;
  if (responseTarget)
  {
    [responseTarget performSelector:command.responseTargetSelector
                         withObject:command.response];
  }
}

// -----------------------------------------------------------------------------
/// @brief Interrupts the GTP command currently being processed by the
/// GtpEngine.
///
/// This method is always executed in the main thread's context, in response to
/// user interaction in the GUI. This method does not return until the
/// interruption has been sent to the GtpEngine.
///
/// @note The current thread architecture does not allow the interrupt to be
/// sent in the context of the secondary thread, because the secondary thread
/// currently blocks and waits for the response to the GTP command that is
/// currently being processed.
///
/// When the GtpEngine is interrupted, it immediately stops processing the
/// current GTP command and returns a result on the GTP response stream.
/// This wakes up the secondary thread that was waiting for the response. The
/// response is processed and the response target is notified in the thread
/// that submitted the command. This is expected to always be the main thread,
/// since the app implements interruptions only for user-generated commands.
/// Response target notification is blocked if the main thread is not yet idle
/// (because interrupt() has not yet been fully processed). The notification
/// #gtpResponseWasReceivedNotification, however, is sent immediately to the
/// global notification centre.
// -----------------------------------------------------------------------------
- (void) interrupt
{
  const char* pchCommand = "# interrupt";
  (*commandStream) << pchCommand << std::endl;
}

@end
