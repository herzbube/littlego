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
#import "EditGameInfoDateController.h"
#import "../../go/GoUtilities.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewDatePickerCell.h"
#import "../../ui/TableViewSliderCell.h"
#import "../../ui/TableViewVariableHeightCell.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the precisions that a game date can have.
// -----------------------------------------------------------------------------
enum GameDatePrecision
{
  GameDatePrecisionDays,
  GameDatePrecisionMonths,
  GameDatePrecisionYears,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game info date" table
/// view.
// -----------------------------------------------------------------------------
enum GameInfoRoundTableViewSection
{
  PrecisionSection,
  DataSection,
  MaxSection,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PrecisionSection.
// -----------------------------------------------------------------------------
enum PrecisionSectionItem
{
  DaysItem,
  MonthsItem,
  YearsItem,
  MaxPrecisionSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DataSection.
// -----------------------------------------------------------------------------
enum DataSectionItem
{
  DatePickerItem,
  MaxDataSectionItem_DaysPrecision,

  MonthsSliderItem = 0,
  YearsSliderItem_MonthsPrecision,
  MaxDataSectionItem_MonthsPrecision,

  YearsSliderItem_YearsPrecision = 0,
  MaxDataSectionItem_YearsPrecision,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditGameInfoDateController.
// -----------------------------------------------------------------------------
@interface EditGameInfoDateController()
@property(nonatomic, retain) NSDateComponents* dateComponentsToEdit;
@property(nonatomic, assign) enum GameDatePrecision gameDatePrecision;
@end


@implementation EditGameInfoDateController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGameInfoDateController
/// instance that is used to edit the values of @a dateComponents.
// -----------------------------------------------------------------------------
+ (EditGameInfoDateController*) controllerWithDateComponents:(NSDateComponents*)dateComponents
                                                    delegate:(id<EditGameInfoDateControllerDelegate>)delegate
{
  return [[[EditGameInfoDateController alloc] initWithDateComponents:dateComponents
                                                            delegate:delegate] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditGameInfoDateController object with
/// @a dateComponents.
///
/// @note This is the designated initializer of EditGameInfoDateController.
// -----------------------------------------------------------------------------
- (id) initWithDateComponents:(NSDateComponents*)dateComponents
                     delegate:(id<EditGameInfoDateControllerDelegate>)delegate;
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;

  self.dateComponents = dateComponents;
  self.delegate = delegate;
  self.context = nil;
  self.dateComponentsToEdit = [[[NSDateComponents alloc] init] autorelease];

  if (self.dateComponents.day != 0)
    self.gameDatePrecision = GameDatePrecisionDays;
  else if (self.dateComponents.month != 0)
    self.gameDatePrecision = GameDatePrecisionMonths;
  else
    self.gameDatePrecision = GameDatePrecisionYears;

  [self updateDateComponents:self.dateComponentsToEdit withDataFrom:self.dateComponents];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGameInfoDateController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.dateComponents = nil;
  self.delegate = nil;
  self.context = nil;
  self.dateComponentsToEdit = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  NSString* screenTitle = @"Edit game date";
  self.title = screenTitle;
  self.navigationItem.title = screenTitle;

  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];
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
  if (section == PrecisionSection)
    return MaxPrecisionSectionItem;
  else if (self.gameDatePrecision == GameDatePrecisionDays)
    return MaxDataSectionItem_DaysPrecision;
  else if (self.gameDatePrecision == GameDatePrecisionMonths)
    return MaxDataSectionItem_MonthsPrecision;
  else
    return MaxDataSectionItem_YearsPrecision;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (section == PrecisionSection)
    return @"Select whether the date is a full date (day, month and year), or if only month and year are known, or if only the year is known.";
  else
    return @"Select the date when the game was played";
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell;

  if (indexPath.section == PrecisionSection)
  {
    cell = [TableViewCellFactory cellWithType:ActionTextCellType tableView:tableView];
    if (indexPath.row == DaysItem)
      cell.textLabel.text = @"Day, month and year";
    else if (indexPath.row == MonthsItem)
      cell.textLabel.text = @"Month and year";
    else
      cell.textLabel.text = @"Year";

    if ([self gameDatePrecisionForPrecisionSectionItem:indexPath.row] == self.gameDatePrecision)
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
      cell.accessoryType = UITableViewCellAccessoryNone;
  }
  else
  {
    if (self.gameDatePrecision == GameDatePrecisionDays)
    {
      cell = [TableViewCellFactory cellWithType:DatePickerCellType tableView:tableView];

      TableViewDatePickerCell* datePickerCell = (TableViewDatePickerCell*)cell;
      datePickerCell.descriptionLabel.text = @"Date";
      datePickerCell.dateComponents = self.dateComponentsToEdit;

      [datePickerCell setDelegate:self
         actionValueDidChange:@selector(dateDidChange:)];
    }
    else
    {
      if (self.gameDatePrecision == GameDatePrecisionMonths && indexPath.row == MonthsSliderItem)
      {
        cell = [TableViewCellFactory cellWithType:SliderWithValueLabelAndStepperCellType tableView:tableView];

        TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
        sliderCell.descriptionLabel.text = @"Month";
        [sliderCell setDelegate:self
           actionValueDidChange:@selector(monthDidChange:)
                 valueFormatter:@selector(stringForMonth:)];
        [sliderCell setValue:(int)self.dateComponentsToEdit.month minimumValue:1 maximumValue:12];
      }
      else
      {
        cell = [TableViewCellFactory cellWithType:SliderWithValueLabelAndStepperCellType tableView:tableView];

        TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
        sliderCell.descriptionLabel.text = @"Year";
        // Minimum year = 1 - it's unlikely that someone wants to record a game that is older than 2000 years
        // Maximum year = 5000 - it's unlikely that this app is going to live that long
        [sliderCell setDelegate:self
           actionValueDidChange:@selector(yearDidChange:)
                 valueFormatter:nil];
        [sliderCell setValue:(int)self.dateComponentsToEdit.year minimumValue:1 maximumValue:5000];
      }
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

  if (indexPath.section == PrecisionSection)
  {
    enum GameDatePrecision newGameDatePrecision = [self gameDatePrecisionForPrecisionSectionItem:indexPath.row];
    if (self.gameDatePrecision == newGameDatePrecision)
      return;

    self.gameDatePrecision = newGameDatePrecision;
    if (self.gameDatePrecision == GameDatePrecisionDays)
    {
      if (self.dateComponentsToEdit.day == 0)
        self.dateComponentsToEdit.day = 1;
      if (self.dateComponentsToEdit.month == 0)
        self.dateComponentsToEdit.month = 1;
    }
    else if (self.gameDatePrecision == GameDatePrecisionMonths)
    {
      self.dateComponentsToEdit.day = 0;
      if (self.dateComponentsToEdit.month == 0)
        self.dateComponentsToEdit.month = 1;
    }
    else
    {
      self.dateComponentsToEdit.day = 0;
      self.dateComponentsToEdit.month = 0;
    }

    [self.tableView reloadData];
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing.
// -----------------------------------------------------------------------------
- (void) dateDidChange:(id)sender
{
  TableViewDatePickerCell* datePickerCell = (TableViewDatePickerCell*)sender;
  [self updateDateComponents:self.dateComponentsToEdit
                withDataFrom:datePickerCell.dateComponents];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing.
// -----------------------------------------------------------------------------
- (void) monthDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.dateComponentsToEdit.month = sliderCell.value;
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing.
// -----------------------------------------------------------------------------
- (void) yearDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.dateComponentsToEdit.year = sliderCell.value;
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  bool didChangeDateInformation;
  if (self.dateComponents.day != self.dateComponentsToEdit.day)
    didChangeDateInformation = true;
  else if (self.dateComponents.month != self.dateComponentsToEdit.month)
    didChangeDateInformation = true;
  else if (self.dateComponents.year != self.dateComponentsToEdit.year)
    didChangeDateInformation = true;
  else
    didChangeDateInformation = false;

  if (didChangeDateInformation)
  {
    [self updateDateComponents:self.dateComponents
                  withDataFrom:self.dateComponentsToEdit];
  }

  [self.delegate editGameInfoDateControllerDidEndEditing:self didChangeDateInformation:didChangeDateInformation];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled editing.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  bool didChangeDateInformation = false;
  [self.delegate editGameInfoDateControllerDidEndEditing:self didChangeDateInformation:didChangeDateInformation];
}

#pragma mark - TableViewSliderCell formatters

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a numberOfMovesOrPeriodsAsNumber.
// -----------------------------------------------------------------------------
- (NSString*) stringForMonth:(NSNumber*)monthAsNumber
{
  int month = [monthAsNumber intValue];
  return [NSString stringWithMonth:month];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Maps @a precisionSectionItem (which is expected to be a value from
/// the #PrecisionSectionItem enumeration) to a value from the enumeration
/// @a GameDatePrecision and returns the result.
// -----------------------------------------------------------------------------
- (enum GameDatePrecision) gameDatePrecisionForPrecisionSectionItem:(NSInteger)precisionSectionItem
{
  if (precisionSectionItem == DaysItem)
    return GameDatePrecisionDays;
  else if (precisionSectionItem == MonthsItem)
    return GameDatePrecisionMonths;
  else
    return GameDatePrecisionYears;
}

// -----------------------------------------------------------------------------
/// @brief Maps @a gameDatePrecision to a value from the enumeration
/// @a PrecisionSectionItem and returns the result.
// -----------------------------------------------------------------------------
- (enum PrecisionSectionItem) precisionSectionRowForGameDatePrecision:(enum GameDatePrecision)gameDatePrecision
{
  if (gameDatePrecision == GameDatePrecisionDays)
    return DaysItem;
  else if (gameDatePrecision == GameDatePrecisionMonths)
    return MonthsItem;
  else
    return YearsItem;
}

// -----------------------------------------------------------------------------
/// @brief Updates @a dateComponents with data that is currently stored in
/// @a dateComponentsSource.
// -----------------------------------------------------------------------------
- (void) updateDateComponents:(NSDateComponents*)dateComponents
                 withDataFrom:(NSDateComponents*)dateComponentsSource
{
  if (self.gameDatePrecision == GameDatePrecisionDays)
  {
    dateComponents.day = dateComponentsSource.day;
    dateComponents.month = dateComponentsSource.month;
    dateComponents.year = dateComponentsSource.year;
  }
  else if (self.gameDatePrecision == GameDatePrecisionMonths)
  {
    dateComponents.day = 0;
    dateComponents.month = dateComponentsSource.month;
    dateComponents.year = dateComponentsSource.year;
  }
  else
  {
    dateComponents.day = 0;
    dateComponents.month = 0;
    dateComponents.year = dateComponentsSource.year;
  }
}

@end
