// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "EditResignBehaviourSettingsController.h"
#import "../player/GtpEngineProfile.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Resign behaviour settings"
/// table view.
// -----------------------------------------------------------------------------
enum EditResignBehaviourSettingsTableViewSection
{
  ResignThresholdSection,
  ResignMinGamesSection,
  ResetToDefaultsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ResignThresholdSection.
// -----------------------------------------------------------------------------
enum ResignThresholdSectionItem
{
  MaxResignThresholdSectionItem = (((GoBoardSizeMax - GoBoardSizeMin) / 2) + 1)
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ResignMinGamesSection.
// -----------------------------------------------------------------------------
enum ResignMinGamesSectionItem
{
  AutoSelectResignMinGamesItem,
  ResignMinGamesItem,
  MaxResignMinGamesSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ResetToDefaultsSection.
// -----------------------------------------------------------------------------
enum ResetToDefaultsSectionItem
{
  ResetToDefaultsItem,
  MaxResetToDefaultsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates categories of "max. games" as they are displayed to the
/// user instead of meaningless raw numbers.
// -----------------------------------------------------------------------------
enum ResignMinGamesCategory
{
  Game0ResignMinGamesCategory,
  Game9ResignMinGamesCategory,
  Game99ResignMinGamesCategory,
  Game450ResignMinGamesCategory,
  Game950ResignMinGamesCategory,
  Game1950ResignMinGamesCategory,
  Game4950ResignMinGamesCategory,
  MaxResignMinGamesCategory,
  UndefinedResignMinGamesCategory
};


@implementation EditResignBehaviourSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a EditResignBehaviourSettingsController object.
///
/// @note This is the designated initializer of
/// EditResignBehaviourSettingsController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;
  self.delegate = nil;
  self.profile = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// EditResignBehaviourSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.profile = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = @"Resign behaviour";
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
    case ResignThresholdSection:
      return MaxResignThresholdSectionItem;
    case ResignMinGamesSection:
      return MaxResignMinGamesSectionItem;
    case ResetToDefaultsSection:
      return MaxResetToDefaultsSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case ResignThresholdSection:
      return @"Resign threshold";
    case ResignMinGamesSection:
      return @"Minimum number of games";
    default:
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case ResignThresholdSection:
      return @"The computer player resigns if the quality of the best move it could find is below this threshold. Lower thresholds make the computer less likely to resign (for instance, the computer will never resign when the threshold is 0%).";
    case ResignMinGamesSection:
      return @"Minimum number of playout games that the computer must calculate before it is allowed to use the resign threshold (see above) to make a decision about resigning. It is recommended that you leave 'Auto-select' turned on and do NOT manually adjust this value. The reason: If this value becomes higher than the 'Max. games' value in the profile's 'Playing strength' settings, the computer will NEVER resign.";
      break;
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
    case ResignThresholdSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      enum GoBoardSize boardSize = (GoBoardSizeMin + 2 * indexPath.row);
      cell.textLabel.text = [NSString stringWithFormat:@"%dx%d boards", boardSize, boardSize];
      int resignThreshold = [self.profile resignThresholdForBoardSize:boardSize];
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%d%%", resignThreshold];
      // The following properties must be set because of cell reuse, and because
      // ResignMinGamesItem may change them to non-standard values
      cell.detailTextLabel.textColor = [UIColor slateBlueColor];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      break;
    }
    case ResignMinGamesSection:
    {
      switch (indexPath.row)
      {
        case AutoSelectResignMinGamesItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Auto-select";
          accessoryView.on = self.profile.autoSelectFuegoResignMinGames;
          [accessoryView addTarget:self action:@selector(toggleAutoSelect:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        case ResignMinGamesItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Minimum games";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%llu", self.profile.fuegoResignMinGames];
          if (self.profile.autoSelectFuegoResignMinGames)
          {
            cell.detailTextLabel.textColor = [UIColor grayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
          }
          else
          {
            cell.detailTextLabel.textColor = [UIColor slateBlueColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
          }
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    case ResetToDefaultsSection:
    {
      cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
      cell.textLabel.text = @"Reset to default values";
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

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (ResignThresholdSection == indexPath.section)
  {
    SliderInputController* controller = [[[SliderInputController alloc] init] autorelease];
    controller.context = indexPath;
    controller.delegate = self;
    controller.title = @"Resign threshold";
    controller.descriptionLabelText = @"Resign threshold (in %)";
    enum GoBoardSize boardSize = GoBoardSizeMin + 2 * indexPath.row;
    int resignThreshold = [self.profile resignThresholdForBoardSize:boardSize];
    controller.value = resignThreshold;
    controller.minimumValue = 0;
    controller.maximumValue = 100;
    [self.navigationController pushViewController:controller animated:YES];
  }
  else if (ResignMinGamesSection == indexPath.section)
  {
    if (ResignMinGamesItem == indexPath.row)
    {
      NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
      formatter.numberStyle = NSNumberFormatterDecimalStyle;
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      for (int resignMinGamesCategoryIndex = 0; resignMinGamesCategoryIndex < MaxResignMinGamesCategory; ++resignMinGamesCategoryIndex)
      {
        unsigned long long resignMinGames = [self resignMinGames:resignMinGamesCategoryIndex];
        NSString* resignMinGamesCategory = [formatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:resignMinGames]];
        [itemList addObject:resignMinGamesCategory];
      }
      int indexOfDefaultResignMinGamesCategory = [self resignMinGamesCategory:self.profile.fuegoResignMinGames];
      if (UndefinedResignMinGamesCategory == indexOfDefaultResignMinGamesCategory)
        indexOfDefaultResignMinGamesCategory = -1;
      UIViewController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                 title:@"Resign min. games"
                                                                    indexOfDefaultItem:indexOfDefaultResignMinGamesCategory
                                                                              delegate:self];
      UINavigationController* navigationController = [[UINavigationController alloc]
                                                      initWithRootViewController:modalController];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      [self presentViewController:navigationController animated:YES completion:nil];
      [navigationController release];
    }
  }
  else if (ResetToDefaultsSection == indexPath.section)
  {
    // TODO iPad: Modify this to not include a cancel button (see HIG).
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Reset to default values"
                                                    otherButtonTitles:nil];
    // The acton sheet must be shown based on the cell, not the table view,
    // otherwise buttons in the sheet cannot be properly tapped.
    [actionSheet showInView:[tableView cellForRowAtIndexPath:indexPath]];
    [actionSheet release];
  }
}

#pragma mark - SliderInputDelegate overrides

// -----------------------------------------------------------------------------
/// @brief SliderInputDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didDismissSliderInputController:(SliderInputController*)controller
{
  NSIndexPath* indexPath = controller.context;
  enum GoBoardSize boardSize = GoBoardSizeMin + 2 * indexPath.row;
  int newResignThreshold = controller.value;
  int oldResignThreshold = [self.profile resignThresholdForBoardSize:boardSize];
  if (oldResignThreshold != newResignThreshold)
  {
    [self.profile setResignThreshold:newResignThreshold forBoardSize:boardSize];
    [self.delegate didChangeResignBehaviour:self];
    NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationNone];
  }
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (controller.indexOfDefaultItem != controller.indexOfSelectedItem)
    {
      self.profile.fuegoResignMinGames = [self resignMinGames:controller.indexOfSelectedItem];
      NSUInteger sectionIndex = ResignMinGamesSection;
      NSUInteger rowIndex = ResignMinGamesItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate overrides

// -----------------------------------------------------------------------------
/// @brief Reacts to the user selecting an action from the action sheet
/// displayed when the "Reset to default values" button was tapped.
// -----------------------------------------------------------------------------
- (void) actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (actionSheet.cancelButtonIndex != buttonIndex)
  {
    [self.profile resetResignBehaviourPropertiesToDefaultValues];
    [self.delegate didChangeResignBehaviour:self];
    self.profile.autoSelectFuegoResignMinGames = autoSelectFuegoResignMinGamesDefault;
    if (! self.profile.autoSelectFuegoResignMinGames)
      self.profile.fuegoResignMinGames = fuegoResignMinGamesDefault;
    [self.tableView reloadData];
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Ponder" switch. Updates the profile
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleAutoSelect:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.autoSelectFuegoResignMinGames = accessoryView.on;

  NSUInteger sectionIndex = ResignMinGamesSection;
  NSUInteger rowIndex = ResignMinGamesItem;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a natural number corresponding to the enumeration value
/// @a resignMinGamesCategory.
///
/// Raises an @e NSInvalidArgumentException if @a resignMinGamesCategory is not
/// recognized.
// -----------------------------------------------------------------------------
- (unsigned long long) resignMinGames:(enum ResignMinGamesCategory)resignMinGamesCategory
{
  switch (resignMinGamesCategory)
  {
    case Game0ResignMinGamesCategory:
      return 0;
    case Game9ResignMinGamesCategory:
      return 9;
    case Game99ResignMinGamesCategory:
      return 99;
    case Game450ResignMinGamesCategory:
      return 450;
    case Game950ResignMinGamesCategory:
      return 950;
    case Game1950ResignMinGamesCategory:
      return 1950;
    case Game4950ResignMinGamesCategory:
      return 4950;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid 'max. games' category: %d", resignMinGamesCategory];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a category enumeration value that corresponds to the natural
/// number @a resignMingames. Returns #UndefinedResignMinGamesCategory if there
/// is no corresponding category.
// -----------------------------------------------------------------------------
- (enum ResignMinGamesCategory) resignMinGamesCategory:(unsigned long long)resignMingames
{
  switch (resignMingames)
  {
    case 0:
      return Game0ResignMinGamesCategory;
    case 9:
      return Game9ResignMinGamesCategory;
    case 99:
      return Game99ResignMinGamesCategory;
    case 450:
      return Game450ResignMinGamesCategory;
    case 950:
      return Game950ResignMinGamesCategory;
    case 1950:
      return Game1950ResignMinGamesCategory;
    case 4950:
      return Game4950ResignMinGamesCategory;
    default:
      return UndefinedResignMinGamesCategory;
  }
}

@end
