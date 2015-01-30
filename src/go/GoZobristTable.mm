// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoMove.h"
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
  // http://stackoverflow.com/questions/8120062/generate-random-64-bit-integer
  // TODO switch to an algorithm from <random> once we are allowed to use C++11
  long long r30 = RAND_MAX*rand()+rand();
  long long s30 = RAND_MAX*rand()+rand();
  long long t4  = rand() & 0xf;
  long long res = (r30 << 34) + (s30 << 4) + t4;
  return res;
}

// -----------------------------------------------------------------------------
/// @brief Generates the Zobrist hash for the current board position represented
/// by @a board.
// -----------------------------------------------------------------------------
- (long long) hashForBoard:(GoBoard*)board
{
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
/// @brief Generates the Zobrist hash for @a move.
///
/// The hash is calculated incrementally from the previous move:
/// - Any stones that are captured by @a move are removed from the hash of the
///   previous move
/// - The stone that was added by @a move is added to the hash of the previous
///   move
///
/// If there is no previous move the calculation starts with 0.
///
/// If @a move is a pass move, the resulting hash is the same as for the
/// previous move.
// -----------------------------------------------------------------------------
- (long long) hashForMove:(GoMove*)move
{
  long long hash;
  if (GoMoveTypePlay == move.type)
  {
    hash = [self hashForStonePlayedBy:move.player
                              atPoint:move.point
                      capturingStones:move.capturedStones
                            afterMove:move.previous];
  }
  else
  {
    GoMove* previousMove = move.previous;
    if (previousMove)
      hash = previousMove.zobristHash;
    else
      hash = 0;
  }
  return hash;
}

// -----------------------------------------------------------------------------
/// @brief Generates the Zobrist hash for a hypothetical move played by
/// @a player on the intersection @a point, after the previous move @a move.
/// The move would capture the stones in @a capturedStones (array of GoPoint
/// objects).
///
/// The hash is calculated incrementally from the Zobrist hash of the previous
/// move @a move:
/// - Stones that are captured are removed from the hash
/// - The stone that was added is added to the hash
///
/// If @a move is nil the calculation starts with 0.
// -----------------------------------------------------------------------------
- (long long) hashForStonePlayedBy:(GoPlayer*)player
                           atPoint:(GoPoint*)point
                   capturingStones:(NSArray*)capturedStones
                         afterMove:(GoMove*)move
{
  long long hash;
  if (move)
    hash = move.zobristHash;
  else
    hash = 0;
  [self throwIfTableSizeDoesNotMatchSizeOfBoard:point.board];
  if (capturedStones)
  {
    for (GoPoint* capturedStone in capturedStones)
    {
      int indexCaptured = [self indexForStoneAt:capturedStone capturedBy:player];
      hash ^= _zobristTable[indexCaptured];
    }
  }
  int indexPlayed = [self indexForStoneAt:point playedBy:player];
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
- (int) indexForStoneAt:(GoPoint*)point playedBy:(GoPlayer*)player
{
  struct GoVertexNumeric vertex = point.vertex.numeric;
  int color = [self colorOfStonePlayedBy:player];
  return [self indexForVertex:vertex color:color boardSize:_boardSize];
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) colorOfStonePlayedBy:(GoPlayer*)player
{
  int color = player.black ? 0 : 1;
  return color;
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) indexForStoneAt:(GoPoint*)point capturedBy:(GoPlayer*)player
{
  struct GoVertexNumeric vertex = point.vertex.numeric;
  int color = [self colorOfStoneCapturedBy:player];
  return [self indexForVertex:vertex color:color boardSize:_boardSize];
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (int) colorOfStoneCapturedBy:(GoPlayer*)player
{
  // The inverse of colorOfStonePlayedBy:()
  int color = player.black ? 1 : 0;
  return color;
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
