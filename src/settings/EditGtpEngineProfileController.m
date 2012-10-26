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
#import "EditGtpEngineProfileController.h"
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfile.h"
#import "../player/GtpEngineProfileModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"
#import "../utility/UiColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Profile" table view.
// -----------------------------------------------------------------------------
enum EditGtpEngineProfileTableViewSection
{
  ProfileNameSection,
  PlayingStrengthSection,
  ProfileNotesSection,
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
/// @brief Enumerates items in the PlayingStrengthSection.
// -----------------------------------------------------------------------------
enum PlayingStrengthSectionItem
{
  PlayingStrengthItem,
  AdvancedConfigurationItem,
  MaxPlayingStrengthSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ProfileNotesSection.
// -----------------------------------------------------------------------------
enum ProfileNotesSectionItem
{
  ProfileNotesItem,
  MaxProfileNotesSectionItem,
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
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name Action methods
//@{
- (void) create:(id)sender;
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
/// @name EditTextDelegate protocol
//@{
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text;
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
//@}
/// @name ItemPickerDelegate protocol
//@{
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection;
//@}
/// @name EditGtpEngineProfileSettingsDelegate protocol
//@{
- (void) didChangeProfile:(EditGtpEngineProfileSettingsController*)editGtpEngineProfileSettingsController;
//@}
/// @name Private helpers
//@{
- (bool) isProfileValid;
//@}
@end


@implementation EditGtpEngineProfileController

@synthesize delegate;
@synthesize profile;
@synthesize profileExists;


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
    controller.profile.playingStrength = defaultPlayingStrength;
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
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

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
  // Because we always display all sections we can reload sections when we
  // toggle between simple/advanced settings. Because sections go from zero
  // to one or more rows (or vice vera), we get a nice animation of rows
  // fading in/out.
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
    case PlayingStrengthSection:
      return MaxPlayingStrengthSectionItem;
    case ProfileNotesSection:
      return MaxProfileNotesSectionItem;
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
      return @"Profile name";
    case PlayingStrengthSection:
      return @"Playing strength";
    case ProfileNotesSection:
      return @"Profile notes";
    default:
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case PlayingStrengthSection:
      return @"Changes become active only after a new game with a player who uses this profile is started.";
      break;
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
    case PlayingStrengthSection:
    {
      switch (indexPath.row)
      {
        case PlayingStrengthItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Playing strength";
          if (customPlayingStrength == self.profile.playingStrength)
            cell.detailTextLabel.text = @"Custom";
          else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.profile.playingStrength];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case AdvancedConfigurationItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
          cell.textLabel.text = @"Advanced configuration";
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
    case ProfileNotesSection:
    {
      switch (indexPath.row)
      {
        case ProfileNotesItem:
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
            cell.textLabel.text = @"Profile notes";
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
    case ProfileNotesSection:
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

  if (PlayingStrengthSection == indexPath.section)
  {
    switch (indexPath.row)
    {
      case PlayingStrengthItem:
      {
        NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
        for (int playingStrength = minimumPlayingStrength; playingStrength < maximumPlayingStrength + 1; ++playingStrength)
        {
          NSString* playingStrengthString = [NSString stringWithFormat:@"%d", playingStrength];
          [itemList addObject:playingStrengthString];
        }
        int indexOfDefaultPlayingStrength;
        if (customPlayingStrength == self.profile.playingStrength)
          indexOfDefaultPlayingStrength = -1;
        else
          indexOfDefaultPlayingStrength = self.profile.playingStrength - minimumPlayingStrength;
        UIViewController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                   title:@"Playing strength"
                                                                      indexOfDefaultItem:indexOfDefaultPlayingStrength
                                                                                delegate:self];
        UINavigationController* navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:modalController];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navigationController animated:YES];
        [navigationController release];
        break;
      }
      case AdvancedConfigurationItem:
      {
        EditGtpEngineProfileSettingsController* editProfileSettingsController = [[EditGtpEngineProfileSettingsController controllerForProfile:profile withDelegate:self] retain];
        [self.navigationController pushViewController:editProfileSettingsController animated:YES];
        [editProfileSettingsController release];
        break;
      }
      default:
      {
        assert(0);
        break;
      }
    }
  }
  else if (ProfileNotesSection == indexPath.section)
  {
    EditTextController* editTextController = [[EditTextController controllerWithText:self.profile.profileDescription
                                                                               style:EditTextControllerStyleTextView
                                                                            delegate:self] retain];
    editTextController.title = @"Edit notes";
    editTextController.acceptEmptyText = true;
    UINavigationController* navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:editTextController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [editTextController release];
  }
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
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  if (! didCancel)
  {
    if (editTextController.textHasChanged)
    {
      self.profile.profileDescription = editTextController.text;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ProfileNotesItem inSection:ProfileNotesSection];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
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
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (controller.indexOfDefaultItem != controller.indexOfSelectedItem)
    {
      self.profile.playingStrength = (minimumPlayingStrength + controller.indexOfSelectedItem);

      NSUInteger sectionIndex = PlayingStrengthSection;
      NSUInteger rowIndex = PlayingStrengthItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief EditGtpEngineProfileSettingsDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeProfile:(EditGtpEngineProfileSettingsController*)editGtpEngineProfileSettingsController
{
  NSUInteger sectionIndex = PlayingStrengthSection;
  NSUInteger rowIndex = PlayingStrengthItem;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
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
/// @brief Returns true if the current profile object contains valid data so
/// that editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isProfileValid
{
  return (self.profile.name.length > 0);
}

@end
