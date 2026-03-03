// -----------------------------------------------------------------------------
// Copyright 2011-2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameInfoViewScoreTabDelegate.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoGameInfo.h"
#import "../../../go/GoGameResult.h"
#import "../../../go/GoGameRules.h"
#import "../../../go/GoScore.h"
#import "../../../go/GoUtilities.h"
#import "../../../main/ModelProvider.h"
#import "../../../main/Registry.h"
#import "../../../ui/TableViewCellFactory.h"
#import "../../../ui/TableViewVariableHeightCell.h"
#import "../../../ui/UiSettingsModel.h"
#import "../../../ui/UIViewControllerAdditions.h"
#import "../../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Score" tab of the
/// "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoScoreTabTableViewSection
{
  ScoreSection,
  GameResultSection,
  MaxSection,
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
  MaxScoreSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameResultSection.
// -----------------------------------------------------------------------------
enum GameResultSectionItem
{
  GameResultSummaryItem,
  UseScoreAsGameResultItem,
  MaxGameResultSection,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates columns in the ScoreSection.
// -----------------------------------------------------------------------------
enum ScoreSectionColumn
{
  BlackPlayerColumn,
  TitleColumn,
  WhitePlayerColumn,
  MaxScoreSectionColumn,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties and properties for
/// GameInfoViewScoreTabDelegate.
// -----------------------------------------------------------------------------
@interface GameInfoViewScoreTabDelegate()
@property(nonatomic, assign) UIViewController* presentingViewController;
@property(nonatomic, assign) UITableView* tableView;
@property(nonatomic, assign) EditGameResultController* editGameResultController;
@property(nonatomic, assign) bool gameResultDataDidChange;
@end


@implementation GameInfoViewScoreTabDelegate

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameInfoViewScoreTabDelegate object.
///
/// @note This is the designated initializer of GameInfoViewScoreTabDelegate.
// -----------------------------------------------------------------------------
- (id) initWithPresentingViewController:(UIViewController*)presentingViewController
                              tableView:(UITableView*)tableView
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.presentingViewController = presentingViewController;
  self.tableView = tableView;
  self.editGameResultController = nil;
  self.gameResultDataDidChange = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewScoreTabDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // This GameInfoViewScoreTabDelegate is deallocated while
  // EditGameResultController is still presented if the game info view is
  // popped directly from the navigation stack => for unknown reasons, UiKit in
  // that case does not deallocate view controllers at the top of the navigation
  // stack first, but immediately deallocates GameInfoViewController.
  // - Scenario 1: User taps the tab bar item.
  // - Scenario 2: A new game is created and the app programmatically pops the
  //   navigation stack.
  // In all cases we remove ourselves as the delegate of
  // EditGameResultController so that EditGameResultController does not attempt
  // to notify us after we are already deallocated.
  if (self.editGameResultController)
    self.editGameResultController.delegate = nil;

  self.presentingViewController = nil;
  self.tableView = nil;
  self.editGameResultController = nil;

  [super dealloc];
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
  if (section == ScoreSection)
    return MaxScoreSectionItem;
  else
    return MaxGameResultSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (section == ScoreSection)
  {
    GoGame* game = [GoGame sharedGame];
    GoBoardPosition* boardPosition = game.boardPosition;
    bool nodeWithNextMoveExists = [GoUtilities nodeWithNextMoveExists:boardPosition.currentNode inCurrentGameVariation:game];
    NSString* titlePartOne = nil;
    if (nodeWithNextMoveExists)
      titlePartOne = @"This score reflects the board position you are currently viewing, NOT the final score. Navigate to the last move of the game to see the final score.";

    NSString* titlePartTwo = nil;
    if ([Registry sharedRegistry].modelProvider.uiSettingsModel.uiAreaPlayMode != UIAreaPlayModeScoring)
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
  else
  {
    return @"The overall game result is recorded when you save the game to the archive. If there are several game variations, the overall game result refers to the outcome of the game that is played out in the main variation.";
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return [self tableView:tableView scoreInfoTypeCellForRowAtIndexPath:indexPath];
}

#pragma mark - Private helpers for tableView:cellForRowAtIndexPath:().

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView scoreInfoTypeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;

  switch (indexPath.section)
  {
    case ScoreSection:
    {
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
      break;
    }
    case GameResultSection:
    {
      switch (indexPath.row)
      {
        case GameResultSummaryItem:
        {
          cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
          TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;

          GoGameResult* gameResult = [GoGame sharedGame].gameInfo.gameResult;
          variableHeightCell.descriptionLabel.text = @"Game result";
          variableHeightCell.valueLabel.text = [GoUtilities stringWithDescriptionOfGameResult:gameResult];
          variableHeightCell.descriptionLabelWidthPercentage = 0.4;

          variableHeightCell.selectionStyle = UITableViewCellSelectionStyleBlue;
          variableHeightCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case UseScoreAsGameResultItem:
        {
          cell = [TableViewCellFactory cellWithType:ActionTextCellType tableView:tableView];
          cell.textLabel.text = @"Use score as game result";
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

  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (indexPath.section != GameResultSection)
    return;

  switch (indexPath.row)
  {
    case GameResultSummaryItem:
    {
      GoGame* game = [GoGame sharedGame];
      GoGameResult* gameResult = game.gameInfo.gameResult;
      self.editGameResultController = [EditGameResultController controllerWithGameResult:gameResult
                                                                                delegate:self];
      [self.presentingViewController.navigationController pushViewController:self.editGameResultController animated:YES];
      break;
    }
    case UseScoreAsGameResultItem:
    {
      GoGame* game = [GoGame sharedGame];
      GoScore* score = game.score;
      GoGameResult* gameResult = game.gameInfo.gameResult;
      switch (score.result)
      {
        case GoGameResultNone:
        {
          gameResult.dataType = GoGameResultDataTypeNoResult;
          break;
        }
        case GoGameResultBlackHasWon:
        {
          gameResult.dataType = GoGameResultDataTypeStructuredData;
          gameResult.gameResultType = GoGameResultTypeBlackWin;
          gameResult.winType = GoGameResultWinTypeWinWithScore;
          gameResult.score = score.totalScoreBlack - score.totalScoreWhite;
          break;
        }
        case GoGameResultWhiteHasWon:
        {
          gameResult.dataType = GoGameResultDataTypeStructuredData;
          gameResult.gameResultType = GoGameResultTypeWhiteWin;
          gameResult.winType = GoGameResultWinTypeWinWithScore;
          gameResult.score = score.totalScoreWhite - score.totalScoreBlack;
          break;
        }
        case GoGameResultTie:
        {
          gameResult.dataType = GoGameResultDataTypeStructuredData;
          gameResult.gameResultType = GoGameResultTypeDraw;
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }

      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:GameResultSummaryItem
                                                  inSection:GameResultSection];
      [tableView reloadRowsAtIndexPaths:@[indexPath]
                       withRowAnimation:UITableViewRowAnimationAutomatic];
      break;
    }
    default:
    {
      assert(0);
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
  UiSettingsModel* settingsModel = [Registry sharedRegistry].modelProvider.uiSettingsModel;

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

#pragma mark - EditGameResultDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditGameResultDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) editGameResultController:(EditGameResultController*)controller gameResultDidChange:(GoGameResult*)gameResult
{
  // At this point self.tableView is not visible => we should not tell it to
  // reload parts of its data yet. Instead we wait until editing finishes and
  // EditGameResultController is dismissed
  self.gameResultDataDidChange = true;
}

// -----------------------------------------------------------------------------
/// @brief EditGameResultDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) editGameResultController:(EditGameResultController*)controller gameResultEditingDidFinish:(GoGameResult*)gameResult
{
  self.editGameResultController = nil;

  if (! self.gameResultDataDidChange)
    return;
  self.gameResultDataDidChange = false;

  NSUInteger sectionIndex = GameResultSection;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:GameResultSummaryItem inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
