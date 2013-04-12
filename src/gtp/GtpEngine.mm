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
#include "GtpEngine.h"

// Fuego
#include <fuego/FuegoMainUtil.h>


@implementation GtpEngine

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpEngine instance which will use
/// the two named pipes to communicate with its counterpart GtpClient.
// -----------------------------------------------------------------------------
+ (GtpEngine*) engineWithInputPipe:(NSString*)inputPipe outputPipe:(NSString*)outputPipe
{
  // Create copies so that the objects can be safely used by the thread when
  // it starts
  NSArray* pipes = [NSArray arrayWithObjects:[[inputPipe copy] autorelease], [[outputPipe copy] autorelease], nil];
  return [[[GtpEngine alloc] initWithPipes:pipes] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpEngine object.
///
/// @note This is the designated initializer of GtpEngine.
// -----------------------------------------------------------------------------
- (id) initWithPipes:(NSArray*)pipes
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

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
/// @brief Deallocates memory allocated by this GtpEngine object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // TODO implement stuff
  [m_thread release];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief The secondary thread's main loop method. Returns only after the
/// GTP engine's main method returns.
// -----------------------------------------------------------------------------
- (void) mainLoop:(NSArray*)pipes
{
  // Create an autorelease pool as the very first thing in this thread
  NSAutoreleasePool* mainPool = [[NSAutoreleasePool alloc] init];

  // Pipe to read commands from the GTP client
  NSString* inputPipePath = [pipes objectAtIndex:0];
  const char* pchInputPipePath = [inputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]];

  // Stream to write responses to the GTP client
  NSString* outputPipePath = [pipes objectAtIndex:1];
  const char* pchOutputPipePath = [outputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]];

  char programName[255];
  char inputPipeParameterName[255];
  char inputPipeParameterValue[255];
  char outputPipeParameterName[255];
  char outputPipeParameterValue[255];
  char nobookParameterName[255];
  char quietParameterName[255];
  sprintf(programName, "fuego");
  sprintf(inputPipeParameterName, "--input-pipe");
  sprintf(inputPipeParameterValue, "%s", pchInputPipePath);
  sprintf(outputPipeParameterName, "--output-pipe");
  sprintf(outputPipeParameterValue, "%s", pchOutputPipePath);
  sprintf(nobookParameterName, "--nobook");  // opening book is loaded separately from a project resource
  sprintf(quietParameterName, "--quiet");  // don't print debug messages, otherwise the project's debugging console becomes overloaded
  int argc = 7;
  char* argv[argc];
  argv[0] = programName;
  argv[1] = inputPipeParameterName;
  argv[2] = inputPipeParameterValue;
  argv[3] = outputPipeParameterName;
  argv[4] = outputPipeParameterValue;
  argv[5] = nobookParameterName;
  argv[6] = quietParameterName;

  try
  {
    // No need to create an autorelease pool, no Objective-C stuff is happening
    // in here...
    FuegoMainUtil::FuegoMain(argc, argv);
  }
  catch(std::exception& e)
  {
  }
  catch(...)
  {
  }

  // Deallocate the autorelease pool as the very last thing in this thread
  [mainPool release];
}

@end
