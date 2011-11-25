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
#import "CommandProcessor.h"
#import "Command.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for CommandProcessor.
// -----------------------------------------------------------------------------
@interface CommandProcessor()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
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
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CommandProcessor object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (sharedProcessor == self)
    sharedProcessor = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invokes doIt() on @a command to execute the encapsulated command.
/// Returns true if execution was successful.
///
/// Releases @a command after execution is complete with the intent of
/// disposing of the command object. A client that wants to continue using the
/// object (not recommended) must retain it.
// -----------------------------------------------------------------------------
- (bool) submitCommand:(id<Command>)command
{
  DDLogInfo(@"Executing %@", command);
  bool result = [command doIt];
  if (result)
    DDLogVerbose(@"Command execution succeeded (%@)", command);
  else
    DDLogError(@"Command execution failed (%@)", command);
  [command release];
  return result;
}

@end
