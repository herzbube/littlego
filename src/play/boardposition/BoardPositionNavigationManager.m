// -----------------------------------------------------------------------------
// Copyright 2015-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionNavigationManager.h"
#import "../model/BoardViewModel.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionNavigationManager.
// -----------------------------------------------------------------------------
@interface BoardPositionNavigationManager()
@property(nonatomic, assign) bool isForwardNavigationEnabled;
@property(nonatomic, assign) bool isBackwardNavigationEnabled;
@property(nonatomic, assign) bool navigationStatesNeedUpdate;
@end


@implementation BoardPositionNavigationManager

#pragma mark - Shared handling

// -----------------------------------------------------------------------------
/// @brief Shared instance of BoardPositionNavigationManager.
// -----------------------------------------------------------------------------
static BoardPositionNavigationManager* sharedNavigationManager = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared BoardPositionNavigationManager object.
// -----------------------------------------------------------------------------
+ (BoardPositionNavigationManager*) sharedNavigationManager
{
  @synchronized(self)
  {
    if (! sharedNavigationManager)
      sharedNavigationManager = [[BoardPositionNavigationManager alloc] init];
    return sharedNavigationManager;
  }
}

// -----------------------------------------------------------------------------
/// @brief Releases the shared BoardPositionNavigationManager object.
// -----------------------------------------------------------------------------
+ (void) releaseSharedNavigationManager
{
  @synchronized(self)
  {
    if (sharedNavigationManager)
    {
      [sharedNavigationManager release];
      sharedNavigationManager = nil;
    }
  }
}

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionNavigationManager object.
///
/// @note This is the designated initializer of BoardPositionNavigationManager.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.delegate = nil;
  self.isForwardNavigationEnabled = false;
  self.isBackwardNavigationEnabled = false;
  // It's possible that this initializer runs rather late, i.e. after the
  // initial GoGame was created, so we need to schedule an update now
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
  [self setupNotificationResponders];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionNavigationManager
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.delegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillStart:) name:boardViewPanningGestureWillStart object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillEnd:) name:boardViewPanningGestureWillEnd object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  GoBoardPosition* boardPosition = oldGame.boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  GoBoardPosition* boardPosition = newGame.boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillStart notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillStart:(NSNotification*)notification
{
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillEnd:(NSNotification*)notification
{
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
{
  self.navigationStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == [GoGame sharedGame].boardPosition)
  {
    if ([keyPath isEqualToString:@"currentBoardPosition"])
      self.navigationStatesNeedUpdate = true;
    else if ([keyPath isEqualToString:@"numberOfBoardPositions"])
      self.navigationStatesNeedUpdate = true;
    [self delayedUpdate];
  }
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(delayedUpdate) withObject:nil waitUntilDone:YES];
    return;
  }
  [self updateNavigationStates];
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of all board position navigation controls.
// -----------------------------------------------------------------------------
- (void) updateNavigationStates
{
  if (! self.navigationStatesNeedUpdate)
    return;
  self.navigationStatesNeedUpdate = false;

  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (! game ||
      game.isComputerThinking ||
      game.score.scoringInProgress ||
      appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    self.isForwardNavigationEnabled = false;
    self.isBackwardNavigationEnabled = false;
    if (self.delegate)
    {
      [self.delegate boardPositionNavigationManager:self
                                   enableNavigation:NO
                                        inDirection:BoardPositionNavigationDirectionAll];
    }
  }
  else
  {
    self.isBackwardNavigationEnabled = !game.boardPosition.isFirstPosition;
    self.isForwardNavigationEnabled = !game.boardPosition.isLastPosition;
    if (self.delegate)
    {
      [self.delegate boardPositionNavigationManager:self
                                   enableNavigation:(self.isBackwardNavigationEnabled ? YES : NO)
                                        inDirection:BoardPositionNavigationDirectionBackward];
      [self.delegate boardPositionNavigationManager:self
                                   enableNavigation:(self.isForwardNavigationEnabled ? YES : NO)
                                        inDirection:BoardPositionNavigationDirectionForward];
    }
  }
}

#pragma mark - Query navigation state

// -----------------------------------------------------------------------------
/// @brief Returns the enabled state that board position navigation controls
/// which "point" in the specified direction should have.
// -----------------------------------------------------------------------------
- (BOOL) isNavigationEnabledInDirection:(enum BoardPositionNavigationDirection)direction
{
  switch (direction)
  {
    case BoardPositionNavigationDirectionForward:
    {
      return (self.isForwardNavigationEnabled ? YES : NO);
    }
    case BoardPositionNavigationDirectionBackward:
    {
      return (self.isBackwardNavigationEnabled ? YES : NO);
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"BoardPositionNavigationDirection is invalid: %d", direction];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "rewind to start" button.
// -----------------------------------------------------------------------------
- (void) rewindToStart:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring board position change", self);
    return;
  }
  [[[[ChangeBoardPositionCommand alloc] initWithFirstBoardPosition] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "previous board position" button.
// -----------------------------------------------------------------------------
- (void) previousBoardPosition:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring board position change", self);
    return;
  }
  [[[[ChangeBoardPositionCommand alloc] initWithOffset:-1] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "next board position" button.
// -----------------------------------------------------------------------------
- (void) nextBoardPosition:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring board position change", self);
    return;
  }
  [[[[ChangeBoardPositionCommand alloc] initWithOffset:1] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "fast forward to end" button.
// -----------------------------------------------------------------------------
- (void) fastForwardToEnd:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring board position change", self);
    return;
  }
  [[[[ChangeBoardPositionCommand alloc] initWithLastBoardPosition] autorelease] submit];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if taps that trigger one of the navigation operations
/// should currently be ignored.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreTaps
{
  return [GoGame sharedGame].isComputerThinking;
}

@end
