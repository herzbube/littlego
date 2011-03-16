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
#import "GoPoint.h"


@interface GoBoard(Private)
- (void) dealloc;
@end


@implementation GoBoard

@synthesize size;

+ (GoBoard*) boardWithSize:(int)size
{
  GoBoard* board = [[GoBoard alloc] init];
  if (board)
  {
    board.size = size;
    [board autorelease];
  }
  return board;
}

- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.size = 0;
  m_points = [[NSMutableDictionary dictionary] retain];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DGSMonXServer object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [m_points release];
  [super dealloc];
}

- (GoPoint*) pointWithVertex:(NSString*)vertex
{
  GoPoint* point = [m_points objectForKey:vertex];
  if (! point)
  {
    point = [GoPoint pointFromVertex:vertex];
    [m_points setObject:point forKey:vertex];
  }
  return point;
}

- (NSEnumerator*) pointEnumerator
{
  // The value array including the enumerator will be destroyed as soon as
  // the current execution path finishes
  return [[m_points allValues] objectEnumerator];
}

@end
