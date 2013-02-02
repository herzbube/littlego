// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../go/GoPoint.h"
#import "../go/GoScore.h"
#import "../go/GoVertex.h"
#import "../gtp/GtpUtilities.h"
#import "../player/GtpEngineProfile.h"
#import "../player/Player.h"
#import "../utility/NSStringAdditions.h"
#import "../ui/UiUtilities.h"
#import "../ui/UiElementMetrics.h"


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
  LastMoveItem,
  NextMoveItem,
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
  ActiveProfileItem,
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
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name UINavigationBarDelegate protocol
//@{
- (BOOL) navigationBar:(UINavigationBar*)navigationBar shouldPopItem:(UINavigationItem*)item;
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
/// @name Notification responders
//@{
- (void) goGameDidCreate:(NSNotification*)notification;
//@}
/// @name Private helpers
//@{
- (CGRect) mainViewFrame;
- (CGRect) navigationBarViewFrame;
- (CGRect) tableViewFrame;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) GoScore* score;
//@}
@end


@implementation GameInfoViewController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GameInfoViewController instance
/// that loads its view from a .nib file.
// -----------------------------------------------------------------------------
+ (GameInfoViewController*) controllerWithDelegate:(id<GameInfoViewControllerDelegate>)delegate score:(GoScore*)score
{
  GameInfoViewController* controller = [[GameInfoViewController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.score = score;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.delegate = nil;
  self.score = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  CGRect mainViewFrame = [self mainViewFrame];
  self.view = [[[UIView alloc] initWithFrame:mainViewFrame] autorelease];
  CGRect navigationBarViewFrame = [self navigationBarViewFrame];
  UINavigationBar* navigationBar = [[[UINavigationBar alloc] initWithFrame:navigationBarViewFrame] autorelease];
  [self.view addSubview:navigationBar];
  CGRect tableViewFrame = [self tableViewFrame];
  UITableView* tableView = [[[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped] autorelease];
  [self.view addSubview:tableView];

  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  navigationBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
  tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

  tableView.delegate = self;
  tableView.dataSource = self;

  UINavigationItem* backItem = [[[UINavigationItem alloc] initWithTitle:@"Back"] autorelease];
  [navigationBar pushNavigationItem:backItem animated:NO];
  [navigationBar pushNavigationItem:self.navigationItem animated:NO];
  navigationBar.delegate = self;
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of this controller's main view, taking into
/// account the current interface orientation. Assumes that super views have
/// the correct bounds.
// -----------------------------------------------------------------------------
- (CGRect) mainViewFrame
{
  int mainViewX = 0;
  int mainViewY = 0;
  int mainViewWidth = [UiElementMetrics screenWidth];
  int mainViewHeight = ([UiElementMetrics screenHeight]
                        - [UiElementMetrics tabBarHeight]
                        - [UiElementMetrics statusBarHeight]);
  return CGRectMake(mainViewX, mainViewY, mainViewWidth, mainViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of the toolbar view, taking into account the
/// current interface orientation. Assumes that super views have the correct
/// bounds.
// -----------------------------------------------------------------------------
- (CGRect) navigationBarViewFrame
{
  CGSize superViewSize = self.view.bounds.size;
  int navigationBarViewX = 0;
  int navigationBarViewY = 0;
  int navigationBarViewWidth = superViewSize.width;
  int navigationBarViewHeight = [UiElementMetrics navigationBarHeight];
  return CGRectMake(navigationBarViewX, navigationBarViewY, navigationBarViewWidth, navigationBarViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of the toolbar view, taking into account the
/// current interface orientation. Assumes that super views have the correct
/// bounds.
// -----------------------------------------------------------------------------
- (CGRect) tableViewFrame
{
  CGSize superViewSize = self.view.bounds.size;
  int tableViewX = 0;
  int tableViewY = [UiElementMetrics navigationBarHeight];
  int tableViewWidth = superViewSize.width;
  int tableViewHeight = superViewSize.height - tableViewY;
  return CGRectMake(tableViewX, tableViewY, tableViewWidth, tableViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Game Info";
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

  // Super's viewDidUnload does not release self.view/self.tableView for us,
  // possibly because we override loadView and create the view ourselves
  self.view = nil;

  // Undo all of the stuff that is happening in viewDidLoad
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief UINavigationBarDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) navigationBar:(UINavigationBar*)navigationBar shouldPopItem:(UINavigationItem*)item
{
  // If we were overriding navigationBar:didPopItem:(), the item would already
  // have been popped with an animation, and our own dismissal would be
  // animated separately. This looks ugly. The solution is to override
  // navigationBar:shouldPopItem:() and trigger our own dismissal now so that
  // the two animations take place together.
  [self.delegate gameInfoViewControllerDidFinish:self];
  return YES;
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
      if (GoGameStateGameHasEnded != [GoGame sharedGame].state)
        return MaxGameStateSectionItem;
      else
        return MaxGameStateSectionItem - 1;  // don't need to display whose turn it is
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
      switch (indexPath.row)
      {
        case GameStateItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"State";
          switch (game.state)
          {
            case GoGameStateGameHasNotYetStarted:
            {
              cell.detailTextLabel.text = @"Game has not yet started";
              break;
            }
            case GoGameStateGameHasStarted:
            {
              cell.detailTextLabel.text = @"Game is in progress";
              break;
            }
            case GoGameStateGameIsPaused:
            {
              cell.detailTextLabel.text = @"Game is paused";
              break;
            }
            case GoGameStateGameHasEnded:
            {
              cell.detailTextLabel.text = @"Game has ended";
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
        case LastMoveItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          NSString* colorOfCurrentPlayer;
          NSString* colorOfOtherPlayer;
          if (game.currentPlayer.isBlack)
          {
            colorOfCurrentPlayer = @"Black";
            colorOfOtherPlayer = @"White";
          }
          else
          {
            colorOfCurrentPlayer = @"White";
            colorOfOtherPlayer = @"Black";
          }
          if (GoGameStateGameHasEnded == game.state)
          {
            cell.textLabel.text = @"Reason";
            switch (game.reasonForGameHasEnded)
            {
              case GoGameHasEndedReasonTwoPasses:
              {
                cell.detailTextLabel.text = @"Both players passed";
                break;
              }
              case GoGameHasEndedReasonResigned:
              {
                cell.detailTextLabel.text = [colorOfCurrentPlayer stringByAppendingString:@" resigned"];
                break;
              }
              default:
              {
                cell.detailTextLabel.text = @"Unknown";
                assert(0);
                break;
              }
            }
          }
          else
          {
            cell.textLabel.text = @"Last move";
            switch (game.state)
            {
              case GoGameStateGameHasNotYetStarted:
              {
                cell.detailTextLabel.text = @"None";
                break;
              }
              case GoGameStateGameHasStarted:
              case GoGameStateGameIsPaused:
              {
                GoMove* lastMove = game.lastMove;
                if (! lastMove)
                {
                  cell.detailTextLabel.text = @"None";
                }
                else
                {
                  switch (lastMove.type)
                  {
                    case GoMoveTypePlay:
                    {
                      cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ played at %@",
                                                   colorOfOtherPlayer,
                                                   lastMove.point.vertex.string];
                      break;
                    }
                    case GoMoveTypePass:
                    {
                      cell.detailTextLabel.text = [colorOfOtherPlayer stringByAppendingString:@" passed"];
                      break;
                    }
                    default:
                    {
                      cell.detailTextLabel.text = @"n/a";
                      assert(0);
                      break;
                    }
                  }
                }
                break;
              }
              default:
              {
                cell.detailTextLabel.text = @"n/a";
                assert(0);
                break;
              }
            }
          }
          break;
        }
        case NextMoveItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Next move";
          if (game.currentPlayer.isBlack)
            cell.detailTextLabel.text = @"Black";
          else
            cell.detailTextLabel.text = @"White";
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
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", game.board.size];
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
        case ActiveProfileItem:
        {
          cell.textLabel.text = @"Active profile";
          GtpEngineProfile* profile = [GtpUtilities activeProfile];
          assert(profile);
          if (profile)
            cell.detailTextLabel.text = profile.name;
          else
            cell.detailTextLabel.text = @"n/a";
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
          return [NSString stringWithKomi:self.score.komi numericZeroValue:false];
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
          if (self.score.territoryScoresAvailable)
            return [NSString stringWithFormat:@"%d", self.score.deadWhite];
          else
            return @"n/a";
        case TitleColumn:
          return @"Dead";
        case WhitePlayerColumn:
          if (self.score.territoryScoresAvailable)
            return [NSString stringWithFormat:@"%d", self.score.deadBlack];
          else
            return @"n/a";
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
          if (self.score.territoryScoresAvailable)
            return [NSString stringWithFormat:@"%d", self.score.territoryBlack];
          else
            return @"n/a";
        case TitleColumn:
          return @"Territory";
        case WhitePlayerColumn:
          if (self.score.territoryScoresAvailable)
            return [NSString stringWithFormat:@"%d", self.score.territoryWhite];
          else
            return @"n/a";
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
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  // Dismiss the Info view when a new game is started. This typically occurs
  // when a saved game is loaded from the archive.
  [self navigationBar:nil shouldPopItem:nil];
}

@end
