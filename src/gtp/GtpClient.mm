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
#include "GtpClient.h"


@interface GtpClient(Private)
/// @name Initialization and deallocation
//@{
- (id) initWithPipes:(NSArray*)pipes responseReceiver:(id)aReceiver;
- (void) dealloc;
//@}
- (void) processCommand:(NSString*)command;
@end


@implementation GtpClient

@synthesize responseReceiver;
@synthesize shouldExit;


// -----------------------------------------------------------------------------
/// @brief Initializes a GtpClient object.
///
/// @note This is the designated initializer of GtpClient.
// -----------------------------------------------------------------------------
- (id) initWithPipes:(NSArray*)pipes responseReceiver:(id)aReceiver
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.responseReceiver = aReceiver;
  self.shouldExit = false;

  // Create and start the thread
  m_thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainLoop:) object:pipes];
  [m_thread start];

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
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief xxx
// -----------------------------------------------------------------------------
+ (GtpClient*) clientWithInputPipe:(NSString*)inputPipe outputPipe:(NSString*)outputPipe responseReceiver:(id)aReceiver;
{
  // Create copies so that the objects can be safely used by the thread when
  // it starts
  NSArray* pipes = [NSArray arrayWithObjects:[inputPipe copy], [outputPipe copy], nil];
  return [[GtpClient alloc] initWithPipes:pipes responseReceiver:aReceiver];
}

// -----------------------------------------------------------------------------
/// @brief xxx
// -----------------------------------------------------------------------------
- (void) mainLoop:(NSArray*)pipes
{
  // Create an autorelease pool as the very first thing in this thread
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  // Stream to write commands for the GTP engine
  NSString* inputPipePath = [pipes objectAtIndex:0];
  const char* pchInputPipePath = [inputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]];
  m_commandStream.open(pchInputPipePath);

  // Stream to read responses from the GTP engine
  NSString* outputPipePath = [pipes objectAtIndex:1];
  const char* pchOutputPipePath = [outputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]];
  m_responseStream.open(pchOutputPipePath);

  // The timer is required because otherwise the run loop has no input source
  NSDate* distantFuture = [NSDate distantFuture]; 
  NSTimer* distantFutureTimer = [[NSTimer alloc] initWithFireDate:distantFuture
                                                         interval:1.0
                                                           target:self
                                                         selector:@selector(setClientThread:)   // pseudo selector
                                                         userInfo:nil
                                                          repeats:NO];
  [[NSRunLoop currentRunLoop] addTimer:distantFutureTimer forMode:NSDefaultRunLoopMode];

  while (true)
  {
    bool hasInputSources = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                                    beforeDate:distantFuture];
    if (! hasInputSources)  // always true, see timer input source above
      break;
    if (self.shouldExit)
      break;
  }

  // Deallocate the autorelease pool as the very last thing in this thread
  [pool release];
}

// -----------------------------------------------------------------------------
/// @brief xxx      executes on the main thread
// -----------------------------------------------------------------------------
- (void) setCommand:(NSString*)command
{
  [self performSelector:@selector(processCommand:) onThread:m_thread withObject:[command copy] waitUntilDone:NO];
}

// -----------------------------------------------------------------------------
/// @brief xxx      executes on the client thread
// -----------------------------------------------------------------------------
- (void) processCommand:(NSString*)command
{
  // Send the command to the engine
  if (nil == command || 0 == [command length])
    return;
  const char* pchCommand = [command cStringUsingEncoding:[NSString defaultCStringEncoding]];
  m_commandStream << pchCommand << std::endl;  // this wakes up the engine

  // Read the engine's response (blocking if necessary)
  std::string fullResponse;
  std::string singleLineResponse;
  while (true)
  {
    getline(m_responseStream, singleLineResponse);
    if (singleLineResponse.empty())
      break;
    if (! fullResponse.empty())
      fullResponse += "\n";
    fullResponse += singleLineResponse;
  }

  // Notify the main thread of the response
  NSString* nsResponse = [NSString stringWithCString:fullResponse.c_str() 
                                            encoding:[NSString defaultCStringEncoding]];
  [self.responseReceiver performSelectorOnMainThread:@selector(setResponse:) withObject:nsResponse waitUntilDone:NO];

  if (NSOrderedSame == [command compare:@"quit"])
  {
    // After the current method is executed, the thread's run loop will wake
    // up, the main loop will find that the flag is true and stop running
    self.shouldExit = true;
  }
}

@end
