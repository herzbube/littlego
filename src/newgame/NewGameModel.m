// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "NewGameModel.h"


@implementation NewGameModel

// -----------------------------------------------------------------------------
/// @brief Initializes a NewGameModel object with user defaults data.
///
/// @note This is the designated initializer of NewGameModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.gameType = gDefaultGameType;
  self.gameTypeLastSelected = gDefaultGameType;
  self.humanPlayerUUID = @"";
  self.computerPlayerUUID = @"";
  self.computerPlaysWhite = gDefaultComputerPlaysWhite;
  self.humanBlackPlayerUUID = @"";
  self.humanWhitePlayerUUID = @"";
  self.computerPlayerSelfPlayUUID = @"";
  self.boardSize = gDefaultBoardSize;
  self.handicap = gDefaultHandicap;
  if (gDefaultScoringSystem == GoScoringSystemAreaScoring)
    self.komi = gDefaultKomiAreaScoring;
  else
    self.komi = gDefaultKomiTerritoryScoring;
  self.koRule = GoKoRuleDefault;
  self.scoringSystem = gDefaultScoringSystem;
  self.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleDefault;
  self.disputeResolutionRule = GoDisputeResolutionRuleDefault;
  self.fourPassesRule = GoFourPassesRuleDefault;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NewGameModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.humanPlayerUUID = nil;
  self.computerPlayerUUID = nil;
  self.humanBlackPlayerUUID = nil;
  self.humanWhitePlayerUUID = nil;
  self.computerPlayerSelfPlayUUID = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:newGameKey];
  self.gameType = [[dictionary valueForKey:gameTypeKey] intValue];
  self.gameTypeLastSelected = [[dictionary valueForKey:gameTypeLastSelectedKey] intValue];
  self.humanPlayerUUID = (NSString*)[dictionary valueForKey:humanPlayerKey];
  self.computerPlayerUUID = (NSString*)[dictionary valueForKey:computerPlayerKey];
  self.computerPlaysWhite = [[dictionary valueForKey:computerPlaysWhiteKey] boolValue];
  self.humanBlackPlayerUUID = (NSString*)[dictionary valueForKey:humanBlackPlayerKey];
  self.humanWhitePlayerUUID = (NSString*)[dictionary valueForKey:humanWhitePlayerKey];
  self.computerPlayerSelfPlayUUID = (NSString*)[dictionary valueForKey:computerPlayerSelfPlayKey];
  self.boardSize = [[dictionary valueForKey:boardSizeKey] intValue];
  self.handicap = [[dictionary valueForKey:handicapKey] intValue];
  NSNumber* komiAsNumber = [dictionary valueForKey:komiKey];
  self.komi = [komiAsNumber doubleValue];
  self.koRule = [[dictionary valueForKey:koRuleKey] intValue];
  self.scoringSystem = [[dictionary valueForKey:scoringSystemKey] intValue];
  self.lifeAndDeathSettlingRule = [[dictionary valueForKey:lifeAndDeathSettlingRuleKey] intValue];
  self.disputeResolutionRule = [[dictionary valueForKey:disputeResolutionRuleKey] intValue];
  self.fourPassesRule = [[dictionary valueForKey:fourPassesRuleKey] intValue];
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
  [dictionary setValue:[NSNumber numberWithInt:self.gameType] forKey:gameTypeKey];
  [dictionary setValue:[NSNumber numberWithInt:self.gameTypeLastSelected] forKey:gameTypeLastSelectedKey];
  [dictionary setValue:self.humanPlayerUUID forKey:humanPlayerKey];
  [dictionary setValue:self.computerPlayerUUID forKey:computerPlayerKey];
  [dictionary setValue:[NSNumber numberWithBool:self.computerPlaysWhite] forKey:computerPlaysWhiteKey];
  [dictionary setValue:self.humanBlackPlayerUUID forKey:humanBlackPlayerKey];
  [dictionary setValue:self.humanWhitePlayerUUID forKey:humanWhitePlayerKey];
  [dictionary setValue:self.computerPlayerSelfPlayUUID forKey:computerPlayerSelfPlayKey];
  [dictionary setValue:[NSNumber numberWithInt:self.boardSize] forKey:boardSizeKey];
  [dictionary setValue:[NSNumber numberWithInt:self.handicap] forKey:handicapKey];
  [dictionary setValue:[NSNumber numberWithDouble:self.komi] forKey:komiKey];
  [dictionary setValue:[NSNumber numberWithInt:self.koRule] forKey:koRuleKey];
  [dictionary setValue:[NSNumber numberWithInt:self.scoringSystem] forKey:scoringSystemKey];
  [dictionary setValue:[NSNumber numberWithInt:self.lifeAndDeathSettlingRule] forKey:lifeAndDeathSettlingRuleKey];
  [dictionary setValue:[NSNumber numberWithInt:self.disputeResolutionRule] forKey:disputeResolutionRuleKey];
  [dictionary setValue:[NSNumber numberWithInt:self.fourPassesRule] forKey:fourPassesRuleKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:newGameKey];
}

// -----------------------------------------------------------------------------
/// @brief Discards the current user defaults and re-initializes this model with
/// registration domain defaults data.
// -----------------------------------------------------------------------------
- (void) resetToRegistrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults removeObjectForKey:newGameKey];
  [self readUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Returns the UUID of the player who is to play black if a new game
/// were started with this model's current data.
///
/// This is a convenience method that picks one of the many player UUID
/// properties and returns its value. The property is determined by the current
/// values of the properties @e gameType and @e computerPlaysWhite.
///
/// Raises an @e NSInvalidArgumentException if @e gameType is not recognized.
// -----------------------------------------------------------------------------
- (NSString*) blackPlayerUUID
{
  switch (self.gameType)
  {
    case GoGameTypeComputerVsHuman:
    {
      if (self.computerPlaysWhite)
        return self.humanPlayerUUID;
      else
        return self.computerPlayerUUID;
    }
    case GoGameTypeHumanVsHuman:
      return self.humanBlackPlayerUUID;
    case GoGameTypeComputerVsComputer:
      return self.computerPlayerSelfPlayUUID;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid game type: %d", self.gameType];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the UUID of the player who is to play white if a new game
/// were started with this model's current data.
///
/// @see blackPlayerUUID().
///
/// Raises an @e NSInvalidArgumentException if @e gameType is not recognized.
// -----------------------------------------------------------------------------
- (NSString*) whitePlayerUUID
{
  switch (self.gameType)
  {
    case GoGameTypeComputerVsHuman:
    {
      if (self.computerPlaysWhite)
        return self.computerPlayerUUID;
      else
        return self.humanPlayerUUID;
    }
    case GoGameTypeHumanVsHuman:
      return self.humanWhitePlayerUUID;
    case GoGameTypeComputerVsComputer:
      return self.computerPlayerSelfPlayUUID;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid game type: %d", self.gameType];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
