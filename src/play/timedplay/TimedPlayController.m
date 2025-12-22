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
#import "TimedPlayController.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPlayerTimeData.h"
#import "../../main/Registry.h"
#import "../../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TimedPlayController.
// -----------------------------------------------------------------------------
@interface TimedPlayController()
@property(nonatomic, assign) Registry* registry;
@property(nonatomic, retain) PlayerClockTimer* blackPlayerClockTimer;
@property(nonatomic, retain) GoPlayerTimeData* blackPlayerTimeData;
@property(nonatomic, retain) PlayerClockTimer* whitePlayerClockTimer;
@property(nonatomic, retain) GoPlayerTimeData* whitePlayerTimeData;
@end


@implementation TimedPlayController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a TimedPlayController object. Registers itself with
/// @a registry as PlayerClockService.
///
/// @note This is the designated initializer of TimedPlayController.
// -----------------------------------------------------------------------------
- (id) initWithRegistry:(Registry*)registry
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.registry = registry;
  self.blackPlayerClockTimer = [[[PlayerClockTimer alloc] initWithDelegate:self] autorelease];
  self.blackPlayerTimeData = nil;
  self.whitePlayerClockTimer = [[[PlayerClockTimer alloc] initWithDelegate:self] autorelease];
  self.whitePlayerTimeData = nil;

  [self setupNotificationResponders];

  self.registry.playerClockService = self;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimedPlayController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  [self.blackPlayerClockTimer invalidateTimerIfOneIsScheduled];
  self.blackPlayerTimeData = nil;
  self.blackPlayerClockTimer = nil;

  [self.whitePlayerClockTimer invalidateTimerIfOneIsScheduled];
  self.whitePlayerTimeData = nil;
  self.whitePlayerClockTimer = nil;

  self.registry.playerClockService = nil;

  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(sceneDidActivate:) name:UISceneDidActivateNotification object:nil];
  [center addObserver:self selector:@selector(sceneWillDeactivate:) name:UISceneWillDeactivateNotification object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the UISceneDidActivateNotification notification.
///
/// UISceneDidActivateNotification is posted after
/// UISceneWillEnterForegroundNotification, which in turn is posted after the
/// scene becomes connected.
///
/// UISceneDidActivateNotification is documented like this:
///   A notification that indicates that the scene is now onscreen and
///   responding to user events. UIKit posts this notification after loading
///   the interface for your scene, but before that interface appears onscreen.
///   Use it to [...] start timers [...].
// -----------------------------------------------------------------------------
- (void) sceneDidActivate:(NSNotification*)notification
{
  // TODO xxx implement
}

// -----------------------------------------------------------------------------
/// @brief Responds to the UISceneWillDeactivateNotification notification.
///
/// UISceneWillDeactivateNotification is posted before
/// UISceneDidEnterBackground, which is when the scene delegate saves the
/// application state if it is marked dirty.
///
/// UISceneWillDeactivateNotification is documented like this:
///   A notification that indicates that the scene is about to resign the active
///   state and stop responding to user events. UIKit posts this notification
///   for temporary interruptions, such as when displaying system alerts. It
///   also posts this notification before transitioning your app to the
///   background state. Use this notification to [...] stop interacting with
///   the user. Specifically, pause ongoing tasks, disable timers [...]. Games
///   should use this notification to pause the game.
// -----------------------------------------------------------------------------
- (void) sceneWillDeactivate:(NSNotification*)notification
{
  // TODO xxx implement
}

#pragma mark - PlayerClockService implementation

// -----------------------------------------------------------------------------
/// @brief PlayerClockService method.
// -----------------------------------------------------------------------------
- (void) startClockOfPlayer:(GoPlayer*)player reason:(enum PlayerClockStartReason)startReason
{
  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return;

  switch (startReason)
  {
    case PlayerClockStartReasonHumanPlayerTurnBegins:
      // The clock is expected to be never started
      [self startClock:playerTimeData];
      break;
    case PlayerClockStartReasonComputerPlayerStartsThinking:
      // The clock may already be started, e.g. if it is the turn of a human
      // player and they are using the "play for me" function
      if (playerTimeData.clockState != GoClockStateStarted)
        [self startClock:playerTimeData];
      break;
    case PlayerClockStartReasonUserRequest:
      // The clock is expected to be never started
      [self startClock:playerTimeData];
      break;
    default:
      // TODO xxx error handling
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayerClockService method.
// -----------------------------------------------------------------------------
- (enum PlayerClockServiceOperationResult) stopClockOfPlayer:(GoPlayer*)player
                                                      reason:(enum PlayerClockStopReason)stopReason
{
  // GoPlayerTimeData is nil if game does not use timed play
  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return PlayerClockServiceOperationResultGameContinues;

  [self stopClockIfNotStopped:playerTimeData];

  if (playerTimeData.didPlayerLoseOnTime)
    return PlayerClockServiceOperationResultGameLostOnTime;
  else
    return PlayerClockServiceOperationResultGameContinues;
}

// -----------------------------------------------------------------------------
/// @brief PlayerClockService method.
// -----------------------------------------------------------------------------
- (enum PlayerClockServiceOperationResult) suspendClockOfPlayer:(GoPlayer*)player
                                                         reason:(enum PlayerClockSuspendReason)suspendReason
{
  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return PlayerClockServiceOperationResultGameContinues;

  // TODO xxx map PlayerClockSuspendReason to GoClockSuspendedReason
  [self suspendClock:playerTimeData reason:GoClockSuspendedReasonUserAction];

  if (playerTimeData.didPlayerLoseOnTime)
    return PlayerClockServiceOperationResultGameLostOnTime;
  else
    return PlayerClockServiceOperationResultGameContinues;
}

#pragma mark - PlayerClockTimerDelegate implementation

// -----------------------------------------------------------------------------
/// @brief PlayerClockTimerDelegate method.
// -----------------------------------------------------------------------------
- (double) timeInSecondsUntilNextFullSecond:(PlayerClockTimer*)playerClockTimer
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataForPlayerClockTimer:playerClockTimer];

  double integralPartOfRemainingTimeInSeconds;
  double fractionalPartOfRemainingTimeInSeconds = modf(playerTimeData.remainingTimeInSeconds,
                                                       &integralPartOfRemainingTimeInSeconds);
  return fractionalPartOfRemainingTimeInSeconds;
}

// -----------------------------------------------------------------------------
/// @brief PlayerClockTimerDelegate method.
// -----------------------------------------------------------------------------
- (bool) timerDidFire:(PlayerClockTimer*)playerClockTimer
{
  GoPlayerTimeData* playerTimeData = [self playerTimeDataForPlayerClockTimer:playerClockTimer];

  if (playerTimeData.clockState != GoClockStateStarted)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Timer failed to suspend clock for %d, clock is not started, state = %d", playerTimeData.isTimeDataForBlackPlayer, playerTimeData.clockState];
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  [playerTimeData suspendClock:GoClockSuspendedReasonHandleTimer];

  // No need to stop the clock, suspendClock:() has already stopped the clock
  // if the player lost on time
  if (playerTimeData.didPlayerLoseOnTime)
    return false;

  [playerTimeData startClock];

  // Schedule another timer
  return true;
}

#pragma mark - Internal handling of clocks/timers

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) startClock:(GoPlayerTimeData*)playerTimeData
{
  [playerTimeData startClock];

  // In case the timer fires exactly at the interval: By scheduling the timer
  // AFTER the clock has started, we can be sure that the clock will NOT see
  // that less than one second have elapsed.
  [self scheduleTimer:playerTimeData];
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) suspendClock:(GoPlayerTimeData*)playerTimeData reason:(enum GoClockSuspendedReason)reason
{
  [self invalidateTimerIfOneIsScheduled:playerTimeData];

  [playerTimeData suspendClock:reason];
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) stopClockIfNotStopped:(GoPlayerTimeData*)playerTimeData
{
  [self invalidateTimerIfOneIsScheduled:playerTimeData];

  [playerTimeData stopClockIfNotStopped];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the GoPlayerTimeData object whose clock is managed by
/// @a playerClockTimer.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataForPlayerClockTimer:(PlayerClockTimer*)playerClockTimer
{
  return (self.blackPlayerClockTimer == playerClockTimer
          ? self.blackPlayerTimeData
          : self.whitePlayerTimeData);
}

// -----------------------------------------------------------------------------
/// @brief Returns the PlayerClockTimer object that manages the clock of
/// @a playerTimeData.
// -----------------------------------------------------------------------------
- (PlayerClockTimer*) playerClockTimerForPlayerTimeData:(GoPlayerTimeData*)playerTimeData
{
  return (self.blackPlayerTimeData == playerTimeData
          ? self.blackPlayerClockTimer
          : self.whitePlayerClockTimer);
}

// -----------------------------------------------------------------------------
/// @brief Schedules a timer that manages the clock of @a playerTimeData.
// -----------------------------------------------------------------------------
- (void) scheduleTimer:(GoPlayerTimeData*)playerTimeData
{
  PlayerClockTimer* playerClockTimer;
  if (playerTimeData.isTimeDataForBlackPlayer)
  {
    self.blackPlayerTimeData = playerTimeData;
    playerClockTimer = self.blackPlayerClockTimer;
  }
  else
  {
    self.whitePlayerTimeData = playerTimeData;
    playerClockTimer = self.whitePlayerClockTimer;
  }

  [playerClockTimer scheduleTimer];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the timer that manages the clock of @a playerTimeData.
// -----------------------------------------------------------------------------
- (void) invalidateTimerIfOneIsScheduled:(GoPlayerTimeData*)playerTimeData
{
  PlayerClockTimer* playerClockTimer = [self playerClockTimerForPlayerTimeData:playerTimeData];

  [playerClockTimer invalidateTimerIfOneIsScheduled];

  if (playerTimeData == self.blackPlayerTimeData)
    self.blackPlayerTimeData = nil;
  else
    self.whitePlayerTimeData = nil;
}

@end
