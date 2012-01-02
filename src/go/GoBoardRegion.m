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
- (void) splitRegionIfRequired;
- (void) fillCache;
- (void) invalidateCache;
//@}
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSArray* points;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) int cachedSize;
@property(nonatomic, assign) bool cachedIsStoneGroup;
@property(nonatomic, assign) enum GoColor cachedColor;
@property(nonatomic, assign) int cachedLiberties;
@property(nonatomic, retain) NSArray* cachedAdjacentRegions;
//@}
@end


@implementation GoBoardRegion

@synthesize points;
@synthesize randomColor;
@synthesize scoringMode;
@synthesize territoryColor;
@synthesize territoryInconsistencyFound;
@synthesize deadStoneGroup;
@synthesize cachedSize;
@synthesize cachedIsStoneGroup;
@synthesize cachedColor;
@synthesize cachedLiberties;
@synthesize cachedAdjacentRegions;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoardRegion instance that
/// contains no GoPoint objects.
// -----------------------------------------------------------------------------
+ (GoBoardRegion*) region
{
  GoBoardRegion* region = [[GoBoardRegion alloc] init];
  if (region)
    [region autorelease];
  return region;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoardRegion instance that
/// contains the GoPoint objects in @a points.
///
/// The GoPoint objects in @a points are added to the new GoBoardRegion instance
/// by invoking addPoint:(). The GoBoardRegion reference of those GoPoint
/// objects is therefore updated automatically to the new GoBoardRegion. See
/// addObject:() for details.
///
/// Raises an @e NSInvalidArgumentException if @a points is nil.
// -----------------------------------------------------------------------------
+ (GoBoardRegion*) regionWithPoints:(NSArray*)points
{
  if (! points)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Points argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }

  GoBoardRegion* region = [[GoBoardRegion alloc] init];
  if (region)
  {
    for (GoPoint* point in points)
      [region addPoint:point];
    [region autorelease];
  }
  return region;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoardRegion instance that
/// contains the single GoPoint object @a point.
///
/// @a point is added to the new GoBoardRegion instance by invoking addPoint:().
/// The GoBoardRegion reference of @a point is therefore updated automatically
/// to the new GoBoardRegion. See addObject:() for details.
///
/// Raises an @e NSInvalidArgumentException if @a point is nil.
// -----------------------------------------------------------------------------
+ (GoBoardRegion*) regionWithPoint:(GoPoint*)point
{
  if (! point)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Point argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }

  return [GoBoardRegion regionWithPoints:[NSArray arrayWithObject:point]];
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

  self.points = [NSMutableArray arrayWithCapacity:0];
  CGFloat red = (CGFloat)random() / (CGFloat)RAND_MAX;
  CGFloat blue = (CGFloat)random() / (CGFloat)RAND_MAX;
  CGFloat green = (CGFloat)random() / (CGFloat)RAND_MAX;
  self.randomColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
  self.scoringMode = false;
  self.territoryColor = GoColorNone;
  self.territoryInconsistencyFound = false;
  self.deadStoneGroup = false;
  [self invalidateCache];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoBoardRegion object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.points = nil;
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
/// The GoBoardRegion reference of @a point is updated to this GoBoardRegion.
/// If @a point has a reference to another GoBoardRegion object, @a point is
/// first removed from that GoBoardRegion by invoking removePoint:(). If
/// @a point was the last point in that region, the other GoBoardRegion object
/// is deallocated.
///
/// Raises an @e NSInvalidArgumentException if @a point is nil, if it already
/// references this GoBoardRegion, or if its @e stoneState property does not
/// match the @e stoneState properties of other GoPoint objects already in this
/// region.
// -----------------------------------------------------------------------------
- (void) addPoint:(GoPoint*)point
{
  // We could rely on NSMutableArray to catch this, but it's better to be
  // explicit and catch this right at the beginning
  if (! point)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Point argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }
  GoBoardRegion* previousRegion = point.region;
  if (self == previousRegion)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Point is already associated with this GoBoardRegion"
                                                   userInfo:nil];
    @throw exception;
  }
  if (points.count > 0)
  {
    GoPoint* otherPoint = [points objectAtIndex:0];
    if (otherPoint.stoneState != point.stoneState)
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Point argument's stoneState (%d) does not match stoneState of points already in this GoBoardRegion (%d)", point.stoneState, otherPoint.stoneState]
                                                     userInfo:nil];
      @throw exception;
    }
  }

  if (previousRegion)
    [previousRegion removePoint:point];  // side-effect: sets point.region to nil
  [(NSMutableArray*)points addObject:point];
  point.region = self;
}

// -----------------------------------------------------------------------------
/// @brief Removes @a point from this GoBoardRegion.
///
/// The GoBoardRegion reference of @a point is updated to nil. If @point is the
/// last point in this region, this GoBoardRegion is deallocated.
///
/// Invoking this method may cause this GoBoardRegion to fragment, i.e. other
/// GoBoardRegion objects may come into existence because GoPoint objects within
/// this GoBoardRegion are no longer adjacent.
///
/// Raises an @e NSInvalidArgumentException if @a point does not reference this
/// GoBoardRegion.
// -----------------------------------------------------------------------------
- (void) removePoint:(GoPoint*)point
{
  GoBoardRegion* previousRegion = point.region;
  if (self != previousRegion)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Point is not associated with this GoBoardRegion"
                                                   userInfo:nil];
    @throw exception;
  }

  [(NSMutableArray*)points removeObject:point];
  // Check points array NOW because the next statement might deallocate this
  // GoBoardRegion, including the array
  bool lastPoint = (0 == points.count);
  // If point is the last point in this region, the next statement is going to
  // deallocate this GoBoardRegion
  point.region = nil;
  // Do post-processing only if we didn't remove the last point, i.e. if this
  // GoBoardRegion object is still alive
  if (! lastPoint)
    [self splitRegionIfRequired];
}

// -----------------------------------------------------------------------------
/// @brief Joins @a region with this GoBoardRegion, i.e. all GoPoint objects
/// in @a region are added to this GoBoardRegion.
///
/// The GoBoardRegion reference of all GoPoint objects will be updated to this
/// GoBoardRegion. As a result, @a region will be deallocated and should not be
/// used after this method returns.
///
/// Raises an @e NSInvalidArgumentException if @a region is nil, if it is the
/// same as this GoBoardRegion, or if the @e stoneState property of its GoPoint
/// members does not match the @e stoneState properties of GoPoint objects
/// already in this region.
// -----------------------------------------------------------------------------
- (void) joinRegion:(GoBoardRegion*)region
{
  if (! region)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Region argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }
  if (self == region)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Region argument is the same as this GoBoardRegion object"
                                                   userInfo:nil];
    @throw exception;
  }

  // Iterate over a copy of the array to be safe from modifications of the
  // array. Such modifications occur because addPoint:() below causes the point
  // to be removed from the other region.
  // Note: The copy, by the way, also solves the problem that the array is
  // deallocated when the last point is removed from the other region. If we
  // were using the original array, the loop would access the deallocated array
  // in its final iteration (the one where it would normally find out that the
  // loop condition has been reached), causing the application to crash.
  NSArray* pointsCopy = [region.points copy];
  for (GoPoint* point in pointsCopy)
    [self addPoint:point];
  [pointsCopy release];
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
/// GoBoardRegion represents.
///
/// Raises an @e NSInternalInconsistencyException if this GoBoardRegion does not
/// represent a stone group.
// -----------------------------------------------------------------------------
- (int) liberties
{
  if (scoringMode)
    return cachedLiberties;

  if (! [self isStoneGroup])
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"GoBoardRegion does not represent a stone group"
                                                   userInfo:nil];
    @throw exception;
  }

  NSMutableArray* libertyPoints = [NSMutableArray arrayWithCapacity:0];
  for (GoPoint* point in points)
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
  for (GoPoint* point in points)
  {
    for (GoPoint* neighbour in point.neighbours)
    {
      // Is the neighbour in an adjacent region?
      GoBoardRegion* adjacentRegion = neighbour.region;
      if (adjacentRegion == self)
        continue;  // no
      if (! adjacentRegion)
        continue;  // no (this is weird, but at the moment we try to be graceful about it)
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
  if (points.count < 2)
    return;

  NSMutableArray* subRegions = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* pointsToProcess = [points mutableCopy];
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
  [pointsToProcess release];

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
    [GoBoardRegion regionWithPoints:subRegion];
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
