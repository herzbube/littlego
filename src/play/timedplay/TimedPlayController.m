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
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPlayerTimeData.h"
#import "../../go/GoTimeSettings.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../main/Registry.h"
#import "../../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TimedPlayController.
// -----------------------------------------------------------------------------
@interface TimedPlayController()
/// @brief The shared registry where this TimedPlayController
/// registers/unregisters itself.
@property(nonatomic, assign) Registry* registry;
/// @brief The timer object that, when active, periodically triggers a decrease
/// of the black player's remaining time.
@property(nonatomic, retain) PlayerClockTimer* blackPlayerClockTimer;
/// @brief The object that holds the black player's time data.
@property(nonatomic, assign) GoPlayerTimeData* blackPlayerTimeData;
/// @brief The timer object that, when active, periodically triggers a decrease
/// of the white player's remaining time.
@property(nonatomic, retain) PlayerClockTimer* whitePlayerClockTimer;
/// @brief The object that holds the white player's time data.
@property(nonatomic, assign) GoPlayerTimeData* whitePlayerTimeData;
/// @brief The GoGame object representing the current game.
@property(nonatomic, assign) GoGame* game;
@property(nonatomic, assign) bool haveSeenFirstGame;
/// @brief Is true if player's clocks are currently managed, false if not.
/// The value of this property is used by notification responders and service
/// request handlers for a quick, inexpensive check to see whether they need
/// to apply further, potentially more expensive logic.
///
/// Player clocks are managed only if the following conditions are met:
/// - If the current game uses timed play (implies that there @b IS a current
///   game), i.e. if property @e isGameUsingTimedPlay has value true.
/// - And if the current game variation has valid time data, i.e. if property
///   @e isTimeDataValid has value true.
@property(nonatomic, assign) bool arePlayerClocksManaged;
@property(nonatomic, assign) bool isGameUsingTimedPlay;
@property(nonatomic, assign) bool isTimeDataValid;
/// @brief Is true to indicate that the Go board is interactive and the user
/// (representing a human player) can currently play a move. Is false to
/// indicate that the Go board is not interactive and the user can currently
/// not play a move. Important: This property does @b NOT reflect whether it is
/// actually a human player's turn, merely that the user has interactive access
/// to the Go board.

/// This flag is true if the following conditions are met:
/// - If the UIKit scene is currently active, i.e. if property @e isSceneActive
///   has value true.
/// - And if the user (representing a human player) can currently play a move,
///   i.e. if property @e canUserPlayMove is true.
///
/// This flag is not relevant for the computer player, because the computer
/// player can think and play a move in the background.
@property(nonatomic, assign) bool isBoardInteractive;
@property(nonatomic, assign) bool isSceneActive;
/// @brief Is true if the user (representing a human player) can currently
/// play a move, false if not. Important: This property does @b NOT reflect
/// whether it is actually a human player's turn, merely that the user has
/// interactive access to the Go board.
@property(nonatomic, assign) bool canUserPlayMove;
@property(nonatomic, assign) bool isGameEnded;
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
  self.game = nil;

  self.haveSeenFirstGame = false;
  self.arePlayerClocksManaged = false;
  self.isGameUsingTimedPlay = false;
  self.isTimeDataValid = true; // TODO xxx set default to false once time data validity is checked
  self.isBoardInteractive = false;
  self.isSceneActive = false;
  self.canUserPlayMove = true; // TODO xxx set default to false once board interactivity is managed
  self.isGameEnded = false;

  self.registry.playerClockService = self;

  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimedPlayController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  self.registry.playerClockService = nil;

  [self.blackPlayerClockTimer invalidateTimerIfOneIsScheduled];
  self.blackPlayerTimeData = nil;
  self.blackPlayerClockTimer = nil;

  [self.whitePlayerClockTimer invalidateTimerIfOneIsScheduled];
  self.whitePlayerTimeData = nil;
  self.whitePlayerClockTimer = nil;

  self.game = nil;

  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(sceneWillDeactivate:) name:UISceneWillDeactivateNotification object:nil];
  [center addObserver:self selector:@selector(sceneDidActivate:) name:UISceneDidActivateNotification object:nil];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
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
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(sceneWillDeactivate:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.isSceneActive = false;
  [self updateIsBoardInteractive];

  if (! self.arePlayerClocksManaged)
    return;

  [self invalidateTimerForNextMovePlayerIfOneIsScheduled];

  GoPlayerTimeData* playerTimeData = [self nextMovePlayerTimeData];
  switch (playerTimeData.clockState)
  {
    case GoClockStateStarted:
    {
      DDLogVerbose(@"sceneWillDeactivate: Suspending clock");
      // TODO xxx Can we merge GoClockSuspendedReasonSceneDeactivated with
      // GoClockSuspendedReasonBoardNotInteractive?
      [self suspendClock:playerTimeData reason:GoClockSuspendedReasonSceneDeactivated];
      break;
    }
    case GoClockStateStopped:
    {
      DDLogVerbose(@"sceneWillDeactivate: Clock is stopped");
      break;
    }
    case GoClockStateSuspended:
    {
      DDLogVerbose(@"sceneWillDeactivate: Clock is already suspended with reason %d", playerTimeData.clockSuspendedReason);
      break;
    }
    default:
    {
      DDLogError(@"sceneWillDeactivate: Unexpected clock state %d", playerTimeData.clockState);
      break;
    }
  }
}

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
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(sceneDidActivate:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.isSceneActive = true;
  [self updateIsBoardInteractive];

  // If no game exists, then the scene is activated for the first time after
  // application launch and application setup has not finished yet. In that
  // case, delay the main part of of the scene activation handling, it will be
  // executed later when the game is created.
  if (! self.game)
    return;

  [self handleSceneDidActivateAfterFirstGameWasSeen];
}

// -----------------------------------------------------------------------------
/// @brief Extension of sceneDidActivate:().
// -----------------------------------------------------------------------------
- (void) handleSceneDidActivateAfterFirstGameWasSeen
{
  if (! self.arePlayerClocksManaged)
    return;

  GoPlayerTimeData* playerTimeData = [self nextMovePlayerTimeData];
  switch (playerTimeData.clockState)
  {
    case GoClockStateStarted:
    {
      // This should not be possible. If the scene was deactivated properly the
      // clock should be suspended. If the app crashed then GoPlayerTimeData
      // should have suspended the clock with reason = RestoredFromArchive
      // during unarchiving.
      DDLogError(@"sceneDidActivate: Clock is started");
      break;
    }
    case GoClockStateStopped:
    {
      DDLogVerbose(@"sceneDidActivate: Clock is stopped");
      break;
    }
    case GoClockStateSuspended: // Fallthrough intentional
    default: // no defensive programming special handling
    {
      switch (playerTimeData.clockSuspendedReason)
      {
        case GoClockSuspendedReasonHandleTimer:
          DDLogWarn(@"sceneDidActivate: App has crashed while timerFired was executing");
          // Fallthrough intentional
        case GoClockSuspendedReasonRestoredFromArchive:
          DDLogWarn(@"sceneDidActivate: App has crashed while clock was started");
          // Bring clock into a sane state that can be handled by the other
          // parts of this controller. We could start the clock (to more closely
          // resemble the app state before the crash), but stopping the clock
          // is more appropriate after a crash, so the user can investigate the
          // situation without time pressure. If this handling is changed,
          // update the GoClockSuspendedReasonRestoredFromArchive documentation.
          [self stopClockIfNotStopped:playerTimeData];
          break;
        case GoClockSuspendedReasonSceneDeactivated:
          // The only way how this suspend reason can be set is when the clock
          // was started during scene deactivation
          DDLogVerbose(@"sceneDidActivate: Starting clock");
          [self startClock:playerTimeData];
          break;
        case GoClockSuspendedReasonUserAction:
          // The clock was suspended by the user when the scene was deactivated
          break;
        case GoClockSuspendedReasonBoardNotInteractive:
          // We can't be 100% sure that when the scene activates it is restored
          // to the exact same "board is not interactive" state than when it
          // was deactivated, therefore it is best to stop the clock now to
          // avoid any problems with the other parts of this controller.
          //
          // TODO xxx Revisit this when self.isBoardInteractive is properly
          // managed. We may then be able to keep the clock suspended.
          DDLogVerbose(@"sceneDidActivate: Stopping clock that was suspended because board is not interactive");
          [self stopClockIfNotStopped:playerTimeData];
          break;
        case GoClockSuspendedReasonNotSuspended:
        default: // no defensive programming special handling
          break;
      }
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(goGameWillCreate:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  // Check if this is the first game to be created during the application's
  // life cycle.
  if (! self.game)
    return;

  [self invalidateTimerForNextMovePlayerIfOneIsScheduled];

  self.game = nil;
  self.blackPlayerTimeData = nil;
  self.whitePlayerTimeData = nil;

  self.isGameUsingTimedPlay = false;
  self.isTimeDataValid = false;
  self.isGameEnded = false;

  [self updateArePlayerClocksManaged];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(goGameDidCreate:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  // goGameWillCreate:() has already stopped any timers and reset some member
  // variables, so we are free to just assign

  GoGame* game = notification.object;

  self.game = game;
  self.blackPlayerTimeData = game.playerBlack.timeData;
  self.whitePlayerTimeData = game.playerWhite.timeData;

  self.isGameUsingTimedPlay = game.timeSettings.isGameUsingTimedPlay;
  self.isTimeDataValid = true; // TODO xxx set default to false once time data validity is checked
  self.isGameEnded = (game.state == GoGameStateGameHasEnded);

  [self updateArePlayerClocksManaged];

  if (self.haveSeenFirstGame)
    return;
  self.haveSeenFirstGame = true;

  // isSceneActive is true if sceneDidActivate:() already ran for the first
  // time. In that case sceneDidActivate:() skipped
  // handleSceneDidActivateAfterFirstGameWasSeen because the game was not yet
  // there, so we have to invoke it now.
  if (self.isSceneActive)
    [self handleSceneDidActivateAfterFirstGameWasSeen];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(goGameStateChanged:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.isGameEnded = (self.game.state == GoGameStateGameHasEnded);

  // No other updates necessary. Regardless of whether the game ended or if
  // play is resumed, any clock changes will be triggered via PlayerClockService
  // requests, and those request handlers will then check self.isGameEnded.

  // TODO xxx Consider making isGameEnded into a calculated property, because
  // we do have self.game that can be queried.
}

#pragma mark - PlayerClockService implementation

// -----------------------------------------------------------------------------
/// @brief PlayerClockService method.
// -----------------------------------------------------------------------------
- (void) startClockOfPlayer:(GoPlayer*)player reason:(enum PlayerClockStartReason)startReason
{
  // TODO xxx Is this guaranteed to execute on the main thread?

  if (! self.arePlayerClocksManaged)
    return;

  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return;

  switch (startReason)
  {
    case PlayerClockStartReasonHumanPlayerTurnBegins:
      // Fallthrough intentional
    case PlayerClockStartReasonComputerPlayerTurnBegins:
    {
      // If the the board is not interactive, we don't care about the human
      // player's clock state. If the clock is stopped we don't want to start
      // it, and if it is suspended there is no GoClockSuspendedReason that
      // would convince us to start it, either.
      if (startReason == PlayerClockStartReasonHumanPlayerTurnBegins &&
          ! self.isBoardInteractive)
      {
        return;
      }

      // User has suspended the clock during the previous turn (the user is
      // allowed to suspend the clock of both human and computer players). We
      // respect the user's wish indefinitely and don't turn the clock back on.
      // TODO xxx consider starting the clock, i.e. the user's wish is valid
      // for only 1 turn => can be made into a user preference
      if (playerTimeData.clockState == GoClockStateSuspended &&
          playerTimeData.clockSuspendedReason == GoClockSuspendedReasonUserAction)
      {
        return;
      }

      // The clock is expected to be never started: Before the player's turn
      // began, nobody can have started the clock because it was not that
      // player's turn.
      [self startClock:playerTimeData];
      return;
    }
    case PlayerClockStartReasonComputerPlayerStartsThinkingOnBehalfOfHumanPlayer:
    {
      // Currently we ignore the request completely.
      // - If the human player's clock is already started, we don't have to do
      //   anything.
      // - If the human player's clock is suspended for any reason (in
      //   particular because of GoClockSuspendedReasonUserAction or
      //   GoClockSuspendedReasonBoardNotInteractive), we don't want to start
      //   their clock.
      // - There is no known scenario how the human player's clock could be
      //   stopped, but if it is we don't want to change the clock state,
      //   either.
      return;
    }
    case PlayerClockStartReasonUserRequest:
    {
      // User may only change the state of the clock of the player whose turn
      // it currently is.
      if (player != self.game.nextMovePlayer)
        return;

      // User may not start the clock if the game has ended. If such a request
      // is made, the controller handling user interactions with the user
      // interface clock is lazily implemented and does not check the game
      // state. We gracefully handle this.
      if (self.isGameEnded)
        return;

      // The clock is expected to be never started. If it is, the controller
      // handling user interactions with the user interface clock made a mistake
      // => we let the app crash because we want to know about it.
      // Note that the user may also start a suspended computer player's clock.
      // The only way how a computer player's clock can be suspended is by user
      // request.
      [self startClock:playerTimeData];
      return;
    }
    default:
    {
      // TODO xxx error handling
      return;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayerClockService method.
// -----------------------------------------------------------------------------
- (enum PlayerClockServiceOperationResult) stopClockOfPlayer:(GoPlayer*)player
                                                      reason:(enum PlayerClockStopReason)stopReason
{
  // TODO xxx Is this guaranteed to execute on the main thread?

  if (! self.arePlayerClocksManaged)
    return PlayerClockServiceOperationResultGameContinues;

  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return PlayerClockServiceOperationResultGameContinues;

  switch (stopReason)
  {
    case PlayerClockStopReasonPlayerTurnEnds:
    {
      switch (playerTimeData.clockState)
      {
        case GoClockStateStarted:
          [self stopClockIfNotStopped:playerTimeData];
          if (playerTimeData.didPlayerLoseOnTime)
            return PlayerClockServiceOperationResultGameLostOnTime;
          else
            return PlayerClockServiceOperationResultGameContinues;
        case GoClockStateStopped:
          // There is no known scenario how the player's clock could be stopped,
          // but if it is we don't have to do anything.
          return PlayerClockServiceOperationResultGameContinues;
        case GoClockStateSuspended:
          // Clock remains suspended - the only thing that's important is that
          // the clock is not started when the move is submitted to GoGame, so
          // that GoGame can perform time keeping operations.
          return PlayerClockServiceOperationResultGameContinues;
      }
    }
    default:
    {
      // TODO xxx error handling
      return PlayerClockServiceOperationResultGameContinues;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayerClockService method.
// -----------------------------------------------------------------------------
- (enum PlayerClockServiceOperationResult) suspendClockOfPlayer:(GoPlayer*)player
                                                         reason:(enum PlayerClockSuspendReason)suspendReason
{
  // TODO xxx Is this guaranteed to execute on the main thread?

  if (! self.arePlayerClocksManaged)
    return PlayerClockServiceOperationResultGameContinues;

  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return PlayerClockServiceOperationResultGameContinues;

  switch (suspendReason)
  {
    case PlayerClockSuspendReasonUserRequest:
    {
      // User may only change the state of the clock of the player whose turn
      // it currently is.
      if (player != self.game.nextMovePlayer)
        return PlayerClockServiceOperationResultGameContinues;

      // The clock is expected to be started. If it is not, the controller
      // handling user interactions with the user interface clock made a mistake
      // => we let the app crash because we want to know about it.
      // Note that the user may also suspend a computer player's clock.
      [self suspendClock:playerTimeData reason:GoClockSuspendedReasonUserAction];
      if (playerTimeData.didPlayerLoseOnTime)
        return PlayerClockServiceOperationResultGameLostOnTime;
      else
        return PlayerClockServiceOperationResultGameContinues;
    }
    default:
    {
      // TODO xxx error handling
      return PlayerClockServiceOperationResultGameContinues;
    }
  }
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

  // Marks the application state as "dirty" so that time data is saved if the
  // scene deactivates. We could also save immediately, but doing that every
  // second would be too much disk activity for not enough gain. By not saving
  // immediately, we risk losing the time data if the app crashes, but that is
  // an acceptable compromise.
  [[ApplicationStateManager sharedManager] applicationStateDidChange];

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
  [[ApplicationStateManager sharedManager] applicationStateDidChange];

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
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx document
// -----------------------------------------------------------------------------
- (void) stopClockIfNotStopped:(GoPlayerTimeData*)playerTimeData
{
  [self invalidateTimerIfOneIsScheduled:playerTimeData];

  [playerTimeData stopClockIfNotStopped];
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the GoPlayerTimeData object for the player who will make the
/// next move, i.e. the player whose clock needs to be managed during the
/// current turn. Returns @e nil if no game has been created yet, or if the
/// current game does not use timed play.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) nextMovePlayerTimeData
{
  if (self.game)
    return self.game.nextMovePlayer.timeData;
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPlayerTimeData object whose clock is managed by
/// @a playerClockTimer. Returns @e nil if no game has been created yet, or if
/// the current game does not use timed play.
// -----------------------------------------------------------------------------
- (GoPlayerTimeData*) playerTimeDataForPlayerClockTimer:(PlayerClockTimer*)playerClockTimer
{
  return (self.blackPlayerClockTimer == playerClockTimer
          ? self.blackPlayerTimeData
          : self.whitePlayerTimeData);
}

// -----------------------------------------------------------------------------
/// @brief Returns the PlayerClockTimer object that manages the clock of
/// @a playerTimeData. Returns @e nil if @a playerTimeData is nil.
// -----------------------------------------------------------------------------
- (PlayerClockTimer*) playerClockTimerForPlayerTimeData:(GoPlayerTimeData*)playerTimeData
{
  if (! playerTimeData)
    return nil;

  return (playerTimeData.isTimeDataForBlackPlayer
          ? self.blackPlayerClockTimer
          : self.whitePlayerClockTimer);
}

// -----------------------------------------------------------------------------
/// @brief Schedules a timer that manages the clock of @a playerTimeData.
/// Does nothing if @a playerTimeData is nil.
// -----------------------------------------------------------------------------
- (void) scheduleTimer:(GoPlayerTimeData*)playerTimeData
{
  if (! playerTimeData)
    return;

  PlayerClockTimer* playerClockTimer = [self playerClockTimerForPlayerTimeData:playerTimeData];
  [playerClockTimer scheduleTimer];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the timer that manages the clock of the player who will
/// make the next move. Does nothing if no game has been created yet, or if
/// the current game does not use timed play.
// -----------------------------------------------------------------------------
- (void) invalidateTimerForNextMovePlayerIfOneIsScheduled
{
  GoPlayerTimeData* playerTimeData = [self nextMovePlayerTimeData];
  [self invalidateTimerIfOneIsScheduled:playerTimeData];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the timer that manages the clock of @a playerTimeData.
/// Does nothing @a playerTimeData is @e nil.
// -----------------------------------------------------------------------------
- (void) invalidateTimerIfOneIsScheduled:(GoPlayerTimeData*)playerTimeData
{
  if (! playerTimeData)
    return;

  PlayerClockTimer* playerClockTimer = [self playerClockTimerForPlayerTimeData:playerTimeData];
  [playerClockTimer invalidateTimerIfOneIsScheduled];
}

// -----------------------------------------------------------------------------
/// @brief Updates the internal property @e arePlayerClocksManaged based on
/// other states. See the documentation of @e arePlayerClocksManaged.
// -----------------------------------------------------------------------------
- (void) updateArePlayerClocksManaged
{
  // TODO xxx consider implementing setters for the properties that
  // arePlayerClocksManaged is depending on, and invoking this updater from
  // these setters. makes sure that rest of implementation cannot make any
  // mistakes
  self.arePlayerClocksManaged = (self.isGameUsingTimedPlay && self.isTimeDataValid);
}

// -----------------------------------------------------------------------------
/// @brief Updates the internal property @e isBoardInteractive based on
/// other states. See the documentation of @e isBoardInteractive.
// -----------------------------------------------------------------------------
- (void) updateIsBoardInteractive
{
  // TODO xxx consider implementing setters for the properties that
  // isBoardInteractive is depending on, and invoking this updater from
  // these setters. makes sure that rest of implementation cannot make any
  // mistakes
  self.isBoardInteractive = (self.isSceneActive && self.canUserPlayMove);
}

@end
