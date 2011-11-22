// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class EditGtpEngineProfileController;
@class GtpEngineProfile;


// -----------------------------------------------------------------------------
/// @brief The EditGtpEngineProfileDelegate protocol must be implemented by the
/// delegate of EditGtpEngineProfileController.
// -----------------------------------------------------------------------------
@protocol EditGtpEngineProfileDelegate
/// @brief This method is invoked after @a editGtpEngineProfileController has
/// updated its profile object with new information.
- (void) didChangeProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController;
/// @brief This method is invoked after @a editGtpEngineProfileController has
/// deleted its profile object.
- (void) didDeleteProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController;
@end


// -----------------------------------------------------------------------------
/// @brief The EditGtpEngineProfileController class is responsible for managing
/// user interaction on the "Edit Profile" view.
///
/// The "Edit Profile" view allows the user to edit the information associated
/// with a GtpEngineProfile object. The view is a generic UITableView whose
/// input elements are created dynamically by EditGtpEngineProfileController.
///
/// EditGtpEngineProfileController expects to be displayed by a navigation
/// controller. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// EditGtpEngineProfileController expects to be configured with a delegate that
/// can be informed when the user makes any changes. For this to work, the
/// delegate must implement the protocol EditGtpEngineProfileDelegate.
// -----------------------------------------------------------------------------
@interface EditGtpEngineProfileController : UITableViewController <UITextFieldDelegate>
{
}

+ (EditGtpEngineProfileController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditGtpEngineProfileDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user makes any
/// changes.
@property(nonatomic, assign) id<EditGtpEngineProfileDelegate> delegate;
/// @brief The model object
@property(retain) GtpEngineProfile* profile;

@end
