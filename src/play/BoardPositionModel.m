// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for BoardPositionModel.
// -----------------------------------------------------------------------------
@interface BoardPositionModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation BoardPositionModel

@synthesize discardFutureMovesAlert;
@synthesize playOnComputersTurnAlert;


// -----------------------------------------------------------------------------
/// @brief Initializes a ScoringModel object with user defaults data.
///
/// @note This is the designated initializer of BoardPositionModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.discardFutureMovesAlert = discardFutureMovesAlertDefault;
  self.playOnComputersTurnAlert = playOnComputersTurnAlertDefault;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:boardPositionKey];
  self.discardFutureMovesAlert = [[dictionary valueForKey:discardFutureMovesAlertKey] boolValue];
  self.playOnComputersTurnAlert = [[dictionary valueForKey:playOnComputersTurnAlertKey] boolValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithBool:self.discardFutureMovesAlert] forKey:discardFutureMovesAlertKey];
  [dictionary setValue:[NSNumber numberWithBool:self.playOnComputersTurnAlert] forKey:playOnComputersTurnAlertKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:boardPositionKey];
}

@end
