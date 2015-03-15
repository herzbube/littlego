// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionCollectionViewController.h"
#import "BoardPositionCollectionViewCell.h"
#import "../model/BoardViewModel.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionCollectionViewController.
// -----------------------------------------------------------------------------
@interface BoardPositionCollectionViewController()
@property(nonatomic, retain) NSString* reuseIdentifierCell;
@property(nonatomic, assign) bool tappingEnabled;
@property(nonatomic, assign) bool allDataNeedsUpdate;
@property(nonatomic, assign) bool currentBoardPositionNeedsUpdate;
@property(nonatomic, assign) bool numberOfItemsNeedsUpdate;
@property(nonatomic, assign) bool tappingEnabledNeedsUpdate;
@property(nonatomic, assign) bool ignoreCurrentBoardPositionChange;
@end


@implementation BoardPositionCollectionViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionCollectionViewController object.
///
/// @note This is the designated initializer of
/// BoardPositionCollectionViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  UICollectionViewFlowLayout* flowLayout = [[[UICollectionViewFlowLayout alloc] init] autorelease];
  flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  flowLayout.minimumLineSpacing = 0.0f;
  // Required because we have items that differ in size
  flowLayout.minimumInteritemSpacing = 0.0f;

  // Call designated initializer of superclass (UICollectionViewController)
  self = [super initWithCollectionViewLayout:flowLayout];
  if (! self)
    return nil;
  self.reuseIdentifierCell = @"BoardPositionCollectionViewCell";
  self.tappingEnabled = true;
  self.allDataNeedsUpdate = false;
  self.currentBoardPositionNeedsUpdate = false;
  self.numberOfItemsNeedsUpdate = false;
  self.tappingEnabledNeedsUpdate = false;
  self.ignoreCurrentBoardPositionChange = false;
  [self setupNotificationResponders];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// BoardPositionCollectionViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [self.collectionView registerClass:[BoardPositionCollectionViewCell class]
          forCellWithReuseIdentifier:self.reuseIdentifierCell];

  // One of the alternate collection view cell background colors is white. We
  // want to contrast this with a very light gray color so that the user sees
  // where the last/first cell begins and ends (e.g. when there are not enough
  // cells to fill the entire horizontal extent of the collection view, but
  // also when the collection view bounces on scroll).
  self.collectionView.backgroundColor = [UIColor whiteSmokeColor];

  self.currentBoardPositionNeedsUpdate = true;
  [self delayedUpdate];
}

#pragma mark - Setup/remove notification responders

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

#pragma mark - UICollectionViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  // TODO xxx not needed if really is 1
  return 1;
}

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
  BoardPositionCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifierCell
                                                                                    forIndexPath:indexPath];
  // Cast is safe, we know that we cannot have more than pow(2, 31) board
  // positions
  cell.boardPosition = (int)indexPath.row;
  return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDelegateFlowLayout protocol method.
// -----------------------------------------------------------------------------
- (CGSize) collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (0 == indexPath.row)
    return [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero];
  else
    return [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionNonZero];
}

#pragma mark - UICollectionViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) collectionView:(UICollectionView*)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath*)indexPath
{
  return (self.tappingEnabled ? YES : NO);
}

// xxx remove if no longer needed
- (BOOL) collectionView:(UICollectionView*)collectionView shouldSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  return (self.tappingEnabled ? YES : NO);
}

// xxx remove if no longer needed
- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
  return (self.tappingEnabled ? YES : NO);
}

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) board
  // positions.
  int newBoardPosition = (int)indexPath.row;

  // The command triggers a notification that we can ignore since it was the
  // user who made the selection
  self.ignoreCurrentBoardPositionChange = true;
  [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
  self.ignoreCurrentBoardPositionChange = false;
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
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:NSKeyValueObservingOptionOld context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  self.allDataNeedsUpdate = true;
  // currentBoardPosition also needs update to cover the case where the app
  // launches and we need to display a non-zero board position right after a
  // game is created
  self.currentBoardPositionNeedsUpdate = true;
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
/// @brief Responds to the #boardViewWillDisplayCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillDisplayCrossHair:(NSNotification*)notification
{
  self.tappingEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillHideCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillHideCrossHair:(NSNotification*)notification
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

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"currentBoardPosition"])
  {
    if (! self.ignoreCurrentBoardPositionChange)
    {
      self.currentBoardPositionNeedsUpdate = true;
      [self delayedUpdate];
    }
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

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  [self updateAllData];
  [self updateNumberOfItems];
  [self updateCurrentBoardPosition];
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
///
/// Reloads all data in the collection view managed by this controller.
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
/// Updates the table view cells that represent the old and the new current
/// board position. Also makes sure that the new board position becomes visible
/// in the board position list table view.
// -----------------------------------------------------------------------------
- (void) updateCurrentBoardPosition
{
  if (! self.currentBoardPositionNeedsUpdate)
    return;
  self.currentBoardPositionNeedsUpdate = false;

  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  NSInteger newCurrentBoardPosition = boardPosition.currentBoardPosition;
  NSInteger numberOfItemsInCollectionView = [self.collectionView numberOfItemsInSection:0];
  if (newCurrentBoardPosition < numberOfItemsInCollectionView)
  {
    NSIndexPath* indexPathForNewCurrentBoardPosition = [NSIndexPath indexPathForRow:newCurrentBoardPosition inSection:0];
    [self.collectionView selectItemAtIndexPath:indexPathForNewCurrentBoardPosition
                                      animated:NO
                                scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
  }
  else
  {
    DDLogError(@"%@: Unexpected new current board position %ld, number of items in collection view = %ld", self, (long)newCurrentBoardPosition, (long)numberOfItemsInCollectionView);
    assert(0);
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
  if (game.isComputerThinking ||
      game.score.scoringInProgress ||
      [ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    self.tappingEnabled = false;
  }
  else
  {
    self.tappingEnabled = true;
  }
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Returns the height of cells managed by this controller.
// -----------------------------------------------------------------------------
- (CGFloat) boardPositionCollectionViewHeight
{
  // Cells for board position 0 and non-zero board positions have the same height
  return [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero].height;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if taps on cells in the list of board positions should
/// currently be ignored.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreTaps
{
  return ! self.tappingEnabled;
}

@end
