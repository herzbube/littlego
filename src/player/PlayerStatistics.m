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
#import "PlayerStatistics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayerStatistics.
// -----------------------------------------------------------------------------
@interface PlayerStatistics()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation PlayerStatistics

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayerStatistics object with all attributes set to
/// zero.
// -----------------------------------------------------------------------------
- (id) init
{
  // Invoke designated initializer
  return [self initWithDictionary:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayerStatistics object with user defaults data stored
/// inside @a dictionary.
///
/// If @a dictionary is @e nil, the PlayerStatistics object has all attributes
/// set to zero.
///
/// Invoke the asDictionary() method to convert a PlayerStatistics object's user
/// defaults attributes back into an NSDictionary suitable for storage in the
/// user defaults system.
///
/// @note This is the designated initializer of PlayerStatistics.
// -----------------------------------------------------------------------------
- (id) initWithDictionary:(NSDictionary*)dictionary
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  else if (! dictionary)
  {
    self.gamesPlayed = 0;
    self.gamesWon = 0;
    self.gamesLost = 0;
    self.gamesTied = 0;
  }
  else
  {
    // The value returned from the NSDictionary has the type NSCFNumber. It
    // appears that this can be treated as an NSNumber object, from which we
    // can get the value by sending the message "intValue".
    self.gamesPlayed = [[dictionary valueForKey:gamesPlayedKey] intValue];
    self.gamesWon = [[dictionary valueForKey:gamesWonKey] intValue];
    self.gamesLost = [[dictionary valueForKey:gamesLostKey] intValue];
    self.gamesTied = [[dictionary valueForKey:gamesTiedKey] intValue];
  }
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayerStatistics object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns this PlayerStatistics object's user defaults attributes as a
/// dictionary suitable for storage in the user defaults system.
// -----------------------------------------------------------------------------
- (NSDictionary*) asDictionary
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  // setValue:forKey:() allows for nil values, so we use that instead of
  // setObject:forKey:() which is less forgiving and would force us to check
  // for nil values.
  // Note: Use NSNumber to represent int and bool values as an object.
  [dictionary setValue:[NSNumber numberWithInt:self.gamesPlayed] forKey:gamesPlayedKey];
  [dictionary setValue:[NSNumber numberWithInt:self.gamesWon] forKey:gamesWonKey];
  [dictionary setValue:[NSNumber numberWithInt:self.gamesLost] forKey:gamesLostKey];
  [dictionary setValue:[NSNumber numberWithInt:self.gamesTied] forKey:gamesTiedKey];
  return dictionary;
}

@end
