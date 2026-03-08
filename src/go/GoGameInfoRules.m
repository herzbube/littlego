// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoGameInfoRules.h"
#import "../utility/ExceptionUtility.h"


@implementation GoGameInfoRules

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRules object with #GoGameInfoRuleNone.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithSgfString:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRules object with the supplied @a sgfString.
///
/// @note This is the designated initializer of GoGameInfoRules.
// -----------------------------------------------------------------------------
- (id) initWithSgfString:(NSString*)sgfString
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // The sgfString setter updates self.gameInfoRule
  self.sgfString = sgfString;

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

  // Don't use "self" because properties have non-trivial setter methods
  _gameInfoRule = [decoder decodeIntForKey:goGameInfoRulesGameInfoRuleKey];
  _sgfString = [[decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoRulesSgfStringKey] retain];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];

  [encoder encodeInt:self.gameInfoRule forKey:goGameInfoRulesGameInfoRuleKey];
  [encoder encodeObject:self.sgfString forKey:goGameInfoRulesSgfStringKey];
}

#pragma mark - Public API - Property setters

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setGameInfoRule:(enum GoGameInfoRule)newValue
{
  if (_gameInfoRule == newValue)
    return;
  _gameInfoRule = newValue;

  if (_sgfString)
    [_sgfString release];

  _sgfString = [self sgfStringForGameInfoRule:newValue];

  // Retain the string even though sgfStringForGameInfoRule:() returns only
  // literals. Reason: We don't want to distinguish between literals and
  // externally-supplied values, we want to be able to simply release the
  // _sgfString value whenever it is overwritten.
  if (_sgfString)
    [_sgfString retain];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setSgfString:(NSString*)newValue
{
  if (_sgfString == newValue)
    return;

  if (newValue)
    newValue = [newValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  _gameInfoRule = [self gameInfoRuleForSgfString:newValue];

  if (_sgfString)
    [_sgfString release];

  if (_gameInfoRule == GoGameInfoRuleSgfString)
    _sgfString = [newValue retain];
  else
    _sgfString = [[self sgfStringForGameInfoRule:_gameInfoRule] retain]; // fix capitalization

  if (_sgfString)
    [_sgfString retain];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Converts @a sgfString to a #GoGameInfoRule value.
// -----------------------------------------------------------------------------
- (enum GoGameInfoRule) gameInfoRuleForSgfString:(NSString*)sgfString
{
  if (! sgfString || sgfString.length == 0)
    return GoGameInfoRuleNone;

  sgfString = [sgfString lowercaseString];

  if ([sgfString isEqualToString:@"aga"])
    return GoGameInfoRuleAGA;
  else if ([sgfString isEqualToString:@"goe"])
    return GoGameInfoRuleIng;
  else if ([sgfString isEqualToString:@"japanese"])
    return GoGameInfoRuleJapanese;
  else if ([sgfString isEqualToString:@"nz"])
    return GoGameInfoRuleNewZealand;
  else
    return GoGameInfoRuleSgfString;
}

// -----------------------------------------------------------------------------
/// @brief Converts @a sgfString to a #GoGameInfoRule value.
// -----------------------------------------------------------------------------
- (NSString*) sgfStringForGameInfoRule:(enum GoGameInfoRule)gameInfoRule
{
  switch (gameInfoRule)
  {
    case GoGameInfoRuleNone:
    case GoGameInfoRuleSgfString:
      return nil;
      break;
    case GoGameInfoRuleAGA:
      return @"AGA";
      break;
    case GoGameInfoRuleIng:
      return @"GOE";
      break;
    case GoGameInfoRuleJapanese:
      return @"Japanese";
      break;
    case GoGameInfoRuleNewZealand:
      return @"NZ";
      break;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Unsupported GoGameInfoRule value %ld"
                                                  argumentValue:gameInfoRule];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
      return nil;
  }
}

@end
