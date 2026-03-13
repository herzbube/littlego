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
/// @brief The GoGameInfoRank class stores the "rank information" game info
/// property value for a player. Its direct correspondences are the SGF
/// properties "BR" (black player ranK) and "WR" (white player rank).
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoGameInfoRank : NSObject <NSSecureCoding>
{
}

- (id) init;
- (id) initWithSgfString:(NSString*)sgfString;
- (id) initWithRankType:(enum GoGameInfoRankType)rankType
                   rank:(long)rank
             ratingType:(enum GoGameInfoRatingType)ratingType;

/// @brief Indicates the kind of data that the GoGameInfoRank object holds.
///
/// The default value is #GoGameInfoRankDataTypeNone.
@property(nonatomic, assign) enum GoGameInfoRankDataType dataType;

/// @brief A single string describing the rank.
///
/// This property is @e nil unless @e dataType has the value
/// #GoGameInfoRankDataTypeSgfString.
///
/// The default value is @e nil.
@property(nonatomic, retain) NSString* sgfString;

/// @brief The rank type.
///
/// This property only holds a useful value if @e dataType has the
/// value #GoGameInfoRankDataTypeStructuredData.
///
/// The default value is #GoGameInfoRankTypeKyu.
@property(nonatomic, assign) enum GoGameInfoRankType rankType;

/// @brief The rank.
///
/// This property only holds a useful value if @e dataType has the
/// value #GoGameInfoRankDataTypeStructuredData.
///
/// The default value is 30.
@property(nonatomic, assign) long rank;

/// @brief The optional rating type that applies to the rank (e.g. the rank
/// is established).
///
/// This property only holds a useful value if @e dataType has the
/// value #GoGameInfoRankDataTypeStructuredData.
///
/// The default value is #GoGameInfoRatingTypeUnspecified.
@property(nonatomic, assign) enum GoGameInfoRatingType ratingType;

@end
