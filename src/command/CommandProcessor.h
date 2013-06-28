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
#import "AsynchronousCommand.h"
#import "../ui/MBProgressHUD.h"

// Forward declarations
@protocol Command;


// -----------------------------------------------------------------------------
/// @brief The CommandProcessor class is responsible for executing commands
/// encapsulated by objects of type Command. It implements a part of the
/// Command Processor design pattern.
///
/// Clients invoke submitCommand:() to pass a command object to the command
/// processor. The command processor then executes the command by invoking the
/// object's doI() method. Execution occurs synchronously or asynchronously
/// depending on whether the command object conforms to the AsynchronousCommand
/// protocol.
///
/// The command processor remembers commands that are undoable in a command
/// history. The history has no size limit. When a client invokes undoCommand(),
/// the command processor looks up the command in its history that was most
/// rececently executed, and invokes this command's undo() method. It then
/// forgets about the command, so that a subsequent invocation of undoCommand()
/// will undo the next command in the history.
///
///
/// @par Asynchronous command execution
///
/// If a command object conforms to the AsynchronousCommand protocol, the
/// command's doIt() or undo() methods are invoked in the context of a secondary
/// thread. Control returns immediately to the caller who invoked
/// submitCommand:() or undoCommand(). CommandProcessor displays an
/// MBProgressHUD while it executes the command, and feeds progress updates from
/// the command into the HUD. Progress updates are delivered via the
/// AsynchronousCommandDelegate protocol.
///
/// @see submitCommand:()
// -----------------------------------------------------------------------------
@interface CommandProcessor : NSObject <AsynchronousCommandDelegate, MBProgressHUDDelegate>
{
}

+ (CommandProcessor*) sharedProcessor;
+ (void) releaseSharedProcessor;
- (bool) submitCommand:(id<Command>)command;
// TODO implement undo functionality discussed in the class documentation
// - (void) undoCommand;

/// @brief Set this property to true to trigger termination of the secondary
/// thread used for asynchronous command execution.
@property(assign, getter=shouldExit, setter=exit:) bool shouldExit;
/// @brief Is true if the code querying this property is running in the context
/// of this CommandProcessor's secondary thread.
@property(assign, readonly) bool currentThreadIsCommandProcessorThread;

@end
