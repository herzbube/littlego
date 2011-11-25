// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Helper struct to bind the numeric compounds of a GoVertex together.
///
/// @ingroup go
// -----------------------------------------------------------------------------
struct GoVertexNumeric
{
  int x;   ///< @brief Horizontal axis compound of the vertex.
  int y;   ///< @brief Vertical axis compound of the vertex.
};

// -----------------------------------------------------------------------------
/// @brief The GoVertex class stores the coordinates that uniquely identify the
/// intersection of a horizontal and a vertical line on the Go board. GoVertex
/// objects are immutable, i.e. they cannot be changed once they have been
/// created.
///
/// @ingroup go
///
/// Vertexes are given as human-readable strings such as "C13". "A1" is in the
/// lower-left corner of the Go board. The letter axis is horizontal, the
/// number axis is vertical. The letter "I" is not used.
///
/// A numeric vertex is a conversion of the compounds of a string vertex into
/// their numeric values. The number axis conversion is 1:1, but letters are
/// converted so that A=1, B=2, etc. The gap caused by the unused letter "I" is
/// closed, i.e. H=8, J=9. The compounds of a numeric vertex are bound together
/// by the helper struct GoVertexNumeric.
///
/// GoVertex supports values in the range 1..19 on both axis.
// -----------------------------------------------------------------------------
@interface GoVertex : NSObject
{
}

+ (GoVertex*) vertexFromNumeric:(struct GoVertexNumeric)numericValue;
+ (GoVertex*) vertexFromString:(NSString*)stringValue;
- (bool) isEqualToVertex:(GoVertex*)vertex;

/// @brief The vertex in its human-readable string format.
@property(nonatomic, retain, readonly) NSString* string;
/// @brief The vertex in its numeric form, which is easier to process in
/// calculations and iterations.
@property(nonatomic, assign, readonly) struct GoVertexNumeric numeric;

@end
