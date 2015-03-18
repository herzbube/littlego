// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The MainTabBarController class is one of several alternative main
/// application view controllers. Its responsibility is to let the user navigate
/// to the different main areas of the application.
///
/// MainTabBarController uses a tab bar to provide the user with navigation
/// capabilities. MainTabBarController displays whichever tab was active when
/// the application was active the last time.
///
/// @see WindowRootViewController
// -----------------------------------------------------------------------------
@interface MainTabBarController : UITabBarController <UITabBarControllerDelegate, UINavigationControllerDelegate>
{
}

- (void) restoreTabBarControllerAppearanceToUserDefaults;
- (UIViewController*) tabControllerForUIArea:(enum UIArea)uiArea;
- (UIView*) tabViewForUIArea:(enum UIArea)uiArea;
- (void) activateTabForUIArea:(enum UIArea)uiArea;

@end
