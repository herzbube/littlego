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
#import "GoPlayer.h"
#import "GoPoint.h"
#import "GoBoardRegion.h"
#import "GoUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoMove.
// -----------------------------------------------------------------------------
@interface GoMove()
/// @name Initialization and deallocation
//@{
- (id) init:(enum GoMoveType)initType by:(GoPlayer*)initPlayer;
- (void) dealloc;
//@}
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite) enum GoMoveType type;
@property(readwrite, retain) GoPlayer* player;
@property(readwrite, assign) GoMove* previous;
@property(readwrite, retain) GoMove* next;
@property(readwrite, retain) NSArray* capturedStones;
//@}
@end


@implementation GoMove

@synthesize type;
@synthesize player;
@synthesize point;
@synthesize previous;
@synthesize next;
@synthesize capturedStones;
@synthesize computerGenerated;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoMove instance of type @a type,
/// which is associated with @a player, and whose predecessor is @a move.
///
/// If @a move is not nil, this method updates @a move so that the newly
/// created GoMove instance becomes its successor. The newly created GoMove
/// instance also gets the alternate color of its predecessor @a move (e.g. if
/// @a move is black, the new GoMove will be white).
///
/// @a move may be nil, in which case the newly created GoMove instance will be
/// black, and the first move of the game.
// -----------------------------------------------------------------------------
+ (GoMove*) move:(enum GoMoveType)type by:(GoPlayer*)player after:(GoMove*)move
{
  GoMove* newMove = [[GoMove alloc] init:type by:player];
  if (newMove)
  {
    newMove.previous = move;
    if (move)
      move.next = newMove;  // set reference to self
    [newMove autorelease];
  }
  return newMove;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoMove object. The GoMove has type @a type, is
/// associated with @a initPlayer, and has no predecessor or successor GoMove.
///
/// @note This is the designated initializer of GoMove.
// -----------------------------------------------------------------------------
- (id) init:(enum GoMoveType)initType by:(GoPlayer*)initPlayer
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  assert(initPlayer != nil);

  self.type = initType;
  self.player = initPlayer;
  self.point = nil;
  self.previous = nil;
  self.next = nil;
  self.capturedStones = [NSMutableArray arrayWithCapacity:0];
  self.computerGenerated = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoMove object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.player = nil;
  self.point = nil;     // not strictly necessary since we don't retain it
  self.previous = nil;  // not strictly necessary since we don't retain it
  if (self.next)
  {
    self.next.previous = nil;  // remove reference to self
    self.next = nil;
  }
  self.capturedStones = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoMove object.
///
/// This method is invoked when GoMove needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoMove(%p): type = %d", self, type];
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
/// - Updates GoPoint.region for GoPoint @a newValue. GoBoardRegions may become
///   fragmented and/or multiple GoBoardRegions may merge with other regions.
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
  assert(NoStone == newValue.stoneState);
  if (NoStone != newValue.stoneState)
    return;

  // ----------------------------------------------------------------------
  // The precondition that this move is legal is not checked!
  // ----------------------------------------------------------------------

  point = newValue;
  if (nil == newValue)  // nil should come in only during init
    return;

  // Update the point's stone state *BEFORE* moving it to a new region
  if (self.player.black)
    newValue.stoneState = BlackStone;
  else
    newValue.stoneState = WhiteStone;
  [GoUtilities movePointToNewRegion:newValue];

  // Check neighbours for captures
  for (GoPoint* neighbour in newValue.neighbours)
  {
    if (! neighbour.hasStone)
      continue;
    if (neighbour.blackStone == newValue.blackStone)
      continue;
    if ([neighbour liberties] > 0)
      continue;
    // The stone made a capture!!!
    for (GoPoint* capture in neighbour.region.points)
    {
      // If in the next iteration of the outer loop we find a neighbour in the
      // same captured group, the neighbour will already have its state reset,
      // and we will skip it
      capture.stoneState = NoStone;
      [(NSMutableArray*)capturedStones addObject:capture];
    }
  }
  // TODO do scoring here!
}

// -----------------------------------------------------------------------------
/// @brief Reverts the board to the state it had before this GoMove was played.
/// Does nothing if this GoMove is not of type #PlayMove.
///
/// As a side-effect of this method, GoBoardRegions may become fragmented
/// and/or multiple GoBoardRegions may merge with other regions.
// -----------------------------------------------------------------------------
- (void) undo
{
  if (PlayMove != self.type)
    return;

  // Update stone state of captured stones *BEFORE* handling the actual point
  // of this move. This makes sure that GoUtilities::movePointToNewRegion:()
  // further down does not join regions incorrectly.
  enum GoStoneState capturedStoneState;
  if (self.player.black)
    capturedStoneState = WhiteStone;
  else
    capturedStoneState = BlackStone;
  for (GoPoint* capture in self.capturedStones)
    capture.stoneState = capturedStoneState;

  // Update the point's stone state *BEFORE* moving it to a new region
  GoPoint* thePoint = self.point;
  assert(thePoint);
  thePoint.stoneState = NoStone;
  [GoUtilities movePointToNewRegion:thePoint];

  // Remove references from/to predecessor. This decreases the retain count of
  // this GoMove and may lead to deallocation
  if (self.previous)
  {
    self.previous.next = nil;
    self.previous = nil;
  }

  // Not strictly necessary since we expect to be deallocated soon
  point = nil;  // make sure not to use the setter here!
  self.player = nil;
}

@end
