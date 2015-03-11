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
#import "MainTabBarController.h"
#import "ApplicationDelegate.h"
#import "DocumentViewController.h"
#import "LicensesViewController.h"
#import "MainUtility.h"
#import "SectionedDocumentViewController.h"
#import "UIAreaInfo.h"
#import "../archive/ArchiveViewController.h"
#import "../diagnostics/DiagnosticsViewController.h"
#import "../play/playtab/PlayTabController.h"
#import "../shared/LayoutManager.h"
#import "../settings/SettingsViewController.h"
#import "../ui/UIElementMetrics.h"
#import "../ui/UiSettingsModel.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MainTabBarController.
// -----------------------------------------------------------------------------
@interface MainTabBarController()
/// @brief Set this to true to create a fake UI that can be used to take
/// screenshots that serve as the basis for launch images.
@property(nonatomic, assign) bool launchImageMode;
@end


@implementation MainTabBarController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a MainTabBarController.
///
/// @note This is the designated initializer of MainTabBarController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UITabBarController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.delegate = self;
  self.moreNavigationController.delegate = self;
  self.moreNavigationController.uiArea = UIAreaNavigation;
  self.launchImageMode = false;
  [self setupTabControllers];
  [self restoreTabBarControllerAppearanceToUserDefaults];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupTabControllers
{
  NSMutableArray* tabControllers = [NSMutableArray array];

  if (self.launchImageMode)
  {
    [self createTabControllerForUIArea:UIAreaSettings tabControllers:tabControllers];
    self.viewControllers = tabControllers;
    return;
  }

  [self createTabControllerForUIArea:UIAreaPlay tabControllers:tabControllers];
  [self createTabControllerForUIArea:UIAreaSettings tabControllers:tabControllers];
  [self createTabControllerForUIArea:UIAreaArchive tabControllers:tabControllers];
  [self createTabControllerForUIArea:UIAreaHelp tabControllers:tabControllers];
  [self createTabControllerForUIArea:UIAreaDiagnostics tabControllers:tabControllers];
  [self createTabControllerForUIArea:UIAreaAbout tabControllers:tabControllers];
  [self createTabControllerForUIArea:UIAreaSourceCode tabControllers:tabControllers];
  [self createTabControllerForUIArea:UIAreaLicenses tabControllers:tabControllers];
  [self createTabControllerForUIArea:UIAreaCredits tabControllers:tabControllers];

  self.viewControllers = tabControllers;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupTabControllers.
// -----------------------------------------------------------------------------
- (void) createTabControllerForUIArea:(enum UIArea)uiArea
                        tabControllers:(NSMutableArray*)tabControllers
{
  UIViewController* rootViewController = [self rootViewControllerForUIArea:uiArea];
  NSString* iconResourceName = [self iconResourceNameForUIArea:uiArea];

  UINavigationController* tabRootViewController = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
  tabRootViewController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:rootViewController.title
                                                                    image:[UIImage imageNamed:iconResourceName]
                                                                      tag:0] autorelease];
  tabRootViewController.uiArea = uiArea;
  [tabControllers addObject:tabRootViewController];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createTabControllerForUIArea:tabControllers:.
// -----------------------------------------------------------------------------
- (NSString*) titleStringForUIArea:(enum UIArea)uiArea
{
  if (self.launchImageMode)
    return @"";
  else
    return [MainUtilty titleStringForUIArea:uiArea];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createTabControllerForUIArea:tabControllers:.
// -----------------------------------------------------------------------------
- (UIViewController*) rootViewControllerForUIArea:(enum UIArea)uiArea
{
  if (self.launchImageMode)
  {
    UIViewController* rootViewController = [[[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    return rootViewController;
  }
  else
  {
    return [MainUtilty rootViewControllerForUIArea:uiArea];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createTabControllerForUIArea:tabControllers:.
// -----------------------------------------------------------------------------
- (NSString*) iconResourceNameForUIArea:(enum UIArea)uiArea
{
  if (self.launchImageMode)
    return @"";
  else
    return [MainUtilty iconResourceNameForUIArea:uiArea];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  if ([LayoutManager sharedManager].uiType != UITypePad)
  {
    // The default bar is translucent, so we see the white background. On the
    // iPhone this does not look good because we have a toolbar stacked on top
    // of the tab bar.
    self.tabBar.barTintColor = [UIColor blackColor];
    // The default tint color is a rather dark/intense blue which does not look
    // good on a black background. The color we select here is slightly lighter
    // and not as intensely blue as the default.
    self.tabBar.tintColor = [UIColor bleuDeFranceColor];
  }

  // TODO xxx We should not fake this color, we should somehow get a real
  // navigation bar to place itself behind the statusbar.
  self.view.backgroundColor = [UIColor navigationbarBackgroundColor];
}

#pragma mark - UITabBarControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief Synchronizes user defaults in response to the user switching tabs.
/// Also writes the visible UI area to the user defaults.
// -----------------------------------------------------------------------------
- (void) tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController
{
  enum UIArea uiArea = viewController.uiArea;
  if (uiArea != UIAreaUnknown)
    [self tabControllerSelectionDidChangeToUIArea:uiArea];
}

// -----------------------------------------------------------------------------
/// @brief Writes changed tab order to user defaults (without synchronizing).
// -----------------------------------------------------------------------------
- (void) tabBarController:(UITabBarController*)tabBarController didEndCustomizingViewControllers:(NSArray*)viewControllers changed:(BOOL)changed
{
  if (! changed)
    return;
  NSArray* tabOrder = [tabBarController.viewControllers valueForKey:@"uiArea"];
  [ApplicationDelegate sharedDelegate].uiSettingsModel.tabOrder = tabOrder;
}

#pragma mark - UINavigationControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief Synchronizes user defaults in response to the user switching views
/// on the tab bar controller's more navigation controller. Also writes the
/// visible UI area to the user defaults.
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController
        didShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
  // Only react to the view controller change if the user is navigating to one
  // of the main controllers managed by this tab bar controller, or to the
  // more navigation controller. We are not interested if the user is navigating
  // around *BELOW* one of the main controllers. When we check the size of the
  // more navigation controller's stack we must include the controller at the
  // bottom of the stack which is the more navigation controller's internal
  // table view controller listing the navigatable children.
  //
  // Caveat of this approach: We can't detect (at least not without considerable
  // effort) the direction of the navigation, i.e. whether the user goes forward
  // from the more navigation controller, or backward from one of the
  // subcontrollers. We are interested only in the former because only that
  // constitutes a "tab change".
  NSUInteger navigationStackSize = self.moreNavigationController.viewControllers.count;
  switch (navigationStackSize)
  {
    case 1:
    {
      // The more navigation controller's internal table view controller. We
      // can't use self.selectedViewController, this does not return the more
      // navigation controller.
      [self tabControllerSelectionDidChangeToUIArea:UIAreaNavigation];
      break;
    }
    case 2:
    {
      enum UIArea uiArea = viewController.uiArea;
      if (uiArea != UIAreaUnknown)
        [self tabControllerSelectionDidChangeToUIArea:uiArea];
      break;
    }
    default:
    {
      // Some subcontroller that we are not interested in
      break;
    }
  }
}

#pragma mark - MainTabBarController methods

// -----------------------------------------------------------------------------
/// @brief Restores the tab bar controller's appearance to the values stored in
/// the user defaults.
///
/// This method should be invoked before the tab bar controller's view appears,
/// otherwise the user will be able to see the appearance change.
// -----------------------------------------------------------------------------
- (void) restoreTabBarControllerAppearanceToUserDefaults
{
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  NSArray* tabOrder = applicationDelegate.uiSettingsModel.tabOrder;
  NSUInteger tabOrderCount = tabOrder.count;
  if (tabOrderCount == self.viewControllers.count)
  {
    NSMutableArray* tabControllers = [NSMutableArray array];
    for (int tabOrderIndex = 0; tabOrderIndex < tabOrderCount; ++tabOrderIndex)
    {
      enum UIArea uiArea = [[tabOrder objectAtIndex:tabOrderIndex] intValue];
      UIViewController* tabController = [self tabControllerForUIArea:uiArea];
      [tabControllers addObject:tabController];
    }
    if (! [self.viewControllers isEqualToArray:tabControllers])
    {
      self.viewControllers = tabControllers;
    }
  }
  [self activateTabForUIArea:applicationDelegate.uiSettingsModel.visibleUIArea];
}

// -----------------------------------------------------------------------------
/// @brief Returns the root controller for the tab identified by @a uiArea.
/// Returns nil if @a uiArea is not recognized.
///
/// This method returns the correct controller even if the tab is located in
/// the "More" navigation controller.
// -----------------------------------------------------------------------------
- (UIViewController*) tabControllerForUIArea:(enum UIArea)uiArea
{
  if (UIAreaNavigation == uiArea)
    return self.moreNavigationController;
  for (UIViewController* controller in self.viewControllers)
  {
    if (controller.uiArea == uiArea)
      return controller;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the main view for the tab identified by @a uiArea. Returns
/// nil if @a uiArea is not recognized.
///
/// This method returns the correct view even if the tab is located in the
/// "More" navigation controller.
// -----------------------------------------------------------------------------
- (UIView*) tabViewForUIArea:(enum UIArea)uiArea
{
  UIViewController* tabController = [self tabControllerForUIArea:uiArea];
  if (tabController)
    return tabController.view;
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Activates the tab identified by @a uiArea, making it visible to the
/// user.
///
/// This method works correctly even if the tab is located in the "More"
/// navigation controller.
// -----------------------------------------------------------------------------
- (void) activateTabForUIArea:(enum UIArea)uiArea
{
  UIViewController* tabController = [self tabControllerForUIArea:uiArea];
  if (tabController)
  {
    self.selectedViewController = tabController;
    // The delegate method tabBarController:didSelectViewController:() is not
    // invoked when the selectedViewController property is changed
    // programmatically
    [self tabControllerSelectionDidChangeToUIArea:uiArea];
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps UIArea values to resource file names. The name that is returned
/// can be used with NSBundle to load the resource file's content.
// -----------------------------------------------------------------------------
- (NSString*) resourceNameForUIArea:(enum UIArea)uiArea
{
  NSString* resourceName = nil;
  switch (uiArea)
  {
    case UIAreaHelp:
      resourceName = manualDocumentResource;
      break;
    case UIAreaAbout:
      resourceName = aboutDocumentResource;
      break;
    case UIAreaSourceCode:
      resourceName = sourceCodeDocumentResource;
      break;
    case UIAreaCredits:
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
- (void) tabControllerSelectionDidChangeToUIArea:(enum UIArea)uiArea
{
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  UiSettingsModel* uiSettingsModel = applicationDelegate.uiSettingsModel;
  uiSettingsModel.visibleUIArea = uiArea;
  [applicationDelegate writeUserDefaults];
}

@end
