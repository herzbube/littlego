// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "EditGtpEngineProfileController.h"
#import "../ApplicationDelegate.h"
#import "../player/GtpEngineProfile.h"
#import "../player/GtpEngineProfileModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Profile" table view.
// -----------------------------------------------------------------------------
enum EditGtpEngineProfileTableViewSection
{
  ProfileNameSection,
  ProfileDescriptionSection,
  ProfileSettingsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ProfileNameSection.
// -----------------------------------------------------------------------------
enum ProfileNameSectionItem
{
  ProfileNameItem,
  MaxProfileNameSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ProfileDescriptionSection.
// -----------------------------------------------------------------------------
enum ProfileDescriptionSectionItem
{
  ProfileDescriptionItem,
  MaxProfileDescriptionSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ProfileSettingsSection.
// -----------------------------------------------------------------------------
enum ProfileSettingsSectionItem
{
  FuegoMaxMemoryItem,
  FuegoThreadCountItem,
  FuegoPonderingItem,
  FuegoReuseSubtreeItem,
  MaxProfileSettingsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// EditGtpEngineProfileController.
// -----------------------------------------------------------------------------
@interface EditGtpEngineProfileController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name Action methods
//@{
- (void) delete:(id)sender;
- (void) togglePondering:(id)sender;
- (void) toggleReuseSubtree:(id)sender;
- (void) maxMemoryDidChange:(id)sender;
- (void) threadCountDidChange:(id)sender;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
//@}
/// @name Private helpers
//@{
- (bool) isProfileValid;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) UITextField* textFieldProfileName;
@property(nonatomic, assign) UITextField* textFieldProfileDescription;
//@}
@end


@implementation EditGtpEngineProfileController

@synthesize delegate;
@synthesize profile;
@synthesize textFieldProfileName;
@synthesize textFieldProfileDescription;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a EditGtpEngineProfileController
/// instance of grouped style that is used to edit @a profile.
// -----------------------------------------------------------------------------
+ (EditGtpEngineProfileController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditGtpEngineProfileDelegate>)delegate
{
  EditGtpEngineProfileController* controller = [[EditGtpEngineProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = profile;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGtpEngineProfileController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.profile = nil;
  self.textFieldProfileName = nil;
  self.textFieldProfileDescription = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  assert(self.delegate != nil);

  self.navigationItem.title = @"Edit Profile";
  // Profile can be deleted only if it is not the default profile.
  if (! [self.profile isDefaultProfile])
  {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(delete:)];
  }
  self.navigationItem.leftBarButtonItem.enabled = [self isProfileValid];
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
    case ProfileNameSection:
      return MaxProfileNameSectionItem;
    case ProfileDescriptionSection:
      return MaxProfileDescriptionSectionItem;
    case ProfileSettingsSection:
      return MaxProfileSettingsSectionItem;
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
    case ProfileNameSection:
    case ProfileDescriptionSection:
      return nil;
    case ProfileSettingsSection:
      return @"GTP engine settings";
    default:
      assert(0);
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell;
  switch (indexPath.section)
  {
    case ProfileNameSection:
    {
      switch (indexPath.row)
      {
        case ProfileNameItem:
        {
          enum TableViewCellType cellType = TextFieldCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          UITextField* textField = (UITextField*)[cell viewWithTag:TextFieldCellTextFieldTag];
          textField.delegate = self;
          textField.text = self.profile.name;
          textField.placeholder = @"Profile name";
          self.textFieldProfileName = textField;
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
    case ProfileDescriptionSection:
    {
      switch (indexPath.row)
      {
        case ProfileDescriptionItem:
        {
          enum TableViewCellType cellType = TextFieldCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          UITextField* textField = (UITextField*)[cell viewWithTag:TextFieldCellTextFieldTag];
          textField.delegate = self;
          textField.text = self.profile.description;
          textField.placeholder = @"Profile description";
          self.textFieldProfileDescription = textField;
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
    case ProfileSettingsSection:
    {
      enum TableViewCellType cellType;
      switch (indexPath.row)
      {
        case FuegoMaxMemoryItem:
        case FuegoThreadCountItem:
          cellType = SliderCellType;
          break;
        default:
          cellType = SwitchCellType;
          break;
      }
      cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
      UISwitch* accessoryView = nil;
      if (SwitchCellType == cellType)
        accessoryView = (UISwitch*)cell.accessoryView;
      switch (indexPath.row)
      {
        case FuegoMaxMemoryItem:
        {
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(maxMemoryDidChange:)];
          sliderCell.descriptionLabel.text = @"Max. memory (MB)";
          sliderCell.slider.minimumValue = fuegoMaxMemoryMinimum;
          sliderCell.slider.maximumValue = fuegoMaxMemoryMaximum;
          sliderCell.value = self.profile.fuegoMaxMemory;
          break;
        }
        case FuegoThreadCountItem:
        {
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(threadCountDidChange:)];
          sliderCell.descriptionLabel.text = @"Number of threads";
          sliderCell.slider.minimumValue = fuegoThreadCountMinimum;
          sliderCell.slider.maximumValue = fuegoThreadCountMaximum;
          sliderCell.value = self.profile.fuegoThreadCount;
          break;
        }
        case FuegoPonderingItem:
          cell.textLabel.text = @"Pondering";
          accessoryView.on = self.profile.fuegoPondering;
          [accessoryView addTarget:self action:@selector(togglePondering:) forControlEvents:UIControlEventValueChanged];
          break;
        case FuegoReuseSubtreeItem:
          cell.textLabel.text = @"Reuse subtree";
          accessoryView.on = self.profile.fuegoReuseSubtree;
          [accessoryView addTarget:self action:@selector(toggleReuseSubtree:) forControlEvents:UIControlEventValueChanged];
          break;
        default:
          assert(0);
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

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat height = tableView.rowHeight;
  switch (indexPath.section)
  {
    case ProfileSettingsSection:
    {
      switch (indexPath.row)
      {
        case FuegoMaxMemoryItem:
        case FuegoThreadCountItem:
          height = [TableViewSliderCell rowHeightInTableView:tableView];
          break;
        default:
          break;
      }
      break;
    }
    default:
      break;
  }
  return height;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
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
  if (textField == self.textFieldProfileName)
    self.profile.name = newText;
  else if (textField == self.textFieldProfileDescription)
    self.profile.description = newText;
  else
  {
    assert(0);
    return YES;
  }
  // Make sure that the editing view cannot be left, unless the profile name is
  // valid
  [self.navigationItem setHidesBackButton:! [self isProfileValid] animated:YES];
  // Notify delegate that something about the profile object has changed
  [self.delegate didChangeProfile:self];
  // Accept all changes, even those that make the profile name invalid
  // -> the user must simply continue editing until the profile name becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to delete the profile object.
// -----------------------------------------------------------------------------
- (void) delete:(id)sender
{
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  [model remove:self.profile];

  [self.delegate didDeleteProfile:self];
  [self.navigationController popViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Ponder" switch. Updates the profile
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) togglePondering:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoPondering = accessoryView.on;

  [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Reuse subtree" switch. Updates the
/// profile object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleReuseSubtree:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoReuseSubtree = accessoryView.on;

  [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the current profile object contains valid data so
/// that editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isProfileValid
{
  // TODO check for duplicate name
  return (self.profile.name.length > 0);
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum amount of memory.
// -----------------------------------------------------------------------------
- (void) maxMemoryDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxMemory = sliderCell.value;

  [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's number of threads.
// -----------------------------------------------------------------------------
- (void) threadCountDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoThreadCount = sliderCell.value;

  [self.delegate didChangeProfile:self];
}

@end
