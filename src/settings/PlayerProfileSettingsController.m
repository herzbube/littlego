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
#import "../ui/TableViewCellFactory.h"
#import "../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Players & Profiles" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum PlayerProfileTableViewSection
{
  HumanPlayersSection,
  ComputerPlayersSection,
  HumanVsHumanGamesSection,
  ResetToDefaultsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the HumanPlayersSection.
// -----------------------------------------------------------------------------
enum HumanPlayersSectionItem
{
  AddHumanPlayerItem,
  MaxHumanPlayersSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ComputerPlayersSection.
// -----------------------------------------------------------------------------
enum ComputerPlayersSectionItem
{
  AddComputerPlayerItem,
  MaxComputerPlayersSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the HumanVsHumanGamesSection.
// -----------------------------------------------------------------------------
enum HumanVsHumanGamesSectionItem
{
  HumanVsHumanGamesItem,
  MaxHumanVsHumanGamesSectionItem
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
  // We need to observe these because the user can edit the players
  // participating in the current game in the GameInfo view
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
  self.title = @"Players";
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

  // Update visual style of reset cell
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ResetToDefaultsItem inSection:ResetToDefaultsSection];
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationNone];
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
    case HumanPlayersSection:
      return MaxHumanPlayersSectionItem + [self.playerModel playerListHuman:true].count;
    case ComputerPlayersSection:
      return MaxComputerPlayersSectionItem + [self.playerModel playerListHuman:false].count;
    case HumanVsHumanGamesSection:
      return MaxHumanVsHumanGamesSectionItem;
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
    case HumanPlayersSection:
      return @"Human players";
    case ComputerPlayersSection:
      return @"Computer players";
    case HumanVsHumanGamesSection:
      return @"Background computer player";
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
    case HumanPlayersSection:
    case ComputerPlayersSection:
    {
      // Ideally we should display this footer only while editing is active.
      // The problem is that showing/hiding this footer in reaction to editing
      // becoming enabled/disabled breaks the table view's rendering of cells
      // in various ways on various iOS versions / iOS devices. Note that
      // editing can be enabled in two ways: 1) For the entire table view, when
      // the user taps the "Edit" toolbar button; and 2) For an individual cell,
      // when the user left-swipes the cell and iOS displays a "Delete" button
      // for that cell only.
      return @"Players that are participating in the current game cannot be deleted.";
    }
    case HumanVsHumanGamesSection:
    {
      return @"Tap to edit the settings of the computer player that operates in the background during human vs. human games and calculates moves upon request.";
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
    case HumanPlayersSection:
    case ComputerPlayersSection:
    {
      bool isHuman = (indexPath.section == HumanPlayersSection);
      NSArray* playerList = [self.playerModel playerListHuman:isHuman];
      if (indexPath.row < playerList.count)
      {
        Player* player = [playerList objectAtIndex:indexPath.row];
        cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
        cell.textLabel.text = player.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      else if (indexPath.row == playerList.count)
      {
        cell = [TableViewCellFactory cellWithType:ActionTextCellType tableView:tableView];
        if (isHuman)
          cell.textLabel.text = @"Add new human player";
        else
          cell.textLabel.text = @"Add new computer player";
      }
      else
      {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
        assert(0);
      }
      break;
    }
    case HumanVsHumanGamesSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.textLabel.text = self.gtpEngineProfileModel.fallbackProfile.name;
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case ResetToDefaultsSection:
    {
      cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
      cell.textLabel.text = @"Reset to defaults";
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
    case HumanPlayersSection:
    case ComputerPlayersSection:
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
        case HumanPlayersSection:
        case ComputerPlayersSection:
        {
          bool isHuman = (indexPath.section == HumanPlayersSection);
          NSArray* playerList = [self.playerModel playerListHuman:isHuman];
          Player* player = [playerList objectAtIndex:indexPath.row];
          [self.playerModel remove:player];
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
        case HumanPlayersSection:
        case ComputerPlayersSection:
        {
          bool isHuman = (indexPath.section == HumanPlayersSection);
          [self newPlayer:isHuman];
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
    case HumanPlayersSection:
    case ComputerPlayersSection:
    {
      bool isHuman = (indexPath.section == HumanPlayersSection);
      NSArray* playerList = [self.playerModel playerListHuman:isHuman];
      if (indexPath.row < playerList.count)
        [self editPlayer:[playerList objectAtIndex:indexPath.row]];
      else if (indexPath.row == playerList.count)
        [self newPlayer:isHuman];
      else
        assert(0);
      break;
    }
    case HumanVsHumanGamesSection:
    {
      [self editProfile:self.gtpEngineProfileModel.fallbackProfile];
      break;
    }
    case ResetToDefaultsSection:
    {
      void (^outerYesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
      {
        if ([GoGame sharedGame].document.dirty)
        {
          void (^innerYesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
          {
            [self resetToDefaults];
          };

          [self presentYesNoAlertWithTitle:@"Please confirm"
                                   message:@"The current game has unsaved changes. In order to proceed, the current game must be discarded so that a new game can be started with the restored players.\n\nAre you sure you want to discard the current game and lose all unsaved changes?"
                                yesHandler:innerYesActionBlock
                                 noHandler:nil];
        }
        else
        {
          [self resetToDefaults];
        }
      };

      [self presentYesNoAlertWithTitle:@"Please confirm"
                               message:@"This will discard ALL players that currently exist, and restore those players that come with the app when it is installed from the App Store.\n\nAre you sure you want to do this?"
                            yesHandler:outerYesActionBlock
                             noHandler:nil];
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
    case HumanPlayersSection:
    case ComputerPlayersSection:
    {
      bool isHuman = (indexPath.section == HumanPlayersSection);
      NSArray* playerList = [self.playerModel playerListHuman:isHuman];
      if (indexPath.row < playerList.count)
      {
        Player* player = [playerList objectAtIndex:indexPath.row];
        if (player.isPlaying)
          return UITableViewCellEditingStyleNone;
        else
          return UITableViewCellEditingStyleDelete;
      }
      else if (indexPath.row == playerList.count)
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
/// @brief Displays EditPlayerProfileController to gather information required
/// to create a new player and profile.
// -----------------------------------------------------------------------------
- (void) newPlayer:(bool)isHuman
{
  EditPlayerProfileController* editPlayerProfileController = [[EditPlayerProfileController controllerForHumanPlayer:isHuman
                                                                                                       withDelegate:self] retain];
  [self.navigationController pushViewController:editPlayerProfileController animated:YES];
  [editPlayerProfileController release];
}

// -----------------------------------------------------------------------------
/// @brief EditPlayerProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didCreatePlayerProfile:(EditPlayerProfileController*)editPlayerProfileController
{
  [self.navigationController popViewControllerAnimated:YES];

  bool isHuman = editPlayerProfileController.player.isHuman;
  NSArray* playerList = [self.playerModel playerListHuman:isHuman];
  NSUInteger newPlayerRow = playerList.count - 1;
  NSInteger section = isHuman ? HumanPlayersSection : ComputerPlayersSection;

  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:newPlayerRow inSection:section];

  [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationTop];  
}

#pragma mark - Edit existing player or profile

// -----------------------------------------------------------------------------
/// @brief Displays EditPlayerProfileController to allow the user to change
/// player and profile information.
// -----------------------------------------------------------------------------
- (void) editPlayer:(Player*)player
{
  EditPlayerProfileController* editPlayerProfileController = [EditPlayerProfileController controllerForPlayer:player withDelegate:self];
  [self presentNavigationControllerWithRootViewController:editPlayerProfileController];
}

// -----------------------------------------------------------------------------
/// @brief Displays EditPlayerProfileController to allow the user to change
/// profile information.
// -----------------------------------------------------------------------------
- (void) editProfile:(GtpEngineProfile*)profile
{
  EditPlayerProfileController* editPlayerProfileController = [EditPlayerProfileController controllerForProfile:profile withDelegate:self];
  [self presentNavigationControllerWithRootViewController:editPlayerProfileController];
}

// -----------------------------------------------------------------------------
/// @brief EditPlayerProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangePlayerProfile:(EditPlayerProfileController*)editPlayerProfileController
{
  if (editPlayerProfileController.player != nil)
  {
    // The user might change the player's "is human" flag, which means we would
    // need to remove the player from one section and it to the other. This is
    // much too complicated, we're simply reloading both sections. This should
    // not be a problem since the user is still on the editing screen and does
    // not see the reloading taking place.
    NSRange indexSetRange = NSMakeRange(HumanPlayersSection, 2);
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:indexSetRange];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

// -----------------------------------------------------------------------------
/// @brief EditPlayerProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didEditPlayerProfile:(EditPlayerProfileController*)editPlayerProfileController
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
  if ([object isKindOfClass:[Player class]])
  {
    Player* player = object;
    bool isHuman = player.isHuman;
    NSArray* playerList = [self.playerModel playerListHuman:isHuman];
    NSUInteger row = [playerList indexOfObject:player];
    NSInteger section = isHuman ? HumanPlayersSection : ComputerPlayersSection;

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];

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
