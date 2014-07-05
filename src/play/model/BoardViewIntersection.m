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


// Project includes
#import "BoardViewIntersection.h"


const BoardViewIntersection BoardViewIntersectionNull = { nil, { 0.0, 0.0 } };


BoardViewIntersection BoardViewIntersectionMake(GoPoint* point, CGPoint coordinates)
{
  BoardViewIntersection intersection;
  intersection.point = point;
  intersection.coordinates = coordinates;
  return intersection;
}

bool BoardViewIntersectionEqualToIntersection(BoardViewIntersection intersection1, BoardViewIntersection intersection2)
{
  if (intersection1.point != intersection2.point)
    return false;
  return CGPointEqualToPoint(intersection1.coordinates, intersection2.coordinates);
}

bool BoardViewIntersectionIsNullIntersection(BoardViewIntersection intersection)
{
  return BoardViewIntersectionEqualToIntersection(intersection, BoardViewIntersectionNull);
}

