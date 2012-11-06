// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "ApplicationDelegate.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


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
  QuincyKitLicenseItem,
  PLCrashReporterLicenseItem,
  ProtobufCLicenseItem,
  MaxLicensesSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for LicensesViewController.
// -----------------------------------------------------------------------------
@interface LicensesViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Private helpers
//@{
- (void) viewLicenseForRow:(int)row;
- (NSString*) licenseTitleForRow:(int)row;
- (NSString*) licenseResourceNameForRow:(int)row;
//@}
@end


@implementation LicensesViewController


// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LicensesViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

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

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  [self viewLicenseForRow:indexPath.row];
}

// -----------------------------------------------------------------------------
/// @brief Displays DocumentViewController with the content of the section at
/// index position @a sectionIndex.
// -----------------------------------------------------------------------------
- (void) viewLicenseForRow:(int)row
{
  NSString* licenseTitle = [self licenseTitleForRow:row];
  NSString* licenseResourceName = [self licenseResourceNameForRow:row];
  DocumentViewController* controller = [DocumentViewController controllerWithTitle:licenseTitle
                                                                      resourceName:licenseResourceName];
  [self.navigationController pushViewController:controller animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Returns a title string that describes the license displayed in table
/// view row @a row.
// -----------------------------------------------------------------------------
- (NSString*) licenseTitleForRow:(int)row
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
    case QuincyKitLicenseItem:
    {
      return @"QuincyKit License";
      break;
    }
    case PLCrashReporterLicenseItem:
    {
      return @"PLCrashReporter License";
      break;
    }
    case ProtobufCLicenseItem:
    {
      return @"protobuf-c License";
      break;
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
- (NSString*) licenseResourceNameForRow:(int)row
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
    case QuincyKitLicenseItem:
    {
      return quincykitLicenseDocumentResource;
      break;
    }
    case PLCrashReporterLicenseItem:
    {
      return plcrashreporterLicenseDocumentResource;
      break;
    }
    case ProtobufCLicenseItem:
    {
      return protobufcLicenseDocumentResource;
      break;
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
