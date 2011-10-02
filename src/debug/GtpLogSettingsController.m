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
#import "GtpLogSettingsController.h"
#import "GtpLogModel.h"
#import "../ApplicationDelegate.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Gtp Log Settings" table
/// view.
// -----------------------------------------------------------------------------
enum GtpLogSettingsTableViewSection
{
  SettingsSection,
  ClearLogSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the SettingsSection.
// -----------------------------------------------------------------------------
enum SettingsSectionItem
{
  LogSizeItem,
  MaxSettingsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ClearLogSection.
// -----------------------------------------------------------------------------
enum ClearLogSectionItem
{
  ClearLogItem,
  MaxClearLogSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpLogSettingsController.
// -----------------------------------------------------------------------------
@interface GtpLogSettingsController()
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
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
- (void) logSizeDidChange:(id)sender;
//@}
/// @name Privately declared properties
//@{
@property(retain) GtpLogModel* model;
//@}
@end


@implementation GtpLogSettingsController

@synthesize model;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpLogSettingsController instance
/// of grouped style.
// -----------------------------------------------------------------------------
+ (GtpLogSettingsController*) controller
{
  GtpLogSettingsController* controller = [[GtpLogSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
    [controller autorelease];
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpLogSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.model = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.model = [ApplicationDelegate sharedDelegate].gtpLogModel;
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
    case SettingsSection:
      return MaxSettingsSectionItem;
    case ClearLogSection:
      return MaxClearLogSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case SettingsSection:
    {
      switch (indexPath.row)
      {
        case LogSizeItem:
          cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(logSizeDidChange:)];
          sliderCell.descriptionLabel.text = @"GTP log size";
          sliderCell.slider.minimumValue = gtpLogSizeMinimum;
          sliderCell.slider.maximumValue = gtpLogSizeMaximum;
          sliderCell.value = self.model.gtpLogSize;
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    case ClearLogSection:
    {
      switch (indexPath.row)
      {
        case ClearLogItem:
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
          cell.textLabel.text = @"Clear GTP log";
          cell.accessoryType = UITableViewCellAccessoryNone;
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    default:
      assert(0);
      break;
  }
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat height = tableView.rowHeight;
  if (SettingsSection == indexPath.section && LogSizeItem == indexPath.row)
    height = [TableViewSliderCell rowHeightInTableView:tableView];
  return height;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (ClearLogSection == indexPath.section && ClearLogItem == indexPath.row)
    [self.model clearLog];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the GTP log size.
// -----------------------------------------------------------------------------
- (void) logSizeDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.model.gtpLogSize = sliderCell.value;
}

@end
