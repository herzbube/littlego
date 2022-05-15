// -----------------------------------------------------------------------------
// Copyright 2015-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "MainUtility.h"
#import "ApplicationDelegate.h"
#import "DocumentViewController.h"
#import "LicensesViewController.h"
#import "MainTabBarController.h"
#import "SectionedDocumentViewController.h"
#import "UIAreaInfo.h"
#import "../archive/ArchiveViewController.h"
#import "../diagnostics/DiagnosticsViewController.h"
#import "../play/rootview/PlayRootViewController.h"
#import "../settings/SettingsViewController.h"
#import "../ui/UiSettingsModel.h"


@implementation MainUtility

// -----------------------------------------------------------------------------
/// @brief Returns a title string that is appropriate for labelling the
/// specified UI area.
// -----------------------------------------------------------------------------
+ (NSString*) titleStringForUIArea:(enum UIArea)uiArea
{
  switch (uiArea)
  {
    case UIAreaPlay:
      return @"Play";
    case UIAreaSettings:
      return @"Settings";
    case UIAreaArchive:
      return @"Archive";
    case UIAreaDiagnostics:
      return @"Diagnostics";
    case UIAreaHelp:
      return @"Help";
    case UIAreaAbout:
      return @"About";
    case UIAreaSourceCode:
      return @"Source Code";
    case UIAreaLicenses:
      return @"Licenses";
    case UIAreaCredits:
      return @"Credits";
    case UIAreaChangelog:
      return @"Changelog";
    case UIAreaNavigation:
      return @"Main Menu";
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the name of a resource that can be used to create an icon
/// image that is appropriate for the specified UI area.
// -----------------------------------------------------------------------------
+ (NSString*) iconResourceNameForUIArea:(enum UIArea)uiArea
{
  switch (uiArea)
  {
    case UIAreaPlay:
      return uiAreaPlayIconResource;
    case UIAreaSettings:
      return uiAreaSettingsIconResource;
    case UIAreaArchive:
      return uiAreaArchiveIconResource;
    case UIAreaDiagnostics:
      return uiAreaDiagnosticsIconResource;
    case UIAreaHelp:
      return uiAreaHelpIconResource;
    case UIAreaAbout:
      return uiAreaAboutIconResource;
    case UIAreaSourceCode:
      return uiAreaSourceCodeIconResource;
    case UIAreaLicenses:
      return uiAreaLicensesIconResource;
    case UIAreaCredits:
      return uiAreaCreditsIconResource;
    case UIAreaChangelog:
      return uiAreaChangelogIconResource;
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a new instance of the root view controller that manages the
/// view hierarchy for the specified UI area.
// -----------------------------------------------------------------------------
+ (UIViewController*) rootViewControllerForUIArea:(enum UIArea)uiArea
{
  UIViewController* rootViewController;
  switch (uiArea)
  {
    case UIAreaPlay:
      rootViewController = [PlayRootViewController playRootViewController];
      break;
    case UIAreaSettings:
      rootViewController = [SettingsViewController controller];
      break;
    case UIAreaArchive:
      rootViewController = [[[ArchiveViewController alloc] init] autorelease];
      break;
    case UIAreaDiagnostics:
      rootViewController = [DiagnosticsViewController controller];
      break;
    case UIAreaHelp:
      rootViewController = [[[SectionedDocumentViewController alloc] init] autorelease];
      break;
    case UIAreaAbout:
      rootViewController = [[[DocumentViewController alloc] init] autorelease];
      break;
    case UIAreaSourceCode:
      rootViewController = [[[DocumentViewController alloc] init] autorelease];
      break;
    case UIAreaLicenses:
      rootViewController = [[[LicensesViewController alloc] init] autorelease];
      break;
    case UIAreaCredits:
      rootViewController = [[[DocumentViewController alloc] init] autorelease];
      break;
    case UIAreaChangelog:
      rootViewController = [[[SectionedDocumentViewController alloc] init] autorelease];
      break;
    default:
      return nil;
  }
  rootViewController.title = [MainUtility titleStringForUIArea:uiArea];
  rootViewController.uiArea = uiArea;
  return rootViewController;
}

// -----------------------------------------------------------------------------
/// @brief Returns the root view of the view hierarchy that makes up
/// #UIAreaPlay.
// -----------------------------------------------------------------------------
+ (UIView*) rootViewForUIAreaPlay
{
  UIViewController* windowRootViewController = [ApplicationDelegate sharedDelegate].windowRootViewController;
  MainTabBarController* tabBarController = (MainTabBarController*)windowRootViewController;
  return [tabBarController tabViewForUIArea:UIAreaPlay];
}

// -----------------------------------------------------------------------------
/// @brief Maps the @a uiArea value to a resource file name and returns that
/// file name. The file name can be used with NSBundle to load the resource
/// file's content.
// -----------------------------------------------------------------------------
+ (NSString*) resourceNameForUIArea:(enum UIArea)uiArea
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
    case UIAreaChangelog:
      resourceName = changelogDocumentResource;
      break;
    default:
      break;
  }
  return resourceName;
}

// -----------------------------------------------------------------------------
/// @brief Activates the UI area @a uiArea, making it visible to the user.
// -----------------------------------------------------------------------------
+ (void) activateUIArea:(enum UIArea)uiArea
{
  UIViewController* windowRootViewController = [ApplicationDelegate sharedDelegate].windowRootViewController;
  MainTabBarController* tabBarController = (MainTabBarController*)windowRootViewController;
  [tabBarController activateTabForUIArea:uiArea];
}

// -----------------------------------------------------------------------------
/// @brief Synchronizes user defaults in response to a different UI area being
/// displayed by the main application view controller.
// -----------------------------------------------------------------------------
+ (void) mainApplicationViewController:(UIViewController*)viewController didDisplayUIArea:(enum UIArea)uiArea
{
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  UiSettingsModel* uiSettingsModel = applicationDelegate.uiSettingsModel;
  uiSettingsModel.visibleUIArea = uiArea;
  [applicationDelegate writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Returns the owner of the application's magnifying glass
/// functionality.
///
/// If we ever decide to change the owner we only have to modify this method,
/// client's won't be affected.
// -----------------------------------------------------------------------------
+ (id<MagnifyingGlassOwner>) magnifyingGlassOwner
{
  return [ApplicationDelegate sharedDelegate].windowRootViewController;
}

@end
