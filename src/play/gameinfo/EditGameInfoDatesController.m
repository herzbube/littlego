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
#import "EditGameInfoDatesController.h"
#import "../../go/GoGameInfoDates.h"
#import "../../go/GoUtilities.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewSliderCell.h"
#import "../../ui/TableViewVariableHeightCell.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game info dates" table
/// view.
// -----------------------------------------------------------------------------
enum GameInfoDatesTableViewSection
{
  DataSection,
  ActionSection,
  MaxSection,
  MaxSection_NoData = DataSection + 1,
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditGameInfoDatesController.
// -----------------------------------------------------------------------------
@interface EditGameInfoDatesController()
@property(nonatomic, retain) GoGameInfoDates* gameInfoDatesToEdit;
@property(nonatomic, retain) UIBarButtonItem* addDateButton;
@property(nonatomic, retain) UIBarButtonItem* doneButton;
@property(nonatomic, retain) NSCalendar* calendar;
@property(nonatomic, assign) bool deletingOfLastDateInProgress;
@end


@implementation EditGameInfoDatesController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGameInfoDatesController
/// instance that is used to edit the values of @a gameInfoDates.
// -----------------------------------------------------------------------------
+ (EditGameInfoDatesController*) controllerWithGameInfoDates:(GoGameInfoDates*)gameInfoDates
                                                    delegate:(id<EditGameInfoDatesControllerDelegate>)delegate;
{
  return [[[EditGameInfoDatesController alloc] initWithGameInfoDates:gameInfoDates
                                                            delegate:delegate] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditGameInfoDatesController object with
/// @a gameInfoDates.
///
/// @note This is the designated initializer of EditGameInfoDatesController.
// -----------------------------------------------------------------------------
- (id) initWithGameInfoDates:(GoGameInfoDates*)gameInfoDates
                    delegate:(id<EditGameInfoDatesControllerDelegate>)delegate;
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;

  self.gameInfoDates = gameInfoDates;
  self.delegate = delegate;
  self.gameInfoDatesToEdit = [[[GoGameInfoDates alloc] init] autorelease];
  self.addDateButton = nil;
  self.doneButton = nil;
  self.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
  self.deletingOfLastDateInProgress = false;

  [self updateGameInfoDates:self.gameInfoDatesToEdit withDataFrom:self.gameInfoDates];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGameInfoDatesController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameInfoDates = nil;
  self.delegate = nil;
  self.gameInfoDatesToEdit = nil;
  self.addDateButton = nil;
  self.doneButton = nil;
  self.calendar = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  NSString* screenTitle = @"Edit game dates";
  self.title = screenTitle;
  self.navigationItem.title = screenTitle;

  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.addDateButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                      target:self
                                                                      action:@selector(addDate:)] autorelease];
  self.doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                   target:self
                                                                   action:@selector(done:)] autorelease];

  [self updateRightBarButtonItems];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
  // This method is invoked when the user taps the button that represents
  // self.editButtonItem (provided by UIKit). UIKit says we must invoke super's
  // implementation first => UITableViewController will turn on table editing.
  [super setEditing:editing animated:animated];

  // Update visual style of discard cell
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:ActionSection];
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationNone];

  // Remove our own "Done" button
  [self updateRightBarButtonItems];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if ([self numberOfRowsInDataSection] == 0 && ! self.deletingOfLastDateInProgress)
    return MaxSection_NoData;
  else
    return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == DataSection)
    return [self numberOfRowsInDataSection];
  else
    return 1;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (section == DataSection)
  {
    if (self.gameInfoDatesToEdit.dataType == GoGameInfoDatesDataTypeSgfString)
      return @"The app was unable to parse the game dates that were found in the game that was most recently loaded from the archive. Above you see the text that the app encountered and that it was unable to parse.";
    else if ([self numberOfRowsInDataSection] == 0)
      return @"Tap the '+' button to add a date";
    else
      return nil;
  }
  else
  {
    return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell;

  if (indexPath.section == DataSection)
  {
    if (self.gameInfoDatesToEdit.dataType == GoGameInfoDatesDataTypeSgfString)
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Dates description";
      variableHeightCell.valueLabel.text = self.gameInfoDatesToEdit.sgfString;
    }
    else
    {
      // It would be nicer to use Value1CellType with a label such as
      // "Date 1", "Date 2", etc. The problem with a number in the label is
      // that when the order of the dates is changed, or dates are deleted,
      // then the table needs to reload the cells so that the numbers are
      // updated. Reloading the table all the time doesn't look too smooth,
      // and in the case of re-ordering during testing there sometimes were
      // crashes when tableView:moveRowAtIndexPath:toIndexPath:() was trying
      // to reload the entire data section.
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      NSDateComponents* dateComponents = [self.gameInfoDatesToEdit.dateComponents objectAtIndex:indexPath.row];
      cell.textLabel.text = [NSString stringWithGameInfoDateComponents:dateComponents
                                                                 style:NSDateFormatterLongStyle];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  else
  {
    cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
    cell.textLabel.text = @"Discard dates information";
    if (self.editing)
      cell.textLabel.textColor = [UIColor lightGrayColor];
    else
      cell.textLabel.textColor = [UIColor systemRedColor];
  }

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (editingStyle)
  {
    case UITableViewCellEditingStyleDelete:
    {
      NSMutableArray* mutableDateComponents = [self.gameInfoDatesToEdit.dateComponents.mutableCopy autorelease];

      // When the user deletes the last date, we want to delete the
      // corresponding table view row, and we also want to delete the
      // ActionSection with the "Discard" cell. However, UITableView crashes if
      // we do both things at the same time. We therefore set this flag so that
      // the UITableViewDataSource methods continue to report the ActionSection
      // as being present while we delete the date's table view row.
      self.deletingOfLastDateInProgress = (mutableDateComponents.count == 1);

      [mutableDateComponents removeObjectAtIndex:indexPath.row];
      self.gameInfoDatesToEdit.dateComponents = mutableDateComponents;


      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                       withRowAnimation:UITableViewRowAnimationRight];

      if (self.deletingOfLastDateInProgress)
      {
        // Reset the flag so that we can delete the ActionSection
        self.deletingOfLastDateInProgress = false;

        NSIndexSet* sectionToDelete = [NSIndexSet indexSetWithIndex:ActionSection];
        [tableView deleteSections:sectionToDelete withRowAnimation:UITableViewRowAnimationAutomatic];

        // Ideally we would like to disable editing here. Unfortunately setting
        // the "editing" property to NO, or invoking setEditing:animated:(),
        // causes the "Done" button to revert its state to "Edit", but if new
        // cells are then added they are shown with
        // UITableViewCellEditingStyleDelete. If we don't try to disable editing
        // programmatically, but instead let the user leave editing mode by
        // tapping the "Done" button, all is well => Conclusion: UIKit does
        // something under the hood when the user taps the "Done" button, but
        // we don't know what.
      }

      break;
    }
    default:
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath
{
  NSMutableArray* mutableDateComponents = [self.gameInfoDatesToEdit.dateComponents.mutableCopy autorelease];
  id elementToMove = [mutableDateComponents objectAtIndex:fromIndexPath.row];
  [mutableDateComponents removeObjectAtIndex:fromIndexPath.row];
  [mutableDateComponents insertObject:elementToMove atIndex:toIndexPath.row];
  self.gameInfoDatesToEdit.dateComponents = mutableDateComponents;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
  // The row with the "Discard" cell can't be edited => when the user taps the
  // cell, UITableView does not invoke tableView:didSelectRowAtIndexPath:()
  return (indexPath.section == 0);
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (indexPath.section == ActionSection)
  {
    self.gameInfoDatesToEdit.dataType = GoGameInfoDatesDataTypeNone;
    self.gameInfoDatesToEdit.sgfString = nil;
    self.gameInfoDatesToEdit.dateComponents = @[];

    [self updateRightBarButtonItems];
    [self.tableView reloadData];
  }
  else
  {
    if (self.gameInfoDatesToEdit.dataType == GoGameInfoDatesDataTypeStructuredData)
      [self showEditGameInfoDateControllerForIndexPath:indexPath];
  }
}

#pragma mark - Private helpers for tableView:numberOfRowsInSection:()

// -----------------------------------------------------------------------------
/// @brief Helper method for tableView:numberOfRowsInSection:().
// -----------------------------------------------------------------------------
- (NSInteger) numberOfRowsInDataSection
{
  if (self.gameInfoDatesToEdit.dataType == GoGameInfoDatesDataTypeNone)
    return 0;
  else if (self.gameInfoDatesToEdit.dataType == GoGameInfoDatesDataTypeSgfString)
    return 1;
  else
    return self.gameInfoDatesToEdit.dateComponents.count;
}

#pragma mark - Private helpers for tableView:didSelectRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:didSelectRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) showEditGameInfoDateControllerForIndexPath:(NSIndexPath*)indexPath
{
  NSDateComponents* dateComponents = [self.gameInfoDatesToEdit.dateComponents objectAtIndex:indexPath.row];

  EditGameInfoDateController* controller = [EditGameInfoDateController controllerWithDateComponents:dateComponents
                                                                                           delegate:self];
  controller.context = indexPath;

  [self presentNavigationControllerWithRootViewController:controller];
}

#pragma mark - EditGameInfoDateControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditGameInfoDateControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) editGameInfoDateControllerDidEndEditing:(EditGameInfoDateController*)controller didChangeDateInformation:(bool)didChangeDateInformation
{
  if (didChangeDateInformation)
  {
    // There is no need to update self.gameInfoDatesToEdit here because the
    // controller already updated the NSDateComponents

    NSIndexPath* indexPath = controller.context;
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user taps the "+" (add) button.
// -----------------------------------------------------------------------------
- (void) addDate:(id)sender
{
  NSDateComponents* (^componentsFromDate)(NSDate*) = ^ NSDateComponents* (NSDate* date)
  {
    NSCalendarUnit componentFlags = (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear);
    NSDateComponents* dateComponents = [self.calendar components:componentFlags
                                                        fromDate:date];
    return dateComponents;
  };

  NSMutableArray* mutableDateComponents = [NSMutableArray arrayWithArray:self.gameInfoDatesToEdit.dateComponents];
  NSDateComponents* newDateComponents;

  if (mutableDateComponents.count == 0)
  {
    newDateComponents = componentsFromDate([NSDate now]);
  }
  else
  {
    // Don't change the precision of the predecessor, add +1 to the most
    // significant part of the predecessor.
    NSDateComponents* predecessorDateComponents = mutableDateComponents.lastObject;
    if (predecessorDateComponents.day != 0)
    {
      // For adding 1 day we use NSCalendar because we don't want to deal with
      // the complexities of month overflows or leap years.
      NSDateComponents* oneDayComponents = [[[NSDateComponents alloc] init] autorelease];
      oneDayComponents.day = 1;

      NSDate* predecessorDate = [self.calendar dateFromComponents:predecessorDateComponents];
      NSDate* newDate = [self.calendar dateByAddingComponents:oneDayComponents
                                                       toDate:predecessorDate
                                                      options:0];
      newDateComponents = componentsFromDate(newDate);
    }
    else
    {
      // For adding 1 month or 1 year we don't use NSCalendar, we can do the
      // addition ourselves
      newDateComponents = [[predecessorDateComponents copy] autorelease];
      if (newDateComponents.month == 12)
      {
        newDateComponents.month = 1;
        newDateComponents.year++;
      }
      else if (predecessorDateComponents.month != 0)
      {
        newDateComponents.month++;
      }
      else
      {
        newDateComponents.year++;
      }
    }
  }

  [mutableDateComponents addObject:newDateComponents];
  self.gameInfoDatesToEdit.dateComponents = mutableDateComponents;

  // Make sure it's not GoGameInfoDatesDataTypeNone
  self.gameInfoDatesToEdit.dataType = GoGameInfoDatesDataTypeStructuredData;

  // If we go from 0 (zero) to 1 (one) date, we need to start showing the
  // "Edit" button
  if (mutableDateComponents.count == 1)
    [self updateRightBarButtonItems];

  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  bool (^areStringValuesDifferent)(NSString*, NSString*) = ^ bool (NSString* stringValue1, NSString* stringValue2)
  {
    // Both strings are nil, or both strings happen to be the same instance
    if (stringValue1 == stringValue2)
      return false;

    // Both strings are not nil
    if (stringValue1 && stringValue2)
      return ! [stringValue1 isEqualToString:stringValue2];

    // One of the strings is nil, the other is not => must be different
    return true;
  };

  bool didChangeDatesInformation;
  if (self.gameInfoDates.dataType != self.gameInfoDatesToEdit.dataType)
    didChangeDatesInformation = true;
  else if (areStringValuesDifferent(self.gameInfoDates.sgfString, self.gameInfoDatesToEdit.sgfString))
    didChangeDatesInformation = true;
  else if (! [self.gameInfoDates.dateComponents isEqualToArray:self.gameInfoDatesToEdit.dateComponents])
    didChangeDatesInformation = true;
  else
    didChangeDatesInformation = false;

  if (didChangeDatesInformation)
    [self updateGameInfoDates:self.gameInfoDates withDataFrom:self.gameInfoDatesToEdit];

  [self.delegate editGameInfoDatesControllerDidEndEditing:self didChangeDatesInformation:didChangeDatesInformation];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled editing.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  bool didChangeDatesInformation = false;
  [self.delegate editGameInfoDatesControllerDidEndEditing:self didChangeDatesInformation:didChangeDatesInformation];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Updates @a gameInfoDates with data that is currently stored in
/// @a gameInfoDatesSource.
// -----------------------------------------------------------------------------
- (void) updateGameInfoDates:(GoGameInfoDates*)gameInfoDates
               withDataFrom:(GoGameInfoDates*)gameInfoDatesSource
{
  gameInfoDates.dataType = gameInfoDatesSource.dataType;
  switch (gameInfoDatesSource.dataType)
  {
    case GoGameInfoDatesDataTypeNone:
      gameInfoDates.sgfString = nil;
      gameInfoDates.dateComponents = @[];
      break;
    case GoGameInfoDatesDataTypeSgfString:
      gameInfoDates.sgfString = gameInfoDatesSource.sgfString;
      gameInfoDates.dateComponents = @[];
      break;
    case GoGameInfoDatesDataTypeStructuredData:
      gameInfoDates.sgfString = nil;
      gameInfoDates.dateComponents = gameInfoDatesSource.dateComponents;
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the button items that appear on the right hand side of the
/// navigation item.
// -----------------------------------------------------------------------------
- (void) updateRightBarButtonItems
{
  // We make use of self.editButtonItem, provided by UIKit. The item
  // - Displays a "Done" button while self.editing == YES. This "Done" is used
  //   to confirm/complete the editing. In the editing state we don't show our
  //   own "Done" button. We also don't show the "Add" button.
  // - Displays an "Edit" button while self.editing == NO. This "Edit" is used
  //   to enter the editing state. While we are not in the editing state we
  //   show our own "Done" button.

  if (self.gameInfoDatesToEdit.dataType == GoGameInfoDatesDataTypeSgfString)
    self.navigationItem.rightBarButtonItems = @[self.doneButton];
  else if ([self numberOfRowsInDataSection] == 0)
    self.navigationItem.rightBarButtonItems = @[self.doneButton, self.addDateButton];
  else if (self.editing)
    self.navigationItem.rightBarButtonItems = @[self.editButtonItem];
  else
    self.navigationItem.rightBarButtonItems = @[self.doneButton, self.addDateButton, self.editButtonItem];
}

@end
