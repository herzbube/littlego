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
#import "../ui/UiSettingsModel.h"
#import "../ui/UiUtilities.h"


@implementation MainTabBarController

// -----------------------------------------------------------------------------
/// @brief Initializes a MainTabBarController.
///
/// @note This is the designated initializer of MainTabBarController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UITabBarController)
  self = [super init];
  if (! self)
    return nil;
  self.delegate = self;
  self.moreNavigationController.delegate = self;
  return self;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief This implementation exists so that in iOS 6 the app can rotate to
/// UIInterfaceOrientationPortraitUpsideDown on the iPhone.
// -----------------------------------------------------------------------------
- (NSUInteger) supportedInterfaceOrientations
{
  return [UiUtilities supportedInterfaceOrientations];
}

#pragma mark - UITabBarControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief Synchronizes user defaults in response to the user switching tabs.
/// Also writes the index of the selected tab controller to the user defaults.
// -----------------------------------------------------------------------------
- (void) tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController
{
  [self tabControllerSelectionDidChange];
}

// -----------------------------------------------------------------------------
/// @brief Writes changed tab order to user defaults (without synchronizing).
// -----------------------------------------------------------------------------
- (void) tabBarController:(UITabBarController*)tabBarController didEndCustomizingViewControllers:(NSArray*)viewControllers changed:(BOOL)changed
{
  if (! changed)
    return;
  NSArray* tabOrder = [[tabBarController.viewControllers valueForKey:@"tabBarItem"] valueForKey:@"tag"];
  [ApplicationDelegate sharedDelegate].uiSettingsModel.tabOrder = tabOrder;
}

#pragma mark - UINavigationControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief Synchronizes user defaults in response to the user switching views
/// on the tab bar controller's more navigation controller. Also writes the
/// index of the selected tab controller to the user defaults.
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController didShowViewController:(UIViewController*)viewController animated:(BOOL)animated
{
  [self tabControllerSelectionDidChange];
}

#pragma mark - MainTabBarController methods

// -----------------------------------------------------------------------------
/// @brief Restores the tab bar controller's appearance to the values stored in
/// the user defaults.
///
/// This method is intended to be invoked during application launch. It should
/// be invoked before the tab bar controller's view appears, otherwise the user
/// will be able to see the appearance change.
// -----------------------------------------------------------------------------
- (void) restoreTabBarControllerAppearanceToUserDefaults
{
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  NSArray* tabOrder = applicationDelegate.uiSettingsModel.tabOrder;
  int tabOrderCount = tabOrder.count;
  if (tabOrderCount == self.viewControllers.count)
  {
    NSMutableArray* tabControllers = [NSMutableArray array];
    for (int tabOrderIndex = 0; tabOrderIndex < tabOrderCount; ++tabOrderIndex)
    {
      enum TabType tabID = [[tabOrder objectAtIndex:tabOrderIndex] intValue];
      UIViewController* tabController = [self tabController:tabID];
      [tabControllers addObject:tabController];
    }
    if (! [self.viewControllers isEqualToArray:tabControllers])
    {
      self.viewControllers = tabControllers;
    }
  }

  int selectedTabIndex = applicationDelegate.uiSettingsModel.selectedTabIndex;
  if (indexOfMoreNavigationController == selectedTabIndex)
    self.selectedViewController = self.moreNavigationController;
  else
    self.selectedIndex = selectedTabIndex;
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
    [self tabControllerSelectionDidChange];
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
    case TabTypeHelp:
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

// -----------------------------------------------------------------------------
/// @brief Synchronizes user defaults in response to a different tab controller
/// being selected (either by the user, or programmatically). Also writes the
/// index of the selected tab controller to the user defaults.
// -----------------------------------------------------------------------------
- (void) tabControllerSelectionDidChange
{
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  applicationDelegate.uiSettingsModel.selectedTabIndex = self.selectedIndex;
  [applicationDelegate writeUserDefaults];
}

@end
