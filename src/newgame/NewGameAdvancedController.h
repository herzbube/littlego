// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "KomiSelectionController.h"


// -----------------------------------------------------------------------------
/// @brief The NewGameAdvancedController class is responsible for managing the
/// "New game > Advanced settings" subscreen.
///
/// The screen managed by NewGameAdvancedController displays a relatively large
/// number of settings that are used to configure a new game. The main
/// "New game" screen does not show these settings directly so that it can
/// focus on showing other, more important main settings.
///
/// NewGameAdvancedController expects to be pushed on top of the stack of a
/// UINavigationController.
// -----------------------------------------------------------------------------
@interface NewGameAdvancedController : UITableViewController <KomiSelectionDelegate, ItemPickerDelegate>
{
}

+ (NewGameAdvancedController*) controllerWithGameType:(enum GoGameType)gameType
                                             loadGame:(bool)loadGame;

@end
