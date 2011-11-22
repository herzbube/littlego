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
#import "../play/ScoringModel.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/PlayerModel.h"
#import "../ui/TableViewCellFactory.h"


NSString* markDeadStonesIntelligentlyText = @"Mark dead stones intelligently";


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Settings" table view.
// -----------------------------------------------------------------------------
enum SettingsTableViewSection
{
  FeedbackSection,
  ViewSection,
  ScoringSection,
  PlayersSection,
  GtpEngineProfilesSection,
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
//  DisplayCoordinatesItem,
//  DisplayMoveNumbersItem,
//  CrossHairPointDistanceFromFingerItem,
  MaxViewSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ScoringSection.
// -----------------------------------------------------------------------------
enum ScoringSectionItem
{
  AskGtpEngineForDeadStonesItem,
  MarkDeadStonesIntelligentlyItem,
  MaxScoringSectionItem
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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
- (void) togglePlaySound:(id)sender;
- (void) toggleVibrate:(id)sender;
- (void) toggleMarkLastMove:(id)sender;
- (void) toggleDisplayCoordinates:(id)sender;
- (void) toggleDisplayMoveNumbers:(id)sender;
- (void) toggleAskGtpEngineForDeadStones:(id)sender;
- (void) toggleMarkDeadStonesIntelligently:(id)sender;
//@}
/// @name EditPlayerDelegate protocol
//@{
- (void) didChangePlayer:(EditPlayerController*)editPlayerController;
- (void) didDeletePlayer:(EditPlayerController*)editPlayerController;
//@}
/// @name NewPlayerDelegate protocol
//@{
- (void) didCreateNewPlayer:(NewPlayerController*)newPlayerController;
//@}
/// @name EditGtpEngineProfileDelegate protocol
//@{
- (void) didChangeProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController;
- (void) didDeleteProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController;
//@}
/// @name NewGtpEngineProfileDelegate protocol
//@{
- (void) didCreateNewProfile:(NewGtpEngineProfileController*)newGtpEngineProfileController;
//@}
/// @name Private helpers
//@{
- (void) newPlayer;
- (void) newProfile;
- (void) editPlayer:(Player*)player;
- (void) editProfile:(GtpEngineProfile*)profile;
//@}
/// @name Privately declared properties
//@{
@property(assign) PlayViewModel* playViewModel;
@property(assign) ScoringModel* scoringModel;
@property(assign) PlayerModel* playerModel;
@property(assign) GtpEngineProfileModel* gtpEngineProfileModel;
//@}
@end


@implementation SettingsViewController

@synthesize playViewModel;
@synthesize scoringModel;
@synthesize playerModel;
@synthesize gtpEngineProfileModel;


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
  self.playViewModel = delegate.playViewModel;
  self.scoringModel = delegate.scoringModel;
  self.playerModel = delegate.playerModel;
  self.gtpEngineProfileModel = delegate.gtpEngineProfileModel;
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
    case ScoringSection:
      return MaxScoringSectionItem;
    case PlayersSection:
      return MaxPlayersSectionItem + self.playerModel.playerCount;
    case GtpEngineProfilesSection:
      return MaxGtpEngineProfilesSectionItem + self.gtpEngineProfileModel.profileCount;
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
    case ScoringSection:
      return @"Scoring";
    case PlayersSection:
      return @"Players";
    case GtpEngineProfilesSection:
      return @"GTP engine profiles";
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
  if (GtpEngineProfilesSection == section)
    return @"A GTP engine profile is a collection of technical settings that define how the GTP engine behaves when that profile is active. Profiles can be attached to computer players to adjust their playing strength.";
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
    case FeedbackSection:
    {
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
    }
    case ViewSection:
    {
      enum TableViewCellType cellType;
      switch (indexPath.row)
      {
//          case CrossHairPointDistanceFromFingerItem:
//            cellType = Value1CellType;
//            break;
        default:
          cellType = SwitchCellType;
          break;
      }
      cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
      UISwitch* accessoryView = nil;
      if (SwitchCellType == cellType)
      {
        accessoryView = (UISwitch*)cell.accessoryView;
        accessoryView.enabled = false;  // TODO enable when settings are implemented
      }
      switch (indexPath.row)
      {
        case MarkLastMoveItem:
          cell.textLabel.text = @"Mark last move";
          accessoryView.on = self.playViewModel.markLastMove;
          accessoryView.enabled = YES;
          [accessoryView addTarget:self action:@selector(toggleMarkLastMove:) forControlEvents:UIControlEventValueChanged];
          break;
//          case DisplayCoordinatesItem:
//            cell.textLabel.text = @"Coordinates";
//            accessoryView.on = self.playViewModel.displayCoordinates;
//            [accessoryView addTarget:self action:@selector(toggleDisplayCoordinates:) forControlEvents:UIControlEventValueChanged];
//            break;
//          case DisplayMoveNumbersItem:
//            cell.textLabel.text = @"Move numbers";
//            accessoryView.on = self.playViewModel.displayMoveNumbers;
//            [accessoryView addTarget:self action:@selector(toggleDisplayMoveNumbers:) forControlEvents:UIControlEventValueChanged];
//            break;
//          case CrossHairPointDistanceFromFingerItem:
//            cell.textLabel.text = @"Cross-hair distance";
//            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.playViewModel.crossHairPointDistanceFromFinger];
//            break;
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    case ScoringSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.on = self.scoringModel.askGtpEngineForDeadStones;
      accessoryView.enabled = YES;
      switch (indexPath.row)
      {
        case AskGtpEngineForDeadStonesItem:
        {
          cell.textLabel.text = @"Find dead stones";
          [accessoryView addTarget:self action:@selector(toggleAskGtpEngineForDeadStones:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        case MarkDeadStonesIntelligentlyItem:
        {
          cell.textLabel.text = markDeadStonesIntelligentlyText;
          cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
          cell.textLabel.numberOfLines = 0;
          [accessoryView addTarget:self action:@selector(toggleMarkDeadStonesIntelligently:) forControlEvents:UIControlEventValueChanged];
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
    case PlayersSection:
    {
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
    }
    case GtpEngineProfilesSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      if (indexPath.row < self.gtpEngineProfileModel.profileCount)
        cell.textLabel.text = [self.gtpEngineProfileModel profileNameAtIndex:indexPath.row];
      else if (indexPath.row == self.gtpEngineProfileModel.profileCount)
        cell.textLabel.text = @"Add profile ...";
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
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (ScoringSection != indexPath.section || MarkDeadStonesIntelligentlyItem != indexPath.row)
    return tableView.rowHeight;

  // Use the same strings as in tableView:cellForRowAtIndexPath:()
  NSString* labelText = markDeadStonesIntelligentlyText;

  // The label shares the cell with a UISwitch
  CGFloat labelWidth = (cellContentViewWidth
                        - 2 * cellContentDistanceFromEdgeHorizontal
                        - cellContentSwitchWidth
                        - cellContentSpacingHorizontal);
  UIFont* labelFont = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  CGSize constraintSize = CGSizeMake(labelWidth, MAXFLOAT);
  CGSize labelSize = [labelText sizeWithFont:labelFont
                           constrainedToSize:constraintSize
                               lineBreakMode:UILineBreakModeWordWrap];  // use same mode as in tableView:cellForRowAtIndexPath:()

  // Add vertical padding
  return labelSize.height + 2 * cellContentDistanceFromEdgeVertical;
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
      if (indexPath.row == self.playerModel.playerCount)
        [self newPlayer];
      else
        assert(0);
      break;
    }
    case GtpEngineProfilesSection:
    {
      if (indexPath.row < self.gtpEngineProfileModel.profileCount)
        [self editProfile:[self.gtpEngineProfileModel.profileList objectAtIndex:indexPath.row]];
      if (indexPath.row == self.gtpEngineProfileModel.profileCount)
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
/// @brief Reacts to a tap gesture on the "Find dead stones" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleAskGtpEngineForDeadStones:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.scoringModel.askGtpEngineForDeadStones = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Mark dead stones intelligently"
/// switch. Writes the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleMarkDeadStonesIntelligently:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.scoringModel.markDeadStonesIntelligently = accessoryView.on;
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
/// @brief NewPlayerDelegate protocol method.
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
/// @brief EditPlayerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangePlayer:(EditPlayerController*)editPlayerController
{
  [[self tableView] reloadData];
}

// -----------------------------------------------------------------------------
/// @brief EditPlayerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didDeletePlayer:(EditPlayerController*)editPlayerController
{
  [[self tableView] reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Displays NewGtpEngineProfileController to gather information
/// required to create a new GtpEngineProfile.
// -----------------------------------------------------------------------------
- (void) newProfile;
{
  NewGtpEngineProfileController* newProfileController = [[NewGtpEngineProfileController controllerWithDelegate:self] retain];
  [self.navigationController pushViewController:newProfileController animated:YES];
  [newProfileController release];
}

// -----------------------------------------------------------------------------
/// @brief NewGtpEngineProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didCreateNewProfile:(NewGtpEngineProfileController*)newGtpEngineProfileController
{
  // Reloading the entire table view data is the cheapest way (in terms of code
  // lines) to add a row for the new profile.
  [[self tableView] reloadData];
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
  [[self tableView] reloadData];
}

// -----------------------------------------------------------------------------
/// @brief EditGtpEngineProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didDeleteProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController
{
  [[self tableView] reloadData];
}

@end
