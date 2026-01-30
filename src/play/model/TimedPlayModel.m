// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "TimedPlayModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TimedPlayModel.
// -----------------------------------------------------------------------------
@interface TimedPlayModel()
@end


@implementation TimedPlayModel

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a TimedPlayModel object with user defaults data.
///
/// @note This is the designated initializer of TimedPlayModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.timeDataValidationMode = GoTimeDataValidationModeBasic;
  self.showTrueRemainingTimeAfterLastMoveWhenLostOnTime = true;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimedPlayModel object.
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
  NSDictionary* dictionary = [userDefaults dictionaryForKey:timedPlayKey];

  self.timeDataValidationMode = [[dictionary valueForKey:timeDataValidationModeKey] intValue];
  self.showTrueRemainingTimeAfterLastMoveWhenLostOnTime = [[dictionary valueForKey:showTrueRemainingTimeAfterLastMoveWhenLostOnTimeKey] boolValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.timeDataValidationMode] forKey:timeDataValidationModeKey];
  [dictionary setValue:[NSNumber numberWithBool:self.showTrueRemainingTimeAfterLastMoveWhenLostOnTime] forKey:showTrueRemainingTimeAfterLastMoveWhenLostOnTimeKey];

  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:timedPlayKey];
}

@end
