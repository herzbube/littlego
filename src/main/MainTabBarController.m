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
#import "../settings/SettingsViewController.h"
#import "../ui/UIElementMetrics.h"
#import "../ui/UiSettingsModel.h"
#import "../ui/UiUtilities.h"
#import "../utility/UIColorAdditions.h"


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
  [self setupTabControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupGui.
// -----------------------------------------------------------------------------
- (void) setupTabControllers
{
  NSMutableArray* tabControllers = [NSMutableArray array];

  NSString* playTitleString = @"Play";
  UIViewController* rootControllerPlayTab = [PlayTabController playTabController];
  UINavigationController* playTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerPlayTab] autorelease];
  [playTabController setNavigationBarHidden:YES animated:NO];
  playTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:playTitleString image:[UIImage imageNamed:playTabIconResource] tag:TabTypePlay] autorelease];
  [tabControllers addObject:playTabController];

  NSString* settingsTitleString = @"Settings";
  SettingsViewController* rootControllerSettingsTab = [SettingsViewController controller];
  rootControllerSettingsTab.title = settingsTitleString;
  UINavigationController* settingsTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerSettingsTab] autorelease];
  settingsTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:settingsTitleString image:[UIImage imageNamed:settingsTabIconResource] tag:TabTypeSettings] autorelease];
  [tabControllers addObject:settingsTabController];

  NSString* archiveTitleString = @"Archive";
  ArchiveViewController* rootControllerArchiveTab = [[[ArchiveViewController alloc] init] autorelease];
  rootControllerArchiveTab.title = archiveTitleString;
  UINavigationController* archiveTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerArchiveTab] autorelease];
  archiveTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:archiveTitleString image:[UIImage imageNamed:archiveTabIconResource] tag:TabTypeArchive] autorelease];
  [tabControllers addObject:archiveTabController];

  NSString* helpTitleString = @"Help";
  SectionedDocumentViewController* rootControllerHelpTab = [[[SectionedDocumentViewController alloc] init] autorelease];
  rootControllerHelpTab.title = helpTitleString;
  UINavigationController* helpTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerHelpTab] autorelease];
  helpTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:helpTitleString image:[UIImage imageNamed:helpTabIconResource] tag:TabTypeHelp] autorelease];
  rootControllerHelpTab.contextTabBarItem = helpTabController.tabBarItem;
  [tabControllers addObject:helpTabController];

  NSString* diagnosticsTitleString = @"Diagnostics";
  DiagnosticsViewController* rootControllerDiagnosticsTab = [DiagnosticsViewController controller];
  rootControllerDiagnosticsTab.title = diagnosticsTitleString;
  UINavigationController* diagnosticsTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerDiagnosticsTab] autorelease];
  diagnosticsTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:diagnosticsTitleString image:[UIImage imageNamed:diagnosticsTabIconResource] tag:TabTypeDiagnostics] autorelease];
  [tabControllers addObject:diagnosticsTabController];

  NSString* aboutTitleString = @"About";
  DocumentViewController* rootControllerAboutTab = [[[DocumentViewController alloc] init] autorelease];
  rootControllerAboutTab.title = aboutTitleString;
  UINavigationController* aboutTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerAboutTab] autorelease];
  aboutTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:aboutTitleString image:[UIImage imageNamed:aboutTabIconResource] tag:TabTypeAbout] autorelease];
  rootControllerAboutTab.contextTabBarItem = aboutTabController.tabBarItem;
  [tabControllers addObject:aboutTabController];

  NSString* sourceCodeTitleString = @"Source Code";
  DocumentViewController* rootControllerSourceCodeTab = [[[DocumentViewController alloc] init] autorelease];
  rootControllerSourceCodeTab.title = sourceCodeTitleString;
  UINavigationController* sourceCodeTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerSourceCodeTab] autorelease];
  sourceCodeTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:sourceCodeTitleString image:[UIImage imageNamed:sourceCodeTabIconResource] tag:TabTypeSourceCode] autorelease];
  rootControllerSourceCodeTab.contextTabBarItem = sourceCodeTabController.tabBarItem;
  [tabControllers addObject:sourceCodeTabController];

  NSString* licensesTitleString = @"Licenses";
  LicensesViewController* rootControllerLicensesTab = [[[LicensesViewController alloc] init] autorelease];
  rootControllerLicensesTab.title = licensesTitleString;
  UINavigationController* licensesTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerLicensesTab] autorelease];
  licensesTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:licensesTitleString image:[UIImage imageNamed:licensesTabIconResource] tag:TabTypeLicenses] autorelease];
  [tabControllers addObject:licensesTabController];

  NSString* creditsTitleString = @"Credits";
  DocumentViewController* rootControllerCreditsTab = [[[DocumentViewController alloc] init] autorelease];
  rootControllerCreditsTab.title = creditsTitleString;
  UINavigationController* creditsTabController = [[[UINavigationController alloc] initWithRootViewController:rootControllerCreditsTab] autorelease];
  creditsTabController.tabBarItem = [[[UITabBarItem alloc] initWithTitle:creditsTitleString image:[UIImage imageNamed:creditsTabIconResource] tag:TabTypeCredits] autorelease];
  rootControllerCreditsTab.contextTabBarItem = creditsTabController.tabBarItem;
  [tabControllers addObject:creditsTabController];

  self.viewControllers = tabControllers;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
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

  // Place an application-wide black background behind the status bar. Requires
  // that the status bar style is set to UIStatusBarStyleLightContent. This
  // happens in the project's Info.plist, by using the UIStatusBarStyle key. In
  // order for that key to take effect, another key named
  // UIViewControllerBasedStatusBarAppearance must also be set in the
  // Info.plist.
  // Note: This method of making the status bar background black is a bit
  // hack'ish, especially because the background view does not participate in
  // the view layout process (instead it is simply created with a fixed frame
  // that is wide enough for landscape), but I simply cannot be bothered with
  // all the "extended layout" mumbo jumbo that Apple introduced in iOS 7.
  CGRect backgroundViewFrame = CGRectZero;
  backgroundViewFrame.size.width = [UiElementMetrics screenWidthLandscape];
  backgroundViewFrame.size.height = [UiElementMetrics statusBarHeight];
  UIView* backgroundView = [[[UIView alloc] initWithFrame:backgroundViewFrame] autorelease];
  [self.view addSubview:backgroundView];
  backgroundView.backgroundColor = [UIColor blackColor];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (NSUInteger) supportedInterfaceOrientations
{
  // This implementation exists so that the app can rotate to
  // UIInterfaceOrientationPortraitUpsideDown on the iPhone
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
