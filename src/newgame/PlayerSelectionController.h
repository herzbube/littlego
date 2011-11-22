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
@class PlayerSelectionController;
@class Player;


// -----------------------------------------------------------------------------
/// @brief The PlayerSelectionDelegate protocol must be implemented by the
/// delegate of PlayerSelectionController.
// -----------------------------------------------------------------------------
@protocol PlayerSelectionDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for dismissing the modal
/// @a controller.
///
/// If @a didMakeSelection is true, the user has made a selection; the selected
/// player object can be queried from the PlayerSelectionController object's
/// property @a player. If @a didMakeSelection is false, the user has cancelled
/// the selection.
- (void) playerSelectionController:(PlayerSelectionController*)controller didMakeSelection:(bool)didMakeSelection;
@end


// -----------------------------------------------------------------------------
/// @brief The PlayerSelectionController class is responsible for managing the
/// view that lets the user select a player.
///
/// PlayerSelectionController expects to be displayed modally by a navigation
/// controller. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// PlayerSelectionController expects to be configured with a delegate that
/// can be informed of the result of data collection. For this to work, the
/// delegate must implement the protocol PlayerSelectionDelegate.
// -----------------------------------------------------------------------------
@interface PlayerSelectionController : UITableViewController
{
}

+ (PlayerSelectionController*) controllerWithDelegate:(id<PlayerSelectionDelegate>)delegate defaultPlayer:(Player*)player blackPlayer:(bool)blackPlayer;

/// @brief This is the delegate that will be informed about the result of data
/// collection.
@property(nonatomic, assign) id<PlayerSelectionDelegate> delegate;
/// @brief The currently selected player.
@property(retain) Player* player;
/// @brief True if the selected player is going to play black.
@property(assign) bool blackPlayer;

@end
