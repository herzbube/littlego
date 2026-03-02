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


// -----------------------------------------------------------------------------
/// @brief The GoGameResult class stores the overall game result. Its direct
/// correspondence is the SGF property "RE".
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoGameResult : NSObject <NSSecureCoding>
{
}

- (id) init;
- (id) initWithSgfString:(NSString*)sgfString;
- (id) initWithNoPlayerWin:(enum GoGameResultType)gameResultType;
- (id) initWithNoScorePlayerWin:(bool)blackPlayerWins
                        winType:(enum GoGameResultWinType)winType;
- (id) initWithPlayerWin:(bool)blackPlayerWins
                   score:(double)score;

/// @brief Indicates the kind of data that the GoGameResult object holds.
///
/// The default value is #GoGameResultDataTypeNoResult.
@property(nonatomic, assign) enum GoGameResultDataType dataType;

/// @brief A string representation of the game result as read directly from SGF
/// data. The string does not conform to the format mandated by the FF4 SGF
/// specification. It is retained in its raw form so that the original data
/// can survive a round-trip when it is written back to SGF.
///
/// This property is @e nil unless @e dataType has the value
/// #GoGameResultDataTypeSgfString.
@property(nonatomic, retain) NSString* sgfString;

/// @brief The result type.
///
/// The default value is #GoGameResultTypeUnknownResult.
///
/// This property only holds a useful value if @e dataType has the
/// value #GoGameResultDataTypeStructuredData.
@property(nonatomic, assign) enum GoGameResultType gameResultType;

/// @brief The win type.
///
/// The default value is #GoGameResultWinTypeWinWithoutScore.
///
/// This property only holds a useful value if @e dataType has the
/// value #GoGameResultDataTypeStructuredData. In addition, the win type only
/// has meaning if the @e gameResultType property is
/// either #GoGameResultTypeBlackWin or #GoGameResultTypeWhiteWin.
@property(nonatomic, assign) enum GoGameResultWinType winType;

/// @brief The score. Fractional values are allowed because of komi.
///
/// Although the property's data type allows negative values (double cannot be
/// unsigned), only zero or positive score values are valid.
///
/// The default value is 0.0.
///
/// This property only holds a useful value if @e dataType has the
/// value #GoGameResultDataTypeStructuredData. In addition, the score only
/// has meaning if the @e gameResultType property is
/// either #GoGameResultTypeBlackWin or #GoGameResultTypeWhiteWin and
/// if the @e winType property is #GoGameResultWinTypeWinWithScore.
@property(nonatomic, assign) double score;

/// @brief Indicates how the GoGameResult object's data can be updated.
///
/// The default value is #GoGameResultUpdatePolicyAutomatic.
@property(nonatomic, assign) enum GoGameResultUpdatePolicy updatePolicy;

@end
