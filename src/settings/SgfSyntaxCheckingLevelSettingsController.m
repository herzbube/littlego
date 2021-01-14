// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "SgfSyntaxCheckingLevelSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../sgf/SgfSettingsModel.h"
#import "../shared/LayoutManager.h"
#import "../ui/TableViewCellFactory.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Playing strength settings"
/// table view.
// -----------------------------------------------------------------------------
enum SgfSyntaxCheckingLevelSettingsTableViewSection
{
  LoadSuccessTypeSection,
  EnableRestrictiveCheckingSection,
  DisableAllWarningMessagesSection,
  DisabledMessagesSection,
  ResetToDefaultsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the LoadSuccessTypeSection.
// -----------------------------------------------------------------------------
enum LoadSuccessTypeSectionItem
{
  LoadSuccessTypeItem,
  MaxLoadSuccessTypeSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the EnableRestrictiveCheckingSection.
// -----------------------------------------------------------------------------
enum EnableRestrictiveCheckingSectionItem
{
  EnableRestrictiveCheckingItem,
  MaxEnableRestrictiveCheckingSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DisableAllWarningMessagesSection.
// -----------------------------------------------------------------------------
enum DisableAllWarningMessagesSectionItem
{
  DisableAllWarningMessagesItem,
  MaxDisableAllWarningMessagesSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DisabledMessagesSection.
// -----------------------------------------------------------------------------
enum DisabledMessagesSectionItem
{
  DisabledMessagesItem,
  MaxDisabledMessagesSectionItem
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
/// @brief Class extension with private properties for
/// SgfSyntaxCheckingLevelSettingsController.
// -----------------------------------------------------------------------------
@interface SgfSyntaxCheckingLevelSettingsController()
@property(nonatomic, retain) SgfSettingsModel* sgfSettingsModel;
@end


@implementation SgfSyntaxCheckingLevelSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an
/// SgfSyntaxCheckingLevelSettingsController instance of grouped style that is
/// used to edit the playing strength attributes of @a profile.
// -----------------------------------------------------------------------------
+ (SgfSyntaxCheckingLevelSettingsController*) controllerWithDelegate:(id<SgfSyntaxCheckingLevelSettingsDelegate>)delegate
{
  SgfSyntaxCheckingLevelSettingsController* controller = [[SgfSyntaxCheckingLevelSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.sgfSettingsModel = [ApplicationDelegate sharedDelegate].sgfSettingsModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// SgfSyntaxCheckingLevelSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
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
  self.navigationItem.title = @"Syntax checking level";
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
    case LoadSuccessTypeSection:
      return MaxLoadSuccessTypeSectionItem;
    case EnableRestrictiveCheckingSection:
      return MaxEnableRestrictiveCheckingSectionItem;
    case DisableAllWarningMessagesSection:
      return MaxDisableAllWarningMessagesSectionItem;
    case DisabledMessagesSection:
      return MaxDisabledMessagesSectionItem;
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
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case LoadSuccessTypeSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Load success type";
      cell.detailTextLabel.text = [self loadSuccessTypeName:self.sgfSettingsModel.loadSuccessType];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case EnableRestrictiveCheckingSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Restrictive checking";
      accessoryView.on = self.sgfSettingsModel.enableRestrictiveChecking;
      [accessoryView addTarget:self action:@selector(toggleEnableRestrictiveChecking:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case DisableAllWarningMessagesSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Disable all warning messages";
      accessoryView.on = self.sgfSettingsModel.disableAllWarningMessages;
      [accessoryView addTarget:self action:@selector(toggleDisableAllWarningMessages:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case DisabledMessagesSection:
    {
      enum TableViewCellType cellType = Value1CellType;
      cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
      cell.textLabel.text = @"Disabled messages";
      cell.detailTextLabel.text = [self.sgfSettingsModel.disabledMessages componentsJoinedByString:@", "];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
      break;
    }
  }

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case LoadSuccessTypeSection:
      return @"What kinds of warning and/or error messages may be present for the app to still accept SGF data and load it.";
    case EnableRestrictiveCheckingSection:
      return @"Make SGF data parsing even more pedantic than usual. Enable this only if you want to examine external SGF data for bad style or uncommon characteristics.";
    case DisableAllWarningMessagesSection:
      return @"Loading SGF data generates no warnings whatsoever (neither critical nor non-critical warnings). Use with care!";
    case DisabledMessagesSection:
      return @"List of specific warning and/or error messages (both critical and non-critical) that are disabled, i.e. they are not generated when SGF data is loaded.";
    default:
      break;
  }
  return nil;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (LoadSuccessTypeSection == indexPath.section)
  {
    NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
    [itemList addObject:[self loadSuccessTypeName:SgfLoadSuccessTypeNoWarningsOrErrors]];
    [itemList addObject:[self loadSuccessTypeName:SgfLoadSuccessTypeNoCriticalWarningsOrErrors]];
    [itemList addObject:[self loadSuccessTypeName:SgfLoadSuccessTypeWithCriticalWarningsOrErrors]];
    int indexOfDefaultItem = self.sgfSettingsModel.loadSuccessType;
    NSString* screenTitle = @"Select load success type";
    NSString* footerTitle = [NSString stringWithFormat:@"The recommended load success type is \"%@\".", [self loadSuccessTypeName:SgfLoadSuccessTypeDefault]];

    ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                  screenTitle:screenTitle
                                                                           indexOfDefaultItem:indexOfDefaultItem
                                                                                     delegate:self];
    itemPickerController.itemPickerControllerMode = ItemPickerControllerModeNonModal;
    itemPickerController.context = indexPath;
    itemPickerController.footerTitle = footerTitle;
    [self.navigationController pushViewController:itemPickerController animated:YES];
  }
  else if (DisabledMessagesSection == indexPath.section)
  {
    SgfDisabledMessagesController* controller = [SgfDisabledMessagesController controllerWithDelegate:self];
    [self.navigationController pushViewController:controller animated:YES];
  }
  else if (ResetToDefaultsSection == indexPath.section)
  {
    UIAlertControllerStyle alertControllerStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
      alertControllerStyle = UIAlertControllerStyleActionSheet;
    else
      alertControllerStyle = UIAlertControllerStyleAlert;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please confirm"
                                                                   message:@"This will reset the syntax checking level settings to a set of default values. Any changes you have made will be discarded."
                                                            preferredStyle:alertControllerStyle];

    void (^resetActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
    {
      [self.sgfSettingsModel resetSyntaxCheckingLevelPropertiesToDefaultValues];
      [self.delegate didChangeSyntaxCheckingLevel:self];
      [self.tableView reloadData];
    };
    UIAlertAction* resetAction = [UIAlertAction actionWithTitle:@"Reset to default values"
                                                          style:UIAlertActionStyleDestructive
                                                        handler:resetActionBlock];
    [alert addAction:resetAction];

    void (^cancelActionBlock) (UIAlertAction*) = ^(UIAlertAction* action) {};
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:cancelActionBlock];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
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
      self.sgfSettingsModel.loadSuccessType = controller.indexOfSelectedItem;

      [self.delegate didChangeSyntaxCheckingLevel:self];

      NSUInteger sectionIndex = LoadSuccessTypeSection;
      NSUInteger rowIndex = LoadSuccessTypeItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SgfDisabledMessagesDelegate overrides

// -----------------------------------------------------------------------------
/// @brief SgfDisabledMessagesDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeDisabledMessages:(SgfDisabledMessagesController*)sgfDisabledMessagesController
{
  NSUInteger sectionIndex = DisabledMessagesSection;
  NSUInteger rowIndex = DisabledMessagesItem;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];

  [self.delegate didChangeSyntaxCheckingLevel:self];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Enable restrictive checking" switch.
/// Updates the settings model object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleEnableRestrictiveChecking:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.sgfSettingsModel.enableRestrictiveChecking = accessoryView.on;

  [self.delegate didChangeSyntaxCheckingLevel:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Disable all warning messages" switch.
/// Updates the settings model object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleDisableAllWarningMessages:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.sgfSettingsModel.disableAllWarningMessages = accessoryView.on;

  [self.delegate didChangeSyntaxCheckingLevel:self];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a enableMode that is suitable for
/// displaying in the UI.
// -----------------------------------------------------------------------------
- (NSString*) loadSuccessTypeName:(enum SgfLoadSuccessType)loadSuccessType
{
  switch (loadSuccessType)
  {
    case SgfLoadSuccessTypeNoWarningsOrErrors:
      return @"No warnings/errors";
    case SgfLoadSuccessTypeNoCriticalWarningsOrErrors:
      return @"No critical warnings/errors";
    case SgfLoadSuccessTypeWithCriticalWarningsOrErrors:
      return @"With critical warnings/errors";
    default:
      [ExceptionUtility throwNotImplementedException];
      return nil;
  }
}

@end
