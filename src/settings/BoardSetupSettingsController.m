// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardSetupSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/BoardSetupModel.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Board setup" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum BoardSetupTableViewSection
{
  DoubleTapToZoomSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DoubleTapToZoomSection.
// -----------------------------------------------------------------------------
enum DoubleTapToZoomSectionItem
{
  DoubleTapToZoomItem,
  MaxDoubleTapToZoomSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardSetupSettingsController.
// -----------------------------------------------------------------------------
@interface BoardSetupSettingsController()
@property(nonatomic, assign) BoardSetupModel* boardSetupModel;
@end


@implementation BoardSetupSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a BoardSetupSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (BoardSetupSettingsController*) controller
{
  BoardSetupSettingsController* controller = [[BoardSetupSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.boardSetupModel = [ApplicationDelegate sharedDelegate].boardSetupModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardSetupSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardSetupModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Board setup settings";
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
  switch (section)
  {
    case DoubleTapToZoomSection:
      return MaxDoubleTapToZoomSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case DoubleTapToZoomSection:
      return @"In board setup mode you may want to quickly tap on the same intersection several times in a row, to cycle through the differently colored setup stones. This may trigger an unwanted double-tap gesture which causes the board to zoom in. When you find that this negatively affects you, you can disable the double-tap gesture for board setup mode only.";
    default:
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
  UISwitch* accessoryView = (UISwitch*)cell.accessoryView;

  switch (indexPath.section)
  {
    case DoubleTapToZoomSection:
    {
      cell.textLabel.text = @"Double-tap to zoom";
      cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
      cell.textLabel.numberOfLines = 0;
      accessoryView.on = self.boardSetupModel.doubleTapToZoom;
      [accessoryView addTarget:self action:@selector(toggleDoubleTapToZoom:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Double-tap to zoom" switch.
/// Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleDoubleTapToZoom:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.boardSetupModel.doubleTapToZoom = accessoryView.on;
}

@end
