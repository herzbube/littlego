// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameVariationSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/GameVariationModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewVariableHeightCell.h"
#import "../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game variation" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum NodeTreeViewTableViewSection
{
  NewMoveInsertPolicySection,
  NewMoveInsertPositionSection,  // not shown when policy is GoNewMoveInsertPolicyReplaceFutureBoardPositions,
  MaxSectionNewMoveInsertPolicyRetainFutureBoardPositions,
  MaxSectionNewMoveInsertPolicyReplaceFutureBoardPositions = MaxSectionNewMoveInsertPolicyRetainFutureBoardPositions - 1,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the NewMoveInsertPolicySection.
// -----------------------------------------------------------------------------
enum NewMoveInsertPolicySectionItem
{
  NewMoveInsertPolicyItem,
  MaxNewMoveInsertPolicySectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the NewMoveInsertPositionSection.
// -----------------------------------------------------------------------------
enum NewMoveInsertPositionSectionItem
{
  NewMoveInsertPositionItem,
  MaxNewMoveInsertPositionSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// GameVariationSettingsController.
// -----------------------------------------------------------------------------
@interface GameVariationSettingsController()
@property(nonatomic, assign) GameVariationModel* gameVariationModel;
@end


@implementation GameVariationSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GameVariationSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (GameVariationSettingsController*) controller
{
  GameVariationSettingsController* controller = [[GameVariationSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.gameVariationModel = [ApplicationDelegate sharedDelegate].gameVariationModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameVariationSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameVariationModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Game variation settings";
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (self.gameVariationModel.newMoveInsertPolicy == GoNewMoveInsertPolicyRetainFutureBoardPositions)
    return MaxSectionNewMoveInsertPolicyRetainFutureBoardPositions;
  else
    return MaxSectionNewMoveInsertPolicyReplaceFutureBoardPositions;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case NewMoveInsertPolicySection:
      return MaxNewMoveInsertPolicySectionItem;
    case NewMoveInsertPositionSection:
      return MaxNewMoveInsertPositionSectionItem;
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
    case NewMoveInsertPolicySection:
      return @"When you make a move while you are viewing a board position in the middle of the current game variation, the app inserts the new move as a new game variation into the node tree and retains future nodes in the current game variation. If this option is turned off the app will instead discard future nodes in the current game variation and replace them with the new move.";
    case NewMoveInsertPositionSection:
      return @"When the app creates a new game variation because of the setting above, select here where the app should insert the new game variation into the node tree.";
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
    case NewMoveInsertPolicySection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
      cell.textLabel.numberOfLines = 0;
      cell.textLabel.text = @"Move creates new game variation when future nodes exist";
      accessoryView.on = self.gameVariationModel.newMoveInsertPolicy == GoNewMoveInsertPolicyRetainFutureBoardPositions;
      [accessoryView addTarget:self action:@selector(toggleNewMoveInsertPolicy:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case NewMoveInsertPositionSection:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"New game variation insert position";
      variableHeightCell.valueLabel.text = [self newMoveInsertPositionAsString:self.gameVariationModel.newMoveInsertPosition];
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

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  switch (indexPath.section)
  {
    case NewMoveInsertPositionSection:
    {
      [self pickNewMoveInsertPosition];
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
/// @brief Reacts to a tap gesture on the "new move insert policy" switch.
/// Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleNewMoveInsertPolicy:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.gameVariationModel.newMoveInsertPolicy = (accessoryView.on
                                                 ? GoNewMoveInsertPolicyRetainFutureBoardPositions
                                                 : GoNewMoveInsertPolicyReplaceFutureBoardPositions);
  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Displays ItemPickerController to allow the user to pick a new value
/// for the "new move insert position" user preference.
// -----------------------------------------------------------------------------
- (void) pickNewMoveInsertPosition
{
  NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
  [itemList addObject:[self newMoveInsertPositionAsString:GoNewMoveInsertPositionNewVariationAtTop]];
  [itemList addObject:[self newMoveInsertPositionAsString:GoNewMoveInsertPositionNewVariationAtBottom]];
  [itemList addObject:[self newMoveInsertPositionAsString:GoNewMoveInsertPositionNewVariationBeforeCurrentVariation]];
  [itemList addObject:[self newMoveInsertPositionAsString:GoNewMoveInsertPositionNewVariationAfterCurrentVariation]];
  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                screenTitle:@"Select new game variation insert position"
                                                                         indexOfDefaultItem:self.gameVariationModel.newMoveInsertPosition
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:NewMoveInsertPositionSection];

  [self presentNavigationControllerWithRootViewController:itemPickerController];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    NSNumber* context = controller.context;
    if (context.intValue == NewMoveInsertPositionSection)
    {
      if (self.gameVariationModel.newMoveInsertPosition != controller.indexOfSelectedItem)
      {
        self.gameVariationModel.newMoveInsertPosition = controller.indexOfSelectedItem;
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:NewMoveInsertPositionItem inSection:NewMoveInsertPositionSection];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
      }
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a short string for @a newMoveInsertPosition that is suitable
/// for display in a cell in the table view managed by this controller.
// -----------------------------------------------------------------------------
- (NSString*) newMoveInsertPositionAsString:(enum GoNewMoveInsertPosition)newMoveInsertPosition
{
  switch (newMoveInsertPosition)
  {
    case GoNewMoveInsertPositionNewVariationAtTop:
      return @"Above all other game variations";
    case GoNewMoveInsertPositionNewVariationAtBottom:
      return @"Below all other game variations";
    case GoNewMoveInsertPositionNewVariationBeforeCurrentVariation:
      return @"Above current game variation";
    case GoNewMoveInsertPositionNewVariationAfterCurrentVariation:
      return @"Below current game variation";
    default:
      assert(0);
      break;
  }
  return nil;
}

@end
