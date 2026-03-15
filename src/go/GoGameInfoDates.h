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
/// @brief The GoGameInfoDates class stores the "dates" game info property
/// value, i.e. a list of dates when the game was played. Its direct
/// correspondence is the SGF property "DT".
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoGameInfoDates : NSObject <NSSecureCoding>
{
}

- (id) init;
- (id) initWithSgfString:(NSString*)sgfString;
- (id) initWithDateComponents:(NSArray*)dateComponents;

/// @brief Indicates the kind of data that the GoGameInfoDates object holds.
///
/// The default value is #GoGameInfoDatesDataTypeNone.
@property(nonatomic, assign) enum GoGameInfoDatesDataType dataType;

/// @brief A string representation of the date(s) when the game was played, as
/// read directly from SGF data. The string does not conform to the format
/// mandated by the FF4 SGF specification. It is retained in its raw form so
/// that the original data can survive a round-trip when it is written back to
/// SGF.
///
/// This property is @e nil unless @e dataType has the value
/// #GoGameResultDataTypeSgfString.
///
/// The default value is @e nil.
@property(nonatomic, retain) NSString* sgfString;

/// @brief A list of NSDateComponents objects.
///
/// This property contains an empty list unless @e dataType has the value
/// #GoGameInfoDatesDataTypeStructuredData.
///
/// The default value is an empty list.
///
/// NSDateComponent objects must contain at least a year component. Optionally
/// NSDateComponent may also contain a month component, or a month and a day
/// component. GoGameInfoDates does not enforce these restrictions, but if the
/// list contains NSDateComponent objects that violate the restrictions then
/// the encoding to SGF will likely fail.
///
/// @note The order in which NSDateComponents appear in the list influences
/// how shortcuts are built when the dates are encoded and written to SGF. The
/// ideal order for shortcut building is 1) earliest dates first; and then
/// 2) dates with less precision before dates with more precision (so that dates
/// with more precision may be able to profit from date parts that the previous
/// date already provided).
@property(nonatomic, retain) NSArray* dateComponents;

@end
