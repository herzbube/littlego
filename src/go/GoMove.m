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


@implementation GoMove

@synthesize type;
@synthesize black;
@synthesize point;
@synthesize previous;
@synthesize next;

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

- (GoMove*) init:(enum GoMoveType)initType
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

// a point whose stone is removed (not relevant here) can mean only one thing:
// the stone on it, and its entire group, was captured
//
// a point that gets a stone can mean exactly one of the following:
// - the stone forms a new group
// - the stone is added to an already existing group
// - the stone merges 2-4 groups
//
// in addition, the stone may have split an existing region with no stones
// into 2-4 new regions
//
// stone groups that are captured do not form new regions, the points in the
// region simply change state
//
// liberty checks must be performed in the following order
// - if setting the stone decreases the liberties of a neighbouring group to
//   zero, that group is captured, unless there is a Ko state from the
//   previous round; a Ko state exists if
//   - the capturing stone is alone, i.e. it forms a single-stone group
//   - the captured stone is alone, i.e. it forms a single-stone group
//   - the captured stone was played in the previous move
//   - when the captured stone was played, it captured a single stone at
//     the same position that is now just played on
// - if no capture was made: if setting the stone decreases the liberties
//   of the stone's group to zero, the move is a suicide and therefore
//   illegal
- (void) setPoint:(GoPoint*)newValue
{
  point = newValue;
  if (nil == point)  // nil should come in only during init
    return;

  // --------------------------------------------------
  // TODO !!!!!!!!!!! a check must be made for illegal moves before this
  // function is invoked -> suicides and illegal Ko moves!!!!!!!!!
  // --------------------------------------------------
  
  assert(PlayMove == self.type);
  assert(NoStone == point.stoneState);

  if (self.black)
    point.stoneState = BlackStone;
  else
    point.stoneState = WhiteStone;

  // Whatever happens further down: The point with the newly placed stone will
  // become part of a different region
  GoBoardRegion* oldRegion = point.region;
  point.region = nil;
  [oldRegion removePoint:point];

  // todo check if region has been split
  // -> maybe region could implement a method that checks if there are points
  //    in it that are no longer neighbours?
  // -> most elegant: invoke that function automatically when the point is
  //    removed, then split the region
  // -> this should have no negative consequences whatsoever

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
      // If in the next iteration we find a neighbour in the same captured
      // group, the neighbour will already have its state reset, and we will
      // skip it
      capture.stoneState = NoStone;
    }
  }
  // TODO do scoring here!
}

@end
