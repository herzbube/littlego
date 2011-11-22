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
@class NewGtpEngineProfileController;
@class GtpEngineProfile;


// -----------------------------------------------------------------------------
/// @brief The NewGtpEngineProfileDelegate protocol must be implemented by the
/// delegate of NewGtpEngineProfileController.
// -----------------------------------------------------------------------------
@protocol NewGtpEngineProfileDelegate
/// @brief This method is invoked after @a newGtpEngineProfileController has
/// created a new profile object.
- (void) didCreateNewProfile:(NewGtpEngineProfileController*)newGtpEngineProfileController;
@end


// -----------------------------------------------------------------------------
/// @brief The NewGtpEngineProfileController class is responsible for managing
/// user interaction on the "New Profile" view.
///
/// The "New Profile" view collects information from the user that is required
/// to create a new GtpEngineProfile. The view is a generic UITableView whose
/// input elements are created dynamically by NewGtpEngineProfileController.
///
/// NewGtpEngineProfileController expects to be displayed by a navigation
/// controller. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// NewGtpEngineProfileController expects to be configured with a delegate that
/// can be informed after a new profile object has been created. For this to
/// work, the delegate must implement the protocol NewGtpEngineProfileDelegate.
// -----------------------------------------------------------------------------
@interface NewGtpEngineProfileController : UITableViewController <UITextFieldDelegate>
{
}

+ (NewGtpEngineProfileController*) controllerWithDelegate:(id<NewGtpEngineProfileDelegate>)delegate;

/// @brief This is the delegate that will be informed about the result of data
/// collection.
@property(nonatomic, assign) id<NewGtpEngineProfileDelegate> delegate;
/// @brief The model object
@property(retain) GtpEngineProfile* profile;

@end
