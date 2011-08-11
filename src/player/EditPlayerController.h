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


// System includes
#import <UIKit/UIKit.h>

// Forward declarations
@class EditPlayerController;
@class Player;


// -----------------------------------------------------------------------------
/// @brief The EditPlayerDelegate protocol must be implemented by the delegate
/// of EditPlayerController.
// -----------------------------------------------------------------------------
@protocol EditPlayerDelegate
/// @brief This method is invoked after @a EditPlayerController has updated its
/// player object with new information.
- (void) didChangePlayer:(EditPlayerController*)editPlayerController;
@end


// -----------------------------------------------------------------------------
/// @brief The EditPlayerController class is responsible for managing user
/// interaction on the "Edit Player" view.
///
/// The "Edit Player" view allows the user to edit the information associated
/// with a player object. The view is a generic UITableView whose input elements
/// are created dynamically by EditPlayerController.
///
/// EditPlayerController expects to be displayed by a navigation controller. For
/// this reason it populates its own navigation item with controls that are
/// then expected to be displayed in the navigation bar of the parent
/// navigation controller.
///
/// EditPlayerController expects to be configured with a delegate that can be
/// informed when the user makes any changes. For this to work, the delegate
/// must implement the protocol EditPlayerDelegate.
// -----------------------------------------------------------------------------
@interface EditPlayerController : UITableViewController <UITextFieldDelegate>
{
}

+ (EditPlayerController*) controllerForPlayer:(Player*)player withDelegate:(id<EditPlayerDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user makes any
/// changes.
@property(nonatomic, assign) id<EditPlayerDelegate> delegate;
/// @brief The model object
@property(retain) Player* player;

@end
