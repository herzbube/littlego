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
#import "GameInfoViewGameTabDelegate.h"
#import "../../model/TimeSettingsModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoGameResult.h"
#import "../../../go/GoGameRules.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoScore.h"
#import "../../../go/GoTimeSettings.h"
#import "../../../go/GoUtilities.h"
#import "../../../main/ModelProvider.h"
#import "../../../main/Registry.h"
#import "../../../player/GtpEngineProfileModel.h"
#import "../../../player/GtpEngineProfile.h"
#import "../../../player/Player.h"
#import "../../../sgf/SgfUtilities.h"
#import "../../../ui/TableViewCellFactory.h"
#import "../../../ui/TableViewVariableHeightCell.h"
#import "../../../ui/UIViewControllerAdditions.h"
#import "../../../utility/NSStringAdditions.h"
#import "../../../utility/TimeDataUtilities.h"


// Constants
static NSString* disputeResolutionRuleText_GameInfoViewController = @"Dispute resolution";


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Game" tab of the
/// "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoGameTabTableViewSection
{
  GameStateSection,
  GameInfoSection,
  TimeSettingsSection,
  PlayersProfileSection,
  MoveStatisticsSection,
  MaxSection,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameStateSection.
// -----------------------------------------------------------------------------
enum GameStateSectionItem
{
  GameStateItem,
  LastMoveItem,
  NextMoveItem,
  MaxGameStateSectionItem,
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
  SideToPlayFirstItem,
  MaxGameInfoSectionItem,
};


// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TimeSettingsSection.
// -----------------------------------------------------------------------------
enum TimeSettingsSectionItem
{
  NoTimedPlayItem,
  MaxTimeSettingsSectionItem_NoTimedPlay,
  MaintimeDescriptionItem = NoTimedPlayItem,
  OvertimeDescriptionItem,
  MaxTimeSettingsSectionItem_TimedPlay,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayersProfileSection.
// -----------------------------------------------------------------------------
enum PlayersProfileSectionItem
{
  BlackPlayerItem,
  WhitePlayerItem,
  HumanVsHumanGameProfileItem,
  MaxPlayersProfileSectionItem,
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
  MaxMoveStatisticsSectionItem,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties and properties for
/// GameInfoViewGameTabDelegate.
// -----------------------------------------------------------------------------
@interface GameInfoViewGameTabDelegate()
@property(nonatomic, assign) UIViewController* presentingViewController;
@property(nonatomic, assign) UITableView* tableView;
/// @brief Is required so that KVO notification responders are not removed
/// twice (e.g. the first time when #playersAndProfilesWillReset is received,
/// the second time when GameInfoViewController is deallocated).
@property(nonatomic, assign) bool kvoNotificationRespondersAreInstalled;
@property(nonatomic, retain) TimeSettingsModel* timeSettingsModel;
@end


@implementation GameInfoViewGameTabDelegate

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameInfoViewGameTabDelegate object.
///
/// @note This is the designated initializer of GameInfoViewGameTabDelegate.
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
  self.kvoNotificationRespondersAreInstalled = false;
  self.timeSettingsModel = [[[TimeSettingsModel alloc] init] autorelease];

  [self.timeSettingsModel updateWithGoTimeSettings:[GoGame sharedGame].timeSettings];
  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewGameTabDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.tableView = nil;
  self.timeSettingsModel = nil;

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
    case GameInfoSection:
      return MaxGameInfoSectionItem;
    case TimeSettingsSection:
      if ([GoGame sharedGame].timeSettings.hasNoTimeSystems)
        return MaxTimeSettingsSectionItem_NoTimedPlay;
      else
        return MaxTimeSettingsSectionItem_TimedPlay;
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
    case GameInfoSection:
      return @"Game information";
    case TimeSettingsSection:
      return @"Time settings";
    case PlayersProfileSection:
      return @"Players";
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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
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
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return [self tableView:tableView gameInfoTypeCellForRowAtIndexPath:indexPath];
}

#pragma mark - Private helpers for tableView:cellForRowAtIndexPath:().

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
                GoGameResult* gameResult = [GoUtilities gameResultForGoGameHasEndedReason:game.reasonForGameHasEnded];
                if (gameResult.dataType == GoGameResultDataTypeStructuredData)
                {
                  cell.detailTextLabel.text = [GoUtilities stringWithDescriptionOfGameResult:gameResult];
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
                  cell.detailTextLabel.text = [GoUtilities stringWithDescriptionOfMove:lastMove];
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
          variableHeightCell.descriptionLabelWidthPercentage = 0.5;
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
                                            inCurrentGameVariation:game].color;
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
    case TimeSettingsSection:
    {
      if (game.timeSettings.hasNoTimeSystems)
      {
        cell = [TableViewCellFactory cellWithType:VariableHeightCellType
                                        tableView:tableView];
        TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
        variableHeightCell.descriptionLabelWidthPercentage = 0.5;
        variableHeightCell.descriptionLabel.text = @"Time settings";
        variableHeightCell.valueLabel.text = [TimeDataUtilities timeSettingsModelSummary:self.timeSettingsModel];
      }
      else
      {
        cell = [TableViewCellFactory cellWithType:VariableHeightCellType
                                        tableView:tableView];
        TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
        variableHeightCell.descriptionLabelWidthPercentage = 0.3;

        if (indexPath.row == MaintimeDescriptionItem)
        {
          variableHeightCell.descriptionLabel.text = @"Main time";
          if (self.timeSettingsModel.absoluteTimingEnabled)
            variableHeightCell.valueLabel.text = [TimeDataUtilities absoluteTimeSystemSummary:self.timeSettingsModel];
          else
            variableHeightCell.valueLabel.text = @"None";
        }
        else
        {
          variableHeightCell.descriptionLabel.text = @"Overtime";
          if (self.timeSettingsModel.periodBasedTimeSystemEnabled)
            variableHeightCell.valueLabel.text = [TimeDataUtilities periodBasedTimeSystemSummary:self.timeSettingsModel];
          else
            variableHeightCell.valueLabel.text = @"None";
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
    cell.accessoryType = UITableViewCellAccessoryNone;
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
      [self.presentingViewController presentNavigationControllerWithRootViewController:editPlayerProfileController];
      break;
    }
    case HumanVsHumanGameProfileItem:
    {
      GtpEngineProfile* profile = [Registry sharedRegistry].modelProvider.gtpEngineProfileModel.fallbackProfile;
      if (profile)
      {
        EditPlayerProfileController* editPlayerProfileController = [EditPlayerProfileController controllerForProfile:profile withDelegate:self];
        [self.presentingViewController presentNavigationControllerWithRootViewController:editPlayerProfileController];
      }
      break;
    }
    default:
    {
      break;
    }
  }
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
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }
  else
  {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }
}

@end
