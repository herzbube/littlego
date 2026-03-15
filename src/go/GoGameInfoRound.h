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
/// @brief The GoGameInfoRound class stores the "round information" game info
/// property value. Its direct correspondence is the SGF property "RO".
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoGameInfoRound : NSObject <NSSecureCoding>
{
}

- (id) init;
- (id) initWithSgfString:(NSString*)sgfString;
- (id) initWithRoundType:(NSString*)roundType roundNumber:(NSString*)roundNumber;

/// @brief Indicates the kind of data that the GoGameInfoRound object holds.
///
/// The default value is #GoGameInfoRoundDataTypeNone.
@property(nonatomic, assign) enum GoGameInfoRoundDataType dataType;

/// @brief A single string describing the round.
///
/// If this property is not @e nil, then the properties @e roundType and
/// @e roundNumber are @e nil.
///
/// The default value is @e nil.
@property(nonatomic, retain) NSString* sgfString;

/// @brief A string describing the round type.
///
/// If this property is not @e nil, then the property @e roundNumber also is
/// not @e nil, but the property @e sgfString is @e nil.
///
/// The default value is @e nil.
@property(nonatomic, retain) NSString* roundType;

/// @brief A string describing the round number.
///
/// Although the term "round number" implies a numeric value, the SGF standard
/// does not define a specific value type, therefore the round number can be
/// any textual value.
///
/// If this property is not @e nil, then the property @e roundType also is
/// not @e nil, but the property @e sgfString is @e nil.
///
/// The default value is @e nil.
@property(nonatomic, retain) NSString* roundNumber;

@end
