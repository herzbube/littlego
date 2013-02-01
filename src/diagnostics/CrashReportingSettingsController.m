// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../ui/TableViewTextCell.h"
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
/// @brief Class extension with private methods for
/// CrashReportingSettingsController.
// -----------------------------------------------------------------------------
@interface CrashReportingSettingsController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
- (BOOL) textFieldShouldClear:(UITextField*)textField;
- (BOOL) textFieldShouldReturn:(UITextField*)textField;
//@}
/// @name Action methods
//@{
- (void) toggleCollectData:(id)sender;
- (void) toggleAutomaticReport:(id)sender;
- (void) toggleAllowContact:(id)sender;
//@}
/// @name Private helpers
//@{
- (void) updateBackButtonVisibleState;
- (bool) isValidContactEmailAddress:(NSString*)emailAddress;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) CrashReportingModel* crashReportingModel;
//@}
@end


@implementation CrashReportingSettingsController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a CrashReportingSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (CrashReportingSettingsController*) controller
{
  CrashReportingSettingsController* controller = [[CrashReportingSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
    [controller autorelease];
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

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.crashReportingModel = delegate.crashReportingModel;

  [self updateBackButtonVisibleState];

  self.title = @"Crash report settings";
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

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
          cell = [TableViewCellFactory cellWithType:TextFieldCellType tableView:tableView];
          TableViewTextCell* textCell = (TableViewTextCell*)cell;
          textCell.textField.delegate = self;
          textCell.textField.text = self.crashReportingModel.contactEmail;
          textCell.textField.placeholder = @"Your email address";
          textCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
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

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

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

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
  // Compose the string as it would look like if the proposed change had already
  // been made
  NSString* newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
  self.crashReportingModel.contactEmail = newText;

  [self updateBackButtonVisibleState];

  // Accept all changes, even those that make the email address invalid
  // -> the user must simply continue editing until the email address becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldClear:(UITextField*)textField
{
  self.crashReportingModel.contactEmail = @"";
  [self updateBackButtonVisibleState];
  // Accept all changes, even those that make the email address invalid
  // -> the user must simply continue editing until the email address becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
  [textField resignFirstResponder];  // dismiss keyboard
  return YES;
}

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
