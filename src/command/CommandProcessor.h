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



// Forward declarations
@protocol Command;


// -----------------------------------------------------------------------------
/// @brief The CommandProcessor class is responsible for executing commands
/// encapsulated by objects of type Command. It implements a part of the
/// Command Processor design pattern.
///
/// Clients invoke submitCommand:() to pass a command object to the command
/// processor. The command processor then synchronously executes the command
/// by invoking the object's doI() method.
///
/// The command processor remembers commands that are undoable in a command
/// history. The history has no size limit. When a client invokes undoCommand(),
/// the command processor looks up the command in its history that was most
/// rececently executed, and invokes this command's undo() method. It then
/// forgets about the command, so that a subsequent invocation of undoCommand()
/// will undo the next command in the history.
///
///
/// @par Command ownership
///
/// CommandProcessor takes ownership of command objects submitted to it.
/// CommandProcessor destroys a command object either immediately after the
/// command has been executed (if it's not undoable), or after the command
/// leaves the command history by any means. Clients should never submit the
/// same command object twice, nor should they continue to use the object after
/// it was submitted.
// -----------------------------------------------------------------------------
@interface CommandProcessor : NSObject
{
}

+ (CommandProcessor*) sharedProcessor;
- (void) submitCommand:(id<Command>)command;
// TODO implement undo functionality discussed in the class documentation
// - (void) undoCommand;

@end
