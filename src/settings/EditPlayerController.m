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
#import "EditPlayerController.h"
#import "../main/ApplicationDelegate.h"
#import "../player/PlayerModel.h"
#import "../player/Player.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../ui/TableViewTextCell.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Player" table view.
// -----------------------------------------------------------------------------
enum EditPlayerTableViewSection
{
  PlayerNameSection,
  IsHumanSection,
  GtpEngineProfileSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayerNameSection.
// -----------------------------------------------------------------------------
enum PlayerNameSectionItem
{
  PlayerNameItem,
  MaxPlayerNameSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the IsHumanSection.
// -----------------------------------------------------------------------------
enum IsHumanSectionItem
{
  IsHumanItem,
  MaxIsHumanSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GtpEngineProfileSection.
// -----------------------------------------------------------------------------
enum GtpEngineProfileSectionItem
{
  GtpEngineProfileItem,
  MaxGtpEngineProfileSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for EditPlayerController.
// -----------------------------------------------------------------------------
@interface EditPlayerController()
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
- (void) toggleIsHuman:(id)sender;
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
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
//@}
/// @name ItemPickerDelegate protocol
//@{
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection;
//@}
/// @name Private helpers
//@{
- (bool) isPlayerValid;
//@}
@end


@implementation EditPlayerController

@synthesize delegate;
@synthesize player;
@synthesize playerExists;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditPlayerController instance of
/// grouped style that is used to edit the attributes of @a player.
// -----------------------------------------------------------------------------
+ (EditPlayerController*) controllerForPlayer:(Player*)player withDelegate:(id<EditPlayerDelegate>)delegate
{
  EditPlayerController* controller = [[EditPlayerController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.player = player;
    controller.playerExists = true;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditPlayerController instance of
/// grouped style that is used to create a new Player object and edit its
/// attributes.
// -----------------------------------------------------------------------------
+ (EditPlayerController*) controllerWithDelegate:(id<EditPlayerDelegate>)delegate
{
  EditPlayerController* controller = [[EditPlayerController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.player = [[[Player alloc] init] autorelease];
    controller.playerExists = false;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditPlayerController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.player = nil;
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

  if (self.playerExists)
  {
    self.navigationItem.title = @"Edit Player";
    self.navigationItem.leftBarButtonItem.enabled = [self isPlayerValid];
  }
  else
  {
    self.navigationItem.title = @"New Player";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(create:)];
    self.navigationItem.rightBarButtonItem.enabled = [self isPlayerValid];
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
  // Because we always display all sections we can reload sections, especially
  // GtpEngineProfileSection when we toggle between human/not human. Because
  // GtpEngineProfileSection will sometimes have zero rows, we get a nice
  // animation of rows fading in/out.
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case PlayerNameSection:
      return MaxPlayerNameSectionItem;
    case IsHumanSection:
      return MaxIsHumanSectionItem;
    case GtpEngineProfileSection:
      if (self.player.isHuman)
        return 0;  // GTP engine profile is only for computer players
      else
        return MaxGtpEngineProfileSectionItem;
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
    case PlayerNameSection:
    case IsHumanSection:
      return nil;
    case GtpEngineProfileSection:
      if (self.player.isHuman)
        return nil;
      else
        return @"Profile";
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
  if (IsHumanSection == section)
  {
    if (self.player.isPlaying)
      return @"This setting cannot be changed because the player currently participates in a game.";
  }
  else if (GtpEngineProfileSection == section)
  {
    // Display this notice only if we are not in "create" mode
    if (self.playerExists && ! self.player.human)
      return @"If the profile is changed the new settings are applied only after a new game with this player is started.";
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
    case PlayerNameSection:
    {
      switch (indexPath.row)
      {
        case PlayerNameItem:
        {
          enum TableViewCellType cellType = TextFieldCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          TableViewTextCell* textCell = (TableViewTextCell*)cell;
          UITextField* textField = textCell.textField;
          textField.delegate = self;
          textField.text = self.player.name;
          textField.placeholder = @"Player name";
          // Place the insertion point into this field; might be better to
          // do this in viewWillAppear:
          [textField becomeFirstResponder];
          break;
        }
        default:
          assert(0);
          break;
      }
      break;
    }
    case IsHumanSection:
    {
      switch (indexPath.row)
      {
        case IsHumanItem:
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          cell.textLabel.text = @"Human player";
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          [accessoryView addTarget:self action:@selector(toggleIsHuman:) forControlEvents:UIControlEventValueChanged];
          accessoryView.on = self.player.human;
          // Player type can be changed only if he is not currently playing a game
          accessoryView.enabled = (! self.player.isPlaying);
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    case GtpEngineProfileSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.textLabel.text = [self.player gtpEngineProfile].name;
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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

  switch (indexPath.section)
  {
    case GtpEngineProfileSection:
    {
      GtpEngineProfile* defaultProfile = [self.player gtpEngineProfile];
      GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      int indexOfDefaultProfile = -1;
      for (int profileIndex = 0; profileIndex < model.profileCount; ++profileIndex)
      {
        GtpEngineProfile* profile = [model.profileList objectAtIndex:profileIndex];
        [itemList addObject:profile.name];
        if (profile == defaultProfile)
          indexOfDefaultProfile = profileIndex;
      }
      UIViewController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                 title:@"Select profile"
                                                                    indexOfDefaultItem:indexOfDefaultProfile
                                                                              delegate:self];
      UINavigationController* navigationController = [[UINavigationController alloc]
                                                      initWithRootViewController:modalController];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      [self presentModalViewController:navigationController animated:YES];
      [navigationController release];
      break;
    }
    default:
    {
      break;
    }
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
  self.player.name = [textField.text stringByReplacingCharactersInRange:range withString:string];
  if (self.playerExists)
  {
    // Make sure that the editing view cannot be left, unless the player is
    // valid
    [self.navigationItem setHidesBackButton:! [self isPlayerValid] animated:YES];
    // Notify delegate that something about the player object has changed
    [self.delegate didChangePlayer:self];
  }
  else
  {
    // Make sure that the new player cannot be added, unless it is valid
    self.navigationItem.rightBarButtonItem.enabled = [self isPlayerValid];
  }
  // Accept all changes, even those that make the player name invalid
  // -> the user must simply continue editing until the player name becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to create a new player object using the
/// data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
  [model add:self.player];
  
  [self.delegate didCreatePlayer:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Is Human" switch. Updates the Player
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleIsHuman:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.player.human = accessoryView.on;

  if (self.playerExists)
    [self.delegate didChangePlayer:self];

  // Reloading the section works because it is always there - it just sometimes
  // has zero rows.
  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:GtpEngineProfileSection];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the current Player object contains valid data so that
/// editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isPlayerValid
{
  return (self.player.name.length > 0);
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
      GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
      GtpEngineProfile* newProfile = [[model profileList] objectAtIndex:controller.indexOfSelectedItem];
      self.player.gtpEngineProfileUUID = newProfile.uuid;

      NSUInteger sectionIndex = GtpEngineProfileSection;
      NSUInteger rowIndex = GtpEngineProfileItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

@end
