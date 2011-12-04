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
#import "GoBoardRegion.h"
#import "GoGame.h"
#import "GoMove.h"
#import "GoPlayer.h"
#import "GoPoint.h"
#import "../ApplicationDelegate.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"
#import "../utility/NSStringAdditions.h"
#import "../play/ScoringModel.h"


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
- (bool) updateTerritoryColor;
- (void) updateScoringProperties;
- (NSArray*) parseDeadStoneGtpResponse:(NSString*)gtpResponse;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) GoGame* game;
@property(nonatomic, retain) NSOperationQueue* operationQueue;
@property(nonatomic, assign) bool boardIsInitialized;
@property(nonatomic, assign) bool lastCalculationHadError;
/// @brief List with all GoBoardRegion objects that currently exist on the
/// board.
///
/// This property exists for optimization reasons only: It contains a
/// pre-calculated list that can be reused by various methods so that they don't
/// have to re-calculate the list repeatedly (re-calculation is
/// not-quite-cheap). This approach works because during scoring mode no
/// changes to the board are possible.
@property(nonatomic, retain) NSArray* allRegions;
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
@synthesize allRegions;


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
  allRegions = nil;
  [self resetValues];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPoint object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.operationQueue = nil;
  self.allRegions = nil;
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
  self.scoringInProgress = true;  // notify while we're still in the main thread context

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

    // Pre-calculate region list exactly once
    if (! self.allRegions)
      self.allRegions = self.game.board.regions;

    // Do territory related stuff at the beginning - if any errors occur we can
    // safely abort, without half of the values already having been calculated.
    if (territoryScoresAvailable)
    {
      // Initialize board only once
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

      // Calculate territory colors every time
      bool success = [self updateTerritoryColor];
      if (! success)
      {
        lastCalculationHadError = true;
        return;
      }
    }

    // Now that territory calculations have finished, simply add up all the
    // scores and statistics
    [self updateScoringProperties];
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
  for (; point != nil; point = point.next)
  {
    GoBoardRegion* region = point.region;
    region.territoryColor = GoColorNone;
    region.territoryInconsistencyFound = false;
    region.deadStoneGroup = false;
    region.scoringMode = true;  // enabling scoring mode allows caching for optimized performance
  }

  // Initialize dead stones
  if ([ApplicationDelegate sharedDelegate].scoringModel.askGtpEngineForDeadStones)
  {
    GtpCommand* command = [GtpCommand command:@"final_status_list dead"];
    command.waitUntilDone = true;
    [command submit];
    if (command.response.status)
    {
      NSArray* deadStoneVertexList = [self parseDeadStoneGtpResponse:command.response.parsedResponse];
      for (NSString* vertex in deadStoneVertexList)
      {
        GoPoint* point = [board pointAtVertex:vertex];
        if (! [point hasStone])
        {
          assert(0);
          return false;
        }
        // TODO The next statement is problematic in two respects: 1) If the
        // region has more than one point, we repeatedly set it to be dead,
        // once for each vertex reported by the GTP engine. 2) We don't perform
        // any kind of check if the vertex list reported by the GTP engine
        // matches our regions.
        point.region.deadStoneGroup = true;
      }
    }
    else
    {
      // Although we would prefer to get a response from the GTP engine, we can
      // live without one
      // -> do nothing and simply go on, ultimately returning success
    }
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
/// @brief Toggles the status of the stone group @a stoneGroup from alive to
/// dead, or vice versa.
///
/// Once the main stone group @a stoneGroup has been updated, this method also
/// considers neighbouring regions and, if necessary, toggles the dead/alive
/// state of other stone groups to remain consistent with the logic of the game
/// rules. The overall effect might be a cascade of toggling operations that
/// affects the entire board.
///
/// @note Invoking this method does not change the current scoring values. The
/// client needs to separately invoke calculateWaitUntilDone:() to get the
/// updated score.
///
/// @note This method does nothing if territory scoring is not enabled on this
/// GoScore object, or if a scoring operation is already in progress.
// -----------------------------------------------------------------------------
- (void) toggleDeadStoneStateOfGroup:(GoBoardRegion*)stoneGroup
{
  if (! territoryScoresAvailable)
    return;
  if (scoringInProgress)
    return;
  if (! [stoneGroup isStoneGroup])
    return;

  bool markDeadStonesIntelligently = [ApplicationDelegate sharedDelegate].scoringModel.markDeadStonesIntelligently;

  // We use this array like a queue: We add GoBoardRegion objects to it that
  // need to be toggled, and we loop until the queue is empty. In each iteration
  // new GoBoardRegion objects may be added to the queue which will cause the
  // loop to run longer.
  NSMutableArray* stoneGroupsToToggle = [NSMutableArray arrayWithCapacity:0];
  // And this array is the guard that prevents an infinite loop: Whenever a
  // GoBoardRegion object is processed by the loop, it puts the processed object
  // into this array. Before the loop starts processing a GoBoardRegion object,
  // though, it looks into the array to see if the object has already been
  // processed in an earlier iteration.
  NSMutableArray* regionsAlreadyProcessed = [NSMutableArray arrayWithCapacity:0];

  [stoneGroupsToToggle addObject:stoneGroup];
  [regionsAlreadyProcessed addObject:stoneGroup];
  while (stoneGroupsToToggle.count > 0)
  {
    GoBoardRegion* stoneGroupToToggle = [stoneGroupsToToggle objectAtIndex:0];
    [stoneGroupsToToggle removeObjectAtIndex:0];

    bool newDeadState = ! stoneGroupToToggle.deadStoneGroup;
    stoneGroupToToggle.deadStoneGroup = newDeadState;
    enum GoColor colorOfStoneGroupToToggle = [stoneGroupToToggle color];

    // If the user has decided that he does not need any help with toggling,
    // we can abort the whole process now
    if (! markDeadStonesIntelligently)
      break;

    // Collect stone groups that are either directly adjacent to the stone
    // group we just toggled ("once removed"), or separated from it by an
    // intermediate empty region ("twice removed").
    NSMutableArray* adjacentStoneGroupsToExamine = [NSMutableArray arrayWithCapacity:0];
    for (GoBoardRegion* adjacentRegionOnceRemoved in [stoneGroupToToggle adjacentRegions])
    {
      if ([regionsAlreadyProcessed containsObject:adjacentRegionOnceRemoved])
        continue;
      [regionsAlreadyProcessed addObject:adjacentRegionOnceRemoved];
      if ([adjacentRegionOnceRemoved color] != GoColorNone)
        [adjacentStoneGroupsToExamine addObject:adjacentRegionOnceRemoved];
      else
      {
        for (GoBoardRegion* adjacentRegionTwiceRemoved in [adjacentRegionOnceRemoved adjacentRegions])
        {
          if ([regionsAlreadyProcessed containsObject:adjacentRegionTwiceRemoved])
            continue;
          [regionsAlreadyProcessed addObject:adjacentRegionTwiceRemoved];
          if ([adjacentRegionTwiceRemoved color] == GoColorNone)
            assert(0);  // inconsistency! regions adjacent to an empty region cannot be empty, too
          else
            [adjacentStoneGroupsToExamine addObject:adjacentRegionTwiceRemoved];
        }
      }
    }

    // Now examine the collected stone groups and, if necessary, toggle their
    // dead/alive state:
    // - Stone groups of the same color need to get into the same state
    // - Stone groups of the opposing color need to get into the opposite
    //   state
    // See the "Guidelines" section in the class documentation for details.
    for (GoBoardRegion* adjacentStoneGroupToExamine in adjacentStoneGroupsToExamine)
    {
      if (! [adjacentStoneGroupToExamine isStoneGroup])
      {
        assert(0);  // error in loop above, we should have collected only stone groups
        continue;
      }
      enum GoColor colorOfAdjacentStoneGroupToExamine = [adjacentStoneGroupToExamine color];
      if (colorOfAdjacentStoneGroupToExamine == colorOfStoneGroupToToggle)
      {
        if (adjacentStoneGroupToExamine.deadStoneGroup != newDeadState)
          [stoneGroupsToToggle addObject:adjacentStoneGroupToExamine];
      }
      else
      {
        // TODO Decide what we should do with this disabled code and update the
        // class documentation.
//        if (adjacentStoneGroupToExamine.deadStoneGroup == newDeadState)
//          [stoneGroupsToToggle addObject:adjacentStoneGroupToExamine];
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief (Re)Calculates the territory color of all GoBoardRegion objects.
/// Returns true if calculation was successful, false if not.
///
/// This method requires that the @e deadStoneGroup property of GoBoardRegion
/// objects is correct and up-to-date.
///
/// Initial dead stones are set up by initializeBoard(). User interaction during
/// scoring invokes toggleDeadStoneStateOfGroup:() to add more dead stones, or
/// turn them back to alive.
// -----------------------------------------------------------------------------
- (bool) updateTerritoryColor
{
  // Regions that are truly empty, i.e. that do not have dead stones
  NSMutableArray* emptyRegions = [NSMutableArray arrayWithCapacity:0];

  // Pass 1: Set territory colors for stone groups. This is easy and can be
  // done both for groups that are alive and dead. While we are at it, we can
  // also collect empty regions, which will be processed in pass 2.
  for (GoBoardRegion* region in self.allRegions)
  {
    if (! [region isStoneGroup])
    {
      // Setting territory color here is temporary, the final color will be
      // determined in pass 2. We still need to do it, though, to erase traces
      // from a previous scoring calculation.
      region.territoryColor = GoColorNone;
      [emptyRegions addObject:region];
    }
    else
    {
      // If the group is alive, it belongs to the territory of the color who
      // played the stones in the group. This is important only for area
      // scoring.
      if (! region.deadStoneGroup)
        region.territoryColor = [region color];
      // If the group is dead, it belongs to the territory of the opposing color
      else
      {
        switch ([region color])
        {
          case GoColorBlack:
            region.territoryColor = GoColorWhite;
            break;
          case GoColorWhite:
            region.territoryColor = GoColorBlack;
            break;
          default:
            return false;  // error! stone groups must be either black or white
        }
      }
    }
  }

  // Pass 2: Process empty regions. Here we examine the stone groups adjacent
  // to each empty region to determine the empty region's final territory color.
  // The rules are explained in detail in the class documentation in the
  /// "Guidelines" section.
  for (GoBoardRegion* emptyRegion in emptyRegions)
  {
    bool aliveSeen = false;
    bool blackAliveSeen = false;
    bool whiteAliveSeen = false;
    bool deadSeen = false;
    bool blackDeadSeen = false;
    bool whiteDeadSeen = false;
    for (GoBoardRegion* adjacentRegion in [emptyRegion adjacentRegions])
    {
      if (! [adjacentRegion isStoneGroup])
        return false;  // error! regions adjacent to an empty region can only be stone groups
      if (adjacentRegion.deadStoneGroup)
      {
        deadSeen = true;
        switch ([adjacentRegion color])
        {
          case GoColorBlack:
            blackDeadSeen = true;
            break;
          case GoColorWhite:
            whiteDeadSeen = true;
            break;
          default:
            return false;  // error! stone group must be either black or white
        }
      }
      else
      {
        aliveSeen = true;
        switch ([adjacentRegion color])
        {
          case GoColorBlack:
            blackAliveSeen = true;
            break;
          case GoColorWhite:
            whiteAliveSeen = true;
            break;
          default:
            return false;  // error! stone group must be either black or white
        }
      }
    }

    bool territoryInconsistencyFound = false;
    enum GoColor territoryColor = GoColorNone;
    if (! deadSeen)
    {
      if (! aliveSeen)  // ok, empty board
        territoryColor = GoColorNone;
      else
      {
        if (blackAliveSeen && whiteAliveSeen)  // ok, neutral territory
          territoryColor = GoColorNone;
        else  // ok, only one color has been seen, and all groups were alive
        {
          if (blackAliveSeen)
            territoryColor = GoColorBlack;
          else
            territoryColor = GoColorWhite;
        }
      }
    }
    else
    {
      if (blackDeadSeen)
      {
        if (blackAliveSeen)  // rules violation! cannot see both dead and alive stones of the same color
          territoryInconsistencyFound = true;
        else if (whiteDeadSeen)  // rules violation! cannot see dead stones of both colors
          territoryInconsistencyFound = true;
        else                     // ok, only dead stones of one color seen (we don't care whether the opposing color has alive stones)
          territoryColor = GoColorWhite;
      }
      else  // repeat of the block above, but for the opposing color
      {
        if (whiteAliveSeen)
          territoryInconsistencyFound = true;
        else if (blackDeadSeen)
          territoryInconsistencyFound = true;
        else
          territoryColor = GoColorBlack;
      }
    }

    emptyRegion.territoryColor = territoryColor;
    emptyRegion.territoryInconsistencyFound = territoryInconsistencyFound;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief (Re)Calculates the scoring and move statistics properties of this
/// GoScore object.
///
/// If territory scoring is enabled, this method requires that the
/// @e deadStoneGroup and @e territoryColor properties of GoBoardRegion objects
/// are correct and up-to-date.
// -----------------------------------------------------------------------------
- (void) updateScoringProperties
{
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

  // Territory & dead stones
  if (territoryScoresAvailable)
  {
    for (GoBoardRegion* region in self.allRegions)
    {
      int regionSize = [region size];
      // Territory: We only count dead stones and empty intersections
      if (region.deadStoneGroup || ! [region isStoneGroup])
      {
        switch (region.territoryColor)
        {
          case GoColorBlack:
            territoryBlack += regionSize;
            break;
          case GoColorWhite:
            territoryWhite += regionSize;
            break;
          default:
            break;
        }
      }

      // Dead stones
      if (region.deadStoneGroup)
      {
        switch ([region color])
        {
          case GoColorBlack:
            deadBlack += regionSize;
            break;
          case GoColorWhite:
            deadWhite += regionSize;
            break;
          default:
            break;
        }
      }
    }
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

@end
