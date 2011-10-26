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
/// @brief The GtpCommandModel class is responsible for managing canned
/// (= predefined) GTP commands.
// -----------------------------------------------------------------------------
@interface GtpCommandModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;
- (NSString*) commandStringAtIndex:(int)index;
- (bool) hasCommand:(NSString*)commandString;
- (void) addCommand:(NSString*)commandString;
- (void) replaceCommandAtIndex:(int)index withCommand:(NSString*)commandString;
- (void) removeCommandAtIndex:(int)index;
- (void) moveCommandAtIndex:(int)fromIndex toIndex:(int)toIndex;
- (void) resetToFactorySettings;

/// @brief Number of commands in @e commandList.
///
/// This property exists purely as a convenience to clients, since the object
/// count is also available from the commandList array.
@property(readonly) int commandCount;
/// @brief Array stores objects of type NSString. Commands appear in the array
/// in the order assigned to them by the user.
@property(readonly, retain) NSArray* commandList;

@end
