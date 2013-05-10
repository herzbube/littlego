// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The PlayViewIntersection struct is a simple container that associates
/// a GoPoint object with its corresponding view coordinates in PlayView.
// -----------------------------------------------------------------------------
struct PlayViewIntersection
{
  GoPoint* point;
  CGPoint coordinates;
};
typedef struct PlayViewIntersection PlayViewIntersection;


// -----------------------------------------------------------------------------
/// @brief The "null" intersection - equivalent to
/// PlayViewIntersectionMake(nil, CGPointZero)
// -----------------------------------------------------------------------------
extern const PlayViewIntersection PlayViewIntersectionNull;


// Helper functions similar to those in CoreGraphics (e.g. CGPointMake)
extern PlayViewIntersection PlayViewIntersectionMake(GoPoint* point, CGPoint coordinates);
extern bool PlayViewIntersectionEqualToIntersection(PlayViewIntersection intersection1, PlayViewIntersection intersection2);
extern bool PlayViewIntersectionIsNullIntersection(PlayViewIntersection intersection);

