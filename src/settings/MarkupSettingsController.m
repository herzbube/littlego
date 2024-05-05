// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "MarkupSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/MarkupModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewVariableHeightCell.h"
#import "../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Markup" user preferences
/// table view.
// -----------------------------------------------------------------------------
enum MarkupTableViewSection
{
  SelectedSymbolMarkupStyleSection,
  MarkupPrecedenceSection,
  UniqueSymbolsSection,
  ConnectionToolAllowsDeleteSection,
  FillMarkerGapsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the SelectedSymbolMarkupStyleSection.
// -----------------------------------------------------------------------------
enum SelectedSymbolMarkupStyleSectionItem
{
  SelectedSymbolMarkupStyleItem,
  MaxSelectedSymbolMarkupStyleSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the MarkupPrecedenceSection.
// -----------------------------------------------------------------------------
enum MarkupPrecedenceSectionItem
{
  MarkupPrecedenceItem,
  MaxMarkupPrecedenceSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the UniqueSymbolsSection.
// -----------------------------------------------------------------------------
enum UniqueSymbolsSectionItem
{
  UniqueSymbolsItem,
  MaxUniqueSymbolsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ConnectionToolAllowsDeleteSection.
// -----------------------------------------------------------------------------
enum ConnectionToolAllowsDeleteSectionItem
{
  ConnectionToolAllowsDeleteItem,
  MaxConnectionToolAllowsDeleteSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the FillMarkerGapsSection.
// -----------------------------------------------------------------------------
enum FillMarkerGapsSectionItem
{
  FillMarkerGapsItem,
  MaxFillMarkerGapsSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// MarkupSettingsController.
// -----------------------------------------------------------------------------
@interface MarkupSettingsController()
@property(nonatomic, assign) MarkupModel* markupModel;
@end


@implementation MarkupSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a MarkupSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (MarkupSettingsController*) controller
{
  MarkupSettingsController* controller = [[MarkupSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.markupModel = [ApplicationDelegate sharedDelegate].markupModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MarkupSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.markupModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Markup settings";
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
    case SelectedSymbolMarkupStyleSection:
      return MaxSelectedSymbolMarkupStyleSectionItem;
    case MarkupPrecedenceSection:
      return MaxMarkupPrecedenceSectionItem;
    case UniqueSymbolsSection:
      return MaxUniqueSymbolsSectionItem;
    case ConnectionToolAllowsDeleteSection:
      return MaxConnectionToolAllowsDeleteSectionItem;
    case FillMarkerGapsSection:
      return MaxFillMarkerGapsSectionItem;
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
    case SelectedSymbolMarkupStyleSection:
      return @"The style to use when marking up an intersection with the \"selected\" symbol.";
    case MarkupPrecedenceSection:
      return @"The order of precedence for drawing symbol and label markup on the board. When both symbol and label markup exists for a given intersection, only one of them can be drawn. This setting determines which of the two should be drawn.";
    case UniqueSymbolsSection:
      return @"If turned on, whenever you place a symbol the app will choose a different symbol for you that is unique on the board. As a consequence, when all symbols are on the board you cannot place symbols anymore. If turned off, the same symbol can be placed multiple times on the board. Turning this on can be convenient to save a couple of taps if you frequently mark up multiple intersections on the same board position.";
    case ConnectionToolAllowsDeleteSection:
      return @"If turned on, tapping on a connection's end point while the connection tool is active will delete the connection. If turned off tapping does nothing while the connection tool is active - connections in that case can only be deleted with the eraser tool. You may want to turn this setting off if you accidentally delete connections instead of placing new ones.";
    case FillMarkerGapsSection:
      return @"Should gaps in the sequence of existing markers be filled when you place a letter or number marker? Example if number markers 1, 2 and 4 already exist: If the setting is turned on the next number marker placed will be 3 (filling the gap), if the setting is turned off the next number marker placed will be 5.";
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
    case SelectedSymbolMarkupStyleSection:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"\"Selected\" symbol style";
      variableHeightCell.valueLabel.text = [self selectedSymbolMarkupStyleAsString:self.markupModel.selectedSymbolMarkupStyle];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case MarkupPrecedenceSection:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Markup precedence";
      variableHeightCell.valueLabel.text = [self markupPrecedenceAsString:self.markupModel.markupPrecedence];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case UniqueSymbolsSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Unique symbols";
      accessoryView.on = self.markupModel.uniqueSymbols;
      [accessoryView addTarget:self action:@selector(toggleUniqueSymbols:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case ConnectionToolAllowsDeleteSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Connection tool allows delete";
      accessoryView.on = self.markupModel.connectionToolAllowsDelete;
      [accessoryView addTarget:self action:@selector(toggleConnectionToolAllowsDelete:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case FillMarkerGapsSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Fill marker gaps";
      accessoryView.on = self.markupModel.fillMarkerGaps;
      [accessoryView addTarget:self action:@selector(toggleFillMarkerGaps:) forControlEvents:UIControlEventValueChanged];
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
    case SelectedSymbolMarkupStyleSection:
    {
      [self pickSelectedSymbolMarkupStyle];
      break;
    }
    case MarkupPrecedenceSection:
    {
      [self pickMarkupPrecedence];
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
/// for the SelectedSymbolMarkupStyle property.
// -----------------------------------------------------------------------------
- (void) pickSelectedSymbolMarkupStyle
{
  NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
  [itemList addObject:[self selectedSymbolMarkupStyleAsString:SelectedSymbolMarkupStyleDotSymbol]];
  [itemList addObject:[self selectedSymbolMarkupStyleAsString:SelectedSymbolMarkupStyleCheckmark]];
  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                screenTitle:@"Select symbol style"
                                                                         indexOfDefaultItem:self.markupModel.selectedSymbolMarkupStyle
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:SelectedSymbolMarkupStyleSection];

  [self presentNavigationControllerWithRootViewController:itemPickerController];
}

// -----------------------------------------------------------------------------
/// @brief Displays ItemPickerController to allow the user to pick a new value
/// for the MarkupPrecedence property.
// -----------------------------------------------------------------------------
- (void) pickMarkupPrecedence
{
  NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
  [itemList addObject:[self markupPrecedenceAsString:MarkupPrecedenceSymbols]];
  [itemList addObject:[self markupPrecedenceAsString:MarkupPrecedenceLabels]];
  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                screenTitle:@"Select markup precedence"
                                                                         indexOfDefaultItem:self.markupModel.markupPrecedence
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:MarkupPrecedenceSection];

  [self presentNavigationControllerWithRootViewController:itemPickerController];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Unique symbols" switch. Writes the
/// new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleUniqueSymbols:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.markupModel.uniqueSymbols = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Connection tool allows delete"
/// switch. Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleConnectionToolAllowsDelete:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.markupModel.connectionToolAllowsDelete = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the "Fill marker gaps" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleFillMarkerGaps:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.markupModel.fillMarkerGaps = accessoryView.on;
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
    if (context.intValue == SelectedSymbolMarkupStyleSection)
    {
      if (self.markupModel.selectedSymbolMarkupStyle != controller.indexOfSelectedItem)
      {
        self.markupModel.selectedSymbolMarkupStyle = controller.indexOfSelectedItem;
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:SelectedSymbolMarkupStyleItem inSection:SelectedSymbolMarkupStyleSection];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
      }
    }
    else
    {
      if (self.markupModel.markupPrecedence != controller.indexOfSelectedItem)
      {
        self.markupModel.markupPrecedence = controller.indexOfSelectedItem;
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:MarkupPrecedenceItem inSection:MarkupPrecedenceSection];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
      }
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a short string for @a selectedSymbolMarkupStyle that is
/// suitable for display in a cell in the table view managed by this controller.
// -----------------------------------------------------------------------------
- (NSString*) selectedSymbolMarkupStyleAsString:(enum SelectedSymbolMarkupStyle)selectedSymbolMarkupStyle
{
  switch (selectedSymbolMarkupStyle)
  {
    case SelectedSymbolMarkupStyleDotSymbol:
      return @"Dot symbol";
    case SelectedSymbolMarkupStyleCheckmark:
      return @"Check mark";
    default:
      assert(0);
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns a short string for @a markupPrecedence that is suitable
/// for display in a cell in the table view managed by this controller.
// -----------------------------------------------------------------------------
- (NSString*) markupPrecedenceAsString:(enum MarkupPrecedence)markupPrecedence
{
  switch (markupPrecedence)
  {
    case MarkupPrecedenceSymbols:
      return @"Draw symbols first";
    case MarkupPrecedenceLabels:
      return @"Draw labels first";
    default:
      assert(0);
      break;
  }
  return nil;
}

@end
