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
#import "Command.h"


// -----------------------------------------------------------------------------
/// @brief The CommandBase class provides a useful default implementation of
/// the interface defined by protocol Command.
///
/// CommandBase synthesizes the properties defined by Command, sets the command
/// name to the object's class name, and sets the "undoable" flag to false.
///
/// To prevent compiler warnings, CommandBase also provides an implementation
/// of the required doIt() method, however the implementation throws an
/// exception to force subclasses to override it.
///
/// CommandBase conveniently knows how to submit itself to the application's
/// shared CommandProcessor, thus clients do not have to concern themselves
/// with where to obtain a CommandProcessor instance.
///
/// Finally, CommandBase provides a description() method that returns useful
/// information about the command object, for instance when used in conjunction
/// with NSLog or the debugger command "po".
// -----------------------------------------------------------------------------
@interface CommandBase : NSObject <Command>
{
}

- (id) init;
- (bool) submit;
- (void) submitAfterDelay:(NSTimeInterval)delay;
- (bool) submitWithCompletionHandler:(void (^)(NSObject<Command>* command, bool success))completionHandler;
- (NSString*) shortDescription;

@end
