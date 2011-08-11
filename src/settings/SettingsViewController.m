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
#import "SettingsViewController.h"
#import "../ApplicationDelegate.h"
#import "../play/PlayViewModel.h"
#import "../player/PlayerModel.h"
#import "../utility/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Settings" table view.
// -----------------------------------------------------------------------------
enum SettingsTableViewSection
{
  FeedbackSection,
  ViewSection,
  PlayersSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the FeedbackSection.
// -----------------------------------------------------------------------------
enum FeedbackSectionItem
{
  PlaySoundItem,
  VibrateItem,
  MaxFeedbackSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ViewSection.
// -----------------------------------------------------------------------------
enum ViewSectionItem
{
  MarkLastMoveItem,
  DisplayCoordinatesItem,
  DisplayMoveNumbersItem,
  CrossHairPointDistanceFromFingerItem,
  MaxViewSectionItem
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
/// @brief Class extension with private methods for SettingsViewController.
// -----------------------------------------------------------------------------
@interface SettingsViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
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
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
- (void) togglePlaySound:(id)sender;
- (void) toggleVibrate:(id)sender;
- (void) toggleMarkLastMove:(id)sender;
- (void) toggleDisplayCoordinates:(id)sender;
- (void) toggleDisplayMoveNumbers:(id)sender;
//@}
/// @name NewPlayerDelegate protocol
//@{
- (void) didCreateNewPlayer:(NewPlayerController*)newPlayerController;
- (void) didChangePlayer:(EditPlayerController*)editPlayerController;
//@}
/// @name Helpers
//@{
- (void) newPlayer;
- (void) editPlayer:(Player*)player;
//@}
@end


@implementation SettingsViewController

@synthesize playViewModel;
@synthesize playerModel;

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SettingsViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
  self.playViewModel = [delegate playViewModel];
  self.playerModel = [delegate playerModel];
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
    case FeedbackSection:
      return MaxFeedbackSectionItem;
    case ViewSection:
      return MaxViewSectionItem;
    case PlayersSection:
      return MaxPlayersSectionItem + self.playerModel.playerCount;
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
    case FeedbackSection:
      return @"Feedback when computer plays";
    case ViewSection:
      return @"View settings";
    case PlayersSection:
      return @"Players";
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
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case FeedbackSection:
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      switch (indexPath.row)
      {
        case PlaySoundItem:
          cell.textLabel.text = @"Play sound";
          accessoryView.on = self.playViewModel.playSound;
          [accessoryView addTarget:self action:@selector(togglePlaySound:) forControlEvents:UIControlEventValueChanged];
          break;
        case VibrateItem:
          cell.textLabel.text = @"Vibrate";
          accessoryView.on = self.playViewModel.vibrate;
          [accessoryView addTarget:self action:@selector(toggleVibrate:) forControlEvents:UIControlEventValueChanged];
          break;
        default:
          assert(0);
          break;
      }
      break;
    case ViewSection:
      {
        enum TableViewCellType cellType;
        switch (indexPath.row)
        {
          case CrossHairPointDistanceFromFingerItem:
            cellType = Value1CellType;
            break;
          default:
            cellType = SwitchCellType;
            break;
        }
        cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
        UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
        accessoryView.enabled = false;  // TODO enable when settings are implemented
        switch (indexPath.row)
        {
          case MarkLastMoveItem:
            cell.textLabel.text = @"Mark last move";
            accessoryView.on = self.playViewModel.markLastMove;
            accessoryView.enabled = YES;
            [accessoryView addTarget:self action:@selector(toggleMarkLastMove:) forControlEvents:UIControlEventValueChanged];
            break;
          case DisplayCoordinatesItem:
            cell.textLabel.text = @"Coordinates";
            accessoryView.on = self.playViewModel.displayCoordinates;
            [accessoryView addTarget:self action:@selector(toggleDisplayCoordinates:) forControlEvents:UIControlEventValueChanged];
            break;
          case DisplayMoveNumbersItem:
            cell.textLabel.text = @"Move numbers";
            accessoryView.on = self.playViewModel.displayMoveNumbers;
            [accessoryView addTarget:self action:@selector(toggleDisplayMoveNumbers:) forControlEvents:UIControlEventValueChanged];
            break;
          case CrossHairPointDistanceFromFingerItem:
            cell.textLabel.text = @"Cross-hair distance";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.playViewModel.crossHairPointDistanceFromFinger];
            break;
          default:
            assert(0);
            break;
        }
        break;
      }
    case PlayersSection:
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      // TODO add icon to player entries to distinguish human from computer
      // players
      if (indexPath.row < self.playerModel.playerCount)
        cell.textLabel.text = [self.playerModel playerNameAtIndex:indexPath.row];
      else if (indexPath.row == self.playerModel.playerCount)
        cell.textLabel.text = @"Add player ...";
      else
        assert(0);
      break;
    default:
      assert(0);
      break;
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
    case PlayersSection:
      if (indexPath.row < self.playerModel.playerCount)
        [self editPlayer:[self.playerModel.playerList objectAtIndex:indexPath.row]];
      if (indexPath.row == self.playerModel.playerCount)
        [self newPlayer];
      else
        assert(0);
      break;
    default:
      return;
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Play Sound" switch. Writes the new
/// value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) togglePlaySound:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.playSound = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Vibrate" switch. Writes the new
/// value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleVibrate:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.vibrate = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Mark last move" switch. Writes the
/// new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleMarkLastMove:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.markLastMove = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Display coordinates" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleDisplayCoordinates:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.displayCoordinates = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Display move numbers" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleDisplayMoveNumbers:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.displayMoveNumbers = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Displays NewPlayerController to gather information required to
/// create a new player.
// -----------------------------------------------------------------------------
- (void) newPlayer;
{
  NewPlayerController* newPlayerController = [[NewPlayerController controllerWithDelegate:self] retain];
  [self.navigationController pushViewController:newPlayerController animated:YES];
  [newPlayerController release];
}

// -----------------------------------------------------------------------------
/// @brief This method is invoked after @a newPlayerController has created a
/// new player object.
// -----------------------------------------------------------------------------
- (void) didCreateNewPlayer:(NewPlayerController*)newPlayerController
{
  // Reloading the entire table view data is the cheapest way (in terms of code
  // lines) to add a row for the new player.
  [[self tableView] reloadData];
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
/// @brief This method is invoked after @a EditPlayerController has updated its
/// player object with new information.
// -----------------------------------------------------------------------------
- (void) didChangePlayer:(EditPlayerController*)editPlayerController
{
  // Reloading the entire table view data is the cheapest way (in terms of code
  // lines) to update the row with changed data
  [[self tableView] reloadData];
}

@end
