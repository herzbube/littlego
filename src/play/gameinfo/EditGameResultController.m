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
#import "EditGameResultController.h"
#import "../../go/GoGameResult.h"
#import "../../go/GoUtilities.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewVariableHeightCell.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game result" table view.
// -----------------------------------------------------------------------------
enum GameResultTableViewSection
{
  DataSection,
  UpdatePolicySection,
  MaxSection,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DataSection.
// -----------------------------------------------------------------------------
enum DataSectionItem
{
  NoResultItem,
  SetResultItem,
  MaxDataSectionItem_NoResult,

  SgfStringItem = 0,
  DiscardSgfStringItem,
  MaxDataSectionItem_SgfString,

  ResultTypeItem_NoWinner = 0,
  DiscardResultItem_NoWinner,
  MaxDataSectionItem_StructuredData_NoWinner,

  ResultTypeItem_NoScore = 0,
  WinTypeItem_NoScore,
  DiscardResultItem_NoScore,
  MaxDataSectionItem_StructuredData_NoScore,

  ResultTypeItem_Score = 0,
  WinTypeItem_Score,
  ScoreItem_Score,
  DiscardResultItem_Score,
  MaxDataSectionItem_StructuredData_Score,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the UpdatePolicySection.
// -----------------------------------------------------------------------------
enum UpdatePolicySectionItem
{
  UpdatePolicyItem,
  MaxUpdatePolicySectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates all table view cells that can ever appear in the
/// "Game result" table view, without regard to the conditions under which
/// they appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// nested switch/if statements.
// -----------------------------------------------------------------------------
enum CellId
{
  CellIdNoResult,
  CellIdSgfString,
  CellIdResultTye,
  CellIdWinType,
  CellIdScore,
  CellIdSetResult,
  CellIdDiscardResult,
  CellIdUpdatePolicy,
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for EditGameResultController.
// -----------------------------------------------------------------------------
@interface EditGameResultController()
@property(nonatomic, retain) GoGameResult* gameResult;
@end


@implementation EditGameResultController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGameResultController
/// instance that is used to edit the values of @a gameResult.
// -----------------------------------------------------------------------------
+ (EditGameResultController*) controllerWithGameResult:(GoGameResult*)gameResult
                                              delegate:(id<EditGameResultDelegate>)delegate
{
  return [[[EditGameResultController alloc] initWithGameResult:gameResult
                                                      delegate:delegate] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditGameResultController object with @a gameResult.
///
/// @note This is the designated initializer of EditGameResultController.
// -----------------------------------------------------------------------------
- (id) initWithGameResult:(GoGameResult*)gameResult
                 delegate:(id<EditGameResultDelegate>)delegate
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;

  self.gameResult = gameResult;
  self.delegate = delegate;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGameResultController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (self.delegate)
    [self.delegate editGameResultController:self gameResultEditingDidFinish:self.gameResult];

  self.gameResult = nil;
  self.delegate = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.title = @"Edit game result";
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
    return MaxUpdatePolicySectionItem;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (section == DataSection)
  {
    if (self.gameResult.dataType == GoGameResultDataTypeSgfString)
      return @"The app was unable to parse the game result text that was found in the game that was most recently loaded from the archive. Above you see the text that the app encountered and that it was unable to parse.";
    else
      return nil;
  }
  else
  {
    return @"When this setting is enabled, the app is allowed to change the game result when the game ends during normal game play (e.g. a player resigns). When this setting is disabled, only the user is allowed to change the game result.";
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
    case CellIdResultTye:
    case CellIdWinType:
      [self showItemPickerForCellId:cellId];
      break;
    case CellIdScore:
      [self showEditTextControllerForCellIdScore];
      break;
    case CellIdSetResult:
      self.gameResult.dataType = GoGameResultDataTypeStructuredData;
      self.gameResult.gameResultType = GoGameResultTypeUnknownResult;
      [self.tableView reloadData];
      if (self.delegate)
        [self.delegate editGameResultController:self gameResultDidChange:self.gameResult];
      break;
    case CellIdDiscardResult:
      self.gameResult.dataType = GoGameResultDataTypeNoResult;
      [self.tableView reloadData];
      if (self.delegate)
        [self.delegate editGameResultController:self gameResultDidChange:self.gameResult];
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
  switch (self.gameResult.dataType)
  {
    case GoGameResultDataTypeNoResult:
      return MaxDataSectionItem_NoResult;
    case GoGameResultDataTypeSgfString:
      return MaxDataSectionItem_SgfString;
    case GoGameResultDataTypeStructuredData:
      switch (self.gameResult.gameResultType)
      {
        case GoGameResultTypeBlackWin:
        case GoGameResultTypeWhiteWin:
          if (self.gameResult.winType == GoGameResultWinTypeWinWithScore)
            return MaxDataSectionItem_StructuredData_Score;
          else
            return MaxDataSectionItem_StructuredData_NoScore;
        default:
          return MaxDataSectionItem_StructuredData_NoWinner;
      }
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
    case CellIdNoResult:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      break;
    }
    case CellIdSgfString:
    {
      cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
      break;
    }
    case CellIdResultTye:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      break;
    }
    case CellIdWinType:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      break;
    }
    case CellIdScore:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      break;
    }
    case CellIdSetResult:
    {
      cell = [TableViewCellFactory cellWithType:ActionTextCellType tableView:tableView];
      break;
    }
    case CellIdDiscardResult:
    {
      cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
      break;
    }
    case CellIdUpdatePolicy:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      break;
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
    case CellIdNoResult:
    {
      cell.textLabel.text = [GoUtilities stringWithDescriptionOfGameResult:self.gameResult];
      cell.textLabel.textAlignment = NSTextAlignmentCenter;
      break;
    }
    case CellIdSgfString:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = @"Result text";
      variableHeightCell.valueLabel.text = self.gameResult.sgfString;
      break;
    }
    case CellIdResultTye:
    {
      cell.textLabel.text = @"Result type";
      cell.detailTextLabel.text = [NSString stringWithGameResultType:self.gameResult.gameResultType];
      break;
    }
    case CellIdWinType:
    {
      cell.textLabel.text = @"Win type";
      cell.detailTextLabel.text = [NSString stringWithWinType:self.gameResult.winType];
      break;
    }
    case CellIdScore:
    {
      cell.textLabel.text = @"Score";
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f", self.gameResult.score];
      break;
    }
    case CellIdSetResult:
    {
      cell.textLabel.text = @"Add a result";
      break;
    }
    case CellIdDiscardResult:
    {
      cell.textLabel.text = @"Discard current result";
      break;
    }
    case CellIdUpdatePolicy:
    {
      cell.textLabel.text = @"Allow automatic updates";
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.on = (self.gameResult.updatePolicy == GoGameResultUpdatePolicyAutomatic);
      [accessoryView removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
      [accessoryView addTarget:self action:@selector(toggleUpdatePolicy:) forControlEvents:UIControlEventValueChanged];
      break;
    }
  }
}

#pragma mark - Private helpers for tableView:didSelectRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:didSelectRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) showItemPickerForCellId:(enum CellId)cellId
{
  NSString* screenTitle;
  NSString* footerTitle = nil;
  NSMutableArray* itemList = [NSMutableArray array];
  int indexOfDefaultItem = -1;

  switch (cellId)
  {
    case CellIdResultTye:
      screenTitle = @"Select result type";
      enum GoGameResultType defaultGameResultType = self.gameResult.gameResultType;
      for (enum GoGameResultType gameResultType = GoGameResultTypeFirst; gameResultType <= GoGameResultTypeLast; ++gameResultType)
      {
        NSString* gameResultTypeString = [NSString stringWithGameResultType:gameResultType];
        [itemList addObject:gameResultTypeString];
        if (gameResultType == defaultGameResultType)
          indexOfDefaultItem = gameResultType;
      }
      break;
    case CellIdWinType:
      screenTitle = [NSString stringWithFormat:@"%@ ...", [NSString stringWithGameResultType:self.gameResult.gameResultType]];
      enum GoGameResultWinType defaultWinType = self.gameResult.winType;
      for (enum GoGameResultWinType winType = GoGameResultWinTypeFirst; winType <= GoGameResultWinTypeLast; ++winType)
      {
        NSString* winTypeString = [NSString stringWithWinType:winType];
        [itemList addObject:winTypeString];
        if (winType == defaultWinType)
          indexOfDefaultItem = winType;
      }
      break;
    default:
      assert(0);
      return;
  }

  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                screenTitle:screenTitle
                                                                         indexOfDefaultItem:indexOfDefaultItem
                                                                                   delegate:self];
  itemPickerController.context = [NSNumber numberWithInt:cellId];
  itemPickerController.footerTitle = footerTitle;
  [self presentNavigationControllerWithRootViewController:itemPickerController];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:didSelectRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) showEditTextControllerForCellIdScore
{
  NSString* scoreAsString = [NSString stringWithScore:self.gameResult.score];

  EditTextController* editTextController = [EditTextController controllerWithText:scoreAsString
                                                                            style:EditTextControllerStyleTextField
                                                                         delegate:self];
  editTextController.title = @"Enter score value";
  editTextController.keyboardType = UIKeyboardTypeDecimalPad;

  [self presentNavigationControllerWithRootViewController:editTextController];
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
    switch (cellId)
    {
      case CellIdResultTye:
      {
        enum GoGameResultType oldGameResultType = self.gameResult.gameResultType;
        enum GoGameResultType newGameResultType = controller.indexOfSelectedItem;

        self.gameResult.gameResultType = newGameResultType;

        switch (newGameResultType)
        {
          case GoGameResultTypeBlackWin:
          case GoGameResultTypeWhiteWin:
          {
            if (oldGameResultType != GoGameResultTypeBlackWin &&
                oldGameResultType != GoGameResultTypeWhiteWin)
            {
              self.gameResult.winType = GoGameResultWinTypeWinWithoutScore;
              self.gameResult.score = 1.0;
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
      case CellIdWinType:
      {
        enum GoGameResultWinType newWinType = controller.indexOfSelectedItem;

        self.gameResult.winType = newWinType;

        switch (newWinType)
        {
          case GoGameResultWinTypeWinWithScore:
            self.gameResult.score = 1.0;
            break;
          default:
            break;
        }

        break;
      }
      default:
      {
        assert(0);
        break;
      }
    }

    [self.tableView reloadData];
    if (self.delegate)
      [self.delegate editGameResultController:self gameResultDidChange:self.gameResult];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController isTextValid:(NSString*)text validationErrorMessage:(NSString**)validationErrorMessage
{
  bool isValidScore = [self controller:editTextController isValidScore:text];

  if (validationErrorMessage)
  {
    if (isValidScore)
      *validationErrorMessage = nil;
    else
      *validationErrorMessage = @"Please enter a numeric score value greater than zero.";
  }

  return isValidScore;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  return [self controller:editTextController isValidScore:text];
}

// -----------------------------------------------------------------------------
/// @brief Helper method for EditTextDelegate protocol methods.
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController isValidScore:(NSString*)text
{
  double score;
  bool success = [text tryConvertToDoubleValue:&score];

  // Only accept positive score values - it doesn't make sense to say that a
  // player wins with a zero - or even a negative - score. Note that the
  // initial value may actually be zero or negative, in case such a value was
  // read from SGF. The user in that case can call up EditTextController, but
  // can only dismiss it with the Cancel button.
  return (success && score > 0.0);
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel
{
  if (! didCancel)
  {
    // No need to check whether conversion is successful => if it were not the
    // user could not have ended editing with didCancel = false
    double score;
    [editTextController.text tryConvertToDoubleValue:&score];

    self.gameResult.score = score;

    NSUInteger sectionIndex = DataSection;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ScoreItem_Score inSection:sectionIndex];
    NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationNone];

    if (self.delegate)
      [self.delegate editGameResultController:self gameResultDidChange:self.gameResult];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Allow automatic updates" switch.
// -----------------------------------------------------------------------------
- (void) toggleUpdatePolicy:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  if (accessoryView.on)
    self.gameResult.updatePolicy = GoGameResultUpdatePolicyAutomatic;
  else
    self.gameResult.updatePolicy = GoGameResultUpdatePolicyManual;

  if (self.delegate)
    [self.delegate editGameResultController:self gameResultDidChange:self.gameResult];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a indexPath.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == UpdatePolicySection)
    return CellIdUpdatePolicy;

  switch (self.gameResult.dataType)
  {
    case GoGameResultDataTypeNoResult:
    {
      if (indexPath.row == NoResultItem)
        return CellIdNoResult;
      else
        return CellIdSetResult;
    }
    case GoGameResultDataTypeSgfString:
    {
      if (indexPath.row == SgfStringItem)
        return CellIdSgfString;
      else
        return CellIdDiscardResult;
    }
    case GoGameResultDataTypeStructuredData:
    {
      return [self cellIdForStructuredDataRow:indexPath.row];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a row, given that
/// the game result holds structured data (#GoGameResultDataTypeStructuredData).
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForStructuredDataRow:(NSInteger)row
{
  switch (self.gameResult.gameResultType)
  {
    case GoGameResultTypeBlackWin:
    case GoGameResultTypeWhiteWin:
    {
      if (self.gameResult.winType == GoGameResultWinTypeWinWithScore)
        return [self cellIdForWinWithScore:row];
      else
        return [self cellIdForWinWithoutScore:row];
    }
    default:
    {
      return [self cellIdForNoWinner:row];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a row, given that
/// the game result holds structured data (#GoGameResultDataTypeStructuredData),
/// has either #GoGameResultTypeBlackWin or #GoGameResultTypeWhiteWin, and
/// has #GoGameResultWinTypeWinWithScore.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForWinWithScore:(NSInteger)row
{
  switch (row)
  {
    case ResultTypeItem_Score:
      return CellIdResultTye;
    case WinTypeItem_Score:
      return CellIdWinType;
    case ScoreItem_Score:
      return CellIdScore;
    case DiscardResultItem_Score:
      return CellIdDiscardResult;
    default:
      assert(0);
      return -1;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a row, given that
/// the game result holds structured data (#GoGameResultDataTypeStructuredData),
/// has either #GoGameResultTypeBlackWin or #GoGameResultTypeWhiteWin, and
/// has a win type that is not #GoGameResultWinTypeWinWithScore.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForWinWithoutScore:(NSInteger)row
{
  switch (row)
  {
    case ResultTypeItem_NoScore:
      return CellIdResultTye;
    case WinTypeItem_NoScore:
      return CellIdWinType;
    case DiscardResultItem_NoScore:
      return CellIdDiscardResult;
    default:
      assert(0);
      return -1;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a row, given that
/// the game result holds structured data (#GoGameResultDataTypeStructuredData),
/// and has neither #GoGameResultTypeBlackWin nor #GoGameResultTypeWhiteWin.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForNoWinner:(NSInteger)row
{
  switch (row)
  {
    case ResultTypeItem_NoWinner:
      return CellIdResultTye;
    case DiscardResultItem_NoWinner:
      return CellIdDiscardResult;
    default:
      assert(0);
      return -1;
  }
}

@end
