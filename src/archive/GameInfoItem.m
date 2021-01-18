// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameInfoItem.h"
#import "../sgf/SgfUtilities.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections required to present a GameInfoItem's data
/// in a table view when GameInfoItemDetailLevelSingleItem is being used.
// -----------------------------------------------------------------------------
enum GameInfoItemDetailLevelSingleItemTableViewSection
{
  SingleItemSection,
  MaxSectionGameInfoItemDetailLevelSingleItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the SingleItemSection.
// -----------------------------------------------------------------------------
enum SingleItemSectionItem
{
  SingleItem,
  MaxSingleItemSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the sections required to present a GameInfoItem's data
/// in a table view when GameInfoItemDetailLevelSummary is being used.
// -----------------------------------------------------------------------------
enum GameInfoItemDetailLevelSummaryTableViewSection
{
  SummarySection,
  MaxSectionGameInfoItemDetailLevelSummary
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the SummarySection.
// -----------------------------------------------------------------------------
enum SummarySectionItem
{
  GameNameSummaryItem,
  GameDatesSummaryItem,
  BlackPlayerNameSummaryItem,
  WhitePlayerNameSummaryItem,
  GameResultSummaryItem,
  BoardSizeSummaryItem,
  MaxSummarySectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the sections required to present a GameInfoItem's data
/// in a table view when GameInfoItemDetailLevelFull is being used.
// -----------------------------------------------------------------------------
enum GameInfoItemDetailLevelFullTableViewSection
{
  BasicInfoSection,
  ExtraInfoSection,
  PlayerInfoSection,
  ContextInfoSection,
  DataSourceInfoSection,
  MaxSectionGameInfoItemDetailLevelFull
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the BasicInfoSection.
// -----------------------------------------------------------------------------
enum BasicInfoSectionItem
{
  GameNameItem,
  GameInformationItem,
  GameDatesItem,
  RulesNameItem,
  NumberOfHandicapStonesItem,
  BoardSizeItem,
  KomiItem,
  GameResultItem,
  MaxBasicInfoSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ExtraInfoSection.
// -----------------------------------------------------------------------------
enum ExtraInfoSectionItem
{
  TimeLimitInSecondsItem,
  OvertimeItem,
  OpeningInformationItem,
  MaxExtraInfoSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayerInfoSection.
// -----------------------------------------------------------------------------
enum PlayerInfoSectionItem
{
  BlackPlayerNameItem,
  BlackPlayerRankItem,
  BlackPlayerTeamNameItem,
  WhitePlayerNameItem,
  WhitePlayerRankItem,
  WhitePlayerTeamNameItem,
  MaxPlayerInfoSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ContextInfoSection.
// -----------------------------------------------------------------------------
enum ContextInfoSectionItem
{
  GameLocationItem,
  EventNameItem,
  RoundInformationItem,
  MaxContextInfoSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DataSourceInfoSection.
// -----------------------------------------------------------------------------
enum DataSourceInfoSectionItem
{
  RecorderNameItem,
  SourceNameItem,
  AnnotationAuthorItem,
  CopyrightInformationItem,
  MaxDataSourceInfoSectionItem
};


#pragma mark - Class extension

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GameInfoItem.
// -----------------------------------------------------------------------------
@interface GameInfoItem()
// Private properties
@property(nonatomic, assign) bool usesDescriptText;

// From here on re-declarations of public properties to make them readwrite
@property(nonatomic, retain, readwrite) SGFCGoGameInfo* goGameInfo;
@property(nonatomic, retain, readwrite) NSString* descriptiveText;
@property(nonatomic, retain, readwrite) NSString* titleText;

@property(nonatomic, retain, readwrite) NSString* boardSizeAsString;
@property(nonatomic, assign, readwrite) SGFCBoardSize boardSize;

@property(nonatomic, retain, readwrite) NSString* recorderName;
@property(nonatomic, retain, readwrite) NSString* sourceName;
@property(nonatomic, retain, readwrite) NSString* annotationAuthor;
@property(nonatomic, retain, readwrite) NSString* copyrightInformation;

@property(nonatomic, retain, readwrite) NSString* gameName;
@property(nonatomic, retain, readwrite) NSString* gameInformation;
@property(nonatomic, retain, readwrite) NSString* gameDatesAsString;
@property(nonatomic, retain, readwrite) NSArray* gameDates;
@property(nonatomic, retain, readwrite) NSString* rulesName;
@property(nonatomic, assign, readwrite) SGFCGoRuleset goRuleset;
@property(nonatomic, retain, readwrite) NSString* numberOfHandicapStonesAsString;
@property(nonatomic, assign, readwrite) SGFCNumber numberOfHandicapStones;
@property(nonatomic, retain, readwrite) NSString* komiAsString;
@property(nonatomic, assign, readwrite) SGFCReal komi;
@property(nonatomic, retain, readwrite) NSString* gameResultAsString;
@property(nonatomic, assign, readwrite) SGFCGameResult gameResult;

@property(nonatomic, retain, readwrite) NSString* timeLimitInSecondsAsString;
@property(nonatomic, assign, readwrite) SGFCReal timeLimitInSeconds;
@property(nonatomic, retain, readwrite) NSString* overtimeInformation;
@property(nonatomic, retain, readwrite) NSString* openingInformation;

@property(nonatomic, retain, readwrite) NSString* blackPlayerName;
@property(nonatomic, retain, readwrite) NSString* blackPlayerRankAsString;
@property(nonatomic, assign, readwrite) SGFCGoPlayerRank blackPlayerRank;
@property(nonatomic, retain, readwrite) NSString* blackPlayerTeamName;
@property(nonatomic, retain, readwrite) NSString* whitePlayerName;
@property(nonatomic, retain, readwrite) NSString* whitePlayerRankAsString;
@property(nonatomic, assign, readwrite) SGFCGoPlayerRank whitePlayerRank;
@property(nonatomic, retain, readwrite) NSString* whitePlayerTeamName;

@property(nonatomic, retain, readwrite) NSString* gameLocation;
@property(nonatomic, retain, readwrite) NSString* eventName;
@property(nonatomic, retain, readwrite) NSString* roundInformationAsString;
@property(nonatomic, assign, readwrite) SGFCRoundInformation roundInformation;
@end


@implementation GameInfoItem

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed autoreleased GameInfoItem object with
/// values taken from @a goGameInfo. @a titleText is used as the title text
/// when the single item or summary detail levels are used to display the
/// GameInfoItem's data.
// -----------------------------------------------------------------------------
+ (GameInfoItem*) gameInfoItemWithGoGameInfo:(SGFCGoGameInfo*)goGameInfo titleText:(NSString*)titleText
{
  return [[[GameInfoItem alloc] initWithGoGameInfo:goGameInfo titleText:titleText] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed autoreleased GameInfoItem object whose
/// only value is @a descriptiveText. @a titleText is used as the title text
/// the GameInfoItem's data is displayed.
// -----------------------------------------------------------------------------
+ (GameInfoItem*) gameInfoItemWithDescriptiveText:(NSString*)descriptiveText titleText:(NSString*)titleText
{
  return [[[GameInfoItem alloc] initWithDescriptiveText:descriptiveText titleText:titleText] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an GameInfoItem object with values taken from
/// @a goGameInfo. @a titleText is used as the title text when the single item
/// or summary detail levels are used to display the GameInfoItem's data.
// -----------------------------------------------------------------------------
- (id) initWithGoGameInfo:(SGFCGoGameInfo*)goGameInfo titleText:(NSString*)titleText
{
  self = [self initWithDescriptiveText:@"" titleText:titleText];
  if (! self)
    return nil;

  self.goGameInfo = goGameInfo;
  self.descriptiveText = nil;
  self.usesDescriptText = false;

  [self updateDataFromGoGameInfo];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an GameInfoItem object whose only value is
/// @a descriptiveText. @a titleText is used as the title text the
/// GameInfoItem's data is displayed.
///
/// @note This is the designated initializer of GameInfoItem.
// -----------------------------------------------------------------------------
- (id) initWithDescriptiveText:(NSString*)descriptiveText titleText:(NSString*)titleText
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.goGameInfo = nil;
  self.descriptiveText = descriptiveText;
  self.usesDescriptText = true;
  self.titleText = titleText;

  // Don't use the expensive setter
  // TODO xxx use GameInfoItemMissingDataDisplayStyleHide
  _missingDataDisplayStyle = GameInfoItemMissingDataDisplayStyleShowAsNoData;

  [self updateDataFromGoGameInfo];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoItem object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.goGameInfo = nil;
  self.descriptiveText = nil;

  self.boardSizeAsString = nil;

  self.recorderName = nil;
  self.sourceName = nil;
  self.annotationAuthor = nil;
  self.copyrightInformation = nil;

  self.gameName = nil;
  self.gameInformation = nil;
  self.gameDatesAsString = nil;
  self.gameDates = nil;
  self.rulesName = nil;
  self.numberOfHandicapStonesAsString = nil;
  self.komiAsString = nil;
  self.gameResultAsString = nil;

  self.timeLimitInSecondsAsString = nil;
  self.overtimeInformation = nil;
  self.openingInformation = nil;

  self.blackPlayerName = nil;
  self.blackPlayerRankAsString = nil;
  self.blackPlayerTeamName = nil;
  self.whitePlayerName = nil;
  self.whitePlayerRankAsString = nil;
  self.whitePlayerTeamName = nil;

  self.gameLocation = nil;
  self.eventName = nil;
  self.roundInformationAsString = nil;

  [super dealloc];
}

#pragma mark - Public API - UITableView support

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView detailLevel:(enum GameInfoItemDetailLevel)detailLevel
{
  if (self.usesDescriptText)
    detailLevel = GameInfoItemDetailLevelSingleItem;

  switch (detailLevel)
  {
    case GameInfoItemDetailLevelSingleItem:
      return MaxSectionGameInfoItemDetailLevelSingleItem;
    case GameInfoItemDetailLevelSummary:
      return MaxSectionGameInfoItemDetailLevelSummary;
    case GameInfoItemDetailLevelFull:
      return MaxSectionGameInfoItemDetailLevelFull;
    default:
      assert(0);
      return 0;
  }
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section detailLevel:(enum GameInfoItemDetailLevel)detailLevel
{
  if (self.usesDescriptText)
    detailLevel = GameInfoItemDetailLevelSingleItem;

  switch (detailLevel)
  {
    case GameInfoItemDetailLevelSingleItem:
      return MaxSingleItemSectionItem;
    case GameInfoItemDetailLevelSummary:
      return MaxSummarySectionItem;
    case GameInfoItemDetailLevelFull:
      switch (section)
      {
        case BasicInfoSection:
          return MaxBasicInfoSectionItem;
        case ExtraInfoSection:
          return MaxExtraInfoSectionItem;
        case PlayerInfoSection:
          return MaxPlayerInfoSectionItem;
        case ContextInfoSection:
          return MaxContextInfoSectionItem;
        case DataSourceInfoSection:
          return MaxDataSourceInfoSectionItem;
        default:
          assert(0);
          return 0;
      }
    default:
      assert(0);
      return 0;
  }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section detailLevel:(enum GameInfoItemDetailLevel)detailLevel
{
  if (self.usesDescriptText)
    return self.titleText;

  switch (detailLevel)
  {
    case GameInfoItemDetailLevelSingleItem:
      return self.titleText;
    case GameInfoItemDetailLevelSummary:
      return self.titleText;
    case GameInfoItemDetailLevelFull:
      switch (section)
      {
        case BasicInfoSection:
          return @"Basic info";
        case ExtraInfoSection:
          return @"Extra info";
        case PlayerInfoSection:
          return @"Player info";
        case ContextInfoSection:
          return @"Context info";
        case DataSourceInfoSection:
          return @"Data source info";
        default:
          assert(0);
          return nil;
      }
    default:
      assert(0);
      return nil;
  }
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath detailLevel:(enum GameInfoItemDetailLevel)detailLevel
{
  if (self.usesDescriptText)
    detailLevel = GameInfoItemDetailLevelSingleItem;

  UITableViewCell* cell = nil;

  switch (detailLevel)
  {
    case GameInfoItemDetailLevelSingleItem:
    {
      if (self.usesDescriptText)
      {
        cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
        cell.textLabel.text = self.descriptiveText;
      }
      else
      {
        cell = [self boardSizeCellWithTableView:tableView];
      }
      break;
    }
    case GameInfoItemDetailLevelSummary:
    {
      switch (indexPath.row)
      {
        case GameNameSummaryItem:
        {
          cell = [self gameNameCellWithTableView:tableView];
          break;
        }
        case GameDatesSummaryItem:
        {
          cell = [self gameDatesCellWithTableView:tableView];
          break;
        }
        case BlackPlayerNameSummaryItem:
        {
          cell = [self blackPlayerNameCellWithTableView:tableView];
          break;
        }
        case WhitePlayerNameSummaryItem:
        {
          cell = [self whitePlayerNameCellWithTableView:tableView];
          break;
        }
        case GameResultSummaryItem:
        {
          cell = [self gameResultCellWithTableView:tableView];
          break;
        }
        case BoardSizeSummaryItem:
        {
          cell = [self boardSizeCellWithTableView:tableView];
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
    case GameInfoItemDetailLevelFull:
    {
      // TODO xxx implement
      switch (indexPath.section)
      {
        case BasicInfoSection:
        {
          break;
        }
        case ExtraInfoSection:
        {
          break;
        }
        case PlayerInfoSection:
        {
          break;
        }
        case ContextInfoSection:
        {
          break;
        }
        case DataSourceInfoSection:
        {
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
    }
    default:
    {
      assert(0);
      break;
    }
  }

  if (cell)
  {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  return cell;
}

#pragma mark - Public API - Property setter

- (void) setMissingDataDisplayStyle:(enum GameInfoItemMissingDataDisplayStyle)missingDataDisplayStyle
{
  if (_missingDataDisplayStyle == missingDataDisplayStyle)
    return;
  _missingDataDisplayStyle = missingDataDisplayStyle;

  // Update properties with missing values to the new style - the simplest
  // way to achieve this is to fully parse the data again
  [self updateDataFromGoGameInfo];
}

#pragma mark - Private API - Initialization

- (void) updateDataFromGoGameInfo
{
  SGFCGoGameInfo* goGameInfo = self.goGameInfo;
  enum GameInfoItemMissingDataDisplayStyle missingDataDisplayStyle = self.missingDataDisplayStyle;

  if (goGameInfo == nil)
  {
    NSString* missingStringValue = [self stringValue:nil forMissingDataDisplayStyle:missingDataDisplayStyle];

    self.boardSizeAsString = missingStringValue;
    self.boardSize = SGFCBoardSizeInvalid;

    self.recorderName = missingStringValue;
    self.sourceName = missingStringValue;
    self.annotationAuthor = missingStringValue;
    self.copyrightInformation = missingStringValue;

    self.gameName = missingStringValue;
    self.gameInformation = missingStringValue;
    self.gameDatesAsString = missingStringValue;
    self.gameDates = [NSArray array];
    self.rulesName = missingStringValue;
    self.goRuleset = SGFCGoRulesetMake(SGFCGoRulesetTypeAGA, NO);
    self.numberOfHandicapStonesAsString = missingStringValue;
    self.numberOfHandicapStones = 0;
    self.komiAsString = missingStringValue;
    self.komi = 0.0;
    self.gameResultAsString = missingStringValue;
    self.gameResult = SGFCGameResultMake(SGFCGameResultTypeUnknownResult, SGFCWinTypeWinWithScore, 0.0, NO);

    self.timeLimitInSecondsAsString = missingStringValue;
    self.timeLimitInSeconds = 0.0;
    self.overtimeInformation = missingStringValue;
    self.openingInformation = missingStringValue;

    self.blackPlayerName = missingStringValue;
    self.blackPlayerRankAsString = missingStringValue;
    self.blackPlayerRank = SGFCGoPlayerRankMake(30, SGFCGoPlayerRankTypeKyu, SGFCGoPlayerRatingTypeUnspecified, NO);
    self.blackPlayerTeamName = missingStringValue;
    self.whitePlayerName = missingStringValue;
    self.whitePlayerRankAsString = missingStringValue;
    self.whitePlayerRank = SGFCGoPlayerRankMake(30, SGFCGoPlayerRankTypeKyu, SGFCGoPlayerRatingTypeUnspecified, NO);
    self.whitePlayerTeamName = missingStringValue;

    self.gameLocation = missingStringValue;
    self.eventName = missingStringValue;
    self.roundInformationAsString = missingStringValue;
    self.roundInformation = SGFCRoundInformationMake(missingStringValue, missingStringValue, NO);
  }
  else
  {
    self.boardSizeAsString = [self stringValue:[SgfUtilities stringForSgfBoardSize:goGameInfo.boardSize]
                    forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.boardSize = goGameInfo.boardSize;

    self.recorderName = [self stringValue:goGameInfo.recorderName forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.sourceName = [self stringValue:goGameInfo.sourceName forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.annotationAuthor = [self stringValue:goGameInfo.annotationAuthor forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.copyrightInformation = [self stringValue:goGameInfo.copyrightInformation forMissingDataDisplayStyle:missingDataDisplayStyle];

    self.gameName = [self stringValue:goGameInfo.gameName forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.gameInformation = [self stringValue:goGameInfo.gameInformation forMissingDataDisplayStyle:missingDataDisplayStyle];
    NSArray* dateArray;
    NSArray* stringArray;
    [SgfUtilities parseSgfGameDates:goGameInfo.gameDates dateArray:&dateArray stringArray:&stringArray];
    self.gameDatesAsString = [self stringValue:[stringArray componentsJoinedByString:@", "]
                    forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.gameDates = dateArray;
    self.rulesName = [self stringValue:goGameInfo.rulesName forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.goRuleset = goGameInfo.goRuleset;
    self.numberOfHandicapStonesAsString = [self stringValue:[NSString stringWithFormat:@"%ld", (long)goGameInfo.numberOfHandicapStones]
                                 forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.numberOfHandicapStones = goGameInfo.numberOfHandicapStones;
    self.komiAsString = [self stringValue:[NSString stringWithFormat:@"%.1f", goGameInfo.komi]
               forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.komi = goGameInfo.komi;
    self.gameResultAsString = [self stringValue:[SgfUtilities stringForSgfGameResult:goGameInfo.gameResult]
                     forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.gameResult = goGameInfo.gameResult;

    self.timeLimitInSecondsAsString = [self stringValue:[NSString stringWithFormat:@"%.1f", goGameInfo.timeLimitInSeconds]
                             forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.timeLimitInSeconds = goGameInfo.timeLimitInSeconds;
    self.overtimeInformation = [self stringValue:goGameInfo.overtimeInformation forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.openingInformation = [self stringValue:goGameInfo.openingInformation forMissingDataDisplayStyle:missingDataDisplayStyle];

    self.blackPlayerName = [self stringValue:goGameInfo.blackPlayerName forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.blackPlayerRankAsString = [self stringValue:[SgfUtilities stringForSgfGoPlayerRank:goGameInfo.goBlackPlayerRank]
                          forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.blackPlayerRank = goGameInfo.goBlackPlayerRank;
    self.blackPlayerTeamName = [self stringValue:goGameInfo.blackPlayerTeamName forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.whitePlayerName = [self stringValue:goGameInfo.whitePlayerName forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.whitePlayerRankAsString = [self stringValue:[SgfUtilities stringForSgfGoPlayerRank:goGameInfo.goWhitePlayerRank]
                          forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.whitePlayerRank = goGameInfo.goWhitePlayerRank;
    self.whitePlayerTeamName = [self stringValue:goGameInfo.whitePlayerTeamName forMissingDataDisplayStyle:missingDataDisplayStyle];

    self.gameLocation = [self stringValue:goGameInfo.gameLocation forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.eventName = [self stringValue:goGameInfo.eventName forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.roundInformationAsString = [self stringValue:goGameInfo.rawRoundInformation forMissingDataDisplayStyle:missingDataDisplayStyle];
    self.roundInformation = goGameInfo.roundInformation;
  }
}

- (NSString*) stringValue:(NSString*)stringValue forMissingDataDisplayStyle:(enum GameInfoItemMissingDataDisplayStyle)missingDataDisplayStyle
{
  // If self.goGameInfo is nil we get nil values
  if (stringValue == nil || stringValue.length == 0)
  {
    switch (missingDataDisplayStyle)
    {
      case GameInfoItemMissingDataDisplayStyleShowAsNoData:
        return @"<No data>";
      case GameInfoItemMissingDataDisplayStyleHide:
      case GameInfoItemMissingDataDisplayStyleShowAsEmpty:
        return @"";
      default:
        assert(0);
        return @"Unsupported GameInfoItemMissingDataDisplayStyle";
    }
  }
  else
  {
    return stringValue;
  }
}

#pragma mark - Private API - Table view cell creation

- (UITableViewCell*) boardSizeCellWithTableView:(UITableView*)tableView
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  cell.textLabel.text = @"Board size";
  cell.detailTextLabel.text = self.boardSizeAsString;
  return cell;
}

- (UITableViewCell*) gameNameCellWithTableView:(UITableView*)tableView
{
  // TODO xxx use VariableHeightCellType, but add a new mode that
  // increases the height of the value label. Also may need to set
  // a distinct reusableCellIdentifier
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  cell.textLabel.text = @"Game name";
  cell.detailTextLabel.text = self.gameName;
  return cell;
}

- (UITableViewCell*) gameDatesCellWithTableView:(UITableView*)tableView
{
  // TODO xxx use VariableHeightCellType, see GameNameItem
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  cell.textLabel.text = @"Dates";
  cell.detailTextLabel.text = self.gameDatesAsString;
  return cell;
}

- (UITableViewCell*) blackPlayerNameCellWithTableView:(UITableView*)tableView
{
  // TODO xxx use VariableHeightCellType, see GameNameItem
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  cell.textLabel.text = @"Black";
  cell.detailTextLabel.text = self.blackPlayerName;
  return cell;
}

- (UITableViewCell*) whitePlayerNameCellWithTableView:(UITableView*)tableView
{
  // TODO xxx use VariableHeightCellType, see GameNameItem
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  cell.textLabel.text = @"White";
  cell.detailTextLabel.text = self.whitePlayerName;
  return cell;
}

- (UITableViewCell*) gameResultCellWithTableView:(UITableView*)tableView
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  cell.textLabel.text = @"Result";
  cell.detailTextLabel.text = self.gameResultAsString;
  return cell;
}

@end
