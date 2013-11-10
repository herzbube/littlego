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
#import "GameInfoViewController.h"
#import "../model/PlayViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameRules.h"
#import "../../go/GoMove.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../player/GtpEngineProfileModel.h"
#import "../../player/GtpEngineProfile.h"
#import "../../player/Player.h"
#import "../../utility/NSStringAdditions.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewSegmentedCell.h"
#import "../../ui/UiUtilities.h"
#import "../../ui/UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoTableViewSection
{
  ScoreSection = 0,
  MaxSectionScoreInfoType,
  GameStateSection = 0,
  GameInfoSection,
  MoveStatisticsSection,
  MaxSectionGameInfoType,
  BoardPositionSection = 0,
  MaxSectionBoardInfoType
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ScoreSection.
// -----------------------------------------------------------------------------
enum ScoreSectionItem
{
  HeadingItem,
  KomiScoreItem,
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
/// @brief Enumerates items in the GameInfoSection.
// -----------------------------------------------------------------------------
enum GameInfoSectionItem
{
  HandicapItem,
  BoardSizeItem,
  KomiItem,
  KoRuleItem,
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
/// @brief Enumerates items in the BoardPositionSection.
// -----------------------------------------------------------------------------
enum BoardPositionSectionItem
{
  CurrentBoardPositionItem,
  CurrentBoardPositionMoveItem,
  MovesAfterCurrentBoardPositionItem,
  MaxBoardPositionSectionItem
};



// -----------------------------------------------------------------------------
/// @brief Class extension with private properties and properties for
/// GameInfoViewController.
// -----------------------------------------------------------------------------
@interface GameInfoViewController()
@property(nonatomic, assign) UINavigationBar* navigationBar;
@property(nonatomic, assign) UITableView* tableView;
@property(nonatomic, assign) PlayViewModel* playViewModel;
/// @brief Is required so that KVO notification responders are not removed
/// twice (e.g. the first time when #playersAndProfilesWillReset is received,
/// the second time when GameInfoViewController is deallocated).
@property(nonatomic, assign) bool kvoNotificationRespondersAreInstalled;
@end


@implementation GameInfoViewController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor.
// -----------------------------------------------------------------------------
+ (GameInfoViewController*) controllerWithDelegate:(id<GameInfoViewControllerDelegate>)delegate
{
  GameInfoViewController* controller = [[GameInfoViewController alloc] initWithNibName:nil bundle:nil];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
    controller.kvoNotificationRespondersAreInstalled = false;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.delegate = nil;
  self.playViewModel = nil;
  self.navigationBar = nil;
  self.tableView = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(playersAndProfilesWillReset:) name:playersAndProfilesWillReset object:nil];
  [self setupKVONotificationResponders];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupKVONotificationResponders
{
  if (self.kvoNotificationRespondersAreInstalled)
    return;
  self.kvoNotificationRespondersAreInstalled = true;
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  [model addObserver:self forKeyPath:@"activeProfile" options:NSKeyValueObservingOptionOld context:NULL];
  [model.activeProfile addObserver:self forKeyPath:@"name" options:0 context:NULL];
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
  if (! self.kvoNotificationRespondersAreInstalled)
    return;
  self.kvoNotificationRespondersAreInstalled = false;
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  [model removeObserver:self forKeyPath:@"activeProfile"];
  [model.activeProfile removeObserver:self forKeyPath:@"name"];
  GoGame* game = [GoGame sharedGame];
  [game.playerBlack.player removeObserver:self forKeyPath:@"name"];
  [game.playerWhite.player removeObserver:self forKeyPath:@"name"];
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [self setupMainView];
  [self setupNavigationBar];
  [self setupTableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupMainView
{
  CGRect mainViewFrame = [self mainViewFrame];
  self.view = [[[UIView alloc] initWithFrame:mainViewFrame] autorelease];
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
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
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupNavigationBar
{
  CGRect navigationBarFrame = [self navigationBarFrame];
  self.navigationBar = [[[UINavigationBar alloc] initWithFrame:navigationBarFrame] autorelease];
  [self.view addSubview:self.navigationBar];
  self.navigationBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
  self.navigationBar.delegate = self;

  UINavigationItem* backItem = [[[UINavigationItem alloc] initWithTitle:@"Back"] autorelease];
  [self.navigationBar pushNavigationItem:backItem animated:NO];

  UISegmentedControl* segmentedControl = [[[UISegmentedControl alloc] initWithItems:@[@"Score", @"Game", @"Board"]] autorelease];
  segmentedControl.selectedSegmentIndex = self.playViewModel.infoTypeLastSelected;
  [segmentedControl addTarget:self action:@selector(infoTypeChanged:) forControlEvents:UIControlEventValueChanged];
  segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  self.navigationItem.titleView = segmentedControl;
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (CGRect) navigationBarFrame
{
  CGSize superViewSize = self.view.bounds.size;
  int navigationBarViewX = 0;
  int navigationBarViewY = 0;
  int navigationBarViewWidth = superViewSize.width;
  int navigationBarViewHeight = [UiElementMetrics navigationBarHeight];
  return CGRectMake(navigationBarViewX, navigationBarViewY, navigationBarViewWidth, navigationBarViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupTableView
{
  CGRect tableViewFrame = [self tableViewFrame];
  self.tableView = [[[UITableView alloc] initWithFrame:tableViewFrame
                                                 style:UITableViewStyleGrouped] autorelease];
  [self.view addSubview:self.tableView];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
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
  int tableViewY = CGRectGetMaxY(self.navigationBar.frame);
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
  [self setupNotificationResponders];
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
  self.navigationBar = nil;
  self.tableView = nil;

  // Undo all of the stuff that is happening in viewDidLoad
  [self removeNotificationResponders];
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
  switch (self.playViewModel.infoTypeLastSelected)
  {
    case ScoreInfoType:
      return MaxSectionScoreInfoType;
    case GameInfoType:
      return MaxSectionGameInfoType;
    case BoardInfoType:
      return MaxSectionBoardInfoType;
    default:
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (self.playViewModel.infoTypeLastSelected)
  {
    case ScoreInfoType:
    {
      return MaxScoreSectionItem;
    }
    case GameInfoType:
    {
      switch (section)
      {
        case GameStateSection:
          if (GoGameStateGameHasEnded != [GoGame sharedGame].state)
            return MaxGameStateSectionItem;
          else
            return MaxGameStateSectionItem - 1;  // don't need to display whose turn it is
        case GameInfoSection:
          return MaxGameInfoSectionItem;
        case MoveStatisticsSection:
          return MaxMoveStatisticsSectionItem;
        default:
          break;
      }
      break;
    }
    case BoardInfoType:
    {
      switch (section)
      {
        case BoardPositionSection:
          return MaxBoardPositionSectionItem;
        default:
          break;
      }
      break;
    }
    default:
    {
      break;
    }
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (self.playViewModel.infoTypeLastSelected)
  {
    case GameInfoType:
    {
      switch (section)
      {
        case GameStateSection:
          return @"Game state";
        case GameInfoSection:
          return @"Game information";
        case MoveStatisticsSection:
          return @"Move statistics";
        default:
          break;
      }
      break;
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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (self.playViewModel.infoTypeLastSelected)
  {
    case ScoreInfoType:
    {
      NSString* titlePartOne = nil;
      if (! [GoGame sharedGame].boardPosition.isLastPosition)
        titlePartOne = @"This score reflects the board position you are currently viewing, NOT the final score. Navigate to the last move of the game to see the final score.";
      NSString* titlePartTwo = nil;
      if (! [GoGame sharedGame].score.territoryScoringEnabled)
        titlePartTwo = @"Dead stones and territory scores are not available because you are not in scoring mode.";
      if (titlePartOne && titlePartTwo)
        return [NSString stringWithFormat:@"%@\n\n%@", titlePartOne, titlePartTwo];
      else if (titlePartOne)
        return titlePartOne;
      else
        return titlePartTwo;
    }
    case BoardInfoType:
    {
      GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
      if (boardPosition.isFirstPosition)
        return @"You are viewing the board position at the beginning of the game, i.e. before the first move was played.";
      else if (boardPosition.isLastPosition)
        return @"You are viewing the board position after the most recent move of the game has been played.";
      else
        return @"You are viewing a board position in the middle of the game.";
    }
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
  switch (self.playViewModel.infoTypeLastSelected)
  {
    case ScoreInfoType:
      return [self tableView:tableView scoreInfoTypeCellForRowAtIndexPath:indexPath];
    case GameInfoType:
      return [self tableView:tableView gameInfoTypeCellForRowAtIndexPath:indexPath];
    case BoardInfoType:
      return [self tableView:tableView boardInfoTypeCellForRowAtIndexPath:indexPath];
    default:
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView scoreInfoTypeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell;
  switch (indexPath.row)
  {
    case ResultItem:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      // TODO include whether a player has resigned
      cell.textLabel.text = [[GoGame sharedGame].score resultString];
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
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView gameInfoTypeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;
  bool isCellSelectable = false;
  GoGame* game = [GoGame sharedGame];
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
            case GoGameStateGameHasStarted:
            {
              if (! game.firstMove)
                cell.detailTextLabel.text = @"Game has not yet started";
              else
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
              DDLogError(@"%@: Unexpected game state %d", self, game.state);
              assert(0);
              break;
            }
          }
          break;
        }
        case LastMoveItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
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
                NSString* colorOfCurrentPlayer;
                if (game.currentPlayer.isBlack)
                  colorOfCurrentPlayer = @"Black";
                else
                  colorOfCurrentPlayer = @"White";
                cell.detailTextLabel.text = [colorOfCurrentPlayer stringByAppendingString:@" resigned"];
                break;
              }
              default:
              {
                cell.detailTextLabel.text = @"Unknown";
                DDLogError(@"%@: Unexpected reasonForGameHasEnded %d", self, game.reasonForGameHasEnded);
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
              case GoGameStateGameHasStarted:
              case GoGameStateGameIsPaused:
              {
                GoMove* lastMove = game.lastMove;
                if (! lastMove)
                  cell.detailTextLabel.text = @"None";
                else
                  cell.detailTextLabel.text = [self descriptionOfMove:lastMove];
                break;
              }
              default:
              {
                cell.detailTextLabel.text = @"n/a";
                DDLogError(@"%@: Unexpected game state %d", self, game.state);
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
    case GameInfoSection:
    {
      switch (indexPath.row)
      {
        case BlackPlayerItem:
        case WhitePlayerItem:
        case ActiveProfileItem:
          isCellSelectable = true;
          cell = [TableViewCellFactory cellWithType:Value1CellType
                                          tableView:tableView
                             reusableCellIdentifier:@"Value1CellWithDisclosureIndicator"];
          break;
        default:
          cell = [TableViewCellFactory cellWithType:Value1CellType
                                          tableView:tableView];
          break;
      }
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
        case KomiItem:
        {
          cell.textLabel.text = @"Komi";
          cell.detailTextLabel.text = [NSString stringWithKomi:game.komi numericZeroValue:false];
          break;
        }
        case KoRuleItem:
        {
          cell.textLabel.text = @"Ko rule";
          cell.detailTextLabel.text = [NSString stringWithKoRule:game.rules.koRule];
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
          GtpEngineProfile* profile = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel.activeProfile;
          assert(profile);
          if (profile)
            cell.detailTextLabel.text = profile.name;
          else
          {
            DDLogError(@"%@: Active GtpEngineProfile is nil", self);
            cell.detailTextLabel.text = @"n/a";
          }
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
      GoScore* score = game.score;
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      switch (indexPath.row)
      {
        case NumberOfMovesItem:
        {
          cell.textLabel.text = @"Total number of moves";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", score.numberOfMoves];
          break;
        }
        case StonesPlayedByBlackItem:
        {
          cell.textLabel.text = @"Stones played by black";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", score.stonesPlayedByBlack];
          break;
        }
        case StonesPlayedByWhiteItem:
        {
          cell.textLabel.text = @"Stones played by white";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", score.stonesPlayedByWhite];
          break;
        }
        case PassMovesPlayedByBlackItem:
        {
          cell.textLabel.text = @"Pass moves played by black";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", score.passesPlayedByBlack];
          break;
        }
        case PassMovesPlayedByWhiteItem:
        {
          cell.textLabel.text = @"Pass moves played by white";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", score.passesPlayedByWhite];
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
  if (isCellSelectable)
  {
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  else
  {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView boardInfoTypeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  switch (indexPath.row)
  {
    case CurrentBoardPositionItem:
    {
      cell.textLabel.text = @"You are viewing";
      if (boardPosition.isFirstPosition)
        cell.detailTextLabel.text = @"Start of game";
      else
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Move %d", boardPosition.currentBoardPosition];
      break;
    }
    case CurrentBoardPositionMoveItem:
    {
      cell.textLabel.text = @"Move info";
      if (boardPosition.isFirstPosition)
        cell.detailTextLabel.text = @"n/a";
      else
        cell.detailTextLabel.text = [self descriptionOfMove:boardPosition.currentMove];
      break;
    }
    case MovesAfterCurrentBoardPositionItem:
    {
      int indexOfLastBoardPosition = boardPosition.numberOfBoardPositions - 1;
      int numberOfMovesAfterCurrentBoardPosition =  indexOfLastBoardPosition - boardPosition.currentBoardPosition;
      cell.textLabel.text = @"Moves after current position";
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", numberOfMovesAfterCurrentBoardPosition];
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  if (GameInfoType != self.playViewModel.infoTypeLastSelected)
    return;
  if (GameInfoSection != indexPath.section)
    return;

  GoGame* game = [GoGame sharedGame];
  switch (indexPath.row)
  {
    case BlackPlayerItem:
    case WhitePlayerItem:
    {
      Player* player;
      if (BlackPlayerItem == indexPath.row)
        player = game.playerBlack.player;
      else
        player = game.playerWhite.player;
      EditPlayerController* editPlayerController = [EditPlayerController controllerForPlayer:player withDelegate:self];
      UINavigationController* navigationController = [[[UINavigationController alloc]
                                                       initWithRootViewController:editPlayerController] autorelease];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      [self presentViewController:navigationController animated:YES completion:nil];
      break;
    }
    case ActiveProfileItem:
    {
      GtpEngineProfile* profile = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel.activeProfile;
      if (profile)
      {
        EditGtpEngineProfileController* editProfileController = [EditGtpEngineProfileController controllerForProfile:profile withDelegate:self];
        UINavigationController* navigationController = [[[UINavigationController alloc]
                                                         initWithRootViewController:editProfileController] autorelease];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:navigationController animated:YES completion:nil];
      }
      break;
    }
    default:
    {
      break;
    }
  }
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
  GoScore* score = [GoGame sharedGame].score;
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
    case KomiScoreItem:
    {
      switch (column)
      {
        case BlackPlayerColumn:
          return @"-";
        case TitleColumn:
          return @"Komi";
        case WhitePlayerColumn:
          return [NSString stringWithKomi:score.komi numericZeroValue:false];
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
          return [NSString stringWithFormat:@"%d", score.capturedByBlack];
        case TitleColumn:
          return @"Captured";
        case WhitePlayerColumn:
          return [NSString stringWithFormat:@"%d", score.capturedByWhite];
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
          if (score.territoryScoringEnabled)
            return [NSString stringWithFormat:@"%d", score.deadWhite];
          else
            return @"n/a";
        case TitleColumn:
          return @"Dead";
        case WhitePlayerColumn:
          if (score.territoryScoringEnabled)
            return [NSString stringWithFormat:@"%d", score.deadBlack];
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
          if (score.territoryScoringEnabled)
            return [NSString stringWithFormat:@"%d", score.territoryBlack];
          else
            return @"n/a";
        case TitleColumn:
          return @"Territory";
        case WhitePlayerColumn:
          if (score.territoryScoringEnabled)
            return [NSString stringWithFormat:@"%d", score.territoryWhite];
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
          return [NSString stringWithFormat:@"%d", score.totalScoreBlack];
        case TitleColumn:
          return @"Score";
        case WhitePlayerColumn:
          return [NSString stringWithFractionValue:score.totalScoreWhite];
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

// -----------------------------------------------------------------------------
/// @brief Responds to the #playersAndProfilesWillReset notification.
// -----------------------------------------------------------------------------
- (void) playersAndProfilesWillReset:(NSNotification*)notification
{
  // We must immediately stop using KVO on players and profiles objects that
  // are about to be deallocated. After the reset is complete, we don't need to
  // re-attach to new players and profiles objects because a new game is started
  // as part of the reset and we will be dismissed.
  [self removeKVONotificationResponders];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  GtpEngineProfileModel* gtpEngineProfileModel = applicationDelegate.gtpEngineProfileModel;
  if (object == gtpEngineProfileModel)
  {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ActiveProfileItem inSection:GameInfoSection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];

    GtpEngineProfile* oldProfile = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldProfile)
      [oldProfile removeObserver:self forKeyPath:@"name"];
    GtpEngineProfile* newProfile = gtpEngineProfileModel.activeProfile;
    if (newProfile)
      [newProfile addObserver:self forKeyPath:@"name" options:0 context:NULL];
  }
  else if ([object isKindOfClass:[GtpEngineProfile class]])
  {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ActiveProfileItem inSection:GameInfoSection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }
  else if ([object isKindOfClass:[Player class]])
  {
    int row;
    if (object == [GoGame sharedGame].playerBlack.player)
      row = BlackPlayerItem;
    else
      row = WhitePlayerItem;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:GameInfoSection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (NSString*) descriptionOfMove:(GoMove*)move
{
  NSString* playerColorString;
  GoPlayer* player = move.player;
  if (player.isBlack)
    playerColorString = @"Black";
  else
    playerColorString = @"White";
  switch (move.type)
  {
    case GoMoveTypePlay:
    {
      return [NSString stringWithFormat:@"%@ played at %@",
              playerColorString,
              move.point.vertex.string];
    }
    case GoMoveTypePass:
    {
      return [playerColorString stringByAppendingString:@" passed"];
    }
    default:
    {
      return @"n/a";
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Info Type" segmented control. Updates
/// the main table view to display information for the selected type.
// -----------------------------------------------------------------------------
- (void) infoTypeChanged:(id)sender
{
  UISegmentedControl* segmentedControl = (UISegmentedControl*)sender;
  self.playViewModel.infoTypeLastSelected = segmentedControl.selectedSegmentIndex;
  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief EditPlayerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didEditPlayer:(EditPlayerController*)editPlayerController;
{
  GoGame* game = [GoGame sharedGame];
  NSMutableArray* indexPaths = [NSMutableArray array];
  if (! editPlayerController.player.isHuman)
  {
    // In case the user selected a different profile or changed the profile
    // name
    [indexPaths addObject:[NSIndexPath indexPathForRow:ActiveProfileItem inSection:GameInfoSection]];
  }
  if (editPlayerController.player == game.playerBlack.player)
    [indexPaths addObject:[NSIndexPath indexPathForRow:BlackPlayerItem inSection:GameInfoSection]];
  else
    [indexPaths addObject:[NSIndexPath indexPathForRow:WhitePlayerItem inSection:GameInfoSection]];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
  [self dismissViewControllerAnimated:YES completion:nil];
}

// -----------------------------------------------------------------------------
/// @brief EditGtpEngineProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didEditProfile:(EditGtpEngineProfileController*)editGtpEngineProfileController
{
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ActiveProfileItem inSection:GameInfoSection];
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationNone];
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
