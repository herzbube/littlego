// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "EditGtpEngineProfileController.h"
#import "../ui/EditTextController.h"
#import "../ui/ItemPickerController.h"

// Forward declarations
@class EditPlayerController;
@class Player;


// -----------------------------------------------------------------------------
/// @brief The EditPlayerDelegate protocol must be implemented by the delegate
/// of EditPlayerController.
// -----------------------------------------------------------------------------
@protocol EditPlayerDelegate <NSObject>
@optional
/// @brief This method is invoked after @a editPlayerController has updated its
/// player object with new information.
- (void) didChangePlayer:(EditPlayerController*)editPlayerController;
/// @brief This method is invoked after @a editPlayerController has created a
/// new player object.
- (void) didCreatePlayer:(EditPlayerController*)editPlayerController;
/// @brief This method is invoked when @a editPlayerController is presented
/// modally and the user has finished working with @a editPlayerController. The
/// delegate is responsible for dismissing @a editPlayerController.
- (void) didEditPlayer:(EditPlayerController*)editPlayerController;
@end


// -----------------------------------------------------------------------------
/// @brief The EditPlayerController class is responsible for managing user
/// interaction on the "Edit/New Player" view.
///
/// The "Edit/New Player" view allows the user to edit the information
/// associated with a Player object. The view is a generic UITableView whose
/// input elements are created dynamically by EditPlayerController. The
/// controller runs in one of two modes, depending on which convenience
/// constructor is used to create the controller instance:
/// - Create mode: The player whose attributes are edited does not exist yet,
///   the user must tap a "create" button to confirm that the player should be
///   created.
/// - Edit mode: The player whose attributes are edited already exists. Changes
///   cannot be undone, they are immediately written to the Player model object.
///
/// EditPlayerController expects to be displayed by a navigation controller,
/// either presented modally or pushed on the controller's navigation stack. For
/// this reason it populates its own navigation item with controls that are
/// then expected to be displayed in the navigation bar of the parent
/// navigation controller.
///
/// EditPlayerController expects to be configured with a delegate that can be
/// informed when the user makes any changes. For this to work, the delegate
/// must implement the protocol EditPlayerDelegate.
// -----------------------------------------------------------------------------
@interface EditPlayerController : UITableViewController <EditTextDelegate, ItemPickerDelegate, EditGtpEngineProfileDelegate>
{
}

+ (EditPlayerController*) controllerForPlayer:(Player*)player withDelegate:(id<EditPlayerDelegate>)delegate;
+ (EditPlayerController*) controllerWithDelegate:(id<EditPlayerDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user makes any
/// changes.
@property(nonatomic, assign) id<EditPlayerDelegate> delegate;
/// @brief The model object
@property(nonatomic, retain) Player* player;
/// @brief Flag is true if the player whose attributes are edited already
/// exists, false if the player still needs to be created.
@property(nonatomic, assign) bool playerExists;

@end
