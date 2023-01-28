// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameVariationsModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GameVariationsModel.
// -----------------------------------------------------------------------------
@interface GameVariationsModel()
@end


@implementation GameVariationsModel

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameVariationsModel object with user defaults data.
///
/// @note This is the designated initializer of GameVariationsModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.newMoveInsertPolicy = GoNewMoveInsertPolicyRetainFutureBoardPositions;
  self.newMoveInsertPosition = GoNewMoveInsertPositionNewVariationAfterCurrentVariation;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameVariationsModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:gameVariationsKey];
  self.newMoveInsertPolicy = [[dictionary valueForKey:newMoveInsertPolicyKey] intValue];
  self.newMoveInsertPosition = [[dictionary valueForKey:newMoveInsertPositionKey] intValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.newMoveInsertPolicy] forKey:newMoveInsertPolicyKey];
  [dictionary setValue:[NSNumber numberWithInt:self.newMoveInsertPosition] forKey:newMoveInsertPositionKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:gameVariationsKey];
}

@end
