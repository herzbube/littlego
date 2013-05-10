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


// Project includes
#import "PlayViewIntersection.h"


const PlayViewIntersection PlayViewIntersectionNull = { nil, { 0.0, 0.0 } };


PlayViewIntersection PlayViewIntersectionMake(GoPoint* point, CGPoint coordinates)
{
  PlayViewIntersection intersection;
  intersection.point = point;
  intersection.coordinates = coordinates;
  return intersection;
}

bool PlayViewIntersectionEqualToIntersection(PlayViewIntersection intersection1, PlayViewIntersection intersection2)
{
  if (intersection1.point != intersection2.point)
    return false;
  return CGPointEqualToPoint(intersection1.coordinates, intersection2.coordinates);
}

bool PlayViewIntersectionIsNullIntersection(PlayViewIntersection intersection)
{
  return PlayViewIntersectionEqualToIntersection(intersection, PlayViewIntersectionNull);
}

