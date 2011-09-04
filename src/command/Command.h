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


// -----------------------------------------------------------------------------
/// @brief The Command protocol defines the interface of a command in the
/// well-known Command design pattern.
// -----------------------------------------------------------------------------
@protocol Command <NSObject>
@required
/// @brief Executes the command. Returns true if execution was successful.
- (bool) doIt;

@optional
/// @brief Undo of the actions performed by execute(). Returns true if the undo
/// operation was successful.
- (bool) undo;

@required
/// @brief The name used by the command to identify itself.
///
/// This is a technical name that should not be displayed in the GUI. It might
/// be used, for instance, for logging purposes.
@property(retain) NSString* name;

@required
/// @brief True if the command's undo() method may be invoked. The default is
/// false.
@property(getter=isUndoable) bool undoable;

@end

