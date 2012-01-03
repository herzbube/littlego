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
#import "GoUtilities.h"
#import "GoBoardRegion.h"
#import "GoPoint.h"
#import "GoGame.h"
#import "GoBoard.h"


@implementation GoUtilities

// -----------------------------------------------------------------------------
/// @brief Moves @a thePoint to a new GoBoardRegion in response to a change of
/// GoPoint.stoneState.
///
/// @a thePoint's stone state already must have its new value at the time this
/// method is invoked.
///
/// Effects of this method are:
/// - @a thePoint is removed from its old GoBoardRegion
/// - @a thePoint is added either to an existing GoBoardRegion (if one of the
///   neighbours of @a thePoint has the same GoPoint.stoneState), or to a new
///   GoBoardRegion (if all neighbours have a different GoPoint.stoneState)
/// - @a thePoint's old GoBoardRegion may become fragmented if @a thePoint
///   has been the only link between two or more sub-regions
/// - @a thePoint's new GoBoardRegion may merge with other regions if
///   @a thePoint joins them together
// -----------------------------------------------------------------------------
+ (void) movePointToNewRegion:(GoPoint*)thePoint
{
  // Step 1: Remove point from old region
  // Note: We must retain/autorelease to make sure that oldRegion still lives
  // when we get to removePoint:() one line further down. If we don't retain
  // and thePoint is the last point of oldRegion, setting thePoint.region to
  // nil will drop oldRegion's retain count to zero and deallocate it.
  GoBoardRegion* oldRegion = [[thePoint.region retain] autorelease];
  thePoint.region = nil;
  [oldRegion removePoint:thePoint];  // possible side-effect: oldRegion might be
                                     // split into multiple GoBoardRegion objects

  // Step 2: Attempt to add the point to the same region as one of its
  // neighbours. At the same time, merge regions if they can be joined.
  GoBoardRegion* newRegion = nil;
  for (GoPoint* neighbour in thePoint.neighbours)
  {
    // Do not consider the neighbour if the stone states do not match (stone
    // state also includes stone color)
    if (neighbour.stoneState != thePoint.stoneState)
      continue;
    if (! newRegion)
    {
      // Join the region of one of the neighbours
      newRegion = neighbour.region;
      thePoint.region = newRegion;
      [newRegion addPoint:thePoint];
    }
    else
    {
      // The stone has already joined a neighbouring region
      // -> now check if entire regions can be merged
      GoBoardRegion* neighbourRegion = neighbour.region;
      if (neighbourRegion != newRegion)
        [newRegion joinRegion:neighbourRegion];
    }
  }

  // Step 3: Still no region? The point forms its own new region!
  if (! newRegion)
  {
    newRegion = [GoBoardRegion regionWithPoint:thePoint];
    thePoint.region = newRegion;
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets up the new game @a game with the handicap information stored in
/// @a handicapInfo.
///
/// @a game must be in state #GameHasNotYetStarted.
///
/// @a handicapInfo is expected to contain information obtained from GTP.
/// The expected format is: "vertex vertex vertex[...]"
///
/// @a handicapInfo may be empty to indicate that there is no handicap.
// -----------------------------------------------------------------------------
+ (void) setupNewGame:(GoGame*)game withGtpHandicap:(NSString*)handicapInfo
{
  if (GameHasNotYetStarted != game.state)
  {
    NSException* exception = [NSException exceptionWithName:@"GameStateException"
                                                     reason:@"The GoGame object is not in state GameHasNotYetStarted, but handicap can only be set up in this state."
                                                   userInfo:nil];
    @throw exception;
  }

  if (0 == handicapInfo.length)
    return;

  GoBoard* board = game.board;

  NSArray* vertexList = [handicapInfo componentsSeparatedByString:@" "];
  NSMutableArray* handicapPoints = [NSMutableArray arrayWithCapacity:vertexList.count];
  for (NSString* vertex in vertexList)
  {
    GoPoint* point = [board pointAtVertex:vertex];
    point.stoneState = GoColorBlack;
    [GoUtilities movePointToNewRegion:point];
    [handicapPoints addObject:point];
  }
  game.handicapPoints = handicapPoints;
}

// -----------------------------------------------------------------------------
/// @brief Returns the maximum handicap for the specified @a boardSize.
// -----------------------------------------------------------------------------
+ (int) maximumHandicapForBoardSize:(enum GoBoardSize)boardSize
{
  switch (boardSize)
  {
    case BoardSize7:
      return 4;
    default:
      return 9;
  }
}

@end
