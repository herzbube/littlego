// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "CrashReportingSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../diagnostics/CrashReportingModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Crash Report" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum CrashReportTableViewSection
{
  CollectDataSection,
  AutomaticReportSection,
  ContactSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the CollectDataSection.
// -----------------------------------------------------------------------------
enum CollectDataSectionItem
{
  CollectDataItem,
  MaxCollectDataSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the AutomaticReportSection.
// -----------------------------------------------------------------------------
enum AutomaticReportSectionItem
{
  AutomaticReportItem,
  MaxAutomaticReportSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ContactSection.
// -----------------------------------------------------------------------------
enum ContactSectionItem
{
  AllowContactItem,
  EmailAddressItem,
  MaxContactSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// CrashReportingSettingsController.
// -----------------------------------------------------------------------------
@interface CrashReportingSettingsController()
@property(nonatomic, assign) CrashReportingModel* crashReportingModel;
@end


@implementation CrashReportingSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a CrashReportingSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (CrashReportingSettingsController*) controller
{
  CrashReportingSettingsController* controller = [[CrashReportingSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.crashReportingModel = [ApplicationDelegate sharedDelegate].crashReportingModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrashReportingSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crashReportingModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  [self updateBackButtonVisibleState];
  self.title = @"Crash report settings";
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
    case CollectDataSection:
      return MaxCollectDataSectionItem;
    case AutomaticReportSection:
      return MaxAutomaticReportSectionItem;
    case ContactSection:
      if (self.crashReportingModel.allowContact)
        return MaxContactSectionItem;
      else
        return MaxContactSectionItem - 1;
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
    case CollectDataSection:
      return @"If the app crashes and this is enabled, data which can help the developer to correct the problem will be collected automatically.";
    case AutomaticReportSection:
      return @"If enabled, crash data will be sent to the developer automatically without asking for your confirmation.";
    case ContactSection:
      return @"If enabled, the email address entered here will be sent along with the crash data. The developer will use the address to contact you if clarifications are needed about the problem.";
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
    case CollectDataSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      cell.textLabel.text = @"Collect crash data";
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.on = self.crashReportingModel.collectCrashData;
      [accessoryView addTarget:self action:@selector(toggleCollectData:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case AutomaticReportSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      cell.textLabel.text = @"Automatic report";
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.on = self.crashReportingModel.automaticReport;
      [accessoryView addTarget:self action:@selector(toggleAutomaticReport:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case ContactSection:
    {
      switch (indexPath.row)
      {
        case AllowContactItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          cell.textLabel.text = @"Allow contact";
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          accessoryView.on = self.crashReportingModel.allowContact;
          [accessoryView addTarget:self action:@selector(toggleAllowContact:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        case EmailAddressItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView reusableCellIdentifier:@"TextFieldCellType"];
          [UiUtilities setupDefaultTypeCell:cell withText:self.crashReportingModel.contactEmail placeHolder:@"Your email address" textIsRequired:true];
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    default:
    {
      assert(0);
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
  if (ContactSection == indexPath.section && EmailAddressItem == indexPath.row)
  {
    EditTextController* editTextController = [[EditTextController controllerWithText:self.crashReportingModel.contactEmail
                                                                               style:EditTextControllerStyleTextField
                                                                            delegate:self] retain];
    editTextController.title = @"Edit email";
    editTextController.acceptEmptyText = false;
    editTextController.keyboardType = UIKeyboardTypeEmailAddress;
    UINavigationController* navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:editTextController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
    [editTextController release];
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Collect crash data" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleCollectData:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.crashReportingModel.collectCrashData = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Automatic report" switch. Writes the
/// new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAutomaticReport:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.crashReportingModel.automaticReport = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Allow contact" switch. Writes the
/// new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAllowContact:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.crashReportingModel.allowContact = accessoryView.on;
  [self updateBackButtonVisibleState];

  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:ContactSection];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - EditTextDelegate overrides

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
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  if (! didCancel)
  {
    if (editTextController.textHasChanged)
    {
      self.crashReportingModel.contactEmail = editTextController.text;
      [self updateBackButtonVisibleState];
      NSIndexPath* indexPathToReload = [NSIndexPath indexPathForRow:EmailAddressItem inSection:ContactSection];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPathToReload];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Updates the visible state of the back button.
///
/// The button is hidden if the user has entered an invalid contact email
/// address.
// -----------------------------------------------------------------------------
- (void) updateBackButtonVisibleState
{
  BOOL hidesBackButton = NO;
  if (self.crashReportingModel.allowContact)
  {
    if (! [self isValidContactEmailAddress:self.crashReportingModel.contactEmail])
      hidesBackButton = YES;
  }
  [self.navigationItem setHidesBackButton:hidesBackButton animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a emailAddress is a valid email address.
// -----------------------------------------------------------------------------
- (bool) isValidContactEmailAddress:(NSString*)emailAddress
{
  return (emailAddress.length > 0);
}

@end
