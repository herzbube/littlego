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


// Project includes
#import "ScoringModel.h"
#import "../go/GoGame.h"
#import "../go/GoScore.h"
#import "../utility/UIColorAdditions.h"


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

@synthesize askGtpEngineForDeadStones;
@synthesize markDeadStonesIntelligently;
@synthesize alphaTerritoryColorBlack;
@synthesize alphaTerritoryColorWhite;
@synthesize alphaTerritoryColorInconsistencyFound;
@synthesize deadStoneSymbolColor;
@synthesize deadStoneSymbolPercentage;
@synthesize scoringMode;
@synthesize score;


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

  self.askGtpEngineForDeadStones = false;
  self.markDeadStonesIntelligently = false;
  self.alphaTerritoryColorBlack = 0.3;
  self.alphaTerritoryColorWhite = 0.3;
  self.alphaTerritoryColorInconsistencyFound = 0.3;
  self.deadStoneSymbolColor = [UIColor redColor];
  self.deadStoneSymbolPercentage = 0.8;
  self.score = nil;
  scoringMode = false;  // don't use self to avoid triggering a notification

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
  self.askGtpEngineForDeadStones = [[dictionary valueForKey:askGtpEngineForDeadStonesKey] boolValue];
  self.markDeadStonesIntelligently = [[dictionary valueForKey:markDeadStonesIntelligentlyKey] boolValue];
  self.alphaTerritoryColorBlack = [[dictionary valueForKey:alphaTerritoryColorBlackKey] floatValue];
  self.alphaTerritoryColorWhite = [[dictionary valueForKey:alphaTerritoryColorWhiteKey] floatValue];
  self.alphaTerritoryColorInconsistencyFound = [[dictionary valueForKey:alphaTerritoryColorInconsistencyFoundKey] floatValue];
  self.deadStoneSymbolColor = [UIColor colorFromHexString:[dictionary valueForKey:deadStoneSymbolColorKey]];
  self.deadStoneSymbolPercentage = [[dictionary valueForKey:deadStoneSymbolPercentageKey] floatValue];
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
  [dictionary setValue:[NSNumber numberWithBool:self.askGtpEngineForDeadStones] forKey:askGtpEngineForDeadStonesKey];
  [dictionary setValue:[NSNumber numberWithBool:self.markDeadStonesIntelligently] forKey:markDeadStonesIntelligentlyKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.alphaTerritoryColorBlack] forKey:alphaTerritoryColorBlackKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.alphaTerritoryColorWhite] forKey:alphaTerritoryColorWhiteKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.alphaTerritoryColorInconsistencyFound] forKey:alphaTerritoryColorInconsistencyFoundKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.deadStoneSymbolColor] forKey:deadStoneSymbolColorKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.deadStoneSymbolPercentage] forKey:deadStoneSymbolPercentageKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:scoringKey];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setScoringMode:(bool)newMode
{
  if (scoringMode == newMode)
    return;
  scoringMode = newMode;
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

@end
