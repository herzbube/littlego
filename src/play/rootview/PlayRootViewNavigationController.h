// -----------------------------------------------------------------------------
// Copyright 2015-2026 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The PlayRootViewNavigationController class is a
/// UINavigationController that handles the special navigational needs of
/// #UIAreaPlay.
///
/// The root view controller of PlayRootViewNavigationController is an instance
/// of one of the subclasses of PlayRootViewController.
///
/// The purpose of PlayRootViewNavigationController is to allow presenting other
/// view controllers on top of the root view controller.
// -----------------------------------------------------------------------------
@interface PlayRootViewNavigationController : UINavigationController <UINavigationControllerDelegate, GameActionManagerViewControllerPresenterDelegate>
{
}

@end
