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
- (void) computerPlayerThinkingStarts:(NSNotification*)notification;
- (void) computerPlayerThinkingStops:(NSNotification*)notification;
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
- (void) addButtonWithImageNamed:(NSString*)imageName withSelector:(SEL)selector;
- (void) setupNotificationResponders;
- (void) populateToolbar;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) UIToolbar* toolbar;
@property(nonatomic, retain) UIBarButtonItem* negativeSpacer;
@property(nonatomic, retain) UIBarButtonItem* flexibleSpacer;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItems;
@property(nonatomic, retain) UIBarButtonItem* boardPositionListViewItem;
@property(nonatomic, retain) UIBarButtonItem* currentBoardPositionViewItem;
@property(nonatomic, assign) bool boardPositionListViewIsVisible;
@property(nonatomic, assign) int numberOfBoardPositionsOnPage;
@property(nonatomic, assign, getter=isTappingEnabled) bool tappingEnabled;
//@}
@end


@implementation BoardPositionToolbarController

@synthesize toolbar;
@synthesize negativeSpacer;
@synthesize flexibleSpacer;
@synthesize navigationBarButtonItems;
@synthesize boardPositionListViewItem;
@synthesize currentBoardPositionViewItem;
@synthesize boardPositionListViewIsVisible;
@synthesize numberOfBoardPositionsOnPage;
@synthesize tappingEnabled;


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

  self.toolbar = aToolbar;
  self.navigationBarButtonItems = [NSMutableArray arrayWithCapacity:0];
  self.numberOfBoardPositionsOnPage = 10;
  self.boardPositionListViewIsVisible = false;
  self.tappingEnabled = true;

  [self setupSpacerItems];
  [self setupNavigationBarButtonItems];
  [self setupCustomViewItemsWithBoardPositionListView:listView currentBoardPositionView:currentView];
  [self setupNotificationResponders];
  [self populateToolbar];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionToolbarController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.toolbar = nil;
  self.negativeSpacer = nil;
  self.flexibleSpacer = nil;
  self.navigationBarButtonItems = nil;
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
  [self addButtonWithImageNamed:rewindToStartButtonIconResource withSelector:@selector(rewindToStart:)];
  [self addButtonWithImageNamed:rewindButtonIconResource withSelector:@selector(rewind:)];
  [self addButtonWithImageNamed:backButtonIconResource withSelector:@selector(previousBoardPosition:)];
  [self addButtonWithImageNamed:playButtonIconResource withSelector:@selector(nextBoardPosition:)];
  [self addButtonWithImageNamed:fastForwardButtonIconResource withSelector:@selector(fastForward:)];
  [self addButtonWithImageNamed:forwardToEndButtonIconResource withSelector:@selector(fastForwardToEnd:)];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupNavigationBarButtonItems().
// -----------------------------------------------------------------------------
- (void) addButtonWithImageNamed:(NSString*)imageName withSelector:(SEL)selector
{
  UIBarButtonItem* button = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageName]
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:selector] autorelease];
  [self.navigationBarButtonItems addObject:button];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupCustomViewItemsWithBoardPositionListView:(UIView*)listView currentBoardPositionView:(UIView*)currentView
{
  self.boardPositionListViewItem = [[UIBarButtonItem alloc] initWithCustomView:listView];
  self.currentBoardPositionViewItem = [[UIBarButtonItem alloc] initWithCustomView:currentView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(computerPlayerThinkingStarts:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStops:) name:computerPlayerThinkingStops object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Toggles the visible items in the toolbar between the board position
/// list view and the navigation buttons. The current board position view is
/// always visible.
// -----------------------------------------------------------------------------
- (void) toggleToolbarItems
{
  self.boardPositionListViewIsVisible = ! self.boardPositionListViewIsVisible;
  [self populateToolbar];
}

// -----------------------------------------------------------------------------
/// @brief Populates the toolbar with bar button items.
// -----------------------------------------------------------------------------
- (void) populateToolbar
{
  NSMutableArray* toolbarItems = [NSMutableArray arrayWithCapacity:0];
  if (self.boardPositionListViewIsVisible)
  {
    [toolbarItems addObject:self.negativeSpacer];
    [toolbarItems addObject:self.boardPositionListViewItem];
    [toolbarItems addObject:self.flexibleSpacer];
    [toolbarItems addObject:self.currentBoardPositionViewItem];
    [toolbarItems addObject:self.negativeSpacer];
  }
  else
  {
    [toolbarItems addObjectsFromArray:self.navigationBarButtonItems];
    [toolbarItems addObject:self.flexibleSpacer];
    [toolbarItems addObject:self.currentBoardPositionViewItem];
    [toolbarItems addObject:self.negativeSpacer];
  }
  [self.toolbar setItems:toolbarItems animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStarts:(NSNotification*)notification
{
  self.tappingEnabled = false;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStops notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStops:(NSNotification*)notification
{
  self.tappingEnabled = true;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "rewind to start" button.
// -----------------------------------------------------------------------------
- (void) rewindToStart:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithFirstBoardPosition] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "rewind" button.
// -----------------------------------------------------------------------------
- (void) rewind:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithOffset:(- self.numberOfBoardPositionsOnPage)] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "previous board position" button.
// -----------------------------------------------------------------------------
- (void) previousBoardPosition:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithOffset:-1] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "next board position" button.
// -----------------------------------------------------------------------------
- (void) nextBoardPosition:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithOffset:1] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "fast forward" button.
// -----------------------------------------------------------------------------
- (void) fastForward:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithOffset:self.numberOfBoardPositionsOnPage] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "fast forward to end" button.
// -----------------------------------------------------------------------------
- (void) fastForwardToEnd:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithLastBoardPosition] submit];
}

@end
