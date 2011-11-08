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

/// GTP engine settings default values
int const fuegoMaxMemoryMinimum = 32;
int const fuegoMaxMemoryMaximum = 512;
int const fuegoMaxMemoryDefault = 64;
int const fuegoThreadCountMinimum = 1;
int const fuegoThreadCountMaximum = 8;
int const fuegoThreadCountDefault = 1;
bool const fuegoPonderingDefault = true;
bool const fuegoReuseSubtreeDefault = true;

// Debug view settings default values
int const gtpLogSizeMinimum = 5;
int const gtpLogSizeMaximum = 1000;

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
NSString* boardInnerMarginPercentageKey = @"BoardInnerMarginPercentage";
NSString* lineColorKey = @"LineColor";
NSString* boundingLineWidthKey = @"BoundingLineWidth";
NSString* normalLineWidthKey = @"NormalLineWidth";
NSString* starPointColorKey = @"StarPointColor";
NSString* starPointRadiusKey = @"StarPointRadius";
NSString* stoneRadiusPercentageKey = @"StoneRadiusPercentage";
NSString* alphaTerritoryColorBlackKey = @"AlphaTerritoryColorBlack";
NSString* alphaTerritoryColorWhiteKey = @"AlphaTerritoryColorWhite";
NSString* deadStoneSymbolColorKey = @"DeadStoneSymbolColorKey";
NSString* deadStoneSymbolPercentageKey = @"DeadStoneSymbolPercentageKey";
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
NSString* uuidKey = @"UUID";
NSString* nameKey = @"Name";
NSString* isHumanKey = @"IsHuman";
NSString* statisticsKey = @"Statistics";
NSString* gamesPlayedKey = @"GamesPlayed";
NSString* gamesWonKey = @"GamesWon";
NSString* gamesLostKey = @"GamesLost";
NSString* gamesTiedKey = @"GamesTied";
NSString* starPointsKey = @"StarPoints";
// GTP engine settings
NSString* gtpEngineSettingsKey = @"GtpEngineSettings";
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
