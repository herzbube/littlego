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
#import "InvalidTimeDataDetailViewController.h"
#import "../model/TimeSettingsModel.h"
#import "../timedplay/CompositeDuration.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeTimeData.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoTimeSettings.h"
#import "../../go/GoTimeSystem.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewVariableHeightCell.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/TimeDataUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Invalid time data details"
/// table view.
///
/// The following section combinations are possible:
/// - CustomPeriodBasedTimeSystemSection
/// - TimeSettingsSection
/// - MoveDataSection
/// - MoveDataSection + TimeDataSection
/// - TimeSettingsSection + MoveDataSection + TimeDataSection
/// - TimeSettingsSection + TimeDataSection
/// - TimeSettingsSection + TimeDataSection + PrecedingTimeDataSection
// -----------------------------------------------------------------------------
enum TimeSettingsTableViewSection
{
  InvalidReasonSection,
  CustomPeriodBasedTimeSystemSection,
  TimeSettingsSection,
  MoveDataSection,
  TimeDataSection,
  PrecedingTimeDataSection,

  CustomPeriodBasedTimeSystemSection_CustomPeriodBasedTimeSystemOnly = InvalidReasonSection + 1,
  MaxSection_CustomPeriodBasedTimeSystemOnly,

  TimeSettingsSection_TimeSettingsOnly = InvalidReasonSection + 1,
  MaxSection_TimeSettingsOnly,

  MoveDataSection_MoveDataOnly = InvalidReasonSection + 1,
  MaxSection_MoveDataOnly,

  MoveDataSection_MoveDataAndTimeData = InvalidReasonSection + 1,
  TimeDataSection_MoveDataAndTimeData,
  MaxSection_MoveDataAndTimeData,

  TimeSettingsSection_TimeSettingsAndTimeData = InvalidReasonSection + 1,
  TimeDataSection_TimeSettingsAndTimeData,
  MaxSection_TimeSettingsAndTimeData,

  TimeSettingsSection_TimeSettingsAndTimeDataAndPrecedingTimeData = InvalidReasonSection + 1,
  TimeDataSection_TimeSettingsAndTimeDataAndPrecedingTimeData,
  PrecedingTimeDataSection_TimeSettingsAndTimeDataAndPrecedingTimeData,
  MaxSection_TimeSettingsAndTimeDataAndPrecedingTimeData,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the InvalidReasonSection.
// -----------------------------------------------------------------------------
enum InvalidReasonSectionItem
{
  InvalidReasonItem,
  MaxInvalidReasonSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the CustomPeriodBasedTimeSystemSection.
// -----------------------------------------------------------------------------
enum CustomPeriodBasedTimeSystemSectionItem
{
  CustomPeriodBasedTimeSystemDescriptionItem,
  MaxCustomPeriodBasedTimeSystemSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TimeSettingsSection.
// -----------------------------------------------------------------------------
enum TimeSettingsSectionItem
{
  AbsoluteTimeSystemSummaryItem,
  PeriodBasedTimeSystemSummaryItem,
  MaxTimeSettingsSectionItem_NoMaximumValue,

  MaximumDurationInSecondsItem_TimeSettings = PeriodBasedTimeSystemSummaryItem + 1,
  MaxTimeSettingsSectionItem_WithMaximumDurationInSeconds,

  MaximumNumberOfMovesOrPeriodsItem_TimeSettings = PeriodBasedTimeSystemSummaryItem + 1,
  MaxTimeSettingsSectionItem_WithMaximumNumberOfMovesOrPeriods,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the MoveDataSection.
// -----------------------------------------------------------------------------
enum MoveDataSectionItem
{
  MoveColorItem,
  MoveDescriptionItem,
  MaxMoveDataSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TimeDataSection.
// -----------------------------------------------------------------------------
enum TimeDataSectionItem
{
  TimeDataColorItem,
  RemainingTimeInSecondsItem,
  MaxTimeDataSectionItem_RemainingTimeInSecondsOnly,

  RemainingNumberOfMovesOrPeriodsItem = RemainingTimeInSecondsItem + 1,
  MaxTimeDataSectionItem_NoMaximumValue,

  MaximumDurationInSecondsItem_TimeData_RemainingTimeInSecondsOnly = RemainingTimeInSecondsItem + 1,
  MaxTimeDataSectionItem_WithMaximumDurationInSeconds_RemainingTimeInSecondsOnly,

  MaximumDurationInSecondsItem_TimeData = RemainingNumberOfMovesOrPeriodsItem + 1,
  MaxTimeDataSectionItem_WithMaximumDurationInSeconds,

  MaximumNumberOfMovesOrPeriodsItem_TimeData = RemainingNumberOfMovesOrPeriodsItem + 1,
  MaxTimeDataSectionItem_WithMaximumNumberOfMovesOrPeriods,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PrecedingTimeDataSection.
// -----------------------------------------------------------------------------
enum PrecedingTimeDataSectionItem
{
  PrecedingRemainingTimeInSecondsItem,
  PrecedingRemainingNumberOfMovesOrPeriodsItem,
  MaxPrecedingTimeDataSectionItem,
  MaxPrecedingTimeDataSectionItem_NoRemainingNumberOfMovesOrPeriods = PrecedingRemainingTimeInSecondsItem + 1,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates all table view cells that can ever appear in the
/// "Invalid time data details" table view, without regard to the conditions
/// under which they appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// nested switch/if statements.
// -----------------------------------------------------------------------------
enum CellId
{
  CellIdInvalidReason,
  CellIdCustomPeriodBasedTimeSystemDescription,
  CellIdAbsoluteTimeSystemSummary,
  CellIdPeriodBasedTimeSystemSummary,
  CellIdMaximumDurationInSeconds,
  CellIdMaximumNumberOfMovesOrPeriods,
  CellIdMoveColor,
  CellIdMoveDescription,
  CellIdTimeDataColor,
  CellIdRemainingNumberOfSeconds,
  CellIdRemainingNumberOfMovesOrPeriods,
  CellIdPrecedingRemainingNumberOfSeconds,
  CellIdPrecedingRemainingNumberOfMovesOrPeriods,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// InvalidTimeDataDetailViewController.
// -----------------------------------------------------------------------------
@interface InvalidTimeDataDetailViewController()
@property(nonatomic, retain) GoGame* game;
@property(nonatomic, retain) GoNode* currentNode;
@property(nonatomic, retain) GoNodeTimeData* precedingNodeTimeData;
@property(nonatomic, retain) TimeSettingsModel* timeSettingsModel;
@end


@implementation InvalidTimeDataDetailViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a InvalidTimeDataDetailViewController object to display
/// detail information about why the time data in @a currentNode is invalid.
///
/// @note This is the designated initializer of
/// InvalidTimeDataDetailViewController.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)game
        currentNode:(GoNode*)currentNode
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;

  self.game = game;
  self.currentNode = currentNode;
  self.precedingNodeTimeData = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this InvalidTimeDataDetailViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  self.currentNode = nil;
  self.precedingNodeTimeData = nil;
  self.timeSettingsModel = nil;

  [super dealloc];
}

#pragma mark - Property getters

// -----------------------------------------------------------------------------
/// @brief Getter implements lazy initialization.
// -----------------------------------------------------------------------------
- (GoNodeTimeData*) precedingNodeTimeData
{
  if (! _precedingNodeTimeData)
  {
    // If the invalidation reason refers to the preceding node, then the current
    // node MUST have a GoNodeTimeData object, and there MUST be a preceding
    // node with a GoNodeTimeData. If not, then the validation function did not
    // work correctly.
    if (self.currentNode.goNodeTimeData)
    {
      enum GoColor playerColor = (self.currentNode.goNodeTimeData.isTimeDataForBlackPlayer
                                  ? GoColorBlack
                                  : GoColorWhite);

      GoNode* precedingNode = [GoUtilities nodeWithMostRecentTimeData:self.currentNode.parent
                                                            forPlayer:playerColor];
      if (precedingNode)
      {
        // Use setter to retain the GoNodeTimeData object
        self.precedingNodeTimeData = precedingNode.goNodeTimeData;

        // Don't use getter
        if (! _precedingNodeTimeData)
          DDLogError(@"%@: Currently selected node does not have a predecessor node with a GoNodeTimeData object for the same player color %d, although the time data invalid reason %d indicates it should", self, playerColor, self.currentNode.timeDataInvalidReason);
      }
    }
    else
    {
      DDLogError(@"%@: Currently selected node does not have a GoNodeTimeData object, although the time data invalid reason %d indicates it should", self, self.currentNode.timeDataInvalidReason);
    }
  }

  return _precedingNodeTimeData;
}

// -----------------------------------------------------------------------------
/// @brief Getter implements lazy initialization.
// -----------------------------------------------------------------------------
- (TimeSettingsModel*) timeSettingsModel
{
  if (! _timeSettingsModel)
  {
    TimeSettingsModel* timeSettingsModel = [[[TimeSettingsModel alloc] init] autorelease];
    [timeSettingsModel updateWithGoTimeSettings:self.game.timeSettings];

    // Use setter to retain the TimeSettingsModel object
    self.timeSettingsModel = timeSettingsModel;
  }

  return _timeSettingsModel;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  if (self.currentNode.timeDataInvalidReason == GoTimeDataInvalidReasonGameDoesNotUseTimedPlay)
    self.title = @"No time data";
  else
    self.title = [NSString stringWithFormat:@"No time data reason %d", self.currentNode.timeDataInvalidReason];
  self.navigationItem.title = self.title;

  // This controller is always presented by a navigation controller. If the
  // presentation style is a popover, then we don't need a cancel button because
  // the user can simply tap outside the presentation area to dismiss the
  // presentation
  if (self.navigationController.modalPresentationStyle != UIModalPresentationPopover)
  {
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancel:)] autorelease];
  }
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  switch (self.currentNode.timeDataInvalidReason)
  {
    // MaxSection_TimeSettingsOnly
    case GoTimeDataInvalidReasonGameDoesNotUseTimedPlay:
    case GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonPeriodDurationExceedsMaximum:
    case GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum:
    case GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum:
      return MaxSection_TimeSettingsOnly;

    // MaxSection_CustomPeriodBasedTimeSystemOnly
    case GoTimeDataInvalidReasonCustomTimeSystem:
      return MaxSection_CustomPeriodBasedTimeSystemOnly;

    // MaxSection_MoveDataOnly
    case GoTimeDataInvalidReasonMoveNodeHasNoTimeData:
      return MaxSection_MoveDataOnly;

    // MaxSection_TimeSettingsAndTimeData
    case GoTimeDataInvalidReasonNonMoveNodeHasTimeData:
    case GoTimeDataInvalidReasonAbsoluteTimeDataFoundWithoutAbsoluteTimeSystem:
    case GoTimeDataInvalidReasonPeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem:
    case GoTimeDataInvalidReasonRemainingTimeNegative:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingTimeExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum:
      return MaxSection_TimeSettingsAndTimeData;

    // MaxSection_MoveDataAndTimeData
    case GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch:
      return MaxSection_MoveDataAndTimeData;

    // MaxSection_TimeSettingsAndTimeDataAndPrecedingTimeData
    case GoTimeDataInvalidReasonAbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData:
    case GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesConstant:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsIsIncreasing:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows:
    default:
      return MaxSection_TimeSettingsAndTimeDataAndPrecedingTimeData;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == InvalidReasonSection)
    return MaxInvalidReasonSectionItem;

  switch (self.currentNode.timeDataInvalidReason)
  {
    // MaxSection_TimeSettingsOnly
    case GoTimeDataInvalidReasonGameDoesNotUseTimedPlay:
      return MaxTimeSettingsSectionItem_NoMaximumValue;
    case GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonPeriodDurationExceedsMaximum:
    case GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum:
      return MaxTimeSettingsSectionItem_WithMaximumDurationInSeconds;
    case GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum:
    case GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum:
      return MaxTimeSettingsSectionItem_WithMaximumNumberOfMovesOrPeriods;

    // MaxSection_CustomPeriodBasedTimeSystemOnly
    case GoTimeDataInvalidReasonCustomTimeSystem:
      return MaxCustomPeriodBasedTimeSystemSectionItem;

    // MaxSection_MoveDataOnly
    case GoTimeDataInvalidReasonMoveNodeHasNoTimeData:
      return MaxMoveDataSectionItem;

    // MaxSection_TimeSettingsAndTimeData
    case GoTimeDataInvalidReasonNonMoveNodeHasTimeData:
    case GoTimeDataInvalidReasonAbsoluteTimeDataFoundWithoutAbsoluteTimeSystem:
    case GoTimeDataInvalidReasonPeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem:
    case GoTimeDataInvalidReasonRemainingTimeNegative:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows:
      if (section == TimeSettingsSection_TimeSettingsAndTimeData)
        return MaxTimeSettingsSectionItem_NoMaximumValue;
      else
        return [self numberOfRowsInTimeDataSection];
    case GoTimeDataInvalidReasonRemainingTimeExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum:
      if (section == TimeSettingsSection_TimeSettingsAndTimeData)
        return MaxTimeSettingsSectionItem_NoMaximumValue;
      else
        return [self numberOfRowsInTimeDataSection];

    // MaxSection_MoveDataAndTimeData
    case GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch:
      if (section == MoveDataSection_MoveDataAndTimeData)
        return MaxMoveDataSectionItem;
      else
        return [self numberOfRowsInTimeDataSection];

    // MaxSection_TimeSettingsAndTimeDataAndPrecedingTimeData
    case GoTimeDataInvalidReasonAbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData:
    case GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesConstant:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsIsIncreasing:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows:
      if (section == TimeSettingsSection_TimeSettingsAndTimeDataAndPrecedingTimeData)
        return MaxTimeSettingsSectionItem_NoMaximumValue;
      else if (section == TimeDataSection_TimeSettingsAndTimeDataAndPrecedingTimeData)
        return [self numberOfRowsInTimeDataSection];
      else
        return [self numberOfRowsInPrecedingTimeDataSection];

    default:
      assert(0);
      return 0;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == InvalidReasonSection)
    return [self titleForHeaderInSection:InvalidReasonSection];

  switch (self.currentNode.timeDataInvalidReason)
  {
    // MaxSection_TimeSettingsOnly
    case GoTimeDataInvalidReasonGameDoesNotUseTimedPlay:
    case GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonPeriodDurationExceedsMaximum:
    case GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum:
    case GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum:
      return [self titleForHeaderInSection:TimeSettingsSection];

    // MaxSection_CustomPeriodBasedTimeSystemOnly
    case GoTimeDataInvalidReasonCustomTimeSystem:
      return [self titleForHeaderInSection:CustomPeriodBasedTimeSystemSection];

    // MaxSection_MoveDataOnly
    case GoTimeDataInvalidReasonMoveNodeHasNoTimeData:
      return [self titleForHeaderInSection:MoveDataSection];

    // MaxSection_TimeSettingsAndTimeData
    case GoTimeDataInvalidReasonNonMoveNodeHasTimeData:
    case GoTimeDataInvalidReasonAbsoluteTimeDataFoundWithoutAbsoluteTimeSystem:
    case GoTimeDataInvalidReasonPeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem:
    case GoTimeDataInvalidReasonRemainingTimeNegative:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingTimeExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum:
      if (section == TimeSettingsSection_TimeSettingsAndTimeData)
        return [self titleForHeaderInSection:TimeSettingsSection];
      else
        return [self titleForHeaderInSection:TimeDataSection];

    // MaxSection_MoveDataAndTimeData
    case GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch:
      if (section == MoveDataSection_MoveDataAndTimeData)
        return [self titleForHeaderInSection:MoveDataSection];
      else
        return [self titleForHeaderInSection:TimeDataSection];

    // MaxSection_TimeSettingsAndTimeDataAndPrecedingTimeData
    case GoTimeDataInvalidReasonAbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData:
    case GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesConstant:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsIsIncreasing:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows:
      if (section == TimeSettingsSection_TimeSettingsAndTimeDataAndPrecedingTimeData)
        return [self titleForHeaderInSection:TimeSettingsSection];
      else if (section == TimeDataSection_TimeSettingsAndTimeDataAndPrecedingTimeData)
        return [self titleForHeaderInSection:TimeDataSection];
      else
        return [self titleForHeaderInSection:PrecedingTimeDataSection];

    default:
      assert(0);
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  enum CellId cellId = [self cellIdForIndexPath:indexPath];
  UITableViewCell* cell = [self createCellWithCellId:cellId
                                        forTableView:tableView];
  [self configureCell:cell
           withCellId:cellId];
  return cell;
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled picking an item.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  // This controller can only be presented, so no need to delegate handling to
  // a delegate
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Private helpers for tableView:titleForHeaderInSection:()

// -----------------------------------------------------------------------------
/// @brief Helper method for tableView:titleForHeaderInSection:().
// -----------------------------------------------------------------------------
- (NSString*) titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case InvalidReasonSection:
      if (self.currentNode.timeDataInvalidReason == GoTimeDataInvalidReasonGameDoesNotUseTimedPlay)
        return @"Description"; // without time systems we don't have a "problem"
      else
        return @"Problem description";
    case CustomPeriodBasedTimeSystemSection:
    case TimeSettingsSection:
      return @"Game time settings";
    case MoveDataSection:
      return @"Move data in currently selected node";
    case TimeDataSection:
      return @"Time data in currently selected node";
    case PrecedingTimeDataSection:
      return @"Preceding time data for the same player";
    default:
      return nil;
  }
}

#pragma mark - Private helpers for tableView:numberOfRowsInSection:()

// -----------------------------------------------------------------------------
/// @brief Helper method for tableView:numberOfRowsInSection:().
// -----------------------------------------------------------------------------
- (NSInteger) numberOfRowsInTimeDataSection
{
  switch (self.currentNode.timeDataInvalidReason)
  {
    case GoTimeDataInvalidReasonRemainingTimeExceedsMaximum:
      if (self.currentNode.goNodeTimeData.isRemainingTimeAbsoluteTime)
        return MaxTimeDataSectionItem_WithMaximumDurationInSeconds_RemainingTimeInSecondsOnly;
      else
        return MaxTimeDataSectionItem_WithMaximumDurationInSeconds;

    case GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum:
      return MaxTimeDataSectionItem_WithMaximumNumberOfMovesOrPeriods;

    default:
      if (self.currentNode.goNodeTimeData.isRemainingTimeAbsoluteTime)
        return MaxTimeDataSectionItem_RemainingTimeInSecondsOnly;
      else
        return MaxTimeDataSectionItem_NoMaximumValue;
  }
}

// -----------------------------------------------------------------------------
/// @brief Helper method for tableView:numberOfRowsInSection:().
// -----------------------------------------------------------------------------
- (NSInteger) numberOfRowsInPrecedingTimeDataSection
{
  if (! self.precedingNodeTimeData || self.precedingNodeTimeData.isRemainingTimeAbsoluteTime)
    return MaxPrecedingTimeDataSectionItem_NoRemainingNumberOfMovesOrPeriods;
  else
    return MaxPrecedingTimeDataSectionItem;
}

#pragma mark - Private helper for tableView:cellForRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) createCellWithCellId:(enum CellId)cellId
                             forTableView:(UITableView*)tableView
{
  UITableViewCell* cell = nil;

  switch (cellId)
  {
    case CellIdInvalidReason:
    case CellIdCustomPeriodBasedTimeSystemDescription:
    case CellIdAbsoluteTimeSystemSummary:
    case CellIdPeriodBasedTimeSystemSummary:
    case CellIdMaximumDurationInSeconds:
    case CellIdMaximumNumberOfMovesOrPeriods:
    case CellIdRemainingNumberOfSeconds:
    case CellIdPrecedingRemainingNumberOfSeconds:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType
                                      tableView:tableView];
      break;
    }
    default:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType
                                      tableView:tableView];
    }
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
    case CellIdInvalidReason:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabelWidthPercentage = 1.0;
      variableHeightCell.descriptionLabel.text = [self stringForTimeDataInvalidReason:self.currentNode.timeDataInvalidReason];
      break;
    }
    case CellIdAbsoluteTimeSystemSummary:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabelWidthPercentage = 0.3;
      variableHeightCell.descriptionLabel.text = @"Main time";
      variableHeightCell.valueLabel.text = [TimeDataUtilities absoluteTimeSystemSummary:self.timeSettingsModel
                                                                  withSecondsResolution:[self shouldDurationValuesUseSecondsResolution]];
      break;
    }
    case CellIdPeriodBasedTimeSystemSummary:
    case CellIdCustomPeriodBasedTimeSystemDescription:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabelWidthPercentage = 0.3;
      variableHeightCell.descriptionLabel.text = @"Overtime";
      variableHeightCell.valueLabel.text = [TimeDataUtilities periodBasedTimeSystemSummary:self.timeSettingsModel
                                                                     withSecondsResolution:[self shouldDurationValuesUseSecondsResolution]];
      break;
    }
    case CellIdMaximumDurationInSeconds:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabelWidthPercentage = 0.5;
      variableHeightCell.descriptionLabel.text = @"Maximum duration supported by the app";
      variableHeightCell.valueLabel.text = [CompositeDuration humanReadableStringWithDurationInSeconds:gMaximumRemainingTimeInSeconds
                                                                                 withSecondsResolution:[self shouldDurationValuesUseSecondsResolution]];
      break;
    }
    case CellIdMaximumNumberOfMovesOrPeriods:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabelWidthPercentage = 0.5;
      variableHeightCell.descriptionLabel.text = @"Maximum number of moves or periods supported by the app";
      variableHeightCell.valueLabel.text = [NSString stringWithFormat:@"%lu", gMaximumRemainingNumberOfMovesOrPeriods];
      break;
    }
    case CellIdMoveColor:
    {
      cell.textLabel.text = @"Move played by";
      GoMove* move = self.currentNode.goMove;
      if (move)
      {
        cell.detailTextLabel.text = [NSString stringWithGoColor:move.player.color];
      }
      else
      {
        assert(0);
        cell.detailTextLabel.text = @"n/a";
      }
      break;
    }
    case CellIdMoveDescription:
    {
      cell.textLabel.text = @"Move";
      GoMove* move = self.currentNode.goMove;
      if (move)
      {
        if (move.type == GoMoveTypePass)
          cell.detailTextLabel.text = @"Pass";
        else
          cell.detailTextLabel.text = move.point.vertex.string;
      }
      else
      {
        assert(0);
        cell.detailTextLabel.text = @"n/a";
      }
      break;
    }
    case CellIdTimeDataColor:
    {
      cell.textLabel.text = @"Time data is for player";
      cell.detailTextLabel.text = [self timeDataColorString:self.currentNode.goNodeTimeData];
      break;
    }
    case CellIdRemainingNumberOfSeconds:
    case CellIdPrecedingRemainingNumberOfSeconds:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabelWidthPercentage = 0.4;
      variableHeightCell.descriptionLabel.text = @"Remaining time";
      variableHeightCell.valueLabel.text = [self numberOfRemainingSecondsString:(cellId == CellIdRemainingNumberOfSeconds
                                                                                 ? self.currentNode.goNodeTimeData
                                                                                 : self.precedingNodeTimeData)];
      break;
    }
    case CellIdRemainingNumberOfMovesOrPeriods:
    case CellIdPrecedingRemainingNumberOfMovesOrPeriods:
    {
      [self configureRemainingNumberOfMovesOrPeriodsCell:cell
                                withDataFromNodeTimeData:(cellId == CellIdRemainingNumberOfMovesOrPeriods
                                                          ? self.currentNode.goNodeTimeData
                                                          : self.precedingNodeTimeData)];
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a indexPath, taking
/// into account the values found in the TimeSettingsModel object with which
/// InvalidTimeDataDetailViewController was initialized.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == InvalidReasonSection)
    return CellIdInvalidReason;

  switch (self.currentNode.timeDataInvalidReason)
  {
    // MaxSection_TimeSettingsOnly
    case GoTimeDataInvalidReasonGameDoesNotUseTimedPlay:
    case GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonPeriodDurationExceedsMaximum:
    case GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum:
    case GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum:
      return [self cellIdForTimeSettingsSectionRow:indexPath.row];

    // MaxSection_CustomPeriodBasedTimeSystemOnly
    case GoTimeDataInvalidReasonCustomTimeSystem:
      return CellIdCustomPeriodBasedTimeSystemDescription;

    // MaxSection_MoveDataOnly
    case GoTimeDataInvalidReasonMoveNodeHasNoTimeData:
      return [self cellIdForMoveDataSectionRow:indexPath.row];

    // MaxSection_TimeSettingsAndTimeData
    case GoTimeDataInvalidReasonNonMoveNodeHasTimeData:
    case GoTimeDataInvalidReasonAbsoluteTimeDataFoundWithoutAbsoluteTimeSystem:
    case GoTimeDataInvalidReasonPeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem:
    case GoTimeDataInvalidReasonRemainingTimeNegative:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingTimeExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum:
      if (indexPath.section == TimeSettingsSection_TimeSettingsAndTimeData)
        return [self cellIdForTimeSettingsSectionRow:indexPath.row];
      else
        return [self cellIdForTimeDataSectionRow:indexPath.row];

    // MaxSection_MoveDataAndTimeData
    case GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch:
      if (indexPath.section == MoveDataSection_MoveDataAndTimeData)
        return [self cellIdForMoveDataSectionRow:indexPath.row];
      else
        return [self cellIdForTimeDataSectionRow:indexPath.row];

    // MaxSection_TimeSettingsAndTimeDataAndPrecedingTimeData
    case GoTimeDataInvalidReasonAbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData:
    case GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesConstant:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsIsIncreasing:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows:
    default:
      if (indexPath.section == TimeSettingsSection_TimeSettingsAndTimeDataAndPrecedingTimeData)
        return [self cellIdForTimeSettingsSectionRow:indexPath.row];
      else if (indexPath.section == TimeDataSection_TimeSettingsAndTimeDataAndPrecedingTimeData)
        return [self cellIdForTimeDataSectionRow:indexPath.row];
      else
        return [self cellIdForPrecedingTimeDataSectionRow:indexPath.row];
  }
}

// -----------------------------------------------------------------------------
/// @brief Helper method for cellIdForIndexPath:().
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForTimeSettingsSectionRow:(NSInteger)row
{
  if (row == AbsoluteTimeSystemSummaryItem)
    return CellIdAbsoluteTimeSystemSummary;
  else if (row == PeriodBasedTimeSystemSummaryItem)
    return CellIdPeriodBasedTimeSystemSummary;

  switch (self.currentNode.timeDataInvalidReason)
  {
    case GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonPeriodDurationExceedsMaximum:
    case GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum:
      return CellIdMaximumDurationInSeconds;

    case GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum:
    case GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum:
      return CellIdMaximumNumberOfMovesOrPeriods;

    default:
      assert(0);
      return -1;
  }
}

// -----------------------------------------------------------------------------
/// @brief Helper method for cellIdForIndexPath:().
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForMoveDataSectionRow:(NSInteger)row
{
  if (row == MoveColorItem)
    return CellIdMoveColor;
  else
    return CellIdMoveDescription;
}

// -----------------------------------------------------------------------------
/// @brief Helper method for cellIdForIndexPath:().
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForTimeDataSectionRow:(NSInteger)row
{
  if (row == TimeDataColorItem)
    return CellIdTimeDataColor;
  else if (row == RemainingTimeInSecondsItem)
    return CellIdRemainingNumberOfSeconds;

  switch (self.currentNode.timeDataInvalidReason)
  {
    case GoTimeDataInvalidReasonRemainingTimeExceedsMaximum:
      if (self.currentNode.goNodeTimeData.isRemainingTimeAbsoluteTime)
        return CellIdMaximumDurationInSeconds;
      else if (row == RemainingNumberOfMovesOrPeriodsItem)
        return CellIdRemainingNumberOfMovesOrPeriods;
      else
        return CellIdMaximumDurationInSeconds;

    case GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum:
      if (row == RemainingNumberOfMovesOrPeriodsItem)
        return CellIdRemainingNumberOfMovesOrPeriods;
      else
        return CellIdMaximumNumberOfMovesOrPeriods;

    default:
      return CellIdRemainingNumberOfMovesOrPeriods;
  }
}

// -----------------------------------------------------------------------------
/// @brief Helper method for cellIdForIndexPath:().
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForPrecedingTimeDataSectionRow:(NSInteger)row
{
  if (row == PrecedingRemainingTimeInSecondsItem)
    return CellIdPrecedingRemainingNumberOfSeconds;
  else
    return CellIdPrecedingRemainingNumberOfMovesOrPeriods;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string denoting the color played by the player whose
/// data is stored in @a nodeTimeData.
// -----------------------------------------------------------------------------
- (NSString*) timeDataColorString:(GoNodeTimeData*)nodeTimeData
{
  if (nodeTimeData)
  {
    enum GoColor color = (nodeTimeData.isTimeDataForBlackPlayer
                          ? GoColorBlack
                          : GoColorWhite);
    return [NSString stringWithGoColor:color];
  }
  else
  {
    assert(0);
    return @"n/a";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representing the number of remaining seconds stored
/// in @a nodeTimeData.
// -----------------------------------------------------------------------------
- (NSString*) numberOfRemainingSecondsString:(GoNodeTimeData*)nodeTimeData
{
  if (nodeTimeData)
  {
    return [CompositeDuration humanReadableStringWithDurationInSeconds:nodeTimeData.remainingTimeInSeconds
                                                 withSecondsResolution:[self shouldDurationValuesUseSecondsResolution]];
  }
  else
  {
    assert(0);
    return @"n/a";
  }
}

// -----------------------------------------------------------------------------
/// @brief Configures @a cell to display the value of either one of the
/// properties @e remainingNumberOfMoves or @e @e remainingNumberOfPeriods of
/// @a nodeTimeData.
// -----------------------------------------------------------------------------
- (void) configureRemainingNumberOfMovesOrPeriodsCell:(UITableViewCell*)cell
                             withDataFromNodeTimeData:(GoNodeTimeData*)nodeTimeData
{
  bool shouldDisplayNumberOfMoves = [self shouldDisplayNumberOfMovesForNodeTimeData:nodeTimeData];

  cell.textLabel.text = (shouldDisplayNumberOfMoves ? @"Remaining moves" : @"Remaining periods");

  if (nodeTimeData)
  {
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (shouldDisplayNumberOfMoves
                                                                    ? nodeTimeData.remainingNumberOfMoves
                                                                    : nodeTimeData.remainingNumberOfPeriods)];
  }
  else
  {
    assert(0);
    cell.detailTextLabel.text = @"n/a";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns @e true if the value of property @e remainingNumberOfMoves
/// of @a nodeTimeData should be displayed. Returns @e false if the value of
/// property @e remainingNumberOfPeriods of @a nodeTimeData should be displayed.
// -----------------------------------------------------------------------------
- (bool) shouldDisplayNumberOfMovesForNodeTimeData:(GoNodeTimeData*)nodeTimeData
{
  if (! nodeTimeData)
  {
    assert(0);
    return true;
  }
  else if (nodeTimeData.isRemainingTimeAbsoluteTime)
  {
    return true;
  }
  else
  {
    return (self.game.timeSettings.periodBasedTimeSystem.goTimeSystemType != GoTimeSystemTypeJapanese);
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns @e true if duration values should display an exact number of
/// seconds in addition to their human-readable string representation. Returns
/// @e false if the human-readable string representation is sufficient.
///
/// Duration values need to display an exact number of seconds if the user needs
/// to be able to compare two duration values in order to understand the reason
/// why time data is invalid.
///
/// Example: If two durations in seconds are 3600 and 3601, the human-readable
/// representation of both durations reads "1 hour", i.e. the two strings are
/// the same. In order to understand that there is a difference, the user needs
/// to see the exact number of seconds.
///
/// The exact number of seconds is displayed even if the human-readable
/// representation would allow the user to calculate the exact number of
/// seconds. For instance, the human-readable duration string "3 minutes" and
/// "3:10 minutes" would allow the user to calculate that the number of seconds
/// is 180 and 190, respectively. However, calculation requires additional
/// mental effort, and we want the user to be able to compare two numbers
/// directly without that additional effort.
// -----------------------------------------------------------------------------
- (bool) shouldDurationValuesUseSecondsResolution
{
  switch (self.currentNode.timeDataInvalidReason)
  {
    case GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonPeriodDurationExceedsMaximum:
    case GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum:
    case GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum:
    case GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased:
    case GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased:
    case GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows:
    case GoTimeDataInvalidReasonRemainingTimeExceedsMaximum:
      return true;
    default:
      return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Return a textual description of @a timeDataInvalidReason.
// -----------------------------------------------------------------------------
- (NSString*) stringForTimeDataInvalidReason:(enum GoTimeDataInvalidReason)timeDataInvalidReason
{
  switch (timeDataInvalidReason)
  {
    case GoTimeDataInvalidReasonGameDoesNotUseTimedPlay:
      return @"The game is configured neither with main time nor with overtime.";
    case GoTimeDataInvalidReasonCustomTimeSystem:
      return @"The game is configured with a custom overtime system for which this app does not understand the rules.";
    case GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum:
      return @"The game is configured with a main time that exceeds the maximum supported by this app.";
    case GoTimeDataInvalidReasonPeriodDurationExceedsMaximum:
      return @"The game is configured with an overtime period duration that exceeds the maximum supported by this app.";
    case GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum:
      return @"The game is configured with an overtime system for which the extra time after each move exceeds the maximum supported by this app.";
    case GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum:
      return @"The game is configured with an overtime number of moves per period that exceeds the maximum supported by this app.";
    case GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum:
      return @"The game is configured with an overtime number of periods that exceeds the maximum supported by this app.";
    case GoTimeDataInvalidReasonMoveNodeHasNoTimeData:
      return @"The currently selected node contains a move, but no time data.";
    case GoTimeDataInvalidReasonNonMoveNodeHasTimeData:
      return @"The currently selected node contains time data, but no move.";
    case GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch:
      return @"Player mismatch: The time data in the currently selected node was recorded for a different player than the player who made the move.";
    case GoTimeDataInvalidReasonAbsoluteTimeDataFoundWithoutAbsoluteTimeSystem:
      return @"The time data in the currently selected node was recorded for main time, but the game is not configured with main time.";
    case GoTimeDataInvalidReasonPeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem:
      return @"The time data in the currently selected node was recorded for overtime, but the game is not configured with overtime.";
    case GoTimeDataInvalidReasonRemainingTimeNegative:
      return @"The time data in the currently selected node indicates that the time left to play is negative.";
    case GoTimeDataInvalidReasonAbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData:
      return @"The time data in the currently selected node was recorded for main time, but overtime has already started at this point of the game.";
    case GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing:
      return @"The time data in the currently selected node indicates that the main time left to play has increased since the previous move. However, the remaining main time should only ever decrease.";
    case GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows:
      return @"The time data in the currently selected node indicates that the time left to play is higher than the main time at the start of the game.";
    case GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows:
      return @"The time data in the currently selected node indicates that the time left to play is higher than the overtime period duration.";
    case GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows:
      return @"The time data in the currently selected node indicates that the number of moves left to play in this period is higher than the overtime number of moves per period.";
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows:
      return @"The time data in the currently selected node indicates that the number of periods left to play is higher than the overtime number of periods.";
    case GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant:
      return @"The time data in the currently selected node indicates that the number of moves left to play in this period has not stayed the same since the previous move. However, the number of moves left to play should stay the same because the overtime number of moves per period is 1.";
    case GoTimeDataInvalidReasonRemainingNumberOfMovesConstant:
      return @"The time data in the currently selected node indicates that the number of moves left to play in this period has stayed the same since the previous move. However, the number of moves left to play should either decrease (before the period reset) or increase (after the period reset).";
    case GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased:
      return @"The time data in the currently selected node indicates that the number of moves left to play in this period has decreased since the previous move, while the number of seconds left to play has increased. However, the number of moves left to play and the number of seconds left to play should both decrease, or the number of seconds left to play should at least stay the same if no time was used to play the move.";
    case GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased:
      return @"The time data in the currently selected node indicates that the number of moves left to play in this period has increased since the previous move (which means a period reset took place), while the number of seconds left to play has decreased. However, the number of moves left to play and the number of seconds left to play should both increase after a period reset, or the number of seconds left to play should at least stay the same if no time was used during the entire period.";
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsIsIncreasing:
      return @"The time data in the currently selected node indicates that the number of periods left to play has increased since the previous move. However, the remaining number of periods should only ever decrease.";
    case GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows:
      return @"The time data in the currently selected node indicates that the time left to play is higher - although it should not be - than the time left to play after the previous move, plus the overtime system's extra time.";
    case GoTimeDataInvalidReasonRemainingTimeExceedsMaximum:
      return @"The time data in the currently selected node indicates a number of seconds left to play in this period that exceeds the maximum supported by this app.";
    case GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum:
      return @"The time data in the currently selected node indicates a number of moves left to play in this period that exceeds the maximum supported by this app.";
    case GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum:
      return @"The time data in the currently selected node indicates a number of periods left to play that exceeds the maximum supported by this app.";
    default:
      return @"An unexpected reason was encountered.";
  }
}

@end
