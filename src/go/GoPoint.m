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
#import "GoPoint.h"
#import "GoGame.h"
#import "GoBoard.h"


@implementation GoPoint

@synthesize vertex;
@synthesize left;
@synthesize right;
@synthesize above;
@synthesize below;
@synthesize neighbours;
@synthesize next;
@synthesize previous;
@synthesize starPoint;
@synthesize stoneState;
@synthesize region;


+ (GoPoint*) pointAtVertex:(GoVertex*)vertex
{
  GoPoint* point = [[GoPoint alloc] init];
  if (point)
  {
    point.vertex = vertex;
    [point autorelease];
  }
  return point;
}

- (GoPoint*) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.vertex = nil;
  self.starPoint = false;
  self.stoneState = NoStone;
  left = nil;
  right = nil;
  above = nil;
  below = nil;
  next = nil;
  previous = nil;
  neighbours = nil;

  return self;
}

- (void) dealloc
{
  self.vertex = nil;
  [neighbours release];
  [super dealloc];
}

- (GoPoint*) left
{
  if (! left)
    left = [[GoGame sharedGame].board neighbourOf:self inDirection:LeftDirection];
  return left;
}

- (GoPoint*) right
{
  if (! right)
    right = [[GoGame sharedGame].board neighbourOf:self inDirection:RightDirection];
  return right;
}

- (GoPoint*) above
{
  if (! above)
    above = [[GoGame sharedGame].board neighbourOf:self inDirection:UpDirection];
  return above;
}

- (GoPoint*) below
{
  if (! below)
    below = [[GoGame sharedGame].board neighbourOf:self inDirection:DownDirection];
  return below;
}

- (NSArray*) neighbours
{
  if (! neighbours)
  {
    neighbours = [[NSMutableArray arrayWithCapacity:0] retain];
    if (self.left)
      [(NSMutableArray*)neighbours addObject:self.left];
    if (self.right)
      [(NSMutableArray*)neighbours addObject:self.right];
    if (self.above)
      [(NSMutableArray*)neighbours addObject:self.above];
    if (self.below)
      [(NSMutableArray*)neighbours addObject:self.below];
  }
  return neighbours;
}

- (GoPoint*) next
{
  if (! next)
    next = [[GoGame sharedGame].board neighbourOf:self inDirection:NextDirection];
  return next;
}

- (GoPoint*) previous
{
  if (! previous)
    previous = [[GoGame sharedGame].board neighbourOf:self inDirection:PreviousDirection];
  return previous;
}

- (void) setStoneState:(enum GoStoneState)newValue
{
  @synchronized(self)
  {
    if (stoneState == newValue)
      return;
    stoneState = newValue;
  }
}

- (bool) hasStone
{
  return (NoStone != self.stoneState);
}

- (bool) blackStone
{
  return (BlackStone == self.stoneState);
}

- (int) liberties
{
  if ([self hasStone])
    return [self.region liberties];
  else
  {
    int liberties = 0;
    for (GoPoint* neighbour in self.neighbours)
    {
      if (! [neighbour hasStone])
        liberties++;
    }
    return liberties;
  }
}

@end
