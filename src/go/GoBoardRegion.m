// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../utility/UIColorAdditions.h"


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
- (void) splitRegionAfterRemovingPoint:(GoPoint*)removedPoint;
- (void) fillSubRegion:(NSMutableArray*)subRegion containingPoint:(GoPoint*)point;
- (void) moveSubRegion:(NSArray*)subRegion fromMainRegion:(GoBoardRegion*)mainRegion;
- (void) removeSubRegion:(NSArray*)subRegion;
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

  self.points = [NSMutableArray arrayWithCapacity:0];
  self.randomColor = [UIColor randomColor];
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
/// The GoBoardRegion reference of @a point is updated to nil. If @a point is
/// the last point in this region, this GoBoardRegion is deallocated.
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
    [self splitRegionAfterRemovingPoint:point];
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
/// are no longer adjacent after @a removedPoint has been removed.
///
/// Additional GoBoardRegion objects are created by this method if it detects
/// that this GoBoardRegion has fragmented into smaller, non-adjacent sets of
/// GoPoint objects.
///
/// @note When this method is invoked, @a removedPoint must already have been
/// removed from this GoBoardRegion.
///
/// @note This is a private backend helper method for removePoint:().
// -----------------------------------------------------------------------------
- (void) splitRegionAfterRemovingPoint:(GoPoint*)removedPoint
{
  // Split not possible if less than 2 points
  if (points.count < 2)
    return;

  // Because the point that has been removed is the splitting point, we iterate
  // the point's neighbours to see if they are still connected
  NSMutableArray* subRegions = [NSMutableArray arrayWithCapacity:0];
  for (GoPoint* neighbourOfRemovedPoint in removedPoint.neighbours)
  {
    // We are not interested in the neighbour if it is not in our region
    if (! [self hasPoint:neighbourOfRemovedPoint])
      continue;
    // Check if the current neighbour is connected to one of the other
    // neighbours that have been previously processed
    bool isNeighbourConnected = false;
    for (NSArray* subRegion in subRegions)
    {
      if ([subRegion containsObject:neighbourOfRemovedPoint])
      {
        isNeighbourConnected = true;
        break;
      }
    }
    if (isNeighbourConnected)
      continue;
    // If the neighbour is not connected, we can create a new subregion that
    // contains the current neighbour and its neighbours that are also in self
    // (the main region)
    NSMutableArray* newSubRegion = [NSMutableArray arrayWithCapacity:0];
    [subRegions addObject:newSubRegion];
    [self fillSubRegion:newSubRegion containingPoint:neighbourOfRemovedPoint];

    // If the new subregion has the same size as self (the main region),
    // then it effectively is the same thing as self. There won't be any more
    // splits, so we can skip processing the remaining neighbours.
    if (points.count == newSubRegion.count)
      break;

    // At this point we know that newSubRegion does not contain all the points
    // of self (the main region), so a split is certain to occur. We can
    // optimize by immediately removing the points of newSubRegion from self
    // (the main region) so that the next iteration will find less objects in
    // self.points and will therefore process more quickly.
    [[GoBoardRegion region] moveSubRegion:newSubRegion fromMainRegion:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Recursively adds GoPoint objects to @a subRegion that are connected
/// with @a point and that, together, form a subregion of this GoBoardRegion.
///
/// @note This is a private backend helper method for
/// splitRegionAfterRemovingPoint:().
// -----------------------------------------------------------------------------
- (void) fillSubRegion:(NSMutableArray*)subRegion containingPoint:(GoPoint*)point
{
  [subRegion addObject:point];
  for (GoPoint* neighbour in point.neighbours)
  {
    if ([subRegion containsObject:neighbour])
      continue;
    if (! [self hasPoint:neighbour])
      continue;
    [self fillSubRegion:subRegion containingPoint:neighbour];
  }
}

// -----------------------------------------------------------------------------
/// @brief Moves the GoPoint objects in @a subRegion to this GoBoardRegion. The
/// GoPoint objects currently must be part of @a mainRegion.
///
/// The purpose of this method is to provide a light-weight alternative to
/// removePoint:(). removePoint:() is heavy-weight because it applies expensive
/// region-fragmentation logic to the GoBoardRegion from which the GoPoint
/// object is removed.
///
/// In contrast, this method does not apply the region-fragmentation logic: it
/// simply assumes the GoPoint objects in @a subRegion are connected and form a
/// subregion of @a mainRegion. Operating under this assumption, GoPoint objects
/// in @a subRegion can simply be bulk-removed from @a mainRegion and bulk-added
/// to this GoBoardRegion. The only thing that is done in addition is updating
/// the GoBoardRegion reference of the GoPoint objects being moved.
///
/// @a note The assumption that GoPoint objects in @a subRegion are connected
/// is not checked for efficiency reasons, again with the goal to keep this
/// method as light-weight as possible.
///
/// @note If @a mainRegion is empty after all GoPoint objects have been moved,
/// it is deallocated. The effect is the same as if joinRegion:() had been
/// called.
///
/// Raises an @e NSInvalidArgumentException if @a subRegion or @a mainRegion are
/// nil, if the GoPoint objects in @a subRegion do not reference @a mainRegion,
/// or if their @e stoneState property does not match the @e stoneState
/// properties of other GoPoint objects already in this region.
///
/// @note This is a private backend helper method for
/// splitRegionAfterRemovingPoint:().
// -----------------------------------------------------------------------------
- (void) moveSubRegion:(NSArray*)subRegion fromMainRegion:(GoBoardRegion*)mainRegion
{
  if (! subRegion)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"subRegion argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }
  if (! mainRegion)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"mainRegion argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }
  
  if (0 == subRegion.count)
    return;
  
  // We only check the attributes of the first point of the subregion, assuming
  // that it is representative for the other points in the array. We don't check
  // all points for efficiency reasons!
  GoPoint* firstPointOfSubRegion = [subRegion objectAtIndex:0];
  GoBoardRegion* previousRegion = firstPointOfSubRegion.region;
  if (mainRegion != previousRegion)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Points of subregion do not reference specified main region"
                                                   userInfo:nil];
    @throw exception;
  }
  if (points.count > 0)
  {
    GoPoint* otherPoint = [points objectAtIndex:0];
    if (otherPoint.stoneState != firstPointOfSubRegion.stoneState)
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Subregion points' stoneState (%d) does not match stoneState of points already in this GoBoardRegion (%d)", firstPointOfSubRegion.stoneState, otherPoint.stoneState]
                                                     userInfo:nil];
      @throw exception;
    }
  }

  // Bulk-remove subRegion. Note that mainRegion may be deallocated by this
  // operation, so we don't use it after the method invocation returns.
  [mainRegion removeSubRegion:subRegion];

  // Bulk-add subRegion
  [(NSMutableArray*)points addObjectsFromArray:subRegion];
  for (GoPoint* point in subRegion)
    point.region = self;
}

// -----------------------------------------------------------------------------
/// @brief Removes GoPoint objects in @a subRegion from this GoBoardRegion
/// without applying any region-fragmentation logic to this GoBoardRegion.
///
/// The GoBoardRegion reference of all GoPoint objects in @a subRegion is
/// updated to nil. If this GoBoardRegion does not contain any other points
/// than those in @a subRegion, this GoBoardRegion is deallocated.
///
/// @note This is a private backend helper method for
/// moveSubRegion:fromMainRegion:().
// -----------------------------------------------------------------------------
- (void) removeSubRegion:(NSArray*)subRegion
{
  [(NSMutableArray*)points removeObjectsInArray:subRegion];
  for (GoPoint* point in subRegion)
    point.region = nil;
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
  if ([self isStoneGroup])
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
