// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "DisplaySettingsController.h"
#import "../command/playerinfluence/ToggleTerritoryStatisticsCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/BoardViewModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../ui/TableViewVariableHeightCell.h"
#import "../ui/UIViewControllerAdditions.h"

// Constants
static const float sliderValueFactorForMoveNumbersPercentage = 100.0;
NSString* displayPlayerInfluenceText = @"Display player influence";


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Display" user preferences
/// table view.
// -----------------------------------------------------------------------------
enum DisplayTableViewSection
{
  ViewSection,
  MarkupPrecedenceSection,
  DisplayCoordinatesSection,
  DisplayMoveNumbersSection,
  DisplayPlayerInfluenceSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ViewSection.
// -----------------------------------------------------------------------------
enum ViewSectionItem
{
  MarkLastMoveItem,
  SelectedSymbolMarkupStyleItem,
  MaxViewSectionItem
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
/// @brief Enumerates items in the DisplayCoordinatesSection.
// -----------------------------------------------------------------------------
enum DisplayCoordinatesSectionItem
{
  DisplayCoordinatesItem,
  MaxDisplayCoordinatesSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DisplayMoveNumbersSection.
// -----------------------------------------------------------------------------
enum DisplayMoveNumbersSectionItem
{
  MoveNumbersPercentageItem,
  MaxDisplayMoveNumbersSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DisplayPlayerInfluenceSection.
// -----------------------------------------------------------------------------
enum DisplayPlayerInfluenceSectionItem
{
  DisplayPlayerInfluenceItem,
  MaxDisplayPlayerInfluenceSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// DisplaySettingsController.
// -----------------------------------------------------------------------------
@interface DisplaySettingsController()
@property(nonatomic, assign) BoardViewModel* boardViewModel;
@end


@implementation DisplaySettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a DisplaySettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (DisplaySettingsController*) controller
{
  DisplaySettingsController* controller = [[DisplaySettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DisplaySettingsController
/// object.
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
  self.title = @"Display settings";
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
    case ViewSection:
      return MaxViewSectionItem;
    case MarkupPrecedenceSection:
      return MaxMarkupPrecedenceSectionItem;
    case DisplayCoordinatesSection:
      return MaxDisplayCoordinatesSectionItem;
    case DisplayMoveNumbersSection:
      return MaxDisplayMoveNumbersSectionItem;
    case DisplayPlayerInfluenceSection:
      return MaxDisplayPlayerInfluenceSectionItem;
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
    case ViewSection:
      return @"The style to use when marking up an intersection with the \"selected\" symbol.";
    case MarkupPrecedenceSection:
      return @"The order of precedence for drawing symbol and label markup on the board. When both symbol and label markup exists for a given intersection, only one of them can be drawn. This setting determines which of the two should be drawn.";
    case DisplayCoordinatesSection:
      return @"On the iPhone you may need to zoom in to see coordinate labels.";
    case DisplayMoveNumbersSection:
      return @"The lowest setting displays no move numbers, the highest setting displays all move numbers. On the iPhone you may need to zoom in to see move numbers.";
    case DisplayPlayerInfluenceSection:
      return @"After turning this on, the Go board will display player influence as soon as the computer player has made its next move. Turning this on also adds a new entry 'Update player influence' to the game actions menu. Select this action to immediately update player influence (useful e.g. after a board position change).";
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
    case ViewSection:
    {
      switch (indexPath.row)
      {
        case MarkLastMoveItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Mark last move";
          accessoryView.on = self.boardViewModel.markLastMove;
          [accessoryView addTarget:self action:@selector(toggleMarkLastMove:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        case SelectedSymbolMarkupStyleItem:
        {
          cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
          TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
          variableHeightCell.descriptionLabel.text = @"\"Selected\" symbol style";
          variableHeightCell.valueLabel.text = [self selectedSymbolMarkupStyleAsString:self.boardViewModel.selectedSymbolMarkupStyle];
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
      break;
    }
    case MarkupPrecedenceSection:
    {
      switch (indexPath.row)
      {
        case MarkupPrecedenceItem:
        {
          cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
          TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
          variableHeightCell.descriptionLabel.text = @"Markup precedence";
          variableHeightCell.valueLabel.text = [self markupPrecedenceAsString:self.boardViewModel.markupPrecedence];
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
      break;
    }
    case DisplayCoordinatesSection:
    {
      switch (indexPath.row)
      {
        case DisplayCoordinatesItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Display coordinates";
          accessoryView.on = self.boardViewModel.displayCoordinates;
          [accessoryView addTarget:self action:@selector(toggleDisplayCoordinates:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        default:
        {
          assert(0);
          @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
          break;
        }
      }
      break;
    }
    case DisplayMoveNumbersSection:
    {
      switch (indexPath.row)
      {
        case MoveNumbersPercentageItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderWithoutValueLabelCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(moveNumbersPercentageDidChange:)];
          sliderCell.descriptionLabel.text = @"Display move numbers";
          sliderCell.slider.minimumValue = 0;
          sliderCell.slider.maximumValue = (1.0
                                            * sliderValueFactorForMoveNumbersPercentage);
          sliderCell.value = (self.boardViewModel.moveNumbersPercentage
                              * sliderValueFactorForMoveNumbersPercentage);
          break;
        }
        default:
        {
          assert(0);
          @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
          break;
        }
      }
      break;
    }
    case DisplayPlayerInfluenceSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = displayPlayerInfluenceText;
      cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
      cell.textLabel.numberOfLines = 0;
      accessoryView.on = self.boardViewModel.displayPlayerInfluence;
      [accessoryView addTarget:self action:@selector(toggleDisplayPlayerInfluence:) forControlEvents:UIControlEventValueChanged];
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
    case ViewSection:
    {
      switch (indexPath.row)
      {
        case SelectedSymbolMarkupStyleItem:
        {
          [self pickSelectedSymbolMarkupStyle];
        }
        default:
        {
          break;
        }
      }
      break;
    }
    case MarkupPrecedenceSection:
    {
      switch (indexPath.row)
      {
        case MarkupPrecedenceItem:
        {
          [self pickMarkupPrecedence];
        }
        default:
        {
          break;
        }
      }
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
/// @brief Reacts to a tap gesture on the "Mark last move" switch. Writes the
/// new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleMarkLastMove:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.boardViewModel.markLastMove = accessoryView.on;
}

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
                                                                         indexOfDefaultItem:self.boardViewModel.selectedSymbolMarkupStyle
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:ViewSection];

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
                                                                         indexOfDefaultItem:self.boardViewModel.markupPrecedence
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:MarkupPrecedenceSection];

  [self presentNavigationControllerWithRootViewController:itemPickerController];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Display coordinates" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleDisplayCoordinates:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.boardViewModel.displayCoordinates = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the "display move numbers" setting.
// -----------------------------------------------------------------------------
- (void) moveNumbersPercentageDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.boardViewModel.moveNumbersPercentage = (1.0 * sliderCell.value / sliderValueFactorForMoveNumbersPercentage);
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Display player influence" switch.
// -----------------------------------------------------------------------------
- (void) toggleDisplayPlayerInfluence:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.boardViewModel.displayPlayerInfluence = accessoryView.on;
  [[[[ToggleTerritoryStatisticsCommand alloc] init] autorelease] submit];
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
    if (context.intValue == ViewSection)
    {
      if (self.boardViewModel.selectedSymbolMarkupStyle != controller.indexOfSelectedItem)
      {
        self.boardViewModel.selectedSymbolMarkupStyle = controller.indexOfSelectedItem;
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:SelectedSymbolMarkupStyleItem inSection:ViewSection];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
      }
    }
    else
    {
      if (self.boardViewModel.markupPrecedence != controller.indexOfSelectedItem)
      {
        self.boardViewModel.markupPrecedence = controller.indexOfSelectedItem;
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
