// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
const float gInfluenceColorAlphaBlack = 0.3;
const float gInfluenceColorAlphaWhite = 0.6;
const CFTimeInterval gGoBoardLongPressDelay = 0.15;
const int arraySizeDefaultTabOrder = 9;
const int defaultTabOrder[arraySizeDefaultTabOrder] = {0, 1, 2, 4, 3, 5, 6, 7, 8};

// Logging constants
const DDLogLevel ddLogLevel = DDLogLevelAll;

// Go constants
const enum GoGameType gDefaultGameType = GoGameTypeComputerVsHuman;
const enum GoBoardSize gDefaultBoardSize = GoBoardSize19;
const int gNumberOfBoardSizes = (GoBoardSizeMax - GoBoardSizeMin) / 2 + 1;
const bool gDefaultComputerPlaysWhite = true;
const int gDefaultHandicap = 0;
const enum GoScoringSystem gDefaultScoringSystem = GoScoringSystemAreaScoring;
const double gDefaultKomiAreaScoring = 7.5;
const double gDefaultKomiTerritoryScoring = 6.5;

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
NSString* goScoreScoringEnabled = @"GoScoreScoringEnabled";
NSString* goScoreScoringDisabled = @"GoScoreScoringDisabled";
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
NSString* territoryStatisticsChanged = @"TerritoryStatisticsChanged";
NSString* boardViewWillDisplayCrossHair = @"BoardViewWillDisplayCrossHair";
NSString* boardViewWillHideCrossHair = @"BoardViewWillHideCrossHair";;
NSString* boardViewDidChangeCrossHair = @"BoardViewDidChangeCrossHair";

// Default values for properties that define how the Go board is displayed
const float iPhoneMaximumZoomScale = 2.5;
const float iPadMaximumZoomScale = 2.0;
const float moveNumbersPercentageDefault = 0.0;
const bool displayPlayerInfluenceDefault = false;

// Board position settings default values
const bool discardFutureMovesAlertDefault = true;
const bool markNextMoveDefault = true;

/// Magnifying glass constants
const CGFloat defaultMagnifyingGlassDimension = 100.0f;
const CGFloat defaultMagnifyingGlassMagnification = 1.25f;

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
const unsigned int fuegoMaxPonderTimeMinimum = 60;     // assign only values that are full minutes because
                                                       // the UI lets the user pick minute values
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
NSString* fallbackGtpEngineProfileUUID = @"5154D01A-1292-453F-B767-BE7389E3589F";

// Archive view constants
NSString* sgfMimeType = @"application/x-go-sgf";  // this is not officially registered with IANA, but seems to be in wide use
NSString* sgfUTI = @"com.red-bean.sgf";
NSString* illegalArchiveGameNameCharacters = @"/\\|";

// Diagnostics view settings default values
const int gtpLogSizeMinimum = 5;
const int gtpLogSizeMaximum = 1000;

// Bug reports constants
const int bugReportFormatVersion = 7;
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
NSString* fabricAPIKeyResource = @"fabric.apikey";

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
NSString* crashlyticsLicenseDocumentResource = @"Crashlytics-opensource.txt.html";
NSString* firebaseLicenseDocumentResource = @"Firebase-oss.html";
NSString* readmeDocumentResource = @"README";
NSString* manualDocumentResource = @"MANUAL";
NSString* creditsDocumentResource = @"Credits.html";
NSString* changelogDocumentResource = @"ChangeLog";
NSString* registrationDomainDefaultsResource = @"RegistrationDomainDefaults.plist";
NSString* playStoneSoundFileResource = @"wood-on-wood-12.aiff";
NSString* mainMenuIconResource = @"main-menu.png";
NSString* uiAreaPlayIconResource = @"gogrid2x2.png";
NSString* uiAreaSettingsIconResource = @"settings.png";
NSString* uiAreaArchiveIconResource = @"archive.png";
NSString* uiAreaHelpIconResource = @"help.png";
NSString* uiAreaDiagnosticsIconResource = @"diagnostics.png";
NSString* uiAreaAboutIconResource = @"about.png";
NSString* uiAreaSourceCodeIconResource = @"source-code.png";
NSString* uiAreaLicensesIconResource = @"licenses.png";
NSString* uiAreaCreditsIconResource = @"credits.png";
NSString* uiAreaChangelogIconResource = @"changelog.png";
NSString* computerPlayButtonIconResource = @"computer-play.png";
NSString* passButtonIconResource = @"pass.png";
NSString* discardButtonIconResource = @"discard.png";
NSString* pauseButtonIconResource = @"pause.png";
NSString* continueButtonIconResource = @"continue.png";
NSString* gameInfoButtonIconResource = @"game-info.png";
NSString* interruptButtonIconResource = @"interrupt.png";
NSString* scoringStartButtonIconResource = @"scoring.png";
NSString* scoringDoneButtonIconResource = @"gogrid2x2.png";
NSString* moreGameActionsButtonIconResource = @"more-game-actions.png";
NSString* forwardButtonIconResource = @"forward.png";
NSString* forwardToEndButtonIconResource = @"forwardtoend.png";
NSString* backButtonIconResource = @"back.png";
NSString* rewindToStartButtonIconResource = @"rewindtostart.png";
NSString* stoneBlackImageResource = @"stone-black.png";
NSString* stoneWhiteImageResource = @"stone-white.png";
NSString* stoneCrosshairImageResource = @"stone-crosshair.png";
NSString* computerVsComputerImageResource = @"computer-vs-computer.png";
NSString* humanVsComputerImageResource = @"human-vs-computer.png";
NSString* humanVsHumanImageResource = @"human-vs-human.png";
NSString* woodenBackgroundImageResource = @"wooden-background-tile.png";
NSString* bugReportMessageTemplateResource = @"bug-report-message-template.txt";

// Constants (mostly keys) for user defaults
// Device-specific suffixes
NSString* iPhoneDeviceSuffix = @"~iphone";
NSString* iPadDeviceSuffix = @"~ipad";
// User Defaults versioning
NSString* userDefaultsVersionRegistrationDomainKey = @"UserDefaultsVersionRegistrationDomain";
NSString* userDefaultsVersionApplicationDomainKey = @"UserDefaultsVersionApplicationDomain";
// Board view settings
NSString* boardViewKey = @"BoardView";
NSString* markLastMoveKey = @"MarkLastMove";
NSString* displayCoordinatesKey = @"DisplayCoordinates";
NSString* displayPlayerInfluenceKey = @"DisplayPlayerInfluence";
NSString* moveNumbersPercentageKey = @"MoveNumbersPercentage";
NSString* playSoundKey = @"PlaySound";
NSString* vibrateKey = @"Vibrate";
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
NSString* koRuleKey = @"KoRule";
NSString* scoringSystemKey = @"ScoringSystem";
NSString* lifeAndDeathSettlingRuleKey = @"LifeAndDeathSettlingRule";
NSString* disputeResolutionRuleKey = @"DisputeResolutionRule";
NSString* fourPassesRuleKey = @"FourPassesRule";
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
// GTP engine configuration not related to profiles
NSString* additiveKnowledgeMemoryThresholdKey = @"AdditiveKnowledgeMemoryThreshold";
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
NSString* autoScoringAndResumingPlayKey = @"AutoScoringAndResumingPlay";
NSString* askGtpEngineForDeadStonesKey = @"AskGtpEngineForDeadStones";
NSString* markDeadStonesIntelligentlyKey = @"MarkDeadStonesIntelligently";
NSString* inconsistentTerritoryMarkupTypeKey = @"InconsistentTerritoryMarkupType";
NSString* scoreMarkModeKey = @"ScoreMarkMode";
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
NSString* visibleUIAreaKey = @"VisibleUIArea";
NSString* tabOrderKey = @"TabOrder";
// Magnifying glass settings
NSString* magnifyingGlassEnableModeKey = @"MagnifyingGlassEnableMode";
NSString* magnifyingGlassAutoThresholdKey = @"MagnifyingGlassAutoThreshold";
NSString* magnifyingGlassVeerDirectionKey = @"MagnifyingGlassVeerDirection";
NSString* magnifyingGlassDistanceFromMagnificationCenterKey = @"MagnifyingGlassDistanceFromMagnificationCenter";

// Constants for NSCoding
// General constants
const int nscodingVersion = 7;  // if you change this, also change bugReportFormatVersion
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
NSString* goGameNextMoveColorKey = @"NextMoveColor";
NSString* goGameAlternatingPlayKey = @"AlternatingPlay";
NSString* goGameMoveModelKey = @"MoveModel";
NSString* goGameStateKey = @"State";
NSString* goGameReasonForGameHasEndedKey = @"ReasonForGameHasEnded";
NSString* goGameReasonForComputerIsThinking = @"ReasonForComputerIsThinking";
NSString* goGameBoardPositionKey = @"BoardPosition";
NSString* goGameRulesKey = @"Rules";
NSString* goGameDocumentKey = @"Document";
NSString* goGameScoreKey = @"Score";
NSString* goGameBlackSetupPointsKey = @"BlackSetupPoints";
NSString* goGameWhiteSetupPointsKey = @"WhiteSetupPoints";
NSString* goGameSetupFirstMoveColorKey = @"SetupFirstMoveColor";
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
NSString* goBoardRegionScoringModeKey = @"ScoringMode";
NSString* goBoardRegionTerritoryColorKey = @"TerritoryColor";
NSString* goBoardRegionTerritoryInconsistencyFoundKey = @"TerritoryInconsistencyFound";
NSString* goBoardRegionStoneGroupStateKey = @"StoneGroupState";
NSString* goBoardRegionCachedSizeKey = @"CachedSize";
NSString* goBoardRegionCachedIsStoneGroupKey = @"CachedIsStoneGroup";
NSString* goBoardRegionCachedColorKey = @"CachedColor";
NSString* goBoardRegionCachedLibertiesKey = @"CachedLiberties";
NSString* goBoardRegionCachedAdjacentRegionsKey = @"CachedAdjacentRegions";
// GoPoint keys
NSString* goPointVertexKey = @"Vertex";
NSString* goPointBoardKey = @"Board";
NSString* goPointIsStarPointKey = @"IsStarPoint";
NSString* goPointStoneStateKey = @"StoneState";
NSString* goPointTerritoryStatisticsScoreKey = @"TerritoryStatisticsScore";
NSString* goPointRegionKey = @"Region";
// GoScore keys
NSString* goScoreScoringEnabledKey = @"ScoringEnabled";
NSString* goScoreKomiKey = @"Komi";
NSString* goScoreCapturedByBlackKey = @"CapturedByBlack";
NSString* goScoreCapturedByWhiteKey = @"CapturedByWhite";
NSString* goScoreDeadBlackKey = @"DeadBlack";
NSString* goScoreDeadWhiteKey = @"DeadWhite";
NSString* goScoreTerritoryBlackKey = @"TerritoryBlack";
NSString* goScoreTerritoryWhiteKey = @"TerritoryWhite";
NSString* goScoreAliveBlackKey = @"AliveBlack";
NSString* goScoreAliveWhiteKey = @"AliveWhite";
NSString* goScoreHandicapCompensationBlackKey = @"HandicapCompensationBlack";
NSString* goScoreHandicapCompensationWhiteKey = @"HandicapCompensationWhite";
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
// GoGameRules keys
NSString* goGameRulesKoRuleKey = @"KoRule";
NSString* goGameRulesScoringSystemKey = @"ScoringSystem";
NSString* goGameRulesLifeAndDeathSettlingRuleKey = @"LifeAndDeathSettlingRule";
NSString* goGameRulesDisputeResolutionRuleKey = @"DisputeResolutionRule";
NSString* goGameRulesFourPassesRuleKey = @"FourPassesRule";
