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
- (id) init:(enum GoMoveType)aType by:(GoPlayer*)aPlayer;
- (void) dealloc;
//@}
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoMoveType type;
@property(nonatomic, retain, readwrite) GoPlayer* player;
@property(nonatomic, assign, readwrite) GoMove* previous;
@property(nonatomic, retain, readwrite) GoMove* next;
@property(nonatomic, retain, readwrite) NSArray* capturedStones;
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
/// created GoMove instance becomes its successor. @a move may be nil, in which
/// case the newly created GoMove instance will be the first move of the game.
///
/// Raises an @e NSInvalidArgumentException if @a type is invalid or @a player
/// is nil.
// -----------------------------------------------------------------------------
+ (GoMove*) move:(enum GoMoveType)type by:(GoPlayer*)player after:(GoMove*)move
{
  switch (type)
  {
    case GoMoveTypePlay:
    case GoMoveTypePass:
      break;
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Type argument %d is invalid", type]
                                                     userInfo:nil];
      @throw exception;
    }
  }

  if (! player)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Player argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }

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
/// @brief Initializes a GoMove object. The GoMove has type @a aType, is
/// associated with @a aPlayer, and has no predecessor or successor GoMove.
///
/// @note This is the designated initializer of GoMove.
// -----------------------------------------------------------------------------
- (id) init:(enum GoMoveType)aType by:(GoPlayer*)aPlayer
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.type = aType;
  self.player = aPlayer;
  point = nil;  // don't use self, otherwise we trigger the setter!
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
  point = nil;  // don't use self, otherwise we trigger the setter!
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
/// must be of type #GoMoveTypePlay and must not have already a point associated
/// with it.
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
///   liberties, that stone group is captured. The GoBoardRegion representing
///   the captured stone group turns back into an empty area.
///
/// Raises an @e NSInternalInconsistencyException if this GoMove is not of type
/// #GoMoveTypePlay, or if another GoPoint object is already associated with
/// this GoMove.
///
/// Raises an @e NSInvalidArgumentException if @a newValue is nil, or if the
/// color of @a newValue is not #GoColorNone.
// -----------------------------------------------------------------------------
- (void) setPoint:(GoPoint*)newValue
{
  // Perform a few cheap precondition checks
  if (GoMoveTypePlay != self.type)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:[NSString stringWithFormat:@"GoMove is not of type GoMoveTypePlay (actual type is %d)", self.type]
                                                   userInfo:nil];
    @throw exception;
  }
  if (point != nil)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:[NSString stringWithFormat:@"GoMove already has an associated GoPoint (%@)", point]
                                                   userInfo:nil];
    @throw exception;
  }
  if (! newValue)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"GoPoint argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }
  if (GoColorNone != newValue.stoneState)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:[NSString stringWithFormat:@"GoPoint color is not GoColorNone (actual color is %d)", newValue.stoneState]
                                                   userInfo:nil];
    @throw exception;
  }

  // ----------------------------------------------------------------------
  // The precondition that this move is legal is not checked because the check
  // is too expensive and adds a new dependency.
  // ----------------------------------------------------------------------

  point = newValue;

  // Update the point's stone state *BEFORE* moving it to a new region
  if (self.player.black)
    newValue.stoneState = GoColorBlack;
  else
    newValue.stoneState = GoColorWhite;
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
      capture.stoneState = GoColorNone;
      [(NSMutableArray*)capturedStones addObject:capture];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Reverts the board to the state it had before this GoMove was played.
/// Also removes references from/to the predecessor GoMove, which usually causes
/// this GoMove to be deallocated.
///
/// As a side-effect of this method, GoBoardRegions may become fragmented
/// and/or multiple GoBoardRegions may merge with other regions.
///
/// Raises an @e NSInternalInconsistencyException if this GoMove is of type
/// #GoMoveTypePlay but has no associated GoPoint object.
// -----------------------------------------------------------------------------
- (void) undo
{
  if (GoMoveTypePlay == self.type)
  {
    if (! point)
    {
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:@"GoMove has no associated GoPoint"
                                                     userInfo:nil];
      @throw exception;
    }

    // Update stone state of captured stones *BEFORE* handling the actual point
    // of this move. This makes sure that GoUtilities::movePointToNewRegion:()
    // further down does not join regions incorrectly.
    enum GoColor capturedStoneColor;
    if (self.player.black)
      capturedStoneColor = GoColorWhite;
    else
      capturedStoneColor = GoColorBlack;
    for (GoPoint* capture in self.capturedStones)
      capture.stoneState = capturedStoneColor;
    [(NSMutableArray*)capturedStones removeAllObjects];

    // Update the point's stone state *BEFORE* moving it to a new region
    GoPoint* thePoint = self.point;
    thePoint.stoneState = GoColorNone;
    [GoUtilities movePointToNewRegion:thePoint];
  }

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
