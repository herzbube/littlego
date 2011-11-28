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
#import "../ui/UiUtilities.h"
#import "../utility/UiColorAdditions.h"


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
- (void) create:(id)sender;
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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
//@}
/// @name UINavigationControllerDelegate protocol
//@{
- (void) navigationController:(UINavigationController*)navigationController willShowViewController:(UIViewController*)viewController animated:(BOOL)animated;
//@}
/// @name Private helpers
//@{
- (bool) isProfileValid;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) UITextView* textView;
@property(nonatomic, retain) UIViewController* textViewController;
@property(nonatomic, assign) bool textViewControllerIsPushed;
//@}
@end


@implementation EditGtpEngineProfileController

@synthesize delegate;
@synthesize profile;
@synthesize profileExists;
@synthesize textView;
@synthesize textViewController;
@synthesize textViewControllerIsPushed;


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
    controller.profileExists = true;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGtpEngineProfileController
/// instance of grouped style that is used to create a new GtpEngineProfile
/// object and edit its attributes.
// -----------------------------------------------------------------------------
+ (EditGtpEngineProfileController*) controllerWithDelegate:(id<EditGtpEngineProfileDelegate>)delegate
{
  EditGtpEngineProfileController* controller = [[EditGtpEngineProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = [[[GtpEngineProfile alloc] init] autorelease];
    controller.profileExists = false;
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
  self.textView = nil;
  self.textViewController = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  // Try to make the text view look similar to a table view cell
  self.textView = [[[UITextView alloc] init] autorelease];
  self.textView.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];  // remove bold'ness
  self.textView.textColor = [UIColor slateBlueColor];
  self.textView.contentInset = UIEdgeInsetsMake(cellContentDistanceFromEdgeVertical,
                                                cellContentDistanceFromEdgeHorizontal,
                                                cellContentDistanceFromEdgeVertical,
                                                cellContentDistanceFromEdgeHorizontal);
  self.textViewController = [[[UIViewController alloc] init] autorelease];
  self.textViewController.view = textView;
  self.textViewController.navigationItem.title = @"Edit description";
  if (! self.navigationController.delegate)
    self.navigationController.delegate = self;
  else
  {
    // This may be a little bit harsh, but we really want to know if there
    // was an implementation change and this class was not properly updated.
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Navigation controller already has a delegate"
                                                   userInfo:nil];
    @throw exception;
  }
  self.textViewControllerIsPushed = false;

  if (self.profileExists)
  {
    self.navigationItem.title = @"Edit Profile";
    self.navigationItem.leftBarButtonItem.enabled = [self isProfileValid];
  }
  else
  {
    self.navigationItem.title = @"New Profile";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(create:)];
    self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
  }
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
      return @"Profile name & description";
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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (ProfileSettingsSection == section)
    return @"Changed settings are applied only after a new game with a player who uses this profile is started.";
  else
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
          enum TableViewCellType cellType = DefaultCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          if (self.profile.profileDescription.length > 0)
          {
            cell.textLabel.text = self.profile.profileDescription;
            cell.textLabel.textColor = [UIColor slateBlueColor];
          }
          else
          {
            // Fake placeholder of UITextField
            cell.textLabel.text = @"Profile description";
            cell.textLabel.textColor = [UIColor lightGrayColor];
          }
          cell.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];  // remove bold'ness
          cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
          cell.textLabel.numberOfLines = 0;
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    case ProfileDescriptionSection:
    {
      NSString* cellText;  // use the same strings as in tableView:cellForRowAtIndexPath:()
      if (ProfileNameSection == indexPath.section)
        cellText = self.profile.name;
      else
        cellText = self.profile.profileDescription;
      height = [UiUtilities tableView:tableView
                  heightForCellOfType:DefaultCellType
                             withText:cellText
               hasDisclosureIndicator:true];
      break;
    }
    case ProfileSettingsSection:
    {
      switch (indexPath.row)
      {
        case FuegoMaxMemoryItem:
        case FuegoThreadCountItem:
        {
          height = [TableViewSliderCell rowHeightInTableView:tableView];
          break;
        }
        default:
        {
          break;
        }
      }
      break;
    }
    default:
    {
      break;
    }
  }
  return height;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
  if (ProfileDescriptionSection == indexPath.section)
  {
    self.textView.text = self.profile.profileDescription;
    [self.textView becomeFirstResponder];
    [self.navigationController pushViewController:self.textViewController animated:YES];
  }
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
  self.profile.name = newText;
  if (self.profileExists)
  {
    // Make sure that the editing view cannot be left, unless the profile
    // is valid
    [self.navigationItem setHidesBackButton:! [self isProfileValid] animated:YES];
    // Notify delegate that something about the profile object has changed
    [self.delegate didChangeProfile:self];
  }
  else
  {
    // Make sure that the new profile cannot be added, unless it is valid
    self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
  }
  // Accept all changes, even those that make the profile name invalid
  // -> the user must simply continue editing until the profile name becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UINavigationControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController willShowViewController:(UIViewController*)viewController animated:(BOOL)animated
{
  if (viewController == self.textViewController)
    self.textViewControllerIsPushed = true;
  else if (viewController == self)
  {
    if (self.textViewControllerIsPushed)
    {
      self.textViewControllerIsPushed = false;
      self.profile.profileDescription = self.textView.text;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ProfileDescriptionItem inSection:ProfileDescriptionSection];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  else
  {
    // self is being popped, so we don't want to be the delegate any longer
    self.navigationController.delegate = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to create a new profile object using the
/// data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  [model add:self.profile];

  [self.delegate didCreateProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Ponder" switch. Updates the profile
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) togglePondering:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoPondering = accessoryView.on;

  if (self.profileExists)
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

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum amount of memory.
// -----------------------------------------------------------------------------
- (void) maxMemoryDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxMemory = sliderCell.value;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's number of threads.
// -----------------------------------------------------------------------------
- (void) threadCountDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoThreadCount = sliderCell.value;

  if (self.profileExists)
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

@end
