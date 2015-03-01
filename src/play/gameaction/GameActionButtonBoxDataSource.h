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
#import "GameActionManager.h"
#import "../../ui/ButtonBoxController.h"


// -----------------------------------------------------------------------------
/// @brief The GameActionButtonBoxDataSource class acts as a mediator between
/// GameActionManager (which defines an abstract set of game actions), and
/// ButtonBoxController (which provides a visual representation of those actions
/// in the form of UIButtons).
///
/// GameActionButtonBoxDataSource defines the basic grid dimensions of the
/// "button box", and which buttons occupy which cells in the grid.
/// GameActionButtonBoxDataSource also performs the duties that are expected
/// by GameActionManagerUIDelegate.
///
/// @see GameActionManager
// -----------------------------------------------------------------------------
@interface GameActionButtonBoxDataSource : NSObject <ButtonBoxControllerDataSource, GameActionManagerUIDelegate>
{
}

/// @brief A weak reference that back-links to the ButtonBoxController object.
/// Required so that button box data can be reloaded when GameActionManager
/// updates the visibility state of game actions.
@property(nonatomic, assign) ButtonBoxController* buttonBoxController;

@end
