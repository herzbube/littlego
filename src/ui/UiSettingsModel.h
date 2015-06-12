// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The UiSettingsModel class provides user defaults data to its clients
/// that is related to the general appearance of the user interface.
// -----------------------------------------------------------------------------
@interface UiSettingsModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;

/// @brief The UI area that is currently visible.
@property(nonatomic, assign) enum UIArea visibleUIArea;
/// @brief The order in which controllers currently appear in the application's
/// main tab bar controller.
///
/// Each view controller in the application's main tab bar controller has an
/// associated UITabBarItem object. That object has a @e tag property whose
/// value is an element from the #UIArea enumeration.
///
/// Array elements are NSNumber objects with integer values. Integer values
/// correspond to the #UIArea enumeration values and can thus be matched to
/// a corresponding view controller.
@property(nonatomic, retain) NSArray* tabOrder;

@end
