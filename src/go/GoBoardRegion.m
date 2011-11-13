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


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoBoardRegion.
// -----------------------------------------------------------------------------
@interface GoBoardRegion()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name Private helper methods
//@{
- (void) setPoints:(NSArray*)points;
- (void) splitRegionIfRequired;
- (void) fillCache;
- (void) invalidateCache;
//@}
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Privately declared properties
//@{
@property int cachedSize;
@property bool cachedIsStoneGroup;
@property enum GoColor cachedColor;
@property int cachedLiberties;
@property(retain) NSArray* cachedAdjacentRegions;
//@}
@end


@implementation GoBoardRegion

@synthesize points;
@synthesize randomColor;
@synthesize scoringMode;
@synthesize territoryColor;
@synthesize deadStoneGroup;
@synthesize cachedSize;
@synthesize cachedIsStoneGroup;
@synthesize cachedColor;
@synthesize cachedLiberties;
@synthesize cachedAdjacentRegions;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoardRegion instance that
/// contains the GoPoint objects in @a points.
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoardRegion instance that
/// contains the single GoPoint object @a point.
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
/// @brief Initializes a GoBoardRegion object.
///
/// @note This is the designated initializer of GoBoardRegion.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  points = [[NSMutableArray arrayWithCapacity:0] retain];

  CGFloat red = (CGFloat)random() / (CGFloat)RAND_MAX;
  CGFloat blue = (CGFloat)random() / (CGFloat)RAND_MAX;
  CGFloat green = (CGFloat)random() / (CGFloat)RAND_MAX;
  self.randomColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
  self.scoringMode = false;
  self.territoryColor = GoColorNone;
  self.deadStoneGroup = false;
  [self invalidateCache];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoBoardRegion object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [points release];
  points = nil;
  self.randomColor = nil;
  [self invalidateCache];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoBoardRegion object.
///
/// This method is invoked when GoBoardRegion needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoBoardRegion(%p): point count = %d", self, points.count];
}

// -----------------------------------------------------------------------------
/// @brief Returns the (unordered) list of GoPoint objects in this
/// GoBoardRegion.
// -----------------------------------------------------------------------------
- (NSArray*) points
{
  @synchronized(self)
  {
    if (scoringMode)
      return points;

    return [[points copy] autorelease];
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets the list of GoPoint objects in this GoBoardRegion to
/// @a newValue. No assumption is made about the order of objects in
/// @a newValue.
// -----------------------------------------------------------------------------
- (void) setPoints:(NSArray*)newValue
{
  @synchronized(self)
  {
    [(NSMutableArray*)points setArray:newValue];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the size of this GoBoardRegion, which corresponds to the
/// number of GoPoint objects in this GoBoardRegion.
// -----------------------------------------------------------------------------
- (int) size
{
  if (scoringMode)
    return cachedSize;

  return [points count];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a point is a part of this GoBoardRegion.
// -----------------------------------------------------------------------------
- (bool) hasPoint:(GoPoint*)point
{
  return [points containsObject:point];
}

// -----------------------------------------------------------------------------
/// @brief Adds @a point to this GoBoardRegion.
///
/// @a point must be removed from its previous GoBoardRegion by separately
/// invoking GoBoardRegion::removePoint:().
// -----------------------------------------------------------------------------
- (void) addPoint:(GoPoint*)point
{
  [(NSMutableArray*)points addObject:point];
  // TODO: Check if we can say "point.region = self" here; this would be
  // analogous to what we do in joinRegion:() further down. If this is not
  // possible, document why. If this is possible, also update the doxygen docs
  // of this method, and possibly also the class docs.
}

// -----------------------------------------------------------------------------
/// @brief Removes @a point from this GoBoardRegion.
///
/// Invoking this method may cause this GoBoardRegion to fragment, i.e. other
/// GoBoardRegion objects may come into existence because GoPoint objects within
/// this GoBoardRegion are no longer adjacent.
// -----------------------------------------------------------------------------
- (void) removePoint:(GoPoint*)point
{
  [(NSMutableArray*)points removeObject:point];
  [self splitRegionIfRequired];
}

// -----------------------------------------------------------------------------
/// @brief Joins @a region with this GoBoardRegion, i.e. all GoPoint objects
/// in @a region are added to this GoBoardRegion.
///
/// The GoBoardRegion reference of all GoPoint objects will be updated to this
/// GoBoardRegion. As a result, @a region will be released and should not be
/// used after this method returns.
// -----------------------------------------------------------------------------
- (void) joinRegion:(GoBoardRegion*)region
{
  for (GoPoint* point in [region points])
  {
    point.region = self;
    [(NSMutableArray*)points addObject:point];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if this GoBoardRegion represents a stone group.
// -----------------------------------------------------------------------------
- (bool) isStoneGroup
{
  if (scoringMode)
    return cachedIsStoneGroup;

  if (0 == [points count])
    return false;
  GoPoint* point = [points objectAtIndex:0];
  return [point hasStone];
}

// -----------------------------------------------------------------------------
/// @brief Returns the color of the stones in this GoBoardRegion, or
/// #GoColorNone if this GoBoardRegion does not represent a stone group.
// -----------------------------------------------------------------------------
- (enum GoColor) color
{
  if (scoringMode)
    return cachedColor;

  if (0 == [points count])
    return GoColorNone;
  GoPoint* point = [points objectAtIndex:0];
  return point.stoneState;
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of liberties of the stone group that this
/// GoBoardRegion represents. Returns -1 if this GoBoardRegion does not
/// represent a stone group.
// -----------------------------------------------------------------------------
- (int) liberties
{
  if (scoringMode)
    return cachedLiberties;

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

// -----------------------------------------------------------------------------
/// @brief Returns a list of of GoBoardRegion objects that are direct neighbours
/// of this GoBoardRegion.
// -----------------------------------------------------------------------------
- (NSArray*) adjacentRegions
{
  if (scoringMode)
    return cachedAdjacentRegions;

  NSMutableArray* adjacentRegions = [NSMutableArray arrayWithCapacity:0];
  for (GoPoint* point in self.points)
  {
    for (GoPoint* neighbour in point.neighbours)
    {
      // Is the neighbour in an adjacent region?
      GoBoardRegion* adjacentRegion = neighbour.region;
      if (adjacentRegion == self)
        continue;  // no
      // Count the adjacent region if it hasn't been counted already
      if (! [adjacentRegions containsObject:adjacentRegion])
        [adjacentRegions addObject:adjacentRegion];
    }
  }
  return adjacentRegions;
}

// -----------------------------------------------------------------------------
/// @brief Splits this GoBoardRegion if any of the GoPoint objects within it
/// are not adjacent.
///
/// Additional GoBoardRegion objects are created by this method if it detects
/// that this GoBoardRegion has fragmented into smaller, non-adjacent sets of
/// GoPoint objects. No assumption is made about the reason why the
/// fragmentation occurred.
///
/// This method does nothing and returns immediately if this GoBoardRegion
/// represents a stone group. The reason for this is efficieny, combined with
/// the knowledge that stone groups can never fragment if the game proceeds in
/// a regular fashion. A stone group can only be captured as a whole, in which
/// case the entire GoBoardRegion "converts" from being a stone group to being
/// an empty area.
///
/// @note This method should be called after making changes to the content of a
/// GoBoardRegion (usually after removing a GoPoint object).
///
/// @todo The implementatin of this method is rather brute-force... try to find
/// a more elegant solution, or document why there is no such solution.
// -----------------------------------------------------------------------------
- (void) splitRegionIfRequired
{
  // Stone groups can never fragment, they are only captured as a whole which
  // leaves the region unchanged
  if ([self isStoneGroup])
    return;
  // Split not possible if less than 2 points
  if (self.points.count < 2)
    return;

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
    DDLogInfo(@"splitRegionIfRequired() creating new GoBoardRegion with these %d points:\n%@", subRegion.count, subRegion);
    [(NSMutableArray*)points removeObjectsInArray:subRegion];
    GoBoardRegion* newRegion = [GoBoardRegion regionWithPoints:subRegion];
    for (GoPoint* point in subRegion)
      point.region = newRegion;
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setScoringMode:(bool)newScoringMode
{
  if (scoringMode == newScoringMode)
    return;

  // Fill the cache before updating scoringMode! This allows fillCache() to
  // invoke normal members to gather the information
  // -> members will check scoringMode and see that the mode is still disabled,
  //    so they will perform their normal dynamic computing
  // -> the result can then be stored in a special caching member whose value
  //    will subsequently be returned by members once they see that the mode is
  //    enabled
  if (newScoringMode)
    [self fillCache];
  else
    [self invalidateCache];

  scoringMode = newScoringMode;
}

// -----------------------------------------------------------------------------
/// Fills the information cache to be used while scoring mode is enabled.
// -----------------------------------------------------------------------------
- (void) fillCache
{
  cachedSize = [self size];
  cachedIsStoneGroup = [self isStoneGroup];
  cachedColor = [self color];
  cachedLiberties = [self liberties];
  self.cachedAdjacentRegions = [self adjacentRegions];  // use self to increase retain count
}

// -----------------------------------------------------------------------------
/// Invalidates cached information gathered while scoring mode was enabled.
// -----------------------------------------------------------------------------
- (void) invalidateCache
{
  cachedSize = -1;
  cachedIsStoneGroup = false;
  cachedColor = GoColorNone;
  cachedLiberties = -1;
  self.cachedAdjacentRegions = nil;  // use self to decrease the retain count
}

@end
