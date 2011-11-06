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
#import "GoScore.h"
#import "GoGame.h"
#import "GoMove.h"
#import "GoPlayer.h"
#import "../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoScore.
// -----------------------------------------------------------------------------
@interface GoScore()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name Other methods
//@{
//@}
/// @name Privately declared properties
//@{
@property(assign) GoGame* game;
@property bool didOneOrMoreCalculations;
//@}
@end


@implementation GoScore

@synthesize komi;
@synthesize capturedByBlack;
@synthesize capturedByWhite;
@synthesize deadBlack;
@synthesize deadWhite;
@synthesize territoryBlack;
@synthesize territoryWhite;
@synthesize totalScoreBlack;
@synthesize totalScoreWhite;
@synthesize result;
@synthesize numberOfMoves;
@synthesize stonesPlayedByBlack;
@synthesize stonesPlayedByWhite;
@synthesize passesPlayedByBlack;
@synthesize passesPlayedByWhite;
@synthesize game;
@synthesize didOneOrMoreCalculations;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoScore instance that operates on
/// @a game.
// -----------------------------------------------------------------------------
+ (GoScore*) scoreFromGame:(GoGame*)game
{
  GoScore* score = [[GoScore alloc] init];
  if (score)
  {
    score.game = game;
    [score autorelease];
  }
  return score;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoScore object.
///
/// @note This is the designated initializer of GoPoint.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  komi = 0;
  capturedByBlack = 0;
  capturedByWhite = 0;
  deadBlack = 0;
  deadWhite = 0;
  territoryBlack = 0;
  territoryWhite = 0;
  totalScoreBlack = 0;
  totalScoreWhite = 0;
  result = GoGameResultNone;
  numberOfMoves = 0;
  stonesPlayedByBlack = 0;
  stonesPlayedByWhite = 0;
  passesPlayedByBlack = 0;
  passesPlayedByWhite = 0;
  game = nil;
  didOneOrMoreCalculations = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPoint object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Calculates the new score.
// -----------------------------------------------------------------------------
- (void) calculate
{
  if (! didOneOrMoreCalculations)
  {
    didOneOrMoreCalculations = true;
    // TODO query GTP engine for initial list of dead stones
  }

  // Komi
  komi = game.komi;

  // Captured stones and move statistics
  numberOfMoves = 0;
  GoMove* move = game.firstMove;
  while (move != nil)
  {
    ++numberOfMoves;
    bool moveByBlack = move.player.black;
    switch (move.type)
    {
      case PlayMove:
      {
        if (moveByBlack)
        {
          capturedByBlack += move.capturedStones.count;
          ++stonesPlayedByBlack;
        }
        else
        {
          capturedByWhite += move.capturedStones.count;
          ++stonesPlayedByWhite;
        }
        break;
      }
      case PassMove:
      {
        if (moveByBlack)
          ++passesPlayedByBlack;
        else
          ++passesPlayedByWhite;
        break;
      }
      default:
        break;
    }
    move = move.next;
  }

  // Territory
  // TODO
  deadBlack = 0;
  deadWhite = 0;
  territoryBlack = 0;
  territoryWhite = 0;

  // Total score
  totalScoreBlack = capturedByBlack + deadWhite + territoryBlack;
  totalScoreWhite = komi + capturedByWhite + deadBlack + territoryWhite;

  // Final result
  if (totalScoreBlack > totalScoreWhite)
    result = GoGameResultBlackHasWon;
  else if (totalScoreWhite > totalScoreBlack)
    result = GoGameResultWhiteHasWon;
  else
    result = GoGameResultTie;
}

// -----------------------------------------------------------------------------
/// @brief Returns a nicely formatted string that reflects the overall result
/// of the current scoring information. The string can be displayed to the user.
// -----------------------------------------------------------------------------
- (NSString*) resultString
{
  switch (self.result)
  {
    case GoGameResultNone:
      return @"No score calculated yet";
    case GoGameResultBlackHasWon:
    {
      NSString* score = [NSString stringWithFractionValue:self.totalScoreBlack - self.totalScoreWhite];
      return [NSString stringWithFormat:@"Black wins by %@", score];
    }
    case GoGameResultWhiteHasWon:
    {
      NSString* score = [NSString stringWithFractionValue:self.totalScoreWhite - self.totalScoreBlack];
      return [NSString stringWithFormat:@"White wins by %@", score];
    }
    case GoGameResultTie:
      return @"Game is a tie";
    default:
    {
      assert(0);
      break;
    }
  }
  return @"Error calculating score";
}

@end
