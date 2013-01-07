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
#import "BoardPositionListController.h"
#import "BoardPositionView.h"
#import "BoardPositionViewMetrics.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for BoardPositionListController.
// -----------------------------------------------------------------------------
@interface BoardPositionListController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) goGameWillCreate:(NSNotification*)notification;
- (void) goGameDidCreate:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name ItemScrollViewDataSource protocol
//@{
- (int) numberOfItemsInItemScrollView:(ItemScrollView*)itemScrollView;
- (UIView*) itemScrollView:(ItemScrollView*)itemScrollView itemViewAtIndex:(int)index;
- (int) itemWidthInItemScrollView:(ItemScrollView*)itemScrollView;
- (int) itemHeightInItemScrollView:(ItemScrollView*)itemScrollView;
//@}
/// @name Private helpers
//@{
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) BoardPositionViewMetrics* boardPositionViewMetrics;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) ItemScrollView* boardPositionListView;
//@}
@end


@implementation BoardPositionListController

@synthesize boardPositionViewMetrics;
@synthesize boardPositionListView;


// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionListController object.
///
/// @note This is the designated initializer of BoardPositionListController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.boardPositionViewMetrics = [[[BoardPositionViewMetrics alloc] init] autorelease];

  [self setupBoardPositionListView];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionListController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
  self.boardPositionViewMetrics = nil;
  self.boardPositionListView = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Creates and sets up the board position list view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionListView
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    CGRect boardPositionListViewFrame = CGRectZero;
    boardPositionListViewFrame.size = self.boardPositionViewMetrics.boardPositionListViewSize;
    enum ItemScrollViewOrientation boardPositionListViewOrientation = ItemScrollViewOrientationHorizontal;
    self.boardPositionListView = [[ItemScrollView alloc] initWithFrame:boardPositionListViewFrame
                                                           orientation:boardPositionListViewOrientation];
  }
  else
  {
    // TODO xxx implement for iPad; take orientation into account
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Not implemented yet"
                                                   userInfo:nil];
    @throw exception;
  }
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
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  [self.boardPositionListView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  [self.boardPositionListView reloadData];
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
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    return self.boardPositionViewMetrics.boardPositionViewWidth;
  }
  else
  {
    // TODO xxx implement for iPad; take orientation into account
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Not implemented yet"
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (int) itemHeightInItemScrollView:(ItemScrollView*)itemScrollView
{
  // TODO xxx implement for iPad; take orientation into account
  NSException* exception = [NSException exceptionWithName:NSGenericException
                                                   reason:@"Not implemented yet"
                                                 userInfo:nil];
  @throw exception;
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

@end
