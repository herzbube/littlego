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
#import "BoardPositionToolbarController.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../ui/UIElementMetrics.h"

// Enums
enum NavigationDirection
{
  NavigationDirectionBackward,
  NavigationDirectionForward
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// BoardPositionToolbarController.
// -----------------------------------------------------------------------------
@interface BoardPositionToolbarController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) goGameWillCreate:(NSNotification*)notification;
- (void) goGameDidCreate:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
- (void) longRunningActionStarts:(NSNotification*)notification;
- (void) longRunningActionEnds:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Updaters
//@{
- (void) delayedUpdate;
- (void) populateToolbar;
- (void) updateButtonStates;
//@}
/// @name Action methods
//@{
- (void) rewindToStart:(id)sender;
- (void) rewind:(id)sender;
- (void) previousBoardPosition:(id)sender;
- (void) nextBoardPosition:(id)sender;
- (void) fastForward:(id)sender;
- (void) fastForwardToEnd:(id)sender;
//@}
/// @name Private helpers
//@{
- (void) setupSpacerItems;
- (void) setupCustomViewItemsWithBoardPositionListView:(UIView*)listView currentBoardPositionView:(UIView*)currentView;
- (void) setupNavigationBarButtonItems;
- (void) addButtonWithImageNamed:(NSString*)imageName withSelector:(SEL)selector navigationDirection:(enum NavigationDirection)direction;
- (void) setupNotificationResponders;
//@}
/// @name Privately declared properties
//@{
/// @brief Updates are delayed as long as this is above zero.
@property(nonatomic, assign) int actionsInProgress;
@property(nonatomic, assign) bool toolbarNeedsPopulation;
@property(nonatomic, assign) bool buttonStatesNeedUpdate;
@property(nonatomic, assign) UIToolbar* toolbar;
@property(nonatomic, retain) UIBarButtonItem* negativeSpacer;
@property(nonatomic, retain) UIBarButtonItem* flexibleSpacer;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItems;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItemsBackward;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItemsForward;
@property(nonatomic, retain) UIBarButtonItem* boardPositionListViewItem;
@property(nonatomic, retain) UIBarButtonItem* currentBoardPositionViewItem;
@property(nonatomic, assign) bool boardPositionListViewIsVisible;
@property(nonatomic, assign) int numberOfBoardPositionsOnPage;
//@}
@end


@implementation BoardPositionToolbarController

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionToolbarController object that places its
/// buttons into @a aToolbar.
// -----------------------------------------------------------------------------
- (id) initWithToolbar:(UIToolbar*)aToolbar
{
  return [self initWithToolbar:aToolbar boardPositionListView:nil currentBoardPositionView:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionToolbarController object that places its
/// buttons, @a listView and @a currentView into @a aToolbar.
///
/// @note This is the designated initializer of BoardPositionToolbarController.
// -----------------------------------------------------------------------------
- (id) initWithToolbar:(UIToolbar*)aToolbar boardPositionListView:(UIView*)listView currentBoardPositionView:(UIView*)currentView
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.actionsInProgress = 0;
  self.toolbar = aToolbar;
  self.navigationBarButtonItems = [NSMutableArray arrayWithCapacity:0];
  self.navigationBarButtonItemsBackward = [NSMutableArray arrayWithCapacity:0];
  self.navigationBarButtonItemsForward = [NSMutableArray arrayWithCapacity:0];
  self.numberOfBoardPositionsOnPage = 10;
  self.boardPositionListViewIsVisible = false;

  [self setupSpacerItems];
  [self setupNavigationBarButtonItems];
  [self setupCustomViewItemsWithBoardPositionListView:listView currentBoardPositionView:currentView];
  [self setupNotificationResponders];

  self.toolbarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionToolbarController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  self.toolbar = nil;
  self.negativeSpacer = nil;
  self.flexibleSpacer = nil;
  self.navigationBarButtonItems = nil;
  self.navigationBarButtonItemsBackward = nil;
  self.navigationBarButtonItemsForward = nil;
  self.boardPositionListViewItem = nil;
  self.currentBoardPositionViewItem = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupSpacerItems
{
  self.negativeSpacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                       target:nil
                                                                       action:nil] autorelease];
  self.negativeSpacer.width = (-[UiElementMetrics toolbarCustomViewItemPaddingHorizontal]);
  self.flexibleSpacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                       target:nil
                                                                       action:nil] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNavigationBarButtonItems
{
  enum NavigationDirection direction = NavigationDirectionBackward;
  [self addButtonWithImageNamed:rewindToStartButtonIconResource withSelector:@selector(rewindToStart:) navigationDirection:direction];
  [self addButtonWithImageNamed:rewindButtonIconResource withSelector:@selector(rewind:) navigationDirection:direction];
  [self addButtonWithImageNamed:backButtonIconResource withSelector:@selector(previousBoardPosition:) navigationDirection:direction];
  direction = NavigationDirectionForward;
  [self addButtonWithImageNamed:playButtonIconResource withSelector:@selector(nextBoardPosition:) navigationDirection:direction];
  [self addButtonWithImageNamed:fastForwardButtonIconResource withSelector:@selector(fastForward:) navigationDirection:direction];
  [self addButtonWithImageNamed:forwardToEndButtonIconResource withSelector:@selector(fastForwardToEnd:) navigationDirection:direction];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupNavigationBarButtonItems().
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
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupCustomViewItemsWithBoardPositionListView:(UIView*)listView currentBoardPositionView:(UIView*)currentView
{
  if (listView)
    self.boardPositionListViewItem = [[[UIBarButtonItem alloc] initWithCustomView:listView] autorelease];
  else
    self.boardPositionListViewItem = nil;

  if (currentView)
    self.currentBoardPositionViewItem = [[[UIBarButtonItem alloc] initWithCustomView:currentView] autorelease];
  else
    self.currentBoardPositionViewItem = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(longRunningActionStarts:) name:longRunningActionStarts object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
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
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  self.toolbarNeedsPopulation = true;
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
/// @brief Responds to the #longRunningActionStarts notifications.
///
/// Increases @e actionsInProgress by 1.
// -----------------------------------------------------------------------------
- (void) longRunningActionStarts:(NSNotification*)notification
{
  self.actionsInProgress++;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notifications.
///
/// Decreases @e actionsInProgress by 1. Triggers a view update if
/// @e actionsInProgress becomes 0 and @e updatesWereDelayed is true.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  self.actionsInProgress--;
  if (0 == self.actionsInProgress)
    [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == [GoGame sharedGame].boardPosition)
  {
    if ([keyPath isEqualToString:@"currentBoardPosition"])
    {
      // It's annoying to have buttons appear and disappear all the time, so
      // we try to minimize this by keeping the same buttons in the toolbar
      // while the user is browsing board positions.
      self.buttonStatesNeedUpdate = true;
    }
    [self delayedUpdate];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if (self.actionsInProgress > 0)
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
    if (self.boardPositionListViewItem)
    {
      [toolbarItems addObject:self.negativeSpacer];
      [toolbarItems addObject:self.boardPositionListViewItem];
    }
    if (self.currentBoardPositionViewItem)
    {
      [toolbarItems addObject:self.flexibleSpacer];
      [toolbarItems addObject:self.currentBoardPositionViewItem];
      [toolbarItems addObject:self.negativeSpacer];
    }
  }
  else
  {
    [toolbarItems addObjectsFromArray:self.navigationBarButtonItems];
    if (self.currentBoardPositionViewItem)
    {
      [toolbarItems addObject:self.flexibleSpacer];
      [toolbarItems addObject:self.currentBoardPositionViewItem];
      [toolbarItems addObject:self.negativeSpacer];
    }
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
  if (game.isComputerThinking)
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

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "rewind to start" button.
// -----------------------------------------------------------------------------
- (void) rewindToStart:(id)sender
{
  [[[ChangeBoardPositionCommand alloc] initWithFirstBoardPosition] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "rewind" button.
// -----------------------------------------------------------------------------
- (void) rewind:(id)sender
{
  [[[ChangeBoardPositionCommand alloc] initWithOffset:(- self.numberOfBoardPositionsOnPage)] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "previous board position" button.
// -----------------------------------------------------------------------------
- (void) previousBoardPosition:(id)sender
{
  [[[ChangeBoardPositionCommand alloc] initWithOffset:-1] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "next board position" button.
// -----------------------------------------------------------------------------
- (void) nextBoardPosition:(id)sender
{
  [[[ChangeBoardPositionCommand alloc] initWithOffset:1] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "fast forward" button.
// -----------------------------------------------------------------------------
- (void) fastForward:(id)sender
{
  [[[ChangeBoardPositionCommand alloc] initWithOffset:self.numberOfBoardPositionsOnPage] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "fast forward to end" button.
// -----------------------------------------------------------------------------
- (void) fastForwardToEnd:(id)sender
{
  [[[ChangeBoardPositionCommand alloc] initWithLastBoardPosition] submit];
}

@end
