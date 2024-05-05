// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#ifndef LITTLEGO_UNITTESTS
#include <fuego-on-ios/FuegoMainUtil.h>
#endif

// System includes
#include <exception>
#include <istream>
#include <ostream>
#include <streambuf>

@implementation GtpEngine

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpEngine instance which will use
/// C++ Standard Library I/O streams to communicate with its counterpart
/// GtpClient. The I/O streams are constructed with the stream buffers in the
/// specified array.
// -----------------------------------------------------------------------------
+ (GtpEngine*) engineWithStreamBuffers:(NSArray*)streamBuffers
{
  return [[[GtpEngine alloc] initWithStreamBuffers:streamBuffers] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpEngine object.
///
/// @note This is the designated initializer of GtpEngine.
// -----------------------------------------------------------------------------
- (id) initWithStreamBuffers:(NSArray*)streamBuffers
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Create and start the thread
  m_thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainLoop:) object:streamBuffers];
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
- (void) mainLoop:(NSArray*)streamBuffers
{
  // Create an autorelease pool as the very first thing in this thread
  NSAutoreleasePool* mainPool = [[NSAutoreleasePool alloc] init];

  // Stream to read commands from the GTP client
  NSValue* inputStreamBufferAsNSValue = [streamBuffers objectAtIndex:0];
  std::streambuf* inputStreamBuffer = reinterpret_cast<std::streambuf*>([inputStreamBufferAsNSValue pointerValue]);
  std::istream inputStream(inputStreamBuffer);

  // Stream to write responses to the GTP client
  NSValue* outputStreamBufferAsNSValue = [streamBuffers objectAtIndex:1];
  std::streambuf* outputStreamBuffer = reinterpret_cast<std::streambuf*>([outputStreamBufferAsNSValue pointerValue]);
  std::ostream outputStream(outputStreamBuffer);

  char programName[255];
  char nobookParameterName[255];
  char quietParameterName[255];
  snprintf(programName, sizeof(programName), "fuego");
  snprintf(nobookParameterName, sizeof(nobookParameterName), "--nobook");  // opening book is loaded separately from a project resource
  snprintf(quietParameterName, sizeof(quietParameterName), "--quiet");  // don't print debug messages, otherwise the project's debugging console becomes overloaded
  int argc = 3;
  char* argv[argc];
  argv[0] = programName;
  argv[1] = nobookParameterName;
  argv[2] = quietParameterName;

  try
  {
#ifndef LITTLEGO_UNITTESTS
    // No need to create an autorelease pool, no Objective-C stuff is happening
    // in here...
    FuegoMainUtil::FuegoMain(argc, argv, &inputStream, &outputStream);
#endif
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
