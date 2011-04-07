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
/// @defgroup go Go module
///
/// Classes in this module directly relate to an aspect of the actual Go game
/// (e.g. GoBoard represents the Go board).
// -----------------------------------------------------------------------------


// Project includes
#import "GoBoard.h"
#import "GoBoardRegion.h"
#import "GoPoint.h"
#import "GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoBoard.
// -----------------------------------------------------------------------------
@interface GoBoard()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
@end


@implementation GoBoard

@synthesize size;

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoard instance of size 0.
// -----------------------------------------------------------------------------
+ (GoBoard*) board
{
  GoBoard* board = [[GoBoard alloc] init];
  if (board)
    [board autorelease];
  return board;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoBoard object with size 0.
///
/// @note This is the designated initializer of GoBoard.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.size = 0;
  m_vertexDict = [[NSMutableDictionary dictionary] retain];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoBoard object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [m_vertexDict release];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Adjusts the size of this GoBoard object to @a newValue.
///
/// This function should only be called while the game has not yet started.
// -----------------------------------------------------------------------------
- (void) setSize:(int)newValue
{
  @synchronized(self)
  {
    if (size == newValue)
      return;
    size = newValue;
    [m_vertexDict removeAllObjects];
    GoPoint* point = [self pointAtVertex:@"A1"];
    GoBoardRegion* region = [GoBoardRegion regionWithPoint:point];
    point.region = region;
    for (; point = point.next; point != nil)
    {
      point.region = region;
      [region addPoint:point];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an enumerator that can be used to iterate over all existing
/// GoPoint objects
///
/// @todo Remove this method, clients should instead use GoPoint::next() or
/// GoPoint::previous() for iteration.
// -----------------------------------------------------------------------------
- (NSEnumerator*) pointEnumerator
{
  // The value array including the enumerator will be destroyed as soon as
  // the current execution path finishes
  return [[m_vertexDict allValues] objectEnumerator];
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object located at @a vertex.
///
/// See the GoVertex class documentation for a discussion of what a vertex is.
// -----------------------------------------------------------------------------
- (GoPoint*) pointAtVertex:(NSString*)vertex
{
  GoPoint* point = [m_vertexDict objectForKey:vertex];
  if (! point)
  {
    point = [GoPoint pointAtVertex:[GoVertex vertexFromString:vertex]];
    [m_vertexDict setObject:point forKey:vertex];
  }
  return point;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is a direct neighbour of @a point
/// located in direction @a direction.
///
/// Returns nil if no neighbour exists in the specified direction. For instance,
/// if @a point is at the left edge of the board, it has no left neighbour,
/// which will cause a nil value to be returned.
///
/// @note #NextDirection and #PreviousDirection are intended to iterate over
/// all existing GoPoint objects.
///
/// @internal This is the backend for the GoPoint directional properties (e.g.
/// GoPoint::left()).
// -----------------------------------------------------------------------------
- (GoPoint*) neighbourOf:(GoPoint*)point inDirection:(enum GoBoardDirection)direction
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  switch (direction)
  {
    case LeftDirection:
      numericVertex.x--;
      if (numericVertex.x < 1)
        return nil;
      break;
    case RightDirection:
      numericVertex.x++;
      if (numericVertex.x > self.size)
        return nil;
      break;
    case UpDirection:
      numericVertex.y++;
      if (numericVertex.y > self.size)
        return nil;
      break;
    case DownDirection:
      numericVertex.y--;
      if (numericVertex.y < 1)
        return nil;
      break;
    case NextDirection:
      numericVertex.x++;
      if (numericVertex.x > self.size)
      {
        numericVertex.x = 1;
        numericVertex.y++;
        if (numericVertex.y > self.size)
          return nil;
      }
      break;
    case PreviousDirection:
      numericVertex.x--;
      if (numericVertex.x < 1)
      {
        numericVertex.x = self.size;
        numericVertex.y--;
        if (numericVertex.y < 1)
          return nil;
      }
      break;
    default:
      return nil;
  }
  GoVertex* vertex = [GoVertex vertexFromNumeric:numericVertex];
  return [self pointAtVertex:vertex.string];
}

@end
