// -----------------------------------------------------------------------------
// Copyright 2025-2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPlayerTimeData.h"
#import "../../go/GoTimeDataValidator.h"
#import "../../go/GoTimeSettings.h"
#import "../../go/GoUtilities.h"
#import "../../play/gameaction/GameActionManager.h"
#import "../../play/model/TimedPlayModel.h"
#import "../../player/Player.h"
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../utility/ExceptionUtility.h"


// There is no enum value UIAreaPlayModeUnknown, so we fake one
static const enum UIAreaPlayMode UIAreaPlayModeUnknown = -1;


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
/// @brief The timer object that, when active, periodically triggers a decrease
/// of the white player's remaining time.
@property(nonatomic, retain) PlayerClockTimer* whitePlayerClockTimer;
/// @brief The GoGame object representing the current game.
@property(nonatomic, assign) GoGame* game;
/// @brief Is true if player's clocks are currently managed, false if not.
/// The value of this property is used by notification responders and service
/// request handlers for a quick, inexpensive check to see whether they need
/// to apply further, potentially more expensive logic.
///
/// Player clocks are managed only if the following conditions are met:
/// - If the current game uses timed play (implies that there @b IS a current
///   game), i.e. if property @e isGameUsingTimedPlay has value true.
/// - And if the current game variation has valid time data, i.e. if property
///   @e timeDataValidationResult has value true in its member
///   @e isTimeDataValid.
@property(nonatomic, assign) bool arePlayerClocksManaged;
@property(nonatomic, assign) bool isGameUsingTimedPlay;
@property(nonatomic, assign) GoTimeDataValidationResult timeDataValidationResult;
/// @brief Is true to indicate that the Go board is interactive and the user
/// (representing a human player) can currently play a move. Is false to
/// indicate that the Go board is not interactive and the user can currently
/// not play a move. Important: This property does @b NOT reflect whether it is
/// actually a human player's turn, merely that the user has interactive access
/// to the Go board.

/// This flag is true if all of the following conditions are met:
/// - The UIKit scene is currently active, i.e. property @e isSceneActive
///   has value true.
/// - The UI area "Play" is visible, i.e. property @e uiArea has value
///    #UIAreaPlay.
/// - The board view is in Play mode, i.e. property @e uiAreaPlayMode has
///   value #UIAreaPlayModePlay.
/// - Nothing is blocking board interactions, i.e. property
///   @e numberOfThingsBlockingBoardInteractions has value 0 (zero).
///
/// This flag is not relevant for the computer player, because the computer
/// player can think, and play a move, in the background.
@property(nonatomic, assign) bool isBoardInteractive;
@property(nonatomic, assign) bool isSceneActive;
@property(nonatomic, assign) enum UIArea uiArea;
@property(nonatomic, assign) enum UIAreaPlayMode uiAreaPlayMode;
/// @brief A number of things that can block user interaction with the Go board
/// are tracked with this counter.
///
/// Only things that are known to be @b NOT blocking when this controller is
/// initialized (i.e. at the application start) can be tracked with this
/// counter, because the counter is initialized at 0 (zero). For instance,
/// isSceneActive needs to be tracked separately because initially the scene
/// is @b NOT active, i.e. initially it @b IS blocking.
@property(nonatomic, assign) int numberOfThingsBlockingBoardInteractions;

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
  self.whitePlayerClockTimer = [[[PlayerClockTimer alloc] initWithDelegate:self] autorelease];
  self.game = nil;

  self.arePlayerClocksManaged = false;
  self.isGameUsingTimedPlay = false;
  self.timeDataValidationResult = GoTimeDataValidationResultInvalid;
  self.isBoardInteractive = false;
  self.isSceneActive = false;
  self.uiArea = UIAreaUnknown;
  self.uiAreaPlayMode = UIAreaPlayModeUnknown;
  self.numberOfThingsBlockingBoardInteractions = 0;

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
  self.blackPlayerClockTimer = nil;

  [self.whitePlayerClockTimer invalidateTimerIfOneIsScheduled];
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
  [center addObserver:self selector:@selector(uiAreaDidChange:) name:uiAreaDidChange object:nil];
  [center addObserver:self selector:@selector(uiAreaPlayModeWillChange:) name:uiAreaPlayModeWillChange object:nil];
  [center addObserver:self selector:@selector(uiAreaPlayModeDidChange:) name:uiAreaPlayModeDidChange object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
  [center addObserver:self selector:@selector(territoryStatisticsGenerationWillBegin:) name:territoryStatisticsGenerationWillBegin object:nil];
  [center addObserver:self selector:@selector(territoryStatisticsGenerationDidEnd:) name:territoryStatisticsGenerationDidEnd object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStarts:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStops:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(moreGameActionsPopupWillAppear:) name:moreGameActionsPopupWillAppear object:nil];
  [center addObserver:self selector:@selector(moreGameActionsPopupDidDisappear:) name:moreGameActionsPopupDidDisappear object:nil];
  [center addObserver:self selector:@selector(gameInfoScreenWillAppear:) name:gameInfoScreenWillAppear object:nil];
  [center addObserver:self selector:@selector(gameInfoScreenDidDisappear:) name:gameInfoScreenDidDisappear object:nil];
  [center addObserver:self selector:@selector(newGameScreenWillAppear:) name:newGameScreenWillAppear object:nil];
  [center addObserver:self selector:@selector(newGameScreenDidDisappear:) name:newGameScreenDidDisappear object:nil];
  [center addObserver:self selector:@selector(saveGameScreenWillAppear:) name:saveGameScreenWillAppear object:nil];
  [center addObserver:self selector:@selector(saveGameScreenDidDisappear:) name:saveGameScreenDidDisappear object:nil];
  [center addObserver:self selector:@selector(currentBoardPositionDidChange:) name:currentBoardPositionDidChange object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(playerLostOnTime:) name:playerLostOnTime object:nil];
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

  // Clock should already have been stopped, but let's play it safe
  [self stopClockIfNotStoppedAndInvalidateTimer:[self nextMovePlayerTimeData]];

  self.game = nil;

  self.isGameUsingTimedPlay = false;
  self.timeDataValidationResult = GoTimeDataValidationResultInvalid;

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
  self.isGameUsingTimedPlay = game.timeSettings.isGameUsingTimedPlay;

  // Time data existence at the moment when we receive the notification:
  // - User creates a new game from scratch: The game contains no nodes besides
  //   the root node.
  // - User loads a game from the archive, or the app restores the game by
  //   loading it from the backup .sgf: The game contains no nodes besides
  //   the root node. Later on, when the node tree has been created based on
  //   the .sgf file content, the notification currentBoardPositionDidChange
  //   will be posted.
  // - The app restores the game from an NSCoding archive: The game contains
  //   a fully established node tree.
  if (self.isGameUsingTimedPlay)
    self.timeDataValidationResult = [GoTimeDataValidator validationStateOfCurrentNode:self.game];
  else
    self.timeDataValidationResult = GoTimeDataValidationResultInvalid;

  [self updateArePlayerClocksManaged];

  // Clock state changes will be triggered via PlayerClockService requests
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #uiAreaDidChange notification.
// -----------------------------------------------------------------------------
- (void) uiAreaDidChange:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(uiAreaDidChange:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  NSNumber* uiAreaAsNumber = notification.object;
  self.uiArea = [uiAreaAsNumber intValue];

  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #uiAreaPlayModeWillChange notification.
// -----------------------------------------------------------------------------
- (void) uiAreaPlayModeWillChange:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(uiAreaPlayModeWillChange:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  // In this notification handler we only care about the change if the user
  // leaves Play mode => in that case we want to suspend the clock as soon as
  // possible because the change to the new mode may take substantial time
  // (e.g. when scoring mode is enabled the score calculation may take some
  // time, in particular when a GTP command is sent).
  if (self.uiAreaPlayMode != UIAreaPlayModePlay)
    return;

  NSArray* oldAndNewModes = notification.object;
  NSNumber* newMode = oldAndNewModes.lastObject;
  self.uiAreaPlayMode = [newMode intValue];

  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #uiAreaPlayModeDidChange notification.
// -----------------------------------------------------------------------------
- (void) uiAreaPlayModeDidChange:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(uiAreaPlayModeDidChange:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  NSArray* oldAndNewModes = notification.object;
  NSNumber* newMode = oldAndNewModes.lastObject;
  self.uiAreaPlayMode = [newMode intValue];

  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(boardViewAnimationWillBegin:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions++;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(boardViewAnimationDidEnd:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions--;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #territoryStatisticsGenerationWillBegin notification.
// -----------------------------------------------------------------------------
- (void) territoryStatisticsGenerationWillBegin:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(territoryStatisticsGenerationWillBegin:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions++;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #territoryStatisticsGenerationDidEnd notification.
// -----------------------------------------------------------------------------
- (void) territoryStatisticsGenerationDidEnd:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(territoryStatisticsGenerationDidEnd:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions--;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStarts:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(computerPlayerThinkingStarts:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  NSArray* notificationObject = notification.object;
  NSNumber* reasonAsNumber = [notificationObject objectAtIndex:1];
  enum GoGameComputerIsThinkingReason reason = [reasonAsNumber intValue];
  if (reason == GoGameComputerIsThinkingReasonMoveSuggestion)
  {
    // Fuego's handler for the "reg_genmove" GTP command ignores the clock (see
    // GoGtpEngine::CmdRegGenMove()), instead it operates with the
    // fuegoMaxThinkingTime time limit (see GtpEngineProfile). Because of this,
    // we cannot let the time that Fuego uses to generate the move suggestion be
    // deducted from the player's remaining time - it may cause the player to
    // lose on time.
    self.numberOfThingsBlockingBoardInteractions++;
    [self updateIsBoardInteractive];
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStops notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStops:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(computerPlayerThinkingStops:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  NSArray* notificationObject = notification.object;
  NSNumber* reasonAsNumber = [notificationObject objectAtIndex:1];
  enum GoGameComputerIsThinkingReason reason = [reasonAsNumber intValue];
  if (reason == GoGameComputerIsThinkingReasonMoveSuggestion)
  {
    // See computerPlayerThinkingStarts:() why this is needed
    self.numberOfThingsBlockingBoardInteractions--;
    [self updateIsBoardInteractive];
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #moreGameActionsPopupWillAppear notification.
// -----------------------------------------------------------------------------
- (void) moreGameActionsPopupWillAppear:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(moreGameActionsPopupWillAppear:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions++;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #moreGameActionsPopupDidDisappear notification.
// -----------------------------------------------------------------------------
- (void) moreGameActionsPopupDidDisappear:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(moreGameActionsPopupDidDisappear:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions--;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gameInfoScreenWillAppear notification.
// -----------------------------------------------------------------------------
- (void) gameInfoScreenWillAppear:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(gameInfoScreenWillAppear:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions++;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gameInfoScreenDidDisappear notification.
// -----------------------------------------------------------------------------
- (void) gameInfoScreenDidDisappear:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(gameInfoScreenDidDisappear:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions--;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #newGameScreenWillAppear notification.
// -----------------------------------------------------------------------------
- (void) newGameScreenWillAppear:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(newGameScreenWillAppear:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions++;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #newGameScreenDidDisappear notification.
// -----------------------------------------------------------------------------
- (void) newGameScreenDidDisappear:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(newGameScreenDidDisappear:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions--;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #saveGameScreenWillAppear notification.
// -----------------------------------------------------------------------------
- (void) saveGameScreenWillAppear:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(saveGameScreenWillAppear:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions++;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #saveGameScreenDidDisappear notification.
// -----------------------------------------------------------------------------
- (void) saveGameScreenDidDisappear:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(saveGameScreenDidDisappear:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.numberOfThingsBlockingBoardInteractions--;
  [self updateIsBoardInteractive];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentBoardPositionDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentBoardPositionDidChange:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(currentBoardPositionDidChange:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  if (! self.isGameUsingTimedPlay)
    return;

  // When do we receive this notification?
  // - When the user selects a different node (= changes the board position)
  //   within the same game variation.
  // - When the user selects a different node in a different game variation.
  //   In this case we receive the notification twice: First when an internal
  //   board position change is performed to select the branching node where
  //   the old and new game variations differ. Then, after the game variation
  //   has been changed, when the board position of the new game variation is
  //   changed to the target node selected by the user.
  // - When GoGame generates a new node for a move that is being played. In
  //   this scenario updateAllPlayerTimeDataToMatchCurrentlySelectedNode would
  //   not be necessary because the time data of the player who just made the
  //   move should already be up-to-date, and the time data of the other player
  //   does not need updating. At the moment, it is not possible to detect
  //   the reason for the node change, though, so we have no choice but to
  //   perform the update.
  //
  // We don't receive this notification if the current game variation changes
  // but the current node does not change. In that case the time validity does
  // not change, because that is tied to the situation at the current node.
  self.timeDataValidationResult = [GoTimeDataValidator validationStateOfCurrentNode:self.game];

  [self updateArePlayerClocksManaged];

  if (self.arePlayerClocksManaged)
    [self updateAllPlayerTimeDataToMatchCurrentlySelectedNode];
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

  if (! self.isGameEnded)
    return;

  if (! self.arePlayerClocksManaged)
    return;

  // If the game ends for any reason we want to stop all suspended clocks, to
  // avoid any risk of them being started accidentally. A start by the user is
  // impossible (see handling of PlayerClockStartReasonUserRequest), but there
  // might be edge cases where the "board not interactive" handling in this
  // controller could lead to a clock being started again.
  // Also, the user interface clock rendering of a suspended clock is plain
  // counter-intuitive once a game has ended.
  [self stopAllClocksIfNotStoppedAndInvalidateTimers];

  // Needs to be invoked because LoadGameCommand applies the game result only
  // AFTER it sets the current board position. If the game ends due to a player
  // losing on time, then we would not need to invoke this, but it also does
  // not hurt (actually it's expected to be a NOP because remaining time is
  // already zero).
  [self setZeroRemainingTimeAfterLastMoveWhenLostOnTime];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #playerLostOnTime notification.
// -----------------------------------------------------------------------------
- (void) playerLostOnTime:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(playerLostOnTime:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  // The GTP engine may have already stopped thinking and is now waiting to
  // deliver the GTP response on the main thread (which is blocked by this
  // method). If that is the case, the interrupt GTP command will be queued,
  // and when it will eventually be processed it will simply have no effect.
  // After this method returns the GTP engine will be unblocked and deliver its
  // response on the main thread. Whoever submitted the GTP command must then
  // be able to cope with the game having ended.
  if (self.game.isComputerThinking)
    [[GameActionManager sharedGameActionManager] interrupt:self];

  // Defensive programming here! It should be impossible for the game to have
  // ended, because all the possible actions that could end the game should
  // have already stopped the player clock BEFORE ending the game. Meaning that
  // the playerLostOnTime notification cannot be sent AFTER ending the game by
  // any other reason.
  if (self.isGameEnded)
  {
    DDLogWarn(@"%@: Received playerLostOnTime notification, but game has already ended with reason %d", self, self.game.reasonForGameHasEnded);
    [self.game revertStateFromEndedToInProgress:false];
  }

  GoPlayerTimeData* playerTimeData = notification.object;
  enum GoGameHasEndedReason reason = (playerTimeData.isTimeDataForBlackPlayer
                                      ? GoGameHasEndedReasonWhiteWinsOnTime
                                      : GoGameHasEndedReasonBlackWinsOnTime);
  [self.game endGameWithReason:reason updateGameResultIfNecessary:true];
}

#pragma mark - PlayerClockService implementation

// -----------------------------------------------------------------------------
/// @brief PlayerClockService method.
// -----------------------------------------------------------------------------
- (void) startClockOfPlayer:(GoPlayer*)player
                     reason:(enum PlayerClockStartReason)startReason
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self startClockOfPlayer:player reason:startReason];
    });
    return;
  }

  if (! self.arePlayerClocksManaged)
    return;

  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return;

  switch (startReason)
  {
    case PlayerClockStartReasonNewGameHumanPlayerTurnBegins:
    case PlayerClockStartReasonLoadGameHumanPlayerTurnBegins:
    case PlayerClockStartReasonHumanPlayerTurnBegins:
      // Fallthrough intentional
    case PlayerClockStartReasonComputerPlayerTurnBegins:
    {
      // When the user is navigating back and forth inside a game variation
      // where the game has ended, we will receive requests for starting the
      // human player's clock when the user selects an appropriate node.
      // Starting a clock when the game has ended must be prevented.
      if (self.isGameEnded)
        return;

      // User has suspended the clock during the previous turn (the user is
      // allowed to suspend the clock of both human and computer players). We
      // respect the user's wish indefinitely and don't turn the clock back on.
      if (playerTimeData.clockState == GoClockStateSuspended &&
          playerTimeData.clockSuspendedReason == GoClockSuspendedReasonUserAction)
      {
        return;
      }

      // From this point onwards: The clock can only be stopped.
      // - It cannot be started because before the player's turn began, nobody
      //   can have started the clock because it was not that player's turn.
      // - It cannot be suspended because before the player's turn began, nobody
      //   can have suspended the clock because it was not that player's turn.
      //   GoClockSuspendedReasonUserAction is the only exception, and that was
      //   handled above.
      assert(playerTimeData.clockState == GoClockStateStopped);

      bool humanPlayerTurnBegins = (startReason != PlayerClockStartReasonComputerPlayerTurnBegins);
      if (humanPlayerTurnBegins)
      {
        TimedPlayModel* timedPlayModel = [Registry sharedRegistry].modelProvider.timedPlayModel;
        if ((startReason == PlayerClockStartReasonNewGameHumanPlayerTurnBegins && ! timedPlayModel.autostartPlayerClockForNewGames) ||
            (startReason == PlayerClockStartReasonLoadGameHumanPlayerTurnBegins && ! timedPlayModel.autostartPlayerClockForArchiveGames) ||
            (startReason == PlayerClockStartReasonHumanPlayerTurnBegins && ! timedPlayModel.autostartPlayerClockWhenTurnBegins))
        {
          [self suspendClockIfNotSuspendedAndInvalidateTimer:playerTimeData
                                                      reason:GoClockSuspendedReasonUserPreferences];
          return;
        }
      }

      // If the the board is not interactive, and the clock is stopped, then
      // we "almost start" the clock - we suspend it. This has the same result
      // as if the clock were started and the board became non-interactive.
      if (humanPlayerTurnBegins &&
          ! self.isBoardInteractive &&
          playerTimeData.clockState == GoClockStateStopped)
      {
        [self suspendClockIfNotSuspendedAndInvalidateTimer:playerTimeData
                                                    reason:GoClockSuspendedReasonBoardNotInteractive];
        return;
      }

      [self startClockAndScheduleTimer:playerTimeData];
      return;
    }
    case PlayerClockStartReasonComputerPlayerStartsThinkingOnBehalfOfHumanPlayer:
    {
      // Currently we ignore the request completely.
      // - If the human player's clock is already started, we don't have to do
      //   anything.
      // - If the human player's clock is suspended for any reason (in
      //   particular because of GoClockSuspendedReasonUserAction,
      //   GoClockSuspendedReasonUserPreferences or
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

      // User may not start any clock if the game has ended => game must be
      // resumed first
      if (self.isGameEnded)
        return;

      // User may not start the clock of a computer player who is not thinking.
      //
      // Two reasons:
      // - It would simply not be correct to let the computer player's time run
      //   out without it being able to think.
      // - Also, the app would crash if we were to start the clock here, and the
      //   user would then trigger the computer player afterwards (starting an
      //   already started clock).
      //
      // This covers (at least) two cases:
      // - Computer vs. computer game that is paused.
      // - Human vs. computer game, when the user has selected a node that
      //   is not the leaf node where the next player to move would be the
      //   computer player, but thinking has not triggered yet.
      if (self.game.nextMovePlayerIsComputerPlayer && ! self.isComputerThinking)
        return;

      // Avoid starting the clock accidentally if the user cannot interact with
      // the board to play a move. Example: If the "Play" UI area is in scoring
      // mode the clock is suspended, but the user can tap the clock in an
      // attempt to start it => we don't want the clock to start because the
      // user cannot play a move in scoring mode.
      if (playerTimeData.clockSuspendedReason == GoClockSuspendedReasonBoardNotInteractive)
        return;

      // The clock is expected to be never started. If it is, the controller
      // handling user interactions with the user interface clock made a mistake
      // => we let the app crash because we want to know about it.
      // Note that the user may also start a suspended computer player's clock.
      // The only way how a computer player's clock can be suspended is by user
      // request.
      [self startClockAndScheduleTimer:playerTimeData];
      return;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"startClockOfPlayer failed, unknown startReason = %d", startReason];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
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
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    __block enum PlayerClockServiceOperationResult result;
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [self stopClockOfPlayer:player reason:stopReason];
    });
    return result;
  }

  if (! self.arePlayerClocksManaged)
    return PlayerClockServiceOperationResultGameContinues;

  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return PlayerClockServiceOperationResultGameContinues;

  switch (stopReason)
  {
    case PlayerClockStopReasonPlayerTurnEnds:
    case PlayerClockStopReasonPlayerResigns:
    case PlayerClockStopReasonSelectedNodeChanges:
    case PlayerClockStopReasonNewGameWillBeCreated:
    {
      switch (playerTimeData.clockState)
      {
        case GoClockStateStarted:
          [self stopClockIfNotStoppedAndInvalidateTimer:playerTimeData];
          if (playerTimeData.didPlayerLoseOnTime)
            return PlayerClockServiceOperationResultGameLostOnTime;
          else
            return PlayerClockServiceOperationResultGameContinues;
        case GoClockStateStopped:
          // Known scenario: The computer player took too long to play a move
          if (playerTimeData.didPlayerLoseOnTime)
            return PlayerClockServiceOperationResultGameLostOnTime;
          else
            return PlayerClockServiceOperationResultGameContinues;
        case GoClockStateSuspended:
          // User has suspended the clock (the user is allowed to suspend the
          // clock of both human and computer players). We respect the user's
          // wish indefinitely and don't stop the clock so that it doesn't
          // turn back on when it's the player's next turn. The only exception
          // is if a player resigns - in that case the game ends and the user
          // must not be able to start the clock again manually
          // (PlayerClockStartReasonUserRequest).
          if (playerTimeData.clockSuspendedReason == GoClockSuspendedReasonUserAction &&
              stopReason != PlayerClockStopReasonPlayerResigns)
          {
            return PlayerClockServiceOperationResultGameContinues;
          }

          // In all other scenarios we stop the clock, for these reasons:
          // - Because there simply is no reason to keep the clock suspended.
          //   If the reason for suspension is still in force when it's the
          //   player's next turn (e.g. board is still not interactive, or user
          //   preference still prevents the clock from being started), the
          //   player's clock will again go from stopped to suspended.
          // - Because keeping the clock suspended would require all sorts of
          //   special case handling in startClockOfPlayer:reason:().
          [self stopClockIfNotStoppedAndInvalidateTimer:playerTimeData];
          return PlayerClockServiceOperationResultGameContinues;
      }
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"stopClockOfPlayer failed, unknown stopReason = %d", stopReason];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
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
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    __block enum PlayerClockServiceOperationResult result;
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [self suspendClockOfPlayer:player reason:suspendReason];
    });
    return result;
  }

  if (! self.arePlayerClocksManaged)
    return PlayerClockServiceOperationResultGameContinues;

  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return PlayerClockServiceOperationResultGameContinues;

  switch (suspendReason)
  {
    case PlayerClockSuspendReasonUserRequest:
    {
      TimedPlayModel* timedPlayModel = [Registry sharedRegistry].modelProvider.timedPlayModel;
      if (! timedPlayModel.canUserSuspendPlayerClocks)
        return PlayerClockServiceOperationResultGameContinues;

      // User may only change the state of the clock of the player whose turn
      // it currently is.
      if (player != self.game.nextMovePlayer)
        return PlayerClockServiceOperationResultGameContinues;

      // The clock is expected to be started. If it is not, the controller
      // handling user interactions with the user interface clock made a mistake
      // => we let the app crash because we want to know about it.
      // Note that the user may also suspend a computer player's clock.
      [self suspendClockIfNotSuspendedAndInvalidateTimer:playerTimeData
                                                  reason:GoClockSuspendedReasonUserAction];
      if (playerTimeData.didPlayerLoseOnTime)
        return PlayerClockServiceOperationResultGameLostOnTime;
      else
        return PlayerClockServiceOperationResultGameContinues;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"suspendClockOfPlayer failed, unknown suspendReason = %d", suspendReason];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
      return PlayerClockServiceOperationResultGameContinues;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayerClockService method.
// -----------------------------------------------------------------------------
- (void) resetClockOfPlayer:(GoPlayer*)player
                     reason:(enum PlayerClockResetReason)resetReason
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self resetClockOfPlayer:player reason:resetReason];
    });
    return;
  }

  if (! self.arePlayerClocksManaged)
    return;

  GoPlayerTimeData* playerTimeData = player.timeData;
  if (! playerTimeData)
    return;

  switch (resetReason)
  {
    case PlayerClockResetReasonRevertLostOnTime:
    {
      if (player != self.game.nextMovePlayer)
        return;

      GoBoardPosition* boardPosition = self.game.boardPosition;
      GoNode* currentNode = boardPosition.currentNode;
      [playerTimeData updateAfterNodeChanged:currentNode];

      return;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"resetClockOfPlayer failed, unknown resetReason = %d", resetReason];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
      return;
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

  [playerTimeData suspendClockIfNotSuspended:GoClockSuspendedReasonHandleTimer];

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
/// @brief Starts the clock encapsulated by @a playerTimeData and schedules a
/// timer to trigger future clock countdowns.
///
/// This is an internal helper method. It does not perform any kind of
/// validation (e.g. clock state) - this is the responsibility of the caller.
/// If the validation is performed poorly, this method may raise an exception.
// -----------------------------------------------------------------------------
- (void) startClockAndScheduleTimer:(GoPlayerTimeData*)playerTimeData
{
  [playerTimeData startClock];
  [[ApplicationStateManager sharedManager] applicationStateDidChange];

  // In case the timer fires exactly at the interval: By scheduling the timer
  // AFTER the clock has started, we can be sure that the clock will NOT see
  // that less than one second have elapsed.
  [self scheduleTimer:playerTimeData];
}

// -----------------------------------------------------------------------------
/// @brief Suspends the clock encapsulated by @a playerTimeData and invalidates
/// a timer if one is scheduled.
///
/// This is an internal helper method. It does not perform any kind of
/// validation (e.g. clock state) - this is the responsibility of the caller.
/// If the validation is performed poorly, this method may raise an exception.
// -----------------------------------------------------------------------------
- (void) suspendClockIfNotSuspendedAndInvalidateTimer:(GoPlayerTimeData*)playerTimeData
                                               reason:(enum GoClockSuspendedReason)reason
{
  [self invalidateTimerIfOneIsScheduled:playerTimeData];

  [playerTimeData suspendClockIfNotSuspended:reason];
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
}

// -----------------------------------------------------------------------------
/// @brief Stops the clock encapsulated by @a playerTimeData and invalidates
/// a timer if one is scheduled.
///
/// This is an internal helper method. It does not perform any kind of
/// validation (e.g. clock state) - this is the responsibility of the caller.
/// If the validation is performed poorly, this method may raise an exception.
// -----------------------------------------------------------------------------
- (void) stopClockIfNotStoppedAndInvalidateTimer:(GoPlayerTimeData*)playerTimeData
{
  [self invalidateTimerIfOneIsScheduled:playerTimeData];

  [playerTimeData stopClockIfNotStopped];
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
}

// -----------------------------------------------------------------------------
/// @brief Stops both players' clocks and invalidates any timers that may be
/// scheduled.
///
/// This is an internal helper method. It does not perform any kind of
/// validation (e.g. clock state) - this is the responsibility of the caller.
/// If the validation is performed poorly, this method may raise an exception.
// -----------------------------------------------------------------------------
- (void) stopAllClocksIfNotStoppedAndInvalidateTimers
{
  GoPlayerTimeData* blackPlayerTimeData = self.game.playerBlack.timeData;
  [self stopClockIfNotStoppedAndInvalidateTimer:blackPlayerTimeData];

  GoPlayerTimeData* whitePlayerTimeData = self.game.playerWhite.timeData;
  [self stopClockIfNotStoppedAndInvalidateTimer:whitePlayerTimeData];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if the current game has ended, false if not.
// -----------------------------------------------------------------------------
- (bool) isGameEnded
{
  if (self.game)
    return (self.game.state == GoGameStateGameHasEnded);
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the current game is a computer vs. computer game
/// that is paused. Returns false if the current game is a computer vs.
/// computer game that is not paused, or if the current game is not a computer
/// vs. computer game.
// -----------------------------------------------------------------------------
- (bool) isComputerVsComputerGamePaused
{
  if (self.game)
    return (self.game.state == GoGameStateGameIsPaused);
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the computer player is currently thinking, false if
/// not.
// -----------------------------------------------------------------------------
- (bool) isComputerThinking
{
  if (self.game)
    return (self.game.isComputerThinking);
  else
    return false;
}

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
          ? self.game.playerBlack.timeData
          : self.game.playerWhite.timeData);
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
/// @brief Updates the PlayerTimeData objects for both players to match their
/// respective situation at the currently selected node in the current game
/// variation.
// -----------------------------------------------------------------------------
- (void) updateAllPlayerTimeDataToMatchCurrentlySelectedNode
{
  GoBoardPosition* boardPosition = self.game.boardPosition;
  GoNode* currentNode = boardPosition.currentNode;

  GoPlayerTimeData* blackPlayerTimeData = self.game.playerBlack.timeData;
  [blackPlayerTimeData updateAfterNodeChanged:currentNode];

  GoPlayerTimeData* whitePlayerTimeData = self.game.playerWhite.timeData;
  [whitePlayerTimeData updateAfterNodeChanged:currentNode];

  [self setZeroRemainingTimeAfterLastMoveWhenLostOnTime];
}

// -----------------------------------------------------------------------------
/// @brief Updates the internal property @e arePlayerClocksManaged based on
/// other states. See the documentation of @e arePlayerClocksManaged.
// -----------------------------------------------------------------------------
- (void) updateArePlayerClocksManaged
{
  // self.isGameUsingTimedPlay only changes when a new game is created. If it
  // has value false then there are no player clocks at all.
  //
  // self.timeDataValidationResult changes when a new game is created, and when
  // the current node selection changes.
  bool newArePlayerClocksManaged = (self.isGameUsingTimedPlay &&
                                    self.timeDataValidationResult.isTimeDataValid);
  if (self.arePlayerClocksManaged == newArePlayerClocksManaged)
    return;

  self.arePlayerClocksManaged = newArePlayerClocksManaged;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  if (self.timeDataValidationResult.isTimeDataValid)
  {
    [center postNotificationName:timeDataDidBecomeValid object:nil];
  }
  else
  {
    if (self.isGameUsingTimedPlay)
      [self stopAllClocksIfNotStoppedAndInvalidateTimers];

    [center postNotificationName:timeDataDidBecomeInvalid object:nil];
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the internal property @e isBoardInteractive based on
/// other states. See the documentation of @e isBoardInteractive. Updates the
/// human player's clock if it is their turn and if the property value changes.
// -----------------------------------------------------------------------------
- (void) updateIsBoardInteractive
{
  bool newIsBoardInteractive = (self.isSceneActive &&
                                self.uiArea == UIAreaPlay &&
                                self.uiAreaPlayMode == UIAreaPlayModePlay &&
                                self.numberOfThingsBlockingBoardInteractions == 0);
  if (self.isBoardInteractive == newIsBoardInteractive)
    return;

  self.isBoardInteractive = newIsBoardInteractive;

  if (! self.arePlayerClocksManaged)
    return;

  GoPlayer* nextMovePlayer = self.game.nextMovePlayer;
  if (! nextMovePlayer.player.isHuman)
    return;

  GoPlayerTimeData* playerTimeData = nextMovePlayer.timeData;
  if (self.isBoardInteractive)
  {
    switch (playerTimeData.clockSuspendedReason)
    {
      case GoClockSuspendedReasonHandleTimer:
        DDLogWarn(@"updateIsBoardInteractive: App has crashed while timerFired was executing");
        // Fallthrough intentional
      case GoClockSuspendedReasonRestoredFromArchive:
        DDLogWarn(@"updateIsBoardInteractive: App has crashed while clock was started");
        // Bring clock into a sane state that can be handled by the other
        // parts of this controller. We could start the clock (to more closely
        // resemble the app state before the crash), but stopping the clock
        // is more appropriate after a crash, so the user can investigate the
        // situation without time pressure. If this handling is changed,
        // update the GoClockSuspendedReasonRestoredFromArchive documentation.
        [self stopClockIfNotStoppedAndInvalidateTimer:playerTimeData];
        break;
      case GoClockSuspendedReasonBoardNotInteractive:
        DDLogVerbose(@"updateIsBoardInteractive: Starting clock that was suspended because board is not interactive");
        [self startClockAndScheduleTimer:playerTimeData];
        break;
      case GoClockSuspendedReasonUserAction:
      case GoClockSuspendedReasonUserPreferences:
        break;
      case GoClockSuspendedReasonNotSuspended:
        // Either clock is already started (should not be possible, but if it
        // is we leave it started), or it is stopped (we don't want to start
        // it).
        break;
      default: // no defensive programming special handling
        break;
    }
  }
  else
  {
    if (playerTimeData.clockState == GoClockStateStarted)
    {
      [self suspendClockIfNotSuspendedAndInvalidateTimer:playerTimeData
                                                  reason:GoClockSuspendedReasonBoardNotInteractive];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets the player clock to display zero remaining time if all
/// conditions are met.
// -----------------------------------------------------------------------------
- (void) setZeroRemainingTimeAfterLastMoveWhenLostOnTime
{
  // See documentation of property for a full explanation why this setting
  // exists.
  if ([Registry sharedRegistry].modelProvider.timedPlayModel.showTrueRemainingTimeAfterLastMoveWhenLostOnTime)
    return;

  GoPlayerTimeData* playerTimeDataLostOnTime = nil;
  switch (self.game.reasonForGameHasEnded)
  {
    case GoGameHasEndedReasonWhiteWinsOnTime:
      playerTimeDataLostOnTime = self.game.playerBlack.timeData;
      break;
    case GoGameHasEndedReasonBlackWinsOnTime:
      playerTimeDataLostOnTime = self.game.playerWhite.timeData;
      break;
    default:
      return;
  }

  GoBoardPosition* boardPosition = self.game.boardPosition;
  GoNode* currentNode = boardPosition.currentNode;
  if ([GoUtilities nodeWithNextMoveExists:currentNode inCurrentGameVariation:self.game])
    return;

  [playerTimeDataLostOnTime updateAfterPlayerLostOnTime];
}

@end
