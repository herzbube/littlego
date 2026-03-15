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
#import "EditGameInfoRoundController.h"
#import "../../go/GoGameInfoRound.h"
#import "../../go/GoUtilities.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewVariableHeightCell.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game info round" table
/// view.
// -----------------------------------------------------------------------------
enum GameInfoRoundTableViewSection
{
  DataSection,
  ActionSection,
  MaxSection,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DataSection.
// -----------------------------------------------------------------------------
enum DataSectionItem
{
  NoRoundInformationItem,
  MaxDataSectionItem_NoData,

  SgfStringItem = 0,
  MaxDataSectionItem_SgfString,

  RoundTypeItem = 0,
  RoundNumberItem,
  MaxDataSectionItem_StructuredData,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ActionSection.
// -----------------------------------------------------------------------------
enum ActionSectionItem
{
  AddSgfStringItem,
  AddStructuredDataItem,
  MaxActionSectionItem_NoData,

  DiscardDataItem = 0,
  MaxActionSectionItem_SomeData,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates all table view cells that can ever appear in the
/// "Game info round" table view, without regard to the conditions under which
/// they appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// nested switch/if statements.
// -----------------------------------------------------------------------------
enum CellId
{
  CellIdNoData,
  CellIdSgfString,
  CellIdRoundType,
  CellIdRoundNumber,
  CellIdAddSgfString,
  CellIdAddStructuredData,
  CellIdDiscardData,
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditGameInfoRoundController.
// -----------------------------------------------------------------------------
@interface EditGameInfoRoundController()
@property(nonatomic, retain) GoGameInfoRound* gameInfoRoundToEdit;
@end


@implementation EditGameInfoRoundController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGameInfoRoundController
/// instance that is used to edit the values of @a gameInfoRound.
// -----------------------------------------------------------------------------
+ (EditGameInfoRoundController*) controllerWithGameInfoRound:(GoGameInfoRound*)gameInfoRound
                                                    delegate:(id<EditGameInfoRoundControllerDelegate>)delegate;
{
  return [[[EditGameInfoRoundController alloc] initWithGameInfoRound:gameInfoRound
                                                            delegate:delegate] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditGameInfoRoundController object with
/// @a gameInfoRound.
///
/// @note This is the designated initializer of EditGameInfoRoundController.
// -----------------------------------------------------------------------------
- (id) initWithGameInfoRound:(GoGameInfoRound*)gameInfoRound
                    delegate:(id<EditGameInfoRoundControllerDelegate>)delegate;
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;

  self.gameInfoRound = gameInfoRound;
  self.delegate = delegate;
  self.gameInfoRoundToEdit = [[[GoGameInfoRound alloc] init] autorelease];

  [self updateGameInfoRound:self.gameInfoRoundToEdit withDataFrom:self.gameInfoRound];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGameInfoRoundController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameInfoRound = nil;
  self.delegate = nil;
  self.gameInfoRoundToEdit = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  NSString* screenTitle = @"Edit round information";
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
  if (section == DataSection)
    return [self numberOfRowsInDataSection];
  else
    return [self numberOfRowsInActionSection];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (section == DataSection)
  {
    if (self.gameInfoRoundToEdit.dataType == GoGameInfoRoundDataTypeSgfString)
      return @"Tap to enter a description of the round in which the game was played.";
    else if (self.gameInfoRoundToEdit.dataType == GoGameInfoRoundDataTypeStructuredData)
      return @"Tap to enter the round number and round type in which the game was played.";
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
  enum CellId cellId = [self cellIdForIndexPath:indexPath];
  UITableViewCell* cell = [self createCellWithCellId:cellId
                                        forTableView:tableView];
  [self configureCell:cell
           withCellId:cellId];
  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  enum CellId cellId = [self cellIdForIndexPath:indexPath];
  switch (cellId)
  {
    case CellIdSgfString:
    case CellIdRoundType:
    case CellIdRoundNumber:
      [self showEditTextControllerForCellId:cellId indexPath:indexPath];
      break;
    case CellIdAddSgfString:
      self.gameInfoRoundToEdit.dataType = GoGameInfoRoundDataTypeSgfString;
      // done:() relies on this being not nil so it can use isEqualToString:()
      self.gameInfoRoundToEdit.sgfString = @"";
      [self.tableView reloadData];
      break;
    case CellIdAddStructuredData:
      self.gameInfoRoundToEdit.dataType = GoGameInfoRoundDataTypeStructuredData;
      // done:() relies on these being not nil so it can use isEqualToString:()
      self.gameInfoRoundToEdit.roundType = @"";
      self.gameInfoRoundToEdit.roundNumber = @"";
      [self.tableView reloadData];
      break;
    case CellIdDiscardData:
      self.gameInfoRoundToEdit.dataType = GoGameInfoRoundDataTypeNone;
      self.gameInfoRoundToEdit.sgfString = nil;
      self.gameInfoRoundToEdit.roundType = nil;
      self.gameInfoRoundToEdit.roundNumber = nil;
      [self.tableView reloadData];
      break;
    default:
      break;
  }
}

#pragma mark - Private helpers for tableView:numberOfRowsInSection:()

// -----------------------------------------------------------------------------
/// @brief Helper method for tableView:numberOfRowsInSection:().
// -----------------------------------------------------------------------------
- (NSInteger) numberOfRowsInDataSection
{
  switch (self.gameInfoRoundToEdit.dataType)
  {
    case GoGameInfoRoundDataTypeNone:
      return MaxDataSectionItem_NoData;
    case GoGameInfoRoundDataTypeSgfString:
      return MaxDataSectionItem_SgfString;
    case GoGameInfoRoundDataTypeStructuredData:
      return MaxDataSectionItem_StructuredData;
  }
}

// -----------------------------------------------------------------------------
/// @brief Helper method for tableView:numberOfRowsInSection:().
// -----------------------------------------------------------------------------
- (NSInteger) numberOfRowsInActionSection
{
  switch (self.gameInfoRoundToEdit.dataType)
  {
    case GoGameInfoRoundDataTypeNone:
      return MaxActionSectionItem_NoData;
    default:
      return MaxActionSectionItem_SomeData;
  }
}

#pragma mark - Private helpers for tableView:cellForRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) createCellWithCellId:(enum CellId)cellId
                             forTableView:(UITableView*)tableView
{
  UITableViewCell* cell = nil;

  switch (cellId)
  {
    case CellIdNoData:
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      break;
    case CellIdSgfString:
    case CellIdRoundType:
    case CellIdRoundNumber:
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      break;
    case CellIdAddSgfString:
    case CellIdAddStructuredData:
      cell = [TableViewCellFactory cellWithType:ActionTextCellType tableView:tableView];
      break;
    case CellIdDiscardData:
      cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
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
    case CellIdNoData:
    {
      cell.textLabel.text = [GoUtilities stringWithDescriptionOfGameInfoRound:self.gameInfoRoundToEdit];
      cell.textLabel.textAlignment = NSTextAlignmentCenter;
      break;
    }
    case CellIdSgfString:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Round description";
      variableHeightCell.valueLabel.text = self.gameInfoRoundToEdit.sgfString;
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case CellIdRoundType:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Round type";
      variableHeightCell.valueLabel.text = self.gameInfoRoundToEdit.roundType;
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case CellIdRoundNumber:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Round number";
      variableHeightCell.valueLabel.text = self.gameInfoRoundToEdit.roundNumber;
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case CellIdAddSgfString:
    {
      cell.textLabel.text = @"Add round description";
      break;
    }
    case CellIdAddStructuredData:
    {
      cell.textLabel.text = @"Add round type and number";
      break;
    }
    case CellIdDiscardData:
    {
      cell.textLabel.text = @"Discard round information";
      break;
    }
  }
}

#pragma mark - Private helpers for tableView:didSelectRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:didSelectRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) showEditTextControllerForCellId:(enum CellId)cellId indexPath:(NSIndexPath*)indexPath
{
  NSString* textToEdit;
  NSString* titleString;
  if (cellId == CellIdSgfString)
  {
    textToEdit = self.gameInfoRoundToEdit.sgfString;
    titleString = @"Edit round description";
  }
  else if (cellId == CellIdRoundType)
  {
    textToEdit = self.gameInfoRoundToEdit.roundType;
    titleString = @"Edit round type";
  }
  else
  {
    textToEdit = self.gameInfoRoundToEdit.roundNumber;
    titleString = @"Edit round number";
  }

  EditTextController* editTextController = [EditTextController controllerWithText:textToEdit
                                                                            style:EditTextControllerStyleTextField
                                                                         delegate:self];
  editTextController.title = titleString;
  editTextController.context = indexPath;

  [self presentNavigationControllerWithRootViewController:editTextController];
}

#pragma mark - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController isTextValid:(NSString*)text validationErrorMessage:(NSString**)validationErrorMessage
{
  if (validationErrorMessage)
    *validationErrorMessage = nil;
  return true;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  return true;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel
{
  if (! didCancel)
  {
    NSIndexPath* indexPath = editTextController.context;
    enum CellId cellId = [self cellIdForIndexPath:indexPath];
    if (cellId == CellIdSgfString)
    {
      self.gameInfoRoundToEdit.sgfString = editTextController.text;
    }
    else if (cellId == CellIdRoundType)
    {
      self.gameInfoRoundToEdit.roundType = editTextController.text;
    }
    else
    {
      self.gameInfoRoundToEdit.roundNumber = editTextController.text;
    }


    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  // Modify the data type if the user did not enter one or both of the required
  // string values. The alternative to modifying the data type would be to treat
  // the incomplete data as invalid and disable the "Done" button, but this
  // could be viewed to be overly strict and annoying.
  if (self.gameInfoRoundToEdit.dataType == GoGameInfoRoundDataTypeSgfString)
  {
    if (self.gameInfoRoundToEdit.sgfString.length == 0)
    {
      self.gameInfoRoundToEdit.dataType = GoGameInfoRoundDataTypeNone;
      self.gameInfoRoundToEdit.sgfString = nil;
    }
  }
  else if (self.gameInfoRoundToEdit.dataType == GoGameInfoRoundDataTypeStructuredData)
  {
    if (self.gameInfoRoundToEdit.roundType.length == 0 &&
        self.gameInfoRoundToEdit.roundNumber.length == 0)
    {
      self.gameInfoRoundToEdit.dataType = GoGameInfoRoundDataTypeNone;
      self.gameInfoRoundToEdit.roundType = nil;
      self.gameInfoRoundToEdit.roundNumber = nil;
    }
    else if (self.gameInfoRoundToEdit.roundType.length == 0)
    {
      self.gameInfoRoundToEdit.dataType = GoGameInfoRoundDataTypeSgfString;
      self.gameInfoRoundToEdit.sgfString = self.gameInfoRoundToEdit.roundNumber;
    }
    else if (self.gameInfoRoundToEdit.roundNumber.length == 0)
    {
      self.gameInfoRoundToEdit.dataType = GoGameInfoRoundDataTypeSgfString;
      self.gameInfoRoundToEdit.sgfString = self.gameInfoRoundToEdit.roundType;
    }
  }

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

  bool didChangeRoundInformation;
  if (self.gameInfoRound.dataType != self.gameInfoRoundToEdit.dataType)
    didChangeRoundInformation = true;
  else if (areStringValuesDifferent(self.gameInfoRound.sgfString, self.gameInfoRoundToEdit.sgfString))
    didChangeRoundInformation = true;
  else if (areStringValuesDifferent(self.gameInfoRound.roundType, self.gameInfoRoundToEdit.roundType))
    didChangeRoundInformation = true;
  else if (areStringValuesDifferent(self.gameInfoRound.roundNumber, self.gameInfoRoundToEdit.roundNumber))
    didChangeRoundInformation = true;
  else
    didChangeRoundInformation = false;

  [self updateGameInfoRound:self.gameInfoRound
               withDataFrom:self.gameInfoRoundToEdit];

  [self.delegate editGameInfoRoundControllerDidEndEditing:self didChangeRoundInformation:didChangeRoundInformation];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled editing.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  bool didChangeRoundInformation = false;
  [self.delegate editGameInfoRoundControllerDidEndEditing:self didChangeRoundInformation:didChangeRoundInformation];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a indexPath.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == DataSection)
  {
    switch (self.gameInfoRoundToEdit.dataType)
    {
      case GoGameInfoRoundDataTypeNone:
        return CellIdNoData;
      case GoGameInfoRoundDataTypeSgfString:
        return CellIdSgfString;
      case GoGameInfoRoundDataTypeStructuredData:
        if (indexPath.row == RoundTypeItem)
          return CellIdRoundType;
        else
          return CellIdRoundNumber;
    }
  }
  else
  {
    switch (self.gameInfoRoundToEdit.dataType)
    {
      case GoGameInfoRoundDataTypeNone:
        if (indexPath.row == AddSgfStringItem)
          return CellIdAddSgfString;
        else
          return CellIdAddStructuredData;
      default:
        return CellIdDiscardData;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates @a gameInfoRound with data that is currently stored in
/// @a gameInfoRoundSource.
// -----------------------------------------------------------------------------
- (void) updateGameInfoRound:(GoGameInfoRound*)gameInfoRound
                withDataFrom:(GoGameInfoRound*)gameInfoRoundSource
{
  gameInfoRound.dataType = gameInfoRoundSource.dataType;
  switch (gameInfoRoundSource.dataType)
  {
    case GoGameInfoRoundDataTypeNone:
      gameInfoRound.sgfString = nil;
      gameInfoRound.roundType = nil;
      gameInfoRound.roundNumber = nil;
      break;
    case GoGameInfoRoundDataTypeSgfString:
      gameInfoRound.sgfString = gameInfoRoundSource.sgfString;
      gameInfoRound.roundType = nil;
      gameInfoRound.roundNumber = nil;
      break;
    case GoGameInfoRoundDataTypeStructuredData:
      gameInfoRound.sgfString = nil;
      gameInfoRound.roundType = gameInfoRoundSource.roundType;
      gameInfoRound.roundNumber = gameInfoRoundSource.roundNumber;
      break;
  }
}

@end
