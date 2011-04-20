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

// Resource file names
NSString* openingBookResource = @"book.dat";
NSString* aboutDocumentResource = @"About.html";
NSString* sourceCodeDocumentResource = @"SourceCode.html";
NSString* apacheLicenseDocumentResource = @"LICENSE.html";
NSString* GPLDocumentResource = @"COPYING.html";
NSString* LGPLDocumentResource = @"COPYING.LESSER.html";
NSString* boostLicenseDocumentResource = @"BoostSoftwareLicense.html";
NSString* registrationDomainDefaultsResource = @"RegistrationDomainDefaults.plist";

// Keys for user defaults
NSString* playViewBackgroundColorKey = @"PlayViewBackgroundColor";
NSString* playViewBoardColorKey = @"PlayViewBoardColor";
NSString* playViewBoardOuterMarginPercentageKey = @"PlayViewBoardOuterMarginPercentage";
NSString* playViewBoardInnerMarginPercentageKey = @"PlayViewBoardInnerMarginPercentage";
NSString* playViewLineColorKey = @"PlayViewLineColor";
NSString* playViewBoundingLineWidthKey = @"PlayViewBoundingLineWidth";
NSString* playViewNormalLineWidthKey = @"PlayViewNormalLineWidth";
NSString* playViewStarPointColorKey = @"PlayViewStarPointColor";
NSString* playViewStarPointRadiusKey = @"PlayViewStarPointRadius";
NSString* playViewStoneRadiusPercentageKey = @"PlayViewStoneRadiusPercentage";
NSString* playViewCrossHairColorKey = @"PlayViewCrossHairColor";
NSString* playViewCrossHairPointDistanceFromFingerKey = @"PlayViewCrossHairPointDistanceFromFinger";
