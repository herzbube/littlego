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
#import "BoardPositionListViewController.h"
#import "BoardPositionView.h"
#import "BoardPositionViewMetrics.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionListViewController.
// -----------------------------------------------------------------------------
@interface BoardPositionListViewController()
@property(nonatomic, assign) ItemScrollView* boardPositionListView;
@property(nonatomic, assign) bool allDataNeedsUpdate;
@property(nonatomic, assign) bool currentBoardPositionNeedsUpdate;
@property(nonatomic, assign) int oldBoardPosition;
@property(nonatomic, assign) bool numberOfItemsNeedsUpdate;
@property(nonatomic, assign) bool tappingEnabledNeedsUpdate;
@end


@implementation BoardPositionListViewController

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionListViewController object.
///
/// @note This is the designated initializer of BoardPositionListViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.boardPositionListView = nil;
  self.allDataNeedsUpdate = false;
  self.currentBoardPositionNeedsUpdate = false;
  self.oldBoardPosition = -1;
  self.numberOfItemsNeedsUpdate = false;
  self.tappingEnabledNeedsUpdate = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionListViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.boardPositionListView = nil;
  self.boardPositionViewMetrics = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.boardPositionListView = [[[ItemScrollView alloc] initWithFrame:CGRectZero
                                                          orientation:ItemScrollViewOrientationHorizontal] autorelease];
  self.view = self.boardPositionListView;
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.view.backgroundColor = [UIColor clearColor];
  self.boardPositionListView.itemScrollViewDelegate = self;
  self.boardPositionListView.itemScrollViewDataSource = self;

  [self setupNotificationResponders];

  self.allDataNeedsUpdate = true;
  self.currentBoardPositionNeedsUpdate = true;
  self.oldBoardPosition = -1;
  self.numberOfItemsNeedsUpdate = false;
  self.tappingEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStarts:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStops:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:NSKeyValueObservingOptionOld context:NULL];
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
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:NSKeyValueObservingOptionOld context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  self.allDataNeedsUpdate = true;
  // currentBoardPosition also needs update to cover the case where the app
  // launches and we need to display a non-zero board position right after a
  // game is created
  self.currentBoardPositionNeedsUpdate = true;
  self.oldBoardPosition = -1;
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
/// @brief Responds to the #goScoreCalculationStarts notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  self.tappingEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
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
    // The old board position is used to find the BoardPositionView whose
    // currentBoardPosition flag needs to be cleared. If several notifications
    // are received while updates are delayed, the old board position in the
    // first notification is the one we need to remember, since the follow-up
    // notifications never caused a BoardPositionView to be updated.
    if (! self.currentBoardPositionNeedsUpdate)
      self.oldBoardPosition = [[change objectForKey:NSKeyValueChangeOldKey] intValue];
    self.currentBoardPositionNeedsUpdate = true;
    [self delayedUpdate];
  }
  else if ([keyPath isEqualToString:@"numberOfBoardPositions"])
  {
    self.numberOfItemsNeedsUpdate = true;
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
  [self updateCurrentBoardPosition];
  [self updateNumberOfItems];
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
///
/// Reloads all data in the board position list view.
// -----------------------------------------------------------------------------
- (void) updateAllData
{
  if (! self.allDataNeedsUpdate)
    return;
  self.allDataNeedsUpdate = false;
  [self.boardPositionListView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
///
/// Sets the currentBoardPosition flag on the BoardPositionView objects for the
/// old/new board positions. Also makes sure that the new board position becomes
/// visible in the board position list view.
// -----------------------------------------------------------------------------
- (void) updateCurrentBoardPosition
{
  if (! self.currentBoardPositionNeedsUpdate)
    return;
  self.currentBoardPositionNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  if (! game)
    return;
  GoBoardPosition* boardPosition = game.boardPosition;
  int newBoardPosition = boardPosition.currentBoardPosition;

  if ([self.boardPositionListView isVisibleItemViewAtIndex:self.oldBoardPosition])
  {
    UIView* itemView = [self.boardPositionListView visibleItemViewAtIndex:self.oldBoardPosition];
    BoardPositionView* boardPositionView = (BoardPositionView*)itemView;
    boardPositionView.currentBoardPosition = false;
  }

  if ([self.boardPositionListView isVisibleItemViewAtIndex:newBoardPosition])
  {
    UIView* itemView = [self.boardPositionListView visibleItemViewAtIndex:newBoardPosition];
    BoardPositionView* boardPositionView = (BoardPositionView*)itemView;
    boardPositionView.currentBoardPosition = true;
  }
  else
  {
    // Triggers itemScrollView:itemViewAtIndex() where we will set up a new
    // view with the "currentBoardPosition" flag set correctly
    [self.boardPositionListView makeVisibleItemViewAtIndex:newBoardPosition animated:true];
  }

  self.oldBoardPosition = -1;
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
///
/// Updates the number of items (i.e. board positions) in the board position
/// list view.
// -----------------------------------------------------------------------------
- (void) updateNumberOfItems
{
  if (! self.numberOfItemsNeedsUpdate)
    return;
  self.numberOfItemsNeedsUpdate = false;
  // ItemScrollView takes care of moving the content offset (i.e. scrolling
  // position) if it currently displays views whose index is beyond the new
  // number of board positions
  [self.boardPositionListView updateNumberOfItems];
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
    self.boardPositionListView.tappingEnabled = false;
  else if (game.isComputerThinking)
    self.boardPositionListView.tappingEnabled = false;
  else if (game.score.scoringInProgress)
    self.boardPositionListView.tappingEnabled = false;
  else
    self.boardPositionListView.tappingEnabled = true;
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (int) numberOfItemsInItemScrollView:(ItemScrollView*)itemScrollView
{
  return [GoGame sharedGame].boardPosition.numberOfBoardPositions;
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (int) itemWidthInItemScrollView:(ItemScrollView*)itemScrollView
{
  return self.boardPositionViewMetrics.boardPositionViewWidth;
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (int) itemHeightInItemScrollView:(ItemScrollView*)itemScrollView
{
  return self.boardPositionViewMetrics.boardPositionViewHeight;
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UIView*) itemScrollView:(ItemScrollView*)itemScrollView itemViewAtIndex:(int)index
{
  BoardPositionView* view = [[[BoardPositionView alloc] initWithBoardPosition:index
                                                                  viewMetrics:self.boardPositionViewMetrics] autorelease];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  if (index == boardPosition.currentBoardPosition)
    view.currentBoardPosition = true;
  return view;
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemScrollView:(ItemScrollView*)itemScrollView didTapItemView:(UIView*)itemView
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring board position change", self);
    return;
  }
  BoardPositionView* boardPositionView = (BoardPositionView*)itemView;
  int newBoardPosition = boardPositionView.boardPosition;
  [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if taps on item views should currently be ignored.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreTaps
{
  return [GoGame sharedGame].isComputerThinking;
}

@end
