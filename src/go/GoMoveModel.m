// -----------------------------------------------------------------------------
// Copyright 2012-213 Patrick Näf (herzbube@herzbube.ch)
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
#import "../go/GoMove.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoMoveModel.
// -----------------------------------------------------------------------------
@interface GoMoveModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name NSCoding protocol
//@{
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
//@}
/// @name Private properties
//@{
@property(nonatomic, retain) NSMutableArray* moveList;
//@}
@end


@implementation GoMoveModel

@synthesize moveList;


// -----------------------------------------------------------------------------
/// @brief Initializes a GoMoveModel object.
///
/// @note This is the designated initializer of GoMoveModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.moveList = [NSMutableArray arrayWithCapacity:0];

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
  self.moveList = [decoder decodeObjectForKey:goMoveModelMoveListKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoMoveModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.moveList = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (int) numberOfMoves
{
  return moveList.count;
}

// -----------------------------------------------------------------------------
/// @brief Adds the GoMove object @a move to this model.
///
/// Raises @e NSInvalidArgumentException if @a move is nil.
// -----------------------------------------------------------------------------
- (void) appendMove:(GoMove*)move
{
  [moveList addObject:move];
  [[NSNotificationCenter defaultCenter] postNotificationName:goMoveModelChanged object:self];
}

// -----------------------------------------------------------------------------
/// @brief Discards the last GoMove object in this model.
///
/// Raises @e NSRangeException if there are no GoMove objects in this model.
// -----------------------------------------------------------------------------
- (void) discardLastMove
{
  [self discardMovesFromIndex:(moveList.count - 1)];  // raises exception and posts notification for us
}

// -----------------------------------------------------------------------------
/// @brief Discards all GoMove objects in this model starting with the object
/// at position @a index.
///
/// Raises @e NSRangeException if @a index is <0 or exceeds the number of
/// GoMove objects in this model.
// -----------------------------------------------------------------------------
- (void) discardMovesFromIndex:(int)index
{
  if (index < 0)
  {
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:[NSString stringWithFormat:@"Index %d must not be <0", index]
                                                   userInfo:nil];
    @throw exception;
  }
  if (index >= moveList.count)
  {
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:[NSString stringWithFormat:@"Index %d must not exceed number of moves %d", index, moveList.count]
                                                   userInfo:nil];
    @throw exception;
  }

  int numberOfMovesToDiscard = moveList.count - index;
  while (numberOfMovesToDiscard > 0)
  {
    [moveList removeLastObject];
    --numberOfMovesToDiscard;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goMoveModelChanged object:self];
}

// -----------------------------------------------------------------------------
/// @brief Discards all GoMove objects in this model.
///
/// Raises @e NSRangeException if there are no GoMove objects in this model.
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
  return [moveList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoMove*) firstMove
{
  if (0 == moveList.count)
    return nil;
  return [moveList objectAtIndex:0];
}
          
// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoMove*) lastMove
{
  if (0 == moveList.count)
    return nil;
  return [moveList lastObject];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.moveList forKey:goMoveModelMoveListKey];
}

@end
