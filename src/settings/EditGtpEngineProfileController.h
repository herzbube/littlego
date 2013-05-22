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
#import "EditGtpEngineProfileSettingsController.h"
#import "EditResignBehaviourSettingsController.h"
#import "../ui/EditTextController.h"
#import "../ui/ItemPickerController.h"

// Forward declarations
@class EditGtpEngineProfileController;
@class GtpEngineProfile;


// -----------------------------------------------------------------------------
/// @brief The EditGtpEngineProfileDelegate protocol must be implemented by the
/// delegate of EditGtpEngineProfileController.
// -----------------------------------------------------------------------------
@protocol EditGtpEngineProfileDelegate <NSObject>
@optional
/// @brief This method is invoked after @a editGtpEngineProfileController has
/// updated its profile object with new information.
- (void) didChangeProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController;
/// @brief This method is invoked after @a editGtpEngineProfileController has
/// created a new profile object.
- (void) didCreateProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController;
/// @brief This method is invoked when @a editGtpEngineProfileController is
/// presented modally and the user has finished working with
/// @a editGtpEngineProfileController. The delegate is responsible for
/// dismissing @a editGtpEngineProfileController.
- (void) didEditProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController;
@end


// -----------------------------------------------------------------------------
/// @brief The EditGtpEngineProfileController class is responsible for managing
/// user interaction on the "Edit/New Profile" view.
///
/// The "Edit/New Profile" view allows the user to edit basic information
/// associated with a GtpEngineProfile object. The user can adjust the profile's
/// playing strength either by selecting one of several pre-defined combinations
/// of settings, or by tweaking individual settings. In the latter case, editing
/// of those settings is delegated to EditGtpEngineProfileSettingsController
/// (isn't that a nice name?).
///
/// The view managed by EditGtpEngineProfileController is a generic UITableView
/// whose input elements are created dynamically by
/// EditGtpEngineProfileController. The controller runs in one of two modes,
/// depending on which convenience constructor is used to create the controller
/// instance:
/// - Create mode: The profile whose attributes are edited does not exist yet,
///   the user must tap a "create" button to confirm that the profile should be
///   created.
/// - Edit mode: The profile whose attributes are edited already exists. Changes
///   cannot be undone, they are immediately written to the GtpEngineProfile
///   model object.
///
/// EditGtpEngineProfileController expects to be displayed by a navigation
/// controller, either presented modally or pushed on the controller's
/// navigation stack. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// EditGtpEngineProfileController expects to be configured with a delegate that
/// can be informed when the user makes any changes. For this to work, the
/// delegate must implement the protocol EditGtpEngineProfileDelegate.
// -----------------------------------------------------------------------------
@interface EditGtpEngineProfileController : UITableViewController <UITextFieldDelegate,
                                                                   EditTextDelegate,
                                                                   ItemPickerDelegate,
                                                                   EditGtpEngineProfileSettingsDelegate,
                                                                   EditResignBehaviourSettingsDelegate>
{
}

+ (EditGtpEngineProfileController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditGtpEngineProfileDelegate>)delegate;
+ (EditGtpEngineProfileController*) controllerWithDelegate:(id<EditGtpEngineProfileDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user makes any
/// changes.
@property(nonatomic, assign) id<EditGtpEngineProfileDelegate> delegate;
/// @brief The model object
@property(nonatomic, retain) GtpEngineProfile* profile;
/// @brief Flag is true if the profile whose attributes are edited already
/// exists, false if the profile still needs to be created.
@property(nonatomic, assign) bool profileExists;

@end
