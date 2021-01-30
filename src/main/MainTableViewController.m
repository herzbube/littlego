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
#import "MainTableViewController.h"
#import "ApplicationDelegate.h"
#import "MainUtility.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiSettingsModel.h"
#import "../utility/UIImageAdditions.h"


/// @brief Enumerates items that appear in the table view managed by this
/// controller
enum MainTableViewItem
{
  MainTableViewItemSettings,
  MainTableViewItemArchive,
  MainTableViewItemDiagnostics,
  MainTableViewItemHelp,
  MainTableViewItemAbout,
  MainTableViewItemSourceCode,
  MainTableViewItemLicenses,
  MainTableViewItemCredits,
  MainTableViewItemChangelog,
  MaxMainTableViewItem
};


@implementation MainTableViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an MainTableViewController object.
///
/// @note This is the designated initializer of MainTableViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStylePlain];
  if (! self)
    return nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MainTableViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (@available(iOS 12.0, *))
  {
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
      [self updateCellImageTint];
  }
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return MaxMainTableViewItem;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];

  enum UIArea uiArea = [self uiAreaForTableRow:indexPath.row];
  cell.imageView.image = [self cellImageForUIArea:uiArea];
  cell.textLabel.text = [MainUtility titleStringForUIArea:uiArea];
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
  enum UIArea uiArea = [self uiAreaForTableRow:indexPath.row];
  [self presentUIArea:uiArea];
}

#pragma mark - MainTableViewController overrides

// -----------------------------------------------------------------------------
/// @brief Presents (i.e. makes visible) the view controller that manages the
/// view hierarchy for the specified UI area.
// -----------------------------------------------------------------------------
- (void) presentUIArea:(enum UIArea)uiArea
{
  UIViewController* rootViewController = [MainUtility rootViewControllerForUIArea:uiArea];
  [self.navigationController pushViewController:rootViewController animated:YES];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a value from the UIArea enumeration that matches
/// @a tableRow.
// -----------------------------------------------------------------------------
- (enum UIArea) uiAreaForTableRow:(NSInteger)tableRow
{
  switch (tableRow)
  {
    case MainTableViewItemSettings:
      return UIAreaSettings;
    case MainTableViewItemArchive:
      return UIAreaArchive;
    case MainTableViewItemDiagnostics:
      return UIAreaDiagnostics;
    case MainTableViewItemHelp:
      return UIAreaHelp;
    case MainTableViewItemAbout:
      return UIAreaAbout;
    case MainTableViewItemSourceCode:
      return UIAreaSourceCode;
    case MainTableViewItemLicenses:
      return UIAreaLicenses;
    case MainTableViewItemCredits:
      return UIAreaCredits;
    case MainTableViewItemChangelog:
      return UIAreaChangelog;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid table row %ld", (long)tableRow];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an image that represents @a uiArea.
// -----------------------------------------------------------------------------
- (UIImage*) cellImageForUIArea:(enum UIArea)uiArea
{
  NSString* iconResourceName = [MainUtility iconResourceNameForUIArea:uiArea];
  UIImage* image = [UIImage imageNamed:iconResourceName];
  // The original icons are differently sized. For a clean display in the table
  // view we must convert them all to the same uniform size. We use the maximum
  // height of a table view cell as the measure.
  CGSize targetSize = CGSizeMake([UiElementMetrics tableViewCellContentViewHeight], [UiElementMetrics tableViewCellContentViewHeight]);
  if (@available(iOS 13.0, *))
    return [UIImage paddedImageWithSize:targetSize tintedFor:self.traitCollection.userInterfaceStyle originalImage:image];
  else
    return [UIImage paddedImageWithSize:targetSize originalImage:image];
}

// -----------------------------------------------------------------------------
/// @brief Updates the tinting of the table view's cell images to match the
/// current UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateCellImageTint
{
  [self.tableView reloadData];
}

@end
