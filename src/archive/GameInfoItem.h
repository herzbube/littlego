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


/// @brief Enumerates the levels of details that can be used to display the data
/// in a GameInfoItem.
enum GameInfoItemDetailLevel
{
  /// @brief The GameInfoItem data is displayed as a single item.
  GameInfoItemDetailLevelSingleItem,

  /// @brief The GameInfoItem data is displayed in summarized form.
  GameInfoItemDetailLevelSummary,

  /// @brief All of the GameInfoItem data is displayed in full.
  GameInfoItemDetailLevelFull,
};

/// @brief Enumerates the styles with which missing data points in GameInfoItem
/// can be displayed.
enum GameInfoItemMissingDataDisplayStyle
{
  /// @brief Missing data points are hidden. For instance, in a UITableView no
  /// rows are generated for missing data points.
  GameInfoItemMissingDataDisplayStyleHide,

  /// @brief Missing data points are represented with a short text indicating
  /// there is no data for the data point is.
  GameInfoItemMissingDataDisplayStyleShowAsNoData,

  /// @brief Missing data points are represented with an empty text.
  GameInfoItemMissingDataDisplayStyleShowAsEmpty,
};

// -----------------------------------------------------------------------------
/// @brief The GameInfoItem class collects data used to represent one of the
/// potentially many games stored inside an SGF file.
///
/// GameInfoItem can be used in one of two major forms, which one is determined
/// by the way how GameInfoItem is initialized.
///
/// - Form 1: GameInfoItem is initialized with an SGFCGoGameInfo object.
///   GameInfoItem processes the data in the SGFCGoGameInfo object and makes it
///   available in a stringified format suitable for display in the UI.
/// - Form 2: GameInfoItem is initialized with a single descriptive text.
///   GameInfoItem in this case serves as a placeholder for a game stored inside
///   an SGF file. This is intended for representing games in the UI that cannot
///   be processed by the app. Typical scenarios are: a game that is not a Go
///   game, or a game that uses a board size that is not supported by the app.
///   GameInfoItem objects initialized with a descriptive text ignore
///   GameInfoItemDetailLevel (see below).
///
/// Clients can freely use the properties of GameInfoItem to display whatever
/// data they want in the UI in whatever way they choose.
///
/// GameInfoItem also provides methods resembling those in the
/// UITableViewDataSource protocol to facilitate the display of its data in a
/// UITableView. These methods use the same signature as the
/// UITableViewDataSource protocol methods, but have an additional
/// GameInfoItemDetailLevel argument. A client that adopts the
/// UITableViewDataSource protocol (typically a UITableViewController) can
/// forward the calls it receives to GameInfoItem and add the desired
/// GameInfoItemDetailLevel value. GameInfoItem reacts by returning different
/// section or row numbers depending on how much level of detail the client
/// desired.
///
/// Different clients that use the same GameInfoItem as a data source at the
/// same time (e.g. overlapping table view controllers) can query GameInfoItem
/// with different detail levels. The same client, however, obviously must use
/// a consistent detail level across all of its queries to receive consistent
/// results.
///
/// @note Which data points make up a given detail level is currently hardcoded
/// into GameInfoItem. If it seems useful in the future GameInfoItem can be
/// extended to support a mechanism with which a client can choose between
/// data points.
// -----------------------------------------------------------------------------
@interface GameInfoItem : NSObject
{
}

/// @name Allocation and initialization
//@{
+ (GameInfoItem*) gameInfoItemWithGoGameInfo:(SGFCGoGameInfo*)goGameInfo titleText:(NSString*)titleText;
+ (GameInfoItem*) gameInfoItemWithDescriptiveText:(NSString*)descriptiveText titleText:(NSString*)titleText;

- (id) initWithGoGameInfo:(SGFCGoGameInfo*)goGameInfo titleText:(NSString*)titleText;
- (id) initWithDescriptiveText:(NSString*)descriptiveText titleText:(NSString*)titleText;
//@}

/// @name UITableView support
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView detailLevel:(enum GameInfoItemDetailLevel)detailLevel;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section detailLevel:(enum GameInfoItemDetailLevel)detailLevel;
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section detailLevel:(enum GameInfoItemDetailLevel)detailLevel;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath detailLevel:(enum GameInfoItemDetailLevel)detailLevel;
//@}

/// @name Initializer data
//@{
/// @brief The SGFCGoGameInfo object used to initialize the GameInfoItem. Is
/// @e nil if GameInfoItem was initialized with a descriptive text.
@property(nonatomic, retain, readonly) SGFCGoGameInfo* goGameInfo;

/// @brief The descriptive text used to initialize the GameInfoItem. Is
/// @e nil if GameInfoItem was initialized with an SGFCGoGameInfo object.
@property(nonatomic, retain, readonly) NSString* descriptiveText;

/// @brief The title text to be used when the GameInfoItem was initialized with
/// a descriptive text, or when the GameInfoItem was initialized with a
/// SGFCGoGameInfo object and the single item or summary detail levels are used
/// to display the GameInfoItem's data.
@property(nonatomic, retain, readonly) NSString* titleText;
//@}

/// @name Customization
//@{
/// @brief The style that the GameInfoItem should use to display missing data
/// points. The default is #GameInfoItemMissingDataDisplayStyleHide.
@property(nonatomic, assign) enum GameInfoItemMissingDataDisplayStyle missingDataDisplayStyle;
//@}

/// @name Root property data
//@{
/// @brief The string representation of the board size, based on the data that
/// appears in the SGF property SZ. This data point is never missing.
@property(nonatomic, retain, readonly) NSString* boardSizeAsString;
/// @brief The board size, based on the data that appears in the SGF property
/// SZ. This data point is never missing.
@property(nonatomic, assign, readonly) SGFCBoardSize boardSize;
//@}

/// @name Data source information
//@{
/// @brief The name of the user (or program) who recorded or entered the game
/// data, exactly as it appears in the SGF property US.
@property(nonatomic, retain, readonly) NSString* recorderName;
/// @brief Indicates whether the property @e recorderName has data.
@property(nonatomic, assign, readonly) bool recorderNameHasData;

/// @brief The name of the source of the game data (e.g. book, journal, etc.),
/// exactly as it appears in the SGF property SO.
@property(nonatomic, retain, readonly) NSString* sourceName;
/// @brief Indicates whether the property @e sourceName has data.
@property(nonatomic, assign, readonly) bool sourceNameHasData;

/// @brief The name of the person who made the annotations to the game, exactly
/// as it appears in the SGF property AN.
@property(nonatomic, retain, readonly) NSString* annotationAuthor;
/// @brief Indicates whether the property @e annotationAuthor has data.
@property(nonatomic, assign, readonly) bool annotationAuthorHasData;

/// @brief The copyright information for the game data (including the
/// annotations), exactly as it appears in the SGF property CP.
@property(nonatomic, retain, readonly) NSString* copyrightInformation;
/// @brief Indicates whether the property @e copyrightInformation has data.
@property(nonatomic, assign, readonly) bool copyrightInformationHasData;
//@}

/// @name Basic game information
//@{
/// @brief The name of the game (e.g. for easily finding the game again within
/// a collection), exactly as it appears in the SGF property GN.
@property(nonatomic, retain, readonly) NSString* gameName;
/// @brief Indicates whether the property @e gameName has data.
@property(nonatomic, assign, readonly) bool gameNameHasData;

/// @brief Information about the game (e.g. background information, a game
/// summary, etc.), exactly as it appears in the SGF property GC.
@property(nonatomic, retain, readonly) NSString* gameInformation;
/// @brief Indicates whether the property @e gameInformation has data.
@property(nonatomic, assign, readonly) bool gameInformationHasData;

/// @brief The string representation of the list of dates when the game was
/// played, based on the data that appears in the SGF property DT.
///
/// If the interpretation of the data in the SGF property DT succeeds, the dates
/// appear formatted according to the user's locale and using the "short" date
/// style. Unlike the SGF data, which allows the specification of partial dates,
/// all dates in this property appear as full dates.
///
/// If the interpretation of the data in the SGF property DT fails this property
/// contains the raw value, exactly as it appears in the SGF property DT.
@property(nonatomic, retain, readonly) NSString* gameDatesAsString;
/// @brief The dates when the game was played, based on the data that appears
/// in the SGF property DT. The array contains NSDate objects.
///
/// If the interpretation of the data in the SGF property DT fails this property
/// contains an empty array.
@property(nonatomic, retain, readonly) NSArray* gameDates;
/// @brief Indicates whether the properties @e gameDatesAsString and
/// @e gameDates have data.
@property(nonatomic, assign, readonly) bool gameDatesHasData;

/// @brief The Go ruleset used for the game, exactly as it appears in the SGF
/// property RU.
@property(nonatomic, retain, readonly) NSString* rulesName;
/// @brief The Go ruleset used for the game, based on the data that appears in
/// the SGF property RU.
///
/// If the interpretation of the data in the SGF property DT fails the returned
/// SGFCGoRuleset has the @e IsValid property set to NO.
@property(nonatomic, assign, readonly) SGFCGoRuleset goRuleset;
/// @brief Indicates whether the properties @e rulesName and @e goRuleset have
/// data.
@property(nonatomic, assign, readonly) bool goRulesetHasData;

/// @brief The number of handicap stones, exactly as it appears in the SGF
/// property HA.
@property(nonatomic, retain, readonly) NSString* numberOfHandicapStonesAsString;
/// @brief The number of handicap stones, based on the data that appears in the
/// SGF property HA.
///
/// If the interpretation of the data in the SGF property HA fails this
/// property has the value 0.
@property(nonatomic, assign, readonly) SGFCNumber numberOfHandicapStones;
/// @brief Indicates whether the properties @e numberOfHandicapStonesAsString
/// and @e numberOfHandicapStones have data.
@property(nonatomic, assign, readonly) bool numberOfHandicapStonesHasData;

/// @brief The komi value, exactly as it appears in the SGF property KM.
@property(nonatomic, retain, readonly) NSString* komiAsString;
/// @brief The komi value, based on the data that appears in the SGF property
/// KM.
///
/// If the interpretation of the data in the SGF property KM fails this
/// property has the value 0.0.
@property(nonatomic, assign, readonly) SGFCReal komi;
/// @brief Indicates whether the properties @e komiAsString and @e komi have
/// data.
@property(nonatomic, assign, readonly) bool komiHasData;

/// @brief The string representation of the game result, based on the data that
/// appears in the SGF property RE.
///
/// If the interpretation of the data in the SGF property RE succeeds, the
/// result appears formatted as a human-readable string without cryptic
/// abbreviations.
///
/// If the interpretation of the data in the SGF property RE fails this property
/// contains the raw value, exactly as it appears in the SGF property RE.
@property(nonatomic, retain, readonly) NSString* gameResultAsString;
/// @brief The game result, based on the data that appears in the SGF property
/// RE.
///
/// If the interpretation of the data in the SGF property RE fails the returned
/// SGFCGameResult has the @e IsValid property set to NO.
@property(nonatomic, assign, readonly) SGFCGameResult gameResult;
/// @brief Indicates whether the properties @e gameResultAsString and
/// @e gameResult have data.
@property(nonatomic, assign, readonly) bool gameResultHasData;
//@}

/// @name Extra game information
//@{
/// @brief The time limit of the game in seconds, exactly as it appears in the
/// SGF property TM.
@property(nonatomic, retain, readonly) NSString* timeLimitInSecondsAsString;
/// @brief The time limit of the game in seconds, based on the data that appears
/// in the SGF property TM.
///
/// If the interpretation of the data in the SGF property TM fails this
/// property has the value 0.0.
@property(nonatomic, assign, readonly) SGFCReal timeLimitInSeconds;
/// @brief Indicates whether the properties @e timeLimitInSecondsAsString and
/// @e timeLimitInSeconds have data.
@property(nonatomic, assign, readonly) bool timeLimitInSecondsHasData;

/// @brief The description of the method used for overtime (byo-yomi), exactly
/// as it appears in the SGF property OT.
@property(nonatomic, retain, readonly) NSString* overtimeInformation;
/// @brief Indicates whether the property @e overtimeInformation has data.
@property(nonatomic, assign, readonly) bool overtimeInformationHasData;

/// @brief Information about the opening played, exactly as it appears in the
/// SGF property ON.
@property(nonatomic, retain, readonly) NSString* openingInformation;
/// @brief Indicates whether the property @e openingInformation has data.
@property(nonatomic, assign, readonly) bool openingInformationHasData;
//@}

/// @name Player information
//@{
/// @brief The name of the black player, exactly as it appears in the SGF
/// property PB.
@property(nonatomic, retain, readonly) NSString* blackPlayerName;
/// @brief Indicates whether the property @e blackPlayerName has data.
@property(nonatomic, assign, readonly) bool blackPlayerNameHasData;

/// @brief The rank of the black player, exactly as it appears in the SGF
/// property BR.
@property(nonatomic, retain, readonly) NSString* blackPlayerRankAsString;
/// @brief The rank of the black player, based on the data that appears in the
/// SGF property BR.
///
/// If the interpretation of the data in the SGF property BR fails the returned
/// SGFCGoPlayerRank has the @e IsValid property set to NO.
@property(nonatomic, assign, readonly) SGFCGoPlayerRank blackPlayerRank;
/// @brief Indicates whether the properties @e blackPlayerRankAsString and
/// @e blackPlayerRank have data.
@property(nonatomic, assign, readonly) bool blackPlayerRankHasData;

/// @brief The name of the black player's team, exactly as it appears in the SGF
/// property BT.
@property(nonatomic, retain, readonly) NSString* blackPlayerTeamName;
/// @brief Indicates whether the property @e blackPlayerTeamName has data.
@property(nonatomic, assign, readonly) bool blackPlayerTeamNameHasData;

/// @brief The name of the white player, exactly as it appears in the SGF
/// property PW.
@property(nonatomic, retain, readonly) NSString* whitePlayerName;
/// @brief Indicates whether the property @e whitePlayerName has data.
@property(nonatomic, assign, readonly) bool whitePlayerNameHasData;

/// @brief The rank of the white player, exactly as it appears in the SGF
/// property WR.
@property(nonatomic, retain, readonly) NSString* whitePlayerRankAsString;
/// @brief The rank of the white player, based on the data that appears in the
/// SGF property WR.
///
/// If the interpretation of the data in the SGF property WR fails the returned
/// SGFCGoPlayerRank has the @e IsValid property set to NO.
@property(nonatomic, assign, readonly) SGFCGoPlayerRank whitePlayerRank;
/// @brief Indicates whether the properties @e whitePlayerRankAsString and
/// @e whitePlayerRank have data.
@property(nonatomic, assign, readonly) bool whitePlayerRankHasData;

/// @brief The name of the white player's team, exactly as it appears in the SGF
/// property WT.
@property(nonatomic, retain, readonly) NSString* whitePlayerTeamName;
/// @brief Indicates whether the property @e whitePlayerTeamName has data.
@property(nonatomic, assign, readonly) bool whitePlayerTeamNameHasData;
//@}

/// @name Context in which the game was played
//@{
/// @brief The name or description of the location where the game was played,
/// exactly as it appears in the SGF property PC.
@property(nonatomic, retain, readonly) NSString* gameLocation;
/// @brief Indicates whether the property @e gameLocation has data.
@property(nonatomic, assign, readonly) bool gameLocationHasData;

/// @brief The name of the event (e.g. tournament) where the game was played,
/// exactly as it appears in the SGF property EV.
@property(nonatomic, retain, readonly) NSString* eventName;
/// @brief Indicates whether the property @e eventName has data.
@property(nonatomic, assign, readonly) bool eventNameHasData;

/// @brief The information that describes the round in which the
/// game was played, exactly as it appears in the SGF property RO.
@property(nonatomic, retain, readonly) NSString* roundInformationAsString;
/// @brief The information that describes the round in which the
/// game was played, based on the data that appears in the SGF property RO.
///
/// If the interpretation of the data in the SGF property RO fails the returned
/// SGFCRoundInformation has the @e IsValid property set to NO.
@property(nonatomic, assign, readonly) SGFCRoundInformation roundInformation;
/// @brief Indicates whether the properties @e roundInformationAsString and
/// @e roundInformation have data.
@property(nonatomic, assign, readonly) bool roundInformationHasData;
//@}

@end
