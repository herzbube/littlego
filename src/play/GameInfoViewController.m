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
#import "../go/GoMove.h"
#import "../go/GoPlayer.h"
#import "../player/Player.h"
#import "../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoTableViewSection
{
  GameResultSection,
  ScoreSection,
  HandicapSection,
  GameInfoSection,
  MaxSection
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
/// @brief Enumerates items in the HandicapSection.
// -----------------------------------------------------------------------------
enum HandicapSectionItem
{
  HandicapItem,
  MaxHandicapSectionItem
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
@property double scoreBlackPlayer;
@property double scoreWhitePlayer;
//@}
@end


@implementation GameInfoViewController

@synthesize delegate;
@synthesize scoreBlackPlayer;
@synthesize scoreWhitePlayer;


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
  self.scoreBlackPlayer = -1;
  self.scoreWhitePlayer = -1;
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
    case GameResultSection:
      return MaxGameResultSectionItem;
    case ScoreSection:
      return MaxScoreSectionItem;
    case HandicapSection:
      return MaxHandicapSectionItem;
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
  GoGame* game = [GoGame sharedGame];
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case GameResultSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Game result";
      switch (game.state)
      {
        case GameHasNotYetStarted:
        {
          cell.detailTextLabel.text = @"Game has not yet started";
          break;
        }
        case GameHasStarted:
        case GameIsPaused:
        {
          cell.detailTextLabel.text = @"Game is in progress";
          break;
        }
        case GameHasEnded:
        {
          // TODO include whether a player has resigned
          if (scoreBlackPlayer > scoreWhitePlayer)
            cell.detailTextLabel.text = @"Black has won";
          else if (scoreWhitePlayer > scoreBlackPlayer)
            cell.detailTextLabel.text = @"White has won";
          else
            cell.detailTextLabel.text = @"Game is tied";
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
      cell = [TableViewCellFactory cellWithType:GridCellType tableView:tableView];
      TableViewGridCell* gridCell = (TableViewGridCell*)cell;
      // Remember which row this is so that the delegate methods know what to do
      gridCell.tag = indexPath.row;
      gridCell.delegate = self;
      // Triggers delegate methods
      [gridCell setupCellContent];
      break;
    }
    case HandicapSection:
    {
      int handicapValue = game.handicapPoints.count;
      if (0 == handicapValue)
      {
        cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
        cell.textLabel.text = @"Handicap";
        cell.detailTextLabel.text = @"No handicap";
      }
      else
      {
        cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
        cell.textLabel.text = @"Handicap";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", handicapValue];
      }
      break;
    }
    case GameInfoSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      switch (indexPath.row)
      {
        case NumberOfMovesItem:
        {
          cell.textLabel.text = @"Number of moves";
          int numberOfMoves = 0;
          GoMove* move = game.firstMove;
          while (move != nil)
          {
            ++numberOfMoves;
            move = move.next;
          }
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", numberOfMoves];
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
        {
          GoGame* game = [GoGame sharedGame];
          return [NSString stringWithKomi:game.komi];
        }
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
          return @"";
        case TitleColumn:
          return @"Captured";
        case WhitePlayerColumn:
          return @"";
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
          return @"";
        case TitleColumn:
          return @"Territory";
        case WhitePlayerColumn:
          return @"";
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
          return @"";
        case TitleColumn:
          return @"Score";
        case WhitePlayerColumn:
          return @"";
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
