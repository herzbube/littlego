// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "MagnifyingViewModel.h"


@implementation MagnifyingViewModel

// -----------------------------------------------------------------------------
/// @brief Initializes a MagnifyingViewModel object with user defaults data.
///
/// @note This is the designated initializer of MagnifyingViewModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.enableMode = MagnifyingGlassEnableModeDefault;
  self.autoThreshold = MagnifyingGlassAutoThresholdDefault;
  self.distanceFromMagnificationCenter = MagnifyingGlassDistanceFromMagnificationCenterDefault;
  self.veerDirection = MagnifyingGlassVeerDirectionDefault;
  self.updateMode = MagnifyingGlassUpdateModeDefault;
  self.magnifyingGlassDimension = defaultMagnifyingGlassDimension;
  self.magnification = defaultMagnifyingGlassMagnification;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  self.enableMode = [[userDefaults valueForKey:magnifyingGlassEnableModeKey] intValue];
  self.autoThreshold = [[userDefaults valueForKey:magnifyingGlassAutoThresholdKey] floatValue];
  self.distanceFromMagnificationCenter = [[userDefaults valueForKey:magnifyingGlassDistanceFromMagnificationCenterKey] floatValue];
  self.veerDirection = [[userDefaults valueForKey:magnifyingGlassVeerDirectionKey] intValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setValue:[NSNumber numberWithInt:self.enableMode] forKey:magnifyingGlassEnableModeKey];
  [userDefaults setValue:[NSNumber numberWithFloat:self.autoThreshold] forKey:magnifyingGlassAutoThresholdKey];
  [userDefaults setValue:[NSNumber numberWithFloat:self.distanceFromMagnificationCenter] forKey:magnifyingGlassDistanceFromMagnificationCenterKey];
  [userDefaults setValue:[NSNumber numberWithInt:self.veerDirection] forKey:magnifyingGlassVeerDirectionKey];
}

@end
