// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/NodeTreeViewModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewVariableHeightCell.h"
#import "../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Tree view" user preferences
/// table view.
// -----------------------------------------------------------------------------
enum NodeTreeViewTableViewSection
{
  BranchingStyleSection,
  AlignMoveNodesSection,
  CondenseMoveNodesSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the BranchingStyleSection.
// -----------------------------------------------------------------------------
enum BranchingStyleSectionItem
{
  BranchingStyleItem,
  MaxBranchingStyleSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the AlignMoveNodesSection.
// -----------------------------------------------------------------------------
enum AlignMoveNodesSectionItem
{
  AlignMoveNodesItem,
  MaxAlignMoveNodesSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the CondenseMoveNodesSection.
// -----------------------------------------------------------------------------
enum CondenseMoveNodesSectionItem
{
  CondenseMoveNodesItem,
  MaxCondenseMoveNodesSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// NodeTreeViewSettingsController.
// -----------------------------------------------------------------------------
@interface NodeTreeViewSettingsController()
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
@end


@implementation NodeTreeViewSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a NodeTreeViewSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (NodeTreeViewSettingsController*) controller
{
  NodeTreeViewSettingsController* controller = [[NodeTreeViewSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.nodeTreeViewModel = [ApplicationDelegate sharedDelegate].nodeTreeViewModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.nodeTreeViewModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Tree view settings";
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
    case BranchingStyleSection:
      return MaxBranchingStyleSectionItem;
    case AlignMoveNodesSection:
      return MaxAlignMoveNodesSectionItem;
    case CondenseMoveNodesSection:
      return MaxCondenseMoveNodesSectionItem;
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
    case BranchingStyleSection:
      return @"The style with which to draw branching lines. The last section of a branching line can be drawn either diagonally or at a right angle. A diagonal line makes better use of the available space and can lead to a tighter diagram. Right angle lines may require more space but may also be easier to read. The default is to draw diagonal lines.";
    case AlignMoveNodesSection:
      return @"If turned on, moves with the same number that appear in different game variations are aligned, i.e. drawn at the same position. If turned off, all nodes are drawn in their natural position. Aligning moves has no effect if there are no other nodes in between the moves. The default is to not align moves.";
    case CondenseMoveNodesSection:
      return @"If turned on, moves within a sequence of moves are condensed, i.e. they are drawn smaller than moves at the beginning or end of the sequence. If turned off, all nodes are drawn with the same size. Condensing move nodes de-emphasizes repetitive content, at the cost of making the tree look less uniform. The default is to not condense moves.";
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
    case BranchingStyleSection:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Branching style";
      variableHeightCell.valueLabel.text = [self branchingStyleAsString:self.nodeTreeViewModel.branchingStyle];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case AlignMoveNodesSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Align moves";
      accessoryView.on = self.nodeTreeViewModel.alignMoveNodes;
      [accessoryView addTarget:self action:@selector(toggleAlignMoveNodes:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case CondenseMoveNodesSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Condense moves";
      accessoryView.on = self.nodeTreeViewModel.condenseMoveNodes;
      [accessoryView addTarget:self action:@selector(toggleCondenseMoveNodes:) forControlEvents:UIControlEventValueChanged];
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
    case BranchingStyleSection:
    {
      [self pickBranchingStyle];
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
- (void) pickBranchingStyle
{
  NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
  [itemList addObject:[self branchingStyleAsString:NodeTreeViewBranchingStyleDiagonal]];
  [itemList addObject:[self branchingStyleAsString:NodeTreeViewBranchingStyleRightAngle]];
  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                screenTitle:@"Select branching style"
                                                                         indexOfDefaultItem:self.nodeTreeViewModel.branchingStyle
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:BranchingStyleSection];

  [self presentNavigationControllerWithRootViewController:itemPickerController];
}
// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Align Move Nodes" switch. Writes the
/// new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAlignMoveNodes:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.nodeTreeViewModel.alignMoveNodes = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Condense move nodes" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleCondenseMoveNodes:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.nodeTreeViewModel.condenseMoveNodes = accessoryView.on;
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
    if (context.intValue == BranchingStyleSection)
    {
      if (self.nodeTreeViewModel.branchingStyle != controller.indexOfSelectedItem)
      {
        self.nodeTreeViewModel.branchingStyle = controller.indexOfSelectedItem;
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:BranchingStyleItem inSection:BranchingStyleSection];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
      }
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a short string for @a branchingStyle that is suitable for
/// display in a cell in the table view managed by this controller.
// -----------------------------------------------------------------------------
- (NSString*) branchingStyleAsString:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  switch (branchingStyle)
  {
    case NodeTreeViewBranchingStyleDiagonal:
      return @"Diagonal";
    case NodeTreeViewBranchingStyleRightAngle:
      return @"Right angle";
    default:
      assert(0);
      break;
  }
  return nil;
}

@end
