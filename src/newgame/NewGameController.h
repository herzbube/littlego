// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "ItemPickerController.h"
#import "HandicapSelectionController.h"

// Forward declarations
@class NewGameController;


// -----------------------------------------------------------------------------
/// @brief The NewGameControllerDelegate protocol must be implemented by the
/// delegate of NewGameController.
// -----------------------------------------------------------------------------
@protocol NewGameControllerDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for dismissing the modal
/// @a controller.
///
/// If @a didStartNewGame is true, the user has requested starting a new game.
/// The choices made by the user are available from NewGamemodel.
/// If @a didStartNewGame is false, the user has cancelled starting a new game.
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame;
@end


// -----------------------------------------------------------------------------
/// @brief The NewGameController class is responsible for managing the
///  "New game" screen.
///
/// The "New Game" screen collects information from the user that is required to
/// start a new game. The view is a generic UITableView whose input elements
/// are created dynamically by NewGameController. The data for populating the
/// view is provided by NewGameModel. Any changes made by the user (even if
/// she does not start a new game) are immediately written back to NewGameModel
/// so that when the "New Game" view is displayed the next time it will have
/// the same choices as the last time.
///
/// NewGameController expects to be displayed modally by a navigation
/// controller. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// NewGameController expects to be configured with a delegate that can be
/// informed of the result of data collection. For this to work, the delegate
/// must implement the protocol NewGameControllerDelegate.
// -----------------------------------------------------------------------------
@interface NewGameController : UIViewController <UITableViewDataSource,
                                                 UITableViewDelegate,
                                                 ItemPickerDelegate,
                                                 HandicapSelectionDelegate>
{
}

+ (NewGameController*) controllerWithDelegate:(id<NewGameControllerDelegate>)delegate
                                     loadGame:(bool)loadGame;

@end
