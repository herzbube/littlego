// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionToolbarController.h"
#import "BoardPositionListViewController.h"
#import "BoardPositionView.h"
#import "CurrentBoardPositionViewController.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"

// Enums
enum NavigationDirection
{
  NavigationDirectionBackward,
  NavigationDirectionForward
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionToolbarController.
// -----------------------------------------------------------------------------
@interface BoardPositionToolbarController()
@property(nonatomic, assign) bool toolbarNeedsPopulation;
@property(nonatomic, assign) bool buttonStatesNeedUpdate;
@property(nonatomic, assign) UIToolbar* toolbar;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItems;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItemsBackward;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItemsForward;
@property(nonatomic, assign) bool boardPositionListViewIsVisible;
@end


@implementation BoardPositionToolbarController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionToolbarController object.
///
/// @note This is the designated initializer of BoardPositionToolbarController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self releaseObjects];
  [self setupChildControllers];
  self.boardPositionListViewIsVisible = false;
  self.toolbarNeedsPopulation = false;
  self.buttonStatesNeedUpdate = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionToolbarController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  [self releaseObjects];
  self.boardPositionListViewController = nil;
  self.currentBoardPositionViewController = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper invoked during initialization and deallocation.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.toolbar = nil;
  self.navigationBarButtonItems = nil;
  self.navigationBarButtonItemsBackward = nil;
  self.navigationBarButtonItemsForward = nil;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    self.boardPositionListViewController = [[[BoardPositionListViewController alloc] init] autorelease];
    self.currentBoardPositionViewController = [[[CurrentBoardPositionViewController alloc] init] autorelease];

    self.currentBoardPositionViewController.delegate = self;
  }
  else
  {
    self.boardPositionListViewController = nil;
    self.currentBoardPositionViewController = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardPositionListViewController:(BoardPositionListViewController*)boardPositionListViewController
{
  if (_boardPositionListViewController == boardPositionListViewController)
    return;
  if (_boardPositionListViewController)
  {
    [_boardPositionListViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionListViewController removeFromParentViewController];
    [_boardPositionListViewController release];
    _boardPositionListViewController = nil;
  }
  if (boardPositionListViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionListViewController];
    [_boardPositionListViewController didMoveToParentViewController:self];
    [boardPositionListViewController retain];
    _boardPositionListViewController = boardPositionListViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setCurrentBoardPositionViewController:(CurrentBoardPositionViewController*)currentBoardPositionViewController
{
  if (_currentBoardPositionViewController == currentBoardPositionViewController)
    return;
  if (_currentBoardPositionViewController)
  {
    [_currentBoardPositionViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_currentBoardPositionViewController removeFromParentViewController];
    [_currentBoardPositionViewController release];
    _currentBoardPositionViewController = nil;
  }
  if (currentBoardPositionViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:currentBoardPositionViewController];
    [_currentBoardPositionViewController didMoveToParentViewController:self];
    [currentBoardPositionViewController retain];
    _currentBoardPositionViewController = currentBoardPositionViewController;
  }
}

#pragma mark - loadView and helpers

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.toolbar = [[[UIToolbar alloc] initWithFrame:CGRectZero] autorelease];
  self.view = self.toolbar;
  self.toolbar.delegate = self;

  [self setupBarButtonItems];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    [self setupBoardPositionViews];
  [self setupNotificationResponders];

  self.toolbarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupBarButtonItems
{
  self.navigationBarButtonItems = [NSMutableArray arrayWithCapacity:0];
  self.navigationBarButtonItemsBackward = [NSMutableArray arrayWithCapacity:0];
  self.navigationBarButtonItemsForward = [NSMutableArray arrayWithCapacity:0];
  UIBarButtonItem* navigationBarButtonSpacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                              target:nil
                                                                                              action:nil] autorelease];
  navigationBarButtonSpacer.width = [AutoLayoutUtility horizontalSpacingSiblings];

  enum NavigationDirection direction = NavigationDirectionBackward;
  [self addButtonWithImageNamed:rewindToStartButtonIconResource withSelector:@selector(rewindToStart:) navigationDirection:direction];
  [self.navigationBarButtonItems addObject:navigationBarButtonSpacer];
  [self addButtonWithImageNamed:backButtonIconResource withSelector:@selector(previousBoardPosition:) navigationDirection:direction];
  [self.navigationBarButtonItems addObject:navigationBarButtonSpacer];
  direction = NavigationDirectionForward;
  [self addButtonWithImageNamed:forwardButtonIconResource withSelector:@selector(nextBoardPosition:) navigationDirection:direction];
  [self.navigationBarButtonItems addObject:navigationBarButtonSpacer];
  [self addButtonWithImageNamed:forwardToEndButtonIconResource withSelector:@selector(fastForwardToEnd:) navigationDirection:direction];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupBarButtonItems().
// -----------------------------------------------------------------------------
- (void) addButtonWithImageNamed:(NSString*)imageName withSelector:(SEL)selector navigationDirection:(enum NavigationDirection)direction
{
  UIBarButtonItem* button = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageName]
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:selector] autorelease];
  [self.navigationBarButtonItems addObject:button];
  if (NavigationDirectionBackward == direction)
    [self.navigationBarButtonItemsBackward addObject:button];
  else
    [self.navigationBarButtonItemsForward addObject:button];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionViews
{
  [self.view addSubview:self.boardPositionListViewController.view];
  [self.view addSubview:self.currentBoardPositionViewController.view];

  self.boardPositionListViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.currentBoardPositionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  int toolbarPaddingHorizontal = [AutoLayoutUtility horizontalSpacingSiblings];
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.boardPositionListViewController.view, @"boardPositionListView",
                                   self.currentBoardPositionViewController.view, @"currentBoardPositionView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            [NSString stringWithFormat:@"H:|-%d-[boardPositionListView]-[currentBoardPositionView]-%d-|", toolbarPaddingHorizontal, toolbarPaddingHorizontal],
                            // This works because currentBoardPositionView has
                            // an intrinsic content size
                            @"V:[boardPositionListView(==currentBoardPositionView)]",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];
  [AutoLayoutUtility alignFirstView:self.boardPositionListViewController.view
                     withSecondView:self.view
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self.view];
  [AutoLayoutUtility alignFirstView:self.currentBoardPositionViewController.view
                     withSecondView:self.view
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self.view];
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
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  self.buttonStatesNeedUpdate = true;
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
      self.buttonStatesNeedUpdate = true;
    else if ([keyPath isEqualToString:@"numberOfBoardPositions"])
      self.buttonStatesNeedUpdate = true;
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
  [self populateToolbar];
  [self updateButtonStates];
}

// -----------------------------------------------------------------------------
/// @brief Populates the toolbar with bar button items.
// -----------------------------------------------------------------------------
- (void) populateToolbar
{
  if (! self.toolbarNeedsPopulation)
    return;
  self.toolbarNeedsPopulation = false;

  NSMutableArray* toolbarItems = [NSMutableArray arrayWithCapacity:0];
  if (self.boardPositionListViewIsVisible)
  {
    self.boardPositionListViewController.view.hidden = NO;
  }
  else
  {
    self.boardPositionListViewController.view.hidden = YES;
    [toolbarItems addObjectsFromArray:self.navigationBarButtonItems];
  }
  [self.toolbar setItems:toolbarItems animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of all toolbar items.
// -----------------------------------------------------------------------------
- (void) updateButtonStates
{
  if (! self.buttonStatesNeedUpdate)
    return;
  self.buttonStatesNeedUpdate = false;

  GoGame* game = [GoGame sharedGame];
  if (game.isComputerThinking || game.score.scoringInProgress)
  {
    for (UIBarButtonItem* item in self.navigationBarButtonItems)
      item.enabled = NO;
  }
  else
  {
    bool isFirstBoardPosition = game.boardPosition.isFirstPosition;
    for (UIBarButtonItem* item in self.navigationBarButtonItemsBackward)
      item.enabled = (isFirstBoardPosition ? NO : YES);
    bool isLastBoardPosition = game.boardPosition.isLastPosition;
    for (UIBarButtonItem* item in self.navigationBarButtonItemsForward)
      item.enabled = (isLastBoardPosition ? NO : YES);
  }
}

// -----------------------------------------------------------------------------
/// @brief Toggles the visible items in the toolbar between the board position
/// list view and the navigation buttons. The current board position view is
/// always visible.
// -----------------------------------------------------------------------------
- (void) toggleToolbarItems
{
  self.boardPositionListViewIsVisible = ! self.boardPositionListViewIsVisible;
  self.toolbarNeedsPopulation = true;
  [self delayedUpdate];
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

#pragma mark - CurrentBoardPositionViewControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief CurrentBoardPositionViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didTapCurrentBoardPositionViewController:(CurrentBoardPositionViewController*)controller
{
  [self toggleToolbarItems];
}

#pragma mark - UIBarPositioning overrides

// -----------------------------------------------------------------------------
/// @brief UIBarPositioning protocol method.
// -----------------------------------------------------------------------------
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return UIBarPositionBottom;
  else
    return UIBarPositionTop;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if taps on bar button items should currently be
/// ignored.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreTaps
{
  return [GoGame sharedGame].isComputerThinking;
}

@end
