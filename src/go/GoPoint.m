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
#import "GoPoint.h"
#import "GoBoard.h"
#import "GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoPoint.
// -----------------------------------------------------------------------------
@interface GoPoint()
@property(nonatomic, assign) bool isLeftValid;
@property(nonatomic, assign) bool isRightValid;
@property(nonatomic, assign) bool isAboveValid;
@property(nonatomic, assign) bool isBelowValid;
@property(nonatomic, assign) bool isNextValid;
@property(nonatomic, assign) bool isPreviousValid;
@end


@implementation GoPoint

@synthesize left=_left;
@synthesize right=_right;
@synthesize above=_above;
@synthesize below=_below;
@synthesize neighbours=_neighbours;
@synthesize next=_next;
@synthesize previous=_previous;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPoint instance located at the
/// intersection identified by @a vertex.
///
/// Raises an @e NSInvalidArgumentException if either @a aVertex or @a aBoard
/// is nil.
// -----------------------------------------------------------------------------
+ (GoPoint*) pointAtVertex:(GoVertex*)vertex onBoard:(GoBoard*)board
{
  if (! vertex || ! board)
  {
    NSString* errorMessage = @"GoVertex or GoBoard argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoPoint* point = [[GoPoint alloc] initWithVertex:vertex onBoard:board];
  if (point)
  {
    point.vertex = vertex;
    [point autorelease];
  }
  return point;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoPoint object. The GoPoint is located at the
/// intersection identified by @a vertex. The GoPoint has no stone, and is not
/// part of any GoBoardRegion.
///
/// @note This is the designated initializer of GoPoint.
// -----------------------------------------------------------------------------
- (id) initWithVertex:(GoVertex*)aVertex onBoard:(GoBoard*)aBoard
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.vertex = aVertex;
  self.board = aBoard;
  self.starPoint = false;
  self.stoneState = GoColorNone;
  self.territoryStatisticsScore = 0.0f;
  _left = nil;
  _right = nil;
  _above = nil;
  _below = nil;
  _next = nil;
  _previous = nil;
  _neighbours = nil;
  _isLeftValid = false;
  _isRightValid = false;
  _isAboveValid = false;
  _isBelowValid = false;
  _isNextValid = false;
  _isPreviousValid = false;

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
  // We can do this because there is a 1:1 relationship between GoPoint and
  // GoVertex
  self.vertex = [GoVertex vertexFromString:[decoder decodeObjectForKey:goPointVertexKey]];
  self.board = [decoder decodeObjectForKey:goPointBoardKey];
  if ([decoder containsValueForKey:goPointIsStarPointKey])
    self.starPoint = true;
  else
    self.starPoint = false;
  if ([decoder containsValueForKey:goPointStoneStateKey])
    self.stoneState = [decoder decodeIntForKey:goPointStoneStateKey];
  else
    self.stoneState = GoColorNone;
  if ([decoder containsValueForKey:goPointTerritoryStatisticsScoreKey])
    self.territoryStatisticsScore = [decoder decodeFloatForKey:goPointTerritoryStatisticsScoreKey];
  else
    self.territoryStatisticsScore = 0.0f;
  self.region = [decoder decodeObjectForKey:goPointRegionKey];

  _left = nil;
  _right = nil;
  _above = nil;
  _below = nil;
  _next = nil;
  _previous = nil;
  _neighbours = nil;
  _isLeftValid = false;
  _isRightValid = false;
  _isAboveValid = false;
  _isBelowValid = false;
  _isNextValid = false;
  _isPreviousValid = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPoint object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.vertex = nil;
  self.board = nil;
  [_neighbours release];
  self.region = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Prepares this GoPoint object for deallocation. This method breaks all
/// retain cycles, making it possible to deallocate GoPoint objects in the first
/// place.
// -----------------------------------------------------------------------------
- (void) prepareForDealloc
{
  // TODO Change design so that there is no retain cycle. Currently this would
  // mean to mark up the property GoPoint.region with "assign" instead of
  // "retain", but then nobody retains GoBoardRegion...
  self.region = nil;
  // GoPoint objects reference each other via their _neighbours arrays.
  // Unfortunately it is not possible to tell NSArray/NSMutableArray not to
  // retain their objects.
  [(NSMutableArray*)_neighbours removeAllObjects];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoPoint object.
///
/// This method is invoked when GoPoint needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoPoint(%p): vertex = %@, stone state = %d", self, _vertex.string, _stoneState];
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #GoBoardDirectionLeft. Returns nil if this GoPoint object
/// is located at the left edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) left
{
  if (! _isLeftValid)
  {
    _isLeftValid = true;
    _left = [self.board neighbourOf:self inDirection:GoBoardDirectionLeft];
  }
  return _left;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #GoBoardDirectionRight. Returns nil if this GoPoint object
/// is located at the right edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) right
{
  if (! _isRightValid)
  {
    _right = [self.board neighbourOf:self inDirection:GoBoardDirectionRight];
    _isRightValid = true;
  }
  return _right;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #GoBoardDirectionUp. Returns nil if this GoPoint object
/// is located at the upper edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) above
{
  if (! _isAboveValid)
  {
    _above = [self.board neighbourOf:self inDirection:GoBoardDirectionUp];
    _isAboveValid = true;
  }
  return _above;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #GoBoardDirectionDown. Returns nil if this GoPoint object
/// is located at the lower edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) below
{
  if (! _isBelowValid)
  {
    _below = [self.board neighbourOf:self inDirection:GoBoardDirectionDown];
    _isBelowValid = true;
  }
  return _below;
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of up to 4 GoPoint objects that are the direct
/// neighbours of this GoPoint object in #GoBoardDirectionLeft,
/// #GoBoardDirectionRight, #GoBoardDirectionUp and #GoBoardDirectionDown. The
/// returned list has no particular order.
// -----------------------------------------------------------------------------
- (NSArray*) neighbours
{
  if (! _neighbours)
  {
    _neighbours = [[NSMutableArray arrayWithCapacity:0] retain];
    if (self.left)
      [(NSMutableArray*)_neighbours addObject:self.left];
    if (self.right)
      [(NSMutableArray*)_neighbours addObject:self.right];
    if (self.above)
      [(NSMutableArray*)_neighbours addObject:self.above];
    if (self.below)
      [(NSMutableArray*)_neighbours addObject:self.below];
  }
  return [[_neighbours retain] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #GoBoardDirectionNext. Returns nil if this GoPoint object
/// is the last GoPoint of the sequence.
// -----------------------------------------------------------------------------
- (GoPoint*) next
{
  if (! _isNextValid)
  {
    _next = [self.board neighbourOf:self inDirection:GoBoardDirectionNext];
    _isNextValid = true;
  }
  return _next;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #GoBoardDirectionPrevious. Returns nil if this GoPoint object
/// is the first GoPoint of the sequence.
// -----------------------------------------------------------------------------
- (GoPoint*) previous
{
  if (! _isPreviousValid)
  {
    _previous = [self.board neighbourOf:self inDirection:GoBoardDirectionPrevious];
    _isPreviousValid = true;
  }
  return _previous;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the intersection represented by this GoPoint is
/// occupied by a stone.
// -----------------------------------------------------------------------------
- (bool) hasStone
{
  return (GoColorNone != self.stoneState);
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the intersection represented by this GoPoint is
/// occupied by a black stone. Otherwise returns false (i.e. also returns false
/// if the intersection is not occupied by a stone).
// -----------------------------------------------------------------------------
- (bool) blackStone
{
  return (GoColorBlack == self.stoneState);
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of liberties that the intersection represented by
/// this GoPoint has. The way how liberties are counted depends on whether the
/// intersection is occupied by a stone.
///
/// If the intersection is occupied by a stone, this method returns the number
/// of liberties of the entire stone group. If the intersection is not occupied,
/// this method returns the number of liberties of just that one intersection.
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
/// @brief Returns true if @a point refers to the same intersection as this
/// GoPoint object.
// -----------------------------------------------------------------------------
- (bool) isEqualToPoint:(GoPoint*)point
{
  if (! point)
  {
    DDLogWarn(@"%@: GoPoint object is nil for isEqualToPoint", self);
    return false;
  }
  // Don't rely on instance identity, it's better to compare the vertex
  return [self.vertex isEqualToVertex:point.vertex];
}

// -----------------------------------------------------------------------------
/// @brief Collects the GoBoardRegion from those neighbours (@e neighbours
/// property) of this GoPoint object whose stoneState matches @a color, then
/// returns an array with those GoBoardRegion objects.
///
/// The array that is returned contains no duplicates.
// -----------------------------------------------------------------------------
- (NSArray*) neighbourRegionsWithColor:(enum GoColor)color
{
  NSMutableArray* neighbourRegions = [NSMutableArray arrayWithCapacity:0];
  for (GoPoint* neighbour in self.neighbours)
  {
    if (neighbour.stoneState != color)
      continue;
    GoBoardRegion* neighbourRegion = neighbour.region;
    if ([neighbourRegions containsObject:neighbourRegion])
      continue;
    [neighbourRegions addObject:neighbourRegion];
  }
  return neighbourRegions;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  // Encode the string instead of the GoVertex object to save on the size of
  // the NSCoding archive.
  [encoder encodeObject:self.vertex.string forKey:goPointVertexKey];
  [encoder encodeObject:self.board forKey:goPointBoardKey];
  if (self.isStarPoint)
    [encoder encodeBool:self.isStarPoint forKey:goPointIsStarPointKey];
  if (self.stoneState != GoColorNone)
    [encoder encodeInt:self.stoneState forKey:goPointStoneStateKey];
  if (self.territoryStatisticsScore != 0.0f)
    [encoder encodeFloat:self.territoryStatisticsScore forKey:goPointTerritoryStatisticsScoreKey];
  [encoder encodeObject:self.region forKey:goPointRegionKey];
}

@end
