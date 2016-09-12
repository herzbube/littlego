// -----------------------------------------------------------------------------
// Copyright 2013-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "../ui/ItemPickerController.h"
#import "../ui/SliderInputController.h"

// Forward declarations
@class EditResignBehaviourSettingsController;
@class GtpEngineProfile;


// -----------------------------------------------------------------------------
/// @brief The EditResignBehaviourSettingsDelegate protocol must be implemented
/// by the delegate of EditResignBehaviourSettingsController.
// -----------------------------------------------------------------------------
@protocol EditResignBehaviourSettingsDelegate
/// @brief This method is invoked after @a editResignBehaviourSettingsController
/// has updated its profile object with new information.
- (void) didChangeResignBehaviour:(EditResignBehaviourSettingsController*)editResignBehaviourSettingsController;
@end


// -----------------------------------------------------------------------------
/// @brief The EditResignBehaviourSettingsController class is responsible for
/// managing user interaction on the "Resign Behaviour" preferences view.
// -----------------------------------------------------------------------------
@interface EditResignBehaviourSettingsController : UITableViewController <SliderInputDelegate, ItemPickerDelegate>
{
}

@property(nonatomic, assign) id<EditResignBehaviourSettingsDelegate> delegate;
@property(nonatomic, assign) GtpEngineProfile* profile;

@end
