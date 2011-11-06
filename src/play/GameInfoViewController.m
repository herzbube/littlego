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
#import "../go/GoBoard.h"
#import "../go/GoGame.h"
#import "../go/GoPlayer.h"
#import "../go/GoScore.h"
#import "../player/Player.h"
#import "../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoTableViewSection
{
  GameStateSection,
  ScoreSection,
  GameInfoSection,
  MoveStatisticsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameStateSection.
// -----------------------------------------------------------------------------
enum GameStateSectionItem
{
  GameStateItem,
  MaxGameStateSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ScoreSection.
// -----------------------------------------------------------------------------
enum ScoreSectionItem
{
  HeadingItem,
  KomiItem,
  CapturedItem,
  DeadItem,
  TerritoryItem,
  TotalScoreItem,
  ResultItem,
  MaxScoreSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates columns in the ScoreSection.
// -----------------------------------------------------------------------------
enum ScoreSectionColumn
{
  BlackPlayerColumn,
  TitleColumn,
  WhitePlayerColumn,
  MaxScoreSectionColumn
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameInfoSection.
// -----------------------------------------------------------------------------
enum GameInfoSectionItem
{
  HandicapItem,
  BoardSizeItem,
  BlackPlayerItem,
  WhitePlayerItem,
  MaxGameInfoSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the MoveStatisticsSection.
// -----------------------------------------------------------------------------
enum MoveStatisticsSectionItem
{
  NumberOfMovesItem,
  StonesPlayedByBlackItem,
  StonesPlayedByWhiteItem,
  PassMovesPlayedByBlackItem,
  PassMovesPlayedByWhiteItem,
  MaxMoveStatisticsSectionItem
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
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name TableViewGridCellDelegate protocol
//@{
- (NSInteger) numberOfColumnsInGridCell:(TableViewGridCell*)gridCell;
- (enum GridCellColumnStyle) gridCell:(TableViewGridCell*)gridCell styleInColumn:(NSInteger)column;
- (NSString*) gridCell:(TableViewGridCell*)gridCell textForColumn:(NSInteger)column;
//@}
/// @name Action methods
//@{
- (void) done:(id)sender;
//@}
/// @name Private helpers
//@{
//@}
/// @name Privately declared properties
//@{
@property(retain) GoScore* score;
//@}
@end


@implementation GameInfoViewController

@synthesize delegate;
@synthesize score;


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
  self.score = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.score = [GoScore scoreFromGame:[GoGame sharedGame]];
  [self.score calculate];
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
    case GameStateSection:
      return MaxGameStateSectionItem;
    case ScoreSection:
      return MaxScoreSectionItem;
    case GameInfoSection:
      return MaxGameInfoSectionItem;
    case MoveStatisticsSection:
      return MaxMoveStatisticsSectionItem;
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
    case GameStateSection:
      return @"Game state";
    case ScoreSection:
      return @"Scoring";
    case GameInfoSection:
      return @"Game information";
    case MoveStatisticsSection:
      return @"Move statistics";
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
  GoGame* game = [GoGame sharedGame];
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case GameStateSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      switch (game.state)
      {
        case GameHasNotYetStarted:
        {
          cell.textLabel.text = @"Game has not yet started";
          break;
        }
        case GameHasStarted:
        {
          cell.textLabel.text = @"Game is in progress";
          break;
        }
        case GameIsPaused:
        {
          cell.textLabel.text = @"Game is paused";
          break;
        }
        case GameHasEnded:
        {
          cell.textLabel.text = @"Game has ended";
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
    case ScoreSection:
    {
      switch (indexPath.row)
      {
        case ResultItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
          // TODO include whether a player has resigned
          cell.textLabel.text = [self.score resultString];
          cell.textLabel.textAlignment = UITextAlignmentCenter;
          break;
        }
        default:
        {
          cell = [TableViewCellFactory cellWithType:GridCellType tableView:tableView];
          TableViewGridCell* gridCell = (TableViewGridCell*)cell;
          // Remember which row this is so that the delegate methods know what to do
          gridCell.tag = indexPath.row;
          gridCell.delegate = self;
          // Triggers delegate methods
          [gridCell setupCellContent];
          break;
        }
      }
      break;
    }
    case GameInfoSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      switch (indexPath.row)
      {
        case HandicapItem:
        {
          cell.textLabel.text = @"Handicap";
          int handicapValue = game.handicapPoints.count;
          if (0 == handicapValue)
            cell.detailTextLabel.text = @"No handicap";
          else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", handicapValue];
          break;
        }
        case BoardSizeItem:
        {
          cell.textLabel.text = @"Board size";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", game.board.dimensions];
          break;
        }
        case BlackPlayerItem:
        {
          cell.textLabel.text = @"Black player";
          cell.detailTextLabel.text = game.playerBlack.player.name;
          break;
        }
        case WhitePlayerItem:
        {
          cell.textLabel.text = @"White player";
          cell.detailTextLabel.text = game.playerWhite.player.name;
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
    case MoveStatisticsSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      switch (indexPath.row)
      {
        case NumberOfMovesItem:
        {
          cell.textLabel.text = @"Total number of moves";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.score.numberOfMoves];
          break;
        }
        case StonesPlayedByBlackItem:
        {
          cell.textLabel.text = @"Stones played by black";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.score.stonesPlayedByBlack];
          break;
        }
        case StonesPlayedByWhiteItem:
        {
          cell.textLabel.text = @"Stones played by white";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.score.stonesPlayedByWhite];
          break;
        }
        case PassMovesPlayedByBlackItem:
        {
          cell.textLabel.text = @"Pass moves played by black";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.score.passesPlayedByBlack];
          break;
        }
        case PassMovesPlayedByWhiteItem:
        {
          cell.textLabel.text = @"Pass moves played by white";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.score.passesPlayedByWhite];
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
      assert(0);
      break;
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief TableViewGridCellDelegate protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfColumnsInGridCell:(TableViewGridCell*)gridCell
{
  return MaxScoreSectionColumn;
}

// -----------------------------------------------------------------------------
/// @brief TableViewGridCellDelegate protocol method.
// -----------------------------------------------------------------------------
- (enum GridCellColumnStyle) gridCell:(TableViewGridCell*)gridCell styleInColumn:(NSInteger)column
{
  if (HeadingItem == gridCell.tag)
    return TitleGridCellColumnStyle;
  else
  {
    if (TitleColumn == column)
      return TitleGridCellColumnStyle;  // title is in the middle column
    else
      return ValueGridCellColumnStyle;
  }
}

// -----------------------------------------------------------------------------
/// @brief TableViewGridCellDelegate protocol method.
// -----------------------------------------------------------------------------
- (NSString*) gridCell:(TableViewGridCell*)gridCell textForColumn:(NSInteger)column
{
  switch (gridCell.tag)
  {
    case HeadingItem:
    {
      switch (column)
      {
        case BlackPlayerColumn:
          return @"Black";
        case WhitePlayerColumn:
          return @"White";
        default:
          return @"";
      }
      break;
    }
    case KomiItem:
    {
      switch (column)
      {
        case BlackPlayerColumn:
          return @"-";
        case TitleColumn:
          return @"Komi";
        case WhitePlayerColumn:
          return [NSString stringWithKomi:self.score.komi];
        default:
          assert(0);
          break;
      }
      break;
    }
    case CapturedItem:
    {
      switch (column)
      {
        case BlackPlayerColumn:
          return [NSString stringWithFormat:@"%d", self.score.capturedByBlack];
        case TitleColumn:
          return @"Captured";
        case WhitePlayerColumn:
          return [NSString stringWithFormat:@"%d", self.score.capturedByWhite];
        default:
          assert(0);
          break;
      }
      break;
    }
    case DeadItem:
    {
      switch (column)
      {
        case BlackPlayerColumn:
          return [NSString stringWithFormat:@"%d", self.score.deadWhite];
        case TitleColumn:
          return @"Territory";
        case WhitePlayerColumn:
          return [NSString stringWithFormat:@"%d", self.score.deadBlack];
        default:
          assert(0);
          break;
      }
      break;
    }
    case TerritoryItem:
    {
      switch (column)
      {
        case BlackPlayerColumn:
          return [NSString stringWithFormat:@"%d", self.score.territoryBlack];
        case TitleColumn:
          return @"Territory";
        case WhitePlayerColumn:
          return [NSString stringWithFormat:@"%d", self.score.territoryWhite];
        default:
          assert(0);
          break;
      }
      break;
    }
    case TotalScoreItem:
    {
      switch (column)
      {
        case BlackPlayerColumn:
          return [NSString stringWithFormat:@"%d", self.score.totalScoreBlack];
        case TitleColumn:
          return @"Score";
        case WhitePlayerColumn:
          return [NSString stringWithFractionValue:self.score.totalScoreWhite];
        default:
          assert(0);
          break;
      }
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
  return @"";
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished selecting a board size.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  [self.delegate gameInfoViewControllerDidFinish:self];
}


@end
