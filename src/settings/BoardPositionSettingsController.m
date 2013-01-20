// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../play/boardposition/BoardPositionModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"

// Constants
NSString* discardFutureMovesAlertText = @"Discard future moves alert";


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Board position" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum MoveHistoryTableViewSection
{
  DiscardFutureMovesAlertSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DiscardFutureMovesAlertSection.
// -----------------------------------------------------------------------------
enum DiscardFutureMovesAlertSectionItem
{
  DiscardFutureMovesAlertItem,
  MaxDiscardFutureMovesAlertSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// BoardPositionSettingsController.
// -----------------------------------------------------------------------------
@interface BoardPositionSettingsController()
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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
- (void) toggleDiscardFutureMovesAlert:(id)sender;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) BoardPositionModel* boardPositionModel;
//@}
@end


@implementation BoardPositionSettingsController

@synthesize boardPositionModel;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a BoardPositionSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (BoardPositionSettingsController*) controller
{
  BoardPositionSettingsController* controller = [[BoardPositionSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardPositionModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Board position settings";
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
  switch (section)
  {
    case DiscardFutureMovesAlertSection:
      return MaxDiscardFutureMovesAlertSectionItem;
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
    case DiscardFutureMovesAlertSection:
      return @"If you make or discard a move while you are looking at a board position in the middle of the game, all moves that have been made after this position will be discarded. If this option is turned off you will NOT be alerted that this is going to happen.";
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
  UITableViewCell* cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
  UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
  switch (indexPath.section)
  {
    case DiscardFutureMovesAlertSection:
    {
      cell.textLabel.text = discardFutureMovesAlertText;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 0;
      accessoryView.on = self.boardPositionModel.discardFutureMovesAlert;
      [accessoryView addTarget:self action:@selector(toggleDiscardFutureMovesAlert:) forControlEvents:UIControlEventValueChanged];
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
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* cellText = nil;
  switch (indexPath.section)
  {
    case DiscardFutureMovesAlertSection:
      cellText = discardFutureMovesAlertText;
      break;
    default:
      return tableView.rowHeight;
  }
  return [UiUtilities tableView:tableView
            heightForCellOfType:SwitchCellType
                       withText:cellText
         hasDisclosureIndicator:false];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Discard future moves alert" switch.
/// Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleDiscardFutureMovesAlert:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.boardPositionModel.discardFutureMovesAlert = accessoryView.on;
}

@end
