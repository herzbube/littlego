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
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Privately declared properties
//@{
@property bool isLeftValid;
@property bool isRightValid;
@property bool isAboveValid;
@property bool isBelowValid;
@property bool isNextValid;
@property bool isPreviousValid;
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
@synthesize isLeftValid;
@synthesize isRightValid;
@synthesize isAboveValid;
@synthesize isBelowValid;
@synthesize isNextValid;
@synthesize isPreviousValid;


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
  self.stoneState = GoColorNone;
  left = nil;
  right = nil;
  above = nil;
  below = nil;
  next = nil;
  previous = nil;
  neighbours = nil;
  isLeftValid = false;
  isRightValid = false;
  isAboveValid = false;
  isBelowValid = false;
  isNextValid = false;
  isPreviousValid = false;

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
/// @brief Returns a description for this GoPoint object.
///
/// This method is invoked when GoPoint needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoPoint(%p): vertex = %@, stone state = %d", self, vertex.string, stoneState];
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #LeftDirection. Returns nil if this GoPoint object
/// is located at the left edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) left
{
  if (! isLeftValid)
  {
    isLeftValid = true;
    left = [[GoGame sharedGame].board neighbourOf:self inDirection:LeftDirection];
  }
  return left;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #RightDirection. Returns nil if this GoPoint object
/// is located at the right edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) right
{
  if (! isRightValid)
  {
    right = [[GoGame sharedGame].board neighbourOf:self inDirection:RightDirection];
    isRightValid = true;
  }
  return right;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #UpDirection. Returns nil if this GoPoint object
/// is located at the upper edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) above
{
  if (! isAboveValid)
  {
    above = [[GoGame sharedGame].board neighbourOf:self inDirection:UpDirection];
    isAboveValid = true;
  }
  return above;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #DownDirection. Returns nil if this GoPoint object
/// is located at the lower edge of the Go board.
// -----------------------------------------------------------------------------
- (GoPoint*) below
{
  if (! isBelowValid)
  {
    below = [[GoGame sharedGame].board neighbourOf:self inDirection:DownDirection];
    isBelowValid = true;
  }
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
  if (! isNextValid)
  {
    next = [[GoGame sharedGame].board neighbourOf:self inDirection:NextDirection];
    isNextValid = true;
  }
  return next;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is the direct neighbour of this
/// GoPoint object in #PreviousDirection. Returns nil if this GoPoint object
/// is the first GoPoint of the sequence.
// -----------------------------------------------------------------------------
- (GoPoint*) previous
{
  if (! isPreviousValid)
  {
    previous = [[GoGame sharedGame].board neighbourOf:self inDirection:PreviousDirection];
    isPreviousValid = true;
  }
  return previous;
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
