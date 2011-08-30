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

// GTP notifications
NSString* gtpCommandSubmittedNotification = @"GtpCommandSubmitted";
NSString* gtpResponseReceivedNotification = @"GtpResponseReceived";
NSString* gtpEngineRunningNotification = @"GtpEngineRunning";
NSString* gtpEngineIdleNotification = @"GtpEngineIdle";
// GoGame notifications
NSString* goGameNewCreated = @"GoGameNewCreated";
NSString* goGameStateChanged = @"GoGameStateChanged";
NSString* goGameFirstMoveChanged = @"GoGameFirstMoveChanged";
NSString* goGameLastMoveChanged = @"GoGameLastMoveChanged";
NSString* goGameScoreChanged = @"GoGameScoreChanged";
// Computer player notifications
NSString* computerPlayerThinkingStarts = @"ComputerPlayerThinkingStarts";
NSString* computerPlayerThinkingStops = @"ComputerPlayerThinkingStops";

/// GTP engine settings default values
int fuegoMaxMemoryMinimum = 32;
int fuegoMaxMemoryMaximum = 512;
int fuegoMaxMemoryDefault = 128;
int fuegoThreadCountMinimum = 1;
int fuegoThreadCountMaximum = 8;
int fuegoThreadCountDefault = 1;
bool fuegoPonderingDefault = true;
bool fuegoReuseSubtreeDefault = true;

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
