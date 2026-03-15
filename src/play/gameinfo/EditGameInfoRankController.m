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
#import "EditGameInfoRankController.h"
#import "../../go/GoGameInfoRank.h"
#import "../../go/GoUtilities.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewSliderCell.h"
#import "../../ui/TableViewVariableHeightCell.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game info rank" table
/// view.
// -----------------------------------------------------------------------------
enum GameInfoRankTableViewSection
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
  NoRankInformationItem,
  MaxDataSectionItem_NoData,

  SgfStringItem = 0,
  MaxDataSectionItem_SgfString,

  RankTypeItem = 0,
  RankItem,
  RatingTypeItem,
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
/// "Game info rank" table view, without regard to the conditions under which
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
  CellIdRankType,
  CellIdRank,
  CellIdRatingType,
  CellIdAddSgfString,
  CellIdAddStructuredData,
  CellIdDiscardData,
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditGameInfoRankController.
// -----------------------------------------------------------------------------
@interface EditGameInfoRankController()
@property(nonatomic, retain) GoGameInfoRank* gameInfoRankToEdit;
@end


@implementation EditGameInfoRankController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGameInfoRankController
/// instance that is used to edit the values of @a gameInfoRank.
// -----------------------------------------------------------------------------
+ (EditGameInfoRankController*) controllerWithGameInfoRank:(GoGameInfoRank*)gameInfoRank
                                                  delegate:(id<EditGameInfoRankControllerDelegate>)delegate;
{
  return [[[EditGameInfoRankController alloc] initWithGameInfoRank:gameInfoRank
                                                          delegate:delegate] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditGameInfoRankController object with
/// @a gameInfoRank.
///
/// @note This is the designated initializer of EditGameInfoRankController.
// -----------------------------------------------------------------------------
- (id) initWithGameInfoRank:(GoGameInfoRank*)gameInfoRank
                   delegate:(id<EditGameInfoRankControllerDelegate>)delegate;
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;

  self.gameInfoRank = gameInfoRank;
  self.delegate = delegate;
  self.context = nil;
  self.screenTitle = nil;
  self.gameInfoRankToEdit = [[[GoGameInfoRank alloc] init] autorelease];

  [self updateGameInfoRank:self.gameInfoRankToEdit withDataFrom:self.gameInfoRank];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGameInfoRankController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameInfoRank = nil;
  self.delegate = nil;
  self.context = nil;
  self.screenTitle = nil;
  self.gameInfoRankToEdit = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.title = self.screenTitle;
  self.navigationItem.title = self.screenTitle;

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
    if (self.gameInfoRankToEdit.dataType == GoGameInfoRankDataTypeSgfString)
      return @"Tap to enter a description of the player rank.";
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
      [self showEditTextControllerForCellIdSgfString];
      break;
    case CellIdRankType:
    case CellIdRatingType:
      [self showItemPickerControllerForCellId:cellId indexPath:indexPath];
      break;
    case CellIdAddSgfString:
      self.gameInfoRankToEdit.dataType = GoGameInfoRankDataTypeSgfString;
      // done:() relies on this being not nil so it can use isEqualToString:()
      self.gameInfoRankToEdit.sgfString = @"";
      [self.tableView reloadData];
      break;
    case CellIdAddStructuredData:
      self.gameInfoRankToEdit.dataType = GoGameInfoRankDataTypeStructuredData;
      self.gameInfoRankToEdit.rankType = GoGameInfoRankTypeKyu;
      self.gameInfoRankToEdit.rank = 30;
      self.gameInfoRankToEdit.ratingType = GoGameInfoRatingTypeUnspecified;
      [self.tableView reloadData];
      break;
    case CellIdDiscardData:
      self.gameInfoRankToEdit.dataType = GoGameInfoRankDataTypeNone;
      self.gameInfoRankToEdit.sgfString = nil;
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
  switch (self.gameInfoRankToEdit.dataType)
  {
    case GoGameInfoRankDataTypeNone:
      return MaxDataSectionItem_NoData;
    case GoGameInfoRankDataTypeSgfString:
      return MaxDataSectionItem_SgfString;
    case GoGameInfoRankDataTypeStructuredData:
      return MaxDataSectionItem_StructuredData;
  }
}

// -----------------------------------------------------------------------------
/// @brief Helper method for tableView:numberOfRowsInSection:().
// -----------------------------------------------------------------------------
- (NSInteger) numberOfRowsInActionSection
{
  switch (self.gameInfoRankToEdit.dataType)
  {
    case GoGameInfoRankDataTypeNone:
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
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      break;
    case CellIdRankType:
    case CellIdRatingType:
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      break;
    case CellIdRank:
      cell = [TableViewCellFactory cellWithType:SliderWithValueLabelAndStepperCellType tableView:tableView];
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
      cell.textLabel.text = [GoUtilities stringWithDescriptionOfGameInfoRank:self.gameInfoRankToEdit];
      cell.textLabel.textAlignment = NSTextAlignmentCenter;
      break;
    }
    case CellIdSgfString:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Rank description";
      variableHeightCell.valueLabel.text = self.gameInfoRankToEdit.sgfString;
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case CellIdRankType:
    {
      cell.textLabel.text = @"Rank type";
      cell.detailTextLabel.text = [NSString stringWithRankType:self.gameInfoRankToEdit.rankType];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case CellIdRank:
    {
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Rank";
      [sliderCell setDelegate:self
         actionValueDidChange:@selector(rankDidChange:)
               valueFormatter:nil];
      [sliderCell setValue:(int)self.gameInfoRankToEdit.rank minimumValue:1 maximumValue:100];
      break;
    }
    case CellIdRatingType:
    {
      cell.textLabel.text = @"Rating type";
      cell.detailTextLabel.text = [NSString stringWithRatingType:self.gameInfoRankToEdit.ratingType];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case CellIdAddSgfString:
    {
      cell.textLabel.text = @"Add rank description";
      break;
    }
    case CellIdAddStructuredData:
    {
      cell.textLabel.text = @"Add numeric rank";
      break;
    }
    case CellIdDiscardData:
    {
      cell.textLabel.text = @"Discard rank information";
      break;
    }
  }
}

#pragma mark - Private helpers for tableView:didSelectRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:didSelectRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) showEditTextControllerForCellIdSgfString
{
  NSString* textToEdit = self.gameInfoRankToEdit.sgfString;
  NSString* titleString = @"Edit rank description";

  EditTextController* editTextController = [EditTextController controllerWithText:textToEdit
                                                                            style:EditTextControllerStyleTextField
                                                                         delegate:self];
  editTextController.title = titleString;

  [self presentNavigationControllerWithRootViewController:editTextController];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:didSelectRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) showItemPickerControllerForCellId:(enum CellId)cellId indexPath:(NSIndexPath*)indexPath
{
  NSString* screenTitle;
  NSString* footerTitle = nil;
  NSMutableArray* itemList = [NSMutableArray array];
  int indexOfDefaultItem = -1;

  if (cellId == CellIdRankType)
  {
    screenTitle = @"Select rank type";
    enum GoGameInfoRankType defaultRankType = self.gameInfoRankToEdit.rankType;
    for (enum GoGameInfoRankType rankType = GoGameInfoRankTypeFirst; rankType <= GoGameInfoRankTypeLast; ++rankType)
    {
      NSString* rankTypeString = [NSString stringWithRankType:rankType];
      [itemList addObject:rankTypeString];
      if (rankType == defaultRankType)
        indexOfDefaultItem = rankType;
    }
  }
  else
  {
    screenTitle = @"Select rating type";
    enum GoGameInfoRatingType defaultRatingType = self.gameInfoRankToEdit.ratingType;
    for (enum GoGameInfoRatingType ratingType = GoGameInfoRatingTypeFirst; ratingType <= GoGameInfoRatingTypeLast; ++ratingType)
    {
      NSString* ratingTypeString = [NSString stringWithRatingType:ratingType];
      [itemList addObject:ratingTypeString];
      if (ratingType == defaultRatingType)
        indexOfDefaultItem = ratingType;
    }
  }

  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                screenTitle:screenTitle
                                                                         indexOfDefaultItem:indexOfDefaultItem
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:cellId];
  itemPickerController.footerTitle = footerTitle;
  [self presentNavigationControllerWithRootViewController:itemPickerController];
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
    self.gameInfoRankToEdit.sgfString = editTextController.text;

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:SgfStringItem inSection:DataSection];
    NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationNone];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection && controller.indexOfDefaultItem != controller.indexOfSelectedItem)
  {
    NSNumber* cellIdAsNumber = controller.context;
    enum CellId cellId = [cellIdAsNumber intValue];
    NSInteger tableRowToReload;
    if (cellId == CellIdRankType)
    {
      self.gameInfoRankToEdit.rankType = controller.indexOfSelectedItem;
      tableRowToReload = RankTypeItem;
    }
    else
    {
      self.gameInfoRankToEdit.ratingType = controller.indexOfSelectedItem;
      tableRowToReload = RatingTypeItem;
    }

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:tableRowToReload inSection:DataSection];
    NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationNone];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the value of the "Rank" slider.
// -----------------------------------------------------------------------------
- (void) rankDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.gameInfoRankToEdit.rank = sliderCell.value;
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  // Modify the data type if the user did not enter the required string value.
  // The alternative to modifying the data type would be to treat the incomplete
  // data as invalid and disable the "Done" button, but this could be viewed to
  // be overly strict and annoying.
  if (self.gameInfoRankToEdit.dataType == GoGameInfoRankDataTypeSgfString)
  {
    if (self.gameInfoRankToEdit.sgfString.length == 0)
    {
      self.gameInfoRankToEdit.dataType = GoGameInfoRankDataTypeNone;
      self.gameInfoRankToEdit.sgfString = nil;
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

  bool didChangeRankInformation;
  if (self.gameInfoRank.dataType != self.gameInfoRankToEdit.dataType)
    didChangeRankInformation = true;
  else if (areStringValuesDifferent(self.gameInfoRank.sgfString, self.gameInfoRankToEdit.sgfString))
    didChangeRankInformation = true;
  else if (self.gameInfoRank.rankType != self.gameInfoRankToEdit.rankType)
    didChangeRankInformation = true;
  else if (self.gameInfoRank.rank != self.gameInfoRankToEdit.rank)
    didChangeRankInformation = true;
  else if (self.gameInfoRank.ratingType != self.gameInfoRankToEdit.ratingType)
    didChangeRankInformation = true;
  else
    didChangeRankInformation = false;

  [self updateGameInfoRank:self.gameInfoRank withDataFrom:self.gameInfoRankToEdit];

  [self.delegate editGameInfoRankControllerDidEndEditing:self didChangeRankInformation:didChangeRankInformation];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled editing.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  bool didChangeRankInformation = false;
  [self.delegate editGameInfoRankControllerDidEndEditing:self didChangeRankInformation:didChangeRankInformation];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a indexPath.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == DataSection)
  {
    switch (self.gameInfoRankToEdit.dataType)
    {
      case GoGameInfoRankDataTypeNone:
        return CellIdNoData;
      case GoGameInfoRankDataTypeSgfString:
        return CellIdSgfString;
      case GoGameInfoRankDataTypeStructuredData:
        if (indexPath.row == RankTypeItem)
          return CellIdRankType;
        else if (indexPath.row == RankItem)
          return CellIdRank;
        else
          return CellIdRatingType;
    }
  }
  else
  {
    switch (self.gameInfoRankToEdit.dataType)
    {
      case GoGameInfoRankDataTypeNone:
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
/// @brief Updates @a gameInfoRank with data that is currently stored in
/// @a gameInfoRankSource.
// -----------------------------------------------------------------------------
- (void) updateGameInfoRank:(GoGameInfoRank*)gameInfoRank
               withDataFrom:(GoGameInfoRank*)gameInfoRankSource
{
  gameInfoRank.dataType = gameInfoRankSource.dataType;
  switch (gameInfoRankSource.dataType)
  {
    case GoGameInfoRankDataTypeNone:
      gameInfoRank.sgfString = nil;
      gameInfoRank.rankType = GoGameInfoRankTypeKyu;
      gameInfoRank.rank = 30;
      gameInfoRank.ratingType = GoGameInfoRatingTypeUnspecified;
      break;
    case GoGameInfoRankDataTypeSgfString:
      gameInfoRank.sgfString = gameInfoRankSource.sgfString;
      gameInfoRank.rankType = GoGameInfoRankTypeKyu;
      gameInfoRank.rank = 30;
      gameInfoRank.ratingType = GoGameInfoRatingTypeUnspecified;
      break;
    case GoGameInfoRankDataTypeStructuredData:
      gameInfoRank.sgfString = nil;
      gameInfoRank.rankType = gameInfoRankSource.rankType;
      gameInfoRank.rank = gameInfoRankSource.rank;
      gameInfoRank.ratingType = gameInfoRankSource.ratingType;
      break;
  }
}

@end
