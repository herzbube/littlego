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
/// @brief The GoGameInfoRules class stores the "game rules" game info property
/// value. Its direct correspondence is the SGF property "RU". Unlike
/// GoGameRules, GoGameInfoRules is merely informational and has no influence on
/// the actual game play.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoGameInfoRules : NSObject <NSSecureCoding>
{
}

- (id) init;
- (id) initWithSgfString:(NSString*)sgfString;

/// @brief Indicates the game rule that the GoGameInfoRules object holds.
///
/// Setting this property automatically adjusts the value of property
/// @a sgfString as follows:
/// - If the new value is #GoGameInfoRuleNone, sets @e nil.
/// - If the new value is one of those pre-defined by the SGF specification,
///   sets the corresponding pre-defined string.
/// - If the new value is #GoGameInfoRuleSgfString, sets @e nil.
///
/// The default value is #GoGameInfoRuleNone.
@property(nonatomic, assign) enum GoGameInfoRule gameInfoRule;

/// @brief A string representation of the game rule stored in @a gameInfoRule.
///
/// Setting this property automatically adjusts the value of property
/// @a gameInfoRule as follows:
/// - If the new value is @e nil or an empty string, sets #GoGameInfoRuleNone.
/// - If the new value is not @e nil or an empty string, but one of the strings
///   pre-defined by the SGF specification, sets the #GoGameInfoRule values that
///   corresponds to the pre-defined string.
/// - If the new value is not @e nil or an empty string, and also not one of
///   the strings pre-defined by the SGF specification, sets
///   #GoGameInfoRuleSgfString.
///
/// The setter of this property also performs the following transformations of
/// the supplied value, resulting in the property holding a different value
/// than the caller supplied:
/// - The supplied value is trimmed, i.e. the property afterwards holds a string
///   where whitespace was removed on both sides.
/// - After trimming, if an empty string remains, the property afterwards holds
///   @e nil.
/// - After trimming, if a string remains that only differs in capitalization
///   from one of the strings pre-defined by the SGF specification, the property
///   afterwards holds the correctly capitalized string.
///
/// The default value is @e nil.
@property(nonatomic, retain) NSString* sgfString;

@end
