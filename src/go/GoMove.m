// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Class extension with private properties for GoMove.
// -----------------------------------------------------------------------------
@interface GoMove()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoMoveType type;
@property(nonatomic, retain, readwrite) GoPlayer* player;
@property(nonatomic, assign, readwrite) GoMove* previous;
@property(nonatomic, assign, readwrite) GoMove* next;
@property(nonatomic, retain, readwrite) NSArray* capturedStones;
@property(nonatomic, assign, readwrite) int moveNumber;
//@}
@end


@implementation GoMove

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
      NSString* errorMessage = [NSString stringWithFormat:@"Type argument %d is invalid", type];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }

  if (! player)
  {
    NSString* errorMessage = @"Player argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoMove* newMove = [[GoMove alloc] init:type by:player];
  if (newMove)
  {
    if (move)
    {
      newMove.previous = move;
      move.next = newMove;
      newMove.moveNumber = move.moveNumber + 1;
    }
    [newMove autorelease];
  }
  return newMove;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoMove object. The GoMove has type @a aType, is
/// associated with @a aPlayer, and has no predecessor or successor GoMove. The
/// GoMove has move number 1.
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
  _point = nil;  // don't use self, otherwise we trigger the setter!
  self.previous = nil;
  self.next = nil;
  self.capturedStones = [NSMutableArray arrayWithCapacity:0];
  self.moveNumber = 1;

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
  self.type = [decoder decodeIntForKey:goMoveTypeKey];
  self.player = [decoder decodeObjectForKey:goMovePlayerKey];
  _point = [decoder decodeObjectForKey:goMovePointKey];  // don't use self, otherwise we trigger the setter!
  self.previous = [decoder decodeObjectForKey:goMovePreviousKey];
  self.next = [decoder decodeObjectForKey:goMoveNextKey];
  self.capturedStones = [decoder decodeObjectForKey:goMoveCapturedStonesKey];
  self.moveNumber = [decoder decodeIntForKey:goMoveMoveNumberKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoMove object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.player = nil;
  _point = nil;  // don't use self, otherwise we trigger the setter!
  if (self.previous)
  {
    self.previous.next = nil;  // remove reference to self
    self.previous = nil;  // not strictly necessary since we don't retain it
  }
  if (self.next)
  {
    self.next.previous = nil;  // remove reference to self
    self.next = nil;  // not strictly necessary since we don't retain it
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
  return [NSString stringWithFormat:@"GoMove(%p): type = %d, move number = %d", self, _type, _moveNumber];
}

// -----------------------------------------------------------------------------
/// @brief Associates the GoPoint @a newValue with this GoMove.
///
/// The caller must have checked whether placing the stone at @a newValue is a
/// legal move.
///
/// Raises an @e NSInternalInconsistencyException if this GoMove is not of type
/// #GoMoveTypePlay.
// -----------------------------------------------------------------------------
- (void) setPoint:(GoPoint*)newValue
{
  if (GoMoveTypePlay != self.type)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"GoMove is not of type GoMoveTypePlay (actual type is %d)", self.type];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  _point = newValue;
}

// -----------------------------------------------------------------------------
/// @brief Modifies the board to reflect the state after this GoMove was played.
///
/// Invoking this method has no effect unless this GoMove is of type
/// #GoMoveTypePlay.
///
/// If this GoMove is of type #GoMoveTypePlay, this method effectively places a
/// stone at the intersection referred to by the GoPoint object stored in the
/// @e point property. This placing of a stone includes the following
/// modifications:
/// - Updates GoPoint.stoneState for the GoPoint object in property @e point.
/// - Updates GoPoint.region for the GoPoint object in property @e point. As a
///   result, GoBoardRegions may become fragmented and/or multiple
///   GoBoardRegions may merge with other regions.
/// - If placing the stone reduces an opposing stone group to 0 (zero)
///   liberties, that stone group is captured. The GoBoardRegion representing
///   the captured stone group turns back into an empty area.
///
/// Raises an @e NSInternalInconsistencyException if this GoMove is of type
/// #GoMoveTypePlay and one of the following conditions is true:
/// - The @e point property is nil
/// - The color of the GoPoint object in the @e point property is not
///   #GoColorNone (i.e. there already is a stone on the intersection).
// -----------------------------------------------------------------------------
- (void) doIt
{
  // Nothing to do for pass moves
  if (GoMoveTypePass == self.type)
    return;

  if (! self.point)
  {
    NSString* errorMessage = @"GoMove has no associated GoPoint";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (GoColorNone != self.point.stoneState)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Color of GoPoint %@ is not GoColorNone (actual color is %d)", self.point, self.point.stoneState];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  // Update the point's stone state *BEFORE* moving it to a new region
  if (self.player.black)
    self.point.stoneState = GoColorBlack;
  else
    self.point.stoneState = GoColorWhite;
  [GoUtilities movePointToNewRegion:self.point];

  // If the captured stones array already contains entries we assume that this
  // invocation of doIt() is actually a "redo", i.e. undo() has previously been
  // invoked for this GoMove
  bool redo = (_capturedStones.count > 0);

  // Check neighbours for captures
  for (GoPoint* neighbour in self.point.neighbours)
  {
    if (! neighbour.hasStone)
      continue;
    if (neighbour.blackStone == self.point.blackStone)
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
      if (redo)
      {
        if (! [_capturedStones containsObject:capture])
        {
          NSString* message = [NSString stringWithFormat:@"Redo of %@: Captured stone on point %@ is not in array", self, capture];
          DDLogError(@"%@", message);
          NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                           reason:message
                                                         userInfo:nil];
          @throw exception;
        }
      }
      else
      {
        [(NSMutableArray*)_capturedStones addObject:capture];
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Reverts the board to the state it had before this GoMove was played.
///
/// As a side-effect of this method, GoBoardRegions may become fragmented
/// and/or multiple GoBoardRegions may merge with other regions.
///
/// Raises an @e NSInternalInconsistencyException if this GoMove is of type
/// #GoMoveTypePlay and one of the following conditions is true:
/// - The @e point property is nil
/// - The color of the GoPoint object in the @e point property does not match
///   the color of the player in the @e player property.
// -----------------------------------------------------------------------------
- (void) undo
{
  // Nothing to do for pass moves
  if (GoMoveTypePass == self.type)
    return;

  if (! _point)
  {
    NSString* errorMessage = @"GoMove has no associated GoPoint";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  enum GoColor playedStoneColor;
  enum GoColor capturedStoneColor;
  if (self.player.black)
  {
    playedStoneColor = GoColorBlack;
    capturedStoneColor = GoColorWhite;
  }
  else
  {
    playedStoneColor = GoColorWhite;
    capturedStoneColor = GoColorBlack;
  }
  if (playedStoneColor != self.point.stoneState)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Color of GoPoint %@ does not match player color %d (actual color is %d)", self.point, playedStoneColor, self.point.stoneState];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  // Update stone state of captured stones *BEFORE* handling the actual point
  // of this move. This makes sure that GoUtilities::movePointToNewRegion:()
  // further down does not join regions incorrectly.
  for (GoPoint* capture in self.capturedStones)
    capture.stoneState = capturedStoneColor;

  // Update the point's stone state *BEFORE* moving it to a new region
  GoPoint* thePoint = self.point;
  thePoint.stoneState = GoColorNone;
  [GoUtilities movePointToNewRegion:thePoint];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeInt:self.type forKey:goMoveTypeKey];
  [encoder encodeObject:self.player forKey:goMovePlayerKey];
  [encoder encodeObject:self.point forKey:goMovePointKey];
  [encoder encodeObject:self.previous forKey:goMovePreviousKey];
  [encoder encodeObject:self.next forKey:goMoveNextKey];
  [encoder encodeObject:self.capturedStones forKey:goMoveCapturedStonesKey];
  [encoder encodeInt:self.moveNumber forKey:goMoveMoveNumberKey];
}

@end
