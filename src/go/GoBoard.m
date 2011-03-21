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


// Project includes
#import "GoBoard.h"
#import "GoBoardRegion.h"
#import "GoPoint.h"
#import "GoVertex.h"

@interface GoBoard(Private)
- (void) dealloc;
@end


@implementation GoBoard

@synthesize size;

+ (GoBoard*) board
{
  GoBoard* board = [[GoBoard alloc] init];
  if (board)
    [board autorelease];
  return board;
}

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

- (void) dealloc
{
  [m_vertexDict release];
  [super dealloc];
}

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

- (NSEnumerator*) pointEnumerator
{
  // The value array including the enumerator will be destroyed as soon as
  // the current execution path finishes
  return [[m_vertexDict allValues] objectEnumerator];
}

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

// this is the helper being called by GoPoint properties
// left/right/above/below/next
// direction "next" and previous are mainly intended for iteration over all
// the points of the board; next = moves to the right and then up; previous =
// moves the left and down
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
