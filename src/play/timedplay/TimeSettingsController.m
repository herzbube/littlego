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
#import "TimeSettingsController.h"
#import "../model/TimeSettingsModel.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewSliderCell.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"


// Arbitrarily chosen maximum values
static const double maximumDurationInSeconds = 43200; // 12 hours
static const unsigned long maximumNumberOfMovesOrPeriods = 1000;

struct CompositeDuration
{
  int numberOfHours;
  int numberOfMinutes;
  int numberOfSeconds;
};
typedef struct CompositeDuration CompositeDuration;


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Time Settings" table view.
// -----------------------------------------------------------------------------
enum TimeSettingsTableViewSection
{
  TimedPlayEnabledSection,
  AbsoluteTimeSystemSection,
  PeriodBasedTimeSystemSection,
  PeriodBasedTimeSystemParametersSection,
  MaxSection,
  MaxSection_TimedPlayDisabled = TimedPlayEnabledSection + 1,
  MaxSection_PeriodBasedTimeSystemDisabled = PeriodBasedTimeSystemSection + 1,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TimedPlayEnabledSection.
// -----------------------------------------------------------------------------
enum TimedPlayEnabledSectionItem
{
  TimedPlayEnabledItem,
  MaxTimedPlayEnabledSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the AbsoluteTimeSystemSection.
// -----------------------------------------------------------------------------
enum AbsoluteTimeSystemSectionItem
{
  AbsoluteTimingEnabledItem,
  AbsoluteTimingDurationInSecondsItem,
  MaxAbsoluteTimeSystemSectionItem,
  MaxAbsoluteTimeSystemSectionItem_AbsoluteTimingDisabled = AbsoluteTimingEnabledItem + 1,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PeriodBasedTimeSystemSection.
// -----------------------------------------------------------------------------
enum PeriodBasedTimeSystemSectionItem
{
  PeriodBasedTimeSystemEnabledItem,
  PeriodBasedTimeSystemTypeItem,
  MaxPeriodBasedTimeSystemSectionItem,
  MaxPeriodBasedTimeSystemSectionItem_PeriodBasedTimeSystemDisabled = PeriodBasedTimeSystemEnabledItem + 1,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PeriodBasedTimeSystemParametersSection.
// -----------------------------------------------------------------------------
enum PeriodBasedTimeSystemParametersSectionItem
{
  PeriodDurationInSecondsItem,  // also used for fischerTimingInitialTimeDurationInSeconds
  NumberOfMovesOrPeriodsItem,   // also used for fischerTimingExtraTimeDurationInSeconds
  MaxPeriodBasedTimeSystemParametersSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates period-based time systems that can be shown in
/// #CellIdFischerTimingExtraTimeDurationInSeconds.
// -----------------------------------------------------------------------------
enum PeriodBasedTimeSystemType
{
  PeriodBasedTimeSystemTypeCanadian,
  PeriodBasedTimeSystemTypeJapanese,
  PeriodBasedTimeSystemTypeFischer,
  PeriodBasedTimeSystemTypeSteadyAverage,
  PeriodBasedTimeSystemTypeTotalAverage,
  PeriodBasedTimeSystemTypeMax,
  PeriodBasedTimeSystemTypeUndefined,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TimeSettingsController.
// -----------------------------------------------------------------------------
@interface TimeSettingsController()
@property(nonatomic, retain) TimeSettingsModel* timeSettingsModel;
@property(nonatomic, assign) bool readonlyMode;
@end


// -----------------------------------------------------------------------------
/// @brief Enumerates all table view cells that can ever appear in the
/// "Time Settings" table view, without regard to the conditions under which
/// they appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// nested switch/if statements.
// -----------------------------------------------------------------------------
enum CellId
{
  CellIdTimedPlayEnabled,
  CellIdAbsoluteTimingEnabled,
  CellIdAbsoluteTimingDurationInSeconds,
  CellIdPeriodBasedTimeSystemEnabled,
  CellIdPeriodBasedTimeSystemType,
  CellIdCanadianTimingPeriodDurationInSeconds,
  CellIdCanadianTimingNumberOfMoves,
  CellIdJapaneseTimingPeriodDurationInSeconds,
  CellIdJapaneseTimingNumberOfPeriods,
  CellIdFischerTimingInitialTimeDurationInSeconds,
  CellIdFischerTimingExtraTimeDurationInSeconds,
  CellIdSteadyAverageTimingPeriodDurationInSeconds,
  CellIdSteadyAverageTimingNumberOfMoves,
  CellIdTotalAverageTimingPeriodDurationInSeconds,
  CellIdTotalAverageTimingNumberOfMoves,
};

@implementation TimeSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a TimeSettingsController object. The user can view and
/// change the values in @a timeSettingsModel.
///
/// @note This is the designated initializer of TimeSettingsController.
// -----------------------------------------------------------------------------
- (id) initWithTimeSettingsModel:(TimeSettingsModel*)timeSettingsModel
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;

  self.timeSettingsModel = timeSettingsModel;
  self.readonlyMode = false;
  self.navigationItem.title = @"Select time settings";

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimeSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (! self.timeSettingsModel.timedPlayEnabled)
    return MaxSection_TimedPlayDisabled;
  else if (! self.timeSettingsModel.periodBasedTimeSystemEnabled)
    return MaxSection_PeriodBasedTimeSystemDisabled;
  else
    return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case TimedPlayEnabledSection:
    {
      return MaxTimedPlayEnabledSectionItem;
    }
    case AbsoluteTimeSystemSection:
    {
      if (self.timeSettingsModel.absoluteTimingEnabled)
        return MaxAbsoluteTimeSystemSectionItem;
      else
        return MaxAbsoluteTimeSystemSectionItem_AbsoluteTimingDisabled;
    }
    case PeriodBasedTimeSystemSection:
    {
      if (self.timeSettingsModel.periodBasedTimeSystemEnabled)
        return MaxPeriodBasedTimeSystemSectionItem;
      else
        return MaxPeriodBasedTimeSystemSectionItem_PeriodBasedTimeSystemDisabled;
    }
    case PeriodBasedTimeSystemParametersSection:
    {
      return MaxPeriodBasedTimeSystemParametersSectionItem;
    }
    default:
    {
      assert(0);
      break;
    }
  }

  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
// TODO xxx
//- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
//{
//  switch (section)
//  {
//    case DiscardMyLastMoveSection:
//      return @"When you discard the computer player's last move this also discards your own last move, so that you can then immediately play again and try out a different move. Turn this option off to only discard a single last move, regardless of who made that move. Note: This option only affects computer vs. human games.";
//    case DiscardFutureNodesAlertSection:
//      return @"When you are viewing a board position in the middle of the current game variation, some actions (e.g. discard the current node) will discard all nodes after this position. If this option is turned off you will NOT be alerted that this is going to happen.";
//    default:
//      break;
//  }
//  return nil;
//}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  enum CellId cellId = [self cellIdForIndexPath:indexPath];
  UITableViewCell* cell = [self createCellWithCellId:cellId
                                        forTableView:tableView
                                   forRowAtIndexPath:indexPath];
  [self configureCell:cell
           withCellId:cellId];
  return cell;
}

#pragma mark - Private helper for tableView:cellForRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) createCellWithCellId:(enum CellId)cellId
                             forTableView:(UITableView*)tableView
                        forRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;

  switch (cellId)
  {
    case CellIdTimedPlayEnabled:
    case CellIdAbsoluteTimingEnabled:
    case CellIdPeriodBasedTimeSystemEnabled:
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      break;
    case CellIdAbsoluteTimingDurationInSeconds:
    case CellIdCanadianTimingPeriodDurationInSeconds:
    case CellIdJapaneseTimingPeriodDurationInSeconds:
    case CellIdFischerTimingInitialTimeDurationInSeconds:
    case CellIdFischerTimingExtraTimeDurationInSeconds:
    case CellIdSteadyAverageTimingPeriodDurationInSeconds:
    case CellIdTotalAverageTimingPeriodDurationInSeconds:
      cell = [TableViewCellFactory cellWithType:SliderWithValueLabelAndStepperCellType tableView:tableView];
      break;
    case CellIdCanadianTimingNumberOfMoves:
    case CellIdJapaneseTimingNumberOfPeriods:
    case CellIdSteadyAverageTimingNumberOfMoves:
    case CellIdTotalAverageTimingNumberOfMoves:
      cell = [TableViewCellFactory cellWithType:SliderWithValueLabelCellType tableView:tableView];
      break;
    case CellIdPeriodBasedTimeSystemType:
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      break;
    default:
      break;
  }

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) configureCell:(UITableViewCell*)cell
            withCellId:(enum CellId)cellId
{
  switch (cellId)
  {
    case CellIdTimedPlayEnabled:
    {
      cell.textLabel.text = @"Use timed play";
      [self configureSwitchCell:cell
                      withValue:self.timeSettingsModel.timedPlayEnabled
                         action:@selector(toggleTimedPlayEnabled:)];
      break;
    }
    case CellIdAbsoluteTimingEnabled:
    {
      cell.textLabel.text = @"Use main time";
      [self configureSwitchCell:cell
                      withValue:self.timeSettingsModel.absoluteTimingEnabled
                         action:@selector(toggleAbsoluteTimingEnabled:)];
      break;
    }
    case CellIdAbsoluteTimingDurationInSeconds:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Main time";
      [self configureSliderCell:sliderCell
          withDurationInSeconds:self.timeSettingsModel.absoluteTimingDurationInSeconds
           actionValueDidChange:@selector(absoluteTimingDurationInSecondsDidChange:)];
      break;
    }
    case CellIdPeriodBasedTimeSystemEnabled:
    {
      cell.textLabel.text = @"Use overtime";
      [self configureSwitchCell:cell
                      withValue:self.timeSettingsModel.periodBasedTimeSystemEnabled
                         action:@selector(togglePeriodBasedTimeSystemEnabled:)];
      break;
    }
    case CellIdPeriodBasedTimeSystemType:
    {
      cell.textLabel.text = @"Time system";
      cell.detailTextLabel.text = [NSString stringWithPeriodBasedTimeSystemType:self.timeSettingsModel.periodBasedTimeSystemType];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case CellIdCanadianTimingPeriodDurationInSeconds:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Overtime";
      [self configureSliderCell:sliderCell
          withDurationInSeconds:self.timeSettingsModel.canadianTimingPeriodDurationInSeconds
           actionValueDidChange:@selector(canadianTimingPeriodDurationInSecondsDidChange:)];
      break;
    }
    case CellIdCanadianTimingNumberOfMoves:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Moves";
      [self configureSliderCell:sliderCell
     withNumberOfMovesOrPeriods:self.timeSettingsModel.canadianTimingNumberOfMoves
           actionValueDidChange:@selector(canadianTimingNumberOfMovesDidChange:)];
      break;
    }
    case CellIdJapaneseTimingPeriodDurationInSeconds:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Period duration";
      [self configureSliderCell:sliderCell
          withDurationInSeconds:self.timeSettingsModel.japaneseTimingPeriodDurationInSeconds
           actionValueDidChange:@selector(japaneseTimingPeriodDurationInSecondsDidChange:)];
      break;
    }
    case CellIdJapaneseTimingNumberOfPeriods:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Time periods";
      [self configureSliderCell:sliderCell
     withNumberOfMovesOrPeriods:self.timeSettingsModel.japaneseTimingNumberOfPeriods
           actionValueDidChange:@selector(japaneseTimingNumberOfPeriodsDidChange:)];
      break;
    }
    case CellIdFischerTimingInitialTimeDurationInSeconds:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Initial time";
      [self configureSliderCell:sliderCell
          withDurationInSeconds:self.timeSettingsModel.fischerTimingInitialTimeDurationInSeconds
           actionValueDidChange:@selector(fischerTimingInitialTimeDurationInSecondsDidChange:)];
      break;
    }
    case CellIdFischerTimingExtraTimeDurationInSeconds:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Extra time";
      [self configureSliderCell:sliderCell
          withDurationInSeconds:self.timeSettingsModel.fischerTimingExtraTimeDurationInSeconds
           actionValueDidChange:@selector(fischerTimingExtraTimeDurationInSecondsDidChange:)];
      break;
    }
    case CellIdSteadyAverageTimingPeriodDurationInSeconds:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Overtime";
      [self configureSliderCell:sliderCell
          withDurationInSeconds:self.timeSettingsModel.steadyAverageTimingPeriodDurationInSeconds
           actionValueDidChange:@selector(steadyAverageTimingPeriodDurationInSecondsDidChange:)];
      break;
    }
    case CellIdSteadyAverageTimingNumberOfMoves:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Moves";
      [self configureSliderCell:sliderCell
     withNumberOfMovesOrPeriods:self.timeSettingsModel.steadyAverageTimingNumberOfMoves
           actionValueDidChange:@selector(steadyAverageTimingNumberOfMovesDidChange:)];
      break;
    }
    case CellIdTotalAverageTimingPeriodDurationInSeconds:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Overtime";
      [self configureSliderCell:sliderCell
          withDurationInSeconds:self.timeSettingsModel.totalAverageTimingPeriodDurationInSeconds
           actionValueDidChange:@selector(totalAverageTimingPeriodDurationInSecondsDidChange:)];
      break;
    }
    case CellIdTotalAverageTimingNumberOfMoves:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Moves";
      [self configureSliderCell:sliderCell
     withNumberOfMovesOrPeriods:self.timeSettingsModel.totalAverageTimingNumberOfMoves
           actionValueDidChange:@selector(totalAverageTimingNumberOfMovesDidChange:)];
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for configureCell:withCellId:().
// -----------------------------------------------------------------------------
- (void) configureSwitchCell:(UITableViewCell*)switchCell
                   withValue:(bool)value
                      action:(SEL)action
{
  UISwitch* accessoryView = (UISwitch*)switchCell.accessoryView;
  accessoryView.on = value ? YES : NO;
  [accessoryView removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
  [accessoryView addTarget:self action:action forControlEvents:UIControlEventValueChanged];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for configureCell:withCellId:().
// -----------------------------------------------------------------------------
- (void) configureSliderCell:(TableViewSliderCell*)sliderCell
       withDurationInSeconds:(double)durationInSeconds
        actionValueDidChange:(SEL)actionValueDidChange
{
  [sliderCell setDelegate:self
     actionValueDidChange:actionValueDidChange
           valueFormatter:@selector(stringForSliderCellValue:)];

  int sliderCellValue = [self sliderCellValueFromDurationInSeconds:durationInSeconds];
  int sliderCellMaximumValue = [self sliderCellMaximumValue];

  [sliderCell setValue:sliderCellValue
          minimumValue:1.0
          maximumValue:sliderCellMaximumValue];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for configureCell:withCellId:().
// -----------------------------------------------------------------------------
- (void) configureSliderCell:(TableViewSliderCell*)sliderCell
  withNumberOfMovesOrPeriods:(unsigned long)numberOfMovesOrPeriods
        actionValueDidChange:(SEL)actionValueDidChange
{
  [sliderCell setDelegate:self
     actionValueDidChange:actionValueDidChange
           valueFormatter:@selector(stringForNumberOfMovesOrPeriods:)];

  [sliderCell setValue:(int)numberOfMovesOrPeriods
          minimumValue:1.0
          maximumValue:maximumNumberOfMovesOrPeriods];
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  enum CellId cellId = [self cellIdForIndexPath:indexPath];
  if (cellId == CellIdPeriodBasedTimeSystemType)
  {
    NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
    for (int periodBasedTimeSystemTypeIndex = 0;
         periodBasedTimeSystemTypeIndex < PeriodBasedTimeSystemTypeMax;
         periodBasedTimeSystemTypeIndex++)
    {
      [itemList addObject:[self stringWithPeriodBasedTimeSystemType:periodBasedTimeSystemTypeIndex]];
    }

    int indexOfDefaultTimeSystem = [self periodBasedTimeSystemType:self.timeSettingsModel.periodBasedTimeSystemType];
    if (PeriodBasedTimeSystemTypeUndefined == indexOfDefaultTimeSystem)
      indexOfDefaultTimeSystem = -1;

    UIViewController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                         screenTitle:@"Select overtime time system"
                                                                  indexOfDefaultItem:indexOfDefaultTimeSystem
                                                                            delegate:self];
    [self presentNavigationControllerWithRootViewController:modalController];
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Used timed play" switch.
// -----------------------------------------------------------------------------
- (void) toggleTimedPlayEnabled:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.timeSettingsModel.timedPlayEnabled = accessoryView.on;

  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Use main time" switch.
// -----------------------------------------------------------------------------
- (void) toggleAbsoluteTimingEnabled:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.timeSettingsModel.absoluteTimingEnabled = accessoryView.on;

  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:AbsoluteTimeSystemSection];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Main time" slider.
// -----------------------------------------------------------------------------
- (void) absoluteTimingDurationInSecondsDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.absoluteTimingDurationInSeconds = [self durationInSecondsFromSliderCellValue:sliderCell.value];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Use overtime" switch.
// -----------------------------------------------------------------------------
- (void) togglePeriodBasedTimeSystemEnabled:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.timeSettingsModel.periodBasedTimeSystemEnabled = accessoryView.on;

  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Period duration"
/// slider while Canadian Timing is selected.
// -----------------------------------------------------------------------------
- (void) canadianTimingPeriodDurationInSecondsDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.canadianTimingPeriodDurationInSeconds = [self durationInSecondsFromSliderCellValue:sliderCell.value];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Number of moves"
/// slider while Canadian Timing is selected.
// -----------------------------------------------------------------------------
- (void) canadianTimingNumberOfMovesDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.canadianTimingNumberOfMoves = sliderCell.value;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Period duration"
/// slider while Japanese Timing is selected.
// -----------------------------------------------------------------------------
- (void) japaneseTimingPeriodDurationInSecondsDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.japaneseTimingPeriodDurationInSeconds = [self durationInSecondsFromSliderCellValue:sliderCell.value];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Number of periods"
/// slider while Japanese Timing is selected.
// -----------------------------------------------------------------------------
- (void) japaneseTimingNumberOfPeriodsDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.japaneseTimingNumberOfPeriods = sliderCell.value;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Initial time"
/// slider while Fischer Timing is selected.
// -----------------------------------------------------------------------------
- (void) fischerTimingInitialTimeDurationInSecondsDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.fischerTimingInitialTimeDurationInSeconds = [self durationInSecondsFromSliderCellValue:sliderCell.value];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Extra time"
/// slider while Fischer Timing is selected.
// -----------------------------------------------------------------------------
- (void) fischerTimingExtraTimeDurationInSecondsDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.fischerTimingExtraTimeDurationInSeconds = [self durationInSecondsFromSliderCellValue:sliderCell.value];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Period duration"
/// slider while Steady Average Timing is selected.
// -----------------------------------------------------------------------------
- (void) steadyAverageTimingPeriodDurationInSecondsDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.steadyAverageTimingPeriodDurationInSeconds = [self durationInSecondsFromSliderCellValue:sliderCell.value];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Number of moves"
/// slider while Steady Average Timing is selected.
// -----------------------------------------------------------------------------
- (void) steadyAverageTimingNumberOfMovesDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.steadyAverageTimingNumberOfMoves = sliderCell.value;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Period duration"
/// slider while Total Average Timing is selected.
// -----------------------------------------------------------------------------
- (void) totalAverageTimingPeriodDurationInSecondsDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.totalAverageTimingPeriodDurationInSeconds = [self durationInSecondsFromSliderCellValue:sliderCell.value];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Number of moves"
/// slider while Total Average Timing is selected.
// -----------------------------------------------------------------------------
- (void) totalAverageTimingNumberOfMovesDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.timeSettingsModel.totalAverageTimingNumberOfMoves = sliderCell.value;
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
      self.timeSettingsModel.periodBasedTimeSystemType = [self goTimeSystemType:controller.indexOfSelectedItem];
      [self.tableView reloadData];
    }
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableViewSliderCell formatters

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of the int value encapsulated by
/// @a sliderCellValueAsNumber.
// -----------------------------------------------------------------------------
- (NSString*) stringForSliderCellValue:(NSNumber*)sliderCellValueAsNumber
{
  int sliderCellValue = [sliderCellValueAsNumber intValue];
  CompositeDuration compositeDuration = [self compositeDurationFromSliderCellValue:sliderCellValue];

  if (compositeDuration.numberOfHours == 0)
  {
    if (compositeDuration.numberOfMinutes == 0)
      return [self duration:compositeDuration.numberOfSeconds singularUnitName:@"second" pluralUnitName:@"seconds"];
    else if (compositeDuration.numberOfSeconds == 0)
      return [self duration:compositeDuration.numberOfMinutes singularUnitName:@"minute" pluralUnitName:@"minutes"];
    else
      return [NSString stringWithFormat:@"%d:%02d minutes", compositeDuration.numberOfMinutes, compositeDuration.numberOfSeconds];
  }
  else
  {
    if (compositeDuration.numberOfMinutes == 0)
      return [self duration:compositeDuration.numberOfHours singularUnitName:@"hour" pluralUnitName:@"hours"];
    else
      return [NSString stringWithFormat:@"%d:%02d hours", compositeDuration.numberOfHours, compositeDuration.numberOfMinutes];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a duration, using either the
/// singular or plural unit names depending on whether @a duration is 1 or
/// greater than 1.
// -----------------------------------------------------------------------------
- (NSString*) duration:(int)duration
      singularUnitName:(NSString*)singularUnitName
        pluralUnitName:(NSString*)pluralUnitName
{
  if (duration == 0)
    return nil;
  else
    return [NSString stringWithFormat:@"%d %@", duration, (duration == 1 ? singularUnitName : pluralUnitName)];
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a numberOfMovesOrPeriodsAsNumber.
// -----------------------------------------------------------------------------
- (NSString*) stringForNumberOfMovesOrPeriods:(NSNumber*)numberOfMovesOrPeriodsAsNumber
{
  return [NSString stringWithFormat:@"%d", [numberOfMovesOrPeriodsAsNumber intValue]];
}

#pragma mark - Converting between linear time and non-linear slider cell values

// -----------------------------------------------------------------------------
/// @brief Returns the maximum value that this controller allows the user to
/// select in a TableViewSliderCell.
// -----------------------------------------------------------------------------
- (int) sliderCellMaximumValue
{
  static int sliderCellMaximumValue = 0;
  if (sliderCellMaximumValue == 0)
  {
    if (maximumDurationInSeconds > gMaximumRemainingTimeInSeconds)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"maximumDurationInSeconds %f exceeds gMaximumRemainingTimeInSeconds %f",
                                maximumDurationInSeconds,
                                gMaximumRemainingTimeInSeconds];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }
    sliderCellMaximumValue = [self sliderCellValueFromDurationInSeconds:maximumDurationInSeconds];
  }

  return sliderCellMaximumValue;
}

// -----------------------------------------------------------------------------
/// @brief Converts @a durationInSeconds into a value that can be assigned to a
/// TableViewSliderCell that is displayed by this controller.
///
/// For each duration value in TimeSettingsModel, this controller displays a
/// TableViewSliderCell object that allows the user to change the duration
/// value.
/// - The minimum duration the user can select is 1 second.
/// - The maximum duration the user can select is 12 hours.
///
/// This controller manages the sliders in a way so that the slider axis is
/// @b not linear. Instead, the slider axis is divided into 3 distinct groups:
/// - Group 1
///   - The unit is "1 second", i.e. each value represents 1 second.
///   - The group is used for durations that range from 1 second to 600 seconds.
///   - The group encompasses 600 seconds, i.e. 10 minutes.
///   - The group has 600 values.
/// - Group 2
///   - The unit is "1 minute", i.e. each value represents 1 minute.
///   - The group is used for durations that range from 601 seconds to 6 hours.
///   - The group encompasses 350 minutes, i.e. 6 hours minus the 10 minutes
///     from group 1.
///   - The group has 350 values.
/// - Group 3
///   - The unit is "5 minutes", i.e. each value represents 5 minutes.
///   - The group is used for durations that range from 6 hours and 1 second
///     to 12 hours.
///   - The group encompasses 360 minutes, i.e. 6 hours.
///   - The group has 72 values.
///
/// In total the 3 groups have 600 + 350 + 72 = 1022 values.
///
/// @note Fractions are rounded up to the nearest integer. If
/// @a durationInSeconds is less than 1 second or more than 12 hours it is
/// adjusted to the respective minimum/maximum value. If @a durationInSeconds
/// does not correspond exactly to a value on the slider axis, then it is
/// rounded up to the next value.
// -----------------------------------------------------------------------------
- (int) sliderCellValueFromDurationInSeconds:(double)durationInSeconds
{
  if (durationInSeconds < 1)
    durationInSeconds = 1;
  else if (durationInSeconds > 43200)
    durationInSeconds = 43200;
  else
    durationInSeconds = ceil(durationInSeconds);

  if (durationInSeconds <= 600)
    return durationInSeconds;

  if (durationInSeconds <= 21600) // 6 hours
  {
    durationInSeconds -= 600;
    return 600 + ceil(durationInSeconds / 60);
  }

  durationInSeconds -= 21600;
  return 950 + ceil(durationInSeconds / 300);
}

// -----------------------------------------------------------------------------
/// @brief Converts @a sliderCellValue into a duration in seconds value that
/// can be assigned to one of the duration properties in TimeSettingsModel.
///
/// This method performs the reverse operation of
/// sliderCellValueFromDurationInSeconds:(). If
/// sliderCellValueFromDurationInSeconds:() performs rounding, the reverse
/// operation will not arrive at the original result.
// -----------------------------------------------------------------------------
- (double) durationInSecondsFromSliderCellValue:(int)sliderCellValue
{
  CompositeDuration compositeDuration = [self compositeDurationFromSliderCellValue:sliderCellValue];
  return [self durationInSecondsFromCompositeDuration:compositeDuration];
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of seconds that @a compositeDuration represents.
// -----------------------------------------------------------------------------
- (double) durationInSecondsFromCompositeDuration:(CompositeDuration)compositeDuration
{
  return (compositeDuration.numberOfSeconds +
          compositeDuration.numberOfMinutes * 60 +
          compositeDuration.numberOfHours * 3600);
}

// -----------------------------------------------------------------------------
/// @brief Converts @a sliderCellValue into a CompositeDuration.
///
/// This method performs the reverse operation of
/// sliderCellValueFromDurationInSeconds:(). If
/// sliderCellValueFromDurationInSeconds:() performs rounding, the reverse
/// operation will not arrive at the original result.
// -----------------------------------------------------------------------------
- (CompositeDuration) compositeDurationFromSliderCellValue:(int)sliderCellValue
{
  CompositeDuration compositeDuration;

  if (sliderCellValue <= 600)
  {
    compositeDuration.numberOfHours = 0;
    compositeDuration.numberOfMinutes = sliderCellValue / 60;
    compositeDuration.numberOfSeconds = sliderCellValue % 60;
  }
  else
  {
    int durationInMinutes;
    if (sliderCellValue <= 950)
      durationInMinutes = sliderCellValue - 600 + 10;
    else
      durationInMinutes = (sliderCellValue - 950) * 5 + 360;

    compositeDuration.numberOfHours = durationInMinutes / 60;
    compositeDuration.numberOfMinutes = durationInMinutes % 60;
    compositeDuration.numberOfSeconds = 0;
  }

  return compositeDuration;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a indexPath, taking
/// into account the values found in the TimeSettingsModel object with which
/// TimeSettingsController was initialized.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForIndexPath:(NSIndexPath*)indexPath
{
  switch (indexPath.section)
  {
    case TimedPlayEnabledSection:
    {
      return CellIdTimedPlayEnabled;
    }
    case AbsoluteTimeSystemSection:
    {
      switch (indexPath.row)
      {
        case AbsoluteTimingEnabledItem:
          return CellIdAbsoluteTimingEnabled;
        case AbsoluteTimingDurationInSecondsItem:
          return CellIdAbsoluteTimingDurationInSeconds;
        default:
          break;
      }
      break;
    }
    case PeriodBasedTimeSystemSection:
    {
      switch (indexPath.row)
      {
        case PeriodBasedTimeSystemEnabledItem:
          return CellIdPeriodBasedTimeSystemEnabled;
        case PeriodBasedTimeSystemTypeItem:
          return CellIdPeriodBasedTimeSystemType;
        default:
          break;
      }
      break;
    }
    case PeriodBasedTimeSystemParametersSection:
    {
      switch (indexPath.row)
      {
        case PeriodDurationInSecondsItem: // FischerInitialTimeDurationInSecondsItem
        {
          switch (self.timeSettingsModel.periodBasedTimeSystemType)
          {
            case GoTimeSystemTypeCanadian:
              return CellIdCanadianTimingPeriodDurationInSeconds;
            case GoTimeSystemTypeJapanese:
              return CellIdJapaneseTimingPeriodDurationInSeconds;
            case GoTimeSystemTypeFischer:
              return CellIdFischerTimingInitialTimeDurationInSeconds;
            case GoTimeSystemTypeSteadyAverage:
              return CellIdSteadyAverageTimingPeriodDurationInSeconds;
            case GoTimeSystemTypeTotalAverage:
              return CellIdTotalAverageTimingPeriodDurationInSeconds;
            default:
              break;
          }
          break;
        }
        case NumberOfMovesOrPeriodsItem: // FischerExtraTimeDurationInSeconds
        {
          switch (self.timeSettingsModel.periodBasedTimeSystemType)
          {
            case GoTimeSystemTypeCanadian:
              return CellIdCanadianTimingNumberOfMoves;
            case GoTimeSystemTypeJapanese:
              return CellIdJapaneseTimingNumberOfPeriods;
            case GoTimeSystemTypeFischer:
              return CellIdFischerTimingExtraTimeDurationInSeconds;
            case GoTimeSystemTypeSteadyAverage:
              return CellIdSteadyAverageTimingNumberOfMoves;
            case GoTimeSystemTypeTotalAverage:
              return CellIdTotalAverageTimingNumberOfMoves;
            default:
              break;
          }
          break;
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

  NSString* errorMessage = [NSString stringWithFormat:@"Cannot determine cell ID, indexPath.section = %ld, indexPath.row = %ld, period-based time system type: %d",
                            (long)indexPath.section,
                            (long)indexPath.row,
                            self.timeSettingsModel.periodBasedTimeSystemType];
  [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];

  // Dummy return to make compiler happy (compiler does not see that an
  // exception is thrown)
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief Returns a value from enumeration #GoTimeSystemType that corresponds
/// to @a periodBasedTimeSystemType.
///
/// Raises an @e NSInvalidArgumentException if @a periodBasedTimeSystemType is
/// not recognized.
// -----------------------------------------------------------------------------
- (enum GoTimeSystemType) goTimeSystemType:(enum PeriodBasedTimeSystemType)periodBasedTimeSystemType
{
  switch (periodBasedTimeSystemType)
  {
    case PeriodBasedTimeSystemTypeCanadian:
      return GoTimeSystemTypeCanadian;
    case PeriodBasedTimeSystemTypeJapanese:
      return GoTimeSystemTypeJapanese;
    case PeriodBasedTimeSystemTypeFischer:
      return GoTimeSystemTypeFischer;
    case PeriodBasedTimeSystemTypeSteadyAverage:
      return GoTimeSystemTypeSteadyAverage;
    case PeriodBasedTimeSystemTypeTotalAverage:
      return GoTimeSystemTypeTotalAverage;
    default:
      break;
  }

  NSString* errorMessage = [NSString stringWithFormat:@"Invalid period-based time system type: %d", periodBasedTimeSystemType];
  [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  // Dummy return to make compiler happy (compiler does not see that an
  // exception is thrown)
  return GoTimeSystemTypeNone;
}

// -----------------------------------------------------------------------------
/// @brief Returns a value from enumeration #PeriodBasedTimeSystemType that
/// corresponds to @a goTimeSystemType. Returns
/// #PeriodBasedTimeSystemTypeUndefined if @a goTimeSystemType is not a
/// period-based time system type.
// -----------------------------------------------------------------------------
- (enum PeriodBasedTimeSystemType) periodBasedTimeSystemType:(enum GoTimeSystemType)goTimeSystemType
{
  switch (goTimeSystemType)
  {
    case GoTimeSystemTypeCanadian:
      return PeriodBasedTimeSystemTypeCanadian;
    case GoTimeSystemTypeJapanese:
      return PeriodBasedTimeSystemTypeJapanese;
    case GoTimeSystemTypeFischer:
      return PeriodBasedTimeSystemTypeFischer;
    case GoTimeSystemTypeSteadyAverage:
      return PeriodBasedTimeSystemTypeSteadyAverage;
    case GoTimeSystemTypeTotalAverage:
      return PeriodBasedTimeSystemTypeTotalAverage;
    default:
      return PeriodBasedTimeSystemTypeUndefined;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a periodBasedTimeSystemType.
///
/// Raises an @e NSInvalidArgumentException if @a periodBasedTimeSystemType is
/// not recognized.
// -----------------------------------------------------------------------------
- (NSString*) stringWithPeriodBasedTimeSystemType:(enum PeriodBasedTimeSystemType)periodBasedTimeSystemType
{
  enum GoTimeSystemType goTimeSystemType = [self goTimeSystemType:periodBasedTimeSystemType];
  return [NSString stringWithPeriodBasedTimeSystemType:goTimeSystemType];
}

@end
