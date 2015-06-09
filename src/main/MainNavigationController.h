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
#import "MainMenuPresenter.h"
#import "../play/gameaction/GameActionManager.h"


// -----------------------------------------------------------------------------
/// @brief The MainNavigationController class is one of several alternative
/// main application view controllers. Its responsibility is to let the user
/// navigate to the different main areas of the application.
///
/// MainNavigationController by default displays the Go board and various other
/// views related to playing the game. MainNavigationController also displays a
/// button in the upper-right corner that floats over the rest of the content.
/// When the user taps the button, MainNavigationController calls up a table
/// view that shows entries that the user can select to navigate to other parts
/// of the application. The Go board is no longer visible in that case until the
/// user dismisses the table view.
///
/// @see WindowRootViewController
// -----------------------------------------------------------------------------
@interface MainNavigationController : UINavigationController <UINavigationControllerDelegate, MainMenuPresenterDelegate, GameInfoViewControllerPresenter>
{
}

- (void) activateUIArea:(enum UIArea)uiArea;
- (UIView*) rootViewForUIAreaPlay;

@end
