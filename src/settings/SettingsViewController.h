// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The SettingsViewController class is responsible for managing user
/// interaction on the "Settings" view.
///
/// The "Settings" view is a very simple table view with only a few items that
/// provide access to different collections of user preferences. Each collection
/// is managed by its own table view controller, the task of
/// SettingsViewController is merely to create those controllers and push them
/// onto the main navigation controller.
// -----------------------------------------------------------------------------
@interface SettingsViewController : UITableViewController
{
}

+ (SettingsViewController*) controller;

@end
