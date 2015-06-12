// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoGameRules.h"


@implementation GoGameRules

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameRules object with default rules.
///
/// @note This is the designated initializer of GoGameRules.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.koRule = GoKoRuleDefault;
  self.scoringSystem = gDefaultScoringSystem;
  self.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleDefault;
  self.disputeResolutionRule = GoDisputeResolutionRuleDefault;
  self.fourPassesRule = GoFourPassesRuleDefault;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;
  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;
  self.koRule = [decoder decodeIntForKey:goGameRulesKoRuleKey];
  self.scoringSystem = [decoder decodeIntForKey:goGameRulesScoringSystemKey];
  self.lifeAndDeathSettlingRule = [decoder decodeIntForKey:goGameRulesLifeAndDeathSettlingRuleKey];
  self.disputeResolutionRule = [decoder decodeIntForKey:goGameRulesDisputeResolutionRuleKey];
  self.fourPassesRule = [decoder decodeIntForKey:goGameRulesFourPassesRuleKey];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeInt:self.koRule forKey:goGameRulesKoRuleKey];
  [encoder encodeInt:self.scoringSystem forKey:goGameRulesScoringSystemKey];
  [encoder encodeInt:self.lifeAndDeathSettlingRule forKey:goGameRulesLifeAndDeathSettlingRuleKey];
  [encoder encodeInt:self.disputeResolutionRule forKey:goGameRulesDisputeResolutionRuleKey];
  [encoder encodeInt:self.fourPassesRule forKey:goGameRulesFourPassesRuleKey];
}

@end
