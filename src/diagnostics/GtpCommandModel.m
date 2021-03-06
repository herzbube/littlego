// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "GtpCommandModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GtpCommandModel.
// -----------------------------------------------------------------------------
@interface GtpCommandModel()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSArray* commandList;
//@}
@end


@implementation GtpCommandModel

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpCommandModel object.
///
/// @note This is the designated initializer of GtpCommandModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.commandList = [NSMutableArray arrayWithCapacity:0];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpCommandModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.commandList = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  self.commandList = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:gtpCannedCommandsKey]];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:self.commandList forKey:gtpCannedCommandsKey];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (int) commandCount
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31)
  // commands.
  return (int)_commandList.count;
}

// -----------------------------------------------------------------------------
/// @brief Returns the command string located at position @a index in the
/// commandList array.
// -----------------------------------------------------------------------------
- (NSString*) commandStringAtIndex:(int)index
{
  return [_commandList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a commandString already exists in the commandList
/// array.
// -----------------------------------------------------------------------------
- (bool) hasCommand:(NSString*)commandString
{
  for (NSString* iterCommandString in _commandList)
  {
    if ([iterCommandString isEqualToString:commandString])
      return true;
  }
  return false;
}

// -----------------------------------------------------------------------------
/// @brief Adds the command string @a commandString to the end of the
/// commandList array.
// -----------------------------------------------------------------------------
- (void) addCommand:(NSString*)commandString
{
  [(NSMutableArray*)_commandList addObject:commandString];
}

// -----------------------------------------------------------------------------
/// @brief Replaces the command string at index position @a index in the
/// commandList array by the new command string @a commandString.
// -----------------------------------------------------------------------------
- (void) replaceCommandAtIndex:(int)index withCommand:(NSString*)commandString
{
  [(NSMutableArray*)_commandList replaceObjectAtIndex:index withObject:commandString];
}

// -----------------------------------------------------------------------------
/// @brief Removes the command string located at position @a index from the
/// commandList array.
// -----------------------------------------------------------------------------
- (void) removeCommandAtIndex:(int)index
{
  [(NSMutableArray*)_commandList removeObjectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Moves the command string located at position @a fromIndex in the
/// commandList array to the new position @a toIndex.
// -----------------------------------------------------------------------------
- (void) moveCommandAtIndex:(int)fromIndex toIndex:(int)toIndex
{
  // Retain because removing the object from the array sends a release message
  NSString* commandToMove = [[_commandList objectAtIndex:fromIndex] retain];
  [(NSMutableArray*)_commandList removeObjectAtIndex:fromIndex];
  [(NSMutableArray*)_commandList insertObject:commandToMove atIndex:toIndex];
  [commandToMove release];
}

// -----------------------------------------------------------------------------
/// @brief Discards the current list of predefined commands and restores the
/// factory default list that is shipped with the application.
// -----------------------------------------------------------------------------
- (void) resetToFactorySettings
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults removeObjectForKey:gtpCannedCommandsKey];
  [self readUserDefaults];
}

@end
