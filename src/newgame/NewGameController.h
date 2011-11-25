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


// Project includes
#import "BoardSizeSelectionController.h"
#import "PlayerSelectionController.h"
#import "HandicapSelectionController.h"
#import "KomiSelectionController.h"

// System includes
#import <UIKit/UIKit.h>

// Forward declarations
@class NewGameController;
@class Player;


// -----------------------------------------------------------------------------
/// @brief The NewGameDelegate protocol must be implemented by the delegate of
/// NewGameController.
// -----------------------------------------------------------------------------
@protocol NewGameDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for dismissing the modal
/// @a controller.
///
/// If @a didStartNewGame is true, the user has requested starting a new game.
/// If @a didStartNewGame is false, the user has cancelled starting a new game.
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame;
@end


// -----------------------------------------------------------------------------
/// @brief The NewGameController class is responsible for managing user
/// interaction on the "New Game" view.
///
/// The "New Game" view collects information from the user that is required to
/// start a new game. The view is a generic UITableView whose input elements
/// are created dynamically by NewGameController. The data for populating the
/// view is provided by NewGameModel.
///
/// NewGameController expects to be displayed modally by a navigation
/// controller. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// NewGameController expects to be configured with a delegate that can be
/// informed of the result of data collection. For this to work, the delegate
/// must implement the protocol NewGameDelegate.
// -----------------------------------------------------------------------------
@interface NewGameController : UITableViewController <BoardSizeSelectionDelegate, PlayerSelectionDelegate, HandicapSelectionDelegate, KomiSelectionDelegate, UIAlertViewDelegate>
{
}

+ (NewGameController*) controllerWithDelegate:(id<NewGameDelegate>)delegate loadGame:(bool)loadGame;

/// @brief This is the delegate that will be informed about the result of data
/// collection.
@property(nonatomic, assign) id<NewGameDelegate> delegate;
/// @brief True if the intent for starting a new game is to load a game from
/// the archive.
@property(nonatomic, assign) bool loadGame;
/// @brief The currently selected board size.
@property(nonatomic, assign) enum GoBoardSize boardSize;
/// @brief The currently selected player for black.
@property(nonatomic, retain) Player* blackPlayer;
/// @brief The currently selected player for white.
@property(nonatomic, retain) Player* whitePlayer;
/// @brief The currently selected handicap.
@property(nonatomic, assign) int handicap;
/// @brief The currently selected Komi.
@property(nonatomic, assign) double komi;

@end
