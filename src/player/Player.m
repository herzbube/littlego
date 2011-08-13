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
#import "Player.h"
#import "PlayerStatistics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for Player.
// -----------------------------------------------------------------------------
@interface Player()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation Player

@synthesize name;
@synthesize human;
@synthesize statistics;


// -----------------------------------------------------------------------------
/// @brief Initializes a Player object with user defaults data.
///
/// @note This is the designated initializer of Player.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  // Invoke designated initializer
  return [self initWithDictionary:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a Player object with user defaults data stored inside
/// @a dictionary.
///
/// If @a dictionary is @e nil, the Player object is human, has no name, and is
/// associated with a PlayerStatistics object that has all attributes set
/// to zero.
///
/// Invoke the asDictionary() method to convert a Player object's user defaults
/// attributes back into an NSDictionary suitable for storage in the user
/// defaults system.
///
/// @note This is the designated initializer of Player.
// -----------------------------------------------------------------------------
- (id) initWithDictionary:(NSDictionary*)dictionary
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  else if (! dictionary)
  {
    self.name = @"";
    self.human = true;
    self.statistics = [[PlayerStatistics alloc] init];
    [self.statistics release];
  }
  else
  {
    self.name = (NSString*)[dictionary valueForKey:nameKey];
    // The value returned from the NSDictionary has the type NSCFBoolean. It
    // appears that this can be treated as an NSNumber object, from which we
    // can get the value by sending the message "boolValue".
    self.human = [[dictionary valueForKey:isHumanKey] boolValue];
    NSDictionary* statisticsDictionary = (NSDictionary*)[dictionary valueForKey:statisticsKey];
    self.statistics = [[PlayerStatistics alloc] initWithDictionary:statisticsDictionary];
  }
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this Player object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.name = nil;
  self.statistics = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns this Player object's user defaults attributes as a dictionary
/// suitable for storage in the user defaults system.
// -----------------------------------------------------------------------------
- (NSDictionary*) asDictionary
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  // setValue:forKey:() allows for nil values, so we use that instead of
  // setObject:forKey:() which is less forgiving and would force us to check
  // for nil values.
  // Note: Use NSNumber to represent int and bool values as an object.
  [dictionary setValue:self.name forKey:nameKey];
  [dictionary setValue:[NSNumber numberWithBool:self.isHuman] forKey:isHumanKey];
  [dictionary setValue:[self.statistics asDictionary] forKey:statisticsKey];
  return dictionary;
}

@end