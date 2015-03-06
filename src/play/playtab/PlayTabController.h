// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "../gameaction/GameActionManager.h"


// -----------------------------------------------------------------------------
/// @brief The PlayTabController class represents the root view controller on
/// the Play tab of MainTabBarController.
///
/// The view hierarchy on the Play tab is laid out differently depending on
/// the UI type that is effective at runtime. Use the class method
/// playTabController() to obtain a UI type-dependent controller object that
/// knows how to set up the correct view hierarchy for the current UI type.
///
/// @see LayoutManager
/// @see MainTabBarController
// -----------------------------------------------------------------------------
@interface PlayTabController : UIViewController <UINavigationControllerDelegate, GameInfoViewControllerPresenter>
{
}

+ (PlayTabController*) playTabController;

@end
