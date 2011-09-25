// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "DebugViewController.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Debug" table view.
// -----------------------------------------------------------------------------
enum DebugTableViewSection
{
  GtpSection,
//  ApplicationLogSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GtpSection.
// -----------------------------------------------------------------------------
enum GtpSectionItem
{
  GtpLogItem,
  GtpClearLogItem,
  GtpCommandsItem,
  GtpSettingsItem,
  MaxGtpSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ApplicationLogSection.
// -----------------------------------------------------------------------------
enum ApplicationLogSectionItem
{
  ApplicationLogItem,
  ApplicationLogSettingsItem,
  MaxApplicationLogSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for DebugViewController.
// -----------------------------------------------------------------------------
@interface DebugViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
//@}
/// @name Helpers
//@{
//@}
@end


@implementation DebugViewController


// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DebugViewController object.
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
  switch (section)
  {
    case GtpSection:
      return MaxGtpSectionItem;
//    case ApplicationLogSection:
//      return MaxApplicationLogSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case GtpSection:
      return @"GTP (Go Text Protocol)";
//    case ApplicationLogSection:
//      return @"Application Log";
    default:
      assert(0);
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  switch (indexPath.section)
  {
    case GtpSection:
    {
      switch (indexPath.row)
      {
        case GtpLogItem:
          cell.textLabel.text = @"GTP log";
          break;
        case GtpClearLogItem:
          cell.textLabel.text = @"Clear GTP log";
          cell.accessoryType = UITableViewCellAccessoryNone;
          break;
        case GtpCommandsItem:
          cell.textLabel.text = @"GTP commands";
          break;
        case GtpSettingsItem:
          cell.textLabel.text = @"Settings";
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
//    case ApplicationLogSection:
//    {
//      switch (indexPath.row)
//      {
//        case ApplicationLogItem:
//          cell.textLabel.text = @"View application log";
//          break;
//        case ApplicationLogSettingsItem:
//          cell.textLabel.text = @"Settings";
//          break;
//        default:
//          assert(0);
//          break;
//      }
//      break;
//    }
    default:
      assert(0);
      break;
  }
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
  switch (indexPath.section)
  {
    case GtpSection:
      break;
//    case ApplicationLogSection:
//      break;
    default:
      return;
  }
}

@end
