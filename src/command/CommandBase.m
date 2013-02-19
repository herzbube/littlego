// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "CommandBase.h"
#import "CommandProcessor.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for CommandBase.
// -----------------------------------------------------------------------------
@interface CommandBase()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation CommandBase

@synthesize name;
@synthesize undoable;

// -----------------------------------------------------------------------------
/// @brief Initializes a CommandBase object. The command is not undoable and
/// uses the command object's class name as the command name.
///
/// @note This is the designated initializer of CommandBase.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.name = NSStringFromClass([self class]);
  self.undoable = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CommandBase object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  DDLogInfo(@"Deallocating %@", self);
  self.name = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this Command object.
///
/// This method is invoked when Command needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  return [NSString stringWithFormat:@"%@(%p): name = %@, undoable = %d", NSStringFromClass([self class]), self, self.name, self.isUndoable];
}

// -----------------------------------------------------------------------------
/// @brief Returns a short description for this Command object that consists
/// only of the class name and the object's address in memory.
///
/// This method is useful for logging a short but unique reference to the
/// object.
// -----------------------------------------------------------------------------
- (NSString*) shortDescription
{
  return [NSString stringWithFormat:@"%@(%p)", NSStringFromClass([self class]), self];
}

// -----------------------------------------------------------------------------
/// @brief This default implementation exists only to prevent an "incomplete
/// implementation" compiler warning. It always throws an exception and must be
/// overridden by subclasses.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  DDLogError(@"%@: No override for doIt()", [self shortDescription]);
  [self doesNotRecognizeSelector:_cmd];
  return false;
}

// -----------------------------------------------------------------------------
/// @brief Submits this command to the application's shared CommandProcessor
/// for execution. Returns true if execution was successful.
///
/// This is a convenience method so that clients do not need to know
/// CommandProcessor, or how to obtain an instance of CommandProcessor.
///
/// Exceptions raised while executing the command are passed back to the caller.
///
/// @note Invoking this method deallocates this command. The client must retain
/// this command to prevent this.
// -----------------------------------------------------------------------------
- (bool) submit
{
  CommandProcessor* processor = [CommandProcessor sharedProcessor];
  return [processor submitCommand:self];  // self is probably deallocated here!
}

// -----------------------------------------------------------------------------
/// @brief Invokes submit() after @a delay seconds.
// -----------------------------------------------------------------------------
- (void) submitAfterDelay:(NSTimeInterval)delay
{
  DDLogVerbose(@"CommandBase::submitAfterDelay() invoked with delay %f (%@)", delay, self);
  [self performSelector:@selector(submit) withObject:nil afterDelay:delay];
}

@end
