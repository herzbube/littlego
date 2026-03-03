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
#import "GoGameResult.h"
#import "../utility/ExceptionUtility.h"


@implementation GoGameResult

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameResult object with #GoGameResultDataTypeNoResult.
/// The update policy is #GoGameResultUpdatePolicyAutomatic.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithDataType:GoGameResultDataTypeNoResult
                      sgfString:nil
                 gameResultType:GoGameResultTypeUnknownResult
                        winType:GoGameResultWinTypeWinWithoutScore
                          score:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameResult object with #GoGameResultDataTypeSgfString
/// and the supplied string value @a sgfString. The update policy is
/// #GoGameResultUpdatePolicyAutomatic.
///
/// @exception NSInvalidArgumentException Is raised if @a sgfString is @e nil.
// -----------------------------------------------------------------------------
- (id) initWithSgfString:(NSString*)sgfString
{
  return [self initWithDataType:GoGameResultDataTypeSgfString
                      sgfString:sgfString
                 gameResultType:GoGameResultTypeUnknownResult
                        winType:GoGameResultWinTypeWinWithScore
                          score:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameResult object with
/// #GoGameResultDataTypeStructuredData and the supplied game result type
/// @a gameResultType. @a gameResultType must be one of the values @b not
/// indicating that one of the player wins The update policy is
/// #GoGameResultUpdatePolicyAutomatic..
///
/// @exception NSInvalidArgumentException Is raised if @a gameResultType is not
/// one of #GoGameResultTypeDraw, #GoGameResultTypeNoResult or
/// #GoGameResultTypeUnknownResult.
// -----------------------------------------------------------------------------
- (id) initWithNoPlayerWin:(enum GoGameResultType)gameResultType
{
  switch (gameResultType)
  {
    case GoGameResultTypeDraw:
    case GoGameResultTypeNoResult:
    case GoGameResultTypeUnknownResult:
      break;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Failed to initialize GoGameResult, game result type should be a \"no win\" type, but is %ld"
                                                  argumentValue:gameResultType];
      break;
  }

  return [self initWithDataType:GoGameResultDataTypeStructuredData
                      sgfString:nil
                 gameResultType:gameResultType
                        winType:GoGameResultWinTypeWinWithScore
                          score:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameResult object with
/// #GoGameResultDataTypeStructuredData and the supplied win type @a winType.
/// @a winType must not be #GoGameResultWinTypeWinWithScore. @a blackPlayerWins
/// indicates whether the black or the white player wins and is used to derive
/// the game result type. The update policy is
/// #GoGameResultUpdatePolicyAutomatic.
///
/// @exception NSInvalidArgumentException Is raised if @a winType is
/// #GoGameResultWinTypeWinWithScore.
// -----------------------------------------------------------------------------
- (id) initWithNoScorePlayerWin:(bool)blackPlayerWins
                        winType:(enum GoGameResultWinType)winType
{
  if (winType == GoGameResultWinTypeWinWithScore)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Failed to initialize GoGameResult, win type should be a \"no score\" type, but is %ld"
                                                argumentValue:winType];
  }

  return [self initWithDataType:GoGameResultDataTypeStructuredData
                      sgfString:nil
                 gameResultType:(blackPlayerWins
                                 ? GoGameResultTypeBlackWin
                                 : GoGameResultTypeWhiteWin)
                        winType:winType
                          score:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameResult object with
/// #GoGameResultDataTypeStructuredData and the supplied score value @a score.
/// @a score must not be negative. @a blackPlayerWins indicates whether the
/// black or the white player wins and is used to derive the game result type.
/// @a winType is set to #GoGameResultWinTypeWinWithScore. The update policy is
/// #GoGameResultUpdatePolicyAutomatic.
// -----------------------------------------------------------------------------
- (id) initWithPlayerWin:(bool)blackPlayerWins
                   score:(double)score
{
  return [self initWithDataType:GoGameResultDataTypeStructuredData
                      sgfString:nil
                 gameResultType:(blackPlayerWins
                                 ? GoGameResultTypeBlackWin
                                 : GoGameResultTypeWhiteWin)
                        winType:GoGameResultWinTypeWinWithScore
                          score:score];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameResult object with the supplied values.
///
/// @exception NSInvalidArgumentException Is raised in the following cases:
/// - If @a dataType is #GoGameResultDataTypeSgfString and @a sgfString is
///   @e nil.
/// - If @a dataType is not #GoGameResultDataTypeSgfString and @a sgfString is
///   not @e nil.
///
/// @note This is the designated initializer of GoGameResult.
// -----------------------------------------------------------------------------
- (id) initWithDataType:(enum GoGameResultDataType)dataType
              sgfString:(NSString*)sgfString
         gameResultType:(enum GoGameResultType)gameResultType
                winType:(enum GoGameResultWinType)winType
                  score:(double)score
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  if (dataType == GoGameResultDataTypeSgfString && ! sgfString)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize GoGameResult, SGF string is missing"];
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }
  else if (dataType != GoGameResultDataTypeSgfString && sgfString != nil)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize GoGameResult, SGF string is present although data type %d is not GoGameResultDataTypeSgfString", dataType];
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  // We accept all score values - even negative ones - so that all SGF data
  // (even strange data) is preserved when it makes a round-trip through
  // GoGameResult.

  self.dataType = dataType;
  self.sgfString = sgfString;
  self.gameResultType = gameResultType;
  self.winType = winType;
  self.score = score;
  self.updatePolicy = GoGameResultUpdatePolicyAutomatic;

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

  self.dataType = [decoder decodeIntForKey:goGameResultDataTypeKey];
  self.sgfString = [decoder decodeObjectOfClass:[NSString class] forKey:goGameResultSgfStringKey];
  self.gameResultType = [decoder decodeIntForKey:goGameResultGameResultTypeKey];
  self.winType = [decoder decodeIntForKey:goGameResultWinTypeKey];
  self.score = [decoder decodeDoubleForKey:goGameResultScoreKey];
  self.updatePolicy = [decoder decodeIntForKey:goGameResultUpdatePolicyKey];

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

  [encoder encodeInt:self.dataType forKey:goGameResultDataTypeKey];
  [encoder encodeObject:self.sgfString forKey:goGameResultSgfStringKey];
  [encoder encodeInt:self.gameResultType forKey:goGameResultGameResultTypeKey];
  [encoder encodeInt:self.winType forKey:goGameResultWinTypeKey];
  [encoder encodeDouble:self.score forKey:goGameResultScoreKey];
  [encoder encodeInt:self.updatePolicy forKey:goGameResultUpdatePolicyKey];
}

@end
