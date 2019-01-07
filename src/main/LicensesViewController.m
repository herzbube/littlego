// -----------------------------------------------------------------------------
// Copyright 2011-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "LicensesViewController.h"
#import "DocumentViewController.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Licenses" table view.
// -----------------------------------------------------------------------------
enum LicensesTableViewSection
{
  LicensesSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the LicensesSection.
// -----------------------------------------------------------------------------
enum LicensesSectionItem
{
  ApacheLicenseItem,
  GPLItem,
  LGPLItem,
  BoostLicenseItem,
  MBProgressHUDLicenseItem,
  LumberjackLicenseItem,
  ZipKitLicenseItem,
  CrashlyticsLicenseItem,
  FirebaseLicenseItem,
  MaxLicensesSectionItem
};


@implementation LicensesViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LicensesViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return MaxLicensesSectionItem;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  cell.textLabel.text = [self licenseTitleForRow:indexPath.row];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  [self viewLicenseForRow:indexPath.row];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Displays DocumentViewController with the content of the section at
/// index position @a sectionIndex.
// -----------------------------------------------------------------------------
- (void) viewLicenseForRow:(NSInteger)row
{
  NSString* licenseTitle = [self licenseTitleForRow:row];
  NSString* licenseResourceName = [self licenseResourceNameForRow:row];
  DocumentViewController* controller = [DocumentViewController controllerWithTitle:licenseTitle
                                                                      resourceName:licenseResourceName];
  [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a title string that describes the license displayed in table
/// view row @a row.
// -----------------------------------------------------------------------------
- (NSString*) licenseTitleForRow:(NSInteger)row
{
  switch (row)
  {
    case ApacheLicenseItem:
    {
      return @"Apache License";
      break;
    }
    case GPLItem:
    {
      return @"GPL";
      break;
    }
    case LGPLItem:
    {
      return @"LGPL";
      break;
    }
    case BoostLicenseItem:
    {
      return @"Boost License";
      break;
    }
    case MBProgressHUDLicenseItem:
    {
      return @"MBProgressHUD License";
      break;
    }
    case LumberjackLicenseItem:
    {
      return @"Cocoa Lumberjack License";
      break;
    }
    case ZipKitLicenseItem:
    {
      return @"ZipKit License";
      break;
    }
    case CrashlyticsLicenseItem:
    {
      return @"Licenses for software used by Crashlytics";
      break;
    }
    case FirebaseLicenseItem:
    {
      return @"Licenses for software used by Firebase";
    }
    default:
    {
      assert(0);
      break;
    }
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns a title string that describes the license displayed in table
/// view row @a row.
// -----------------------------------------------------------------------------
- (NSString*) licenseResourceNameForRow:(NSInteger)row
{
  switch (row)
  {
    case ApacheLicenseItem:
    {
      return apacheLicenseDocumentResource;
      break;
    }
    case GPLItem:
    {
      return GPLDocumentResource;
      break;
    }
    case LGPLItem:
    {
      return LGPLDocumentResource;
      break;
    }
    case BoostLicenseItem:
    {
      return boostLicenseDocumentResource;
      break;
    }
    case MBProgressHUDLicenseItem:
    {
      return MBProgressHUDLicenseDocumentResource;
      break;
    }
    case LumberjackLicenseItem:
    {
      return lumberjackLicenseDocumentResource;
      break;
    }
    case ZipKitLicenseItem:
    {
      return zipkitLicenseDocumentResource;
      break;
    }
    case CrashlyticsLicenseItem:
    {
      return crashlyticsLicenseDocumentResource;
      break;
    }
    case FirebaseLicenseItem:
    {
      return firebaseLicenseDocumentResource;
    }
    default:
    {
      assert(0);
      break;
    }
  }
  return nil;
}

@end
