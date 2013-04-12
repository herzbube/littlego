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
#import "PlayerModel.h"
#import "Player.h"


@implementation PlayerModel

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayerModel object with user defaults data.
///
/// @note This is the designated initializer of PlayerModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.playerCount = 0;
  self.playerList = [NSMutableArray arrayWithCapacity:self.playerCount];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayerModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.playerList = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSMutableArray* localPlayerList = [NSMutableArray array];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSArray* userDefaultsPlayerList = [userDefaults arrayForKey:playerListKey];
  for (NSDictionary* playerDictionary in userDefaultsPlayerList)
  {
    Player* player = [[Player alloc] initWithDictionary:playerDictionary];
    // We want the array to retain and release the object for us -> decrease
    // the retain count by 1 (was set to 1 by alloc/init)
    [player autorelease];
    [localPlayerList addObject:player];
  }
  self.playerCount = [localPlayerList count];
  // Completely replace the previous player list to trigger the
  // key-value-observing mechanism.
  self.playerList = localPlayerList;
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableArray* userDefaultsPlayerList = [NSMutableArray array];
  for (Player* player in self.playerList)
    [userDefaultsPlayerList addObject:[player asDictionary]];
  // Note: NSUserDefaults takes care entirely by itself of writing only changed
  // values.
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:userDefaultsPlayerList forKey:playerListKey];
}

// -----------------------------------------------------------------------------
/// @brief Returns the name of the player at position @a index in the list of
/// players. This is a convenience method.
// -----------------------------------------------------------------------------
- (NSString*) playerNameAtIndex:(int)index
{
  assert(index >= 0 && index < [self.playerList count]);
  Player* player = (Player*)[self.playerList objectAtIndex:index];
  return player.name;
}

// -----------------------------------------------------------------------------
/// @brief Adds object @a player to this model.
// -----------------------------------------------------------------------------
- (void) add:(Player*)player
{
  NSMutableArray* localPlayerList = (NSMutableArray*)self.playerList;
  [localPlayerList addObject:player];
  self.playerCount = [localPlayerList count];
}

// -----------------------------------------------------------------------------
/// @brief Removes object @a player from this model.
// -----------------------------------------------------------------------------
- (void) remove:(Player*)player
{
  NSMutableArray* localPlayerList = (NSMutableArray*)self.playerList;
  [localPlayerList removeObject:player];
  self.playerCount = [localPlayerList count];
}

// -----------------------------------------------------------------------------
/// @brief Returns the player object identified by @a uuid. Returns nil if no
/// such object exists.
// -----------------------------------------------------------------------------
- (Player*) playerWithUUID:(NSString*)uuid
{
  for (Player* player in self.playerList)
  {
    if ([player.uuid isEqualToString:uuid])
      return player;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns a filtered list of player objects where all players are
/// either humans (@a human is true) or computers (@a human is false).
// -----------------------------------------------------------------------------
- (NSArray*) playerListHuman:(bool)human
{
  NSMutableArray* filteredPlayerList = [NSMutableArray arrayWithCapacity:0];
  for (Player* player in self.playerList)
  {
    if (human != player.human)
      continue;
    [filteredPlayerList addObject:player];
  }
  return filteredPlayerList;
}

@end
