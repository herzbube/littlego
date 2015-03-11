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
#import "MainUtility.h"
#import "DocumentViewController.h"
#import "LicensesViewController.h"
#import "SectionedDocumentViewController.h"
#import "UIAreaInfo.h"
#import "../archive/ArchiveViewController.h"
#import "../diagnostics/DiagnosticsViewController.h"
#import "../play/playtab/PlayTabController.h"
#import "../settings/SettingsViewController.h"


@implementation MainUtilty

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
      return playTabIconResource;
    case UIAreaSettings:
      return settingsTabIconResource;
    case UIAreaArchive:
      return archiveTabIconResource;
    case UIAreaDiagnostics:
      return diagnosticsTabIconResource;
    case UIAreaHelp:
      return helpTabIconResource;
    case UIAreaAbout:
      return aboutTabIconResource;
    case UIAreaSourceCode:
      return sourceCodeTabIconResource;
    case UIAreaLicenses:
      return licensesTabIconResource;
    case UIAreaCredits:
      return creditsTabIconResource;
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
      rootViewController = [PlayTabController playTabController];
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
    default:
      return nil;
  }
  rootViewController.title = [MainUtilty titleStringForUIArea:uiArea];
  rootViewController.uiArea = uiArea;
  return rootViewController;
}

@end
