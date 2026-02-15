// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "TimedPlaySettingsController.h"
#import "../main/ModelProvider.h"
#import "../main/Registry.h"
#import "../play/model/TimedPlayModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UIViewControllerAdditions.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Timed Play" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum TimedPlayTableViewSection
{
  AutostartClockSection,
  ClockInteractionSection,
  TimeDataValidationSection,
  InvalidTimeSystemSection,
  MaxSection,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the AutostartClockSection.
// -----------------------------------------------------------------------------
enum AutostartClockSectionItem
{
  AutostartPlayerClockForNewGamesItem,
  AutostartPlayerClockForArchiveGamesItem,
  AutostartPlayerClockWhenTurnBeginsItem,
  MaxAutostartClockSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ClockInteractionSection.
// -----------------------------------------------------------------------------
enum ClockInteractionSectionItem
{
  CanUserSuspendPlayerClocksItem,
  MaxClockInteractionSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TimeDataValidationSection.
// -----------------------------------------------------------------------------
enum TimeDataValidationSectionItem
{
  TimeDataValidationModeItem,
  MaxTimeDataValidationSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the InvalidTimeSystemSection.
// -----------------------------------------------------------------------------
enum InvalidTimeSystemSectionItem
{
  ShowClockViewForCustomTimeSystemItem,
  MaxInvalidTimeSystemSectionItem,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// TimedPlaySettingsController.
// -----------------------------------------------------------------------------
@interface TimedPlaySettingsController()
@property(nonatomic, assign) TimedPlayModel* timedPlayModel;
@end


@implementation TimedPlaySettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TimedPlaySettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (TimedPlaySettingsController*) controller
{
  TimedPlaySettingsController* controller = [[TimedPlaySettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.timedPlayModel = [Registry sharedRegistry].modelProvider.timedPlayModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimedPlaySettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.timedPlayModel = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Timed play settings";
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
    case AutostartClockSection:
      return MaxAutostartClockSectionItem;
    case ClockInteractionSection:
      return MaxClockInteractionSectionItem;
    case TimeDataValidationSection:
      return MaxTimeDataValidationSectionItem;
    case InvalidTimeSystemSection:
      return MaxInvalidTimeSystemSectionItem;
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
    case AutostartClockSection:
      return @"These settings control in which scenarios the app should automatically start the clock of a human player. When a setting is turned off, the app suspends the human player's clock instead of starting it, allowing the human player to start the clock when they are ready for it (tapping the suspended clock starts it).\n\nNote: Computer players' clocks are not affected by these settings because computer players are always ready, i.e. they always start thinking immediately when it is their turn.";
    case ClockInteractionSection:
      return @"When this setting is turned on, you can tap the clock of the player whose turn it is to suspend that player's clock. Tapping the suspended clock again resumes time keeping. Because suspending the clock could be viewed as 'cheating', it is possible to turn this feature off.\n\nNote: Independent of this setting, the app automatically suspends the clock when you receive a phone call, or when you are otherwise prevented to play a move in time (e.g. when switching tabs).";
    case TimeDataValidationSection:
      return @"When you load a game from the archive the app validates the time data it finds in the game record. Here you can select how strict the checks should be. This can be useful when you load games from the archive that were recorded by other Go programs.\n\nNote: Changing this setting has no effect on the current game.";
    case InvalidTimeSystemSection:
      return @"When you load a game from the archive and the time data validation routine detects a problem with one of the recorded time systems (e.g. a custom time system for which this app does not understand the rules), the clock view will inform you about the reason but it will not let you use the clock. If you don't find the information useful, you can select here to not show the clock view at all.";
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
    case AutostartClockSection:
    {
      if (indexPath.row == AutostartPlayerClockForNewGamesItem)
      {
        cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
        UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
        cell.textLabel.text = @"Autostart clock when starting a new game";
        cell.textLabel.numberOfLines = 0;
        accessoryView.on = self.timedPlayModel.autostartPlayerClockForNewGames;
        [accessoryView removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
        [accessoryView addTarget:self action:@selector(toggleAutostartPlayerClockForNewGames:) forControlEvents:UIControlEventValueChanged];
      }
      else if (indexPath.row == AutostartPlayerClockForArchiveGamesItem)
      {
        cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
        UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
        cell.textLabel.text = @"Autostart clock when loading a game from the archive";
        cell.textLabel.numberOfLines = 0;
        accessoryView.on = self.timedPlayModel.autostartPlayerClockForArchiveGames;
        [accessoryView removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
        [accessoryView addTarget:self action:@selector(toggleAutostartPlayerClockForArchiveGames:) forControlEvents:UIControlEventValueChanged];
      }
      else
      {
        cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
        UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
        cell.textLabel.text = @"Autostart clock when turn begins";
        cell.textLabel.numberOfLines = 0;
        accessoryView.on = self.timedPlayModel.autostartPlayerClockWhenTurnBegins;
        [accessoryView removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
        [accessoryView addTarget:self action:@selector(toggleAutostartPlayerClockWhenTurnBegins:) forControlEvents:UIControlEventValueChanged];
      }
      break;
    }
    case ClockInteractionSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Tap suspends clock";
      cell.textLabel.numberOfLines = 1;
      accessoryView.on = self.timedPlayModel.canUserSuspendPlayerClocks;
      [accessoryView removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
      [accessoryView addTarget:self action:@selector(toggleCanUserSuspendPlayerClocks:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case TimeDataValidationSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Time data validation mode";
      cell.detailTextLabel.text = [self timeDataValidationModeName:self.timedPlayModel.timeDataValidationMode];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case InvalidTimeSystemSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Hide clock view when time data validation finds a problem with one of the time systems";
      cell.textLabel.numberOfLines = 0;
      accessoryView.on = self.timedPlayModel.hidePlayerClockViewForInvalidTimeSystems;
      [accessoryView removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
      [accessoryView addTarget:self action:@selector(toggleHidePlayerClockViewForInvalidTimeSystems:) forControlEvents:UIControlEventValueChanged];
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

  if (TimeDataValidationSection == indexPath.section)
  {
    NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
    [itemList addObject:[self timeDataValidationModeName:GoTimeDataValidationModeBasic]];
    [itemList addObject:[self timeDataValidationModeName:GoTimeDataValidationModeNormal]];
    [itemList addObject:[self timeDataValidationModeName:GoTimeDataValidationModeStrict]];

    int indexOfDefaultTimeDataValidationMode;
    switch (self.timedPlayModel.timeDataValidationMode)
    {
      case GoTimeDataValidationModeBasic:
        indexOfDefaultTimeDataValidationMode = 0;
        break;
      case GoTimeDataValidationModeNormal:
        indexOfDefaultTimeDataValidationMode = 1;
        break;
      case GoTimeDataValidationModeStrict:
        indexOfDefaultTimeDataValidationMode = 2;
        break;
      default:
        indexOfDefaultTimeDataValidationMode = -1;
        break;
    }

    NSString* screenTitle = @"Time data validation mode";
    ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                  screenTitle:screenTitle
                                                                           indexOfDefaultItem:indexOfDefaultTimeDataValidationMode
                                                                                     delegate:self];
    itemPickerController.context = indexPath;
    [self presentNavigationControllerWithRootViewController:itemPickerController];
  }
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)itemPickerController didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (itemPickerController.indexOfDefaultItem != itemPickerController.indexOfSelectedItem)
    {
      switch (itemPickerController.indexOfSelectedItem)
      {
        case 0:
          self.timedPlayModel.timeDataValidationMode = GoTimeDataValidationModeBasic;
          break;
        case 1:
          self.timedPlayModel.timeDataValidationMode = GoTimeDataValidationModeNormal;
          break;
        case 2:
          self.timedPlayModel.timeDataValidationMode = GoTimeDataValidationModeStrict;
          break;
        default:
          assert(0);
          break;
      }

      NSArray* indexPaths = [NSArray arrayWithObject:itemPickerController.context];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Autostart player clock for new games"
/// switch. Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAutostartPlayerClockForNewGames:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.timedPlayModel.autostartPlayerClockForNewGames = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Autostart player clock for archive
/// games" switch. Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAutostartPlayerClockForArchiveGames:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.timedPlayModel.autostartPlayerClockForArchiveGames = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Autostart player clock when turn
/// begins" switch. Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAutostartPlayerClockWhenTurnBegins:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.timedPlayModel.autostartPlayerClockWhenTurnBegins = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Can user suspend player clocks"
/// switch. Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleCanUserSuspendPlayerClocks:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.timedPlayModel.canUserSuspendPlayerClocks = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Show player clock view for custom
/// time system" switch. Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleHidePlayerClockViewForInvalidTimeSystems:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.timedPlayModel.hidePlayerClockViewForInvalidTimeSystems = accessoryView.on;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a timeDataValidationMode that is
/// suitable for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a timeDataValidationMode is not
/// recognized.
// -----------------------------------------------------------------------------
- (NSString*) timeDataValidationModeName:(enum GoTimeDataValidationMode)timeDataValidationMode
{
  switch (timeDataValidationMode)
  {
    case GoTimeDataValidationModeBasic:
      return @"Basic";
    case GoTimeDataValidationModeNormal:
      return @"Normal";
    case GoTimeDataValidationModeStrict:
      return @"Strict";
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Unsupported time data validation mode %d" argumentValue:timeDataValidationMode];
      return nil;
  }
}

@end
