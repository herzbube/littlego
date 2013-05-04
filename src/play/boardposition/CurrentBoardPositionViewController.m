// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "CurrentBoardPositionViewController.h"
#import "BoardPositionView.h"
#import "BoardPositionViewMetrics.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// CurrentBoardPositionViewController.
// -----------------------------------------------------------------------------
@interface CurrentBoardPositionViewController()
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
@property(nonatomic, assign) bool allDataNeedsUpdate;
@property(nonatomic, assign) bool boardPositionViewNeedsUpdate;
@property(nonatomic, assign) bool tappingEnabledNeedsUpdate;
@property(nonatomic, assign, getter=isTappingEnabled) bool tappingEnabled;
@end


@implementation CurrentBoardPositionViewController

// -----------------------------------------------------------------------------
/// @brief Initializes a CurrentBoardPositionViewController object.
///
/// @note This is the designated initializer of
/// CurrentBoardPositionViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.delegate = nil;
  self.boardPositionViewMetrics = nil;
  [self setupTapGestureRecognizer];
  self.allDataNeedsUpdate = false;
  self.boardPositionViewNeedsUpdate = false;
  self.tappingEnabledNeedsUpdate = false;
  self.tappingEnabled = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TapGestureController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.delegate = nil;
  self.tapRecognizer = nil;
  self.boardPositionViewMetrics = nil;
  self.boardPositionView = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupTapGestureRecognizer
{
  self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)] autorelease];
  self.tapRecognizer.delegate = self;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.boardPositionView = [[[BoardPositionView alloc] initWithBoardPosition:-1
                                                                 viewMetrics:self.boardPositionViewMetrics] autorelease];
  self.view = self.boardPositionView;

	[self.boardPositionView addGestureRecognizer:self.tapRecognizer];
  [self setupNotificationResponders];

  self.allDataNeedsUpdate = true;
  self.boardPositionViewNeedsUpdate = false;
  self.tappingEnabledNeedsUpdate = true;
  self.tappingEnabled = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (void) viewWillUnload
{
  [self removeNotificationResponders];
  self.boardPositionView = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStarts:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStops:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:NSKeyValueObservingOptionOld context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tapping gesture in the view's Go board area.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;
  if (self.delegate)
    [self.delegate didTapCurrentBoardPositionViewController:self];
}

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  return self.isTappingEnabled;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  GoBoardPosition* boardPosition = oldGame.boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  GoBoardPosition* boardPosition = newGame.boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:NSKeyValueObservingOptionOld context:NULL];
  self.allDataNeedsUpdate = true;
  self.tappingEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStarts:(NSNotification*)notification
{
  self.tappingEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStops notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStops:(NSNotification*)notification
{
  self.tappingEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"currentBoardPosition"])
  {
    self.boardPositionViewNeedsUpdate = true;
    [self delayedUpdate];
  }
  else
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  [self updateAllData];
  [self updateBoardPositionView];
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Updates the information displayed by the BoardPositionView.
// -----------------------------------------------------------------------------
- (void) updateAllData
{
  if (! self.allDataNeedsUpdate)
    return;
  self.allDataNeedsUpdate = false;
  GoGame* game = [GoGame sharedGame];
  if (game)
  {
    GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
    self.boardPositionView.boardPosition = boardPosition.currentBoardPosition;
    // BoardPositionView only updates its layout if a new board position is
    // set. In this updater, however, we have to force the layout update, to cover
    // the following scenario: Old board position is 0, new game is started with
    // a different komi or handicap, new board position is again 0. The
    // BoardPositionView must display the new komi/handicap values.
    [self.boardPositionView setNeedsLayout];
  }
  else
  {
    self.boardPositionView.boardPosition = -1;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the information displayed by the BoardPositionView.
// -----------------------------------------------------------------------------
- (void) updateBoardPositionView
{
  if (! self.boardPositionViewNeedsUpdate)
    return;
  self.boardPositionViewNeedsUpdate = false;
  GoGame* game = [GoGame sharedGame];
  if (game)
  {
    GoBoardPosition* boardPosition = game.boardPosition;
    self.boardPositionView.boardPosition = boardPosition.currentBoardPosition;
  }
  else
  {
    self.boardPositionView.boardPosition = -1;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates whether tapping is enabled.
// -----------------------------------------------------------------------------
- (void) updateTappingEnabled
{
  if (! self.tappingEnabledNeedsUpdate)
    return;
  self.tappingEnabledNeedsUpdate = false;
  GoGame* game = [GoGame sharedGame];
  if (! game)
    self.tappingEnabled = false;
  else if (game.isComputerThinking)
    self.tappingEnabled = false;
  else
    self.tappingEnabled = true;
}

@end
