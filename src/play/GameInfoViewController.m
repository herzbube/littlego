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
#import "GameInfoViewController.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoTableViewSection
{
  HandicapSection,
  ScoreSection,
  GameResultSection,
  GameInfoSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the HandicapSection.
// -----------------------------------------------------------------------------
enum HandicapSectionItem
{
  HandicapItem,
  MaxHandicapSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ScoreSection.
// -----------------------------------------------------------------------------
enum ScoreSectionItem
{
  HeadingItem,
  KomiItem,
  CapturedItem,
  TerritoryItem,
  TotalScoreItem,
  MaxScoreSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameResultSection.
// -----------------------------------------------------------------------------
enum GameResultSectionItem
{
  GameResultItem,
  MaxGameResultSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameInfoSection.
// -----------------------------------------------------------------------------
enum GameInfoSectionItem
{
  NumberOfMovesItem,
  BoardSizeItem,
  BlackPlayerItem,
  WhitePlayerItem,
  MaxGameInfoSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GameInfoViewController.
// -----------------------------------------------------------------------------
@interface GameInfoViewController()
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
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
- (void) done:(id)sender;
//@}
/// @name Helpers
//@{
//@}
@end


@implementation GameInfoViewController

@synthesize delegate;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GameInfoViewController instance
/// that loads its view from a .nib file.
// -----------------------------------------------------------------------------
+ (GameInfoViewController*) controllerWithDelegate:(id<GameInfoViewControllerDelegate>)delegate
{
  GameInfoViewController* controller = [[GameInfoViewController alloc] initWithNibName:@"GameInfoView" bundle:nil];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
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
    case HandicapSection:
      return MaxHandicapSectionItem;
    case ScoreSection:
      return MaxScoreSectionItem;
    case GameResultSection:
      return MaxGameResultSectionItem;
    case GameInfoSection:
      return MaxGameInfoSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;
  cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  cell.textLabel.text = @"bla";
  return cell;
/*
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
*/
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished selecting a board size.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  [self.delegate gameInfoViewControllerDidFinish:self];
}


@end
