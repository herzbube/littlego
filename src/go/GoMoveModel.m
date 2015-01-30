// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoMoveModel.h"
#import "GoGame.h"
#import "GoGameDocument.h"
#import "../go/GoMove.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoMoveModel.
// -----------------------------------------------------------------------------
@interface GoMoveModel()
/// @name Private properties
//@{
@property(nonatomic, assign) GoGame* game;
@property(nonatomic, retain) NSMutableArray* moveList;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) int numberOfMoves;
//@}
@end


@implementation GoMoveModel

// -----------------------------------------------------------------------------
/// @brief Initializes a GoMoveModel object that is associated with @a game.
///
/// @note This is the designated initializer of GoMoveModel.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)game
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.game = game;
  self.moveList = [NSMutableArray arrayWithCapacity:0];
  self.numberOfMoves = 0;
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
  self.game = [decoder decodeObjectForKey:goMoveModelGameKey];
  self.moveList = [decoder decodeObjectForKey:goMoveModelMoveListKey];
  self.numberOfMoves = [decoder decodeIntForKey:goMoveModelNumberOfMovesKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoMoveModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  self.moveList = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Adds the GoMove object @a move to this model.
///
/// Raises @e NSInvalidArgumentException if @a move is nil.
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) appendMove:(GoMove*)move
{
  [_moveList addObject:move];
  self.game.document.dirty = true;
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) moves.
  self.numberOfMoves = (int)_moveList.count;  // triggers KVO observers
}

// -----------------------------------------------------------------------------
/// @brief Discards the last GoMove object in this model.
///
/// Raises @e NSRangeException if there are no GoMove objects in this model.
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) discardLastMove
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) moves.
  [self discardMovesFromIndex:((int)_moveList.count - 1)];  // raises exception and posts notification for us
}

// -----------------------------------------------------------------------------
/// @brief Discards all GoMove objects in this model starting with the object
/// at position @a index.
///
/// Raises @e NSRangeException if @a index is <0 or exceeds the number of
/// GoMove objects in this model.
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) discardMovesFromIndex:(int)index
{
  if (index < 0)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Index %d must not be <0", index];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (index >= _moveList.count)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Index %d must not exceed number of moves %ld", index, _moveList.count];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  NSUInteger numberOfMovesToDiscard = _moveList.count - index;
  while (numberOfMovesToDiscard > 0)
  {
    [_moveList removeLastObject];
    --numberOfMovesToDiscard;
  }

  self.game.document.dirty = true;
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) moves.
  self.numberOfMoves = (int)_moveList.count;  // triggers KVO observers
}

// -----------------------------------------------------------------------------
/// @brief Discards all GoMove objects in this model.
///
/// Raises @e NSRangeException if there are no GoMove objects in this model.
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) discardAllMoves
{
  [self discardMovesFromIndex:0];  // raises exception and posts notification for us
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoMove object located at index position @a index.
///
/// Raises @e NSRangeException if @a index is <0 or exceeds the number of
/// GoMove objects in this model.
// -----------------------------------------------------------------------------
- (GoMove*) moveAtIndex:(int)index
{
  return [_moveList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoMove*) firstMove
{
  if (0 == _moveList.count)
    return nil;
  return [_moveList objectAtIndex:0];
}
          
// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoMove*) lastMove
{
  if (0 == _moveList.count)
    return nil;
  return [_moveList lastObject];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.game forKey:goMoveModelGameKey];
  [encoder encodeObject:self.moveList forKey:goMoveModelMoveListKey];
  [encoder encodeInt:self.numberOfMoves forKey:goMoveModelNumberOfMovesKey];
}

@end
