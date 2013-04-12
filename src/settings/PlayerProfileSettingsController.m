// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayerProfileSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"
#import "../player/PlayerModel.h"
#import "../player/Player.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Players & Profiles" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum PlayerProfileTableViewSection
{
  PlayersSection,
  GtpEngineProfilesSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayersSection.
// -----------------------------------------------------------------------------
enum PlayersSectionItem
{
  AddPlayerItem,
  MaxPlayersSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GtpEngineProfilesSection.
// -----------------------------------------------------------------------------
enum GtpEngineProfilesSectionItem
{
  AddGtpEngineProfileItem,
  MaxGtpEngineProfilesSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayerProfileSettingsController.
// -----------------------------------------------------------------------------
@interface PlayerProfileSettingsController()
@property(nonatomic, assign) PlayerModel* playerModel;
@property(nonatomic, assign) GtpEngineProfileModel* gtpEngineProfileModel;
@end


@implementation PlayerProfileSettingsController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a PlayerProfileSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (PlayerProfileSettingsController*) controller
{
  PlayerProfileSettingsController* controller = [[PlayerProfileSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
    [controller autorelease];
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayerProfileSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.playerModel = nil;
  self.gtpEngineProfileModel = nil;
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
  self.playerModel = delegate.playerModel;
  self.gtpEngineProfileModel = delegate.gtpEngineProfileModel;

  self.title = @"Players & Profiles";
  
  // self.editButtonItem is a standard item provided by UIViewController, which
  // is linked to triggering the view's edit mode
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];

  // Undo all of the stuff that is happening in viewDidLoad
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.playerModel = nil;
  self.gtpEngineProfileModel = nil;
  self.navigationItem.rightBarButtonItem = nil;
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief Called when the user taps the edit/done button.
///
/// We override this so that we can add rows to the table view for adding new
/// players and GTP engine profiles (or remove those rows again when editing
/// ends).
// -----------------------------------------------------------------------------
- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
  // Invoke super implementation, as per API documentation
  [super setEditing:editing animated:animated];

  NSIndexPath* indexPathAddPlayerRow = [NSIndexPath indexPathForRow:self.playerModel.playerCount
                                                          inSection:PlayersSection];
  NSIndexPath* indexPathAddProfileRow = [NSIndexPath indexPathForRow:self.gtpEngineProfileModel.profileCount
                                                           inSection:GtpEngineProfilesSection];
  NSArray* indexPaths = [NSArray arrayWithObjects:indexPathAddPlayerRow, indexPathAddProfileRow, nil];
  if (editing)
  {
    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationBottom];
  }
  else
  {
    [self.tableView deleteRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationBottom];
  }
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
    case PlayersSection:
      if (self.tableView.editing)
        return MaxPlayersSectionItem + self.playerModel.playerCount;
      else
        return self.playerModel.playerCount;
    case GtpEngineProfilesSection:
      if (self.tableView.editing)
        return MaxGtpEngineProfilesSectionItem + self.gtpEngineProfileModel.profileCount;
      else
        return self.gtpEngineProfileModel.profileCount;
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
    case PlayersSection:
      return @"Players";
    case GtpEngineProfilesSection:
      return @"Profiles";
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
  if (PlayersSection == section)
    return @"Players that are participating in the current game cannot be deleted.";
  else if (GtpEngineProfilesSection == section)
    return @"A profile is a collection of technical settings that define how the computer calculates its moves when that profile is active. Profiles can be attached to computer players to adjust their playing strength. The default profile cannot be deleted.";
  else
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
    case PlayersSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      // TODO add icon to player entries to distinguish human from computer
      // players
      if (indexPath.row < self.playerModel.playerCount)
        cell.textLabel.text = [self.playerModel playerNameAtIndex:indexPath.row];
      else if (indexPath.row == self.playerModel.playerCount)
        cell.textLabel.text = @"Add player ...";  // visible only during editing mode
      else
        assert(0);
      break;
    }
    case GtpEngineProfilesSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      if (indexPath.row < self.gtpEngineProfileModel.profileCount)
        cell.textLabel.text = [self.gtpEngineProfileModel profileNameAtIndex:indexPath.row];
      else if (indexPath.row == self.gtpEngineProfileModel.profileCount)
        cell.textLabel.text = @"Add profile ...";  // visible only during editing mode
      else
        assert(0);
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
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (indexPath.section)
  {
    case PlayersSection:
    case GtpEngineProfilesSection:
      // Rows that are editable are indented, the delegate determines which
      // editing style to use in tableView:editingStyleForRowAtIndexPath:()
      return YES;
    default:
      break;
  }
  // Rows that are not editable are not indented
  return NO;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (editingStyle)
  {
    case UITableViewCellEditingStyleDelete:
    {
      switch (indexPath.section)
      {
        case PlayersSection:
        {
          Player* player = [self.playerModel.playerList objectAtIndex:indexPath.row];
          [self.playerModel remove:player];
          break;
        }
        case GtpEngineProfilesSection:
        {
          GtpEngineProfile* profile = [self.gtpEngineProfileModel.profileList objectAtIndex:indexPath.row];
          NSString* profileUUID = profile.uuid;
          NSString* defaultProfileUUID = [self.gtpEngineProfileModel defaultProfile].uuid;
          // Players that refer to the profile that is about to be deleted,
          // are set to refer to the default profile instead
          for (Player* player in self.playerModel.playerList)
          {
            if ([profileUUID isEqualToString:player.gtpEngineProfileUUID])
              player.gtpEngineProfileUUID = defaultProfileUUID;
          }
          [self.gtpEngineProfileModel remove:profile];
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      // Animate item deletion. Requires that in the meantime we have not
      // triggered a reloadData().
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
      break;
    }
    case UITableViewCellEditingStyleInsert:
    {
      switch (indexPath.section)
      {
        case PlayersSection:
        {
          [self newPlayer];
          break;
        }
        case GtpEngineProfilesSection:
        {
          [self newProfile];
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
      return;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  switch (indexPath.section)
  {
    case PlayersSection:
    {
      if (indexPath.row < self.playerModel.playerCount)
        [self editPlayer:[self.playerModel.playerList objectAtIndex:indexPath.row]];
      else if (indexPath.row == self.playerModel.playerCount)
        [self newPlayer];
      else
        assert(0);
      break;
    }
    case GtpEngineProfilesSection:
    {
      if (indexPath.row < self.gtpEngineProfileModel.profileCount)
        [self editProfile:[self.gtpEngineProfileModel.profileList objectAtIndex:indexPath.row]];
      else if (indexPath.row == self.gtpEngineProfileModel.profileCount)
        [self newProfile];
      else
        assert(0);
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCellEditingStyle) tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (indexPath.section)
  {
    case PlayersSection:
    {
      if (indexPath.row < self.playerModel.playerCount)
      {
        Player* player = [self.playerModel.playerList objectAtIndex:indexPath.row];
        if (player.isPlaying)
          return UITableViewCellEditingStyleNone;
        else
          return UITableViewCellEditingStyleDelete;
      }
      else if (indexPath.row == self.playerModel.playerCount)
        return UITableViewCellEditingStyleInsert;
      else
        assert(0);
      break;
    }
    case GtpEngineProfilesSection:
    {
      if (indexPath.row < self.gtpEngineProfileModel.profileCount)
      {
        GtpEngineProfile* profile = [self.gtpEngineProfileModel.profileList objectAtIndex:indexPath.row];
        if ([profile isDefaultProfile])
          return UITableViewCellEditingStyleNone;
        else
          return UITableViewCellEditingStyleDelete;
      }
      else if (indexPath.row == self.gtpEngineProfileModel.profileCount)
        return UITableViewCellEditingStyleInsert;
      else
        assert(0);
      break;
    }
    default:
    {
      break;
    }
  }
  return UITableViewCellEditingStyleNone;
}

// -----------------------------------------------------------------------------
/// @brief Displays EditPlayerController to gather information required to
/// create a new player.
// -----------------------------------------------------------------------------
- (void) newPlayer;
{
  EditPlayerController* editPlayerController = [[EditPlayerController controllerWithDelegate:self] retain];
  [self.navigationController pushViewController:editPlayerController animated:YES];
  [editPlayerController release];
}

// -----------------------------------------------------------------------------
/// @brief EditPlayerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didCreatePlayer:(EditPlayerController*)editPlayerController
{
  [self.navigationController popViewControllerAnimated:YES];
  int newPlayerRow = self.playerModel.playerCount - 1;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:newPlayerRow inSection:PlayersSection];
  [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationTop];  
}

// -----------------------------------------------------------------------------
/// @brief Displays EditPlayerController to allow the user to change player
/// information.
// -----------------------------------------------------------------------------
- (void) editPlayer:(Player*)player
{
  EditPlayerController* editPlayerController = [[EditPlayerController controllerForPlayer:player withDelegate:self] retain];
  [self.navigationController pushViewController:editPlayerController animated:YES];
  [editPlayerController release];
}

// -----------------------------------------------------------------------------
/// @brief EditPlayerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangePlayer:(EditPlayerController*)editPlayerController
{
  NSUInteger changedPlayerRow = [self.playerModel.playerList indexOfObject:editPlayerController.player];
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:changedPlayerRow inSection:PlayersSection];
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationNone];
}

// -----------------------------------------------------------------------------
/// @brief Displays EditGtpEngineProfileController to gather information
/// required to create a new GtpEngineProfile.
// -----------------------------------------------------------------------------
- (void) newProfile;
{
  EditGtpEngineProfileController* editProfileController = [[EditGtpEngineProfileController controllerWithDelegate:self] retain];
  [self.navigationController pushViewController:editProfileController animated:YES];
  [editProfileController release];
}

// -----------------------------------------------------------------------------
/// @brief EditGtpEngineProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didCreateProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController
{
  [self.navigationController popViewControllerAnimated:YES];
  int newProfileRow = self.gtpEngineProfileModel.profileCount - 1;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:newProfileRow inSection:GtpEngineProfilesSection];
  [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationTop];  
}

// -----------------------------------------------------------------------------
/// @brief Displays EditGtpEngineProfileController to allow the user to change
/// profile information.
// -----------------------------------------------------------------------------
- (void) editProfile:(GtpEngineProfile*)profile
{
  EditGtpEngineProfileController* editProfileController = [[EditGtpEngineProfileController controllerForProfile:profile withDelegate:self] retain];
  [self.navigationController pushViewController:editProfileController animated:YES];
  [editProfileController release];
}

// -----------------------------------------------------------------------------
/// @brief EditGtpEngineProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController
{
  NSUInteger changedProfileRow = [self.gtpEngineProfileModel.profileList indexOfObject:editGtpEngineProfileController.profile];
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:changedProfileRow inSection:GtpEngineProfilesSection];
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationNone];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  // Here we are dealing with the (forbidden) scenario that the user can delete
  // a player that is associated with a running game. Imagine this:
  // - We have 3 players, A, B and C
  // - A game is currently running, with A and B playing
  // - The setting view enters editing mode; since C is not playing, its cell
  //   is marked as "deletable" (UITableViewCellEditingStyleDelete)
  // - The user now switches away from the settings view to the play view,
  //   where he deviously starts a new game with A and C playing
  // - The user comes back to the settings view, which is still in editing
  //   mode, with the cell for C still marked as deletable
  // - The user deletes player C, which is forbidden!
  // To prevent this from happening, we simply turn editing off if a new game
  // is created.
  if (self.tableView.editing)
    [self setEditing:NO animated:YES];
}

@end
