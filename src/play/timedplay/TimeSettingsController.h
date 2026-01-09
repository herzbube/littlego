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
#import "../../ui/ItemPickerController.h"

// Forward declarations
@class TimeSettingsModel;


// -----------------------------------------------------------------------------
/// @brief The TimeSettingsController class is responsible for displaying
/// the values in a TimeSettingsModel object and letting the user change those
/// values.
// -----------------------------------------------------------------------------
@interface TimeSettingsController : UITableViewController <ItemPickerDelegate>
{
}

- (id) initWithTimeSettingsModel:(TimeSettingsModel*)timeSettingsModel;

@end
