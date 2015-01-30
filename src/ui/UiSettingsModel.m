// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "UiSettingsModel.h"


@implementation UiSettingsModel

// -----------------------------------------------------------------------------
/// @brief Initializes a UiSettingsModel object with default values.
///
/// @note This is the designated initializer of UiSettingsModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.selectedTabIndex = defaultSelectedTabIndex;
  _tabOrder = [[NSMutableArray arrayWithCapacity:arraySizeDefaultTabOrder] retain];
  for (int arrayIndex = 0; arrayIndex < arraySizeDefaultTabOrder; ++arrayIndex)
    [(NSMutableArray*)_tabOrder addObject:[NSNumber numberWithInt:defaultTabOrder[arrayIndex]]];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this UiSettingsModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.tabOrder = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) tabs.
  self.selectedTabIndex = (int)[userDefaults integerForKey:selectedTabIndexKey];
  self.tabOrder = [userDefaults arrayForKey:tabOrderKey];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setInteger:self.selectedTabIndex forKey:selectedTabIndexKey];
  [userDefaults setObject:self.tabOrder forKey:tabOrderKey];
}

@end
