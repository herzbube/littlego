// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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

// Go constants
const enum GoBoardSize gDefaultBoardSize = BoardSize19;

// Table view cell constants
// Note: Values determined experimentally by debugging a default UITableViewCell
const int cellContentViewWidth = 300;
const int cellContentDistanceFromEdgeHorizontal = 10;
const int cellContentDistanceFromEdgeVertical = 11;
// Values determined experimentally in Interface Builder
const int cellContentSpacingHorizontal = 8;
const int cellContentSpacingVertical = 8;
// Values also from IB
const int cellContentLabelHeight = 21;
const int cellContentSliderHeight = 23;
const int cellContentSwitchWidth = 94;

// Filesystem related constants
NSString* sgfTemporaryFileName = @"---tmp+++.sgf";
NSString* sgfBackupFileName = @"backup.sgf";

// GTP notifications
NSString* gtpCommandWillBeSubmittedNotification = @"GtpCommandWillBeSubmitted";
NSString* gtpResponseWasReceivedNotification = @"GtpResponseWasReceived";
NSString* gtpEngineRunningNotification = @"GtpEngineRunning";
NSString* gtpEngineIdleNotification = @"GtpEngineIdle";
// GoGame notifications
NSString* goGameNewCreated = @"GoGameNewCreated";
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
NSString* registrationDomainDefaultsResource = @"RegistrationDomainDefaults.plist";
NSString* playStoneSoundFileResource = @"wood-on-wood-12.aiff";

// Keys for user defaults
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
NSString* crossHairPointDistanceFromFingerKey = @"CrossHairPointDistanceFromFinger";
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
NSString* alphaTerritoryColorInconsistencyFoundKey = @"AlphaTerritoryColorInconsistencyFound";
NSString* deadStoneSymbolColorKey = @"DeadStoneSymbolColor";
NSString* deadStoneSymbolPercentageKey = @"DeadStoneSymbolPercentage";
