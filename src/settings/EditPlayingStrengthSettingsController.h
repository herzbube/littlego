// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "MaxMemoryController.h"
#import "../ui/ItemPickerController.h"

// Forward declarations
@class EditPlayingStrengthSettingsController;
@class GtpEngineProfile;


// -----------------------------------------------------------------------------
/// @brief The EditPlayingStrengthSettingsDelegate protocol must be implemented
/// by the delegate of EditPlayingStrengthSettingsController.
// -----------------------------------------------------------------------------
@protocol EditPlayingStrengthSettingsDelegate
/// @brief This method is invoked after @a EditPlayingStrengthSettingsController
/// has updated its profile object with new information.
- (void) didChangeProfile:(EditPlayingStrengthSettingsController*)editPlayingStrengthSettingsController;
@end


// -----------------------------------------------------------------------------
/// @brief The EditPlayingStrengthSettingsController class is responsible for
/// managing user interaction on the "Playing strength" preferences view.
///
/// The "Playing strength" preferences view allows the advanced user to edit
/// individual, playing-strength related preferences associated with a
/// GtpEngineProfile object. The view is a generic UITableView whose input
/// elements are created dynamically by EditPlayingStrengthSettingsController.
///
/// EditPlayingStrengthSettingsController expects to be displayed by a
/// navigation controller. For this reason it populates its own navigation item
/// with controls that are then expected to be displayed in the navigation bar
/// of the parent navigation controller.
///
/// EditPlayingStrengthSettingsController expects to be configured with a
/// delegate that can be informed when the user makes any changes. For this to
/// work, the delegate must implement the protocol
/// EditPlayingStrengthSettingsDelegate.
// -----------------------------------------------------------------------------
@interface EditPlayingStrengthSettingsController : UITableViewController <MaxMemoryControllerDelegate, ItemPickerDelegate, UIActionSheetDelegate>
{
}

+ (EditPlayingStrengthSettingsController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditPlayingStrengthSettingsDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user makes any
/// changes.
@property(nonatomic, assign) id<EditPlayingStrengthSettingsDelegate> delegate;
/// @brief The model object
@property(nonatomic, retain) GtpEngineProfile* profile;

@end
