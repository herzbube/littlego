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


// GUI constants
const float gHalfPixel = 0.5;
const float gDisabledViewAlpha = 0.439216f;
const CFTimeInterval gPlayViewLongPressDelay = 0.1;
const int indexOfMoreNavigationController = 0x7fffffff;
const int defaultSelectedTabIndex = 0;
const int arraySizeDefaultTabOrder = 9;
const int defaultTabOrder[arraySizeDefaultTabOrder] = {0, 1, 2, 4, 3, 5, 6, 7, 8};

// Logging constants
const int ddLogLevel = LOG_LEVEL_VERBOSE;

// Go constants
const enum GoGameType gDefaultGameType = GoGameTypeComputerVsHuman;
const enum GoBoardSize gDefaultBoardSize = GoBoardSize19;
const int gNumberOfBoardSizes = (GoBoardSizeMax - GoBoardSizeMin) / 2 + 1;
const bool gDefaultComputerPlaysWhite = true;
const int gDefaultHandicap = 0;
const double gDefaultKomi = 6.5;

// Filesystem related constants
NSString* sgfTemporaryFileName = @"---tmp+++.sgf";
NSString* archiveBackupFileName = @"backup.plist";
NSString* sgfBackupFileName = @"backup.sgf";
NSString* inboxFolderName = @"Inbox";

// GTP notifications
NSString* gtpCommandWillBeSubmittedNotification = @"GtpCommandWillBeSubmitted";
NSString* gtpResponseWasReceivedNotification = @"GtpResponseWasReceived";
NSString* gtpEngineRunningNotification = @"GtpEngineRunning";
NSString* gtpEngineIdleNotification = @"GtpEngineIdle";
// GoGame notifications
NSString* goGameWillCreate = @"GoGameWillCreate";
NSString* goGameDidCreate = @"GoGameDidCreate";
NSString* goGameStateChanged = @"GoGameStateChanged";
// Computer player notifications
NSString* computerPlayerThinkingStarts = @"ComputerPlayerThinkingStarts";
NSString* computerPlayerThinkingStops = @"ComputerPlayerThinkingStops";
// Archive related notifications
NSString* archiveContentChanged = @"ArchiveContentChanged";
// GTP log related notifications
NSString* gtpLogContentChanged = @"GtpLogContentChanged";
NSString* gtpLogItemChanged = @"GtpLogItemChanged";
// Scoring related notifications
NSString* goScoreTerritoryScoringEnabled = @"GoScoreTerritoryScoringEnabled";
NSString* goScoreTerritoryScoringDisabled = @"GoScoreTerritoryScoringDisabled";
NSString* goScoreCalculationStarts = @"GoScoreCalculationStarts";
NSString* goScoreCalculationEnds = @"GoScoreCalculationEnds";
NSString* askGtpEngineForDeadStonesStarts = @"AskGtpEngineForDeadStonesStarts";
NSString* askGtpEngineForDeadStonesEnds = @"AskGtpEngineForDeadStonesEnds";
// Other notifications
NSString* longRunningActionStarts = @"LongRunningActionStarts";
NSString* longRunningActionEnds = @"LongRunningActionEnds";
NSString* boardPositionChangeProgress = @"BoardPositionChangeProgress";
NSString* playersAndProfilesWillReset = @"PlayersAndProfilesWillReset";
NSString* playersAndProfilesDidReset = @"PlayersAndProfilesDidReset";

// Play view settings default values
const float maximumZoomScaleDefault = 3.0;
const float maximumZoomScaleMaximum = 3.0;
const float stoneDistanceFromFingertipDefault = 0.5;
const float moveNumbersPercentageDefault = 0.0;

// Board position settings default values
const bool discardFutureMovesAlertDefault = true;
const bool markNextMoveDefault = true;

/// GTP engine profile constants
const int minimumPlayingStrength = 1;
const int maximumPlayingStrength = 5;
const int customPlayingStrength = 0;
const int defaultPlayingStrength = 3;
const int minimumResignBehaviour = 1;
const int maximumResignBehaviour = 5;
const int customResignBehaviour = 0;
const int defaultResignBehaviour = 3;
const int fuegoMaxMemoryMinimum = 16;
const int fuegoMaxMemoryDefault = 32;
const int fuegoThreadCountMinimum = 1;
const int fuegoThreadCountMaximum = 8;
const int fuegoThreadCountDefault = 1;
const bool fuegoPonderingDefault = false;
const unsigned int fuegoMaxPonderTimeMinimum = 60;     // only values that are full minutes because
                                                       // Settings tab lets the user pick minute values
const unsigned int fuegoMaxPonderTimeMaximum = 3600;   // ditto
const unsigned int fuegoMaxPonderTimeDefault = 300;    // ditto
const bool fuegoReuseSubtreeDefault = false;
const unsigned int fuegoMaxThinkingTimeMinimum = 1;
const unsigned int fuegoMaxThinkingTimeMaximum = 120;  // not too high, user must be able to pick individual values
                                                       // in the range from 1-10 seconds in the Settings tab
const unsigned int fuegoMaxThinkingTimeDefault = 10;
const unsigned long long fuegoMaxGamesMinimum = 1;
const unsigned long long fuegoMaxGamesMaximum = 18446744073709551615ULL;  // std::numeric_limits<unsigned long long>::max();
const unsigned long long fuegoMaxGamesDefault = 18446744073709551615ULL;  // std::numeric_limits<unsigned long long>::max();
const unsigned long long fuegoMaxGamesPlayingStrength1 = 500;    // start with 500 because anything below this is
                                                                 // quite ridiculous; 500 is still very weak
const unsigned long long fuegoMaxGamesPlayingStrength2 = 5000;
const unsigned long long fuegoMaxGamesPlayingStrength3 = 10000;  // on fast CPUs this still imposes a noticable
                                                                 // limit (measurement made on a MacBook)
const bool autoSelectFuegoResignMinGamesDefault = true;
const unsigned long long fuegoResignMinGamesDefault = 5000;
const int arraySizeFuegoResignThresholdDefault = (GoBoardSizeMax - GoBoardSizeMin) / 2 + 1;
const int fuegoResignThresholdDefault[arraySizeFuegoResignThresholdDefault] = {5, 5, 5, 5, 8, 8, 8};
NSString* defaultGtpEngineProfileUUID = @"5154D01A-1292-453F-B767-BE7389E3589F";

// Archive view constants
NSString* sgfMimeType = @"application/x-go-sgf";  // this is not officially registered with IANA, but seems to be in wide use
NSString* sgfUTI = @"com.red-bean.sgf";

// Diagnostics view settings default values
const int gtpLogSizeMinimum = 5;
const int gtpLogSizeMaximum = 1000;

// Bug reports constants
const int bugReportFormatVersion = 4;
NSString* bugReportDiagnosticsInformationFileName = @"littlego-bugreport.zip";
NSString* bugReportDiagnosticsInformationFileMimeType = @"application/zip";
NSString* bugReportInfoFileName = @"bugreport-info.plist";
NSString* bugReportInMemoryObjectsArchiveFileName = @ "in-memory-objects.plist";
NSString* bugReportUserDefaultsFileName = @ "userdefaults.plist";
NSString* bugReportCurrentGameFileName = @ "currentgame.sgf";
NSString* bugReportScreenshotFileName = @ "screenshot.png";
NSString* bugReportBoardAsSeenByGtpEngineFileName = @ "showboard.txt";
NSString* bugReportLogsArchiveFileName = @ "logs.zip";
NSString* bugReportEmailRecipient = @"herzbube@herzbube.ch";
NSString* bugReportEmailSubject = @"Little Go Bug Report";

// Crash reporting constants
NSString* crashReportSubmissionURL = @"http://www.herzbube.ch/quincykit/crash_v200.php";

// Resource file names
NSString* openingBookResource = @"book.dat";
NSString* aboutDocumentResource = @"About.html";
NSString* sourceCodeDocumentResource = @"SourceCode.html";
NSString* apacheLicenseDocumentResource = @"LICENSE.html";
NSString* GPLDocumentResource = @"COPYING.html";
NSString* LGPLDocumentResource = @"COPYING.LESSER.html";
NSString* boostLicenseDocumentResource = @"BoostSoftwareLicense.html";
NSString* MBProgressHUDLicenseDocumentResource = @"MBProgressHUD-license.html";
NSString* lumberjackLicenseDocumentResource = @"Lumberjack-LICENSE.txt.html";
NSString* zipkitLicenseDocumentResource = @"ZipKit-COPYING.TXT.html";
NSString* quincykitLicenseDocumentResource = @"QuincyKit-LICENSE.txt.html";
NSString* plcrashreporterLicenseDocumentResource = @"PLCrashReporter-LICENSE.txt.html";
NSString* protobufcLicenseDocumentResource = @"protobuf-c-LICENSE.txt.html";
NSString* readmeDocumentResource = @"README";
NSString* manualDocumentResource = @"MANUAL";
NSString* creditsDocumentResource = @"Credits.html";
NSString* registrationDomainDefaultsResource = @"RegistrationDomainDefaults.plist";
NSString* playStoneSoundFileResource = @"wood-on-wood-12.aiff";
NSString* computerPlayButtonIconResource = @"computer-play.png";
NSString* passButtonIconResource = @"gopass.png";
NSString* discardButtonIconResource = @"delete-to-left.png";
NSString* pauseButtonIconResource = @"48-pause.png";
NSString* continueButtonIconResource = @"40-forward.png";
NSString* gameInfoButtonIconResource = @"tabular.png";
NSString* interruptButtonIconResource = @"298-circlex.png";
NSString* playButtonIconResource = @"49-play.png";
NSString* fastForwardButtonIconResource = @"fastforward.png";
NSString* forwardToEndButtonIconResource = @"forwardtoend.png";
NSString* backButtonIconResource = @"back.png";
NSString* rewindButtonIconResource = @"rewind.png";
NSString* rewindToStartButtonIconResource = @"rewindtostart.png";
NSString* humanIconResource = @"111-user.png";
NSString* computerIconResource = @"computer.png";
NSString* stoneBlackImageResource = @"stone-black.png";
NSString* stoneWhiteImageResource = @"stone-white.png";
NSString* stoneCrosshairImageResource = @"stone-crosshair.png";
NSString* computerVsComputerImageResource = @"computer-vs-computer.png";
NSString* humanVsComputerImageResource = @"human-vs-computer.png";
NSString* humanVsHumanImageResource = @"human-vs-human.png";
NSString* woodenBackgroundImageResource = @"wooden-background.png";
NSString* bugReportMessageTemplateResource = @"bug-report-message-template.txt";

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
NSString* moveNumbersPercentageKey = @"MoveNumbersPercentage";
NSString* playSoundKey = @"PlaySound";
NSString* vibrateKey = @"Vibrate";
NSString* backgroundColorKey = @"BackgroundColor";
NSString* boardColorKey = @"BoardColor";
NSString* lineColorKey = @"LineColor";
NSString* boundingLineWidthKey = @"BoundingLineWidth";
NSString* normalLineWidthKey = @"NormalLineWidth";
NSString* starPointColorKey = @"StarPointColor";
NSString* starPointRadiusKey = @"StarPointRadius";
NSString* stoneRadiusPercentageKey = @"StoneRadiusPercentage";
NSString* crossHairColorKey = @"CrossHairColor";
NSString* maximumZoomScaleKey = @"MaximumZoomScale";
NSString* stoneDistanceFromFingertipKey = @"StoneDistanceFromFingertip";
NSString* infoTypeLastSelectedKey = @"InfoTypeLastSelected";
// New game settings
NSString* newGameKey = @"NewGame";
NSString* gameTypeKey = @"GameType";
NSString* gameTypeLastSelectedKey = @"GameTypeLastSelected";
NSString* humanPlayerKey = @"HumanPlayer";
NSString* computerPlayerKey = @"ComputerPlayer";
NSString* computerPlaysWhiteKey = @"ComputerPlaysWhite";
NSString* humanBlackPlayerKey = @"HumanBlackPlayer";
NSString* humanWhitePlayerKey = @"HumanWhitePlayer";
NSString* computerPlayerSelfPlayKey = @"ComputerPlayerSelfPlay";
NSString* boardSizeKey = @"BoardSize";
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
NSString* fuegoMaxPonderTimeKey = @"FuegoMaxPonderTime";
NSString* fuegoReuseSubtreeKey = @"FuegoReuseSubtree";
NSString* fuegoMaxThinkingTimeKey = @"FuegoMaxThinkingTime";
NSString* fuegoMaxGamesKey = @"FuegoMaxGames";
NSString* autoSelectFuegoResignMinGamesKey = @"AutoSelectFuegoResignMinGames";
NSString* fuegoResignMinGamesKey = @"FuegoResignMinGames";
NSString* fuegoResignThresholdKey = @"FuegoResignThreshold";
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
NSString* scoreWhenGameEndsKey = @"ScoreWhenGameEnds";
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
// Crash reporting settings
NSString* collectCrashDataKey = @"CrashReportActivated";
NSString* automaticReportCrashDataKey = @"AutomaticallySendCrashReports";
NSString* allowContactCrashDataKey = @"CrashDataContactAllowKey";
NSString* contactEmailCrashDataKey = @"CrashDataContactEmailKey";
// Board position settings
NSString* boardPositionKey = @"BoardPosition";
NSString* discardFutureMovesAlertKey = @"DiscardFutureMovesAlert";
NSString* markNextMoveKey = @"MarkNextMove";
// Logging settings
NSString* loggingEnabledKey = @"LoggingEnabled";
// User interface settings
NSString* selectedTabIndexKey = @"SelectedTabIndex";
NSString* tabOrderKey = @"TabOrder";

// Constants for NSCoding
// General constants
const int nscodingVersion = 4;
NSString* nscodingVersionKey = @"NSCodingVersion";
// Top-level object keys
NSString* nsCodingGoGameKey = @"GoGame";
// GoGame keys
NSString* goGameTypeKey = @"Type";
NSString* goGameBoardKey = @"Board";
NSString* goGameHandicapPointsKey = @"HandicapPoints";
NSString* goGameKomiKey = @"Komi";
NSString* goGamePlayerBlackKey = @"PlayerBlack";
NSString* goGamePlayerWhiteKey = @"PlayerWhite";
NSString* goGameMoveModelKey = @"MoveModel";
NSString* goGameStateKey = @"State";
NSString* goGameReasonForGameHasEndedKey = @"ReasonForGameHasEnded";
NSString* goGameIsComputerThinkingKey = @"IsComputerThinking";
NSString* goGameBoardPositionKey = @"BoardPosition";
NSString* goGameDocumentKey = @"Document";
NSString* goGameScoreKey = @"Score";
// GoPlayer keys
NSString* goPlayerPlayerUUIDKey = @"PlayerUUID";
NSString* goPlayerIsBlackKey = @"IsBlack";
// GoMove keys
NSString* goMoveTypeKey = @"Type";
NSString* goMovePlayerKey = @"Player";
NSString* goMovePointKey = @"Point";
NSString* goMovePreviousKey = @"Previous";
NSString* goMoveNextKey = @"Next";
NSString* goMoveCapturedStonesKey = @"CapturedStones";
NSString* goMoveMoveNumberKey = @"MoveNumber";
// GoMoveModel keys
NSString* goMoveModelGameKey = @"Game";
NSString* goMoveModelMoveListKey = @"MoveList";
NSString* goMoveModelNumberOfMovesKey = @"NumberOfMoves";
// GoBoardPosition keys
NSString* goBoardPositionGameKey = @"Game";
NSString* goBoardPositionCurrentBoardPositionKey = @"CurrentBoardPosition";
NSString* goBoardPositionNumberOfBoardPositionsKey = @"NumberOfBoardPositions";
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
// GoScore keys
NSString* goScoreTerritoryScoringEnabledKey = @"TerritoryScoringEnabled";
NSString* goScoreScoringInProgressKey = @"ScoringInProgress";
NSString* goScoreAskGtpEngineForDeadStonesInProgressKey = @"AskGtpEngineForDeadStonesInProgress";
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
NSString* goScoreDidAskGtpEngineForDeadStonesKey = @"DidAskGtpEngineForDeadStones";
NSString* goScoreLastCalculationHadErrorKey = @"LastCalculationHadError";
// GtpLogItem keys
NSString* gtpLogItemCommandStringKey = @"CommandString";
NSString* gtpLogItemTimeStampKey = @"TimeStamp";
NSString* gtpLogItemHasResponseKey = @"HasResponse";
NSString* gtpLogItemResponseStatusKey = @"ResponseStatus";
NSString* gtpLogItemParsedResponseStringKey = @"ParsedResponseString";
NSString* gtpLogItemRawResponseStringKey = @"RawResponseString";
// GoGameDocument keys
NSString* goGameDocumentDirtyKey = @"Dirty";
NSString* goGameDocumentDocumentNameKey = @"DocumentName";
