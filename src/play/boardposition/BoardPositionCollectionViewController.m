// -----------------------------------------------------------------------------
// Copyright 2015-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoNodeModel.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionCollectionViewController.
// -----------------------------------------------------------------------------
@interface BoardPositionCollectionViewController()
@property(nonatomic, retain) NSString* reuseIdentifierCell;
@property(nonatomic, assign) bool allDataNeedsUpdate;
@property(nonatomic, assign) bool currentBoardPositionNeedsUpdate;
@property(nonatomic, assign) bool numberOfItemsNeedsUpdate;
@property(nonatomic, assign) bool userInteractionEnabledNeedsUpdate;
@property(nonatomic, assign) bool boardPositionZeroNeedsUpdate;
@property(nonatomic, assign) bool boardPositionDataNeedsUpdate;
@property(nonatomic, assign) bool ignoreCurrentBoardPositionChange;
@property(nonatomic, retain) NSIndexPath* indexPathForDelayedSelectItemOperation;
@property(nonatomic, retain) NSMutableArray* boardPositionsWithChangedData;
@end


@implementation BoardPositionCollectionViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionCollectionViewController object that
/// manages a collection view that extends in @a scrollDirection.
///
/// @note This is the designated initializer of
/// BoardPositionCollectionViewController.
// -----------------------------------------------------------------------------
- (id) initWithScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
  UICollectionViewFlowLayout* flowLayout = [[[UICollectionViewFlowLayout alloc] init] autorelease];
  flowLayout.scrollDirection = scrollDirection;
  flowLayout.minimumLineSpacing = 0.0f;
  // Required because we have items that differ in size
  flowLayout.minimumInteritemSpacing = 0.0f;

  // Call designated initializer of superclass (UICollectionViewController)
  self = [super initWithCollectionViewLayout:flowLayout];
  if (! self)
    return nil;
  self.reuseIdentifierCell = @"BoardPositionCollectionViewCell";
  self.allDataNeedsUpdate = false;
  self.currentBoardPositionNeedsUpdate = false;
  self.numberOfItemsNeedsUpdate = false;
  self.userInteractionEnabledNeedsUpdate = false;
  self.boardPositionZeroNeedsUpdate = false;
  self.boardPositionDataNeedsUpdate = false;
  self.ignoreCurrentBoardPositionChange = false;
  self.indexPathForDelayedSelectItemOperation = nil;
  self.boardPositionsWithChangedData = [NSMutableArray array];
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
  self.reuseIdentifierCell = nil;
  self.indexPathForDelayedSelectItemOperation = nil;
  self.boardPositionsWithChangedData = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  [self.collectionView registerClass:[BoardPositionCollectionViewCell class]
          forCellWithReuseIdentifier:self.reuseIdentifierCell];
  self.collectionView.accessibilityIdentifier = boardPositionCollectionViewAccessibilityIdentifier;

  [self updateCollectionViewBackgroundColor];

  // Make sure that the updater does its job the first time that it gets the
  // chance. This is required because this controller is instantiated after
  // an interface orientation change, and user interaction might already be
  // disabled. Example: Computer play game action is executed, then an interface
  // orientation change is initiated while the computer is still thinking.
  self.userInteractionEnabledNeedsUpdate = true;

  // If this controller is instantiated during application startup there is no
  // game yet, so we don't need this update. If this controller is instantiated
  // after an interface orientation change, then a game likely exists and we do
  // need the update.
  GoGame* game = [GoGame sharedGame];
  if (game)
  {
    self.currentBoardPositionNeedsUpdate = true;
    [self delayedUpdate];
  }
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
    [self updateCollectionViewBackgroundColor];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStarts:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStops:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillStart:) name:boardViewPanningGestureWillStart object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillEnd:) name:boardViewPanningGestureWillEnd object:nil];
  [center addObserver:self selector:@selector(handicapPointDidChange:) name:handicapPointDidChange object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
  [center addObserver:self selector:@selector(nodeSetupDataDidChange:) name:nodeSetupDataDidChange object:nil];
  [center addObserver:self selector:@selector(nodeAnnotationDataDidChange:) name:nodeAnnotationDataDidChange object:nil];
  [center addObserver:self selector:@selector(markupOnPointsDidChange:) name:markupOnPointsDidChange object:nil];
  [center addObserver:self selector:@selector(currentBoardPositionDidChange:) name:currentBoardPositionDidChange object:nil];
  [center addObserver:self selector:@selector(numberOfBoardPositionsDidChange:) name:numberOfBoardPositionsDidChange object:nil];
  [center addObserver:self selector:@selector(currentGameVariationDidChange:) name:currentGameVariationDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
  BoardPositionCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifierCell
                                                                                    forIndexPath:indexPath];

  // Cast is safe, we know that we cannot have more than pow(2, 31) board
  // positions
  cell.boardPosition = (int)indexPath.row;

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

#pragma mark - UICollectionViewDelegateFlowLayout overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDelegateFlowLayout protocol method.
// -----------------------------------------------------------------------------
- (CGSize) collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
  if (flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal)
  {
    // Horizontal scroll direction = cells have different sizes
    if (0 == indexPath.row)
      return [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero];
    else
      return [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionNonZero];
  }
  else
  {
    // Vertical scroll direction = all cells have the same size
    CGSize size = [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero];
    size.width = self.view.frame.size.width;
    return size;
  }
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

  // The command posts currentBoardPositionDidChange, which we can ignore since
  // it was the user who made the selection
  self.ignoreCurrentBoardPositionChange = true;
  [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
  self.ignoreCurrentBoardPositionChange = false;
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  [self.boardPositionsWithChangedData removeAllObjects];
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
/// @brief Responds to the #goScoreCalculationStarts notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillStart notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillStart:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillEnd:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #handicapPointDidChange notification.
// -----------------------------------------------------------------------------
- (void) handicapPointDidChange:(NSNotification*)notification
{
  self.boardPositionZeroNeedsUpdate = true;
  // After updating the zero board position it needs to be re-selected
  self.currentBoardPositionNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
{
  self.userInteractionEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeSetupDataDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeSetupDataDidChange:(NSNotification*)notification
{
  GoNode* node = notification.object;
  [self nodeDataDidChange:node];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeAnnotationDataDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeAnnotationDataDidChange:(NSNotification*)notification
{
  GoNode* node = notification.object;
  [self nodeDataDidChange:node];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #markupOnPointsDidChange notification.
// -----------------------------------------------------------------------------
- (void) markupOnPointsDidChange:(NSNotification*)notification
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  GoNode* currentNode = boardPosition.currentNode;
  [self nodeDataDidChange:currentNode];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentBoardPositionDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentBoardPositionDidChange:(NSNotification*)notification
{
  if (self.ignoreCurrentBoardPositionChange)
    return;

  self.currentBoardPositionNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #numberOfBoardPositionsDidChange notification.
// -----------------------------------------------------------------------------
- (void) numberOfBoardPositionsDidChange:(NSNotification*)notification
{
  self.numberOfItemsNeedsUpdate = true;

  NSArray* notificationObject = notification.object;
  NSNumber* oldNumberOfBoardPositions = notificationObject.firstObject;
  NSNumber* newNumberOfBoardPositions = notificationObject.lastObject;
  if (1 == [newNumberOfBoardPositions intValue] && [oldNumberOfBoardPositions intValue] > 1)
  {
    // The number of board positions has decreased from >1 to =1, i.e. all
    // moves were discarded. If the current board position was 0 before the
    // discard, the discard does not change the current board position, which
    // means that the notification currentBoardPositionDidChange is NOT posted.
    // This is a problem for this controller, because updateNumberOfItems()
    // causes the collection view to reload all data, and after the reload no
    // cell is selected. So, to make sure that board position 0 is selected
    // after the reload, we fake a board position change by setting the flag
    // self.currentBoardPositionNeedsUpdate.
    self.currentBoardPositionNeedsUpdate = true;
  }

  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentGameVariationDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentGameVariationDidChange:(NSNotification*)notification
{
  self.allDataNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

#pragma mark - Helpers for notification responders

// -----------------------------------------------------------------------------
/// @brief Helper method for notification responders that want to update the
/// cell that displays the data of @a node.
// -----------------------------------------------------------------------------
- (void) nodeDataDidChange:(GoNode*)node
{
  GoNodeModel* nodeModel = [GoGame sharedGame].nodeModel;
  int indexOfNode = [nodeModel indexOfNode:node];
  if (indexOfNode == -1)
    return;

  // Indexes of nodes and board positions are the same
  [self.boardPositionsWithChangedData addObject:[NSNumber numberWithInt:indexOfNode]];

  self.boardPositionDataNeedsUpdate = true;
  // If the cell being updated displays the current board position, it needs to
  // be re-selected after the update
  self.currentBoardPositionNeedsUpdate = true;
  [self delayedUpdate];
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
  [self updateAllData];
  [self updateNumberOfItems];
  [self updateBoardPositionZero];
  [self updateBoardPositionData];
  [self updateCurrentBoardPosition];
  [self updateUserInteractionEnabled];
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
/// Updates the collection view to display the cell that represents the current
/// board position. If the collection view is not visible at the moment, the
/// selection operation is delayed until the collection view becomes visible.
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
    // If the collection view is not visible (= it's window property is nil)
    // then it won't perform the desired scrolling operation. When the
    // collection view becomes visible later on, the item will be selected, but
    // the UICollectionViewCell won't be visible. This happens in at least two
    // known scenarios:
    // - The interface rotates
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
  UICollectionViewScrollPosition scrollPosition;
  UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
  if (flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal)
    scrollPosition = UICollectionViewScrollPositionCenteredHorizontally;
  else
    scrollPosition = UICollectionViewScrollPositionCenteredVertically;
  [self.collectionView selectItemAtIndexPath:indexPath
                                    animated:NO
                              scrollPosition:scrollPosition];
}

// -----------------------------------------------------------------------------
/// @brief Updates the cell that displays board position zero.
// -----------------------------------------------------------------------------
- (void) updateBoardPositionZero
{
  if (! self.boardPositionZeroNeedsUpdate)
    return;
  self.boardPositionZeroNeedsUpdate = false;

  [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
}

// -----------------------------------------------------------------------------
/// @brief Updates one or more cells that display changed data.
// -----------------------------------------------------------------------------
- (void) updateBoardPositionData
{
  if (! self.boardPositionDataNeedsUpdate)
    return;
  self.boardPositionDataNeedsUpdate = false;

  NSMutableArray* indexPathsToReload = [NSMutableArray array];
  for (NSNumber* indexOfBoardPositionAsNumber in self.boardPositionsWithChangedData)
  {
    int indexOfBoardPosition = [indexOfBoardPositionAsNumber intValue];
    [indexPathsToReload addObject:[NSIndexPath indexPathForRow:indexOfBoardPosition inSection:0]];
  }
  [self.boardPositionsWithChangedData removeAllObjects];

  [self.collectionView reloadItemsAtIndexPaths:indexPathsToReload];
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
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (game.isComputerThinking ||
      game.score.scoringInProgress ||
      appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    self.collectionView.userInteractionEnabled = NO;
  }
  else
  {
    self.collectionView.userInteractionEnabled = YES;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the background color of the collection view to match the
/// current UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateCollectionViewBackgroundColor
{
  // The collection view by default has a background color (i.e. it's not nil
  // or [UIColor clearColor]), but in light mode that color is unsuitable for
  // our needs because it is white, and one of the alternate collection view
  // cell background colors is also white. We want to contrast this with a very
  // light gray color so that the user sees where the last/first cell begins and
  // ends (e.g. when there are not enough cells to fill the entire horizontal
  // extent of the collection view, and also when the collection view bounces
  // on scroll).
  bool isLightUserInterfaceStyle = [UiUtilities isLightUserInterfaceStyle:self.traitCollection];
  self.collectionView.backgroundColor = isLightUserInterfaceStyle ? [UIColor whiteSmokeColor] : [UIColor blackColor];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Returns the maximum size that a cell managed by this controller can
/// have.
// -----------------------------------------------------------------------------
- (CGSize) boardPositionCollectionViewMaximumCellSize
{
  // Cells for board position 0 and non-zero board positions have the same
  // height, but the board position 0 cell has a larger width
  return [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero];
}

@end
