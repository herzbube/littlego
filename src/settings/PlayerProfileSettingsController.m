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
#import "PlayerProfileSettingsController.h"
#import "../command/ResetPlayersAndProfilesCommand.h"
#import "../go/GoGame.h"
#import "../go/GoGameDocument.h"
#import "../go/GoPlayer.h"
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"
#import "../player/PlayerModel.h"
#import "../player/Player.h"
#import "../shared/LayoutManager.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Players & Profiles" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum PlayerProfileTableViewSection
{
  PlayersSection,
  GtpEngineProfilesSection,
  ResetToDefaultsSection,
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
/// @brief Enumerates items in the ResetToDefaultsSection.
// -----------------------------------------------------------------------------
enum ResetToDefaultsSectionItem
{
  ResetToDefaultsItem,
  MaxResetToDefaultsSectionItem
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

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a PlayerProfileSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (PlayerProfileSettingsController*) controller
{
  PlayerProfileSettingsController* controller = [[PlayerProfileSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
    controller.playerModel = delegate.playerModel;
    controller.gtpEngineProfileModel = delegate.gtpEngineProfileModel;
    [controller setupNotificationResponders];
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayerProfileSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.playerModel = nil;
  self.gtpEngineProfileModel = nil;
  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [self setupKVONotificationResponders];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupKVONotificationResponders
{
  [self.gtpEngineProfileModel addObserver:self forKeyPath:@"activeProfile" options:NSKeyValueObservingOptionOld context:NULL];
  [self.gtpEngineProfileModel.activeProfile addObserver:self forKeyPath:@"name" options:0 context:NULL];
  GoGame* game = [GoGame sharedGame];
  [game.playerBlack.player addObserver:self forKeyPath:@"name" options:0 context:NULL];
  [game.playerWhite.player addObserver:self forKeyPath:@"name" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self removeKVONotificationResponders];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeKVONotificationResponders
{
  [self.gtpEngineProfileModel removeObserver:self forKeyPath:@"activeProfile"];
  [self.gtpEngineProfileModel.activeProfile removeObserver:self forKeyPath:@"name"];
  GoGame* game = [GoGame sharedGame];
  [game.playerBlack.player removeObserver:self forKeyPath:@"name"];
  [game.playerWhite.player removeObserver:self forKeyPath:@"name"];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Players & Profiles";
  // self.editButtonItem is a standard item provided by UIViewController, which
  // is linked to triggering the view's edit mode
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This is called when the user taps the edit/done button.
///
/// We override this so that we can add rows to the table view for adding new
/// players and GTP engine profiles (or remove those rows again when editing
/// ends).
// -----------------------------------------------------------------------------
- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
  // Invoke super implementation, as per API documentation
  [super setEditing:editing animated:animated];
  // Update footer titles. I have not found a more graceful way how to do this
  // than to reload entire sections
  NSRange indexSetRange = NSMakeRange(PlayersSection, 3);
  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:indexSetRange];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
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
    case PlayersSection:
      return MaxPlayersSectionItem + self.playerModel.playerCount;
    case GtpEngineProfilesSection:
      return MaxGtpEngineProfilesSectionItem + self.gtpEngineProfileModel.profileCount;
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
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case PlayersSection:
      return @"Players";
    case GtpEngineProfilesSection:
      return @"Profiles";
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
    case PlayersSection:
    {
      if (self.tableView.editing)
        return @"Players that are participating in the current game cannot be deleted.";
      break;
    }
    case GtpEngineProfilesSection:
    {
      if (self.tableView.editing)
        return @"The human vs. human games profile and the active profile (may be the same) cannot be deleted.";
      else
        return @"A profile is a collection of technical settings that define how the computer calculates its moves when that profile is active. Profiles can be attached to computer players to adjust their playing strength.";
    }
    default:
    {
      break;
    }
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
    case PlayersSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      // TODO add icon to player entries to distinguish human from computer
      // players
      if (indexPath.row < self.playerModel.playerCount)
      {
        // Cast is required because NSInteger and int differ in size in 64-bit.
        // Cast is safe because this app was not made to handle more than
        // pow(2, 31) players.
        cell.textLabel.text = [self.playerModel playerNameAtIndex:(int)indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      else if (indexPath.row == self.playerModel.playerCount)
      {
        cell.textLabel.text = @"Add new player";
        cell.accessoryType = UITableViewCellAccessoryNone;
      }
      else
      {
        assert(0);
      }
      break;
    }
    case GtpEngineProfilesSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      if (indexPath.row < self.gtpEngineProfileModel.profileCount)
      {
        // Cast is required because NSInteger and int differ in size in 64-bit.
        // Cast is safe because this app was not made to handle more than
        // pow(2, 31) profiles.
        cell.textLabel.text = [self.gtpEngineProfileModel profileNameAtIndex:(int)indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      else if (indexPath.row == self.gtpEngineProfileModel.profileCount)
      {
        cell.textLabel.text = @"Add new profile";
        cell.accessoryType = UITableViewCellAccessoryNone;
      }
      else
      {
        assert(0);
      }
      break;
    }
    case ResetToDefaultsSection:
    {
      cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
      cell.textLabel.text = @"Reset to default players & profiles";
      if (self.editing)
        cell.textLabel.textColor = [UIColor lightGrayColor];
      else
        cell.textLabel.textColor = [UIColor redColor];
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
          GtpEngineProfile* profileToDelete = [self.gtpEngineProfileModel.profileList objectAtIndex:indexPath.row];
          NSString* profileToDeleteUUID = profileToDelete.uuid;

          // Players that refer to the profile that is about to be deleted need
          // a replacement. We use the first profile that we can find that is
          // not the "human vs. human games" profile. If no such profile exists
          // we fallback to the "human vs. human games" profile after all.
          NSString* replacementProfileUUID = fallbackGtpEngineProfileUUID;
          for (GtpEngineProfile* replacementProfile in self.gtpEngineProfileModel.profileList)
          {
            if ([replacementProfile.uuid isEqualToString:profileToDeleteUUID])
              continue;
            if ([replacementProfile.uuid isEqualToString:fallbackGtpEngineProfileUUID])
              continue;
            replacementProfileUUID = replacementProfile.uuid;
            break;
          }

          // Now re-associate players that refer to the profile that is about to
          // be deleted. Note that it is not possible to delete the active
          // profile, so we don't have to handle a change of the active profile
          // here.
          for (Player* player in self.playerModel.playerList)
          {
            if ([profileToDeleteUUID isEqualToString:player.gtpEngineProfileUUID])
              player.gtpEngineProfileUUID = replacementProfileUUID;
          }
          [self.gtpEngineProfileModel remove:profileToDelete];
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

#pragma mark - UITableViewDelegate overrides

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
    case ResetToDefaultsSection:
    {
      UIAlertController* outerAlertController = [UIAlertController alertControllerWithTitle:@"Please confirm"
                                                                                    message:@"This will discard ALL players and profiles that currently exist, and restore those players and profiles that come with the app when it is installed from the App Store.\n\nAre you sure you want to do this?"
                                                                             preferredStyle:UIAlertControllerStyleAlert];

      UIAlertAction* outerNoAction = [UIAlertAction actionWithTitle:@"No"
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction* action) {}];
      [outerAlertController addAction:outerNoAction];

      void (^outerYesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
      {
        if ([GoGame sharedGame].document.dirty)
        {
          UIAlertController* innerAlertController = [UIAlertController alertControllerWithTitle:@"Please confirm"
                                                                                        message:@"The current game has unsaved changes. In order to proceed, the current game must be discarded so that a new game can be started with the restored players and profiles.\n\nAre you sure you want to discard the current game and lose all unsaved changes?"
                                                                                 preferredStyle:UIAlertControllerStyleAlert];

          UIAlertAction* innerNoAction = [UIAlertAction actionWithTitle:@"No"
                                                                  style:UIAlertActionStyleCancel
                                                                handler:^(UIAlertAction* action) {}];
          [innerAlertController addAction:innerNoAction];

          void (^innerYesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
          {
            [self resetToDefaults];
          };
          UIAlertAction* innerYesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:innerYesActionBlock];
          [innerAlertController addAction:innerYesAction];

          [self presentViewController:innerAlertController animated:YES completion:nil];
        }
        else
        {
          [self resetToDefaults];
        }
      };
      UIAlertAction* outerYesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                               style:UIAlertActionStyleDefault
                                                             handler:outerYesActionBlock];
      [outerAlertController addAction:outerYesAction];

      [self presentViewController:outerAlertController animated:YES completion:nil];
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
        if ([profile isFallbackProfile] || profile.isActiveProfile)
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

#pragma mark - Create new player

// -----------------------------------------------------------------------------
/// @brief Displays EditPlayerController to gather information required to
/// create a new player.
// -----------------------------------------------------------------------------
- (void) newPlayer
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

#pragma mark - Edit existing player

// -----------------------------------------------------------------------------
/// @brief Displays EditPlayerController to allow the user to change player
/// information.
// -----------------------------------------------------------------------------
- (void) editPlayer:(Player*)player
{
  EditPlayerController* editPlayerController = [EditPlayerController controllerForPlayer:player withDelegate:self];
  UINavigationController* navigationController = [[[UINavigationController alloc]
                                                   initWithRootViewController:editPlayerController] autorelease];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  navigationController.delegate = [LayoutManager sharedManager];
  [self presentViewController:navigationController animated:YES completion:nil];
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
/// @brief EditPlayerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didEditPlayer:(EditPlayerController*)editPlayerController
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Create new profile

// -----------------------------------------------------------------------------
/// @brief Displays EditGtpEngineProfileController to gather information
/// required to create a new GtpEngineProfile.
// -----------------------------------------------------------------------------
- (void) newProfile
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

#pragma mark - Edit existing profile

// -----------------------------------------------------------------------------
/// @brief Displays EditGtpEngineProfileController to allow the user to change
/// profile information.
// -----------------------------------------------------------------------------
- (void) editProfile:(GtpEngineProfile*)profile
{
  EditGtpEngineProfileController* editProfileController = [EditGtpEngineProfileController controllerForProfile:profile withDelegate:self];
  UINavigationController* navigationController = [[[UINavigationController alloc]
                                                   initWithRootViewController:editProfileController] autorelease];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  navigationController.delegate = [LayoutManager sharedManager];
  [self presentViewController:navigationController animated:YES completion:nil];
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
/// @brief EditGtpEngineProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didEditProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  [self removeKVONotificationResponders];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  [self setupKVONotificationResponders];
  // Here we are dealing with the (forbidden) scenario that the user can delete
  // a player that is associated with a running game. Imagine this:
  // - We have 3 players, A, B and C
  // - A game is currently running, with A and B playing
  // - The setting view enters editing mode; since C is not playing, its cell
  //   is marked as "deletable" (UITableViewCellEditingStyleDelete)
  // - The user now switches away from the settings view to the Play UI area,
  //   where he deviously starts a new game with A and C playing
  // - The user comes back to the settings view, which is still in editing
  //   mode, with the cell for C still marked as deletable
  // - The user deletes player C, which is forbidden!
  // To prevent this from happening, we simply turn editing off if a new game
  // is created.
  if (self.tableView.editing)
  {
    // The notification may be posted on a secondary thread. Because UIKit is
    // not thread-safe we must make sure that we invoke the UIKit method on the
    // main thread.
    [self performSelector:@selector(disableEditingOnMainThread)
                 onThread:[NSThread mainThread]
               withObject:nil
            waitUntilDone:NO];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper. Is invoked in the context of the main thread.
// -----------------------------------------------------------------------------
- (void) disableEditingOnMainThread
{
  [self setEditing:NO animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == self.gtpEngineProfileModel)
  {
    GtpEngineProfile* oldProfile = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldProfile)
      [oldProfile removeObserver:self forKeyPath:@"name"];
    GtpEngineProfile* newProfile = self.gtpEngineProfileModel.activeProfile;
    if (newProfile)
      [newProfile addObserver:self forKeyPath:@"name" options:0 context:NULL];
    // New active profile must not be delete-able; old active profile can now
    // be deleted
    if (self.tableView.editing)
    {
      NSMutableArray* indexPathsToReload = [NSMutableArray array];
      if (oldProfile)
      {
        NSUInteger row = [self.gtpEngineProfileModel.profileList indexOfObject:oldProfile];
        [indexPathsToReload addObject:[NSIndexPath indexPathForRow:row inSection:GtpEngineProfilesSection]];
      }
      if (newProfile)
      {
        NSUInteger row = [self.gtpEngineProfileModel.profileList indexOfObject:newProfile];
        [indexPathsToReload addObject:[NSIndexPath indexPathForRow:row inSection:GtpEngineProfilesSection]];
      }
      [self.tableView reloadRowsAtIndexPaths:indexPathsToReload
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  else if ([object isKindOfClass:[GtpEngineProfile class]])
  {
    NSUInteger row = [self.gtpEngineProfileModel.profileList indexOfObject:object];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:GtpEngineProfilesSection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }
  else if ([object isKindOfClass:[Player class]])
  {
    NSUInteger row = [self.playerModel.playerList indexOfObject:object];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:PlayersSection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }
}

#pragma mark - Reset to defaults

// -----------------------------------------------------------------------------
/// @brief Resets all players and profiles to their factory defaults. Also
/// starts a new game.
// -----------------------------------------------------------------------------
- (void) resetToDefaults
{
  if (self.tableView.editing)
    [self setEditing:NO animated:YES];
  [self removeNotificationResponders];
  [[[[ResetPlayersAndProfilesCommand alloc] init] autorelease] submit];
  [self setupNotificationResponders];
  [self.tableView reloadData];
}

@end
