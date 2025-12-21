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
#import "GoNodeTimeData.h"
#import "GoTimeSettings.h"
#import "GoTimeSystem.h"
#import "../utility/ExceptionUtility.h"


static double timerIntervalOneSecond = 1.0;

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
/// @brief The timer object used to periodically update the time data in this
/// GoPlayerTimeData object.
@property(nonatomic, retain) NSTimer* timer;
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
  self.timer = nil;

  self.isTimeDataForBlackPlayer = isTimeDataForBlackPlayer;

  // Initializes the remaining properties
  [self updateWithTimeSettings];

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
  // TODO xxx probably we don't need to get the timer from the archive
  self.isTimeDataForBlackPlayer = [decoder decodeBoolForKey:goPlayerTimeDataIsTimeDataForBlackPlayerKey];
  self.isRemainingTimeAbsoluteTime = [decoder decodeBoolForKey:goPlayerTimeDataIsRemainingTimeAbsoluteTimeKey];
  self.remainingTimeInSeconds = [decoder decodeDoubleForKey:goPlayerTimeDataRemainingTimeInSecondsKey];
  self.remainingNumberOfMoves = [decoder decodeIntForKey:goPlayerTimeDataRemainingNumberOfMovesKey];
  self.remainingNumberOfPeriods = [decoder decodeIntForKey:goPlayerTimeDataRemainingNumberOfPeriodsKey];

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
  // TODO xxx probably we don't need to archive the timer
  [encoder encodeBool:self.isTimeDataForBlackPlayer forKey:goPlayerTimeDataIsTimeDataForBlackPlayerKey];
  [encoder encodeBool:self.isRemainingTimeAbsoluteTime forKey:goPlayerTimeDataIsRemainingTimeAbsoluteTimeKey];
  [encoder encodeDouble:self.remainingTimeInSeconds forKey:goPlayerTimeDataRemainingTimeInSecondsKey];
  [encoder encodeInt:self.remainingNumberOfMoves forKey:goPlayerTimeDataRemainingNumberOfMovesKey];
  [encoder encodeInt:self.remainingNumberOfPeriods forKey:goPlayerTimeDataRemainingNumberOfPeriodsKey];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Updates this GoPlayerTimeData object after the current node changed
/// to @a node. @a goColor indicates which player's time data the updating logic
/// should use. When this method returns, the time data in this GoPlayerTimeData
/// object reflects the player's situation at @a node.
///
/// The updating logic goes through all nodes on the path between the game's
/// root node and @a node and searches for nodes that contain a GoMove object
/// representing a move made by the player identified by @a goColor, and a
/// GoNodeTimeData object. For every such node, the time data in the
/// GoNodeTimeData object is processed according to the parameters in the
/// GoTimeSettings object that was supplied to the GoPlayerTimeData initializer.
///
/// A few scenarios for which this method is intended:
/// - A new game is started. In that scenario @a node is the leaf node of the
///   new game's main variation. Because it's a new game, the leaf node is
///   likely the game's root node.
/// - A new game is loaded from the archive. In that scenario @a node is the
///   leaf node of the loaded game's main variation.
/// - The user navigates between nodes within the current game variation.
///   In that scenario @a node is the node that the user navigates to.
/// - The user changes the current game variation. In that scenario @a node is
///   the node that the user navigates to.
// -----------------------------------------------------------------------------
- (enum GoPeriodDurationElapsedResultType) updateAfterNodeChanged:(GoNode*)node
                                                        forPlayer:(enum GoColor)goColor
{
  // TODO xxx implement. difficulties:
  // - recognizing the switch from absolute time to overtime => in SGF we would
  //   see this via presence of OB/OW, but GoNodeTimeData has no "presence"
  //   indicator at the moment => maybe need to add it?
  // - when the clock was suspended, elapsed time is stored internally. this
  //   data is either lost upon a node change, or we need to record it in
  //   GoNodeTimeData; in the latter case, the design of GoClock may need to be
  //   changed.
  return GoPeriodDurationElapsedResultTypeGameContinues;
}

// -----------------------------------------------------------------------------
/// @brief Updates the time data in this GoPlayerTimeData object and in
/// @a goNodeTimeData after a move was played. Updating is performed according
/// to the parameters in the GoTimeSettings object that was supplied to the
/// GoPlayerTimeData initializer.
///
/// Raises an @e NSInternalInconsistencyException in the following cases:
/// - If the clock is started. The caller needs to suspend or stop the clock
///   before invoking this method, to guarantee consistent data.
/// - If the player has already lost on time. The caller needs to make sure
///   the player still has some time left before invoking this method. Invoke
///   didPlayerLoseOnTime() to check.
///
/// Raises @e NSInvalidArgumentException if @a goNodeTimeData is @e nil.
// -----------------------------------------------------------------------------
- (void) updateAfterMoveWasPlayed:(GoNodeTimeData*)goNodeTimeData
{
  if (! goNodeTimeData)
  {
    NSString* errorMessage = @"updateAfterMoveWasPlayed: failed: goNodeTimeData is nil";
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

  GoTimeSystem* timeSystem = self.effectiveTimeSystem;
  __block bool isRemainingTimeAbsoluteTime = self.isRemainingTimeAbsoluteTime;
  __block double remainingTimeInSeconds = self.remainingTimeInSeconds;
  __block unsigned int remainingNumberOfMoves = self.remainingNumberOfMoves;
  __block unsigned int remainingNumberOfPeriods = self.remainingNumberOfPeriods;

  void (^updateGoNodeTimeData) (void) = ^ void ()
  {
    goNodeTimeData.isRemainingTimeAbsoluteTime = isRemainingTimeAbsoluteTime;
    goNodeTimeData.remainingTimeInSeconds = remainingTimeInSeconds;
    goNodeTimeData.remainingNumberOfMoves = remainingNumberOfMoves;
    goNodeTimeData.remainingNumberOfPeriods = remainingNumberOfPeriods;
  };

  void (^updateSelf) (void) = ^ void ()
  {
    self.remainingTimeInSeconds = remainingTimeInSeconds;
    self.remainingNumberOfMoves = remainingNumberOfMoves;

    [self postNotificationOnMainThread:playerTimeDataHasChanged];
  };

  // If the time system does not have a requirement for minimum number of moves,
  // we don't have to modify remainingNumberOfMoves, and therefore also don't
  // have to do a period reset. The typical case for this is Absolute Timing.
  if (! timeSystem.hasMinimumNumberOfMovesPerPeriod)
  {
    updateGoNodeTimeData();
    return;
  }

  if (remainingNumberOfMoves > 0)
  {
    remainingNumberOfMoves--;

    if (remainingNumberOfMoves > 0)
    {
      // No reset needed
      updateGoNodeTimeData();
      updateSelf();
      return;
    }
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

  // Important: Update the node time data before the period reset => We want to
  // record how much time and how many moves remained when the move ended, not
  // how much time and how many moves remain when playing the next move will
  // start
  updateGoNodeTimeData();

  // Perform period reset if necessary
  switch (timeSystem.goUnusedTimeHandling)
  {
    case GoUnusedTimeHandlingRoundDown:
      remainingTimeInSeconds = timeSystem.periodDurationInSeconds;
      remainingNumberOfMoves = timeSystem.minimumNumberOfMovesPerPeriod;
      break;
    case GoUnusedTimeHandlingUseForExtraMoves:
      break;
    case GoUnusedTimeHandlingAddPeriodDuration:
      remainingTimeInSeconds = timeSystem.periodDurationInSeconds + remainingTimeInSeconds;
      remainingNumberOfMoves = timeSystem.minimumNumberOfMovesPerPeriod;
      break;
    case GoUnusedTimeHandlingAddExtraTime:
      remainingTimeInSeconds = timeSystem.extraTimeDurationInSeconds + remainingTimeInSeconds;
      remainingNumberOfMoves = timeSystem.minimumNumberOfMovesPerPeriod;
      break;
    case GoUnusedTimeHandlingNone:
    default:
    {
      NSString* errorMessage = @"updateAfterMoveWasPlayed: failed (period reset): time system has unexpected unused time handling %ld";
      [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:errorMessage
                                                        argumentValue:timeSystem.goUnusedTimeHandling];
      break;
    }
  }

  updateSelf();
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document; idea is that we need to know when to trigger the game loss; player can think until then
// -----------------------------------------------------------------------------
- (double) timeWithoutMoveUntilGameIsLostOnTime
{
  // TODO xxx implement
  return 0.0;
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

#pragma mark - Clock/timer handling

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

    // In case the timer fires exactly at the interval: By scheduling the timer
    // AFTER the clock has started, we can be sure that the clock will NOT see
    // that less than one second have elapsed.
    double timerInterval = [GoPlayerTimeData timeUntilNextFullSecond:self.remainingTimeInSeconds];
    [self scheduleTimerOnMainThread:[NSNumber numberWithDouble:timerInterval]];

    [self postNotificationOnMainThread:playerClockStateHasChanged];
  }
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) suspendClock:(enum GoClockSuspendedReason)reason
{
  @synchronized(self)
  {
    if (self.goClock.state != GoClockStateStarted)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Failed to suspend clock for %d, clock is not started, state = %d", self.isTimeDataForBlackPlayer, self.goClock.state];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }

    [self invalidateTimerOnMainThread];

    double elapsedTimeInSecondsSinceClockWasStarted = [self.goClock suspend:reason];

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

    if (self.goClock.state == GoClockStateStarted)
      [self invalidateTimerOnMainThread];

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
+ (double) timeUntilNextFullSecond:(double)remainingTimeInSeconds
{
  double integralPartOfRemainingTimeInSeconds;
  double fractionalPartOfRemainingTimeInSeconds = modf(remainingTimeInSeconds, &integralPartOfRemainingTimeInSeconds);
  if (fractionalPartOfRemainingTimeInSeconds > 0)
    return fractionalPartOfRemainingTimeInSeconds;
  else
    return timerIntervalOneSecond;
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) scheduleTimerOnMainThread:(NSNumber*)timerIntervalAsNumber
{
  // We want to make sure that the timer is scheduled on the main thread so
  // that the timer also fires on the main thread, and the app is notified of
  // the time data update on the main thread
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(scheduleTimerOnMainThread:)
                           withObject:timerIntervalAsNumber
                        waitUntilDone:YES];
    return;
  }

  // TODO xxx remove
  DDLogError(@"scheduling timer with interval %@", timerIntervalAsNumber);

  double timerInterval = [timerIntervalAsNumber doubleValue];
  if (timerInterval < 0)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to schedule timer, timer interval %f is less than zero", timerInterval];
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  if (self.timer)
  {
    NSString* errorMessage = @"Failed to schedule timer, another timer is already running";
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  self.timer = [NSTimer scheduledTimerWithTimeInterval:timerInterval
                                                target:self
                                              selector:@selector(timerHasElapsed)
                                              userInfo:nil
                                               repeats:NO];
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) invalidateTimerOnMainThread
{
  // The timer must be invalidated on the same thread where it was scheduled
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(invalidateTimerOnMainThread)
                           withObject:nil
                        waitUntilDone:YES];
    return;
  }

  // The timer has fired at the same time we were trying to invalidate it, and
  // the timer handler did not schedule a new timer
  if (! self.timer)
    return;

  [self.timer invalidate];
  self.timer = nil;
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) timerHasElapsed
{
  @synchronized(self)
  {
    // The timer was invalidated at the same time it was firing. This means we
    // should not continue, whoever did the invalidation will take the necessary
    // steps to update our data.
    if (! self.timer)
      return;
    self.timer = nil;

    if (self.goClock.state != GoClockStateStarted)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Timer failed to suspend clock for %d, clock is not started, state = %d", self.isTimeDataForBlackPlayer, self.goClock.state];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }

    double elapsedTimeInSecondsSinceClockWasStarted = [self.goClock suspend:GoClockSuspendedReasonHandleTimer];

    enum GoPeriodDurationElapsedResultType result = [self deductElapsedTimeInSeconds:elapsedTimeInSecondsSinceClockWasStarted];

    [self postNotificationOnMainThread:playerTimeDataHasChanged];

    if (result == GoPeriodDurationElapsedResultTypeGameLostOnTime)
    {
      [self.goClock stop];
      [self postNotificationOnMainThread:playerClockStateHasChanged];

      [self postNotificationOnMainThread:playerLostOnTime];
    }
    else
    {
      [self.goClock restart];

      // In case the timer fires exactly at the interval: By scheduling the timer
      // AFTER the clock has started, we can be sure that the clock will NOT see
      // that less than one second have elapsed.
      double timerInterval = [GoPlayerTimeData timeUntilNextFullSecond:self.remainingTimeInSeconds];
      [self scheduleTimerOnMainThread:[NSNumber numberWithDouble:timerInterval]];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) postNotificationOnMainThread:(NSString*)notificationName
{
  // We want to make sure that the timer is scheduled on the main thread so
  // that the timer also fires on the main thread, and the app is notified of
  // the time data update on the main thread
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
/// GoPlayerTimeData initializer.
// -----------------------------------------------------------------------------
- (void) updateWithTimeSettings
{
  self.isRemainingTimeAbsoluteTime = (self.goTimeSettings.absoluteTimeSystem.goTimeSystemType == GoTimeSystemTypeAbsolute);

  GoTimeSystem* timeSystem = self.effectiveTimeSystem;

  self.remainingTimeInSeconds = timeSystem.periodDurationInSeconds;

  if (timeSystem.hasMinimumNumberOfMovesPerPeriod)
    self.remainingNumberOfMoves = timeSystem.minimumNumberOfMovesPerPeriod;
  else
    self.remainingNumberOfMoves = 0;

  self.remainingNumberOfPeriods = timeSystem.numberOfPeriods;
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
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (enum GoPeriodDurationElapsedResultType) deductElapsedTimeInSeconds:(double)elapsedTimeInSeconds
{
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

@end
