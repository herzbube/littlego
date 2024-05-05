// -----------------------------------------------------------------------------
// Copyright 2021-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "ComputerAssistanceSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/BoardViewModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewVariableHeightCell.h"
#import "../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Computer assistance" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum ComputerAssistanceTableViewSection
{
  ComputerAssistanceSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ComputerAssistanceSection.
// -----------------------------------------------------------------------------
enum ComputerAssistanceSectionItem
{
  ComputerAssistanceItem,
  MaxComputerAssistanceSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ComputerAssistanceSettingsController.
// -----------------------------------------------------------------------------
@interface ComputerAssistanceSettingsController()
@property(nonatomic, assign) BoardViewModel* boardViewModel;
@end


@implementation ComputerAssistanceSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a
/// ComputerAssistanceSettingsController instance of grouped style.
// -----------------------------------------------------------------------------
+ (ComputerAssistanceSettingsController*) controller
{
  ComputerAssistanceSettingsController* controller = [[ComputerAssistanceSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// ComputerAssistanceSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardViewModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Computer assistance";
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
    case ComputerAssistanceSection:
      return MaxComputerAssistanceSectionItem;
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
    case ComputerAssistanceSection:
      return @"When it is your turn to play you can ask the computer for assistance. Depending on what you select here the computer will immediately play a move on your behalf (which you can still discard if you don't like it), or it will merely make a suggestion how to play (but you then have to play the move yourself). If you prefer you can also play without computer assistance.";
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
  UITableViewCell* cell = nil;

  switch (indexPath.section)
  {
    case ComputerAssistanceSection:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Computer assistance";
      variableHeightCell.valueLabel.text = [self computerAssistanceTypeAsString:self.boardViewModel.computerAssistanceType];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    default:
    {
      assert(0);
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
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

  switch (indexPath.section)
  {
    case ComputerAssistanceSection:
    {
      [self pickComputerAssistanceType];
      break;
    }
    default:
    {
      break;
    }
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Displays ItemPickerController to allow the user to pick a new value
/// for the ComputerAssistanceType property.
// -----------------------------------------------------------------------------
- (void) pickComputerAssistanceType
{
  NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
  [itemList addObject:[self computerAssistanceTypeAsString:ComputerAssistanceTypePlayForMe]];
  [itemList addObject:[self computerAssistanceTypeAsString:ComputerAssistanceTypeSuggestMove]];
  [itemList addObject:[self computerAssistanceTypeAsString:ComputerAssistanceTypeNone]];
  ItemPickerController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                           screenTitle:@"Select assistance type"
                                                                    indexOfDefaultItem:self.boardViewModel.computerAssistanceType
                                                                              delegate:self];

  [self presentNavigationControllerWithRootViewController:modalController];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (self.boardViewModel.computerAssistanceType != controller.indexOfSelectedItem)
    {
      self.boardViewModel.computerAssistanceType = controller.indexOfSelectedItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ComputerAssistanceItem inSection:ComputerAssistanceSection];
      [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a short string for @a computerAssistanceType that is suitable
/// for display in a cell in the table view managed by this controller.
// -----------------------------------------------------------------------------
- (NSString*) computerAssistanceTypeAsString:(enum ComputerAssistanceType)computerAssistanceType
{
  switch (computerAssistanceType)
  {
    case ComputerAssistanceTypePlayForMe:
      return @"Play for me";
    case ComputerAssistanceTypeSuggestMove:
      return @"Suggest move";
    case ComputerAssistanceTypeNone:
      return @"No assistance";
    default:
      assert(0);
      break;
  }
  return nil;
}

@end
