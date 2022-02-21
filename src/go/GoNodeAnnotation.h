// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The GoNodeAnnotation class collects information that is not related
/// to any specific place on the Go board, but marks the whole node instead.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoNodeAnnotation : NSObject <NSCoding>
{
}

/// @brief Updates the property @e estimatedScoreSummary with the value of
/// @a goScoreSummary, and the property @e estimatedScoreValue with the value of
/// @a goScoreValue. Returns true if the update was successful, returns false if
/// the update failed due to an illegal combination of @a goScoreSummary and
/// @a goScoreValue.
///
/// If @a goScoreSummary is #GoScoreSummaryNone, this method ignores the value
/// of @a goScoreValue, resets the property @e estimatedScoreValue to 0.0, and
/// returns true.
///
/// If @a GoScoreSummary is #GoScoreSummaryBlackWins or
/// #GoScoreSummaryWhiteWins, the value of @a goScoreValue must be greater than
/// zero, otherwise this method returns false.
///
/// If @a GoScoreSummary is #GoScoreSummaryTie, the value of @a goScoreValue
/// must be zero, otherwise this method returns false.
- (bool) setEstimatedScoreSummary:(enum GoScoreSummary)goScoreSummary value:(double)goScoreValue;

/// @brief A short text without newlines, describing the node. Is @e nil if no
/// short description is available. The default value is @e nil.
///
/// There is no guarantee that the description is actually short. When the
/// property is set no attempt is made to restrict the length of the string.
///
/// When the property is set, any newlines that the new value contains are
/// converted to a space character.
///
/// This property corresponds to the SGF node annotation property N (node
/// name).
@property(nonatomic, retain) NSString* shortDescription;

/// @brief A long text which may include newlines, describing in detail the
/// node. Is @e nil if no long description is available. The default value is
/// @e nil.
///
/// There is no guarantee that the description is actually long. The presence
/// of a long description is no guarantee that a short description exists.
///
/// This property corresponds to the SGF node annotation property C (comment
/// text).
@property(nonatomic, retain) NSString* longDescription;

/// @brief The valuation of the board position in the node. The default value is
/// #GoBoardPositionValuationNone.
///
/// This property corresponds to the presence or absence of the SGF node
/// annotation properties GB, GW, DM and UC.
@property(nonatomic, assign) enum GoBoardPositionValuation goBoardPositionValuation;

/// @brief The hotspot designation of the node. The default value is
/// #GoBoardPositionHotspotDesignationNone.
///
/// This property corresponds to the SGF node annotation property HO.
@property(nonatomic, assign) enum GoBoardPositionHotspotDesignation goBoardPositionHotspotDesignation;

/// @brief The summary of the estimated score at the position in the node. To
/// find out the actual score the property @e estimatedScoreValue must be
/// evaluated. The default value is #GoScoreSummaryNone.
///
/// To avoid illegal combinations of values, the method
/// setEstimatedScoreSummary:value:() must always be used to update this
/// property in conjunction with property @e estimatedScoreValue.
///
/// This property, together with the property @e estimatedScore, corresponds to
/// the SGF node annotation property V (node value).
@property(nonatomic, assign, readonly) enum GoScoreSummary estimatedScoreSummary;

/// @brief The estimated score value at the position in the node. To find out
/// whether a non-zero value indicates a win for black or white the property
/// @e estimatedScoreSummary must be evaluated. The default value is 0.0.
///
/// The value of this property is never negative. The value of this property
/// is always 0.0 (zero) if the property @e estimatedScoreSummary has value
/// #GoScoreSummaryTie or #GoScoreSummaryNone.
///
/// To avoid illegal combinations of values, the method
/// setEstimatedScoreSummary:value:() must always be used to update this
/// property in conjunction with property @e estimatedScoreSummary.
///
/// This property, together with the property @e estimatedScoreSummary,
/// corresponds to the SGF node annotation property V (node value).
@property(nonatomic, assign, readonly) double estimatedScoreValue;

@end
