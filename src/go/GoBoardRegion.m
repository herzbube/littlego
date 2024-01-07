// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Class extension with private properties for GoBoardRegion.
// -----------------------------------------------------------------------------
@interface GoBoardRegion()
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
    NSString* errorMessage = @"Point argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
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
  _scoringMode = false;  // don't use self, otherwise we trigger the setter!
  self.territoryColor = GoColorNone;
  self.territoryInconsistencyFound = false;
  self.stoneGroupState = GoStoneGroupStateUndefined;
  [self invalidateCache];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;

  self.points = [decoder decodeObjectOfClass:[NSMutableArray class] forKey:goBoardRegionPointsKey];
  self.randomColor = [UIColor randomColor];
  // Don't use self.scoringMode, otherwise we trigger the setter!
  if ([decoder containsValueForKey:goBoardRegionScoringModeKey])
    _scoringMode = true;
  else
    _scoringMode = false;
  if ([decoder containsValueForKey:goBoardRegionTerritoryColorKey])
    self.territoryColor = [decoder decodeIntForKey:goBoardRegionTerritoryColorKey];
  else
    self.territoryColor = GoColorNone;
  if ([decoder containsValueForKey:goBoardRegionTerritoryInconsistencyFoundKey])
    self.territoryInconsistencyFound = true;
  else
    self.territoryInconsistencyFound = false;
  if ([decoder containsValueForKey:goBoardRegionStoneGroupStateKey])
    self.stoneGroupState = [decoder decodeIntForKey:goBoardRegionStoneGroupStateKey];
  else
    self.stoneGroupState = GoStoneGroupStateUndefined;
  if ([decoder containsValueForKey:goBoardRegionCachedSizeKey])
    self.cachedSize = [decoder decodeIntForKey:goBoardRegionCachedSizeKey];
  else
    self.cachedSize = -1;
  if ([decoder containsValueForKey:goBoardRegionCachedIsStoneGroupKey])
    self.cachedIsStoneGroup = true;
  else
    self.cachedIsStoneGroup = false;
  if ([decoder containsValueForKey:goBoardRegionCachedColorKey])
    self.cachedColor = [decoder decodeIntForKey:goBoardRegionCachedColorKey];
  else
    self.cachedColor = GoColorNone;
  if ([decoder containsValueForKey:goBoardRegionCachedLibertiesKey])
    self.cachedLiberties = [decoder decodeIntForKey:goBoardRegionCachedLibertiesKey];
  else
    self.cachedLiberties = -1;
  if ([decoder containsValueForKey:goBoardRegionCachedAdjacentRegionsKey])
    self.cachedAdjacentRegions = [decoder decodeObjectOfClass:[NSArray class] forKey:goBoardRegionCachedAdjacentRegionsKey];
  else
    self.cachedAdjacentRegions = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
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
  return [NSString stringWithFormat:@"GoBoardRegion(%p): point count = %lu", self, (unsigned long)_points.count];
}

// -----------------------------------------------------------------------------
/// @brief Returns the size of this GoBoardRegion, which corresponds to the
/// number of GoPoint objects in this GoBoardRegion.
// -----------------------------------------------------------------------------
- (int) size
{
  if (_scoringMode)
    return _cachedSize;
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because a region can never have more than pow(2, 32) points
  return (int)[_points count];
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
    NSString* errorMessage = @"Point argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  GoBoardRegion* previousRegion = point.region;
  if (self == previousRegion)
  {
    NSString* errorMessage = @"Point is already associated with this GoBoardRegion";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (_points.count > 0)
  {
    GoPoint* otherPoint = [_points objectAtIndex:0];
    if (otherPoint.stoneState != point.stoneState)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Point argument's stoneState (%d) does not match stoneState of points already in this GoBoardRegion (%d)", point.stoneState, otherPoint.stoneState];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }

  if (previousRegion)
    [previousRegion removePoint:point];  // side-effect: sets point.region to nil
  [(NSMutableArray*)_points addObject:point];
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
    NSString* errorMessage = @"Point is not associated with this GoBoardRegion";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [(NSMutableArray*)_points removeObject:point];
  // Check _points array NOW because the next statement might deallocate this
  // GoBoardRegion, including the array
  bool lastPoint = (0 == _points.count);
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
    NSString* errorMessage = @"Region argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (self == region)
  {
    NSString* errorMessage = @"Region argument is the same as this GoBoardRegion object";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
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
  if (_scoringMode)
    return _cachedIsStoneGroup;

  if (0 == [_points count])
    return false;
  GoPoint* point = [_points objectAtIndex:0];
  return [point hasStone];
}

// -----------------------------------------------------------------------------
/// @brief Returns the color of the stones in this GoBoardRegion, or
/// #GoColorNone if this GoBoardRegion does not represent a stone group.
// -----------------------------------------------------------------------------
- (enum GoColor) color
{
  if (_scoringMode)
    return _cachedColor;

  if (0 == [_points count])
    return GoColorNone;
  GoPoint* point = [_points objectAtIndex:0];
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
  if (_scoringMode)
    return _cachedLiberties;

  if (! [self isStoneGroup])
  {
    NSString* errorMessage = @"GoBoardRegion does not represent a stone group";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  NSMutableArray* libertyPoints = [NSMutableArray arrayWithCapacity:0];
  for (GoPoint* point in _points)
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
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because a region's liberties can never exceed pow(2, 32).
  return (int)[libertyPoints count];
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of of GoBoardRegion objects that are direct neighbours
/// of this GoBoardRegion.
// -----------------------------------------------------------------------------
- (NSArray*) adjacentRegions
{
  if (_scoringMode)
    return _cachedAdjacentRegions;

  NSMutableArray* adjacentRegions = [NSMutableArray arrayWithCapacity:0];
  for (GoPoint* point in _points)
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
/// It may help to understand the implementation if one keeps in mind that this
/// method is invoked only for the following scenarios:
/// - When a stone is placed either by regular play, or when a board position
///   is set up, a single empty region may fragment into multiple empty regions
/// - When a stone is removed by undoing a move, a single stone group may
///   fragment into multiple stone groups
///
/// @note When this method is invoked, @a removedPoint must already have been
/// removed from this GoBoardRegion.
///
/// @note This is a private backend helper method for removePoint:().
// -----------------------------------------------------------------------------
- (void) splitRegionAfterRemovingPoint:(GoPoint*)removedPoint
{
  // Split not possible if less than 2 points
  if (_points.count < 2)
    return;

  // Because the point that has been removed is the splitting point, we iterate
  // the point's neighbours to see if they are still connected
  NSMutableArray* subRegions = [NSMutableArray arrayWithCapacity:0];
  for (GoPoint* neighbourOfRemovedPoint in removedPoint.neighbours)
  {
    // We are not interested in the neighbour if it is not in our region
    if (neighbourOfRemovedPoint.region != self)
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
    if (_points.count == newSubRegion.count)
      break;

    // At this point we know that newSubRegion does not contain all the points
    // of self (the main region), so a split is certain to occur. We need to
    // immediately remove the points of newSubRegion from self (the main region)
    // so that in the next iteration the GoPoint.region property of those
    // points is already correct.
    [[GoBoardRegion region] moveSubRegion:newSubRegion fromMainRegion:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Recursively adds GoPoint objects to @a subRegion that are connected
/// with @a point and that, together, form a subregion of this GoBoardRegion.
///
/// @note This is a private backend helper method for
/// splitRegionAfterRemovingPoint:().
///
/// @note When a game is loaded from .sgf, this is the single-most
/// time-consuming method. Example for the current implementation: When the
/// "Ear-reddening game" (325 moves) is loaded on an iPhone 3GS, the total load
/// time is ~3500ms. Roughly half of that time, or ~1700ms, is taken up by
/// executing this method. This has been determined using the "Time Profiler"
/// instrument and the ad-hoc distribution build. Optimization efforts that
/// have been made so far:
/// - Replacing recursion by a stack-based implementation significantly slows
///   the implementation (by ~75%)
/// - Assigning point.neighbours to a local variable and using that variable in
///   the for-loop has no noticeable benefit
/// - The order of the 2 checks inside the for-loop is important. The current
///   order is significantly faster than if the order were reversed. The same
///   instrumentation as above shows that on an iPhone 3GS the current order of
///   checks makes this method ~15% faster (1678ms instead of 1956ms for the
///   reversed order of checks).
// -----------------------------------------------------------------------------
- (void) fillSubRegion:(NSMutableArray*)subRegion containingPoint:(GoPoint*)point
{
  [subRegion addObject:point];
  for (GoPoint* neighbour in point.neighbours)
  {
    // The order of the following 2 checks is important!!! See method docs for
    // optimization notes.
    if (neighbour.region != self)
      continue;
    if ([subRegion containsObject:neighbour])
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
    NSString* errorMessage = @"subRegion argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (! mainRegion)
  {
    NSString* errorMessage = @"mainRegion argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
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
    NSString* errorMessage = @"Points of subregion do not reference specified main region";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (_points.count > 0)
  {
    GoPoint* otherPoint = [_points objectAtIndex:0];
    if (otherPoint.stoneState != firstPointOfSubRegion.stoneState)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Subregion points' stoneState (%d) does not match stoneState of points already in this GoBoardRegion (%d)", firstPointOfSubRegion.stoneState, otherPoint.stoneState];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }

  // Bulk-remove subRegion. We directly access the _points member of the
  // mainRegion instance for efficiency reasons
  [(NSMutableArray*)mainRegion->_points removeObjectsInArray:subRegion];
  // Bulk-add subRegion
  [(NSMutableArray*)_points addObjectsFromArray:subRegion];
  // Update region references. Note that mainRegion may be deallocated by this
  // operation, so we must not use it after the loop completes.
  for (GoPoint* point in subRegion)
    point.region = self;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the stone located at @a point in this GoBoardRegion
/// is a connecting stone that connects sub-groups of stones, and at least one
/// of these sub-groups has no liberties of its own. The parameter
/// @a suicidalSubgroup in this case is filled with the GoPoint objects that
/// form the suicidal sub-group. Returns false if the stone located at @a point
/// is not a connecting stone, or if it is a connecting stone but all sub-groups
/// of stones that it connects have at least one liberty. The content of
/// @a suicidalSubgroup in this case remains unchanged.
///
/// Raises @e NSInternalInconsistencyException if this GoBoardRegion is not a
/// a stone group.
///
/// @note This method is intended to be invoked during board setup prior to the
/// first move. The implementation is very similar to
/// splitRegionAfterRemovingPoint:(), which is intended to be invoked during
/// regular play.
// -----------------------------------------------------------------------------
- (bool) isStoneConnectingSuicidalSubgroups:(GoPoint*)point
                           suicidalSubgroup:(NSMutableArray*)suicidalSubgroup
{
  if (! self.isStoneGroup)
  {
    NSString* errorMessage = @"GoBoardRegion is not a stone group";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  NSMutableArray* subRegions = [NSMutableArray arrayWithCapacity:0];

  for (GoPoint* neighbourOfConnectingPoint in point.neighbours)
  {
    // We are not interested in the neighbour if it is not in our region
    if (neighbourOfConnectingPoint.region != self)
      continue;

    // Check if the current neighbour has already been found in a previous
    // iteration. If so this means that the current neighbour is connected to
    // one of the other neighbours that have been previously processed.
    bool isNeighbourConnected = false;
    for (NSArray* subRegion in subRegions)
    {
      if ([subRegion containsObject:neighbourOfConnectingPoint])
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

    bool newSubRegionHasLiberties = false;

    [self fillSubRegion:newSubRegion
        containingPoint:neighbourOfConnectingPoint
    withConnectingPoint:point
           hasLiberties:&newSubRegionHasLiberties];

    if (! newSubRegionHasLiberties)
    {
      [suicidalSubgroup addObjectsFromArray:newSubRegion];
      return true;
    }

    // If the new subregion has the same size as self (the main region), minus
    // the connecting point, then it effectively is the same thing as self,
    // minus the connecting point. There won't be any more subregions, so we
    // can skip processing the remaining neighbours.
    // This check can only have an effect in the very first iteration. If it
    // fails in the first iteration, it will fail in all subsequent iterations,
    // too.
    if ((_points.count - 1) == newSubRegion.count)
      break;
  }

  return false;
}

// -----------------------------------------------------------------------------
/// @brief Recursively adds GoPoint objects to @a subRegion that are connected
/// with @a point and that, together, form a subregion of this GoBoardRegion.
///
/// When the recursion encounters @a connectingPoint it stops traversal in that
/// direction. It also does not add @a connectingPoint to @a subRegion.
///
/// The recursion sets the out parameter @a hasLiberties to true when it
/// encounters a GoPoint object that has at least one liberty. The recursion
/// does @b not set the out parameter if it encounters no GoPoint objects with
/// at least one liberty. To distinguish the two cases, the initial caller of
/// this method must therefore initialize @a hasLiberties with false.
///
/// @note This is a private backend helper method for
/// isStoneConnectingSuicidalSubgroups:(). The implementation is similar to
/// fillSubRegion:containingPoint:().
// -----------------------------------------------------------------------------
- (void) fillSubRegion:(NSMutableArray*)subRegion
       containingPoint:(GoPoint*)point
   withConnectingPoint:(GoPoint*)connectingPoint
          hasLiberties:(bool*)hasLiberties
{
  [subRegion addObject:point];

  for (GoPoint* neighbour in point.neighbours)
  {
    if (neighbour.region == self)
    {
      if (neighbour == connectingPoint)
        continue;

      if ([subRegion containsObject:neighbour])
        continue;

      [self fillSubRegion:subRegion
          containingPoint:neighbour
      withConnectingPoint:connectingPoint
             hasLiberties:hasLiberties];
    }
    else if ([neighbour hasStone])
    {
      // Neighbour belongs to stone group of opposing color
    }
    else
    {
      // Neighbour is an empty intersection, i.e. a liberty
      *hasLiberties = true;
    }
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setScoringMode:(bool)newScoringMode
{
  if (_scoringMode == newScoringMode)
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

  _scoringMode = newScoringMode;
}

// -----------------------------------------------------------------------------
/// Fills the information cache to be used while scoring mode is enabled.
// -----------------------------------------------------------------------------
- (void) fillCache
{
  _cachedSize = [self size];
  _cachedIsStoneGroup = [self isStoneGroup];
  _cachedColor = [self color];
  if ([self isStoneGroup])
    _cachedLiberties = [self liberties];
  self.cachedAdjacentRegions = [self adjacentRegions];  // use self to increase retain count
}

// -----------------------------------------------------------------------------
/// Invalidates cached information gathered while scoring mode was enabled.
// -----------------------------------------------------------------------------
- (void) invalidateCache
{
  _cachedSize = -1;
  _cachedIsStoneGroup = false;
  _cachedColor = GoColorNone;
  _cachedLiberties = -1;
  self.cachedAdjacentRegions = nil;  // use self to decrease the retain count
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.points forKey:goBoardRegionPointsKey];
  if (self.scoringMode)
    [encoder encodeBool:self.scoringMode forKey:goBoardRegionScoringModeKey];
  if (self.territoryColor != GoColorNone)
    [encoder encodeInt:self.territoryColor forKey:goBoardRegionTerritoryColorKey];
  if (self.territoryInconsistencyFound)
    [encoder encodeBool:self.territoryInconsistencyFound forKey:goBoardRegionTerritoryInconsistencyFoundKey];
  if (self.stoneGroupState != GoStoneGroupStateUndefined)
    [encoder encodeInt:self.stoneGroupState forKey:goBoardRegionStoneGroupStateKey];
  if (self.cachedSize != -1)
    [encoder encodeInt:self.cachedSize forKey:goBoardRegionCachedSizeKey];
  if (self.cachedIsStoneGroup)
    [encoder encodeBool:self.cachedIsStoneGroup forKey:goBoardRegionCachedIsStoneGroupKey];
  if (self.cachedColor != GoColorNone)
    [encoder encodeInt:self.cachedColor forKey:goBoardRegionCachedColorKey];
  if (self.cachedLiberties != -1)
    [encoder encodeInt:self.cachedLiberties forKey:goBoardRegionCachedLibertiesKey];
  if (self.cachedAdjacentRegions)
    [encoder encodeObject:self.cachedAdjacentRegions forKey:goBoardRegionCachedAdjacentRegionsKey];
}

@end
