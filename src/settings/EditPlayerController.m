// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "../gtp/GtpUtilities.h"
#import "../main/ApplicationDelegate.h"
#import "../player/PlayerModel.h"
#import "../player/Player.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"
#import "../shared/LayoutManager.h"
#import "../ui/TableViewCellFactory.h"
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
  EditGtpEngineProfileItem,
  MaxGtpEngineProfileSectionItem
};


@implementation EditPlayerController

#pragma mark - Initialization and deallocation

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

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  if (self.playerExists)
  {
    self.navigationItem.title = @"Edit Player";
    if (self.presentingViewController)
    {
      self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                                 style:UIBarButtonItemStyleDone
                                                                                target:self
                                                                                action:@selector(done:)] autorelease];
      self.navigationItem.rightBarButtonItem.enabled = [self isPlayerValid];
    }
    else
    {
      self.navigationItem.leftBarButtonItem.enabled = [self isPlayerValid];
    }
  }
  else
  {
    self.navigationItem.title = @"New Player";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(create:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = [self isPlayerValid];
  }
}

#pragma mark - UITableViewDataSource overrides

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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (IsHumanSection == section)
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
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case PlayerNameSection:
    {
      switch (indexPath.row)
      {
        case PlayerNameItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView reusableCellIdentifier:@"TextFieldCellType"];
          [UiUtilities setupDefaultTypeCell:cell withText:self.player.name placeHolder:@"Player name" textIsRequired:true];
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
        {
          assert(0);
          @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
          break;
        }
      }
      break;
    }
    case GtpEngineProfileSection:
    {
      switch (indexPath.row)
      {
        case GtpEngineProfileItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Profile";
          cell.detailTextLabel.text = [self.player gtpEngineProfile].name;
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case EditGtpEngineProfileItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
          cell.textLabel.text = @"Display profile settings ...";
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

  switch (indexPath.section)
  {
    case PlayerNameSection:
    {
      EditTextController* editTextController = [[EditTextController controllerWithText:self.player.name
                                                                                 style:EditTextControllerStyleTextField
                                                                              delegate:self] retain];
      editTextController.title = @"Edit name";
      editTextController.acceptEmptyText = false;
      UINavigationController* navigationController = [[UINavigationController alloc]
                                                      initWithRootViewController:editTextController];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      navigationController.delegate = [LayoutManager sharedManager];
      [self presentViewController:navigationController animated:YES completion:nil];
      [navigationController release];
      [editTextController release];
      break;
    }
    case GtpEngineProfileSection:
    {
      switch (indexPath.row)
      {
        case GtpEngineProfileItem:
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
                                                                               screenTitle:@"Select profile"
                                                                        indexOfDefaultItem:indexOfDefaultProfile
                                                                                  delegate:self];
          UINavigationController* navigationController = [[UINavigationController alloc]
                                                          initWithRootViewController:modalController];
          navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
          navigationController.delegate = [LayoutManager sharedManager];
          [self presentViewController:navigationController animated:YES completion:nil];
          [navigationController release];
          break;
        }
        case EditGtpEngineProfileItem:
        {
          GtpEngineProfile* profile = [self.player gtpEngineProfile];
          EditGtpEngineProfileController* controller = [EditGtpEngineProfileController controllerForProfile:profile withDelegate:self];
          [self.navigationController pushViewController:controller animated:YES];
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
      self.player.name = editTextController.text;
      if (self.playerExists)
      {
        if ([self.delegate respondsToSelector:@selector(didChangePlayer:)])
          [self.delegate didChangePlayer:self];
      }
      else
      {
        self.navigationItem.rightBarButtonItem.enabled = [self isPlayerValid];
      }
      NSIndexPath* indexPathToReload = [NSIndexPath indexPathForRow:PlayerNameItem inSection:PlayerNameSection];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPathToReload];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EditGtpEngineProfileDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditGtpEngineProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController
{
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:GtpEngineProfileItem inSection:GtpEngineProfileSection];
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationNone];
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
      GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
      GtpEngineProfile* newProfile = [[model profileList] objectAtIndex:controller.indexOfSelectedItem];
      self.player.gtpEngineProfileUUID = newProfile.uuid;

      NSUInteger sectionIndex = GtpEngineProfileSection;
      NSUInteger rowIndex = GtpEngineProfileItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];

      if ([GtpUtilities playerProvidingActiveProfile] == self.player)
        [GtpUtilities setupComputerPlayer];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to create a new player object using the
/// data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
  [model add:self.player];

  if ([self.delegate respondsToSelector:@selector(didCreatePlayer:)])
    [self.delegate didCreatePlayer:self];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user taps "done" to dismiss this controller. The
/// "done" button is shown only if this controller is presented modally.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(didEditPlayer:)])
    [self.delegate didEditPlayer:self];
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
  {
    if ([self.delegate respondsToSelector:@selector(didChangePlayer:)])
      [self.delegate didChangePlayer:self];
  }

  // Reloading the section works because it is always there - it just sometimes
  // has zero rows.
  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:GtpEngineProfileSection];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if the current Player object contains valid data so that
/// editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isPlayerValid
{
  return (self.player.name.length > 0);
}

@end
