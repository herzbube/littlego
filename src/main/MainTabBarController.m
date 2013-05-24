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


// Project includes
#import "MainTabBarController.h"
#import "ApplicationDelegate.h"
#import "../ui/UiUtilities.h"


@implementation MainTabBarController

// -----------------------------------------------------------------------------
/// @brief Initializes a MainTabBarController.
///
/// @note This is the designated initializer of MainTabBarController.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  // Call designated initializer of superclass (NSObject)
  self = [super initWithCoder:decoder];
  if (! self)
    return nil;
  self.delegate = self;
  self.moreNavigationController.delegate = self;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This implementation exists so that in iOS 6 the app can rotate to
/// UIInterfaceOrientationPortraitUpsideDown on the iPhone.
// -----------------------------------------------------------------------------
- (NSUInteger) supportedInterfaceOrientations
{
  return [UiUtilities supportedInterfaceOrientations];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  // Disable edit button in the "more" navigation controller
  self.customizableViewControllers = [NSArray array];
}

// -----------------------------------------------------------------------------
/// @brief UITabBarControllerDelegate method
///
/// Writes user defaults in response to the user switching tabs.
// -----------------------------------------------------------------------------
- (void) tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController
{
  [[ApplicationDelegate sharedDelegate] writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief UINavigationControllerDelegate method
///
/// Writes user defaults in response to the user switching views on the tab
/// bar controller's more navigation controller.
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController didShowViewController:(UIViewController*)viewController animated:(BOOL)animated
{
  [[ApplicationDelegate sharedDelegate] writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Returns the root controller for the tab identified by @a tabID.
/// Returns nil if @a tabID is not recognized.
///
/// This method returns the correct controller even if the tab is located in
/// the "More" navigation controller.
// -----------------------------------------------------------------------------
- (UIViewController*) tabController:(enum TabType)tabID
{
  for (UIViewController* controller in self.viewControllers)
  {
    if (controller.tabBarItem.tag == tabID)
      return controller;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the main view for the tab identified by @a tabID. Returns
/// nil if @a tabID is not recognized.
///
/// This method returns the correct view even if the tab is located in the
/// "More" navigation controller.
// -----------------------------------------------------------------------------
- (UIView*) tabView:(enum TabType)tabID
{
  UIViewController* tabController = [self tabController:tabID];
  if (tabController)
    return tabController.view;
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Activates the tab identified by @a tabID, making it visible to the
/// user.
///
/// This method works correctly even if the tab is located in the "More"
/// navigation controller.
// -----------------------------------------------------------------------------
- (void) activateTab:(enum TabType)tabID
{
  UIViewController* tabController = [self tabController:tabID];
  if (tabController)
  {
    self.selectedViewController = tabController;
    // The delegate method tabBarController:didSelectViewController:() is not
    // invoked when the selectedViewController property is changed
    // programmatically
    [[ApplicationDelegate sharedDelegate] writeUserDefaults];
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps TabType values to resource file names. The name that is returned
/// can be used with NSBundle to load the resource file's content.
// -----------------------------------------------------------------------------
- (NSString*) resourceNameForTabType:(enum TabType)tabType
{
  NSString* resourceName = nil;
  switch (tabType)
  {
    case TabTypeManual:
      resourceName = manualDocumentResource;
      break;
    case TabTypeAbout:
      resourceName = aboutDocumentResource;
      break;
    case TabTypeSourceCode:
      resourceName = sourceCodeDocumentResource;
      break;
    case TabTypeCredits:
      resourceName = creditsDocumentResource;
      break;
    default:
      break;
  }
  return resourceName;
}

@end
