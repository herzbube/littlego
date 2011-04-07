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
#import "GoMove.h"
#import "GoPoint.h"
#import "GoBoardRegion.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoMove.
// -----------------------------------------------------------------------------
@interface GoMove()
/// @name Initialization and deallocation
//@{
- (id) init:(enum GoMoveType)initType;
- (void) dealloc;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite, assign) GoMove* previous;
@property(readwrite, retain) GoMove* next;
//@}
@end


@implementation GoMove

@synthesize type;
@synthesize black;
@synthesize point;
@synthesize previous;
@synthesize next;

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoMove instance of type @a type,
/// whose predecessor is @a move.
///
/// If @a move is not nil, this method updates @a move so that the newly
/// created GoMove instance becomes its successor. The newly created GoMove
/// instance also gets the alternate color of its predecessor @a move (e.g. if
/// @a move is black, the new GoMove will be white).
///
/// @a move may be nil, in which case the newly created GoMove instance will be
/// black, and the first move of the game.
// -----------------------------------------------------------------------------
+ (GoMove*) move:(enum GoMoveType)type after:(GoMove*)move
{
  GoMove* newMove = [[GoMove alloc] init:type];
  if (newMove)
  {
    newMove.previous = move;
    move.next = newMove;  // set reference to self
    newMove.black = ! move.isBlack;
    [newMove autorelease];
  }
  return newMove;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoMove object. The GoMove has type @a type, is black,
/// has no associated GoPoint, and has no predecessor or successor GoMove.
///
/// @note This is the designated initializer of GoMove.
// -----------------------------------------------------------------------------
- (id) init:(enum GoMoveType)initType
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.type = initType;
  self.black = true;
  self.point = nil;
  self.previous = nil;
  self.next = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoMove object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.point = nil;     // not strictly necessary since we don't retain it
  self.previous = nil;  // not strictly necessary since we don't retain it
  if (self.next)
  {
    self.next.previous = nil;  // remove reference to self
    self.next = nil;
  }
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Associates the GoPoint @a newValue with this GoMove. This GoMove
/// must be of type #PlayMove.
///
/// Invoking this method effectively places a stone at GoPoint @a newValue. The
/// caller must have checked whether placing the stone at @a newValue is a
/// legal move.
///
/// This method performs the following operations as a side-effect:
/// - Updates GoPoint.stoneState for GoPoint @a newValue.
/// - Updates GoPoint.region for GoPoint @a newValue. The old GoBoardRegion may
///   become fragmented due to placing the stone. Additionally, the new
///   GoBoardRegion may merge with other regions if the newly placed stone
///   joins neighbouring stone groups.
/// - If placing the stone reduces an opposing stone group to 0 (zero)
///   liberties, that stone group is captured. The game score is updated
///   accordingly, and the GoBoardRegion representing the captured stone group
///   turns back into an empty area.
// -----------------------------------------------------------------------------
- (void) setPoint:(GoPoint*)newValue
{
  // Perform a few cheap precondition checks
  assert(PlayMove == self.type);
  if (PlayMove != self.type)
    return;
  assert(NoStone == point.stoneState);
  if (NoStone != point.stoneState)
    return;

  // ----------------------------------------------------------------------
  // The precondition that this move is legal is not checked!
  // ----------------------------------------------------------------------

  point = newValue;
  if (nil == point)  // nil should come in only during init
    return;

  if (self.black)
    point.stoneState = BlackStone;
  else
    point.stoneState = WhiteStone;

  GoBoardRegion* oldRegion = point.region;
  point.region = nil;
  [oldRegion removePoint:point];  // possible side-effect: oldRegion might be
                                  // split into multiple GoBoardRegion objects

  // Add stone to existing group and merge regions if the stone has joined
  // them together
  GoBoardRegion* newRegion = nil;
  NSArray* neighbours = point.neighbours;
  for (GoPoint* neighbour in neighbours)
  {
    if (! neighbour.hasStone)
      continue;
    if (neighbour.blackStone != point.blackStone)
      continue;
    if (neighbour.region == newRegion)
      continue;
    if (! newRegion)
    {
      // Join the stone group of one of the neighbours
      newRegion = neighbour.region;
      point.region = newRegion;
      [newRegion addPoint:point];
    }
    else
    {
      // Merge the current stone group with yet another one
      [newRegion joinRegion:neighbour.region];
    }
  }

  // Still no region? The stone forms its own new stone group!
  if (! newRegion)
  {
    newRegion = [GoBoardRegion regionWithPoint:point];
    point.region = newRegion;
  }

  // Iterate neighbours again, but this time check for captures
  int numberOfCapturedStones = 0;
  for (GoPoint* neighbour in neighbours)
  {
    if (! neighbour.hasStone)
      continue;
    if (neighbour.blackStone == point.blackStone)
      continue;
    if ([neighbour liberties] > 0)
      continue;
    // The stone made a capture!!!
    numberOfCapturedStones += [neighbour.region size];
    for (GoPoint* capture in neighbour.region.points)
    {
      // If in the next iteration of the outer loop we find a neighbour in the
      // same captured group, the neighbour will already have its state reset,
      // and we will skip it
      capture.stoneState = NoStone;
    }
  }
  // TODO do scoring here!
}

@end
