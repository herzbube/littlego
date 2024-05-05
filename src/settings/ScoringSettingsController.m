// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "ScoringSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/ScoringModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewVariableHeightCell.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UIViewControllerAdditions.h"

// Constants
NSString* markDeadStonesIntelligentlyText = @"Mark dead stones intelligently";
NSString* inconsistentTerritoryMarkupTypeText = @"Inconsistent territory markup type";


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Scoring" user preferences
/// table view.
// -----------------------------------------------------------------------------
enum ScoringTableViewSection
{
  AutoScoringAndResumingPlaySection,
  AskGtpEngineForDeadStonesItemSection,
  MarkDeadStonesIntelligentlySection,
  InconsistentTerritoryMarkupTypeSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the AutoScoringAndResumingPlaySection.
// -----------------------------------------------------------------------------
enum AutoScoringAndResumingPlaySectionItem
{
  AutoScoringAndResumingPlayItem,
  MaxAutoScoringAndResumingPlaySectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the AskGtpEngineForDeadStonesItemSection.
// -----------------------------------------------------------------------------
enum AskGtpEngineForDeadStonesItemSectionItem
{
  AskGtpEngineForDeadStonesItem,
  MaxAskGtpEngineForDeadStonesItemSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the MarkDeadStonesIntelligentlySection.
// -----------------------------------------------------------------------------
enum MarkDeadStonesIntelligentlySectionItem
{
  MarkDeadStonesIntelligentlyItem,
  MaxMarkDeadStonesIntelligentlySectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the InconsistentTerritoryMarkupTypeSection.
// -----------------------------------------------------------------------------
enum InconsistentTerritoryMarkupTypeSectionItem
{
  InconsistentTerritoryMarkupTypeItem,
  MaxInconsistentTerritoryMarkupTypeSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ScoringSettingsController.
// -----------------------------------------------------------------------------
@interface ScoringSettingsController()
@property(nonatomic, assign) ScoringModel* scoringModel;
@end


@implementation ScoringSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a ScoringSettingsController instance
/// of grouped style.
// -----------------------------------------------------------------------------
+ (ScoringSettingsController*) controller
{
  ScoringSettingsController* controller = [[ScoringSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ScoringSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scoringModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Scoring settings";
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
    case AutoScoringAndResumingPlaySection:
      return MaxAutoScoringAndResumingPlaySectionItem;
    case AskGtpEngineForDeadStonesItemSection:
      return MaxAskGtpEngineForDeadStonesItemSectionItem;
    case MarkDeadStonesIntelligentlySection:
      return MaxMarkDeadStonesIntelligentlySectionItem;
    case InconsistentTerritoryMarkupTypeSection:
      return MaxInconsistentTerritoryMarkupTypeSectionItem;
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
    case AutoScoringAndResumingPlaySection:
      return (@"Recommended for smoother gameplay. Turning this on has two "
              "effects: 1) The app automatically activates scoring mode when "
              "the game ends by two consecutive pass moves. 2) The app "
              "automatically resumes play when you leave scoring mode so that "
              "you and your opponent can settle life & death disputes.");
    case AskGtpEngineForDeadStonesItemSection:
      return @"When scoring mode is activated the app suggests an initial set of dead stones. The process of finding these dead stones takes a moment, and the suggestion may not always be accurate, so you may wish to turn this option off.";
    case MarkDeadStonesIntelligentlySection:
      return @"If turned on, whenever you toggle the dead/alive status of a stone group, all adjacent stone groups of the same color are automatically toggled to the same dead/alive status. This can greatly speed up the scoring process.";
    case InconsistentTerritoryMarkupTypeSection:
      return @"The style to mark inconsistent territory. This is territory where something about the dead or alive state of neighbouring stones is inconsistent, thus making it impossible to determine whether the territory is black, white or neutral. For instance, the territory has neighbouring stones of both colors, but both colors are marked dead.";
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case AutoScoringAndResumingPlaySection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.enabled = YES;
      cell.textLabel.text = @"Auto scoring / resuming play";
      accessoryView.on = self.scoringModel.autoScoringAndResumingPlay;
      [accessoryView addTarget:self action:@selector(toggleAutoScoringAndResumingPlay:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case AskGtpEngineForDeadStonesItemSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.enabled = YES;
      cell.textLabel.text = @"Find dead stones";
      accessoryView.on = self.scoringModel.askGtpEngineForDeadStones;
      [accessoryView addTarget:self action:@selector(toggleAskGtpEngineForDeadStones:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case MarkDeadStonesIntelligentlySection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.enabled = YES;
      cell.textLabel.text = markDeadStonesIntelligentlyText;
      cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
      cell.textLabel.numberOfLines = 0;
      accessoryView.on = self.scoringModel.markDeadStonesIntelligently;
      [accessoryView addTarget:self action:@selector(toggleMarkDeadStonesIntelligently:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case InconsistentTerritoryMarkupTypeSection:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = inconsistentTerritoryMarkupTypeText;
      variableHeightCell.valueLabel.text = [self inconsistentTerritoryMarkupTypeAsString:self.scoringModel.inconsistentTerritoryMarkupType];
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
    case InconsistentTerritoryMarkupTypeSection:
    {
      [self pickInconsistentTerritoryMarkupType];
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
/// @brief Reacts to a tap gesture on the "Auto scoring / resuming play" switch.
/// Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAutoScoringAndResumingPlay:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.scoringModel.autoScoringAndResumingPlay = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Find dead stones" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAskGtpEngineForDeadStones:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.scoringModel.askGtpEngineForDeadStones = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Mark dead stones intelligently"
/// switch. Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleMarkDeadStonesIntelligently:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.scoringModel.markDeadStonesIntelligently = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Displays ItemPickerController to allow the user to pick a new value
/// for the InconsistentTerritoryMarkupType property.
// -----------------------------------------------------------------------------
- (void) pickInconsistentTerritoryMarkupType
{
  NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
  [itemList addObject:[self inconsistentTerritoryMarkupTypeAsString:InconsistentTerritoryMarkupTypeDotSymbol]];
  [itemList addObject:[self inconsistentTerritoryMarkupTypeAsString:InconsistentTerritoryMarkupTypeFillColor]];
  [itemList addObject:[self inconsistentTerritoryMarkupTypeAsString:InconsistentTerritoryMarkupTypeNeutral]];
  ItemPickerController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                           screenTitle:@"Select style"
                                                                    indexOfDefaultItem:self.scoringModel.inconsistentTerritoryMarkupType
                                                                              delegate:self];
  modalController.footerTitle = @"Select neutral to not mark inconsistent territory at all, thus making it look as if it were neutral territory. Select this option if you are confident that you don't need any help picking out inconsistencies.";
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
    if (self.scoringModel.inconsistentTerritoryMarkupType != controller.indexOfSelectedItem)
    {
      self.scoringModel.inconsistentTerritoryMarkupType = controller.indexOfSelectedItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:InconsistentTerritoryMarkupTypeItem inSection:InconsistentTerritoryMarkupTypeSection];
      [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a short string for @a markupType that is suitable for display
/// in a cell in the table view managed by this controller.
// -----------------------------------------------------------------------------
- (NSString*) inconsistentTerritoryMarkupTypeAsString:(enum InconsistentTerritoryMarkupType)markupType
{
  switch (markupType)
  {
    case InconsistentTerritoryMarkupTypeDotSymbol:
      return @"Dot symbol";
    case InconsistentTerritoryMarkupTypeFillColor:
      return @"Fill color";
    case InconsistentTerritoryMarkupTypeNeutral:
      return @"Neutral";
    default:
      assert(0);
      break;
  }
  return nil;
}

@end
