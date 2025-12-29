// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoPlayerTimeData.h"
#import "GoClock.h"
#import "GoNode.h"
#import "GoNodeTimeData.h"
#import "GoTimeSettings.h"
#import "GoTimeSystem.h"
#import "GoUtilities.h"
#import "../utility/ExceptionUtility.h"


// TODO xxx Review synchronization, e.g. timer/Fuego/user triggers could overlap
// TODO xxx Add unit tests

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoPlayerTimeData.
// -----------------------------------------------------------------------------
@interface GoPlayerTimeData()
/// @name Private properties
//@{
/// @brief The time settings that provide the parameters for the updating logic.
@property(nonatomic, assign) GoTimeSettings* goTimeSettings;
/// @brief The clock that is used to keep the time for the player.
@property(nonatomic, retain, readwrite) GoClock* goClock;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) bool isTimeDataForBlackPlayer;
@property(nonatomic, assign, readwrite) bool isRemainingTimeAbsoluteTime;
@property(nonatomic, assign, readwrite) double remainingTimeInSeconds;
@property(nonatomic, assign, readwrite) unsigned int remainingNumberOfMoves;
@property(nonatomic, assign, readwrite) unsigned int remainingNumberOfPeriods;
//@}
@end


@implementation GoPlayerTimeData

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoPlayerTimeData object with @a goTimeSettings.
/// @a isTimeDataForBlackPlayer indicates whether the object holds data for the
/// black or the white player. The clock is not running.
///
/// @note This is the designated initializer of GoPlayerTimeData.
// -----------------------------------------------------------------------------
- (id) initWithTimeSettings:(GoTimeSettings*)goTimeSettings
   isTimeDataForBlackPlayer:(bool)isTimeDataForBlackPlayer
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.goTimeSettings = goTimeSettings;
  self.goClock = [[[GoClock alloc] init] autorelease];

  self.isTimeDataForBlackPlayer = isTimeDataForBlackPlayer;

  // Initializes the remaining properties
  [self updateWithTimeSettingsTimeData];

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

  self.goTimeSettings = [decoder decodeObjectOfClass:[GoTimeSettings class] forKey:goPlayerTimeDataTimeSettingsKey];
  self.goClock = [decoder decodeObjectOfClass:[GoClock class] forKey:goPlayerTimeDataClockKey];
  self.isTimeDataForBlackPlayer = [decoder decodeBoolForKey:goPlayerTimeDataIsTimeDataForBlackPlayerKey];
  self.isRemainingTimeAbsoluteTime = [decoder decodeBoolForKey:goPlayerTimeDataIsRemainingTimeAbsoluteTimeKey];
  self.remainingTimeInSeconds = [decoder decodeDoubleForKey:goPlayerTimeDataRemainingTimeInSecondsKey];
  self.remainingNumberOfMoves = [decoder decodeIntForKey:goPlayerTimeDataRemainingNumberOfMovesKey];
  self.remainingNumberOfPeriods = [decoder decodeIntForKey:goPlayerTimeDataRemainingNumberOfPeriodsKey];

  // If all goes well we should restore into the suspended clock state (because
  // when it is suspended the app is supposed to suspend clocks). However, if
  // the app crashes we may subsequentially restore into the started clock
  // state.
  //
  // A GoClock that is restored into its started state begins its life with the
  // same amount of elapsed time as when it was archived, and continues to run
  // seemingly uninterrupted. One way how we could handle this is to immediately
  // schedule a timer to get back into sync with the clock. However, the whole
  // process of restoring the app into its previous state is relatively time
  // consuming. During that time no user interactions are possible, so letting
  // the clock running is a bad idea. The best solution therefore is to suspend
  // the clock now (which will deduce any elapsed time from our remaining time),
  // and to let an external handler decide at the appropriate time whether to
  // start the clock again, or leave it suspended.

  // TODO xxx do we still need this?
  if (self.clockState == GoClockStateStarted)
    [self suspendClockIfNotSuspended:GoClockSuspendedReasonRestoredFromArchive];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPlayerTimeData object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.goTimeSettings = nil;
  self.goClock = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.goTimeSettings forKey:goPlayerTimeDataTimeSettingsKey];
  [encoder encodeObject:self.goClock forKey:goPlayerTimeDataClockKey];
  [encoder encodeBool:self.isTimeDataForBlackPlayer forKey:goPlayerTimeDataIsTimeDataForBlackPlayerKey];
  [encoder encodeBool:self.isRemainingTimeAbsoluteTime forKey:goPlayerTimeDataIsRemainingTimeAbsoluteTimeKey];
  [encoder encodeDouble:self.remainingTimeInSeconds forKey:goPlayerTimeDataRemainingTimeInSecondsKey];
  [encoder encodeInt:self.remainingNumberOfMoves forKey:goPlayerTimeDataRemainingNumberOfMovesKey];
  [encoder encodeInt:self.remainingNumberOfPeriods forKey:goPlayerTimeDataRemainingNumberOfPeriodsKey];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Updates the time data in this GoPlayerTimeData object and in
/// @a goNodeTimeData after a move was played. Updating is performed according
/// to the parameters in the GoTimeSettings object that was supplied to the
/// GoPlayerTimeData initializer.
///
/// @exception NSInternalInconsistencyException Is raised in the following
/// cases:
/// - If the clock is started. The caller needs to suspend or stop the clock
///   before invoking this method, to guarantee consistent data.
/// - If the player has already lost on time. The caller needs to make sure
///   the player still has some time left before invoking this method. Invoke
///   didPlayerLoseOnTime() to check.
///
/// @exception NSInvalidArgumentException Is raised if @a nodeTimeData is
/// @e nil.
// -----------------------------------------------------------------------------
- (void) updateAfterMoveWasPlayed:(GoNodeTimeData*)nodeTimeData
{
  if (! nodeTimeData)
  {
    NSString* errorMessage = @"updateAfterMoveWasPlayed: failed: nodeTimeData is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  if (self.goClock.state == GoClockStateStarted)
  {
    NSString* errorMessage = @"updateAfterMoveWasPlayed: failed: Clock is still started";
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  if (self.didPlayerLoseOnTime)
  {
    NSString* errorMessage = @"updateAfterMoveWasPlayed: failed: player has lost on time";
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  bool dataHasChanged = false;

  // If the time system does not have a requirement for minimum number of moves,
  // we don't have to modify remainingNumberOfMoves, and therefore also don't
  // have to do a period reset. The typical case for this is Absolute Timing.
  GoTimeSystem* timeSystem = self.effectiveTimeSystem;
  if (timeSystem.hasMinimumNumberOfMovesPerPeriod)
  {
    if (self.remainingNumberOfMoves > 0)
    {
      self.remainingNumberOfMoves--;
      dataHasChanged = true;
    }
    else
    {
      if (timeSystem.goUnusedTimeHandling != GoUnusedTimeHandlingUseForExtraMoves)
      {
        NSString* errorMessage = @"updateAfterMoveWasPlayed: failed: time system has unexpected unused time handling %ld";
        [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:errorMessage
                                                          argumentValue:timeSystem.goUnusedTimeHandling];
      }
    }
  }

  // Important: Set the node time data with values before the period reset. We
  // want to record how much time and how many moves remained when the move
  // ended, not how much time and how many moves remain when playing the next
  // move will start.
  nodeTimeData.isRemainingTimeAbsoluteTime = self.isRemainingTimeAbsoluteTime;
  nodeTimeData.remainingTimeInSeconds = self.remainingTimeInSeconds;
  nodeTimeData.remainingNumberOfMoves = self.remainingNumberOfMoves;
  nodeTimeData.remainingNumberOfPeriods = self.remainingNumberOfPeriods;

  dataHasChanged |= [self performPeriodResetIfNecessary:timeSystem];

  if (dataHasChanged)
    [self postNotificationOnMainThread:playerTimeDataHasChanged];
}

// -----------------------------------------------------------------------------
/// @brief Updates this GoPlayerTimeData object after the currently selected
/// node changed to @a node. When this method returns, the time data in this
/// GoPlayerTimeData object reflects the player's situation at @a node.
///
/// The updating logic searches backwards through the path between @a node
/// (including @a node) and the game's root node and looks for a node that
/// contains a move made by the player whose time data is stored by this
/// GoPlayerTimeData.
/// - If such a node can be found, the time data in this GoPlayerTimeData is
///   updated to equal the data in the GoNodeTimeData object that is expected
///   to exist in the same node that contains the move.
/// - If no such node can be found, the time data in this GoPlayerTimeData is
///   updated to equal the initial time settings after the game was started.
///
/// @exception NSInvalidArgumentException Is raised if @a node is @e nil.
/// @exception NSInternalInconsistencyException Is raised if a node with a move
///            is found, but that node does not contain a GoNodeTimeData object.
// -----------------------------------------------------------------------------
- (void) updateAfterNodeChanged:(GoNode*)node
{
  if (! node)
  {
    NSString* errorMessage = @"updateAfterNodeChanged: failed: node is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  enum GoColor color = (self.isTimeDataForBlackPlayer
                        ? GoColorBlack
                        : GoColorWhite);
  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:node
                                                              playedBy:color];

  bool dataHasChanged;
  if (nodeWithMostRecentMove)
  {
    GoNodeTimeData* nodeTimeData = nodeWithMostRecentMove.goNodeTimeData;
    if (! nodeTimeData)
    {
      NSString* errorMessage = @"updateAfterNodeChanged: failed: node contains move, but does not contain";
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }

    dataHasChanged = [self updateWithNodeTimeData:nodeTimeData];
  }
  else
  {
    dataHasChanged = [self updateWithTimeSettingsTimeData];
  }

  if (dataHasChanged)
    [self postNotificationOnMainThread:playerTimeDataHasChanged];
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (int) remainingNumberOfMovesOrPeriods
{
  if (self.isRemainingTimeAbsoluteTime)
    return self.goTimeSettings.absoluteTimeSystem.numberOfPeriods;

  GoTimeSystem* timeSystem = self.goTimeSettings.periodBasedTimeSystem;
  if (timeSystem.goTimeSystemType == GoTimeSystemTypeJapanese)
    return self.remainingNumberOfPeriods;
  else
    return self.remainingNumberOfMoves;
}

// -----------------------------------------------------------------------------
/// @brief The state of the clock that is used to keep the time for the
/// player (e.g. stopped, running, etc.).
///
/// The default value after initialization is #GoClockStateStopped.
// -----------------------------------------------------------------------------
- (enum GoClockState) clockState
{
  return self.goClock.state;
}

// -----------------------------------------------------------------------------
/// @brief The reason why the clock is currently suspended.
///
/// This property has value #GoClockSuspendedReasonNotSuspended if the clock
/// is currently not suspended, i.e. if property @e state does not have the
/// value #GoClockStateSuspended.
// -----------------------------------------------------------------------------
- (enum GoClockSuspendedReason) clockSuspendedReason
{
  return self.goClock.suspendedReason;
}

#pragma mark - Clock handling

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) startClock
{
  @synchronized(self)
  {
    if (self.goClock.state == GoClockStateStarted)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Failed to start clock for %d, clock is already started", self.isTimeDataForBlackPlayer];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }

    if (self.didPlayerLoseOnTime)
    {
      NSString* errorMessage = @"Failed to start clock for %d, player has lost on time";
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }

    if (self.goClock.state == GoClockStateStopped)
      [self.goClock start];
    else
      [self.goClock resume];

    [self postNotificationOnMainThread:playerClockStateHasChanged];
  }
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) suspendClockIfNotSuspended:(enum GoClockSuspendedReason)reason
{
  @synchronized(self)
  {
    if (self.goClock.state == GoClockStateSuspended)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Failed to suspend clock for %d, clock is already suspended", self.isTimeDataForBlackPlayer];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }

    double elapsedTimeInSecondsSinceClockWasStarted;
    if (self.goClock.state == GoClockStateStarted)
    {
      elapsedTimeInSecondsSinceClockWasStarted = [self.goClock suspend:reason];
    }
    else
    {
      // GoClock doesn't allow going directly from stopped to suspended. Instead
      // it forces us to first start the clock, and then suspend it.
      [self.goClock start];
      [self.goClock suspend:reason];
      elapsedTimeInSecondsSinceClockWasStarted = 0.0;
    }

    [self postNotificationOnMainThread:playerClockStateHasChanged];

    enum GoPeriodDurationElapsedResultType result = [self deductElapsedTimeInSeconds:elapsedTimeInSecondsSinceClockWasStarted];

    [self postNotificationOnMainThread:playerTimeDataHasChanged];

    if (result == GoPeriodDurationElapsedResultTypeGameLostOnTime)
    {
      [self.goClock stop];
      [self postNotificationOnMainThread:playerClockStateHasChanged];

      [self postNotificationOnMainThread:playerLostOnTime];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) stopClockIfNotStopped
{
  @synchronized(self)
  {
    if (self.goClock.state == GoClockStateStopped)
      return;

    double elapsedTimeInSecondsSinceClockWasStarted = [self.goClock stop];

    [self postNotificationOnMainThread:playerClockStateHasChanged];

    enum GoPeriodDurationElapsedResultType result = [self deductElapsedTimeInSeconds:elapsedTimeInSecondsSinceClockWasStarted];

    [self postNotificationOnMainThread:playerTimeDataHasChanged];

    if (result == GoPeriodDurationElapsedResultTypeGameLostOnTime)
      [self postNotificationOnMainThread:playerLostOnTime];
  }
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (bool) didPlayerLoseOnTime
{
  if (self.goClock.state == GoClockStateStarted)
  {
    NSString* errorMessage = @"Failed to determine whether player lost on time, clock is still started";
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  return (self.remainingTimeInSeconds <= 0);
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) postNotificationOnMainThread:(NSString*)notificationName
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(postNotificationOnMainThread:) withObject:notificationName waitUntilDone:YES];
    return;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

#pragma mark - Private helper methods

// -----------------------------------------------------------------------------
/// @brief Updates the time data in this GoPlayerTimeData object to match the
/// the parameters in the GoTimeSettings object that was supplied to the
/// GoPlayerTimeData initializer. Returns true if any properties of this
/// GoPlayerTimeData changed their values. Returns false if no properties
/// changed their values.
// -----------------------------------------------------------------------------
- (bool) updateWithTimeSettingsTimeData
{
  bool dataHasChanged = false;

  bool isRemainingTimeAbsoluteTime = (self.goTimeSettings.absoluteTimeSystem.goTimeSystemType == GoTimeSystemTypeAbsolute);
  if (self.isRemainingTimeAbsoluteTime != isRemainingTimeAbsoluteTime)
  {
    self.isRemainingTimeAbsoluteTime = isRemainingTimeAbsoluteTime;
    dataHasChanged = true;
  }

  GoTimeSystem* timeSystem = self.effectiveTimeSystem;

  if (self.remainingTimeInSeconds != timeSystem.periodDurationInSeconds)
  {
    self.remainingTimeInSeconds = timeSystem.periodDurationInSeconds;
    dataHasChanged = true;
  }

  unsigned int remainingNumberOfMoves = (timeSystem.hasMinimumNumberOfMovesPerPeriod
                                         ? timeSystem.minimumNumberOfMovesPerPeriod
                                         : 0);
  if (self.remainingNumberOfMoves != remainingNumberOfMoves)
  {
    self.remainingNumberOfMoves = remainingNumberOfMoves;
    dataHasChanged = true;
  }

  if (self.remainingNumberOfPeriods != timeSystem.numberOfPeriods)
  {
    self.remainingNumberOfPeriods = timeSystem.numberOfPeriods;
    dataHasChanged = true;
  }

  return dataHasChanged;
}

// -----------------------------------------------------------------------------
/// @brief Returns the time system that is in effect.
// -----------------------------------------------------------------------------
- (GoTimeSystem*) effectiveTimeSystem
{
  if (self.isRemainingTimeAbsoluteTime)
    return self.goTimeSettings.absoluteTimeSystem;
  else
    return self.goTimeSettings.periodBasedTimeSystem;
}

// -----------------------------------------------------------------------------
/// @brief Updates the time data in this GoPlayerTimeData object to be equal to
/// the time data in @a nodeTimeData.
// -----------------------------------------------------------------------------
- (bool) updateWithNodeTimeData:(GoNodeTimeData*)nodeTimeData
{
  bool dataHasChanged = false;

  if (self.isRemainingTimeAbsoluteTime != nodeTimeData.isRemainingTimeAbsoluteTime)
  {
    self.isRemainingTimeAbsoluteTime = nodeTimeData.isRemainingTimeAbsoluteTime;
    dataHasChanged = true;
  }

  if (self.remainingTimeInSeconds != nodeTimeData.remainingTimeInSeconds)
  {
    self.remainingTimeInSeconds = nodeTimeData.remainingTimeInSeconds;
    dataHasChanged = true;
  }

  if (self.remainingNumberOfMoves != nodeTimeData.remainingNumberOfMoves)
  {
    self.remainingNumberOfMoves = nodeTimeData.remainingNumberOfMoves;
    dataHasChanged = true;
  }

  if (self.remainingNumberOfPeriods != nodeTimeData.remainingNumberOfPeriods)
  {
    self.remainingNumberOfPeriods = nodeTimeData.remainingNumberOfPeriods;
    dataHasChanged = true;
  }

  // Determine the effective time system after isRemainingTimeAbsoluteTime has
  // been updated
  GoTimeSystem* timeSystem = [self effectiveTimeSystem];
  dataHasChanged |= [self performPeriodResetIfNecessary:timeSystem];

  return dataHasChanged;
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (enum GoPeriodDurationElapsedResultType) deductElapsedTimeInSeconds:(double)elapsedTimeInSeconds
{
  // TODO xxx do we really want to deduct time with full accuracy? SGF does
  // allow saving fractional values, but how much accuracy do we really need?
  self.remainingTimeInSeconds -= elapsedTimeInSeconds;

  if (self.remainingTimeInSeconds > 0)
    return GoPeriodDurationElapsedResultTypeGameContinues;

  GoTimeSystem* periodBasedTimeSystem = self.goTimeSettings.periodBasedTimeSystem;
  if (self.isRemainingTimeAbsoluteTime)
  {
    if (! periodBasedTimeSystem.supportsTimedPlay)
      return GoPeriodDurationElapsedResultTypeGameLostOnTime;

    self.isRemainingTimeAbsoluteTime = false;
    self.remainingTimeInSeconds += periodBasedTimeSystem.periodDurationInSeconds;
    self.remainingNumberOfPeriods = periodBasedTimeSystem.numberOfPeriods;
    if (periodBasedTimeSystem.hasMinimumNumberOfMovesPerPeriod)
      self.remainingNumberOfMoves = periodBasedTimeSystem.minimumNumberOfMovesPerPeriod;
    else
      self.remainingNumberOfMoves = 0;
    return [self countDownPeriodsWithTimeSystem:periodBasedTimeSystem];
  }
  else
  {
    return [self countDownPeriodsWithTimeSystem:periodBasedTimeSystem];
  }
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (enum GoPeriodDurationElapsedResultType) countDownPeriodsWithTimeSystem:(GoTimeSystem*)timeSystem
{
  while (self.remainingTimeInSeconds <= 0)
  {
    self.remainingNumberOfPeriods--;

    if (self.remainingNumberOfPeriods == 0)
    {
      return GoPeriodDurationElapsedResultTypeGameLostOnTime;
    }

    self.remainingTimeInSeconds += timeSystem.periodDurationInSeconds;
  }

  return GoPeriodDurationElapsedResultTypeGameContinues;
}

// -----------------------------------------------------------------------------
/// @brief Performs a period reset based on the values in @a timeSystem, but
/// only if such a reset is necessary. Returns true if any properties of this
/// GoPlayerTimeData changed their values. Returns false if no properties
/// changed their values (e.g. because no period reset was necessary).
// -----------------------------------------------------------------------------
- (bool) performPeriodResetIfNecessary:(GoTimeSystem*)timeSystem
{
  if (! timeSystem.hasMinimumNumberOfMovesPerPeriod ||
      self.remainingNumberOfMoves > 0)
  {
    return false;
  }

  switch (timeSystem.goUnusedTimeHandling)
  {
    case GoUnusedTimeHandlingRoundDown:
      self.remainingTimeInSeconds = timeSystem.periodDurationInSeconds;
      self.remainingNumberOfMoves = timeSystem.minimumNumberOfMovesPerPeriod;
      return true;
    case GoUnusedTimeHandlingUseForExtraMoves:
      return false;
    case GoUnusedTimeHandlingAddPeriodDuration:
      self.remainingTimeInSeconds += timeSystem.periodDurationInSeconds;
      self.remainingNumberOfMoves = timeSystem.minimumNumberOfMovesPerPeriod;
      return true;
    case GoUnusedTimeHandlingAddExtraTime:
      self.remainingTimeInSeconds += timeSystem.extraTimeDurationInSeconds;
      self.remainingNumberOfMoves = timeSystem.minimumNumberOfMovesPerPeriod;
      return true;
    case GoUnusedTimeHandlingNone:
    default:
    {
      NSString* errorMessage = @"performPeriodResetIfNecessary: failed: time system has unexpected unused time handling %ld";
      [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:errorMessage
                                                        argumentValue:timeSystem.goUnusedTimeHandling];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
      return false;
    }
  }
}

@end
