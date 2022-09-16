// -----------------------------------------------------------------------------
// Copyright 2011-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "../model/BoardViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameRules.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../player/GtpEngineProfileModel.h"
#import "../../player/GtpEngineProfile.h"
#import "../../player/Player.h"
#import "../../sgf/SgfUtilities.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/TableViewVariableHeightCell.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/NSStringAdditions.h"

// Constants
NSString* disputeResolutionRuleText_GameInfoViewController = @"Dispute resolution";


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoTableViewSection
{
  ScoreSection = 0,
  MaxSectionScoreInfoType,
  GameStateSection = 0,
  GameInfoSection,
  PlayersProfileSection,
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
  HandicapCompensationItem,  // area scoring
  AliveItem,                 // area scoring
  CapturedItem = HandicapCompensationItem,  // territory scoring
  DeadItem,                                 // territory scoring
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
  ScoringSystemItem,
  LifeAndDeathSettlingRuleItem,
  DisputeResolutionRuleItem,
  FourPassesRuleItem,
  BlackSetupStonesItem,
  WhiteSetupStonesItem,
  SideToPlayFirstItem,
  MaxGameInfoSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayersProfileSection.
// -----------------------------------------------------------------------------
enum PlayersProfileSectionItem
{
  BlackPlayerItem,
  WhitePlayerItem,
  HumanVsHumanGameProfileItem,
  MaxPlayersProfileSectionItem
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
  StonesCapturedByBlackItem,
  StonesCapturedByWhiteItem,
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
@property(nonatomic, assign) UITableView* tableView;
@property(nonatomic, assign) BoardViewModel* boardViewModel;
/// @brief Is required so that KVO notification responders are not removed
/// twice (e.g. the first time when #playersAndProfilesWillReset is received,
/// the second time when GameInfoViewController is deallocated).
@property(nonatomic, assign) bool kvoNotificationRespondersAreInstalled;
@end


@implementation GameInfoViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameInfoViewController object.
///
/// @note This is the designated initializer of GameInfoViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.gameInfoViewControllerCreator = nil;
  self.tableView = nil;
  self.boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
  self.kvoNotificationRespondersAreInstalled = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.tableView = nil;
  self.boardViewModel = nil;
  [self.gameInfoViewControllerCreator gameInfoViewControllerWillDeallocate:self];
  self.gameInfoViewControllerCreator = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupNavigationBar];
  [self setupTableView];
  [self setupAutoLayoutConstraints];
  [self configureViews];
  [self setupNotificationResponders];
}

#pragma mark - Private helpers for view setup

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupNavigationBar
{
  UISegmentedControl* segmentedControl = [[[UISegmentedControl alloc] initWithItems:@[@"Score", @"Game", @"Board"]] autorelease];
  segmentedControl.selectedSegmentIndex = self.boardViewModel.infoTypeLastSelected;
  [segmentedControl addTarget:self action:@selector(infoTypeChanged:) forControlEvents:UIControlEventValueChanged];
  self.navigationItem.titleView = segmentedControl;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupTableView
{
  self.tableView = [[[UITableView alloc] initWithFrame:CGRectZero
                                                 style:UITableViewStyleGrouped] autorelease];
  [self.view addSubview:self.tableView];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.tableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  self.title = @"Game Info";
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(playersAndProfilesWillReset:) name:playersAndProfilesWillReset object:nil];
  if (GameInfoType == self.boardViewModel.infoTypeLastSelected)
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
  GoGame* game = [GoGame sharedGame];
  [game.playerBlack.player removeObserver:self forKeyPath:@"name"];
  [game.playerWhite.player removeObserver:self forKeyPath:@"name"];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  switch (self.boardViewModel.infoTypeLastSelected)
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
  switch (self.boardViewModel.infoTypeLastSelected)
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
        case PlayersProfileSection:
          if ([GoGame sharedGame].type == GoGameTypeHumanVsHuman)
            return MaxPlayersProfileSectionItem;
          else
            return MaxPlayersProfileSectionItem - 1;
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
  switch (self.boardViewModel.infoTypeLastSelected)
  {
    case GameInfoType:
    {
      switch (section)
      {
        case GameStateSection:
          return @"Game state";
        case GameInfoSection:
          return @"Game information";
        case PlayersProfileSection:
          return @"Players";
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
  switch (self.boardViewModel.infoTypeLastSelected)
  {
    case ScoreInfoType:
    {
      GoGame* game = [GoGame sharedGame];
      GoBoardPosition* boardPosition = game.boardPosition;
      int numberOfMovesAfterCurrentBoardPosition = [GoUtilities numberOfMovesAfterNode:boardPosition.currentNode];
      NSString* titlePartOne = nil;
      if (numberOfMovesAfterCurrentBoardPosition > 0)
        titlePartOne = @"This score reflects the board position you are currently viewing, NOT the final score. Navigate to the last move of the game to see the final score.";

      NSString* titlePartTwo = nil;
      if ([ApplicationDelegate sharedDelegate].uiSettingsModel.uiAreaPlayMode != UIAreaPlayModeScoring)
      {
        if (GoScoringSystemAreaScoring == game.rules.scoringSystem)
          titlePartTwo = @"Stone count";
        else
          titlePartTwo = @"Dead stone count";
        titlePartTwo = [titlePartTwo stringByAppendingString:@" and territory score are not available because you are not in scoring mode."];
      }

      if (titlePartOne && titlePartTwo)
        return [NSString stringWithFormat:@"%@\n\n%@", titlePartOne, titlePartTwo];
      else if (titlePartOne)
        return titlePartOne;
      else
        return titlePartTwo;
    }
    case GameInfoType:
    {
      if (section == GameInfoSection)
      {
        NSString* footerText;
        if ([GoGame sharedGame].setupFirstMoveColor == GoColorNone)
          footerText = @"The side to play first is currently determined by the normal game rules.";
        else
          footerText = @"The side to play first is currently set up, overriding the normal game rules.";
        return [footerText stringByAppendingString:@" The side to play first can be changed in board setup mode."];
      }
      break;
    }
    case BoardInfoType:
    {
      GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
      GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:boardPosition.currentNode];
      if (! nodeWithMostRecentMove)
        return @"You are viewing the board position at the beginning of the game, i.e. before the first move was played.";
      else if (! nodeWithMostRecentMove.goMove.next)
        return @"You are viewing the board position after the most recent move of the game has been played.";
      else
        return @"You are viewing a board position in the middle of the game.";
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
  switch (self.boardViewModel.infoTypeLastSelected)
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

#pragma mark - Private helpers for tableView:cellForRowAtIndexPath:().

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
      cell.textLabel.text = [[GoGame sharedGame].score resultString];
      cell.textLabel.textAlignment = NSTextAlignmentCenter;
      cell.textLabel.numberOfLines = 0;
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
              else if ([GoUtilities isGameInResumedPlayState:game])
                cell.detailTextLabel.text = @"Resumed play";
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
              case GoGameHasEndedReasonThreePasses:
              {
                cell.detailTextLabel.text = @"Three pass moves";
                break;
              }
              case GoGameHasEndedReasonFourPasses:
              {
                cell.detailTextLabel.text = @"Four pass moves";
                break;
              }
              default:
              {
                SGFCGameResult gameResult = [SgfUtilities gameResultForGoGameHasEndedReason:game.reasonForGameHasEnded];
                if (gameResult.IsValid)
                {
                  cell.detailTextLabel.text = [SgfUtilities stringForSgfGameResult:gameResult];;
                }
                else
                {
                  cell.detailTextLabel.text = @"Unknown";
                  DDLogError(@"%@: Unexpected reasonForGameHasEnded %d", self, game.reasonForGameHasEnded);
                  assert(0);
                }
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
          if (game.nextMovePlayer.isBlack)
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
      if (DisputeResolutionRuleItem == indexPath.row)
      {
        cell = [TableViewCellFactory cellWithType:VariableHeightCellType
                                        tableView:tableView];
      }
      else
      {
        cell = [TableViewCellFactory cellWithType:Value1CellType
                                        tableView:tableView];
      }
      switch (indexPath.row)
      {
        case HandicapItem:
        {
          cell.textLabel.text = @"Handicap";
          NSUInteger handicapValue = game.handicapPoints.count;
          if (0 == handicapValue)
            cell.detailTextLabel.text = @"No handicap";
          else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)handicapValue];
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
        case ScoringSystemItem:
        {
          cell.textLabel.text = @"Scoring system";
          cell.detailTextLabel.text = [NSString stringWithScoringSystem:game.rules.scoringSystem];
          break;
        }
        case LifeAndDeathSettlingRuleItem:
        {
          cell.textLabel.text = @"Life & death settling after";
          cell.detailTextLabel.text = [NSString stringWithLifeAndDeathSettlingRule:game.rules.lifeAndDeathSettlingRule];
          break;
        }
        case DisputeResolutionRuleItem:
        {
          TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
          variableHeightCell.descriptionLabel.text = disputeResolutionRuleText_GameInfoViewController;
          variableHeightCell.valueLabel.text = [NSString stringWithDisputeResolutionRule:game.rules.disputeResolutionRule];
          break;
        }
        case FourPassesRuleItem:
        {
          cell.textLabel.text = @"Four passes";
          cell.detailTextLabel.text = [NSString stringWithFourPassesRule:game.rules.fourPassesRule];
          break;
        }
        case BlackSetupStonesItem:
        case WhiteSetupStonesItem:
        {
          NSUInteger numberOfSetupStones;
          if (indexPath.row == BlackSetupStonesItem)
          {
            cell.textLabel.text = @"Black setup stones";
            numberOfSetupStones = game.blackSetupPoints.count;
          }
          else
          {
            cell.textLabel.text = @"White setup stones";
            numberOfSetupStones = game.whiteSetupPoints.count;
          }
          if (0 == numberOfSetupStones)
            cell.detailTextLabel.text = @"None";
          else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfSetupStones];
          break;
        }
        case SideToPlayFirstItem:
        {
          // We need an item that somehow shows the influence of the non-obvious
          // game setup property game.setupFirstMoveColor. We could simply show
          // its value here, but if the value were GoColorNone - i.e. no player
          // is explicitly set up to play first - the information would be quite
          // worthless to the user. Therefore, if game.setupFirstMoveColor is
          // indeed GoColorNone we show the player to play first according to
          // the normal game rules.
          cell.textLabel.text = @"Side to play first";
          enum GoColor colorToPlayFirst = [GoUtilities playerAfter:nil
                                                            inGame:game].color;
          cell.detailTextLabel.text = [NSString stringWithGoColor:colorToPlayFirst];
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
    case PlayersProfileSection:
    {
      isCellSelectable = true;
      switch (indexPath.row)
      {
        case BlackPlayerItem:
        case WhitePlayerItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType
                                          tableView:tableView
                             reusableCellIdentifier:@"Value1CellWithDisclosureIndicator"];
          if (indexPath.row == BlackPlayerItem)
          {
            cell.textLabel.text = @"Black player";
            cell.detailTextLabel.text = game.playerBlack.player.name;
          }
          else
          {
            cell.textLabel.text = @"White player";
            cell.detailTextLabel.text = game.playerWhite.player.name;
            break;
          }
          break;
        }
        case HumanVsHumanGameProfileItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType
                                          tableView:tableView
                             reusableCellIdentifier:@"ComputerSettingsCell"];
          cell.textLabel.text = @"Computer settings";
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
        case StonesCapturedByBlackItem:
        {
          cell.textLabel.text = @"Stones captured by black";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", score.capturedByBlack];
          break;
        }
        case StonesCapturedByWhiteItem:
        {
          cell.textLabel.text = @"Stones captured by white";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", score.capturedByWhite];
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
      break;
    }
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
      GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:boardPosition.currentNode];
      if (nodeWithMostRecentMove)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Move %d", nodeWithMostRecentMove.goMove.moveNumber];
      else
        cell.detailTextLabel.text = @"Start of game";
      break;
    }
    case CurrentBoardPositionMoveItem:
    {
      cell.textLabel.text = @"Move info";
      GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:boardPosition.currentNode];
      if (nodeWithMostRecentMove)
        cell.detailTextLabel.text = [self descriptionOfMove:nodeWithMostRecentMove.goMove];
      else
        cell.detailTextLabel.text = @"n/a";
      break;
    }
    case MovesAfterCurrentBoardPositionItem:
    {
      int numberOfMovesAfterCurrentBoardPosition = [GoUtilities numberOfMovesAfterNode:boardPosition.currentNode];
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

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  if (GameInfoType != self.boardViewModel.infoTypeLastSelected)
    return;
  if (PlayersProfileSection != indexPath.section)
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
      EditPlayerProfileController* editPlayerProfileController = [EditPlayerProfileController controllerForPlayer:player withDelegate:self];
      [self presentNavigationControllerWithRootViewController:editPlayerProfileController];
      break;
    }
    case HumanVsHumanGameProfileItem:
    {
      GtpEngineProfile* profile = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel.fallbackProfile;
      if (profile)
      {
        EditPlayerProfileController* editPlayerProfileController = [EditPlayerProfileController controllerForProfile:profile withDelegate:self];
        [self presentNavigationControllerWithRootViewController:editPlayerProfileController];
      }
      break;
    }
    default:
    {
      break;
    }
  }
}

#pragma mark - TableViewGridCellDelegate overrides

// -----------------------------------------------------------------------------
/// @brief TableViewGridCellDelegate protocol method.
// -----------------------------------------------------------------------------
- (int) numberOfColumnsInGridCell:(TableViewGridCell*)gridCell
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
  GoGame* game = [GoGame sharedGame];
  GoGameRules* rules = game.rules;
  GoScore* score = game.score;
  UiSettingsModel* settingsModel = [ApplicationDelegate sharedDelegate].uiSettingsModel;

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
    case CapturedItem:  // HandicapCompensationItem in area scoring
    {
      if (GoScoringSystemAreaScoring == rules.scoringSystem)
      {
        switch (column)
        {
          case BlackPlayerColumn:
            return @"-";
          case TitleColumn:
            return @"Handicap";
          case WhitePlayerColumn:
            return [NSString stringWithFractionValue:score.handicapCompensationWhite];
          default:
            assert(0);
            break;
        }
      }
      else
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
      }
      break;
    }
    case DeadItem:  // AliveItem in area scoring
    {
      if (GoScoringSystemAreaScoring == rules.scoringSystem)
      {
        switch (column)
        {
          case BlackPlayerColumn:
            if (settingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
              return [NSString stringWithFormat:@"%d", score.aliveBlack];
            else
              return @"n/a";
          case TitleColumn:
            return @"Stones";
          case WhitePlayerColumn:
            if (settingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
              return [NSString stringWithFormat:@"%d", score.aliveWhite];
            else
              return @"n/a";
          default:
            assert(0);
            break;
        }
      }
      else
      {
        switch (column)
        {
          case BlackPlayerColumn:
            if (settingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
              return [NSString stringWithFormat:@"%d", score.deadWhite];
            else
              return @"n/a";
          case TitleColumn:
            return @"Dead";
          case WhitePlayerColumn:
            if (settingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
              return [NSString stringWithFormat:@"%d", score.deadBlack];
            else
              return @"n/a";
          default:
            assert(0);
            break;
        }
      }
      break;
    }
    case TerritoryItem:
    {
      switch (column)
      {
        case BlackPlayerColumn:
          if (settingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
            return [NSString stringWithFormat:@"%d", score.territoryBlack];
          else
            return @"n/a";
        case TitleColumn:
          return @"Territory";
        case WhitePlayerColumn:
          if (settingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
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
          return [NSString stringWithFractionValue:score.totalScoreBlack];
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

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  // Unregister ourselves as observer while the old game configuration that
  // we used for registering is still around. For instance, the new game might
  // use different players or a different profile, so if we were waiting with
  // unregistering until dealloc (at which time the new game has already been
  // started), we would unregister ourselves from the wrong objects.
  [self removeNotificationResponders];
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

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([object isKindOfClass:[Player class]])
  {
    int row;
    if (object == [GoGame sharedGame].playerBlack.player)
      row = BlackPlayerItem;
    else
      row = WhitePlayerItem;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:PlayersProfileSection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }
}

#pragma mark - EditPlayerProfileDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditPlayerProfileDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didEditPlayerProfile:(EditPlayerProfileController*)editPlayerProfileController;
{
  if (editPlayerProfileController.player != nil)
  {
    GoGame* game = [GoGame sharedGame];
    NSMutableArray* indexPaths = [NSMutableArray array];
    if (editPlayerProfileController.player == game.playerBlack.player)
      [indexPaths addObject:[NSIndexPath indexPathForRow:BlackPlayerItem inSection:PlayersProfileSection]];
    else
      [indexPaths addObject:[NSIndexPath indexPathForRow:WhitePlayerItem inSection:PlayersProfileSection]];
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationNone];
    [self dismissViewControllerAnimated:YES completion:nil];
  }
  else
  {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Info Type" segmented control. Updates
/// the main table view to display information for the selected type.
// -----------------------------------------------------------------------------
- (void) infoTypeChanged:(id)sender
{
  UISegmentedControl* segmentedControl = (UISegmentedControl*)sender;
  // Cast is required because NSInteger and int (the type underlying enums)
  // differ in size in 64-bit. Cast is safe because the segments are designed
  // to match the enumeration.
  self.boardViewModel.infoTypeLastSelected = (enum InfoType)segmentedControl.selectedSegmentIndex;
  [self.tableView reloadData];
  if (GameInfoType == self.boardViewModel.infoTypeLastSelected)
    [self setupKVONotificationResponders];
  else
    [self removeKVONotificationResponders];
}

@end
