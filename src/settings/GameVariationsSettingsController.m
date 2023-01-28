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
#import "GameVariationsSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/GameVariationsModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewVariableHeightCell.h"
#import "../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game variations" user
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
/// GameVariationsSettingsController.
// -----------------------------------------------------------------------------
@interface GameVariationsSettingsController()
@property(nonatomic, assign) GameVariationsModel* gameVariationsModel;
@end


@implementation GameVariationsSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GameVariationsSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (GameVariationsSettingsController*) controller
{
  GameVariationsSettingsController* controller = [[GameVariationsSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.gameVariationsModel = [ApplicationDelegate sharedDelegate].gameVariationsModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameVariationsSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameVariationsModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Game variations settings";
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (self.gameVariationsModel.newMoveInsertPolicy == GoNewMoveInsertPolicyRetainFutureBoardPositions)
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
      return @"When a new move is being played and you are viewing a board position somewhere in the middle of the current game variation, the app needs to know what it should do with the current game variation. Select here 1) if you want to keep the current game variation and insert the new move as a new game variation into the node tree, or 2) if you want to discard the remaining board positions in the current game variation and replace them with the new move.\n\nThis setting has no effect if you are viewing the last board position of the current game variation - in this case the new move is simply added as a new board position.";
    case NewMoveInsertPositionSection:
      return @"When the app creates a new game variation because of the setting above, select here where the app should insert the new game variation into the node tree. The app can insert the new game variation above or below all the other game variations, or it can insert the new game variation just above or below the current game variation.";
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
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"New move insert policy";
      variableHeightCell.valueLabel.text = [self newMoveInsertPolicyAsString:self.gameVariationsModel.newMoveInsertPolicy];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case NewMoveInsertPositionSection:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"New game variation insert position";
      variableHeightCell.valueLabel.text = [self newMoveInsertPositionAsString:self.gameVariationsModel.newMoveInsertPosition];
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
    case NewMoveInsertPolicySection:
    {
      [self pickNewMoveInsertPolicy];
      break;
    }
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
/// @brief Displays ItemPickerController to allow the user to pick a new value
/// for the "branching style" user preference.
// -----------------------------------------------------------------------------
- (void) pickNewMoveInsertPolicy
{
  NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
  [itemList addObject:[self newMoveInsertPolicyAsString:GoNewMoveInsertPolicyRetainFutureBoardPositions]];
  [itemList addObject:[self newMoveInsertPolicyAsString:GoNewMoveInsertPolicyReplaceFutureBoardPositions]];
  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                screenTitle:@"Select new move insert policy"
                                                                         indexOfDefaultItem:self.gameVariationsModel.newMoveInsertPolicy
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:NewMoveInsertPolicySection];

  [self presentNavigationControllerWithRootViewController:itemPickerController];
}

// -----------------------------------------------------------------------------
/// @brief Displays ItemPickerController to allow the user to pick a new value
/// for the "node selection style" user preference.
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
                                                                         indexOfDefaultItem:self.gameVariationsModel.newMoveInsertPosition
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
    if (context.intValue == NewMoveInsertPolicySection)
    {
      if (self.gameVariationsModel.newMoveInsertPolicy != controller.indexOfSelectedItem)
      {
        self.gameVariationsModel.newMoveInsertPolicy = controller.indexOfSelectedItem;
        [self.tableView reloadData];
      }
    }
    else if (context.intValue == NewMoveInsertPositionSection)
    {
      if (self.gameVariationsModel.newMoveInsertPosition != controller.indexOfSelectedItem)
      {
        self.gameVariationsModel.newMoveInsertPosition = controller.indexOfSelectedItem;
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
/// @brief Returns a short string for @a newMoveInsertPolicy that is suitable
/// for display in a cell in the table view managed by this controller.
// -----------------------------------------------------------------------------
- (NSString*) newMoveInsertPolicyAsString:(enum GoNewMoveInsertPolicy)newMoveInsertPolicy
{
  switch (newMoveInsertPolicy)
  {
    case GoNewMoveInsertPolicyRetainFutureBoardPositions:
      return @"Keep current game variation";
    case GoNewMoveInsertPolicyReplaceFutureBoardPositions:
      return @"Replace current game variation";
    default:
      assert(0);
      break;
  }
  return nil;
}

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
