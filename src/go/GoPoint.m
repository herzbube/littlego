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
#import "GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoPoint.
// -----------------------------------------------------------------------------
@interface GoPoint()
/// @name Initialization and deallocation
//@{
- (id) initWithVertex:(GoVertex*)aVertex;
- (void) dealloc;
//@}
@end


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


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPoint instance located at the
/// intersection identified by @a vertex.
// -----------------------------------------------------------------------------
+ (GoPoint*) pointAtVertex:(GoVertex*)vertex
{
  GoPoint* point = [[GoPoint alloc] initWithVertex:vertex];
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
- (id) initWithVertex:(GoVertex*)aVertex
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.vertex = aVertex;
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

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPoint object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.vertex = nil;
  [neighbours release];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #LeftDirection. Returns nil if this GoPoint object
/// is located at the left edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) left
{
  // TODO: Caching will not work if this point is at the left edge; the same is
  // also true for the other directions.
  if (! left)
    left = [[GoGame sharedGame].board neighbourOf:self inDirection:LeftDirection];
  return left;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #RightDirection. Returns nil if this GoPoint object
/// is located at the right edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) right
{
  if (! right)
    right = [[GoGame sharedGame].board neighbourOf:self inDirection:RightDirection];
  return right;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #UpDirection. Returns nil if this GoPoint object
/// is located at the upper edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) above
{
  if (! above)
    above = [[GoGame sharedGame].board neighbourOf:self inDirection:UpDirection];
  return above;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #DownDirection. Returns nil if this GoPoint object
/// is located at the lower edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) below
{
  if (! below)
    below = [[GoGame sharedGame].board neighbourOf:self inDirection:DownDirection];
  return below;
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of up to 4 GoPoint objects that are the direct
/// neighbours of this GoPoint object in #LeftDirection, #RightDirection,
/// #UpDirection and #DownDirection. The returned list has no particular order.
// -----------------------------------------------------------------------------
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
  return [[neighbours retain] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #NextDirection. Returns nil if this GoPoint object
/// is the last GoPoint of the sequence.
// -----------------------------------------------------------------------------
- (GoPoint*) next
{
  if (! next)
    next = [[GoGame sharedGame].board neighbourOf:self inDirection:NextDirection];
  return next;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #PreviousDirection. Returns nil if this GoPoint object
/// is the first GoPoint of the sequence.
// -----------------------------------------------------------------------------
- (GoPoint*) previous
{
  if (! previous)
    previous = [[GoGame sharedGame].board neighbourOf:self inDirection:PreviousDirection];
  return previous;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the intersection represented by this GoPoint is
/// occupied by a stone.
// -----------------------------------------------------------------------------
- (bool) hasStone
{
  return (NoStone != self.stoneState);
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the intersection represented by this GoPoint is
/// occupied by a black stone. Otherwise returns false (i.e. also returns false
/// if the intersection is not occupied by a stone).
// -----------------------------------------------------------------------------
- (bool) blackStone
{
  return (BlackStone == self.stoneState);
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
/// @brief Returns true if playing a stone on the intersection represented by
/// this GoPoint would be legal. This includes checking for suicide moves and
/// Ko situations.
// -----------------------------------------------------------------------------
- (bool) isLegalMove
{
  return [[GoGame sharedGame] isLegalMove:self];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a point refers to the same intersection as this
/// GoPoint object.
// -----------------------------------------------------------------------------
- (bool) isEqualToPoint:(GoPoint*)point
{
  if (! point)
    return false;
  // Don't rely on instance identity, it's better to compare the vertex
  return [self.vertex isEqualToVertex:point.vertex];
}

@end
