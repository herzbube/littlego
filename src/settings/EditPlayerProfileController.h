// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "EditPlayingStrengthSettingsController.h"
#import "EditResignBehaviourSettingsController.h"
#import "../ui/EditTextController.h"
#import "../ui/ItemPickerController.h"

// Forward declarations
@class EditPlayerProfileController;
@class GtpEngineProfile;
@class Player;


// -----------------------------------------------------------------------------
/// @brief The EditPlayerProfileDelegate protocol must be implemented by the
/// delegate of EditPlayerProfileController.
// -----------------------------------------------------------------------------
@protocol EditPlayerProfileDelegate <NSObject>
@optional
/// @brief This method is invoked after @a editPlayerProfileController has
/// updated its player or profile object with new information.
- (void) didChangePlayerProfile:(EditPlayerProfileController*)editPlayerProfileController;
/// @brief This method is invoked after @a editPlayerProfileController has
/// created new player object. Is never invoked for profiles because
/// EditPlayerProfileController does not support creating new standalone
/// profiles.
- (void) didCreatePlayerProfile:(EditPlayerProfileController*)editPlayerProfileController;
/// @brief This method is invoked when @a editPlayerProfileController is
/// presented modally and the user has finished working with
/// @a editPlayerProfileController. The delegate is responsible for
/// dismissing @a editPlayerProfileController.
- (void) didEditPlayerProfile:(EditPlayerProfileController*)editPlayerProfileController;
@end


// -----------------------------------------------------------------------------
/// @brief The EditPlayerProfileController class is responsible for managing
/// user interaction on the "Edit/New Player" and the "Edit Profile" views.
///
/// EditPlayerProfileController provides two views which are very similar:
/// - The "Edit/New Player" view allows the user to edit all the information
///   associated with a Player object and to edit basic information associated
///   with the GtpEngineProfile object that is referenced by the Player.
/// - The "Edit Profile" view allows the user to edit basic information
///   associated with a GtpEngineProfile object only.
///
/// "Basic information" associated with a GtpEngineProfile object means: The
/// user can adjust only the profile's playing strength and resign behaviour
/// by selecting one of several pre-defined combinations of settings. Tweaking
/// the individual settings of a profile is delegated to
/// EditPlayingStrengthSettingsController and
/// EditResignBehaviourSettingsController, respectively.
///
/// @note EditPlayerProfileController presents its view in a manner that blurs
/// the distinction between players and profiles. Experience over the years has
/// shown that many users are confused by the distinctions, and those users
/// that can understand the distinction don't really need it.
///
/// The view managed by EditPlayerProfileController is a generic UITableView
/// whose input elements are created dynamically by EditPlayerProfileController.
/// The controller runs in one of two modes, depending on which convenience
/// constructor is used to create the controller instance:
/// - Create mode: The player and profile whose attributes are edited do not
///   exist yet, the user must tap a "create" button to confirm that the player
///   and profile should be created.
/// - Edit mode: The player and profile whose attributes are edited already
///   exists. Changes cannot be undone, they are immediately written to the
///   Player and GtpEngineProfile model objects.
///
/// EditPlayerProfileController expects to be displayed by a navigation
/// controller, either presented modally (create mode) or pushed on the
/// controller's navigation stack (edit mode). For this reason it populates its
/// own navigation item with controls that are then expected to be displayed in
/// the navigation bar of the parent navigation controller.
///
/// EditPlayerProfileController expects to be configured with a delegate that
/// can be informed when the user makes any changes. For this to work, the
/// delegate must implement the protocol EditPlayerProfileDelegate.
// -----------------------------------------------------------------------------
@interface EditPlayerProfileController : UITableViewController <UITextFieldDelegate,
                                                                EditTextDelegate,
                                                                ItemPickerDelegate,
                                                                EditPlayingStrengthSettingsDelegate,
                                                                EditResignBehaviourSettingsDelegate>
{
}

+ (EditPlayerProfileController*) controllerForPlayer:(Player*)player withDelegate:(id<EditPlayerProfileDelegate>)delegate;
+ (EditPlayerProfileController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditPlayerProfileDelegate>)delegate;
+ (EditPlayerProfileController*) controllerForHumanPlayer:(bool)human withDelegate:(id<EditPlayerProfileDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user makes any
/// changes.
@property(nonatomic, assign) id<EditPlayerProfileDelegate> delegate;
/// @brief The Player model object. Is @e nil if only a profile is being edited.
@property(nonatomic, retain) Player* player;
/// @brief The GtpEngineProfile model object. Either a profile associated with
/// the player in the @e player property, or a standalone profile.
@property(nonatomic, retain) GtpEngineProfile* profile;
/// @brief Flag is true if the model objects whose attributes are edited already
/// exist, false if the model objects still need to be created.
@property(nonatomic, assign) bool playerProfileExists;

@end
