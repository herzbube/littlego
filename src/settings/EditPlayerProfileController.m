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
#import "EditPlayerProfileController.h"
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfile.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/Player.h"
#import "../player/PlayerModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"
#import "../ui/UIViewControllerAdditions.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Player + Profile"
/// table view.
// -----------------------------------------------------------------------------
enum EditPlayerProfileTableViewSection
{
  PlayerSection,
  PlayingStrengthSection,
  ResignBehaviourSection,
  ProfileNotesSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayerSection.
// -----------------------------------------------------------------------------
enum PlayerSectionItem
{
  PlayerNameItem,
  IsHumanItem,
  MaxPlayerSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayingStrengthSection.
// -----------------------------------------------------------------------------
enum PlayingStrengthSectionItem
{
  PlayingStrengthItem,
  PlayingStrengthAdvancedConfigurationItem,
  MaxPlayingStrengthSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ResignBehaviourSection.
// -----------------------------------------------------------------------------
enum ResignBehaviourSectionItem
{
  ResignBehaviourItem,
  ResignBehaviourAdvancedConfigurationItem,
  MaxResignBehaviourSectionItem
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
/// @brief Class extension with private properties for
/// EditPlayerProfileController.
// -----------------------------------------------------------------------------
@interface EditPlayerProfileController()
@end


@implementation EditPlayerProfileController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a EditPlayerProfileController
/// instance of grouped style that is used to edit @a player.
// -----------------------------------------------------------------------------
+ (EditPlayerProfileController*) controllerForPlayer:(Player*)player withDelegate:(id<EditPlayerProfileDelegate>)delegate;
{
  EditPlayerProfileController* controller = [[EditPlayerProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.player = player;
    controller.profile = player.gtpEngineProfile;
    controller.playerProfileExists = true;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a EditPlayerProfileController
/// instance of grouped style that is used to edit @a profile.
// -----------------------------------------------------------------------------
+ (EditPlayerProfileController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditPlayerProfileDelegate>)delegate;
{
  EditPlayerProfileController* controller = [[EditPlayerProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.player = nil;
    controller.profile = profile;
    controller.playerProfileExists = true;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditPlayerProfileController
/// instance of grouped style that is used to create a new Player object and
/// a new GtpEngineProfile object and edit their attributes.
// -----------------------------------------------------------------------------
+ (EditPlayerProfileController*) controllerForHumanPlayer:(bool)human withDelegate:(id<EditPlayerProfileDelegate>)delegate
{
  EditPlayerProfileController* controller = [[EditPlayerProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.player = [[[Player alloc] init] autorelease];
    controller.player.human = human;
    if (human)
    {
      controller.profile = nil;
    }
    else
    {
      controller.profile = [[[GtpEngineProfile alloc] init] autorelease];
      controller.profile.playingStrength = defaultPlayingStrength;
      controller.player.gtpEngineProfileUUID = controller.profile.uuid;
    }
    controller.playerProfileExists = false;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditPlayerProfileController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.player = nil;
  self.profile = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  if (self.playerProfileExists)
  {
    if (self.player != nil)
      self.navigationItem.title = @"Edit Player";
    else
      self.navigationItem.title = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel.fallbackProfile.name;
    if (self == [self.navigationController.viewControllers objectAtIndex:0])
    {
      // We are the root view controller of the navigation stack, so we are
      // presented modally and need to display a button that allows dismissing
      self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                                 style:UIBarButtonItemStyleDone
                                                                                target:self
                                                                                action:@selector(done:)] autorelease];
      self.navigationItem.rightBarButtonItem.enabled = [self isPlayerProfileValid];
    }
    else
    {
      self.navigationItem.leftBarButtonItem.enabled = [self isPlayerProfileValid];
    }
  }
  else
  {
    self.navigationItem.title = @"New Player";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(create:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = [self isPlayerProfileValid];
  }
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  if (self.profile.isActiveProfile && self.profile.hasUnappliedChanges)
    [self.profile applyProfile];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (self.player)
  {
    if (self.player.isHuman)
      return 1;  // Profile sections are only for computer players
    else
      return MaxSection;
  }
  else
  {
    return (MaxSection - 1);
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  if (! self.player)
    section++;

  switch (section)
  {
    case PlayerSection:
      return MaxPlayerSectionItem;
    case PlayingStrengthSection:
      return MaxPlayingStrengthSectionItem;
    case ResignBehaviourSection:
      return MaxResignBehaviourSectionItem;
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
  if (! self.player)
    section++;

  switch (section)
  {
    case PlayerSection:
      return @"Player info";
    case PlayingStrengthSection:
      return @"Playing strength";
    case ResignBehaviourSection:
      return @"Resign behaviour";
    case ProfileNotesSection:
      return @"Notes";
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
  if (self.player && section == PlayerSection)
  {
    if (self.player.isPlaying)
      return @"This setting cannot be changed because the player currently participates in a game.";
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSUInteger section = indexPath.section;
  if (! self.player)
    section++;

  UITableViewCell* cell = nil;
  switch (section)
  {
    case PlayerSection:
    {
      switch (indexPath.row)
      {
        case PlayerNameItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView reusableCellIdentifier:@"TextFieldCellType"];
          [UiUtilities setupDefaultTypeCell:cell withText:self.player.name placeHolder:@"Player name" textIsRequired:true];
          break;
        }
        case IsHumanItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          cell.textLabel.text = @"Human player";
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          [accessoryView addTarget:self action:@selector(toggleIsHuman:) forControlEvents:UIControlEventValueChanged];
          accessoryView.on = self.player.human;
          // Player type can be changed only if player is not currently playing a game
          accessoryView.enabled = (! self.player.isPlaying);
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
        case PlayingStrengthAdvancedConfigurationItem:
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
    case ResignBehaviourSection:
    {
      switch (indexPath.row)
      {
        case ResignBehaviourItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Resign behaviour";
          if (customResignBehaviour == self.profile.resignBehaviour)
            cell.detailTextLabel.text = @"Custom";
          else
          {
            cell.detailTextLabel.text = [self resignBehaviourName:self.profile.resignBehaviour];
          }
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case ResignBehaviourAdvancedConfigurationItem:
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
    case ProfileNotesSection:
    {
      switch (indexPath.row)
      {
        case ProfileNotesItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView reusableCellIdentifier:@"TextFieldCellType"];
          [UiUtilities setupDefaultTypeCell:cell withText:self.profile.profileDescription placeHolder:@"Notes" textIsRequired:false];
          if (! self.player)
            cell.accessoryType = UITableViewCellAccessoryNone;
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

  NSUInteger section = indexPath.section;
  if (! self.player)
    section++;

  if (PlayerSection == section)
  {
    switch (indexPath.row)
    {
      case PlayerNameItem:
      {
        EditTextController* editTextController = [[EditTextController controllerWithText:self.player.name
                                                                                   style:EditTextControllerStyleTextField
                                                                                delegate:self] retain];
        editTextController.title = @"Edit name";
        editTextController.acceptEmptyText = false;
        editTextController.context = [NSNumber numberWithInteger:section];
        [self presentNavigationControllerWithRootViewController:editTextController];
        [editTextController release];
        break;
      }
      default:
      {
        break;
      }
    }
  }
  else if (PlayingStrengthSection == section)
  {
    switch (indexPath.row)
    {
      case PlayingStrengthItem:
      {
        NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
        for (int playingStrength = minimumPlayingStrength; playingStrength <= maximumPlayingStrength; ++playingStrength)
        {
          NSString* playingStrengthString = [NSString stringWithFormat:@"%d", playingStrength];
          [itemList addObject:playingStrengthString];
        }
        int indexOfDefaultPlayingStrength;
        if (customPlayingStrength == self.profile.playingStrength)
          indexOfDefaultPlayingStrength = -1;
        else
          indexOfDefaultPlayingStrength = self.profile.playingStrength - minimumPlayingStrength;
        ItemPickerController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                 screenTitle:@"Playing strength"
                                                                          indexOfDefaultItem:indexOfDefaultPlayingStrength
                                                                                    delegate:self];
        modalController.context = [NSNumber numberWithInteger:section];
        [self presentNavigationControllerWithRootViewController:modalController];
        break;
      }
      case PlayingStrengthAdvancedConfigurationItem:
      {
        EditPlayingStrengthSettingsController* editPlayingStrengthSettingsController = [[EditPlayingStrengthSettingsController controllerForProfile:self.profile withDelegate:self] retain];
        [self.navigationController pushViewController:editPlayingStrengthSettingsController animated:YES];
        [editPlayingStrengthSettingsController release];
        break;
      }
      default:
      {
        assert(0);
        break;
      }
    }
  }
  else if (ResignBehaviourSection == section)
  {
    switch (indexPath.row)
    {
      case ResignBehaviourItem:
      {
        NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
        for (int resignBehaviour = minimumResignBehaviour; resignBehaviour <= maximumResignBehaviour; ++resignBehaviour)
        {
          NSString* resignBehaviourString = [self resignBehaviourName:resignBehaviour];
          [itemList addObject:resignBehaviourString];
        }
        int indexOfDefaultResignBehaviour;
        if (customResignBehaviour == self.profile.resignBehaviour)
          indexOfDefaultResignBehaviour = -1;
        else
          indexOfDefaultResignBehaviour = self.profile.resignBehaviour - minimumResignBehaviour;
        ItemPickerController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                 screenTitle:@"Resign behaviour"
                                                                          indexOfDefaultItem:indexOfDefaultResignBehaviour
                                                                                    delegate:self];
        modalController.context = [NSNumber numberWithInteger:section];
        [self presentNavigationControllerWithRootViewController:modalController];
        break;
      }
      case ResignBehaviourAdvancedConfigurationItem:
      {
        EditResignBehaviourSettingsController* editResignBehaviourSettingsController = [[[EditResignBehaviourSettingsController alloc] init] autorelease];
        editResignBehaviourSettingsController.profile = self.profile;
        editResignBehaviourSettingsController.delegate = self;
        [self.navigationController pushViewController:editResignBehaviourSettingsController animated:YES];
        break;
      }
      default:
      {
        assert(0);
        break;
      }
    }
  }
  else if (ProfileNotesSection == section)
  {
    // We don't allow the user to edit the profile notes of the
    // Human vs. human games profile
    if (! self.player)
      return;

    EditTextController* editTextController = [[EditTextController controllerWithText:self.profile.profileDescription
                                                                               style:EditTextControllerStyleTextView
                                                                            delegate:self] retain];
    editTextController.title = @"Edit notes";
    editTextController.acceptEmptyText = true;
    editTextController.context = [NSNumber numberWithInteger:section];
    [self presentNavigationControllerWithRootViewController:editTextController];
    [editTextController release];
  }
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
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel
{
  if (! didCancel)
  {
    if (editTextController.textHasChanged)
    {
      NSNumber* context = editTextController.context;
      NSInteger sectionFromContext = [context integerValue];
      NSUInteger sectionToReload = sectionFromContext;
      if (! self.player)
        sectionToReload--;

      NSIndexPath* indexPathToReload = nil;
      switch (sectionFromContext)
      {
        case PlayerSection:
        {
          self.player.name = editTextController.text;
          indexPathToReload = [NSIndexPath indexPathForRow:PlayerNameItem inSection:sectionToReload];
          if (self.playerProfileExists)
          {
            if ([self.delegate respondsToSelector:@selector(didChangePlayerProfile:)])
              [self.delegate didChangePlayerProfile:self];
          }
          else
          {
            self.navigationItem.rightBarButtonItem.enabled = [self isPlayerProfileValid];
          }
          break;
        }
        case ProfileNotesSection:
        {
          self.profile.profileDescription = editTextController.text;
          indexPathToReload = [NSIndexPath indexPathForRow:ProfileNotesItem inSection:sectionToReload];
          break;
        }
        default:
        {
          DDLogError(@"%@: Unexpected section %ld", self, (long)sectionFromContext);
          assert(0);
          break;
        }
      }
      if (indexPathToReload)
      {
        NSArray* indexPaths = [NSArray arrayWithObject:indexPathToReload];
        [self.tableView reloadRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationNone];
      }
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
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
      NSNumber* context = controller.context;
      NSInteger sectionIndex = [context integerValue];
      NSUInteger sectionToReload = sectionIndex;
      if (! self.player)
        sectionToReload--;
      NSInteger rowIndex;

      if (PlayingStrengthSection == sectionIndex)
      {
        self.profile.playingStrength = (minimumPlayingStrength + controller.indexOfSelectedItem);
        rowIndex = PlayingStrengthItem;
      }
      else
      {
        self.profile.resignBehaviour = (minimumResignBehaviour + controller.indexOfSelectedItem);
        rowIndex = ResignBehaviourItem;
      }

      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionToReload];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EditPlayingStrengthSettingsDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditPlayingStrengthSettingsDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeProfile:(EditPlayingStrengthSettingsController*)editPlayingStrengthSettingsController
{
  NSUInteger sectionIndex = PlayingStrengthSection;
  NSUInteger rowIndex = PlayingStrengthItem;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - EditResignBehaviourSettingsController overrides

// -----------------------------------------------------------------------------
/// @brief EditResignBehaviourSettingsController protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeResignBehaviour:(EditResignBehaviourSettingsController*)editResignBehaviourSettingsController
{
  NSUInteger sectionIndex = ResignBehaviourSection;
  NSUInteger rowIndex = ResignBehaviourItem;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to create a new player and profile
/// object using the data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
  [model add:self.player];

  if (self.profile)
  {
    GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
    [model add:self.profile];
  }

  if ([self.delegate respondsToSelector:@selector(didCreatePlayerProfile:)])
    [self.delegate didCreatePlayerProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user taps "done" to dismiss this controller. The
/// "done" button is shown only if this controller is presented modally.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(didEditPlayerProfile:)])
    [self.delegate didEditPlayerProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Is Human" switch. Updates the Player
/// object with the new value and also updates the UI.
// -----------------------------------------------------------------------------
- (void) toggleIsHuman:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  // Player object reacts to changing the flag by either removing the profile
  // reference, or adding a reference to the first existing profile
  self.player.human = accessoryView.on;

  bool hasOldProfile = (self.profile != nil);
  if (self.player.isHuman != hasOldProfile)
  {
    assert(0);
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"isHuman %d and hasOldProfile %d do not match", self.player.isHuman, hasOldProfile] userInfo:nil];
  }

  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;

  if (self.player.isHuman)
  {
    if (self.playerProfileExists)
      [model remove:self.profile];
    else
      ;  // don't remove the profile from the model, it hasn't been added yet

    self.profile = nil;
  }
  else
  {
    self.profile = [[[GtpEngineProfile alloc] init] autorelease];
    self.profile.playingStrength = defaultPlayingStrength;

    if (self.playerProfileExists)
      [model add:self.profile];
    else
      ;  // don't add the profile to the model yet, the user could still cancel

    self.player.gtpEngineProfileUUID = self.profile.uuid;
  }

  if (self.playerProfileExists)
  {
    if ([self.delegate respondsToSelector:@selector(didChangePlayerProfile:)])
      [self.delegate didChangePlayerProfile:self];
  }

  [self.tableView reloadData];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if the current player and/or profile objects contain
/// valid data so that editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isPlayerProfileValid
{
  if (self.player)
    return (self.player.name.length > 0);
  else
    return true;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a resignBehaviour that is
/// suitable for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a resignBehaviour is not
/// recognized.
// -----------------------------------------------------------------------------
- (NSString*) resignBehaviourName:(int)resignBehaviour
{
  switch (resignBehaviour)
  {
    case 0:
      return @"Custom";
    case 1:
      return @"Pushover";
    case 2:
      return @"Resign quickly";
    case 3:
      return @"Normal";
    case 4:
      return @"Stubborn";
    case 5:
      return @"Never resign";
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid resign behaviour: %d", resignBehaviour];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
