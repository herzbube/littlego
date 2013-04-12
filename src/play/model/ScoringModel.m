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


// Project includes
#import "ScoringModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ScoringModel.
// -----------------------------------------------------------------------------
@interface ScoringModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Setters needed for posting notifications to notify our observers
//@{
- (void) setScoringMode:(bool)newMode;
//@}
@end


@implementation ScoringModel

// -----------------------------------------------------------------------------
/// @brief Initializes a ScoringModel object with user defaults data.
///
/// @note This is the designated initializer of ScoringModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.scoreWhenGameEnds = true;
  self.askGtpEngineForDeadStones = false;
  self.markDeadStonesIntelligently = false;
  self.alphaTerritoryColorBlack = 0.3;
  self.alphaTerritoryColorWhite = 0.3;
  self.deadStoneSymbolColor = [UIColor redColor];
  self.deadStoneSymbolPercentage = 0.8;
  self.inconsistentTerritoryMarkupType = InconsistentTerritoryMarkupTypeDotSymbol;
  self.inconsistentTerritoryDotSymbolColor = [UIColor redColor];
  self.inconsistentTerritoryDotSymbolPercentage = 0.5;
  self.inconsistentTerritoryFillColor = [UIColor redColor];
  self.inconsistentTerritoryFillColorAlpha = 0.3;
  self.score = nil;
  _scoringMode = false;  // don't use self to avoid triggering a notification

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ScoringModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.deadStoneSymbolColor = nil;
  self.score = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:scoringKey];
  self.scoreWhenGameEnds = [[dictionary valueForKey:scoreWhenGameEndsKey] boolValue];
  self.askGtpEngineForDeadStones = [[dictionary valueForKey:askGtpEngineForDeadStonesKey] boolValue];
  self.markDeadStonesIntelligently = [[dictionary valueForKey:markDeadStonesIntelligentlyKey] boolValue];
  self.alphaTerritoryColorBlack = [[dictionary valueForKey:alphaTerritoryColorBlackKey] floatValue];
  self.alphaTerritoryColorWhite = [[dictionary valueForKey:alphaTerritoryColorWhiteKey] floatValue];
  self.deadStoneSymbolColor = [UIColor colorFromHexString:[dictionary valueForKey:deadStoneSymbolColorKey]];
  self.deadStoneSymbolPercentage = [[dictionary valueForKey:deadStoneSymbolPercentageKey] floatValue];
  self.inconsistentTerritoryMarkupType = [[dictionary valueForKey:inconsistentTerritoryMarkupTypeKey] intValue];
  self.inconsistentTerritoryDotSymbolColor = [UIColor colorFromHexString:[dictionary valueForKey:inconsistentTerritoryDotSymbolColorKey]];
  self.inconsistentTerritoryDotSymbolPercentage = [[dictionary valueForKey:inconsistentTerritoryDotSymbolPercentageKey] floatValue];
  self.inconsistentTerritoryFillColor = [UIColor colorFromHexString:[dictionary valueForKey:inconsistentTerritoryFillColorKey]];
  self.inconsistentTerritoryFillColorAlpha = [[dictionary valueForKey:inconsistentTerritoryFillColorAlphaKey] floatValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  // setValue:forKey:() allows for nil values, so we use that instead of
  // setObject:forKey:() which is less forgiving and would force us to check
  // for nil values.
  // Note: Use NSNumber to represent int and bool values as an object.
  [dictionary setValue:[NSNumber numberWithBool:self.scoreWhenGameEnds] forKey:scoreWhenGameEndsKey];
  [dictionary setValue:[NSNumber numberWithBool:self.askGtpEngineForDeadStones] forKey:askGtpEngineForDeadStonesKey];
  [dictionary setValue:[NSNumber numberWithBool:self.markDeadStonesIntelligently] forKey:markDeadStonesIntelligentlyKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.alphaTerritoryColorBlack] forKey:alphaTerritoryColorBlackKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.alphaTerritoryColorWhite] forKey:alphaTerritoryColorWhiteKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.deadStoneSymbolColor] forKey:deadStoneSymbolColorKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.deadStoneSymbolPercentage] forKey:deadStoneSymbolPercentageKey];
  [dictionary setValue:[NSNumber numberWithInt:self.inconsistentTerritoryMarkupType] forKey:inconsistentTerritoryMarkupTypeKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.inconsistentTerritoryDotSymbolColor] forKey:inconsistentTerritoryDotSymbolColorKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.inconsistentTerritoryDotSymbolPercentage] forKey:inconsistentTerritoryDotSymbolPercentageKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.inconsistentTerritoryFillColor] forKey:inconsistentTerritoryFillColorKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.inconsistentTerritoryFillColorAlpha] forKey:inconsistentTerritoryFillColorAlphaKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:scoringKey];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setScoringMode:(bool)newMode
{
  if (_scoringMode == newMode)
    return;
  _scoringMode = newMode;
  NSString* notificationName;
  if (newMode)
  {
    self.score = [GoScore scoreForGame:[GoGame sharedGame] withTerritoryScores:true];
    notificationName = goScoreScoringModeEnabled;
  }
  else
  {
    self.score = nil;
    notificationName = goScoreScoringModeDisabled;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Enables scoring mode. Uses @a scoreObject instead of creating a new
/// score object from scratch. This model takes ownership of (i.e. retains)
/// @a scoreObject.
///
/// This method is used to restore scoring mode when the application launches.
/// Scoring mode needs to be restored when it was enabled during the previous
/// session, and also when a bug report is received and archived GoScore object
/// in the diagnostics information file is processed.
// -----------------------------------------------------------------------------
- (void) restoreScoringModeWithScoreObject:(GoScore*)scoreObject
{
  _scoringMode = true;       // don't use self because we don't want to trigger the setter
  self.score = scoreObject;  // use self to retain the score object
  [[NSNotificationCenter defaultCenter] postNotificationName:goScoreScoringModeEnabled object:nil];
}

@end
