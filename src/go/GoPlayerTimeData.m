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


static NSTimeInterval timerIntervalOneSecond = 1.0;

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
@property(nonatomic, retain) NSTimer* timer;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) bool isTimeDataForBlackPlayer;
@property(nonatomic, retain, readwrite) GoClock* goClock;
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
  self.timer = nil;

  self.isTimeDataForBlackPlayer = isTimeDataForBlackPlayer;
  self.goClock = [[[GoClock alloc] init] autorelease];

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
  // TODO xxx probably we don't need to get the timer from the archive
  self.isTimeDataForBlackPlayer = [decoder decodeBoolForKey:goPlayerTimeDataIsTimeDataForBlackPlayerKey];
  self.goClock = [decoder decodeObjectOfClass:[GoClock class] forKey:goPlayerTimeDataClockKey];
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
  // TODO xxx probably we don't need to archive the timer
  [encoder encodeBool:self.isTimeDataForBlackPlayer forKey:goPlayerTimeDataIsTimeDataForBlackPlayerKey];
  [encoder encodeObject:self.goClock forKey:goPlayerTimeDataClockKey];
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
/// @brief Updates the time data in this GoPlayerTimeData object after a move
/// was played. @a timeUsedForMoveInSeconds indicates how much time was used
/// to play the move. Updating is performed according to the parameters in the
/// GoTimeSettings object that was supplied to the GoPlayerTimeData initializer.
///
/// Returns whether the game can continue, or whether the game is lost on time.
/// If the game is lost on time, property @e remainingTimeInSeconds has a
/// negative value indicating how much time was.
///
/// TODO xxx when this returns, if a period reset was necessary the reset
/// has already been done; in this case the time data cannot be used to populate
/// GoNodeTimeData.
// -----------------------------------------------------------------------------
- (enum GoPeriodDurationElapsedResultType) updateAfterMoveWasPlayed:(double)timeUsedForMoveInSeconds
                                                     goNodeTimeData:(GoNodeTimeData*)goNodeTimeData
{
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
    // TODO xxx does KVO trigger if the same value is set?

    // TODO xxx order in which properties are updated may be important when
    // clients use KVO; think about it and document it.

    self.isRemainingTimeAbsoluteTime = isRemainingTimeAbsoluteTime;
    self.remainingTimeInSeconds = remainingTimeInSeconds;
    self.remainingNumberOfMoves = remainingNumberOfMoves;
    self.remainingNumberOfPeriods = remainingNumberOfPeriods;
  };

  remainingTimeInSeconds -= timeUsedForMoveInSeconds;

  // If necessary, switch from absolute time system to period-based time system
  if (remainingTimeInSeconds <= 0 && isRemainingTimeAbsoluteTime && self.goTimeSettings.periodBasedTimeSystem)
  {
    timeSystem = self.goTimeSettings.periodBasedTimeSystem;

    isRemainingTimeAbsoluteTime = false;
    remainingTimeInSeconds += timeSystem.periodDurationInSeconds;
    if (timeSystem.hasMinimumNumberOfMovesPerPeriod)
      remainingNumberOfMoves = timeSystem.minimumNumberOfMovesPerPeriod;
    else
      remainingNumberOfMoves = 0;
    remainingNumberOfPeriods = timeSystem.numberOfPeriods;
  }

  // Now that we are in the correct time system, we can deduct time periods
  // if necessary
  while (remainingTimeInSeconds <= 0)
  {
    remainingNumberOfPeriods--;

    // TODO xxx this should not happen, should it? the computer player should
    // always play on time, and the user should never get the opportunity to
    // play a move after they run out of time
    if (remainingNumberOfPeriods == 0)
    {
      updateGoNodeTimeData();
      updateSelf();
      return GoPeriodDurationElapsedResultTypeGameLostOnTime;
    }

    remainingTimeInSeconds += timeSystem.periodDurationInSeconds;
  }

  // At this point no further period switching is possible and
  // we can start dealing with remainingNumberOfMoves.

  // If the time system does not have a requirement for minimum number of moves,
  // we don't have to modify remainingNumberOfMoves, and therefore also don't
  // have to do a period reset.
  if (! timeSystem.hasMinimumNumberOfMovesPerPeriod)
  {
    updateGoNodeTimeData();
    updateSelf();
    return GoPeriodDurationElapsedResultTypeGameContinues;
  }

  if (remainingNumberOfMoves > 0)
  {
    remainingNumberOfMoves--;

    if (remainingNumberOfMoves > 0)
    {
      // No reset needed
      updateGoNodeTimeData();
      updateSelf();
      return GoPeriodDurationElapsedResultTypeGameContinues;
    }
  }
  else
  {
    if (timeSystem.goUnusedTimeHandling != GoUnusedTimeHandlingUseForExtraMoves)
    {
      NSString* errorMessage = @"Failed to update time data after move was played, time system has unexpected unused time handling %ld";
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
      NSString* errorMessage = @"Failed to update time data after move was played (period reset), time system has unexpected unused time handling %ld";
      [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:errorMessage
                                                        argumentValue:timeSystem.goUnusedTimeHandling];
      break;
    }
  }

  updateSelf();
  return GoPeriodDurationElapsedResultTypeGameContinues;
}

// -----------------------------------------------------------------------------
/// @brief Updates the time data in this GoPlayerTimeData object after the
/// current period's duration has elapsed while the player is still thinking
/// about their move. Updating is performed according to the parameters in the
/// GoTimeSettings object that was supplied to the GoPlayerTimeData initializer.
// -----------------------------------------------------------------------------
//- (enum GoPeriodDurationElapsedResultType) updateAfterPeriodDurationHasElapsed
//{
//  // TODO xxx implement
//  return GoPeriodDurationElapsedResultTypeGameContinues;
//}

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

#pragma mark - Clock/timer handling

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) startClock
{
  @synchronized(self)
  {
    NSNumber* timerInterval = [self timerIntervalFiringAtNextRemainingSecond];

    // TODO xxx state check needed? yes! must not start two timers
    if (self.goClock.state == GoClockStateStopped)
      [self.goClock start];
    else
      [self.goClock resume];

    // In case the timer fires exactly at the interval: By scheduling the timer
    // AFTER the clock has started, we can be sure that the clock will NOT see
    // that less than one second have elapsed.
    [self scheduleTimerOnMainThread:timerInterval];

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
    [self invalidateTimerOnMainThread];

    // TODO xxx state check needed? Yes, the timer handler may have left the
    // clock in suspended state
    [self.goClock suspend:reason];

    // TODO xxx must not deduct because the suspended clock keeps track of the elapsed time
//    self.remainingTimeInSeconds -= self.goClock.totalElapsedTimeInSecondsSinceClockWasStarted;

    [self postNotificationOnMainThread:playerClockStateHasChanged];
//    [self postNotificationOnMainThread:playerTimeDataHasChanged];
  }
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (NSNumber*) timerIntervalFiringAtNextRemainingSecond
{
  double remainingTimeInSeconds;
  if (self.goClock.state == GoClockStateStopped)
    remainingTimeInSeconds = self.remainingTimeInSeconds;
  else
    remainingTimeInSeconds = self.remainingTimeInSeconds - self.goClock.totalElapsedTimeInSecondsSinceClockWasStarted;

  double integralPartOfRemainingTimeInSeconds;
  double fractionalPartOfRemainingTimeInSeconds = modf(remainingTimeInSeconds, &integralPartOfRemainingTimeInSeconds);
  if (fractionalPartOfRemainingTimeInSeconds > 0)
    return [NSNumber numberWithDouble:fractionalPartOfRemainingTimeInSeconds];
  else
    return [NSNumber numberWithDouble:timerIntervalOneSecond];
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

  self.timer = [NSTimer scheduledTimerWithTimeInterval:[timerIntervalAsNumber doubleValue]
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

    // TODO xxx do we need a different reason?
    [self.goClock suspend:GoClockSuspendedReasonAppSuspended];

    // Calculate the interval before updating self.remainingTimeInSeconds,
    // because the calculation includes the clock's elapsed time
    NSNumber* timerInterval = [self timerIntervalFiringAtNextRemainingSecond];

    // TODO xxx implement more logic => period change, lose on time
    self.remainingTimeInSeconds -= self.goClock.totalElapsedTimeInSecondsSinceClockWasStarted;

    [self postNotificationOnMainThread:playerTimeDataHasChanged];

    [self.goClock restart];

    // In case the timer fires exactly at the interval: By scheduling the timer
    // AFTER the clock has started, we can be sure that the clock will NOT see
    // that less than one second have elapsed.
    [self scheduleTimerOnMainThread:timerInterval];
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
  self.isRemainingTimeAbsoluteTime = (self.goTimeSettings.absoluteTimeSystem != nil);

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

@end
