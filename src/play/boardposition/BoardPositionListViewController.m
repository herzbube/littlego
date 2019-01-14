// -----------------------------------------------------------------------------
// Copyright 2013-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "../model/BoardViewModel.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionListViewController.
// -----------------------------------------------------------------------------
@interface BoardPositionListViewController()
@property(nonatomic, retain) NSString* reuseIdentifierCell;
@property(nonatomic, assign) bool allDataNeedsUpdate;
@property(nonatomic, assign) bool numberOfItemsNeedsUpdate;
@property(nonatomic, assign) bool currentBoardPositionNeedsUpdate;
@property(nonatomic, assign) int oldCurrentBoardPosition;
@property(nonatomic, assign) bool userInteractionEnabledNeedsUpdate;
@property(nonatomic, retain) NSIndexPath* indexPathForDelayedSelectItemOperation;
@end


@implementation BoardPositionListViewController

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionListViewController object.
///
/// @note This is the designated initializer of BoardPositionListViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  UICollectionViewFlowLayout* flowLayout = [[[UICollectionViewFlowLayout alloc] init] autorelease];
  flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  flowLayout.itemSize = [BoardPositionView boardPositionViewSize];
  flowLayout.minimumLineSpacing = 0.0f;

  // Call designated initializer of superclass (UICollectionViewController)
  self = [super initWithCollectionViewLayout:flowLayout];
  if (! self)
    return nil;
  self.reuseIdentifierCell = @"BoardPositionView";
  self.allDataNeedsUpdate = false;
  self.numberOfItemsNeedsUpdate = false;
  self.currentBoardPositionNeedsUpdate = false;
  self.oldCurrentBoardPosition = -1;
  self.userInteractionEnabledNeedsUpdate = false;
  self.indexPathForDelayedSelectItemOperation = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionListViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.reuseIdentifierCell = nil;
  self.indexPathForDelayedSelectItemOperation = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  [self.collectionView registerClass:[BoardPositionView class]
          forCellWithReuseIdentifier:self.reuseIdentifierCell];
  self.collectionView.backgroundColor = [UIColor clearColor];

  [self setupNotificationResponders];

  self.allDataNeedsUpdate = true;
  self.numberOfItemsNeedsUpdate = false;
  self.currentBoardPositionNeedsUpdate = true;
  self.oldCurrentBoardPosition = -1;
  self.userInteractionEnabledNeedsUpdate = true;
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
  [center addObserver:self selector:@selector(boardViewWillDisplayCrossHair:) name:boardViewWillDisplayCrossHair object:nil];
  [center addObserver:self selector:@selector(boardViewWillHideCrossHair:) name:boardViewWillHideCrossHair object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:NSKeyValueObservingOptionOld context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
}

#pragma mark - UICollectionViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (NSInteger) collectionView:(UICollectionView*)collectionView
      numberOfItemsInSection:(NSInteger)section
{
  GoGame* game = [GoGame sharedGame];
  if (game)
    return game.boardPosition.numberOfBoardPositions;
  else
    return 0;
}

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (UICollectionViewCell*) collectionView:(UICollectionView*)collectionView
                  cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  BoardPositionView* cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifierCell
                                                                      forIndexPath:indexPath];
  // Cast is safe, we know that we cannot have more than pow(2, 31) board
  // positions
  cell.boardPosition = (int)indexPath.row;
  cell.currentBoardPosition = (cell.boardPosition == [GoGame sharedGame].boardPosition.currentBoardPosition);

  if (self.indexPathForDelayedSelectItemOperation)
  {
    // We should not interrupt the data acquisiton process, so we perform the
    // scrolling operation asynchronously. See the comments in
    // updateCurrentBoardPosition for an explanation why we do this stuff here.
    [self performSelector:@selector(selectItemAtIndexPath:) withObject:self.indexPathForDelayedSelectItemOperation afterDelay:0];
    self.indexPathForDelayedSelectItemOperation = nil;
  }

  return cell;
}

#pragma mark - UICollectionViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) board
  // positions.
  int newBoardPosition = (int)indexPath.row;
  [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
}

#pragma mark - Notification responders

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
  self.oldCurrentBoardPosition = -1;
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStarts:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStops notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStops:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillDisplayCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillDisplayCrossHair:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillHideCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillHideCrossHair:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
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
      self.oldCurrentBoardPosition = [[change objectForKey:NSKeyValueChangeOldKey] intValue];
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
  // Update number of items before current board position because
  // updateCurrentBoardPosition() will try to clear the "current" flag of the
  // previous board position view, but that board position might have been
  // discarded.
  [self updateNumberOfItems];
  [self updateCurrentBoardPosition];
  [self updateUserInteractionEnabled];
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
  [self.collectionView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
///
/// Reloads all data in the collection view managed by this controller.
///
/// We only know that the number of board positions has changed since the last
/// update, but we don't know exactly what has changed. Because we don't know
/// exactly what has changed, it is impossible to delete rows from
/// UICollectionView, or insert rows into UICollectionView without making
/// assumptions. For instance:
/// - User discards 1 board position, then creates a new board position by
///   playing a move. In this scenario, due to our delayed update scheme, two
///   changes to the number of board positions are coalesced into a single
///   update. When the update is finally performed, it appears as if the number
///   of board positions has not actually changed (1 position was discarded,
///   1 was added).
/// - User discards 2 board positions, then creates a new board position by
///   playing a move. Again, 2 changes are coalesced into one update so that
///   when the update is finally performed it appears as if one new board
///   position was added (2 positions were discarded, 1 was added).
///
/// We don't want to make assumptions about such scenarios, because future
/// changes to command implementations are bound to break them. The simplest
/// solution is to reload the entire collection view. We rely on
/// UICollectionView to perform smooth UI updates so that no flickering occurs
/// for cells whose content has not actually changed.
// -----------------------------------------------------------------------------
- (void) updateNumberOfItems
{
  if (! self.numberOfItemsNeedsUpdate)
    return;
  self.numberOfItemsNeedsUpdate = false;
  [self.collectionView reloadData];
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
  NSInteger newCurrentBoardPosition = boardPosition.currentBoardPosition;
  NSInteger numberOfItemsInCollectionView = [self.collectionView numberOfItemsInSection:0];

  if (self.oldCurrentBoardPosition >= 0)
  {
    NSIndexPath* indexPathForOldCurrentBoardPosition = [NSIndexPath indexPathForRow:self.oldCurrentBoardPosition inSection:0];
    // Returns nil if cell is not visible, in which case we don't have to do
    // anything
    UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPathForOldCurrentBoardPosition];
    if (cell)
    {
      BoardPositionView* boardPositionView = (BoardPositionView*)cell;
      boardPositionView.currentBoardPosition = false;
    }
    self.oldCurrentBoardPosition = -1;
  }

  if (newCurrentBoardPosition < numberOfItemsInCollectionView)
  {
    NSIndexPath* indexPathForNewCurrentBoardPosition = [NSIndexPath indexPathForRow:newCurrentBoardPosition inSection:0];
    // If the collection view is not visible (= it's window property is nil)
    // then it won't perform the desired scrolling operation. When the
    // collection view becomes visible later on, the item will be selected, but
    // the UICollectionViewCell won't be visible. This happens in at least two
    // known scenarios:
    // - The collection view is hidden
    // - The application launches into an UI area that is not UIAreaPlay
    // The workaround is to delay the scrolling operation until we know that
    // the collection view has become visible. In this case we have chosen
    // collectionView:cellForItemAtIndexPath: as a likely trigger because we
    // can assume that when the collection view starts to acquire data from its
    // data source, then it will also be visible.
    if (self.view.window)
      [self selectItemAtIndexPath:indexPathForNewCurrentBoardPosition];
    else
      self.indexPathForDelayedSelectItemOperation = indexPathForNewCurrentBoardPosition;
  }
  else
  {
    DDLogError(@"%@: Unexpected new current board position %ld, number of items in collection view = %ld", self, (long)newCurrentBoardPosition, (long)numberOfItemsInCollectionView);
    assert(0);
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateCurrentBoardPosition.
// -----------------------------------------------------------------------------
- (void) selectItemAtIndexPath:(NSIndexPath*)indexPath
{
  // Scroll and center only if cell is not visible; if the method was invoked
  // because the user selected an already visible cell we don't want to center
  // on that cell, this has a jarring effect
  UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPath];
  if (! cell)
  {
    UICollectionViewScrollPosition scrollPosition;
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    if (flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal)
      scrollPosition = UICollectionViewScrollPositionCenteredHorizontally;
    else
      scrollPosition = UICollectionViewScrollPositionCenteredVertically;
    [self.collectionView selectItemAtIndexPath:indexPath
                                      animated:NO
                                scrollPosition:scrollPosition];
    cell = [self.collectionView cellForItemAtIndexPath:indexPath];
  }
  if (cell)
  {
    BoardPositionView* boardPositionView = (BoardPositionView*)cell;
    boardPositionView.currentBoardPosition = true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates whether user interaction on the collection view should be
/// enabled or not.
///
/// Although disabling user interaction is a harsh measure (it even disables
/// scrolling), it is the only RELIABLE way that I have found to prevent the
/// user from changing the selected cell. I attempted to override various
/// UICollectionViewDelegate methods for controlling highlighting/selection,
/// but without success. Notably:
/// - I implemented the override
///   collectionView:shouldHighlightItemAtIndexPath:() so that it returns NO
///   when selection changes should be disabled
/// - If this override is present and UICollectionView gets NO as a return
///   value, the collection view immediately de-selects the currently selected
///   cell!
// -----------------------------------------------------------------------------
- (void) updateUserInteractionEnabled
{
  if (! self.userInteractionEnabledNeedsUpdate)
    return;
  self.userInteractionEnabledNeedsUpdate = false;
  GoGame* game = [GoGame sharedGame];
  if (! game ||
      game.isComputerThinking ||
      game.score.scoringInProgress ||
      [ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    self.collectionView.userInteractionEnabled = NO;
  }
  else
  {
    self.collectionView.userInteractionEnabled = YES;
  }
}

@end
