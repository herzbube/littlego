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


// GUI constants
const float gHalfPixel = 0.5;
const int crossHairPointDistanceFromFingerOnSmallestBoard = 2;

// Go constants
const enum GoBoardSize gDefaultBoardSize = GoBoardSize19;
const int gNumberOfBoardSizes = (GoBoardSizeMax - GoBoardSizeMin) / 2 + 1;

// Filesystem related constants
NSString* sgfTemporaryFileName = @"---tmp+++.sgf";
NSString* sgfBackupFileName = @"backup.sgf";

// Application notifications
NSString* applicationIsReadyForAction = @"ApplicationIsReadyForAction";
// GTP notifications
NSString* gtpCommandWillBeSubmittedNotification = @"GtpCommandWillBeSubmitted";
NSString* gtpResponseWasReceivedNotification = @"GtpResponseWasReceived";
NSString* gtpEngineRunningNotification = @"GtpEngineRunning";
NSString* gtpEngineIdleNotification = @"GtpEngineIdle";
// GoGame notifications
NSString* goGameWillCreate = @"GoGameWillCreate";
NSString* goGameDidCreate = @"GoGameDidCreate";
NSString* goGameStateChanged = @"GoGameStateChanged";
NSString* goGameFirstMoveChanged = @"GoGameFirstMoveChanged";
NSString* goGameLastMoveChanged = @"GoGameLastMoveChanged";
// Computer player notifications
NSString* computerPlayerThinkingStarts = @"ComputerPlayerThinkingStarts";
NSString* computerPlayerThinkingStops = @"ComputerPlayerThinkingStops";
// Archive related notifications
NSString* gameSavedToArchive = @"GameSavedToArchive";
NSString* gameLoadedFromArchive = @"GameLoadedFromArchive";
NSString* archiveContentChanged = @"ArchiveContentChanged";
// GTP log related notifications
NSString* gtpLogContentChanged = @"GtpLogContentChanged";
NSString* gtpLogItemChanged = @"GtpLogItemChanged";
// Scoring related notifications
NSString* goScoreScoringModeEnabled = @"GoScoreScoringModeEnabled";
NSString* goScoreScoringModeDisabled = @"GoScoreScoringModeDisabled";
NSString* goScoreCalculationStarts = @"goScoreCalculationStarts";
NSString* goScoreCalculationEnds = @"goScoreCalculationEnds";

/// GTP engine profile default values
const int fuegoMaxMemoryMinimum = 16;
const int fuegoMaxMemoryMaximum = 512;
const int fuegoMaxMemoryDefault = 32;
const int fuegoThreadCountMinimum = 1;
const int fuegoThreadCountMaximum = 8;
const int fuegoThreadCountDefault = 1;
const bool fuegoPonderingDefault = true;
const bool fuegoReuseSubtreeDefault = true;
NSString* defaultGtpEngineProfileUUID = @"5154D01A-1292-453F-B767-BE7389E3589F";

// Debug view settings default values
const int gtpLogSizeMinimum = 5;
const int gtpLogSizeMaximum = 1000;

// Resource file names
NSString* openingBookResource = @"book.dat";
NSString* aboutDocumentResource = @"About.html";
NSString* sourceCodeDocumentResource = @"SourceCode.html";
NSString* apacheLicenseDocumentResource = @"LICENSE.html";
NSString* GPLDocumentResource = @"COPYING.html";
NSString* LGPLDocumentResource = @"COPYING.LESSER.html";
NSString* boostLicenseDocumentResource = @"BoostSoftwareLicense.html";
NSString* readmeDocumentResource = @"README";
NSString* manualDocumentResource = @"MANUAL";
NSString* creditsDocumentResource = @"Credits.html";
NSString* registrationDomainDefaultsResource = @"RegistrationDomainDefaults.plist";
NSString* playStoneSoundFileResource = @"wood-on-wood-12.aiff";
NSString* playForMeButtonIconResource = @"computer-play.png";
NSString* passButtonIconResource = @"gopass.png";
NSString* undoButtonIconResource = @"213-reply.png";
NSString* pauseButtonIconResource = @"48-pause.png";
NSString* continueButtonIconResource = @"49-play.png";
NSString* gameInfoButtonIconResource = @"tabular.png";

// Constants (mostly keys) for user defaults
// Device-specific suffixes
NSString* iPhoneDeviceSuffix = @"~iphone";
NSString* iPadDeviceSuffix = @"~ipad";
// User Defaults versioning
NSString* userDefaultsVersionRegistrationDomainKey = @"UserDefaultsVersionRegistrationDomain";
NSString* userDefaultsVersionApplicationDomainKey = @"UserDefaultsVersionApplicationDomain";
// Play view settings
NSString* playViewKey = @"PlayView";
NSString* markLastMoveKey = @"MarkLastMove";
NSString* displayCoordinatesKey = @"DisplayCoordinates";
NSString* displayMoveNumbersKey = @"DisplayMoveNumbers";
NSString* playSoundKey = @"PlaySound";
NSString* vibrateKey = @"Vibrate";
NSString* backgroundColorKey = @"BackgroundColor";
NSString* boardColorKey = @"BoardColor";
NSString* boardOuterMarginPercentageKey = @"BoardOuterMarginPercentage";
NSString* lineColorKey = @"LineColor";
NSString* boundingLineWidthKey = @"BoundingLineWidth";
NSString* normalLineWidthKey = @"NormalLineWidth";
NSString* starPointColorKey = @"StarPointColor";
NSString* starPointRadiusKey = @"StarPointRadius";
NSString* stoneRadiusPercentageKey = @"StoneRadiusPercentage";
NSString* crossHairColorKey = @"CrossHairColor";
NSString* placeStoneUnderFingerKey = @"PlaceStoneUnderFinger";
// New game settings
NSString* newGameKey = @"NewGame";
NSString* boardSizeKey = @"BoardSize";
NSString* blackPlayerKey = @"BlackPlayer";
NSString* whitePlayerKey = @"WhitePlayer";
NSString* handicapKey = @"Handicap";
NSString* komiKey = @"Komi";
// Players
NSString* playerListKey = @"PlayerList";
NSString* playerUUIDKey = @"UUID";
NSString* playerNameKey = @"Name";
NSString* isHumanKey = @"IsHuman";
NSString* gtpEngineProfileReferenceKey = @"GtpEngineProfileUUID";
NSString* statisticsKey = @"Statistics";
NSString* gamesPlayedKey = @"GamesPlayed";
NSString* gamesWonKey = @"GamesWon";
NSString* gamesLostKey = @"GamesLost";
NSString* gamesTiedKey = @"GamesTied";
NSString* starPointsKey = @"StarPoints";
// GTP engine profiles
NSString* gtpEngineProfileListKey = @"GtpEngineProfileList";
NSString* gtpEngineProfileUUIDKey = @"UUID";
NSString* gtpEngineProfileNameKey = @"Name";
NSString* gtpEngineProfileDescriptionKey = @"Description";
NSString* fuegoMaxMemoryKey = @"FuegoMaxMemory";
NSString* fuegoThreadCountKey = @"FuegoThreadCount";
NSString* fuegoPonderingKey = @"FuegoPondering";
NSString* fuegoReuseSubtreeKey = @"FuegoReuseSubtree";
// Archive view settings
NSString* archiveViewKey = @"ArchiveView";
NSString* sortCriteriaKey = @"SortCriteria";
NSString* sortAscendingKey = @"SortAscending";
// GTP Log view settings
NSString* gtpLogViewKey = @"GtpLogView";
NSString* gtpLogSizeKey = @"GtpLogSize";
NSString* gtpLogViewFrontSideIsVisibleKey = @"GtpLogViewFrontSideIsVisible";
// GTP canned commands settings
NSString* gtpCannedCommandsKey = @"GtpCannedCommands";
// Scoring settings
NSString* scoringKey = @"Scoring";
NSString* askGtpEngineForDeadStonesKey = @"AskGtpEngineForDeadStones";
NSString* markDeadStonesIntelligentlyKey = @"MarkDeadStonesIntelligently";
NSString* alphaTerritoryColorBlackKey = @"AlphaTerritoryColorBlack";
NSString* alphaTerritoryColorWhiteKey = @"AlphaTerritoryColorWhite";
NSString* deadStoneSymbolColorKey = @"DeadStoneSymbolColor";
NSString* deadStoneSymbolPercentageKey = @"DeadStoneSymbolPercentage";
NSString* inconsistentTerritoryMarkupTypeKey = @"InconsistentTerritoryMarkupType";
NSString* inconsistentTerritoryDotSymbolColorKey = @"InconsistentTerritoryDotSymbolColor";
NSString* inconsistentTerritoryDotSymbolPercentageKey = @"InconsistentTerritoryDotSymbolPercentage";
NSString* inconsistentTerritoryFillColorKey = @"InconsistentTerritoryFillColor";
NSString* inconsistentTerritoryFillColorAlphaKey = @"InconsistentTerritoryFillColorAlpha";

// Constants for NSCoding
// General constants
const int nscodingVersion = 1;
NSString* nscodingVersionKey = @"NSCodingVersion";
// GoGame keys
NSString* goGameTypeKey = @"Type";
NSString* goGameBoardKey = @"Board";
NSString* goGameHandicapPointsKey = @"HandicapPoints";
NSString* goGameKomiKey = @"Komi";
NSString* goGamePlayerBlackKey = @"PlayerBlack";
NSString* goGamePlayerWhiteKey = @"PlayerWhite";
NSString* goGameFirstMoveKey = @"FirstMove";
NSString* goGameLastMoveKey = @"LastMove";
NSString* goGameStateKey = @"State";
NSString* goGameReasonForGameHasEndedKey = @"ReasonForGameHasEnded";
NSString* goGameIsComputerThinkingKey = @"IsComputerThinking";
NSString* goGameNextMoveIsComputerGeneratedKey = @"NextMoveIsComputerGenerated";
// GoPlayer keys
NSString* goPlayerPlayerKey = @"Player";
NSString* goPlayerIsBlackKey = @"IsBlack";
// GoMove keys
NSString* goMoveTypeKey = @"Type";
NSString* goMovePlayerKey = @"Player";
NSString* goMovePointKey = @"Point";
NSString* goMovePreviousKey = @"Previous";
NSString* goMoveNextKey = @"Next";
NSString* goMoveCapturedStonesKey = @"CapturedStones";
NSString* goMoveComputerGeneratedKey = @"ComputerGenerated";
// GoBoard keys
NSString* goBoardSizeKey = @"Size";
NSString* goBoardVertexDictKey = @"VertexDict";
NSString* goBoardStarPointsKey = @"StarPoints";
// GoBoardRegion keys
NSString* goBoardRegionPointsKey = @"Points";
NSString* goBoardRegionRandomColorKey = @"RandomColor";
NSString* goBoardRegionScoringModeKey = @"ScoringMode";
NSString* goBoardRegionTerritoryColorKey = @"TerritoryColor";
NSString* goBoardRegionTerritoryInconsistencyFoundKey = @"TerritoryInconsistencyFound";
NSString* goBoardRegionDeadStoneGroupKey = @"DeadStoneGroup";
NSString* goBoardRegionCachedSizeKey = @"CachedSize";
NSString* goBoardRegionCachedIsStoneGroupKey = @"CachedIsStoneGroup";
NSString* goBoardRegionCachedColorKey = @"CachedColor";
NSString* goBoardRegionCachedLibertiesKey = @"CachedLiberties";
NSString* goBoardRegionCachedAdjacentRegionsKey = @"CachedAdjacentRegions";
// GoPoint keys
NSString* goPointVertexKey = @"Vertex";
NSString* goPointBoardKey = @"Board";
NSString* goPointLeftKey = @"Left";
NSString* goPointRightKey = @"Right";
NSString* goPointAboveKey = @"Above";
NSString* goPointBelowKey = @"Below";
NSString* goPointNeighboursKey = @"Neighbours";
NSString* goPointNextKey = @"Next";
NSString* goPointPreviousKey = @"Previous";
NSString* goPointIsStarPointKey = @"IsStarPoint";
NSString* goPointStoneStateKey = @"StoneState";
NSString* goPointRegionKey = @"Region";
NSString* goPointIsLeftValidKey = @"IsLeftValid";
NSString* goPointIsRightValidKey = @"IsRightValid";
NSString* goPointIsAboveValidKey = @"IsAboveValid";
NSString* goPointIsBelowValidKey = @"IsBelowValid";
NSString* goPointIsNextValidKey = @"IsNextValid";
NSString* goPointIsPreviousValidKey = @"IsPreviousValid";
// GoVertex keys
NSString* goVertexStringKey = @"String";
NSString* goVertexNumericXKey = @"NumericX";
NSString* goVertexNumericYKey = @"NumericY";
// GoScore keys
NSString* goScoreTerritoryScoresAvailableKey = @"TerritoryScoresAvailable";
NSString* goScoreScoringInProgressKey = @"ScoringInProgress";
NSString* goScoreKomiKey = @"Komi";
NSString* goScoreCapturedByBlackKey = @"CapturedByBlack";
NSString* goScoreCapturedByWhiteKey = @"CapturedByWhite";
NSString* goScoreDeadBlackKey = @"DeadBlack";
NSString* goScoreDeadWhiteKey = @"DeadWhite";
NSString* goScoreTerritoryBlackKey = @"TerritoryBlack";
NSString* goScoreTerritoryWhiteKey = @"TerritoryWhite";
NSString* goScoreTotalScoreBlackKey = @"TotalScoreBlack";
NSString* goScoreTotalScoreWhiteKey = @"TotalScoreWhite";
NSString* goScoreResultKey = @"Result";
NSString* goScoreNumberOfMovesKey = @"NumberOfMoves";
NSString* goScoreStonesPlayedByBlackKey = @"StonesPlayedByBlack";
NSString* goScoreStonesPlayedByWhiteKey = @"StonesPlayedByWhite";
NSString* goScorePassesPlayedByBlackKey = @"PassesPlayedByBlack";
NSString* goScorePassesPlayedByWhiteKey = @"PassesPlayedByWhite";
NSString* goScoreGameKey = @"Game";
NSString* goScoreBoardIsInitializedKey = @"BoardIsInitialized";
NSString* goScoreLastCalculationHadErrorKey = @"LastCalculationHadError";
NSString* goScoreAllRegionsKey = @"AllRegions";
// GtpLogItem keys
NSString* gtpLogItemCommandStringKey = @"CommandString";
NSString* gtpLogItemTimeStampKey = @"TimeStamp";
NSString* gtpLogItemHasResponseKey = @"HasResponse";
NSString* gtpLogItemResponseStatusKey = @"ResponseStatus";
NSString* gtpLogItemParsedResponseStringKey = @"ParsedResponseString";
NSString* gtpLogItemRawResponseStringKey = @"RawResponseString";
