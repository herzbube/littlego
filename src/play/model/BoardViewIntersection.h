// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The BoardViewIntersection struct is a simple container that
/// associates a GoPoint object with the view coordinates of the intersection
/// represented by the GoPoint object.
///
/// The coordinates are in the coordinate system of the canvas that represents
/// the full Go board. This canvas is equal to the content of the scroll view
/// that displays the part of the Go board that is currently visible. Location
/// and sizes of board elements on the canvas are managed by the
/// BoardViewMetrics class.
// -----------------------------------------------------------------------------
struct BoardViewIntersection
{
  GoPoint* point;
  CGPoint coordinates;
};
typedef struct BoardViewIntersection BoardViewIntersection;


// -----------------------------------------------------------------------------
/// @brief The "null" intersection - equivalent to
/// BoardViewIntersectionMake(nil, CGPointZero)
// -----------------------------------------------------------------------------
extern const BoardViewIntersection BoardViewIntersectionNull;


// Helper functions similar to those in CoreGraphics (e.g. CGPointMake)
extern BoardViewIntersection BoardViewIntersectionMake(GoPoint* point, CGPoint coordinates);
extern bool BoardViewIntersectionEqualToIntersection(BoardViewIntersection intersection1, BoardViewIntersection intersection2);
extern bool BoardViewIntersectionIsNullIntersection(BoardViewIntersection intersection);

