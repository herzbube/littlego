// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionTableListViewController.h"
#import "../model/BoardViewModel.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/TableViewCellFactory.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionTableListViewController.
// -----------------------------------------------------------------------------
@interface BoardPositionTableListViewController()
/// @brief Prevents unregistering by dealloc if registering hasn't happened
/// yet. Registering may not happen if the controller's view is never loaded.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, retain) UITableView* currentBoardPositionTableView;
@property(nonatomic, retain) UITableView* boardPositionListTableView;
@property(nonatomic, assign) bool tappingEnabled;
@property(nonatomic, assign) bool allDataNeedsUpdate;
@property(nonatomic, assign) bool currentBoardPositionNeedsUpdate;
@property(nonatomic, assign) bool numberOfItemsNeedsUpdate;
@property(nonatomic, assign) bool tappingEnabledNeedsUpdate;
@property(nonatomic, assign) bool boardPositionZeroNeedsUpdate;
@property(nonatomic, assign) bool userInterfaceStyleNeedsUpdate;
@property(nonatomic, retain) UIImage* blackStoneImage;
@property(nonatomic, retain) UIImage* whiteStoneImage;
@property(nonatomic, retain) UIColor* alternateCellBackgroundColor1;
@property(nonatomic, retain) UIColor* alternateCellBackgroundColor2;
@property(nonatomic, retain) UIColor* alternateCellBackgroundColor1DarkMode;
@property(nonatomic, retain) UIColor* alternateCellBackgroundColor2DarkMode;
@end


@implementation BoardPositionTableListViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionTableListViewController object.
///
/// @note This is the designated initializer of
/// BoardPositionTableListViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self releaseObjects];
  self.notificationRespondersAreSetup = false;
  self.tappingEnabled = true;
  self.allDataNeedsUpdate = false;
  self.currentBoardPositionNeedsUpdate = false;
  self.numberOfItemsNeedsUpdate = false;
  self.tappingEnabledNeedsUpdate = false;
  self.boardPositionZeroNeedsUpdate = false;
  self.userInterfaceStyleNeedsUpdate = false;
  self.blackStoneImage = nil;
  self.whiteStoneImage = nil;
  self.alternateCellBackgroundColor1 = [UIColor lightBlueColor];
  self.alternateCellBackgroundColor2 = [UIColor whiteColor];
  if (@available(iOS 13.0, *))
  {
    self.alternateCellBackgroundColor1DarkMode = [UIColor systemGrayColor];
    self.alternateCellBackgroundColor2DarkMode = [UIColor systemGray2Color];
  }
  else
  {
    self.alternateCellBackgroundColor1DarkMode = self.alternateCellBackgroundColor1;
    self.alternateCellBackgroundColor2DarkMode = self.alternateCellBackgroundColor2;
  }
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// BoardPositionTableListViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  [self releaseObjects];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.currentBoardPositionTableView = nil;
  self.boardPositionListTableView = nil;
  self.blackStoneImage = nil;
  self.whiteStoneImage = nil;
  self.alternateCellBackgroundColor1 = nil;
  self.alternateCellBackgroundColor2 = nil;
  self.alternateCellBackgroundColor1DarkMode = nil;
  self.alternateCellBackgroundColor2DarkMode = nil;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [self createViews];
  [self setupViewHierarchy];
  [self configureViews];
  [self setupAutoLayoutConstraints];
  [self setupNotificationResponders];
  [self setupStoneImages];

  self.currentBoardPositionNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (@available(iOS 12.0, *))
  {
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
    {
      self.userInterfaceStyleNeedsUpdate = true;
      [self delayedUpdate];
    }
  }
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createViews
{
  [super loadView];
  // Plain style is required so that the header views stay visible. With
  // grouped style the header view of boardPositionListTableView scrolls out
  // of sight. Also plain style headers are much smaller and look better with
  // the way how we layout our two table views.
  self.currentBoardPositionTableView = [[[UITableView alloc] initWithFrame:CGRectZero
                                                                     style:UITableViewStylePlain] autorelease];
  self.boardPositionListTableView = [[[UITableView alloc] initWithFrame:CGRectZero
                                                                  style:UITableViewStylePlain] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.currentBoardPositionTableView];
  [self.view addSubview:self.boardPositionListTableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  self.currentBoardPositionTableView.delegate = self;
  self.currentBoardPositionTableView.dataSource = self;
  self.currentBoardPositionTableView.scrollEnabled = NO;
  self.currentBoardPositionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.currentBoardPositionTableView.accessibilityIdentifier = currentBoardPositionViewAccessibilityIdentifier;

  self.boardPositionListTableView.delegate = self;
  self.boardPositionListTableView.dataSource = self;
  self.boardPositionListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.boardPositionListTableView.accessibilityIdentifier = boardPositionTableViewAccessibilityIdentifier;

  // One of the alternate table view cell background colors is white. We want
  // to contrast this with a very light gray color so that the user sees where
  // the last/first cell of self.boardPositionListTableView begins and ends
  // (e.g. when there are not enough cells to fill the entire vertical extent
  // of self.boardPositionListTableView, but also when the table view bounces
  // on scroll). If the table view had grouped style we would not need to do
  // this because then the view would already have the correct background color.
  if (@available(iOS 13.0, *))
    self.boardPositionListTableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
  else
    self.boardPositionListTableView.backgroundColor = [UIColor whiteSmokeColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.currentBoardPositionTableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionListTableView.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.currentBoardPositionTableView, @"currentBoardPositionTableView",
                                   self.boardPositionListTableView, @"boardPositionListTableView",
                                   nil];

  CGFloat realTableViewHeight = ([self tableView:self.currentBoardPositionTableView heightForHeaderInSection:0] +
                                 [self tableView:self.currentBoardPositionTableView heightForRowAtIndexPath:[NSIndexPath indexPathWithIndex:0]]);

  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-0-[currentBoardPositionTableView]-0-|",
                            @"H:|-0-[boardPositionListTableView]-0-|",
                            [NSString stringWithFormat:@"V:|-0-[currentBoardPositionTableView(==%f)]-0-[boardPositionListTableView]-0-|", realTableViewHeight],
                            nil];
  for (NSString* visualFormat in visualFormats)
  {
    NSArray* constraint = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:viewsDictionary];
    [self.view addConstraints:constraint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  if (self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = true;
  
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStarts:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStops:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(boardViewWillDisplayCrossHair:) name:boardViewWillDisplayCrossHair object:nil];
  [center addObserver:self selector:@selector(boardViewWillHideCrossHair:) name:boardViewWillHideCrossHair object:nil];
  [center addObserver:self selector:@selector(handicapPointDidChange:) name:handicapPointDidChange object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
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
  if (! self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = false;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupStoneImages
{
  int stoneImageWidthAndHeight = floor([UiElementMetrics tableViewCellContentViewHeight] * 0.7);
  CGSize stoneImageSize = CGSizeMake(stoneImageWidthAndHeight, stoneImageWidthAndHeight);
  self.blackStoneImage = [[UIImage imageNamed:stoneBlackImageResource] imageByResizingToSize:stoneImageSize];
  self.whiteStoneImage = [[UIImage imageNamed:stoneWhiteImageResource] imageByResizingToSize:stoneImageSize];
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
/// @brief Responds to the #handicapPointDidChange notifications.
// -----------------------------------------------------------------------------
- (void) handicapPointDidChange:(NSNotification*)notification
{
  self.boardPositionZeroNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notifications.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  self.tappingEnabledNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notifications.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
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
  [self updateCurrentBoardPosition];
  [self updateBoardPositionZero];
  [self updateTappingEnabled];
  [self updateUserInterfaceStyle];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
///
/// Reloads all data in all table views managed by this controller.
// -----------------------------------------------------------------------------
- (void) updateAllData
{
  if (! self.allDataNeedsUpdate)
    return;
  self.allDataNeedsUpdate = false;
  [self.currentBoardPositionTableView reloadData];
  [self.boardPositionListTableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
///
/// Updates the number of items (i.e. board positions) in the board position
/// list table view.
// -----------------------------------------------------------------------------
- (void) updateNumberOfItems
{
  if (! self.numberOfItemsNeedsUpdate)
    return;
  self.numberOfItemsNeedsUpdate = false;
  // We only know that the number of board positions has changed since the last
  // update, but we don't know exactly what has changed. Because we don't know
  // exactly what has changed, it is impossible to delete rows from UITableView,
  // or insert rows into UITableView without making assumptions. For instance:
  // - User discards 1 board position, then creates a new board position by
  //   playing a move. In this scenario, due to our delayed update scheme, two
  //   changes to the number of board positions are coalesced into a single
  //   update. When the update is finally performed, it appears as if the number
  //   of board positions has not actually changed (1 position was discarded,
  //   1 was added).
  // - User discards 2 board positions, then creates a new board position by
  //   playing a move. Again, 2 changes are coalesced into one update so that
  //   when the update is finally performed it appears as if one new board
  //   position was added (2 positions were discarded, 1 was added).
  //
  // We don't want to make assumptions about such scenarios, because future
  // changes to command implementations are bound to break them. The simplest
  // solution is to reload the entire table view. We rely on UITableView
  // performing smooth UI updates so that no flickering occurs for cells whose
  // content has not actually changed.
  [self.boardPositionListTableView reloadData];
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

  [self updateCurrentBoardPositionInCurrentBoardPositionTableView];
  [self updateCurrentBoardPositionInBoardPositionListTableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateCurrentBoardPosition().
// -----------------------------------------------------------------------------
- (void) updateCurrentBoardPositionInCurrentBoardPositionTableView
{
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  UITableViewCell* cell = [self.currentBoardPositionTableView cellForRowAtIndexPath:indexPath];
  if (! cell)
    return;  // cell has not yet been loaded, so no update necessary
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.currentBoardPositionTableView reloadRowsAtIndexPaths:indexPaths
                                            withRowAnimation:UITableViewRowAnimationNone];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateCurrentBoardPosition().
// -----------------------------------------------------------------------------
- (void) updateCurrentBoardPositionInBoardPositionListTableView
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  NSInteger newCurrentBoardPosition = boardPosition.currentBoardPosition;
  NSInteger numberOfRowsInTableView = [self.boardPositionListTableView numberOfRowsInSection:0];
  if (newCurrentBoardPosition < numberOfRowsInTableView)
  {
    NSIndexPath* indexPathForNewCurrentBoardPosition = [NSIndexPath indexPathForRow:newCurrentBoardPosition inSection:0];
    [self.boardPositionListTableView selectRowAtIndexPath:indexPathForNewCurrentBoardPosition
                                                 animated:NO
                                           scrollPosition:UITableViewScrollPositionNone];
    UITableViewCell* cellForNewCurrentBoardPosition = [self.boardPositionListTableView cellForRowAtIndexPath:indexPathForNewCurrentBoardPosition];
    if (! cellForNewCurrentBoardPosition)
    {
      [self.boardPositionListTableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionMiddle
                                                                         animated:NO];
    }
  }
  else
  {
    DDLogError(@"%@: Unexpected new current board position %ld, number of rows in table view = %ld", self, (long)newCurrentBoardPosition, (long)numberOfRowsInTableView);
    assert(0);
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the cell that displays board position zero.
// -----------------------------------------------------------------------------
- (void) updateBoardPositionZero
{
  if (! self.boardPositionZeroNeedsUpdate)
    return;
  self.boardPositionZeroNeedsUpdate = false;

  // Don't reload cells, this would remove the selected state. Instead update
  // the cells directly.
  UITableViewCell* currentBoardPositionTableViewCell = [self.currentBoardPositionTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
  UITableViewCell* boardPositionListTableViewCell = [self.boardPositionListTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

  // The reason why we update the cell is because handicap has changed during
  // board setup. We therefore need to update only the detail text label.
  currentBoardPositionTableViewCell.detailTextLabel.text = [self detailLabelTextForBoardPosition:0 move:nil];
  boardPositionListTableViewCell.detailTextLabel.text = [self detailLabelTextForBoardPosition:0 move:nil];
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
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (game.isComputerThinking ||
      game.score.scoringInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysCrossHair ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    self.tappingEnabled = false;
  }
  else
  {
    self.tappingEnabled = true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the user interface style of the table view and its cells
/// (light mode or dark mode).
// -----------------------------------------------------------------------------
- (void) updateUserInterfaceStyle
{
  if (! self.userInterfaceStyleNeedsUpdate)
    return;
  self.userInterfaceStyleNeedsUpdate = false;

  [self.currentBoardPositionTableView reloadData];
  [self.boardPositionListTableView reloadData];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return 1;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.currentBoardPositionTableView)
  {
    // Must always return 1 here for setupCurrentBoardPositionTableView(), even
    // if there is no game and no board position. As a consequence, there is
    // a bit of special handling in tableView:cellForRowAtIndexPath:().
    return 1;
  }
  else
  {
    GoGame* game = [GoGame sharedGame];
    if (game)
    {
      int numberOfBoardPositions = game.boardPosition.numberOfBoardPositions;
      return numberOfBoardPositions;
    }
    else
    {
      return 0;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  if (tableView == self.currentBoardPositionTableView)
    return @"Current board position";
  else
    return @"All board positions - Tap to select";
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:SubtitleCellType tableView:tableView];
  GoGame* game = [GoGame sharedGame];
  if (! game)
  {
    // This happens during application startup, and only for the current
    // board position table view, because we always return 1 for that table
    // view in tableView:numberOfRowsInSection:(). We don't have any content,
    // so we just display an empty cell. Note that we can't eliminate this
    // because when we are setting up layout constraints during initialization
    // we rely on the fact that one row is always present.
    return cell;
  }

  int boardPositionOfCell;
  GoMove* move = nil;
  if (tableView == self.currentBoardPositionTableView)
  {
    GoBoardPosition* boardPosition = game.boardPosition;
    boardPositionOfCell = boardPosition.currentBoardPosition;
    move = boardPosition.currentMove;
  }
  else
  {
    // Cast is required because NSInteger and int differ in size in 64-bit. Cast
    // is safe because this app was not made to handle more than pow(2, 31)
    // board positions.
    boardPositionOfCell = (int)indexPath.row;
    if (0 == boardPositionOfCell)
      move = nil;
    else
    {
      int moveIndexOfCell = boardPositionOfCell - 1;
      move = [game.moveModel moveAtIndex:moveIndexOfCell];
    }
  }

  cell.textLabel.text = [self labelTextForMove:move];
  cell.textLabel.accessibilityIdentifier = intersectionLabelBoardPositionAccessibilityIdentifier;

  cell.detailTextLabel.text = [self detailLabelTextForBoardPosition:boardPositionOfCell move:move];
  cell.detailTextLabel.accessibilityIdentifier = boardPositionLabelBoardPositionAccessibilityIdentifier;

  cell.imageView.image = [self stoneImageForMove:move];
  if (cell.imageView.image == nil)
    cell.imageView.accessibilityIdentifier = noStoneImageViewBoardPositionAccessibilityIdentifier;
  else if (cell.imageView.image == self.blackStoneImage)
    cell.imageView.accessibilityIdentifier = blackStoneImageViewBoardPositionAccessibilityIdentifier;
  else
    cell.imageView.accessibilityIdentifier = whiteStoneImageViewBoardPositionAccessibilityIdentifier;

  cell.backgroundColor = [self backgroundColorForBoardPosition:boardPositionOfCell];
  cell.backgroundView.accessibilityIdentifier = unselectedBackgroundViewBoardPositionAccessibilityIdentifier;

  cell.selectedBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  cell.selectedBackgroundView.backgroundColor = [UIColor darkTangerineColor];
  cell.selectedBackgroundView.accessibilityIdentifier = selectedBackgroundViewBoardPositionAccessibilityIdentifier;

  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) tableView:(UITableView*)tableView shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (tableView == self.boardPositionListTableView && self.tappingEnabled && ! tableView.tracking)
    return YES;
  else
    return NO;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (tableView != self.boardPositionListTableView)
  {
    DDLogError(@"%@: Unexpected table view %@", self, tableView);
    assert(0);
    return;
  }
  // TODO: Can we remove this? This check should not be necessary since we also
  // implement tableView:shouldHighlightRowAtIndexPath:().
  if (! self.tappingEnabled)
  {
    DDLogWarn(@"%@: Ignoring board position change", self);
    return;
  }
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) board
  // positions.
  int newBoardPosition = (int)indexPath.row;
  [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section;
{
  // We implement this delegate method to make sure that there are no
  // differences between the height of self.currentBoardPositionTableView that
  // is calculated by setupAutoLayoutConstraints() and the height that is
  // actually rendered.
  return [UiElementMetrics tableViewHeaderViewSizeForStyle:tableView.style].height;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  // Since iOS 11 cells with UITableViewCellStyleSubtitle have a different
  // height than cells of other types. In addition, the height is not the same
  // across all devices. This makes it very difficult for
  // setupAutoLayoutConstraints() to calculate the correct height of
  // self.currentBoardPositionTableView. To make sure that there are no
  // differences between the height calculated by setupAutoLayoutConstraints()
  // and the height that is actually rendered, we implement this delegate
  // method. Doing so forces UITableView to apply the desired height, even if
  // the iOS default height might be different.
  return [UiElementMetrics tableViewCellSizeForType:SubtitleCellType].height;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView willDisplayHeaderView:(UIView*)view forSection:(NSInteger)section
{
  if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
  {
    UITableViewHeaderFooterView* headerFooterView = (UITableViewHeaderFooterView*)view;
    headerFooterView.contentView.backgroundColor = [UIColor blackColor];
    headerFooterView.textLabel.textColor = [UIColor whiteColor];
  }
  else
  {
    DDLogError(@"%@: Header view object %@ has unexpected type %@", self, view, [view class]);
    assert(0);
  }
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (NSString*) labelTextForMove:(GoMove*)move
{
  if (nil == move)
    return @"Start of the game";
  else if (GoMoveTypePlay == move.type)
    return move.point.vertex.string;
  else
    return @"Pass";
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (NSString*) detailLabelTextForBoardPosition:(int)boardPosition move:(GoMove*)move
{
  if (0 == boardPosition)
  {
    GoGame* game = [GoGame sharedGame];
    NSString* komiString = [NSString stringWithKomi:game.komi numericZeroValue:true];
    return [NSString stringWithFormat:@"Handicap: %1lu, Komi: %@", (unsigned long)game.handicapPoints.count, komiString];
  }
  else
  {
    int moveNumber = boardPosition;
    NSString* labelText = [NSString stringWithFormat:@"Move %d", moveNumber];
    NSUInteger numberOfCapturedStones = move.capturedStones.count;
    if (numberOfCapturedStones > 0)
    {
      labelText = [NSString stringWithFormat:@"%@, captures %lu stone", labelText, (unsigned long)numberOfCapturedStones];
      if (numberOfCapturedStones > 1)
        labelText = [labelText stringByAppendingString:@"s"];  // plural
    }
    return labelText;
  }
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UIImage*) stoneImageForMove:(GoMove*)move
{
  if (nil == move)
    return nil;
  else if (move.player.black)
    return self.blackStoneImage;
  else
    return self.whiteStoneImage;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UIColor*) backgroundColorForBoardPosition:(int)boardPosition
{
  bool isLightUserInterfaceStyle = [UiUtilities isLightUserInterfaceStyle:self.traitCollection];
  if (0 == (boardPosition % 2))
    return isLightUserInterfaceStyle ? self.alternateCellBackgroundColor1 : self.alternateCellBackgroundColor1DarkMode;
  else
    return isLightUserInterfaceStyle ? self.alternateCellBackgroundColor2 : self.alternateCellBackgroundColor2DarkMode;
}

@end
