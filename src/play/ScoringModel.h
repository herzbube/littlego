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


// Forward declarations
@class GoScore;


// -----------------------------------------------------------------------------
/// @brief The ScoringModel class provides user defaults data to its clients
/// that is related to scoring.
// -----------------------------------------------------------------------------
@interface ScoringModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;
- (void) restoreScoringModeWithScoreObject:(GoScore*)scoreObject;

// -----------------------------------------------------------------------------
/// @name User defaults properties
// -----------------------------------------------------------------------------
//@{
@property(nonatomic, assign) bool scoreWhenGameEnds;
@property(nonatomic, assign) bool askGtpEngineForDeadStones;
@property(nonatomic, assign) bool markDeadStonesIntelligently;
@property(nonatomic, assign) float alphaTerritoryColorBlack;
@property(nonatomic, assign) float alphaTerritoryColorWhite;
@property(nonatomic, retain) UIColor* deadStoneSymbolColor;
@property(nonatomic, assign) float deadStoneSymbolPercentage;
@property(nonatomic, assign) enum InconsistentTerritoryMarkupType inconsistentTerritoryMarkupType;
@property(nonatomic, retain) UIColor* inconsistentTerritoryDotSymbolColor;
@property(nonatomic, assign) float inconsistentTerritoryDotSymbolPercentage;
@property(nonatomic, retain) UIColor* inconsistentTerritoryFillColor;
@property(nonatomic, assign) float inconsistentTerritoryFillColorAlpha;
//@}

// -----------------------------------------------------------------------------
/// @name Scoring properties
// -----------------------------------------------------------------------------
//@{
/// @brief Is true if scoring mode is enabled on the Play view.
@property(nonatomic, assign) bool scoringMode;
/// @brief The GoScore object that provides scoring data while scoring mode is
/// enabled. Is nil while scoring mode is disabled.
@property(nonatomic, retain) GoScore* score;
//@}

@end
