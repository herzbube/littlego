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
#import "GoBoardRegion.h"
#import "GoPoint.h"


@interface GoBoardRegion(Private)
- (void) setPoints:(NSArray*)points;
- (void) splitNonStoneRegionIfRequired;
@end

@implementation GoBoardRegion

@synthesize points;
@synthesize color;

+ (GoBoardRegion*) regionWithPoints:(NSArray*)points
{
  GoBoardRegion* region = [[GoBoardRegion alloc] init];
  if (region)
  {
    region.points = points;
    [region autorelease];
  }
  return region;
}

+ (GoBoardRegion*) regionWithPoint:(GoPoint*)point
{
  GoBoardRegion* region = [[GoBoardRegion alloc] init];
  if (region)
  {
    [region addPoint:point];
    [region autorelease];
  }
  return region;
}

- (GoBoardRegion*) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  points = [[NSMutableArray arrayWithCapacity:0] retain];

  CGFloat red = (CGFloat)random() / (CGFloat)RAND_MAX;
  CGFloat blue = (CGFloat)random() / (CGFloat)RAND_MAX;
  CGFloat green = (CGFloat)random() / (CGFloat)RAND_MAX;
  self.color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];

  return self;
}

- (void) dealloc
{
  [points release];
  points = nil;
  [super dealloc];
}

- (NSArray*) points
{
  @synchronized(self)
  {
    return [points copy];
  }
}

- (void) setPoints:(NSArray*)newValue
{
  @synchronized(self)
  {
    [(NSMutableArray*)points setArray:newValue];
  }
}

- (int) size
{
  return [points count];
}

- (bool) hasPoint:(GoPoint*)point
{
  return [points containsObject:point];
}

- (void) addPoint:(GoPoint*)point
{
  [(NSMutableArray*)points addObject:point];
}

- (void) removePoint:(GoPoint*)point
{
  [(NSMutableArray*)points removeObject:point];
  [self splitNonStoneRegionIfRequired];
}

- (void) joinRegion:(GoBoardRegion*)region
{
  for (GoPoint* point in [region points])
  {
    point.region = self;
    [(NSMutableArray*)points addObject:point];
  }
}

- (bool) isStoneGroup
{
  if (0 == [points count])
    return false;
  GoPoint* point = [points objectAtIndex:0];
  return [point hasStone];
}

- (bool) hasBlackStones
{
  if (0 == [points count])
    return false;  // todo throw exception? create subclass?
  GoPoint* point = [points objectAtIndex:0];
  if (! [point hasStone])
    return false;  // todo throw exception? create subclass?
  return point.blackStone;
}

- (int) liberties
{
  if (! [self isStoneGroup])
    return -1;  // todo is there a plausible implementation for non-stone groups

  NSMutableArray* libertyPoints = [NSMutableArray arrayWithCapacity:0];
  for (GoPoint* point in self.points)
  {
    for (GoPoint* neighbour in point.neighbours)
    {
      // Is it a liberty?
      if ([neighbour hasStone])
        continue;  // no
      // Count the liberty if it hasn't been counted already
      if (! [libertyPoints containsObject:neighbour])
        [libertyPoints addObject:neighbour];
    }
  }
  return [libertyPoints count];
}

// TODO: The following implementatin is rather brute-force... find a more
// elegant solution...
- (void) splitNonStoneRegionIfRequired
{
  assert(! [self isStoneGroup]);

  NSMutableArray* subRegions = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* pointsToProcess = [self.points mutableCopy];
  while ([pointsToProcess count] > 0)
  {
    // Step 1: Create new subregion that contains the current point and its
    // neighbours that are also in self (the main region)
    GoPoint* pointToProcess = [pointsToProcess objectAtIndex:0];
    NSMutableArray* newSubRegion = [NSMutableArray arrayWithCapacity:0];
    [newSubRegion addObject:pointToProcess];
    for (GoPoint* neighbour in pointToProcess.neighbours)
    {
      if (! [self hasPoint:neighbour])
        continue;
      [newSubRegion addObject:neighbour];
    }
    [pointsToProcess removeObject:pointToProcess];

    // Step 2: Check if there is at least one common point between the new
    // subregion from step 1, and any previously created subregions. If so,
    // the two subregions can be joined
    NSMutableArray* joinableSubRegions = [NSMutableArray arrayWithCapacity:0];
    for (NSMutableArray* previousSubRegion in subRegions)
    {
      for (GoPoint* newPoint in newSubRegion)
      {
        if ([previousSubRegion containsObject:newPoint])
        {
          [joinableSubRegions addObject:previousSubRegion];
          break;
        }
      }
    }

    // Step 3: Permanently keep the new subregion if it can't be joined,
    // otherwise join all subregions that were found to be adjacent
    if (0 == [joinableSubRegions count])
    {
      [subRegions addObject:newSubRegion];
      continue;
    }
    // Treat the new subregion the same as the other ones
    [joinableSubRegions addObject:newSubRegion];
    // Keep the first of the already existing subregions
    NSMutableArray* subRegiontoKeep = nil;
    for (NSMutableArray* joinableSubRegion in joinableSubRegions)
    {
      if (! subRegiontoKeep)
      {
        subRegiontoKeep = joinableSubRegion;
        continue;
      }
      [subRegions removeObject:joinableSubRegion];
      for (GoPoint* joinablePoint in joinableSubRegion)
      {
        if (! [subRegiontoKeep containsObject:joinablePoint])
          [subRegiontoKeep addObject:joinablePoint];
      }
    }
  }

  if ([subRegions count] == 1)  // no split occurred
    return;
  bool keepFirstWithThisRegion = true;
  for (NSMutableArray* subRegion in subRegions)
  {
    if (keepFirstWithThisRegion)
    {
      keepFirstWithThisRegion = false;
      continue;
    }
    [(NSMutableArray*)points removeObjectsInArray:subRegion];
    GoBoardRegion* newRegion = [GoBoardRegion regionWithPoints:subRegion];
    for (GoPoint* point in subRegion)
      point.region = newRegion;
  }
}

@end
