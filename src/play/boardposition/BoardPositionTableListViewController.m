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
#import "BoardPositionTableListViewController.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionTableListViewController.
// -----------------------------------------------------------------------------
@interface BoardPositionTableListViewController()
@property(nonatomic, retain) UILabel* currentBoardPositionTitleLabel;
@property(nonatomic, retain) UITableView* currentBoardPositionTableView;
@property(nonatomic, retain) UILabel* boardPositionListTitleLabel;
@property(nonatomic, retain) UITableView* boardPositionListTableView;
@property(nonatomic, assign) bool tappingEnabled;
@property(nonatomic, assign) bool allDataNeedsUpdate;
@property(nonatomic, assign) bool currentBoardPositionNeedsUpdate;
@property(nonatomic, assign) int oldCurrentBoardPosition;
@property(nonatomic, assign) bool numberOfItemsNeedsUpdate;
@property(nonatomic, assign) bool tappingEnabledNeedsUpdate;
@property(nonatomic, retain) UIImage* blackStoneImage;
@property(nonatomic, retain) UIImage* whiteStoneImage;
@end


@implementation BoardPositionTableListViewController

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
  self.tappingEnabled = true;
  self.allDataNeedsUpdate = false;
  self.currentBoardPositionNeedsUpdate = false;
  self.oldCurrentBoardPosition = -1;
  self.numberOfItemsNeedsUpdate = false;
  self.tappingEnabledNeedsUpdate = false;
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
/// @brief Private helper for dealloc and viewDidUnload
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.currentBoardPositionTitleLabel = nil;
  self.currentBoardPositionTableView = nil;
  self.boardPositionListTitleLabel = nil;
  self.boardPositionListTableView = nil;
  self.blackStoneImage = nil;
  self.whiteStoneImage = nil;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  CGRect frame = CGRectZero;
  // setupTableViews requires that the parent view has a certain minimal height,
  // so we assign an arbitrary height here that will later be expanded to the
  // real height thanks to the autoresizingMask. Note that the height must be
  // greater than 2 * label height + current board position table view height +
  // some vertical spacing.
  frame.size.height = 200;
  self.view = [[[UIView alloc] initWithFrame:frame] autorelease];
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

  [self setupTableViews];
  [self setupNotificationResponders];
  [self setupStoneImages];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (void) viewWillUnload
{
  [super viewWillUnload];
  [self removeNotificationResponders];
  [self releaseObjects];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupTableViews
{
  [self setupCurrentBoardPositionTitleLabel];
  [self setupCurrentBoardPositionTableView];
  [self setupBoardPositionListTitleLabel];
  [self setupBoardPositionListTableView];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupCurrentBoardPositionTitleLabel
{
  NSString* labelText = @"Current board position";
  self.currentBoardPositionTitleLabel = [self titleLabelWithText:labelText];

  CGRect currentBoardPositionTitleLabelFrame = self.currentBoardPositionTitleLabel.frame;
  currentBoardPositionTitleLabelFrame.origin.y = [UiElementMetrics spacingVertical];
  self.currentBoardPositionTitleLabel.frame = currentBoardPositionTitleLabelFrame;
  [self.view addSubview:self.currentBoardPositionTitleLabel];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionListTitleLabel
{
  NSString* labelText = @"List of board positions";
  self.boardPositionListTitleLabel = [self titleLabelWithText:labelText];

  CGRect boardPositionListTitleLabelFrame = self.boardPositionListTitleLabel.frame;
  boardPositionListTitleLabelFrame.origin.y = CGRectGetMaxY(self.currentBoardPositionTableView.frame);
  self.boardPositionListTitleLabel.frame = boardPositionListTitleLabelFrame;
  [self.view addSubview:self.boardPositionListTitleLabel];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (UILabel*) titleLabelWithText:(NSString*)labelText
{
  UIFont* labelFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  CGSize labelSize = [labelText sizeWithFont:labelFont
                           constrainedToSize:constraintSize
                               lineBreakMode:UILineBreakModeWordWrap];

  CGRect labelFrame;
  labelFrame.origin.x = [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal];
  labelFrame.origin.y = 0;
  labelFrame.size = labelSize;
  UILabel* titleLabel = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
  titleLabel.font = labelFont;
  titleLabel.text = labelText;
  titleLabel.textColor = [UIColor grayColor];
  titleLabel.backgroundColor = [UIColor clearColor];
  return titleLabel;
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupCurrentBoardPositionTableView
{
  CGFloat tableViewX = 0;
  CGFloat tableViewY = CGRectGetMaxY(self.currentBoardPositionTitleLabel.frame);
  CGFloat tableViewWidth = self.view.frame.size.width;
  // A bit of optimization: By setting the initial height to 0, we can prevent
  // tableView:cellForRowAtIndexPath:() from being triggered when we invoke
  // layoutIfNeeded() further down.
  CGFloat fakeTableViewHeight = 0;
  CGRect currentBoardPositionTableViewFrame = CGRectMake(tableViewX, tableViewY, tableViewWidth, fakeTableViewHeight);
  self.currentBoardPositionTableView = [[[UITableView alloc] initWithFrame:currentBoardPositionTableViewFrame
                                                                     style:UITableViewStyleGrouped] autorelease];
  [self.view addSubview:self.currentBoardPositionTableView];
  self.currentBoardPositionTableView.delegate = self;
  self.currentBoardPositionTableView.dataSource = self;

  // Force the table view to immediately layout its subviews. As a result,
  // afterwards we can get the correct content size and use to resize the table
  // view to its proper height. Note that this invokes some of our
  // UITableViewDataSource methods!
  [self.currentBoardPositionTableView layoutIfNeeded];
  CGFloat realTableViewHeight = [self.currentBoardPositionTableView contentSize].height;
  currentBoardPositionTableViewFrame.size.height = realTableViewHeight;
  self.currentBoardPositionTableView.frame = currentBoardPositionTableViewFrame;

  self.currentBoardPositionTableView.backgroundView = nil;
  self.currentBoardPositionTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.currentBoardPositionTableView.scrollEnabled = NO;
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionListTableView
{
  CGRect mainViewFrame = self.view.frame;
  CGFloat tableViewX = 0;
  CGFloat tableViewY = (CGRectGetMaxY(self.boardPositionListTitleLabel.frame)
                        + [UiElementMetrics spacingVertical]);
  CGFloat tableViewWidth = self.view.frame.size.width;
  CGFloat tableViewHeight = (mainViewFrame.size.height - tableViewY - [UiElementMetrics spacingVertical]);
  CGRect boardPositionListTableViewFrame = CGRectMake(tableViewX, tableViewY, tableViewWidth, tableViewHeight);
  self.boardPositionListTableView = [[[UITableView alloc] initWithFrame:boardPositionListTableViewFrame
                                                                  style:UITableViewStyleGrouped] autorelease];
  [self.view addSubview:self.boardPositionListTableView];
  self.boardPositionListTableView.delegate = self;
  self.boardPositionListTableView.dataSource = self;

  self.boardPositionListTableView.backgroundView = nil;
  self.boardPositionListTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
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
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupStoneImages
{
  int stoneImageWidthAndHeight = floor([UiElementMetrics tableViewCellContentViewHeight] * 0.7);
  CGSize stoneImageSize = CGSizeMake(stoneImageWidthAndHeight, stoneImageWidthAndHeight);
  self.blackStoneImage = [[UIImage imageNamed:stoneBlackImageResource] imageByResizingToSize:stoneImageSize];
  self.whiteStoneImage = [[UIImage imageNamed:stoneWhiteImageResource] imageByResizingToSize:stoneImageSize];
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
  [self updateNumberOfItems];
  [self updateCurrentBoardPosition];
  [self updateTappingEnabled];
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
  int oldNumberOfBoardPositions = [self.boardPositionListTableView numberOfRowsInSection:0];
  int newNumberOfBoardPositions = [GoGame sharedGame].boardPosition.numberOfBoardPositions;
  if (oldNumberOfBoardPositions == newNumberOfBoardPositions)
    return;
  else if (newNumberOfBoardPositions > oldNumberOfBoardPositions)
  {
    NSMutableArray* indexPaths = [NSMutableArray array];
    for (int boardPositionToInsert = oldNumberOfBoardPositions; boardPositionToInsert < newNumberOfBoardPositions; ++boardPositionToInsert)
    {
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:boardPositionToInsert inSection:0];
      [indexPaths addObject:indexPath];
    }
    [self.boardPositionListTableView insertRowsAtIndexPaths:indexPaths
                                           withRowAnimation:UITableViewRowAnimationTop];
  }
  else if (newNumberOfBoardPositions < oldNumberOfBoardPositions)
  {
    NSMutableArray* indexPaths = [NSMutableArray array];
    for (int boardPositionToInsert = newNumberOfBoardPositions; boardPositionToInsert < oldNumberOfBoardPositions; ++boardPositionToInsert)
    {
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:boardPositionToInsert inSection:0];
      [indexPaths addObject:indexPath];
    }
    [self.boardPositionListTableView deleteRowsAtIndexPaths:indexPaths
                                           withRowAnimation:UITableViewRowAnimationBottom];
  }
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
  int newCurrentBoardPosition = boardPosition.currentBoardPosition;

  int numberOfRowsInTableView = [self.boardPositionListTableView numberOfRowsInSection:0];

  NSMutableArray* indexPaths = [NSMutableArray arrayWithCapacity:0];
  if (self.oldCurrentBoardPosition >= 0 && self.oldCurrentBoardPosition < numberOfRowsInTableView)
  {
    NSIndexPath* indexPathForOldCurrentBoardPosition = [NSIndexPath indexPathForRow:self.oldCurrentBoardPosition inSection:0];
    [indexPaths addObject:indexPathForOldCurrentBoardPosition];
  }
  NSIndexPath* indexPathForNewCurrentBoardPosition = [NSIndexPath indexPathForRow:newCurrentBoardPosition inSection:0];
  if (newCurrentBoardPosition < numberOfRowsInTableView && newCurrentBoardPosition != self.oldCurrentBoardPosition)
    [indexPaths addObject:indexPathForNewCurrentBoardPosition];
  [self.boardPositionListTableView reloadRowsAtIndexPaths:indexPaths
                                         withRowAnimation:UITableViewRowAnimationNone];
  self.oldCurrentBoardPosition = -1;

  UITableViewCell* cellForNewCurrentBoardPosition = [self.boardPositionListTableView cellForRowAtIndexPath:indexPathForNewCurrentBoardPosition];
  if (! cellForNewCurrentBoardPosition)
  {
    [self.boardPositionListTableView scrollToRowAtIndexPath:indexPathForNewCurrentBoardPosition
                                           atScrollPosition:UITableViewScrollPositionMiddle
                                                   animated:NO];
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
  if ([GoGame sharedGame].isComputerThinking)
    self.tappingEnabled = false;
  else
    self.tappingEnabled = true;
  // Must update manually because the delegate method
  // tableView:shouldHighlightRowAtIndexPath:() is available only in iOS 6 and
  // later
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  int currentBoardPosition = boardPosition.currentBoardPosition;
  NSArray* indexPathsForVisibleRows = [self.boardPositionListTableView indexPathsForVisibleRows];
  for (NSIndexPath* indexPath in indexPathsForVisibleRows)
  {
    if (indexPath.row == currentBoardPosition)
      continue;  // keep the highlight of the current board position intact
    UITableViewCell* cell = [self.boardPositionListTableView cellForRowAtIndexPath:indexPath];
    if (self.tappingEnabled)
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    else
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
}

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
    // because when we are setting up the table view frame during initialization
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
    boardPositionOfCell = indexPath.row;
    if (0 == boardPositionOfCell)
      move = nil;
    else
    {
      int moveIndexOfCell = boardPositionOfCell - 1;
      move = [game.moveModel moveAtIndex:moveIndexOfCell];
    }
  }
  cell.textLabel.text = [self labelTextForMove:move];
  cell.detailTextLabel.text = [self detailLabelTextForBoardPosition:boardPositionOfCell move:move];
  cell.imageView.image = [self stoneImageForMove:move];
  return cell;
}

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
    return [NSString stringWithFormat:@"Handicap: %1d, Komi: %@", game.handicapPoints.count, komiString];
  }
  else
  {
    int moveNumber = boardPosition;
    NSString* labelText = [NSString stringWithFormat:@"Move %d", moveNumber];
    int numberOfCapturedStones = move.capturedStones.count;
    if (numberOfCapturedStones > 0)
    {
      labelText = [NSString stringWithFormat:@"%@, captures %d stone", labelText, numberOfCapturedStones];
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
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (tableView == self.currentBoardPositionTableView)
  {
    GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
    int currentBoardPosition = boardPosition.currentBoardPosition;
    if (0 == currentBoardPosition)
    {
    }
    else
    {
      GoMove* currentMove = boardPosition.currentMove;
      cell.backgroundColor = [self backgroundColorForMove:currentMove];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  else
  {
    int boardPositionOfCell = indexPath.row;
    if (0 == boardPositionOfCell)
    {
    }
    else
    {
      int moveIndex = boardPositionOfCell - 1;
      GoMove* move = [[GoGame sharedGame].moveModel moveAtIndex:moveIndex];
      cell.backgroundColor = [self backgroundColorForMove:move];
    }

    if (boardPositionOfCell == [GoGame sharedGame].boardPosition.currentBoardPosition)
    {
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.selected = YES;
    }
    else
    {
      if (self.tappingEnabled)
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      else
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.selected = NO;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for
/// tableView:willDisplayCell:forRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UIColor*) backgroundColorForMove:(GoMove*)move
{
  if (move.player.black)
    return [UIColor whiteColor];
  else
    return [UIColor lightBlueColor];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (NSIndexPath*) tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (tableView == self.boardPositionListTableView && self.tappingEnabled)
    return indexPath;
  else
    return nil;  // highlighting is disabled in updateTappingEnabled()
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (tableView == self.currentBoardPositionTableView)
  {
    DDLogError(@"%@: Unexpected table view %@", self, tableView);
    assert(0);
    return;
  }
  int newBoardPosition = indexPath.row;
  [[[[ChangeBoardPositionCommand alloc] initWithBoardPosition:newBoardPosition] autorelease] submit];
}

@end
