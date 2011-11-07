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
#import "GoBoard.h"
#import "GoGame.h"
#import "GoMove.h"
#import "GoPlayer.h"
#import "GoPoint.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"
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
/// @name Private helpers
//@{
- (void) resetValues;
- (void) doCalculate;
- (void) calculateEnds;
- (bool) initializeBoard;
- (NSArray*) parseDeadStoneGtpResponse:(NSString*)gtpResponse;
//@}
/// @name Privately declared properties
//@{
@property(assign) GoGame* game;
@property(retain) NSOperationQueue* operationQueue;
@property bool boardIsInitialized;
@property bool lastCalculationHadError;
//@}
@end


@implementation GoScore

@synthesize territoryScoresAvailable;
@synthesize scoringInProgress;
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
@synthesize operationQueue;
@synthesize boardIsInitialized;
@synthesize lastCalculationHadError;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoScore instance that operates on
/// @a game.
///
/// If @a withTerritoryScores is true, this GoScore calculates territory scores.
// -----------------------------------------------------------------------------
+ (GoScore*) scoreForGame:(GoGame*)game withTerritoryScores:(bool)withTerritoryScores
{
  GoScore* score = [[GoScore alloc] init];
  if (score)
  {
    score.game = game;
    score.territoryScoresAvailable = withTerritoryScores;
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

  territoryScoresAvailable = false;
  scoringInProgress = false;
  game = nil;
  operationQueue = [[NSOperationQueue alloc] init];
  boardIsInitialized = false;
  lastCalculationHadError = false;
  [self resetValues];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPoint object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.operationQueue = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Resets all score values to zero. Typically invoked before a new
/// calculation starts.
// -----------------------------------------------------------------------------
- (void) resetValues
{
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
}

// -----------------------------------------------------------------------------
/// @brief Starts calculation of a new score.
///
/// If @a waitUntilDone is false, this method returns immediately and does not
/// wait for the calculation to finish.
///
/// Observers are notified of the start and end of the calculation by the
/// notifications #goScoreCalculationStarts and #goScoreCalculationStarts which
/// are posted on the application's default NSNotificationCentre.
///
/// @note This method does nothing if a scoring operation is already in
/// progress.
// -----------------------------------------------------------------------------
- (void) calculateWaitUntilDone:(bool)waitUntilDone
{
  if (self.scoringInProgress)
    return;
  self.scoringInProgress = true;

  if (waitUntilDone)
    [self doCalculate];
  else
  {
    NSInvocationOperation* operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                            selector:@selector(doCalculate)
                                                                              object:nil];
    [self.operationQueue addOperation:operation];
    [operation release];
  }
}

// -----------------------------------------------------------------------------
/// @brief Calculates a new score.
///
/// This method runs in the main thread context if calculateWaitUntilDone:()
/// was invoked with value @e true for the @e waitUntilDone argument. If the
/// argument value was @e false, though, this method runs in the context of a
/// secondary thread.
// -----------------------------------------------------------------------------
- (void) doCalculate
{
  @try
  {
    lastCalculationHadError = false;
    [self resetValues];

    // Initialize board only if territory scores are requested
    if (territoryScoresAvailable)
    {
      if (! boardIsInitialized)
      {
        bool success = [self initializeBoard];
        if (! success)
        {
          lastCalculationHadError = true;
          return;
        }
        boardIsInitialized = true;
      }
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
    if (territoryScoresAvailable)
    {
      deadBlack = 0;
      deadWhite = 0;
      territoryBlack = 0;
      territoryWhite = 0;
    }

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
  @finally
  {
    [self performSelector:@selector(calculateEnds)
                 onThread:[NSThread mainThread]
               withObject:nil
            waitUntilDone:NO];
  }
}

// -----------------------------------------------------------------------------
/// @brief Is invoked by doCalculate() when it finishes its calculation.
/// Notifies observers by posting #goScoreCalculationEnds on the application's
/// default NSNotificationCentre.
///
/// This method is always executed in the context of the main thread.
// -----------------------------------------------------------------------------
- (void) calculateEnds
{
  self.scoringInProgress = false;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setScoringInProgress:(bool)newValue
{
  if (scoringInProgress == newValue)
    return;
  scoringInProgress = newValue;
  NSString* notificationName;
  if (newValue)
    notificationName = goScoreCalculationStarts;
  else
    notificationName = goScoreCalculationEnds;
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

// -----------------------------------------------------------------------------
/// @brief Returns a nicely formatted string that reflects the overall result
/// of the current scoring information. The string can be displayed to the user.
// -----------------------------------------------------------------------------
- (NSString*) resultString
{
  if (lastCalculationHadError)
    return @"Error calculating score";

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
  return @"Unknown game result";
}

// -----------------------------------------------------------------------------
/// @brief Initializes all GoPoint objects on the board in preparation of
/// territory scoring.
///
/// The GoPoint objects are set to belong to no territory. An initial set of
/// dead stones, discovered by the GTP engine, is also marked.
///
/// Returns true if initialization was successful, false if not.
// -----------------------------------------------------------------------------
- (bool) initializeBoard
{
  // Initialize territory color
  GoBoard* board = game.board;
  GoPoint* point = [board pointAtVertex:@"A1"];
  for (; point = point.next; point != nil)
    point.territoryColor = GoColorNone;

  // Initialize dead stones
  GtpCommand* command = [GtpCommand command:@"final_status_list dead"];
  command.waitUntilDone = true;
  [command submit];
  if (! command.response.status)
    return true;  // although it's weird we can live with GTP not providing an initial list of dead stones
  NSArray* deadStoneVertexList = [self parseDeadStoneGtpResponse:command.response.parsedResponse];
  for (NSString* vertex in deadStoneVertexList)
  {
    GoPoint* point = [board pointAtVertex:vertex];
    if (! [point hasStone])
    {
      assert(0);
      return false;
    }
    point.deadStone = true;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Parses @a gtpResponse, which is expected to be the response to the
/// command "final_status_list dead", for strings that denote vertexes. Returns
/// a list with all vertexes found.
// -----------------------------------------------------------------------------
- (NSArray*) parseDeadStoneGtpResponse:(NSString*)gtpResponse
{
  NSMutableArray* deadStoneVertexList = [NSMutableArray arrayWithCapacity:0];
  if (0 == gtpResponse.length)
    return deadStoneVertexList;
  NSArray* responseLines = [gtpResponse componentsSeparatedByString:@"\n"];
  for (NSString* responseLine in responseLines)
  {
    if (0 == responseLine.length)
      continue;
    NSArray* vertexList = [responseLine componentsSeparatedByString:@" "];
    for (NSString* vertex in vertexList)
    {
      if (0 == vertex.length)
        continue;
      [deadStoneVertexList addObject:vertex];
    }
  }
  return deadStoneVertexList;
}

// -----------------------------------------------------------------------------
/// @brief Toggles the status of the stone group to which @a point belongs from
/// alive to dead, or vice versa.
///
/// Invoking this method does not change the current scoring values. The client
/// needs to separately invoke calculate() to get the updated score.
///
/// @note This method does nothing if territory scoring is not enabled on this
/// GoScore object, or if a scoring operation is already in progress.
// -----------------------------------------------------------------------------
- (void) togglePoint:(GoPoint*)point
{
  if (! territoryScoresAvailable)
    return;
  if (! scoringInProgress)
    return;
  // TODO xxx implement
}

@end
