// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "SectionedDocumentViewController.h"
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
    [self createTabControllerForTabType:TabTypeSettings tabControllers:tabControllers];
    self.viewControllers = tabControllers;
    return;
  }

  [self createTabControllerForTabType:TabTypePlay tabControllers:tabControllers];
  [self createTabControllerForTabType:TabTypeSettings tabControllers:tabControllers];
  [self createTabControllerForTabType:TabTypeArchive tabControllers:tabControllers];
  [self createTabControllerForTabType:TabTypeHelp tabControllers:tabControllers];
  [self createTabControllerForTabType:TabTypeDiagnostics tabControllers:tabControllers];
  [self createTabControllerForTabType:TabTypeAbout tabControllers:tabControllers];
  [self createTabControllerForTabType:TabTypeSourceCode tabControllers:tabControllers];
  [self createTabControllerForTabType:TabTypeLicenses tabControllers:tabControllers];
  [self createTabControllerForTabType:TabTypeCredits tabControllers:tabControllers];

  // View controllers on the Play tab create their own navigation bar
  UINavigationController* playTabRootViewController = [tabControllers firstObject];
  [playTabRootViewController setNavigationBarHidden:YES animated:NO];

  self.viewControllers = tabControllers;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupTabControllers.
// -----------------------------------------------------------------------------
- (void) createTabControllerForTabType:(enum TabType)tabType
                        tabControllers:(NSMutableArray*)tabControllers
{
  NSString* titleString = [self titleStringForTabType:tabType];
  UIViewController* rootViewController = [self rootViewControllerForTabType:tabType];
  NSString* iconResourceName = [self iconResourceNameForTabType:tabType];

  rootViewController.title = titleString;
  UINavigationController* tabRootViewController = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
  tabRootViewController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:titleString image:[UIImage imageNamed:iconResourceName] tag:tabType] autorelease];
  if ([rootViewController respondsToSelector:@selector(setContextTabBarItem:)])
      [rootViewController performSelector:@selector(setContextTabBarItem:) withObject:tabRootViewController.tabBarItem afterDelay:0];
  [tabControllers addObject:tabRootViewController];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createTabControllerForTabType:tabControllers:.
// -----------------------------------------------------------------------------
- (NSString*) titleStringForTabType:(enum TabType)tabType
{
  if (self.launchImageMode)
    return @"";

  switch (tabType)
  {
    case TabTypePlay:
      return @"Play";
    case TabTypeSettings:
      return @"Settings";
    case TabTypeArchive:
      return @"Archive";
    case TabTypeDiagnostics:
      return @"Diagnostics";
    case TabTypeHelp:
      return @"Help";
    case TabTypeAbout:
      return @"About";
    case TabTypeSourceCode:
      return @"Source Code";
    case TabTypeLicenses:
      return @"Licenses";
    case TabTypeCredits:
      return @"Credits";
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createTabControllerForTabType:tabControllers:.
// -----------------------------------------------------------------------------
- (UIViewController*) rootViewControllerForTabType:(enum TabType)tabType
{
  if (self.launchImageMode)
  {
    UIViewController* rootViewController = [[[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    return rootViewController;
  }

  switch (tabType)
  {
    case TabTypePlay:
      return [PlayTabController playTabController];
    case TabTypeSettings:
      return [SettingsViewController controller];
    case TabTypeArchive:
      return [[[ArchiveViewController alloc] init] autorelease];
    case TabTypeDiagnostics:
      return [DiagnosticsViewController controller];
    case TabTypeHelp:
      return [[[SectionedDocumentViewController alloc] init] autorelease];
    case TabTypeAbout:
      return [[[DocumentViewController alloc] init] autorelease];
    case TabTypeSourceCode:
      return [[[DocumentViewController alloc] init] autorelease];
    case TabTypeLicenses:
      return [[[LicensesViewController alloc] init] autorelease];
    case TabTypeCredits:
      return [[[DocumentViewController alloc] init] autorelease];
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createTabControllerForTabType:tabControllers:.
// -----------------------------------------------------------------------------
- (NSString*) iconResourceNameForTabType:(enum TabType)tabType
{
  if (self.launchImageMode)
    return @"";

  switch (tabType)
  {
    case TabTypePlay:
      return playTabIconResource;
    case TabTypeSettings:
      return settingsTabIconResource;
    case TabTypeArchive:
      return archiveTabIconResource;
    case TabTypeDiagnostics:
      return diagnosticsTabIconResource;
    case TabTypeHelp:
      return helpTabIconResource;
    case TabTypeAbout:
      return aboutTabIconResource;
    case TabTypeSourceCode:
      return sourceCodeTabIconResource;
    case TabTypeLicenses:
      return licensesTabIconResource;
    case TabTypeCredits:
      return creditsTabIconResource;
    default:
      return nil;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  if ([LayoutManager sharedManager].uiType == UITypePhonePortraitOnly)
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
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) tabs.
  applicationDelegate.uiSettingsModel.selectedTabIndex = (int)self.selectedIndex;
  [applicationDelegate writeUserDefaults];
}

@end
