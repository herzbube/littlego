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
#import "MainTableViewController.h"
#import "MainUtility.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
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

  enum TabType tabType = [self tabTypeForTableRow:indexPath.row];
  cell.imageView.image = [self cellImageForTableType:tabType];
  cell.textLabel.text = [MainUtilty titleStringForTabType:tabType];
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
  enum TabType tabType = [self tabTypeForTableRow:indexPath.row];
  UIViewController* rootViewController = [MainUtilty rootViewControllerForTabType:tabType];
  [self.navigationController pushViewController:rootViewController animated:YES];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a value from the TabType enumeration that matches
/// @a tableRow.
// -----------------------------------------------------------------------------
- (enum TabType) tabTypeForTableRow:(NSInteger)tableRow
{
  switch (tableRow)
  {
    case MainTableViewItemSettings:
      return TabTypeSettings;
    case MainTableViewItemArchive:
      return TabTypeArchive;
    case MainTableViewItemDiagnostics:
      return TabTypeDiagnostics;
    case MainTableViewItemHelp:
      return TabTypeHelp;
    case MainTableViewItemAbout:
      return TabTypeAbout;
    case MainTableViewItemSourceCode:
      return TabTypeSourceCode;
    case MainTableViewItemLicenses:
      return TabTypeLicenses;
    case MainTableViewItemCredits:
      return TabTypeCredits;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid table row %ld", tableRow];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an image that represents @a tabType.
// -----------------------------------------------------------------------------
- (UIImage*) cellImageForTableType:(enum TabType)tabType
{
  NSString* iconResourceName = [MainUtilty iconResourceNameForTabType:tabType];
  UIImage* image = [UIImage imageNamed:iconResourceName];
  // The original icons are differently sized. For a clean display in the table
  // view we must convert them all to the same uniform size. We use the maximum
  // height of a table view cell as the measure.
  CGSize targetSize = CGSizeMake([UiElementMetrics tableViewCellContentViewHeight], [UiElementMetrics tableViewCellContentViewHeight]);
  return [UIImage paddedImageWithSize:targetSize originalImage:image];
}

@end
