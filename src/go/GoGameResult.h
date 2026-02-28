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


/// @brief Enumerates the kinds of data that a GoGameResult object can hold.
///
/// @ingroup go
enum GoGameResultDataType
{
  /// @brief The data stored by the GoGameResult object does not represent a
  /// game result.
  GoGameResultDataTypeNoResult,

  /// @brief The GoGameResult object holds a game result that is described by a
  /// string that was read from SGF data. The string does not conform to the
  /// format mandated by the FF4 SGF specification and can therefore not be
  /// parsed and transformed into structured data.
  GoGameResultDataTypeSgfString,

  /// @brief The GoGameResult object holds a game result that is described by
  /// structured data, i.e. at least a #GoGameResultType value, possibly
  /// accompanied by a #GoGameResultWinType value and a score value to further
  /// describe the game result in more detail.
  GoGameResultDataTypeStructuredData,
};

/// @brief GoGameResultType enumerates the main result types with which a game
/// can end. Depending on the enumeration value, additional values are needed
/// to determine the exact nature of the game result.
///
/// @ingroup go
enum GoGameResultType
{
  /// @brief The black player wins the game. The nature of the win is detailed
  /// by an accompanying GoGameResultWinType value.
  GoGameResultTypeBlackWin,

  /// @brief The white player wins. The nature of the win is detailed
  /// by an accompanying GoGameResultWinType value.
  GoGameResultTypeWhiteWin,

  /// @brief The game ends with a draw (jigo).
  GoGameResultTypeDraw,

  /// @brief The game ends with no result, or with suspended play.
  GoGameResultTypeNoResult,

  /// @brief The game ends with an unknown result.
  GoGameResultTypeUnknownResult,
};

/// @brief GoGameResultWinType enumerates how a player can win a game. A
/// GoGameResultWinType value is used to accompany a game result type value of
/// either #GoGameResultTypeBlackWin or #GoGameResultTypeWhiteWin.
///
/// @ingroup go
enum GoGameResultWinType
{
  /// @brief The player wins the game by normal play. A score was established.
  /// The actual score is detailed by an accompanying non-negative numeric
  /// value.
  GoGameResultWinTypeWinWithScore,

  /// @brief The player wins the game by normal play. No score was established,
  /// or the score was not recorded.
  GoGameResultWinTypeWinWithoutScore,

  /// @brief The player wins the game by resignation.
  GoGameResultWinTypeWinByResignation,

  /// @brief The player wins the game on time.
  GoGameResultWinTypeWinOnTime,

  /// @brief The player wins the game by forfeit.
  GoGameResultWinTypeWinByForfeit,
};

/// @brief Enumerates ways how the data in a GoGameResult object can be updated.
///
/// @ingroup go
enum GoGameResultUpdatePolicy
{
  /// @brief The app is allowed to automatically update the GoGameResult
  /// object's data, based on game results obtained from game play, overwriting
  /// any previously established game result.
  ///
  /// Example: If the black player resigns, the app is allowed to set the
  /// GoGameResult object's data with #GoGameResultTypeBlackWin
  /// and #GoGameResultWinTypeWinByResignation.
  GoGameResultUpdatePolicyAutomatic,

  /// @brief The app is not allowed to automatically update the GoGameResult
  /// object's data. The data may only be manually updated by the user.
  GoGameResultUpdatePolicyManual
};

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
/// The default value is #GoGameResultWinTypeWinWithScore.
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
