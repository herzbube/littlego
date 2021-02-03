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
#import "../ui/TableViewVariableHeightCell.h"


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
  BoardSizeItem,
  NumberOfHandicapStonesItem,
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
  OvertimeInformationItem,
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
@property(nonatomic, assign) CGFloat descriptionLabelWidthPercentageForVariableHeightCells;

@property(nonatomic, retain) NSMutableDictionary* summarySectionItems;
@property(nonatomic, retain) NSMutableDictionary* detailLevelFullSections;
@property(nonatomic, retain) NSMutableDictionary* dataSourceInfoSectionItems;
@property(nonatomic, retain) NSMutableDictionary* basicInfoSectionItems;
@property(nonatomic, retain) NSMutableDictionary* extraInfoSectionItems;
@property(nonatomic, retain) NSMutableDictionary* playerInfoSectionItems;
@property(nonatomic, retain) NSMutableDictionary* contextInfoSectionItems;

// From here on re-declarations of public properties to make them readwrite
@property(nonatomic, retain, readwrite) SGFCGoGameInfo* goGameInfo;
@property(nonatomic, retain, readwrite) NSString* descriptiveText;
@property(nonatomic, retain, readwrite) NSString* titleText;

@property(nonatomic, retain, readwrite) NSString* boardSizeAsString;
@property(nonatomic, assign, readwrite) SGFCBoardSize boardSize;

@property(nonatomic, retain, readwrite) NSString* recorderName;
@property(nonatomic, assign, readwrite) bool recorderNameHasData;
@property(nonatomic, retain, readwrite) NSString* sourceName;
@property(nonatomic, assign, readwrite) bool sourceNameHasData;
@property(nonatomic, retain, readwrite) NSString* annotationAuthor;
@property(nonatomic, assign, readwrite) bool annotationAuthorHasData;
@property(nonatomic, retain, readwrite) NSString* copyrightInformation;
@property(nonatomic, assign, readwrite) bool copyrightInformationHasData;

@property(nonatomic, retain, readwrite) NSString* gameName;
@property(nonatomic, assign, readwrite) bool gameNameHasData;
@property(nonatomic, retain, readwrite) NSString* gameInformation;
@property(nonatomic, assign, readwrite) bool gameInformationHasData;
@property(nonatomic, retain, readwrite) NSString* gameDatesAsString;
@property(nonatomic, retain, readwrite) NSArray* gameDates;
@property(nonatomic, assign, readwrite) bool gameDatesHasData;
@property(nonatomic, retain, readwrite) NSString* rulesName;
@property(nonatomic, assign, readwrite) SGFCGoRuleset goRuleset;
@property(nonatomic, assign, readwrite) bool goRulesetHasData;
@property(nonatomic, retain, readwrite) NSString* numberOfHandicapStonesAsString;
@property(nonatomic, assign, readwrite) SGFCNumber numberOfHandicapStones;
@property(nonatomic, assign, readwrite) bool numberOfHandicapStonesHasData;
@property(nonatomic, retain, readwrite) NSString* komiAsString;
@property(nonatomic, assign, readwrite) SGFCReal komi;
@property(nonatomic, assign, readwrite) bool komiHasData;
@property(nonatomic, retain, readwrite) NSString* gameResultAsString;
@property(nonatomic, assign, readwrite) SGFCGameResult gameResult;
@property(nonatomic, assign, readwrite) bool gameResultHasData;

@property(nonatomic, retain, readwrite) NSString* timeLimitInSecondsAsString;
@property(nonatomic, assign, readwrite) SGFCReal timeLimitInSeconds;
@property(nonatomic, assign, readwrite) bool timeLimitInSecondsHasData;
@property(nonatomic, retain, readwrite) NSString* overtimeInformation;
@property(nonatomic, assign, readwrite) bool overtimeInformationHasData;
@property(nonatomic, retain, readwrite) NSString* openingInformation;
@property(nonatomic, assign, readwrite) bool openingInformationHasData;

@property(nonatomic, retain, readwrite) NSString* blackPlayerName;
@property(nonatomic, assign, readwrite) bool blackPlayerNameHasData;
@property(nonatomic, retain, readwrite) NSString* blackPlayerRankAsString;
@property(nonatomic, assign, readwrite) SGFCGoPlayerRank blackPlayerRank;
@property(nonatomic, assign, readwrite) bool blackPlayerRankHasData;
@property(nonatomic, retain, readwrite) NSString* blackPlayerTeamName;
@property(nonatomic, assign, readwrite) bool blackPlayerTeamNameHasData;
@property(nonatomic, retain, readwrite) NSString* whitePlayerName;
@property(nonatomic, assign, readwrite) bool whitePlayerNameHasData;
@property(nonatomic, retain, readwrite) NSString* whitePlayerRankAsString;
@property(nonatomic, assign, readwrite) SGFCGoPlayerRank whitePlayerRank;
@property(nonatomic, assign, readwrite) bool whitePlayerRankHasData;
@property(nonatomic, retain, readwrite) NSString* whitePlayerTeamName;
@property(nonatomic, assign, readwrite) bool whitePlayerTeamNameHasData;

@property(nonatomic, retain, readwrite) NSString* gameLocation;
@property(nonatomic, assign, readwrite) bool gameLocationHasData;
@property(nonatomic, retain, readwrite) NSString* eventName;
@property(nonatomic, assign, readwrite) bool eventNameHasData;
@property(nonatomic, retain, readwrite) NSString* roundInformationAsString;
@property(nonatomic, assign, readwrite) SGFCRoundInformation roundInformation;
@property(nonatomic, assign, readwrite) bool roundInformationHasData;
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
  [self updateItemDictionaries];

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

  // Experimentally determined value. On an iPhone 5s, the most narrow of the
  // supported devices, this percentage gives enough space to a
  // TableViewVariableHeightCell's description label to display the reference
  // text "Game name" on one line, plus a bit of extra width to create a spacing
  // between the two labels of the cell. On wider devices this ratio could be
  // larger, but a dynamically calculated ratio is too much work for now.
  self.descriptionLabelWidthPercentageForVariableHeightCells = 0.4;

  self.goGameInfo = nil;
  self.descriptiveText = descriptiveText;
  self.usesDescriptText = true;
  self.titleText = titleText;

  // Don't use the expensive setter
  _missingDataDisplayStyle = GameInfoItemMissingDataDisplayStyleHide;

  [self updateDataFromGoGameInfo];
  [self updateItemDictionaries];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoItem object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.goGameInfo = nil;
  self.descriptiveText = nil;
  self.titleText = nil;

  self.summarySectionItems = nil;
  self.detailLevelFullSections = nil;
  self.dataSourceInfoSectionItems = nil;
  self.basicInfoSectionItems = nil;
  self.extraInfoSectionItems = nil;
  self.playerInfoSectionItems = nil;
  self.contextInfoSectionItems = nil;

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
      if (self.missingDataDisplayStyle == GameInfoItemMissingDataDisplayStyleHide)
        return self.detailLevelFullSections.count;
      else
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
    {
      return MaxSingleItemSectionItem;
    }
    case GameInfoItemDetailLevelSummary:
    {
      if (self.missingDataDisplayStyle == GameInfoItemMissingDataDisplayStyleHide)
        return self.summarySectionItems.count;
      else
        return MaxSummarySectionItem;
    }
    case GameInfoItemDetailLevelFull:
    {
      if (self.missingDataDisplayStyle == GameInfoItemMissingDataDisplayStyleHide)
      {
        section = [(NSNumber*)self.detailLevelFullSections[@(section)] intValue];
        NSDictionary* sectionItemsDictionary = [self sectionItemsDictionaryForSection:section];
        return sectionItemsDictionary.count;
      }
      else
      {
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
      }
    }
    default:
    {
      assert(0);
      return 0;
    }
  }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section detailLevel:(enum GameInfoItemDetailLevel)detailLevel
{
  if (self.usesDescriptText)
    return self.titleText;

  switch (detailLevel)
  {
    case GameInfoItemDetailLevelSingleItem:
    {
      return self.titleText;
    }
    case GameInfoItemDetailLevelSummary:
    {
      return self.titleText;
    }
    case GameInfoItemDetailLevelFull:
    {
      if (self.missingDataDisplayStyle == GameInfoItemMissingDataDisplayStyleHide)
        section = [(NSNumber*)self.detailLevelFullSections[@(section)] intValue];

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
    }
    default:
    {
      assert(0);
      return nil;
    }
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
        cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
        TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
        variableHeightCell.descriptionLabel.text = self.descriptiveText;
        variableHeightCell.valueLabel.text = nil;
        variableHeightCell.descriptionLabelWidthPercentage = 1.0;
      }
      else
      {
        cell = [self boardSizeCellWithTableView:tableView];
      }
      break;
    }
    case GameInfoItemDetailLevelSummary:
    {
      NSUInteger row;
      if (self.missingDataDisplayStyle == GameInfoItemMissingDataDisplayStyleHide)
        row = [(NSNumber*)self.summarySectionItems[@(indexPath.row)] intValue];
      else
        row = indexPath.row;

      switch (row)
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
      NSUInteger section;
      NSUInteger row;
      if (self.missingDataDisplayStyle == GameInfoItemMissingDataDisplayStyleHide)
      {
        section = [(NSNumber*)self.detailLevelFullSections[@(indexPath.section)] intValue];
        row = [self mapEnumItemFromSection:section row:indexPath.row];
      }
      else
      {
        section = indexPath.section;
        row = indexPath.row;
      }

      switch (section)
      {
        case BasicInfoSection:
        {
          switch (row)
          {
            case GameNameItem:
              return [self gameNameCellWithTableView:tableView];
            case GameInformationItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Game information" itemValue:self.gameInformation];
            case GameDatesItem:
              return [self gameDatesCellWithTableView:tableView];
            case RulesNameItem:
              return [self value1CellWithTableView:tableView itemName:@"Rules name" itemValue:self.rulesName];
            case BoardSizeItem:
              return [self boardSizeCellWithTableView:tableView];
            case NumberOfHandicapStonesItem:
              return [self value1CellWithTableView:tableView itemName:@"Handicap" itemValue:self.numberOfHandicapStonesAsString];
            case KomiItem:
              return [self value1CellWithTableView:tableView itemName:@"Komi" itemValue:self.komiAsString];
            case GameResultItem:
              return [self gameResultCellWithTableView:tableView];
            default:
              assert(0);
              break;
          }
          break;
        }
        case ExtraInfoSection:
        {
          switch (row)
          {
            case TimeLimitInSecondsItem:
              return [self value1CellWithTableView:tableView itemName:@"Time limit" itemValue:self.timeLimitInSecondsAsString];
            case OvertimeInformationItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Overtime" itemValue:self.overtimeInformation];
            case OpeningInformationItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Opening" itemValue:self.openingInformation];
            default:
              assert(0);
              break;
          }
          break;
        }
        case PlayerInfoSection:
        {
          switch (row)
          {
            case BlackPlayerNameItem:
              return [self blackPlayerNameCellWithTableView:tableView];
            case BlackPlayerRankItem:
              return [self value1CellWithTableView:tableView itemName:@"Black rank" itemValue:self.blackPlayerRankAsString];
            case BlackPlayerTeamNameItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Black team" itemValue:self.blackPlayerTeamName];
            case WhitePlayerNameItem:
              return [self whitePlayerNameCellWithTableView:tableView];
            case WhitePlayerRankItem:
              return [self value1CellWithTableView:tableView itemName:@"White rank" itemValue:self.whitePlayerRankAsString];
            case WhitePlayerTeamNameItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"White team" itemValue:self.whitePlayerTeamName];
            default:
              assert(0);
              break;
          }
          break;
        }
        case ContextInfoSection:
        {
          switch (row)
          {
            case GameLocationItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Location" itemValue:self.gameLocation];
            case EventNameItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Event" itemValue:self.eventName];
            case RoundInformationItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Round" itemValue:self.roundInformationAsString];
            default:
              assert(0);
              break;
          }
          break;
        }
        case DataSourceInfoSection:
        {
          switch (row)
          {
            case RecorderNameItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Recorder" itemValue:self.recorderName];
            case SourceNameItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Source" itemValue:self.sourceName];
            case AnnotationAuthorItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Annotations by" itemValue:self.annotationAuthor];
            case CopyrightInformationItem:
              return [self variableHeightCellWithTableView:tableView itemName:@"Copyright" itemValue:self.copyrightInformation];
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
  [self updateItemDictionaries];
}

#pragma mark - Private API - Initialization

- (void) updateDataFromGoGameInfo
{
  SGFCGoGameInfo* goGameInfo = self.goGameInfo;
  enum GameInfoItemMissingDataDisplayStyle missingDataDisplayStyle = self.missingDataDisplayStyle;

  bool dummyHasData;

  if (goGameInfo == nil)
  {
    NSString* missingStringValue = [self stringValue:nil forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&dummyHasData];

    self.boardSizeAsString = missingStringValue;
    self.boardSize = SGFCBoardSizeInvalid;

    self.recorderName = missingStringValue;
    self.recorderNameHasData = false;
    self.sourceName = missingStringValue;
    self.sourceNameHasData = false;
    self.annotationAuthor = missingStringValue;
    self.annotationAuthorHasData = false;
    self.copyrightInformation = missingStringValue;
    self.copyrightInformationHasData = false;

    self.gameName = missingStringValue;
    self.gameNameHasData = false;
    self.gameInformation = missingStringValue;
    self.gameInformationHasData = false;
    self.gameDatesAsString = missingStringValue;
    self.gameDates = [NSArray array];
    self.gameDatesHasData = false;
    self.rulesName = missingStringValue;
    self.goRuleset = SGFCGoRulesetMake(SGFCGoRulesetTypeAGA, NO);
    self.goRulesetHasData = false;
    self.numberOfHandicapStonesAsString = missingStringValue;
    self.numberOfHandicapStones = 0;
    self.numberOfHandicapStonesHasData = false;
    self.komiAsString = missingStringValue;
    self.komi = 0.0;
    self.komiHasData = false;
    self.gameResultAsString = missingStringValue;
    self.gameResult = SGFCGameResultMake(SGFCGameResultTypeUnknownResult, SGFCWinTypeWinWithScore, 0.0, NO);
    self.gameResultHasData = false;

    self.timeLimitInSecondsAsString = missingStringValue;
    self.timeLimitInSeconds = 0.0;
    self.timeLimitInSecondsHasData = false;
    self.overtimeInformation = missingStringValue;
    self.overtimeInformationHasData = false;
    self.openingInformation = missingStringValue;
    self.openingInformationHasData = false;

    self.blackPlayerName = missingStringValue;
    self.blackPlayerNameHasData = false;
    self.blackPlayerRankAsString = missingStringValue;
    self.blackPlayerRank = SGFCGoPlayerRankMake(30, SGFCGoPlayerRankTypeKyu, SGFCGoPlayerRatingTypeUnspecified, NO);
    self.blackPlayerRankHasData = false;
    self.blackPlayerTeamName = missingStringValue;
    self.blackPlayerTeamNameHasData = false;
    self.whitePlayerName = missingStringValue;
    self.whitePlayerNameHasData = false;
    self.whitePlayerRankAsString = missingStringValue;
    self.whitePlayerRank = SGFCGoPlayerRankMake(30, SGFCGoPlayerRankTypeKyu, SGFCGoPlayerRatingTypeUnspecified, NO);
    self.whitePlayerRankHasData = false;
    self.whitePlayerTeamName = missingStringValue;
    self.whitePlayerTeamNameHasData = false;

    self.gameLocation = missingStringValue;
    self.gameLocationHasData = false;
    self.eventName = missingStringValue;
    self.eventNameHasData = false;
    self.roundInformationAsString = missingStringValue;
    self.roundInformation = SGFCRoundInformationMake(missingStringValue, missingStringValue, NO);
    self.roundInformationHasData = false;
  }
  else
  {
    self.boardSizeAsString = [self stringValue:[SgfUtilities stringForSgfBoardSize:goGameInfo.boardSize]
                    forMissingDataDisplayStyle:missingDataDisplayStyle
                                       hasData:&dummyHasData];
    self.boardSize = goGameInfo.boardSize;

    self.recorderName = [self stringValue:goGameInfo.recorderName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_recorderNameHasData];
    self.sourceName = [self stringValue:goGameInfo.sourceName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_sourceNameHasData];
    self.annotationAuthor = [self stringValue:goGameInfo.annotationAuthor forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_annotationAuthorHasData];
    self.copyrightInformation = [self stringValue:goGameInfo.copyrightInformation forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_copyrightInformationHasData];

    self.gameName = [self stringValue:goGameInfo.gameName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_gameNameHasData];
    self.gameInformation = [self stringValue:goGameInfo.gameInformation forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_gameInformationHasData];
    NSArray* dateArray;
    NSArray* stringArray;
    [SgfUtilities parseSgfGameDates:goGameInfo.gameDates dateArray:&dateArray stringArray:&stringArray];
    self.gameDatesAsString = [self stringValue:[stringArray componentsJoinedByString:@", "]
                             withFallbackValue:goGameInfo.rawGameDates
                    forMissingDataDisplayStyle:missingDataDisplayStyle
                                       hasData:&_gameDatesHasData];
    self.gameDates = dateArray;
    self.rulesName = [self stringValue:goGameInfo.rulesName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_goRulesetHasData];
    self.goRuleset = goGameInfo.goRuleset;
    NSString* formattedNumberOfHandicapStones;
    if (goGameInfo.numberOfHandicapStones != 0)
      formattedNumberOfHandicapStones = [NSString stringWithFormat:@"%ld", (long)goGameInfo.numberOfHandicapStones];
    else
      formattedNumberOfHandicapStones = @"";
    self.numberOfHandicapStonesAsString = [self stringValue:formattedNumberOfHandicapStones
                                 forMissingDataDisplayStyle:missingDataDisplayStyle
                                                    hasData:&_numberOfHandicapStonesHasData];
    self.numberOfHandicapStones = goGameInfo.numberOfHandicapStones;
    NSString* formattedKomi;
    if (goGameInfo.komi != 0.0)
      formattedKomi = [NSString stringWithFormat:@"%.1f", goGameInfo.komi];
    else
      formattedKomi = @"";
    self.komiAsString = [self stringValue:formattedKomi
               forMissingDataDisplayStyle:missingDataDisplayStyle
                                  hasData:&_komiHasData];
    self.komi = goGameInfo.komi;
    self.gameResultAsString = [self stringValue:[SgfUtilities stringForSgfGameResult:goGameInfo.gameResult]
                              withFallbackValue:goGameInfo.rawGameResult
                     forMissingDataDisplayStyle:missingDataDisplayStyle
                                        hasData:&_gameResultHasData];
    self.gameResult = goGameInfo.gameResult;

    NSString* formattedTimeLimitInSeconds;
    if (goGameInfo.timeLimitInSeconds != 0.0)
      formattedTimeLimitInSeconds = [NSString stringWithFormat:@"%.1f", goGameInfo.timeLimitInSeconds];
    else
      formattedTimeLimitInSeconds = @"";
    self.timeLimitInSecondsAsString = [self stringValue:formattedTimeLimitInSeconds
                             forMissingDataDisplayStyle:missingDataDisplayStyle
                                                hasData:&_timeLimitInSecondsHasData];
    self.timeLimitInSeconds = goGameInfo.timeLimitInSeconds;
    self.overtimeInformation = [self stringValue:goGameInfo.overtimeInformation forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_overtimeInformationHasData];
    self.openingInformation = [self stringValue:goGameInfo.openingInformation forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_openingInformationHasData];

    self.blackPlayerName = [self stringValue:goGameInfo.blackPlayerName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_blackPlayerNameHasData];
    self.blackPlayerRankAsString = [self stringValue:[SgfUtilities stringForSgfGoPlayerRank:goGameInfo.goBlackPlayerRank]
                                   withFallbackValue:goGameInfo.blackPlayerRank
                          forMissingDataDisplayStyle:missingDataDisplayStyle
                                             hasData:&_blackPlayerRankHasData];
    self.blackPlayerRank = goGameInfo.goBlackPlayerRank;
    self.blackPlayerTeamName = [self stringValue:goGameInfo.blackPlayerTeamName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_blackPlayerTeamNameHasData];
    self.whitePlayerName = [self stringValue:goGameInfo.whitePlayerName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_whitePlayerNameHasData];
    self.whitePlayerRankAsString = [self stringValue:[SgfUtilities stringForSgfGoPlayerRank:goGameInfo.goWhitePlayerRank]
                                   withFallbackValue:goGameInfo.whitePlayerRank
                          forMissingDataDisplayStyle:missingDataDisplayStyle
                                             hasData:&_whitePlayerRankHasData];
    self.whitePlayerRank = goGameInfo.goWhitePlayerRank;
    self.whitePlayerTeamName = [self stringValue:goGameInfo.whitePlayerTeamName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_whitePlayerTeamNameHasData];

    self.gameLocation = [self stringValue:goGameInfo.gameLocation forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_gameLocationHasData];
    self.eventName = [self stringValue:goGameInfo.eventName forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_eventNameHasData];
    self.roundInformationAsString = [self stringValue:goGameInfo.rawRoundInformation forMissingDataDisplayStyle:missingDataDisplayStyle hasData:&_roundInformationHasData];
    self.roundInformation = goGameInfo.roundInformation;
  }
}

- (NSString*) stringValue:(NSString*)stringValue withFallbackValue:(NSString*)fallbackValue forMissingDataDisplayStyle:(enum GameInfoItemMissingDataDisplayStyle)missingDataDisplayStyle hasData:(bool*)hasData
{
  NSString* result = [self stringValue:stringValue forMissingDataDisplayStyle:missingDataDisplayStyle hasData:hasData];

  if (! (*hasData))
    result = [self stringValue:fallbackValue forMissingDataDisplayStyle:missingDataDisplayStyle hasData:hasData];

  return result;
}

- (NSString*) stringValue:(NSString*)stringValue forMissingDataDisplayStyle:(enum GameInfoItemMissingDataDisplayStyle)missingDataDisplayStyle hasData:(bool*)hasData
{
  // If self.goGameInfo is nil we get nil values
  if (stringValue == nil || stringValue.length == 0)
  {
    *hasData = false;

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
    *hasData = true;
    return stringValue;
  }
}

- (void) updateItemDictionaries
{
  self.summarySectionItems = [NSMutableDictionary dictionary];
  NSUInteger summarySectionRow = 0;
  _summarySectionItems[@(summarySectionRow++)] = @(BoardSizeSummaryItem);
  if (self.gameNameHasData)
    _summarySectionItems[@(summarySectionRow++)] = @(GameNameSummaryItem);
  if (self.gameDatesHasData)
    _summarySectionItems[@(summarySectionRow++)] = @(GameDatesSummaryItem);
  if (self.blackPlayerNameHasData)
    _summarySectionItems[@(summarySectionRow++)] = @(BlackPlayerNameSummaryItem);
  if (self.whitePlayerNameHasData)
    _summarySectionItems[@(summarySectionRow++)] = @(WhitePlayerNameSummaryItem);
  if (self.gameResultHasData)
    _summarySectionItems[@(summarySectionRow++)] = @(GameResultSummaryItem);

  self.basicInfoSectionItems = [NSMutableDictionary dictionary];
  NSUInteger basicInfoSectionRow = 0;
  if (self.gameNameHasData)
    _basicInfoSectionItems[@(basicInfoSectionRow++)] = @(GameNameItem);
  if (self.gameInformationHasData)
    _basicInfoSectionItems[@(basicInfoSectionRow++)] = @(GameInformationItem);
  if (self.gameDatesHasData)
    _basicInfoSectionItems[@(basicInfoSectionRow++)] = @(GameDatesItem);
  if (self.goRulesetHasData)
    _basicInfoSectionItems[@(basicInfoSectionRow++)] = @(RulesNameItem);
  _basicInfoSectionItems[@(basicInfoSectionRow++)] = @(BoardSizeItem);
  if (self.numberOfHandicapStonesHasData)
    _basicInfoSectionItems[@(basicInfoSectionRow++)] = @(NumberOfHandicapStonesItem);
  if (self.komiHasData)
    _basicInfoSectionItems[@(basicInfoSectionRow++)] = @(KomiItem);
  if (self.gameResultHasData)
    _basicInfoSectionItems[@(basicInfoSectionRow++)] = @(GameResultItem);

  self.extraInfoSectionItems = [NSMutableDictionary dictionary];
  NSUInteger extraInfoSectionRow = 0;
  if (self.timeLimitInSecondsHasData)
    _extraInfoSectionItems[@(extraInfoSectionRow++)] = @(TimeLimitInSecondsItem);
  if (self.overtimeInformationHasData)
    _extraInfoSectionItems[@(extraInfoSectionRow++)] = @(OvertimeInformationItem);
  if (self.openingInformationHasData)
    _extraInfoSectionItems[@(extraInfoSectionRow++)] = @(OpeningInformationItem);
  
  self.playerInfoSectionItems = [NSMutableDictionary dictionary];
  NSUInteger playerInfoSectionRow = 0;
  if (self.blackPlayerNameHasData)
    _playerInfoSectionItems[@(playerInfoSectionRow++)] = @(BlackPlayerNameItem);
  if (self.blackPlayerRankHasData)
    _playerInfoSectionItems[@(playerInfoSectionRow++)] = @(BlackPlayerRankItem);
  if (self.blackPlayerTeamNameHasData)
    _playerInfoSectionItems[@(playerInfoSectionRow++)] = @(BlackPlayerTeamNameItem);
  if (self.whitePlayerNameHasData)
    _playerInfoSectionItems[@(playerInfoSectionRow++)] = @(WhitePlayerNameItem);
  if (self.whitePlayerRankHasData)
    _playerInfoSectionItems[@(playerInfoSectionRow++)] = @(WhitePlayerRankItem);
  if (self.whitePlayerTeamNameHasData)
    _playerInfoSectionItems[@(playerInfoSectionRow++)] = @(WhitePlayerTeamNameItem);
  
  self.contextInfoSectionItems = [NSMutableDictionary dictionary];
  NSUInteger contextInfoSectionRow = 0;
  if (self.gameLocationHasData)
    _contextInfoSectionItems[@(contextInfoSectionRow++)] = @(GameLocationItem);
  if (self.eventNameHasData)
    _contextInfoSectionItems[@(contextInfoSectionRow++)] = @(EventNameItem);
  if (self.roundInformationHasData)
    _contextInfoSectionItems[@(contextInfoSectionRow++)] = @(RoundInformationItem);

  self.dataSourceInfoSectionItems = [NSMutableDictionary dictionary];
  NSUInteger dataSourceInfoSectionRow = 0;
  if (self.recorderNameHasData)
    _dataSourceInfoSectionItems[@(dataSourceInfoSectionRow++)] = @(RecorderNameItem);
  if (self.sourceNameHasData)
    _dataSourceInfoSectionItems[@(dataSourceInfoSectionRow++)] = @(SourceNameItem);
  if (self.annotationAuthorHasData)
    _dataSourceInfoSectionItems[@(dataSourceInfoSectionRow++)] = @(AnnotationAuthorItem);
  if (self.copyrightInformationHasData)
    _dataSourceInfoSectionItems[@(dataSourceInfoSectionRow++)] = @(CopyrightInformationItem);

  self.detailLevelFullSections = [NSMutableDictionary dictionary];
  NSUInteger detailLevelFullSection = 0;
  if (basicInfoSectionRow > 0)
    _detailLevelFullSections[@(detailLevelFullSection++)] = @(BasicInfoSection);
  if (extraInfoSectionRow > 0)
    _detailLevelFullSections[@(detailLevelFullSection++)] = @(ExtraInfoSection);
  if (playerInfoSectionRow > 0)
    _detailLevelFullSections[@(detailLevelFullSection++)] = @(PlayerInfoSection);
  if (contextInfoSectionRow > 0)
    _detailLevelFullSections[@(detailLevelFullSection++)] = @(ContextInfoSection);
  if (dataSourceInfoSectionRow > 0)
    _detailLevelFullSections[@(detailLevelFullSection++)] = @(DataSourceInfoSection);
}

#pragma mark - Private API - Table view cell creation

- (NSUInteger) mapEnumItemFromSection:(NSUInteger)section row:(NSUInteger)row
{
  NSDictionary* sectionItemsDictionary = [self sectionItemsDictionaryForSection:section];
  return [(NSNumber*)sectionItemsDictionary[@(row)] intValue];
}

- (NSDictionary*) sectionItemsDictionaryForSection:(NSUInteger)section
{
  switch (section)
  {
    case BasicInfoSection:
    {
      return _basicInfoSectionItems;
    }
    case ExtraInfoSection:
    {
      return _extraInfoSectionItems;
    }
    case PlayerInfoSection:
    {
      return _playerInfoSectionItems;
    }
    case ContextInfoSection:
    {
      return _contextInfoSectionItems;
    }
    case DataSourceInfoSection:
    {
      return _dataSourceInfoSectionItems;
    }
    default:
    {
      assert(0);
      return nil;
    }
  }
}

- (UITableViewCell*) boardSizeCellWithTableView:(UITableView*)tableView
{
  return [self value1CellWithTableView:tableView itemName:@"Board size" itemValue:self.boardSizeAsString];
}

- (UITableViewCell*) gameNameCellWithTableView:(UITableView*)tableView
{
  return [self variableHeightCellWithTableView:tableView itemName:@"Game name" itemValue:self.gameName];
}

- (UITableViewCell*) gameDatesCellWithTableView:(UITableView*)tableView
{
  return [self variableHeightCellWithTableView:tableView itemName:@"Dates" itemValue:self.gameDatesAsString];
}

- (UITableViewCell*) blackPlayerNameCellWithTableView:(UITableView*)tableView
{
  return [self variableHeightCellWithTableView:tableView itemName:@"Black" itemValue:self.blackPlayerName];
}

- (UITableViewCell*) whitePlayerNameCellWithTableView:(UITableView*)tableView
{
  return [self variableHeightCellWithTableView:tableView itemName:@"White" itemValue:self.whitePlayerName];
}

- (UITableViewCell*) gameResultCellWithTableView:(UITableView*)tableView
{
  return [self variableHeightCellWithTableView:tableView itemName:@"Result" itemValue:self.gameResultAsString];
}

- (UITableViewCell*) value1CellWithTableView:(UITableView*)tableView itemName:(NSString*)itemName itemValue:(NSString*)itemValue
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  cell.textLabel.text = itemName;
  cell.detailTextLabel.text = itemValue;
  return cell;
}

- (UITableViewCell*) variableHeightCellWithTableView:(UITableView*)tableView itemName:(NSString*)itemName itemValue:(NSString*)itemValue
{
  TableViewVariableHeightCell* cell = (TableViewVariableHeightCell*)[TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
  cell.descriptionLabel.text = itemName;
  cell.valueLabel.text = itemValue;
  cell.descriptionLabelWidthPercentage = self.descriptionLabelWidthPercentageForVariableHeightCells;
  return cell;
}

@end
