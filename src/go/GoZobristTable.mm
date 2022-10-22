// -----------------------------------------------------------------------------
// Copyright 2013-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoZobristTable.h"
#import "GoBoard.h"
#import "GoGame.h"
#import "GoMove.h"
#import "GoNode.h"
#import "GoNodeSetup.h"
#import "GoPlayer.h"
#import "GoPoint.h"
#import "GoVertex.h"

// C++ standard library
#include <cstdlib>
#include <ctime>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoZobristTable.
// -----------------------------------------------------------------------------
@interface GoZobristTable()
@property(nonatomic, assign) enum GoBoardSize boardSize;
@property(nonatomic, assign) long long* zobristTable;
@end


@implementation GoZobristTable

// -----------------------------------------------------------------------------
/// @brief Initializes a GoZobristTable object for use with a board of size
/// @a boardSize.
///
/// @note This is the designated initializer of GoZobristTable.
// -----------------------------------------------------------------------------
- (id) initWithBoardSize:(enum GoBoardSize)boardSize
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.boardSize = boardSize;
  [self setupZobristTable];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoZobristTable object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  delete[] _zobristTable;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// Private helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupZobristTable
{
  [self throwIfLongLongIsLessThan8Bytes];
  _zobristTable = new long long[_boardSize * _boardSize * 2];
  [self fillZobristTableWithRandomNumbers];
}

// -----------------------------------------------------------------------------
/// Private helper for setupZobristTable()
// -----------------------------------------------------------------------------
- (void) throwIfLongLongIsLessThan8Bytes
{
  size_t sizeOfLongLong = sizeof(long long);
  if (sizeOfLongLong < 8)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"sizeof(long long) is %ld, i.e. less than 8 bytes", sizeOfLongLong];
    DDLogError(@"%@", errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// Private helper for setupZobristTable()
// -----------------------------------------------------------------------------
- (void) fillZobristTableWithRandomNumbers
{
  // Cast is required because time_t (the result of time()) and unsigned (the
  // parameter of srand()) differ in size in 64-bit. Cast is safe because we
  // don't care about the exact time_t value, we just want a number that is
  // not always the same to initialize the random number generator so that we
  // won't get the same sequence of random numbers every time.
  srand((unsigned)time(NULL));
  for (int vertexX = 0; vertexX < _boardSize; ++vertexX)
  {
    for (int vertexY = 0; vertexY < _boardSize; ++vertexY)
    {
      for (int color = 0; color < 2; ++color)
      {
        int index = (color * _boardSize * _boardSize) + (vertexY * _boardSize) + vertexX;
        _zobristTable[index] = [self random64BitNumber];
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// Private helper for fillZobristTableWithRandomNumbers:()
// -----------------------------------------------------------------------------
- (long long) random64BitNumber
{
  // Implementation taken from
  // https://stackoverflow.com/questions/8120062/generate-random-64-bit-integer
  // TODO switch to an algorithm from <random> once we are allowed to use C++11
  long long r30 = RAND_MAX*rand()+rand();
  long long s30 = RAND_MAX*rand()+rand();
  long long t4  = rand() & 0xf;
  long long res = (r30 << 34) + (s30 << 4) + t4;
  return res;
}

// TODO xxx remove if no longer needed
// -----------------------------------------------------------------------------
/// @brief Generates the Zobrist hash for the current board position represented
/// by @a board.
///
/// Raises @e NSInvalidArgumentException if @a board is @e nil.
///
/// Raises @e NSGenericException if the board size with which this
/// GoZobristTable was initialized does not match the board size of the GoBoard
/// object associated with @a game.
// -----------------------------------------------------------------------------
- (long long) hashForBoard:(GoBoard*)board
{
  if (!board )
  {
    NSString* errorMessage = @"Board argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [self throwIfTableSizeDoesNotMatchSizeOfBoard:board];

  long long hash = 0;

  GoPoint* point = [board pointAtVertex:@"A1"];
  while (point)
  {
    if (point.hasStone)
    {
      int index = [self indexOfPoint:point];
      hash ^= _zobristTable[index];
    }
    point = point.next;
  }

  return hash;
}

// -----------------------------------------------------------------------------
/// @brief Generates the Zobrist hash for a board that is empty except for the
/// black handicap stones obtained from @a game.
///
/// Raises @e NSInvalidArgumentException if @a game is @e nil.
///
/// Raises @e NSGenericException if the board size with which this
/// GoZobristTable was initialized does not match the board size of the GoBoard
/// object associated with @a game.
// -----------------------------------------------------------------------------
- (long long) hashForHandicapStonesInGame:(GoGame*)game
{
  if (! game)
  {
    NSString* errorMessage = @"Game argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [self throwIfTableSizeDoesNotMatchSizeOfBoard:game.board];

  long long hash = 0;

  for (GoPoint* handicapPoint in game.handicapPoints)
  {
    int index = [self indexForStoneAt:handicapPoint playedByColor:GoColorBlack];
    hash ^= _zobristTable[index];
  }

  return hash;
}

// -----------------------------------------------------------------------------
/// @brief Generates the Zobrist hash for @a node.
///
/// The hash is calculated incrementally from the previous node:
/// - If @a node contains game setup then...
///   - Any stones that are placed by the setup are added to the hash of
///     the previous node
///   - Any stones that are removed by the setup are removed from the hash of
///     the previous node
/// - If @a node contains a move that places a stone then...
///   - Any stones that are captured by @a move are removed from the hash of the
///     previous node
///   - The stone that was added by the move is added to the hash of the previous
///     node
/// - If @a node contains a move that is a pass move, the resulting hash is the
///   same as for the previous node.
///
/// If there is no previous move the calculation starts with the hash in @a game
/// after handicap stones were placed.
///
/// Raises @e NSInvalidArgumentException if @a node or @a game is @e nil.
///
/// Raises @e NSGenericException if the board size with which this
/// GoZobristTable was initialized does not match the board size of the GoBoard
/// object associated with @a game.
///
/// Raises @e NSInternalInconsistencyException if @a node contains game setup
/// and the hash calculation finds inconsistencies in the setup information.
// -----------------------------------------------------------------------------
- (long long) hashForNode:(GoNode*)node
                   inGame:(GoGame*)game
{
  if (!node || !game)
  {
    NSString* errorMessage = @"Node or game argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  long long hash;
  if (node.goNodeSetup)
  {
    GoNodeSetup* nodeSetup = node.goNodeSetup;
    GoNode* parentNode = node.parent;
    hash = [self hashForBlackSetupStones:nodeSetup.blackSetupStones
                        whiteSetupStones:nodeSetup.whiteSetupStones
                           noSetupStones:nodeSetup.noSetupStones
                previousBlackSetupStones:nodeSetup.previousBlackSetupStones
                previousWhiteSetupStones:nodeSetup.previousWhiteSetupStones
                               afterNode:parentNode
                                  inGame:game];
  }
  else if (node.goMove && node.goMove.type == GoMoveTypePlay)
  {
    GoMove* move = node.goMove;
    GoNode* parentNode = node.parent;
    hash = [self hashForStonePlayedByColor:move.player.color
                                   atPoint:move.point
                           capturingStones:move.capturedStones
                                 afterNode:parentNode
                                    inGame:game];
  }
  else
  {
    GoNode* parentNode = node.parent;
    if (parentNode)
      hash = parentNode.zobristHash;
    else
      hash = game.zobristHashAfterHandicap;
  }

  return hash;
}

// -----------------------------------------------------------------------------
/// @brief Generates the Zobrist hash for a hypothetical game setup, where the
/// board initially contains the black and white stones in
/// @a previousBlackSetupStones and @a previousWhiteSetupStones. The game setup
/// would place the black and white stones in @a blackSetupStones and
/// @a whiteSetupStones (possibly replacing existing stones of the other color),
/// and remove stones from points listed in @a noSetupStones (the color of the
/// stones being removed is derived from the initial board state).
///
/// The hash is calculated incrementally from the Zobrist hash of the previous
/// node @a node:
/// - Stones that are placed by the setup are added to the hash of the
///   previous node
/// - Stones that are removed by the setup are removed from the hash of the
///   previous node
///
/// If @a node is @e nil the calculation starts with the hash in @a game after
/// handicap stones were placed.
///
/// Raises @e NSInvalidArgumentException if @a game is @e nil.
///
/// Raises @e NSGenericException if the board size with which this
/// GoZobristTable was initialized does not match the board size of the GoBoard
/// object associated with @a game.
///
/// Raises @e NSInternalInconsistencyException if the hash calculation finds
/// inconsistencies in the setup information.
// -----------------------------------------------------------------------------
- (long long) hashForBlackSetupStones:(NSArray*)blackSetupStones
                     whiteSetupStones:(NSArray*)whiteSetupStones
                        noSetupStones:(NSArray*)noSetupStones
             previousBlackSetupStones:(NSArray*)previousBlackSetupStones
             previousWhiteSetupStones:(NSArray*)previousWhiteSetupStones
                            afterNode:(GoNode*)node
                               inGame:(GoGame*)game
{
  if (!game)
  {
    NSString* errorMessage = @"Game argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [self throwIfTableSizeDoesNotMatchSizeOfBoard:game.board];

  long long hash;
  if (node)
    hash = node.zobristHash;
  else
    hash = game.zobristHashAfterHandicap;

  if (blackSetupStones)
  {
    for (GoPoint* point in blackSetupStones)
    {
      if (previousWhiteSetupStones && [previousWhiteSetupStones containsObject:point])
      {
        // White stone is removed & replaced by black stone
        int indexRemoved = [self indexForStoneAt:point playedByColor:GoColorWhite];
        hash ^= _zobristTable[indexRemoved];
      }

      int indexPlayed = [self indexForStoneAt:point playedByColor:GoColorBlack];
      hash ^= _zobristTable[indexPlayed];
    }
  }

  if (whiteSetupStones)
  {
    for (GoPoint* point in whiteSetupStones)
    {
      if (previousBlackSetupStones && [previousBlackSetupStones containsObject:point])
      {
        // Black stone is removed & replaced by white stone
        int indexRemoved = [self indexForStoneAt:point playedByColor:GoColorBlack];
        hash ^= _zobristTable[indexRemoved];
      }

      int indexPlayed = [self indexForStoneAt:point playedByColor:GoColorWhite];
      hash ^= _zobristTable[indexPlayed];
    }
  }

  if (noSetupStones)
  {
    for (GoPoint* point in noSetupStones)
    {
      if (previousBlackSetupStones && [previousBlackSetupStones containsObject:point])
      {
        int indexRemoved = [self indexForStoneAt:point playedByColor:GoColorBlack];
        hash ^= _zobristTable[indexRemoved];
      }
      else if (previousWhiteSetupStones && [previousWhiteSetupStones containsObject:point])
      {
        // White stone is removed & replaced by black stone
        int indexRemoved = [self indexForStoneAt:point playedByColor:GoColorWhite];
        hash ^= _zobristTable[indexRemoved];
      }
      else
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Calculating Zobrist hash for game setup failed: Setup attempts to remove stone of undetermined color at %@", point];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }
    }
  }

  return hash;
}


// -----------------------------------------------------------------------------
/// @brief Generates the Zobrist hash for a hypothetical move played by @a color
/// on the intersection @a point, after the previous node @a node. The move
/// would capture the stones in @a capturedStones (array of GoPoint objects).
///
/// The hash is calculated incrementally from the Zobrist hash of the previous
/// node @a node:
/// - Stones that are captured are removed from the hash
/// - The stone that was added is added to the hash
///
/// If @a node is @e nil the calculation starts with the hash in @a game after
/// handicap stones were placed.
///
/// Raises @e NSInvalidArgumentException if @a color is neither GoColorBlack
/// nor GoColorWhite.
///
/// Raises @e NSInvalidArgumentException if @a point or @a game is @e nil.
///
/// Raises @e NSGenericException if the board size with which this
/// GoZobristTable was initialized does not match the board size of the GoBoard
/// object associated with @a game.
// -----------------------------------------------------------------------------
- (long long) hashForStonePlayedByColor:(enum GoColor)color
                                atPoint:(GoPoint*)point
                        capturingStones:(NSArray*)capturedStones
                              afterNode:(GoNode*)node
                                 inGame:(GoGame*)game
{
  if (color != GoColorBlack && color != GoColorWhite)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Invalid color argument %d", color];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (!point || !game)
  {
    NSString* errorMessage = @"Point or game argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [self throwIfTableSizeDoesNotMatchSizeOfBoard:game.board];

  long long hash;
  if (node)
    hash = node.zobristHash;
  else
    hash = game.zobristHashAfterHandicap;

  if (capturedStones)
  {
    for (GoPoint* capturedStone in capturedStones)
    {
      int indexCaptured = [self indexForStoneAt:capturedStone capturedByColor:color];
      hash ^= _zobristTable[indexCaptured];
    }
  }

  int indexPlayed = [self indexForStoneAt:point playedByColor:color];
  hash ^= _zobristTable[indexPlayed];

  return hash;
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) indexOfPoint:(GoPoint*)point
{
  struct GoVertexNumeric vertex = point.vertex.numeric;
  int color = [self colorOfStoneAtPoint:point];
  return [self indexForVertex:vertex color:color boardSize:_boardSize];
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) colorOfStoneAtPoint:(GoPoint*)point
{
  int color = point.blackStone ? 0 : 1;
  return color;
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) indexForStoneAt:(GoPoint*)point playedByColor:(enum GoColor)color
{
  struct GoVertexNumeric vertex = point.vertex.numeric;
  int colorOfPlayedStone = [self colorOfStonePlayedByColor:color];
  return [self indexForVertex:vertex color:colorOfPlayedStone boardSize:_boardSize];
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) colorOfStonePlayedByColor:(enum GoColor)color
{
  // The inverse of colorOfStoneCapturedByColor:()
  return (GoColorBlack == color ? 0 : 1);
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) indexForStoneAt:(GoPoint*)point capturedByColor:(enum GoColor)color
{
  struct GoVertexNumeric vertex = point.vertex.numeric;
  int colorOfCapturedStone = [self colorOfStoneCapturedByColor:color];
  return [self indexForVertex:vertex color:colorOfCapturedStone boardSize:_boardSize];
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) colorOfStoneCapturedByColor:(enum GoColor)color
{
  // The inverse of colorOfStonePlayedByColor:()
  return (GoColorBlack == color ? 1 : 0);
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) indexForVertex:(struct GoVertexNumeric)vertex color:(int)color boardSize:(enum GoBoardSize)boardSize
{
  int index = (color * boardSize * boardSize) + ((vertex.y - 1) * boardSize) + (vertex.x - 1);
  return index;
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (void) throwIfTableSizeDoesNotMatchSizeOfBoard:(GoBoard*)board
{
  if (board.size != _boardSize)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Board size %d does not match Zobrist table size %d", board.size, _boardSize];
    DDLogError(@"%@", errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

@end
