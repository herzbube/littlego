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
#import "../archive/ArchiveViewController.h"
#import "../diagnostics/DiagnosticsViewController.h"
#import "../play/playtab/PlayTabController.h"
#import "../settings/SettingsViewController.h"


@implementation MainUtilty

// -----------------------------------------------------------------------------
/// @brief Returns a title string that is appropriate for labelling the
/// specified tab type.
// -----------------------------------------------------------------------------
+ (NSString*) titleStringForTabType:(enum TabType)tabType
{
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
/// @brief Returns the name of a resource that can be used to create an icon
/// image that is appropriate for the specified tab type.
// -----------------------------------------------------------------------------
+ (NSString*) iconResourceNameForTabType:(enum TabType)tabType
{
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

// -----------------------------------------------------------------------------
/// @brief Returns a new instance of the root view controller that manages the
/// view hierarchy for the specified tab type.
// -----------------------------------------------------------------------------
+ (UIViewController*) rootViewControllerForTabType:(enum TabType)tabType
{
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

@end
