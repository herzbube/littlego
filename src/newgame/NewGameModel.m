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
#import "NewGameModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for NewGameModel.
// -----------------------------------------------------------------------------
@interface NewGameModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation NewGameModel

@synthesize boardSize;
@synthesize blackPlayerUUID;
@synthesize whitePlayerUUID;
@synthesize handicap;
@synthesize komi;


// -----------------------------------------------------------------------------
/// @brief Initializes a NewGameModel object with user defaults data.
///
/// @note This is the designated initializer of NewGameModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.boardSize = GoBoardSizeUndefined;
  self.blackPlayerUUID = @"";
  self.whitePlayerUUID = @"";
  self.handicap = 0;
  self.komi = 0;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NewGameModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.blackPlayerUUID = nil;
  self.whitePlayerUUID = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:newGameKey];
  self.boardSize = [[dictionary valueForKey:boardSizeKey] intValue];
  self.blackPlayerUUID = (NSString*)[dictionary valueForKey:blackPlayerKey];
  self.whitePlayerUUID = (NSString*)[dictionary valueForKey:whitePlayerKey];
  self.handicap = [[dictionary valueForKey:handicapKey] intValue];
  self.komi = [[dictionary valueForKey:komiKey] doubleValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  // setValue:forKey:() allows for nil values, so we use that instead of
  // setObject:forKey:() which is less forgiving and would force us to check
  // for nil values.
  // Note: Use NSNumber to represent int and bool values as an object.
  [dictionary setValue:[NSNumber numberWithInt:self.boardSize] forKey:boardSizeKey];
  [dictionary setValue:self.blackPlayerUUID forKey:blackPlayerKey];
  [dictionary setValue:self.whitePlayerUUID forKey:whitePlayerKey];
  [dictionary setValue:[NSNumber numberWithInt:self.handicap] forKey:handicapKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.komi] forKey:komiKey];
  // Note: NSUserDefaults takes care entirely by itself of writing only changed
  // values.
  // TODO: As far as I can tell, the assertion above is wrong, at least on the
  // simulator. Verify whether the assertion might be true on the device proper.
  // If it's not, implement my own layer that takes care of storing only values
  // that differ from the registered defaults.
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:newGameKey];
}

@end
