// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardSetupModel.h"


@implementation BoardSetupModel

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardSetupModel object with default values.
///
/// @note This is the designated initializer of BoardSetupModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  
  self.boardSetupStoneColor = GoColorBlack;
  self.doubleTapToZoom = true;
  self.autoEnableBoardSetupMode = false;
  self.changeHandicapAlert = true;
  self.tryNotToPlaceIllegalStones = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  self.boardSetupStoneColor = [[userDefaults valueForKey:boardSetupStoneColorKey] intValue];
  self.doubleTapToZoom = [[userDefaults valueForKey:doubleTapToZoomKey] boolValue] == YES;
  self.autoEnableBoardSetupMode = [[userDefaults valueForKey:autoEnableBoardSetupModeKey] boolValue] == YES;
  self.changeHandicapAlert = [[userDefaults valueForKey:changeHandicapAlertKey] boolValue] == YES;
  self.tryNotToPlaceIllegalStones = [[userDefaults valueForKey:tryNotToPlaceIllegalStonesKey] boolValue] == YES;
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  [userDefaults setValue:[NSNumber numberWithInt:self.boardSetupStoneColor] forKey:boardSetupStoneColorKey];
  [userDefaults setValue:[NSNumber numberWithBool:self.doubleTapToZoom ? YES : NO] forKey:doubleTapToZoomKey];
  [userDefaults setValue:[NSNumber numberWithBool:self.autoEnableBoardSetupMode ? YES : NO] forKey:autoEnableBoardSetupModeKey];
  [userDefaults setValue:[NSNumber numberWithBool:self.changeHandicapAlert ? YES : NO] forKey:changeHandicapAlertKey];
  [userDefaults setValue:[NSNumber numberWithBool:self.tryNotToPlaceIllegalStones ? YES : NO] forKey:tryNotToPlaceIllegalStonesKey];
}

@end
