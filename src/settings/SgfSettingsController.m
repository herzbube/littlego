// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "SgfSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../shared/LayoutManager.h"
#import "../sgf/SgfSettingsModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"
#import "../ui/UIViewControllerAdditions.h"
#import "../utility/ExceptionUtility.h"
#import "../utility/UIColorAdditions.h"

// Library includes
#import <iconv.h>

// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Smart Game Format" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum SgfTableViewSection
{
  SyntaxCheckingLevelSection,
  EncodingSection,
  OtherSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the SyntaxCheckingLevelSection.
// -----------------------------------------------------------------------------
enum SyntaxCheckingLevelSectionItem
{
  SyntaxCheckingLevelItem,
  SyntaxCheckingLevelAdvancedConfigurationItem,
  MaxSyntaxCheckingLevelSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the EncodingSection.
// -----------------------------------------------------------------------------
enum EncodingSectionItem
{
  EncodingModeItem,
  DefaultEncodingItem,
  ForcedEncodingItem,
  MaxEncodingSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the OtherSection.
// -----------------------------------------------------------------------------
enum OtherSectionItem
{
  ReverseVariationOrderingItem,
  MaxOtherSectionItem,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SgfSettingsController.
// -----------------------------------------------------------------------------
@interface SgfSettingsController()
@property(nonatomic, assign) SgfSettingsModel* sgfSettingsModel;
@end


@implementation SgfSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a SgfSettingsController instance
/// of grouped style.
// -----------------------------------------------------------------------------
+ (SgfSettingsController*) controller
{
  SgfSettingsController* controller = [[SgfSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.sgfSettingsModel = [ApplicationDelegate sharedDelegate].sgfSettingsModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SgfSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sgfSettingsModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Smart Game Format (SGF)";
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
    case SyntaxCheckingLevelSection:
      return MaxSyntaxCheckingLevelSectionItem;
    case EncodingSection:
      return MaxEncodingSectionItem;
    case OtherSection:
      return MaxOtherSectionItem;
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
    case SyntaxCheckingLevelSection:
      return @"Syntax checking level";
    case EncodingSection:
      return @"Text encoding";
    case OtherSection:
      return @"Other";
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
    case SyntaxCheckingLevelSection:
    {
      switch (indexPath.row)
      {
        case SyntaxCheckingLevelItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Syntax checking level";
          if (customSyntaxCheckingLevel == self.sgfSettingsModel.syntaxCheckingLevel)
            cell.detailTextLabel.text = @"Custom";
          else
            cell.detailTextLabel.text = [self syntaxCheckingLevelName:self.sgfSettingsModel.syntaxCheckingLevel];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case SyntaxCheckingLevelAdvancedConfigurationItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
          cell.textLabel.text = @"Advanced configuration";
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
      break;
    }
    case EncodingSection:
    {
      switch (indexPath.row)
      {
        case EncodingModeItem:
        {
          enum TableViewCellType cellType = Value1CellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          cell.textLabel.text = @"Encoding mode";
          cell.detailTextLabel.text = [self encodingModeName:self.sgfSettingsModel.encodingMode];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case DefaultEncodingItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Default encoding";
          if (self.sgfSettingsModel.defaultEncoding.length == 0)
            cell.detailTextLabel.text = @"<None>";
          else
            cell.detailTextLabel.text = self.sgfSettingsModel.defaultEncoding;
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case ForcedEncodingItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Forced encoding";
          if (self.sgfSettingsModel.forcedEncoding.length == 0)
            cell.detailTextLabel.text = @"<None>";
          else
            cell.detailTextLabel.text = self.sgfSettingsModel.forcedEncoding;
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
      break;
    }
    case OtherSection:
    {
      switch (indexPath.row)
      {
        case ReverseVariationOrderingItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Reverse variation ordering";
          accessoryView.on = self.sgfSettingsModel.reverseVariationOrdering;
          [accessoryView addTarget:self action:@selector(toggleReverseVariationOrdering:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        default:
        {
          assert(0);
          @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
          break;
        }
      }
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

  if (SyntaxCheckingLevelSection == indexPath.section)
  {
    switch (indexPath.row)
    {
      case SyntaxCheckingLevelItem:
      {
        NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
        for (int syntaxCheckingLevel = minimumSyntaxCheckingLevel; syntaxCheckingLevel <= maximumSyntaxCheckingLevel; ++syntaxCheckingLevel)
        {
          NSString* syntaxCheckingLevelString = [self syntaxCheckingLevelName:syntaxCheckingLevel];
          [itemList addObject:syntaxCheckingLevelString];
        }
        int indexOfDefaultSyntaxCheckingLevel;
        NSString* screenTitle = @"Syntax checking level";
        NSString* footerTitle = [NSString stringWithFormat:@"The recommended syntax checking level is \"%@\".", [self syntaxCheckingLevelName:defaultSyntaxCheckingLevel]];

        if (customSyntaxCheckingLevel == self.sgfSettingsModel.syntaxCheckingLevel)
          indexOfDefaultSyntaxCheckingLevel = -1;
        else
          indexOfDefaultSyntaxCheckingLevel = self.sgfSettingsModel.syntaxCheckingLevel - minimumSyntaxCheckingLevel;
        ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                      screenTitle:screenTitle
                                                                               indexOfDefaultItem:indexOfDefaultSyntaxCheckingLevel
                                                                                         delegate:self];
        itemPickerController.context = indexPath;
        itemPickerController.footerTitle = footerTitle;
        UINavigationController* navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:itemPickerController];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        navigationController.delegate = [LayoutManager sharedManager];
        [self presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
        break;
      }
      case SyntaxCheckingLevelAdvancedConfigurationItem:
      {
        SgfSyntaxCheckingLevelSettingsController* sgfSyntaxCheckingLevelSettingsController = [[SgfSyntaxCheckingLevelSettingsController controllerWithDelegate:self] retain];
        [self.navigationController pushViewController:sgfSyntaxCheckingLevelSettingsController animated:YES];
        [sgfSyntaxCheckingLevelSettingsController release];
        break;
      }
      default:
      {
        assert(0);
        break;
      }
    }
  }
  else if (EncodingSection == indexPath.section)
  {
    if (indexPath.row == EncodingModeItem)
    {
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      [itemList addObject:[self encodingModeName:SgfEncodingModeSingleEncoding]];
      [itemList addObject:[self encodingModeName:SgfEncodingModeMultipleEncodings]];
      [itemList addObject:[self encodingModeName:SgfcEncodingModeBoth]];

      int indexOfDefaultItem = self.sgfSettingsModel.encodingMode;
      NSString* screenTitle = @"Select the encoding mode";
      NSString* footerTitle = [NSString stringWithFormat:@"\"%@\" first tries loading SGF data with \"%@\" mode. If that fails with a fatal error it then tries again with \"%@\" mode.\n\nThe recommended encoding mode is \"%@\".",
                               [self encodingModeName:SgfcEncodingModeBoth],
                               [self encodingModeName:SgfEncodingModeSingleEncoding],
                               [self encodingModeName:SgfEncodingModeMultipleEncodings],
                               [self encodingModeName:SgfcEncodingModeDefault]];

      ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                    screenTitle:screenTitle
                                                                             indexOfDefaultItem:indexOfDefaultItem
                                                                                       delegate:self];
      itemPickerController.itemPickerControllerMode = ItemPickerControllerModeNonModal;
      itemPickerController.context = indexPath;
      itemPickerController.footerTitle = footerTitle;
      [self.navigationController pushViewController:itemPickerController animated:YES];
    }
    else if (indexPath.row == DefaultEncodingItem || indexPath.row == ForcedEncodingItem)
    {
      NSString* editText;
      NSString* title;
      if (indexPath.row == DefaultEncodingItem)
      {
        editText = self.sgfSettingsModel.defaultEncoding;
        title = @"Edit default encoding";
      }
      else
      {
        editText = self.sgfSettingsModel.forcedEncoding;
        title = @"Edit forced encoding";
      }
      EditTextController* editTextController = [EditTextController controllerWithText:editText
                                                                                style:EditTextControllerStyleTextField
                                                                             delegate:self];
      editTextController.title = title;
      editTextController.acceptEmptyText = true;
      editTextController.context = indexPath;
      UINavigationController* navigationController = [[UINavigationController alloc]
                                                      initWithRootViewController:editTextController];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      navigationController.delegate = [LayoutManager sharedManager];
      [self presentViewController:navigationController animated:YES completion:nil];
      [navigationController release];
    }
  }
}

#pragma mark - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  bool shouldEndEditingWithText;

  const char* fromCode = [text UTF8String];
  const char* toCode = "UTF-8";
  iconv_t iconvDescriptor = iconv_open(toCode, fromCode);
  if (iconvDescriptor == (iconv_t)(-1))
  {
    shouldEndEditingWithText = false;

    NSString* message = nil;
    if (errno == EINVAL)
      message = [NSString stringWithFormat:@"Conversion from text encoding \"%@\" is not possible on this system.\n\nThe text encoding is either invalid, or it is not supported on this system.", text];
    else
      message = [NSString stringWithFormat:@"An unexpected error occurred while trying to find out if \"%@\" is a valid text encoding.\n\nThe system error code is %d.", text, errno];

    [editTextController presentOkAlertWithTitle:@"Text encoding validation failed" message:message];
  }
  else
  {
    shouldEndEditingWithText = true;
    iconv_close(iconvDescriptor);
  }

  return shouldEndEditingWithText;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  if (! didCancel)
  {
    if (editTextController.textHasChanged)
    {
      NSIndexPath* context = editTextController.context;
      NSInteger itemFromContext = context.row;

      if (itemFromContext == DefaultEncodingItem)
        self.sgfSettingsModel.defaultEncoding = editTextController.text;
      else
        self.sgfSettingsModel.forcedEncoding = editTextController.text;

      NSIndexPath* indexPathToReload = [NSIndexPath indexPathForRow:itemFromContext inSection:EncodingSection];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPathToReload];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
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
      NSIndexPath* context = itemPickerController.context;
      if (SyntaxCheckingLevelSection == context.section)
        self.sgfSettingsModel.syntaxCheckingLevel = (minimumSyntaxCheckingLevel + itemPickerController.indexOfSelectedItem);
      else
        self.sgfSettingsModel.encodingMode = itemPickerController.indexOfSelectedItem;

      NSArray* indexPaths = [NSArray arrayWithObject:context];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SgfSyntaxCheckingLevelSettingsDelegate overrides

// -----------------------------------------------------------------------------
/// @brief SgfSyntaxCheckingLevelSettingsDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeSyntaxCheckingLevel:(SgfSyntaxCheckingLevelSettingsController*)sgfSyntaxCheckingLevelSettingsController
{
  NSUInteger sectionIndex = SyntaxCheckingLevelSection;
  NSUInteger rowIndex = SyntaxCheckingLevelItem;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Reverse variation ordering" switch.
/// Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleReverseVariationOrdering:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.sgfSettingsModel.reverseVariationOrdering = accessoryView.on;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a syntaxCheckingLevel that is
/// suitable for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a syntaxCheckingLevel is not
/// recognized.
// -----------------------------------------------------------------------------
- (NSString*) syntaxCheckingLevelName:(int)syntaxCheckingLevel
{
  switch (syntaxCheckingLevel)
  {
    case 0:
      return @"Custom";
    case 1:
      return @"Minimal";
    case 2:
      return @"Medium";
    case 3:
      return @"Strict";
    case 4:
      return @"Maximum";
    default:
      [ExceptionUtility throwNotImplementedException];
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a encodingMode that is
/// suitable for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a encodingMode is not
/// recognized.
// -----------------------------------------------------------------------------
- (NSString*) encodingModeName:(enum SgfEncodingMode)encodingMode
{
  switch (encodingMode)
  {
    case SgfEncodingModeSingleEncoding:
      return @"Single encoding";
    case SgfEncodingModeMultipleEncodings:
      return @"Multiple encodings";
    case SgfcEncodingModeBoth:
      return @"Try both modes";
    default:
      [ExceptionUtility throwNotImplementedException];
      return nil;
  }
}

@end
