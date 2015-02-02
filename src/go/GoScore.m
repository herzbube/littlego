// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoBoardPosition.h"
#import "GoBoardRegion.h"
#import "GoGame.h"
#import "GoGameRules.h"
#import "GoMove.h"
#import "GoPlayer.h"
#import "GoPoint.h"
#import "../main/ApplicationDelegate.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"
#import "../utility/NSStringAdditions.h"
#import "../play/model/ScoringModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoScore.
// -----------------------------------------------------------------------------
@interface GoScore()
@property(nonatomic, assign) GoGame* game;
@property(nonatomic, retain) NSOperationQueue* operationQueue;
@property(nonatomic, assign) bool didAskGtpEngineForDeadStones;
@property(nonatomic, assign) bool lastCalculationHadError;
@end


@implementation GoScore

// -----------------------------------------------------------------------------
/// @brief Initializes a GoScore object that operates on @a game.
///
/// @note This is the designated initializer of GoScore.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)game
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  _scoringEnabled = false;                       // don't use self to avoid triggering a notification
  _scoringInProgress = false;                    // ditto
  _askGtpEngineForDeadStonesInProgress = false;  // ditto
  _game = game;
  _operationQueue = [[NSOperationQueue alloc] init];
  _didAskGtpEngineForDeadStones = false;
  _lastCalculationHadError = false;
  [self resetValues];

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
  _scoringEnabled = [decoder decodeBoolForKey:goScoreScoringEnabledKey];
  _komi = [decoder decodeDoubleForKey:goScoreKomiKey];
  _capturedByBlack = [decoder decodeIntForKey:goScoreCapturedByBlackKey];
  _capturedByWhite = [decoder decodeIntForKey:goScoreCapturedByWhiteKey];
  _deadBlack = [decoder decodeIntForKey:goScoreDeadBlackKey];
  _deadWhite = [decoder decodeIntForKey:goScoreDeadWhiteKey];
  _territoryBlack = [decoder decodeIntForKey:goScoreTerritoryBlackKey];
  _territoryWhite = [decoder decodeIntForKey:goScoreTerritoryWhiteKey];
  _aliveBlack = [decoder decodeIntForKey:goScoreAliveBlackKey];
  _aliveWhite = [decoder decodeIntForKey:goScoreAliveWhiteKey];
  _handicapCompensationBlack = [decoder decodeDoubleForKey:goScoreHandicapCompensationBlackKey];
  _handicapCompensationWhite = [decoder decodeDoubleForKey:goScoreHandicapCompensationWhiteKey];
  _totalScoreBlack = [decoder decodeDoubleForKey:goScoreTotalScoreBlackKey];
  _totalScoreWhite = [decoder decodeDoubleForKey:goScoreTotalScoreWhiteKey];
  _result = [decoder decodeIntForKey:goScoreResultKey];
  _numberOfMoves = [decoder decodeIntForKey:goScoreNumberOfMovesKey];
  _stonesPlayedByBlack = [decoder decodeIntForKey:goScoreStonesPlayedByBlackKey];
  _stonesPlayedByWhite = [decoder decodeIntForKey:goScoreStonesPlayedByWhiteKey];
  _passesPlayedByBlack = [decoder decodeIntForKey:goScorePassesPlayedByBlackKey];
  _passesPlayedByWhite = [decoder decodeIntForKey:goScorePassesPlayedByWhiteKey];
  _game = [decoder decodeObjectForKey:goScoreGameKey];
  _didAskGtpEngineForDeadStones = [decoder decodeBoolForKey:goScoreDidAskGtpEngineForDeadStonesKey];
  _lastCalculationHadError = [decoder decodeBoolForKey:goScoreLastCalculationHadErrorKey];

  // If we wanted to restore the two "in progress" states we would need to
  // handle the case where one or both of the states is actually true, i.e. we
  // would have to continue the scoring calculation exactly at the point where
  // it was interrupted. Since we can't do this, there is no point in
  // saving/restoring the two "in progress" states.
  _scoringInProgress = false;
  _askGtpEngineForDeadStonesInProgress = false;
  _operationQueue = [[NSOperationQueue alloc] init];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoScore object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.operationQueue = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Resets all score values to zero. Typically invoked before a new
/// calculation starts.
// -----------------------------------------------------------------------------
- (void) resetValues
{
  self.komi = 0;
  self.capturedByBlack = 0;
  self.capturedByWhite = 0;
  self.deadBlack = 0;
  self.deadWhite = 0;
  self.territoryBlack = 0;
  self.territoryWhite = 0;
  self.aliveBlack = 0;
  self.aliveWhite = 0;
  self.handicapCompensationBlack = 0;
  self.handicapCompensationWhite = 0;
  self.totalScoreBlack = 0;
  self.totalScoreWhite = 0;
  self.result = GoGameResultNone;
  self.numberOfMoves = 0;
  self.stonesPlayedByBlack = 0;
  self.stonesPlayedByWhite = 0;
  self.passesPlayedByBlack = 0;
  self.passesPlayedByWhite = 0;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setScoringEnabled:(bool)newState
{
  if (_scoringEnabled == newState)
    return;
  _scoringEnabled = newState;
  if (newState)
  {
    [self initializeRegions];
    self.didAskGtpEngineForDeadStones = false;
  }
  else
  {
    [self uninitializeRegions];
  }
  [self postScoringModeNotification];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setScoringEnabled.
// -----------------------------------------------------------------------------
- (void) initializeRegions
{
  NSArray* allRegions = self.game.board.regions;
  DDLogVerbose(@"%@: initializing GoBoardRegion objects, number of regions = %lu", self, (unsigned long)allRegions.count);
  for (GoBoardRegion* region in allRegions)
  {
    region.territoryColor = GoColorNone;
    region.territoryInconsistencyFound = false;
    if (region.isStoneGroup)
      region.stoneGroupState = GoStoneGroupStateAlive;
    else
      region.stoneGroupState = GoStoneGroupStateUndefined;
    region.scoringMode = true;  // enabling scoring mode allows caching for optimized performance
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setScoringEnabled.
// -----------------------------------------------------------------------------
- (void) uninitializeRegions
{
  NSArray* allRegions = self.game.board.regions;
  DDLogVerbose(@"%@: uninitializing GoBoardRegion objects, number of regions = %lu", self, (unsigned long)allRegions.count);
  for (GoBoardRegion* region in allRegions)
    region.scoringMode = false;  // forget cached values
}

// -----------------------------------------------------------------------------
/// @brief Notifies this GoScore that the board position is about to be changed.
/// Invocation of this method must be balanced by also invoking
/// didChangeBoardPosition.
///
/// If scoring is currently enabled, this GoScore temporarily un-initializes
/// GoGame and its associated objects so that the scoring mode does not
/// interfere with the board position change.
// -----------------------------------------------------------------------------
- (void) willChangeBoardPosition
{
  if (! self.scoringEnabled)
    return;
  [self uninitializeRegions];
}

// -----------------------------------------------------------------------------
/// @brief Notifies this GoScore that a board position change has been
/// completed. This method must be invoked to balance a previous invocation of
/// willChangeBoardPosition.
///
/// If scoring is currently enabled, this GoScore re-initializes GoGame and its
/// associated objects for scoring mode so that a new score can be calculated
/// for the new board position.
// -----------------------------------------------------------------------------
- (void) didChangeBoardPosition
{
  if (! self.scoringEnabled)
    return;
  [self initializeRegions];
  self.didAskGtpEngineForDeadStones = false;
}

// -----------------------------------------------------------------------------
/// @brief Starts calculation of a new score.
///
/// If @a waitUntilDone is false, this method returns immediately and does not
/// wait for the calculation to finish.
///
/// Observers are notified of the start and end of the calculation by the
/// notifications #goScoreCalculationStarts and #goScoreCalculationStarts which
/// are posted on the application's default NSNotificationCentre in the context
/// of the main thread.
///
/// @note This method does nothing if a scoring operation is already in
/// progress.
// -----------------------------------------------------------------------------
- (void) calculateWaitUntilDone:(bool)waitUntilDone
{
  DDLogVerbose(@"%@: calculateWaitUntilDone invoked; waitUntilDone = %d, scoringInProgress = %d, game = %@",
               self,
               waitUntilDone,
               self.scoringInProgress,
               self.game);
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
    self.lastCalculationHadError = false;
    [self resetValues];

    if (self.scoringEnabled)
    {
      [self askGtpEngineForDeadStones];
      bool success = [self updateTerritoryColor];
      DDLogVerbose(@"%@: updateTerritoryColor returned with result = %d", self, success);
      if (! success)
      {
        self.lastCalculationHadError = true;
        return;
      }
    }

    [self updateScoringProperties];
  }
  @finally
  {
    self.scoringInProgress = false;
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setScoringInProgress:(bool)newValue
{
  if (_scoringInProgress == newValue)
    return;
  _scoringInProgress = newValue;
  [self postScoringInProgressNotification];
}

// -----------------------------------------------------------------------------
/// @brief Returns a nicely formatted string that reflects the overall result
/// of the current scoring information. The string can be displayed to the user.
// -----------------------------------------------------------------------------
- (NSString*) resultString
{
  if (self.lastCalculationHadError)
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
      DDLogError(@"%@: Unexpected GoGameResult value %d", self, self.result);
      assert(0);
      break;
    }
  }
  return @"Unknown game result";
}

// -----------------------------------------------------------------------------
/// @brief Queries the GTP engine for an initial set of dead stones. Updates
/// GoBoardRegion objects with the result of the query.
// -----------------------------------------------------------------------------
- (void) askGtpEngineForDeadStones
{
  if (! [ApplicationDelegate sharedDelegate].scoringModel.askGtpEngineForDeadStones)
    return;
  if (self.didAskGtpEngineForDeadStones)
    return;
  self.didAskGtpEngineForDeadStones = true;

  @try
  {
    self.askGtpEngineForDeadStonesInProgress = true;
    [self performSelector:@selector(postNotificationOnMainThread:)
                 onThread:[NSThread mainThread]
               withObject:askGtpEngineForDeadStonesStarts
            waitUntilDone:YES];
    GtpCommand* command = [GtpCommand command:@"final_status_list dead"];
    [command submit];
    if (command.response.status)
    {
      NSArray* deadStoneVertexList = [self parseDeadStoneGtpResponse:command.response.parsedResponse];
      for (NSString* vertex in deadStoneVertexList)
      {
        GoPoint* point = [self.game.board pointAtVertex:vertex];
        if (! [point hasStone])
        {
          DDLogError(@"%@: GTP engine reports vertex %@ is dead stone, but point %@ has no stone", self, vertex, point);
          assert(0);
          continue;
        }
        // TODO The next statement is problematic in two respects: 1) If the
        // region has more than one point, we repeatedly set it to be dead,
        // once for each vertex reported by the GTP engine. 2) We don't perform
        // any kind of check if the vertex list reported by the GTP engine
        // matches our regions.
        point.region.stoneGroupState = GoStoneGroupStateDead;
      }
    }
    else
    {
      DDLogError(@"%@: Querying GTP engine for initial set of dead stones failed", self);
      assert(0);
    }
  }
  @finally
  {
    self.askGtpEngineForDeadStonesInProgress = false;
    [self performSelector:@selector(postNotificationOnMainThread:)
                 onThread:[NSThread mainThread]
               withObject:askGtpEngineForDeadStonesEnds
            waitUntilDone:YES];
  }
}

// -----------------------------------------------------------------------------
/// @brief Posts either #goScoreScoringEnabled or #goScoreScoringDisabled to the
/// global notification center, depending on whether scoring mode is currently
/// enabled or disabled.
///
/// This method is part of the public API. It must not do anything else except
/// posting the notification.
// -----------------------------------------------------------------------------
- (void) postScoringModeNotification
{
  NSString* notificationName;
  if (self.scoringEnabled)
    notificationName = goScoreScoringEnabled;
  else
    notificationName = goScoreScoringDisabled;
  // When a new game is started, scoring mode of the old game is disabled first.
  // Because the process of starting a new game may run in a seconary thread,
  // we must use waitUntilDone:YES here to guarantee that GoScoreScoringDisabled
  // is delivered before the old game - and with it this GoScore object - are
  // deallocated. In fact, we must guarantee that postNotificationOnMainThread:
  // is invoked ***NOW***, otherwise this GoScore object may have been
  // deallocated by the time the runtime is ready to execute the selector.
  [self performSelector:@selector(postNotificationOnMainThread:)
               onThread:[NSThread mainThread]
             withObject:notificationName
          waitUntilDone:YES];
}

// -----------------------------------------------------------------------------
/// @brief Posts either #goScoreCalculationStarts or #goScoreCalculationEnds to
/// the global notification center, depending on whether a scoring operation is
/// currently in progress.
///
/// This method is part of the public API. It must not do anything else except
/// posting the notification.
// -----------------------------------------------------------------------------
- (void) postScoringInProgressNotification
{
  NSString* notificationName;
  if (self.scoringInProgress)
    notificationName = goScoreCalculationStarts;
  else
    notificationName = goScoreCalculationEnds;
  [self performSelector:@selector(postNotificationOnMainThread:)
               onThread:[NSThread mainThread]
             withObject:notificationName
          waitUntilDone:YES];
}

// -----------------------------------------------------------------------------
/// @brief Private helper. Is invoked in the context of the main thread.
// -----------------------------------------------------------------------------
- (void) postNotificationOnMainThread:(NSString*)notificationName
{
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
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
/// dead, or vice versa. If @a stoneGroup is in seki, its status is changed to
/// dead.
///
/// Once the main stone group @a stoneGroup has been updated, this method also
/// considers neighbouring regions and, if necessary, toggles the dead/alive
/// state of other stone groups to remain consistent with the logic of the game
/// rules. This feature is optional and the user can turn it off in the user
/// preferences. For details read the class documentation, section "Mark dead
/// stones intelligently".
///
/// @note Invoking this method does not change the current scoring values. The
/// client needs to separately invoke calculateWaitUntilDone:() to get the
/// updated score.
///
/// @note This method does nothing if scoring is not enabled on this GoScore
/// object, or if a scoring operation is already in progress.
// -----------------------------------------------------------------------------
- (void) toggleDeadStateOfStoneGroup:(GoBoardRegion*)stoneGroup
{
  if (! self.scoringEnabled)
    return;
  if (self.scoringInProgress)
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

    enum GoStoneGroupState newStoneGroupState;
    switch (stoneGroupToToggle.stoneGroupState)
    {
      case GoStoneGroupStateAlive:
        newStoneGroupState = GoStoneGroupStateDead;
        break;
      case GoStoneGroupStateDead:
        newStoneGroupState = GoStoneGroupStateAlive;
        break;
      case GoStoneGroupStateSeki:
        newStoneGroupState = GoStoneGroupStateDead;
        break;
      default:
        DDLogError(@"%@: Unknown stone group state = %d", self, stoneGroupToToggle.stoneGroupState);
        assert(0);
        continue;
    }
    stoneGroupToToggle.stoneGroupState = newStoneGroupState;
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
          {
            DDLogError(@"%@: Inconsistency - regions adjacent to an empty region cannot be empty, too, adjacent empty region = %@", self, adjacentRegionTwiceRemoved);
            assert(0);
          }
          else
            [adjacentStoneGroupsToExamine addObject:adjacentRegionTwiceRemoved];
        }
      }
    }

    // Now examine the collected stone groups and, if necessary, toggle their
    // dead/alive state:
    // - Stone groups of the same color need to get into the same state
    // - In theory, stone groups of the opposing color need to get into the
    //   opposite state, but doing this has too much effect, so for the moment
    //   we ignore the opposing color
    // See the "Mark dead stones intelligently" section in the class
    // documentation for details.
    for (GoBoardRegion* adjacentStoneGroupToExamine in adjacentStoneGroupsToExamine)
    {
      if (! [adjacentStoneGroupToExamine isStoneGroup])
      {
        DDLogError(@"%@: Error in previous loop, we should have collected only stone groups, adjacent empty region = %@", self, adjacentStoneGroupToExamine);
        assert(0);
        continue;
      }
      enum GoColor colorOfAdjacentStoneGroupToExamine = [adjacentStoneGroupToExamine color];
      if (colorOfAdjacentStoneGroupToExamine == colorOfStoneGroupToToggle)
      {
        if (adjacentStoneGroupToExamine.stoneGroupState != newStoneGroupState)
          [stoneGroupsToToggle addObject:adjacentStoneGroupToExamine];
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Toggles the status of the stone group @a stoneGroup from seki to
/// alive, or vice versa. If @a stoneGroup is dead, its status is changed to
/// in seki.
// -----------------------------------------------------------------------------
- (void) toggleSekiStateOfStoneGroup:(GoBoardRegion*)stoneGroup
{
  if (! self.scoringEnabled)
    return;
  if (self.scoringInProgress)
    return;
  if (! [stoneGroup isStoneGroup])
    return;
  enum GoStoneGroupState newStoneGroupState;
  switch (stoneGroup.stoneGroupState)
  {
    case GoStoneGroupStateAlive:
      newStoneGroupState = GoStoneGroupStateSeki;
      break;
    case GoStoneGroupStateDead:
      newStoneGroupState = GoStoneGroupStateSeki;
      break;
    case GoStoneGroupStateSeki:
      newStoneGroupState = GoStoneGroupStateAlive;
      break;
    default:
      DDLogError(@"%@: Unknown stone group state = %d", self, stoneGroup.stoneGroupState);
      assert(0);
      return;
  }
  stoneGroup.stoneGroupState = newStoneGroupState;
}

// -----------------------------------------------------------------------------
/// @brief (Re)Calculates the territory color of all GoBoardRegion objects.
/// Returns true if calculation was successful, false if not.
///
/// This method looks at the @e stoneGroupState property of GoBoardRegion
/// objects. For details see the class documentation, paragraph "Determining
/// territory color".
///
/// Initial dead stones are set up by askGtpEngineForDeadStones(). User
/// interaction during scoring invokes toggleDeadStateOfStoneGroup:() to add
/// more dead stones, or turn them back to alive.
// -----------------------------------------------------------------------------
- (bool) updateTerritoryColor
{
  // Preliminary sanity check. The fact that only two scoring systems can occur
  // makes some of the logic further down a lot simpler.
  enum GoScoringSystem scoringSystem = self.game.rules.scoringSystem;
  if (GoScoringSystemAreaScoring != scoringSystem &&
      GoScoringSystemTerritoryScoring != scoringSystem)
  {
    DDLogError(@"%@: Unknown scoring system = %d", self, scoringSystem);
    return false;
  }

  // Regions that are truly empty, i.e. that do not have dead stones
  NSMutableArray* emptyRegions = [NSMutableArray arrayWithCapacity:0];

  // Pass 1: Set territory colors for stone groups. This is easy and can be
  // done both for groups that are alive and dead. While we are at it, we can
  // also collect empty regions, which will be processed in pass 2.
  NSArray* allRegions = self.game.board.regions;
  for (GoBoardRegion* region in allRegions)
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
      switch (region.stoneGroupState)
      {
        case GoStoneGroupStateAlive:
        {
          // If the group is alive, it belongs to the territory of the color who
          // played the stones in the group. This is important only for area
          // scoring.
          region.territoryColor = [region color];
          break;
        }
        case GoStoneGroupStateDead:
        {
          // If the group is dead, it belongs to the territory of the opposing
          // color
          switch ([region color])
          {
            case GoColorBlack:
              region.territoryColor = GoColorWhite;
              break;
            case GoColorWhite:
              region.territoryColor = GoColorBlack;
              break;
            default:
              DDLogError(@"%@: Stone groups must be either black or white, region %@ has color %d", self, region, [region color]);
              return false;
          }
          break;
        }
        case GoStoneGroupStateSeki:
        {
          // If the group is in seki, the scoring system decides the territory
          // that the group belongs to
          if (GoScoringSystemAreaScoring == scoringSystem)
            region.territoryColor = [region color];
          else
            region.territoryColor = GoColorNone;
          break;
        }
        default:
        {
          DDLogError(@"%@: Unknown stone group state = %d", self, region.stoneGroupState);
          return false;
        }
      }
    }
  }

  // Pass 2: Process empty regions. Here we examine the stone groups adjacent
  // to each empty region to determine the empty region's final territory color.
  for (GoBoardRegion* emptyRegion in emptyRegions)
  {
    bool aliveSeen = false;
    bool blackAliveSeen = false;
    bool whiteAliveSeen = false;
    bool deadSeen = false;
    bool blackDeadSeen = false;
    bool whiteDeadSeen = false;
    bool sekiSeen = false;
    bool blackSekiSeen = false;
    bool whiteSekiSeen = false;
    for (GoBoardRegion* adjacentRegion in [emptyRegion adjacentRegions])
    {
      if (! [adjacentRegion isStoneGroup])
      {
        DDLogError(@"%@: Regions adjacent to an empty region can only be stone groups, adjacent region = %@", self, adjacentRegion);
        return false;
      }

      // Preliminary sanity check. The fact that only two colors can occur makes
      // the subsequent logic simpler.
      enum GoColor adjacentRegionColor = [adjacentRegion color];
      if (GoColorBlack != adjacentRegionColor && GoColorWhite != adjacentRegionColor)
      {
        DDLogError(@"%@: Stone groups must be either black or white, adjacent stone group region %@ has color %d", self, adjacentRegion, adjacentRegionColor);
        return false;
      }

      switch (adjacentRegion.stoneGroupState)
      {
        case GoStoneGroupStateAlive:
        {
          aliveSeen = true;
          if (GoColorBlack == adjacentRegionColor)
            blackAliveSeen = true;
          else
            whiteAliveSeen = true;
          break;
        }
        case GoStoneGroupStateDead:
        {
          deadSeen = true;
          if (GoColorBlack == adjacentRegionColor)
            blackDeadSeen = true;
          else
            whiteDeadSeen = true;
          break;
        }
        case GoStoneGroupStateSeki:
        {
          sekiSeen = true;
          if (GoColorBlack == adjacentRegionColor)
            blackSekiSeen = true;
          else
            whiteSekiSeen = true;
          break;
        }
        default:
        {
          DDLogError(@"%@: Unknown stone group state = %d", self, adjacentRegion.stoneGroupState);
          return false;
        }
      }
    }

    bool territoryInconsistencyFound = false;
    enum GoColor territoryColor = GoColorNone;
    if (! deadSeen)
    {
      if (! aliveSeen && ! sekiSeen)
      {
        // Ok, empty board, neutral territory
        territoryColor = GoColorNone;
      }
      else if ((blackSekiSeen && blackAliveSeen) || (whiteSekiSeen && whiteAliveSeen))
      {
        // Rules violation! Cannot see alive and seki stones of the same
        // color. In such a position, the seki stones could, theoretically,
        // be connected to the alive stones. The opposing player therefore
        // MUST play so that no connection is possible and this position
        // cannot occur.
        territoryInconsistencyFound = true;
      }
      else if ((blackSekiSeen && whiteAliveSeen) || (whiteSekiSeen && blackAliveSeen))
      {
        // Rules violation! Cannot see alive and seki stones of different
        // colors. In all seki positions and examples that I could find,
        // seki stones are always completely surrounded, the only liberties
        // being their own eyes, or liberties shared with seki stones of
        // the other color. The opposing player therefore MUST play and fill
        // in all liberties around the seki stones.
        territoryInconsistencyFound = true;
      }
      else if ((blackSekiSeen && whiteSekiSeen) || (blackAliveSeen && whiteAliveSeen))
      {
        // Ok, dame, neutral territory
        territoryColor = GoColorNone;
      }
      else if (sekiSeen)
      {
        // Ok, only one color has been seen, and all groups were in seki
        if (GoScoringSystemAreaScoring == scoringSystem)
        {
          // Area scoring counts this as territory
          if (blackSekiSeen)
            territoryColor = GoColorBlack;
          else
            territoryColor = GoColorWhite;
        }
        else
        {
          // Territory scoring counts this as neutral territory
          territoryColor = GoColorNone;
        }
      }
      else
      {
        // Ok, only one color has been seen, and all groups were alive
        if (blackAliveSeen)
          territoryColor = GoColorBlack;
        else
          territoryColor = GoColorWhite;
      }
    }
    else
    {
      if (sekiSeen)
      {
        // Rules violation! Cannot see dead and seki stones at the same time
        territoryInconsistencyFound = true;
      }
      else if (blackDeadSeen && whiteDeadSeen)
      {
        // Rules violation! Cannot see dead stones of both colors
        territoryInconsistencyFound = true;
      }
      else if ((blackDeadSeen && blackAliveSeen) || (whiteDeadSeen && whiteAliveSeen))
      {
        // Rules violation! Cannot see both dead and alive stones of the same
        // color
        territoryInconsistencyFound = true;
      }
      else
      {
        // Ok, only dead stones of one color seen (we don't care whether the
        // opposing color has alive stones)
        if (blackDeadSeen)
          territoryColor = GoColorWhite;
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
  self.komi = self.game.komi;

  // Captured stones (up to the current board position) and move statistics (for
  // the entire game)
  self.numberOfMoves = 0;
  GoMove* currentBoardPositionMove = self.game.boardPosition.currentMove;
  bool loopHasPassedCurrentBoardPosition = false;
  GoMove* move = self.game.lastMove;
  while (move != nil)
  {
    if (! loopHasPassedCurrentBoardPosition)
    {
      if (move == currentBoardPositionMove)
        loopHasPassedCurrentBoardPosition = true;
    }

    self.numberOfMoves++;
    bool moveByBlack = move.player.black;
    switch (move.type)
    {
      case GoMoveTypePlay:
      {
        if (moveByBlack)
        {
          if (loopHasPassedCurrentBoardPosition)
          {
            // Cast is required because NSUInteger and int differ in size in
            // 64-bit. Cast is safe because the number of captured stones can
            // never exceed pow(2, 32).
            self.capturedByBlack += (int)move.capturedStones.count;
          }
          self.stonesPlayedByBlack++;
        }
        else
        {
          if (loopHasPassedCurrentBoardPosition)
          {
            // Cast is required because NSUInteger and int differ in size in
            // 64-bit. Cast is safe because the number of captured stones can
            // never exceed pow(2, 32).
            self.capturedByWhite += (int)move.capturedStones.count;
          }
          self.stonesPlayedByWhite++;
        }
        break;
      }
      case GoMoveTypePass:
      {
        if (moveByBlack)
          self.passesPlayedByBlack++;
        else
          self.passesPlayedByWhite++;
        break;
      }
      default:
        break;
    }
    move = move.previous;
  }

  // Area, territory & dead stones (for current board position)
  if (self.scoringEnabled)
  {
    NSArray* allRegions = self.game.board.regions;
    for (GoBoardRegion* region in allRegions)
    {
      int regionSize = [region size];
      bool regionIsStoneGroup = [region isStoneGroup];
      enum GoStoneGroupState stoneGroupState = region.stoneGroupState;
      bool regionIsDeadStoneGroup = (GoStoneGroupStateDead == stoneGroupState);
      enum GoColor regionTerritoryColor = region.territoryColor;

      // Territory: We count dead stones and intersections in empty regions. An
      // empty region could be an eye in seki, which only counts when area
      // scoring is in effect. We don't have to check the scoring system,
      // though, this was already done when the empty region's territory color
      // was determined.
      if (regionIsDeadStoneGroup || ! regionIsStoneGroup)
      {
        switch (regionTerritoryColor)
        {
          case GoColorBlack:
            self.territoryBlack += regionSize;
            break;
          case GoColorWhite:
            self.territoryWhite += regionSize;
            break;
          default:
            break;
        }
      }

      // Alive stones + stones in seki
      if (regionIsStoneGroup && ! regionIsDeadStoneGroup)
      {
        switch (regionTerritoryColor)
        {
          case GoColorBlack:
            self.aliveBlack += regionSize;
            break;
          case GoColorWhite:
            self.aliveWhite += regionSize;
            break;
          default:
            break;
        }
      }

      // Dead stones
      if (regionIsDeadStoneGroup)
      {
        switch ([region color])
        {
          case GoColorBlack:
            self.deadBlack += regionSize;
            break;
          case GoColorWhite:
            self.deadWhite += regionSize;
            break;
          default:
            break;
        }
      }
    }
  }

  // Handicap
  // Cast is required because NSUInteger and int differ in size in 64-bit.
  // Cast is safe because the number of handicap stones never exceeds
  // pow(2, 31).
  int numberOfHandicapStones = (int)self.game.handicapPoints.count;
  if (numberOfHandicapStones > 0)
  {
    self.handicapCompensationWhite = numberOfHandicapStones;
  }

  // Total score
  switch (self.game.rules.scoringSystem)
  {
    case GoScoringSystemAreaScoring:
    {
      self.totalScoreBlack = self.aliveBlack + self.territoryBlack + self.handicapCompensationBlack;
      self.totalScoreWhite = self.komi + self.aliveWhite + self.territoryWhite + self.handicapCompensationWhite;
      break;
    }
    case GoScoringSystemTerritoryScoring:
    {
      self.totalScoreBlack = self.capturedByBlack + self.deadWhite + self.territoryBlack;
      self.totalScoreWhite = self.komi + self.capturedByWhite + self.deadBlack + self.territoryWhite;
      break;
    }
    default:
    {
      break;
    }
  }

  // Final result
  if (self.totalScoreBlack > self.totalScoreWhite)
    self.result = GoGameResultBlackHasWon;
  else if (self.totalScoreWhite > self.totalScoreBlack)
    self.result = GoGameResultWhiteHasWon;
  else
    self.result = GoGameResultTie;
}


// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeBool:self.scoringEnabled forKey:goScoreScoringEnabledKey];
  [encoder encodeDouble:self.komi forKey:goScoreKomiKey];
  [encoder encodeInt:self.capturedByBlack forKey:goScoreCapturedByBlackKey];
  [encoder encodeInt:self.capturedByWhite forKey:goScoreCapturedByWhiteKey];
  [encoder encodeInt:self.deadBlack forKey:goScoreDeadBlackKey];
  [encoder encodeInt:self.deadWhite forKey:goScoreDeadWhiteKey];
  [encoder encodeInt:self.territoryBlack forKey:goScoreTerritoryBlackKey];
  [encoder encodeInt:self.territoryWhite forKey:goScoreTerritoryWhiteKey];
  [encoder encodeInt:self.aliveBlack forKey:goScoreAliveBlackKey];
  [encoder encodeInt:self.aliveWhite forKey:goScoreAliveWhiteKey];
  [encoder encodeDouble:self.handicapCompensationBlack forKey:goScoreHandicapCompensationBlackKey];
  [encoder encodeDouble:self.handicapCompensationWhite forKey:goScoreHandicapCompensationWhiteKey];
  [encoder encodeDouble:self.totalScoreBlack forKey:goScoreTotalScoreBlackKey];
  [encoder encodeDouble:self.totalScoreWhite forKey:goScoreTotalScoreWhiteKey];
  [encoder encodeInt:self.result forKey:goScoreResultKey];
  [encoder encodeInt:self.numberOfMoves forKey:goScoreNumberOfMovesKey];
  [encoder encodeInt:self.stonesPlayedByBlack forKey:goScoreStonesPlayedByBlackKey];
  [encoder encodeInt:self.stonesPlayedByWhite forKey:goScoreStonesPlayedByWhiteKey];
  [encoder encodeInt:self.passesPlayedByBlack forKey:goScorePassesPlayedByBlackKey];
  [encoder encodeInt:self.passesPlayedByWhite forKey:goScorePassesPlayedByWhiteKey];
  [encoder encodeObject:self.game forKey:goScoreGameKey];
  [encoder encodeBool:self.didAskGtpEngineForDeadStones forKey:goScoreDidAskGtpEngineForDeadStonesKey];
  [encoder encodeBool:self.lastCalculationHadError forKey:goScoreLastCalculationHadErrorKey];
}

@end
