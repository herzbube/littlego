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
#import "../ui/EditTextController.h"
#import "../newgame/NewGameController.h"

// Forward declarations
@class ArchiveGame;
@class ArchiveViewModel;


// -----------------------------------------------------------------------------
/// @brief The ViewGameController class is responsible for managing user
/// interaction on the "View Game" view.
///
/// The "View Game" view displays information associated with an ArchiveGame
/// object. The view is a generic UITableView whose input elements are created
/// dynamically by ViewGameController.
///
/// ViewGameController expects to be displayed by a navigation controller. For
/// this reason it populates its own navigation item with controls that are
/// then expected to be displayed in the navigation bar of the parent
/// navigation controller.
// -----------------------------------------------------------------------------
@interface ViewGameController : UITableViewController <EditTextDelegate, NewGameDelegate>
{
}

+ (ViewGameController*) controllerWithGame:(ArchiveGame*)game model:(ArchiveViewModel*)model;

/// @brief Reference to the ArchiveGame that this ViewGameController displays
/// data for.
@property(nonatomic, assign) ArchiveGame* game;
/// @brief Model that manages all ArchiveGame objects.
@property(nonatomic, assign) ArchiveViewModel* model;

@end
