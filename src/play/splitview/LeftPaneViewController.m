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
#import "LeftPaneViewController.h"
#import "../boardposition/BoardPositionCollectionViewController.h"
#import "../boardposition/BoardPositionTableListViewController.h"
#import "../boardposition/BoardPositionToolbarController.h"
#import "../controller/StatusViewController.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LeftPaneViewController.
// -----------------------------------------------------------------------------
@interface LeftPaneViewController()
@property(nonatomic, assign) bool useBoardPositionToolbar;
@property(nonatomic, retain) BoardPositionCollectionViewController* boardPositionCollectionViewController;
@property(nonatomic, retain) BoardPositionToolbarController* boardPositionToolbarController;
@property(nonatomic, retain) BoardPositionTableListViewController* boardPositionTableListViewController;
@property(nonatomic, retain) StatusViewController* statusViewController;
@end


@implementation LeftPaneViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a LeftPaneViewController object.
///
/// @note This is the designated initializer of LeftPaneViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupUseBoardPositionToolbar];
  [self setupChildControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LeftPaneViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardPositionToolbarController = nil;
  self.boardPositionTableListViewController = nil;

  self.boardPositionCollectionViewController = nil;
  self.statusViewController = nil;
  
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for initializer.
// -----------------------------------------------------------------------------
- (void) setupUseBoardPositionToolbar
{
  if ([LayoutManager sharedManager].uiType == UITypePhone)
    self.useBoardPositionToolbar = false;
  else
    self.useBoardPositionToolbar = true;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  if (self.useBoardPositionToolbar)
  {
    self.boardPositionToolbarController = [[[BoardPositionToolbarController alloc] init] autorelease];
    self.boardPositionTableListViewController = [[[BoardPositionTableListViewController alloc] init] autorelease];
  }
  else
  {
    self.boardPositionCollectionViewController = [[[BoardPositionCollectionViewController alloc] initWithScrollDirection:UICollectionViewScrollDirectionVertical] autorelease];
    self.statusViewController = [[[StatusViewController alloc] init] autorelease];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardPositionToolbarController:(BoardPositionToolbarController*)boardPositionToolbarController
{
  if (_boardPositionToolbarController == boardPositionToolbarController)
    return;
  if (_boardPositionToolbarController)
  {
    [_boardPositionToolbarController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionToolbarController removeFromParentViewController];
    [_boardPositionToolbarController release];
    _boardPositionToolbarController = nil;
  }
  if (boardPositionToolbarController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionToolbarController];
    [boardPositionToolbarController didMoveToParentViewController:self];
    [boardPositionToolbarController retain];
    _boardPositionToolbarController = boardPositionToolbarController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardPositionTableListViewController:(BoardPositionTableListViewController*)boardPositionTableListViewController
{
  if (_boardPositionTableListViewController == boardPositionTableListViewController)
    return;
  if (_boardPositionTableListViewController)
  {
    [_boardPositionTableListViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionTableListViewController removeFromParentViewController];
    [_boardPositionTableListViewController release];
    _boardPositionTableListViewController = nil;
  }
  if (boardPositionTableListViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionTableListViewController];
    [boardPositionTableListViewController didMoveToParentViewController:self];
    [boardPositionTableListViewController retain];
    _boardPositionTableListViewController = boardPositionTableListViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardPositionCollectionViewController:(BoardPositionCollectionViewController*)boardPositionCollectionViewController
{
  if (_boardPositionCollectionViewController == boardPositionCollectionViewController)
    return;
  if (_boardPositionCollectionViewController)
  {
    [_boardPositionCollectionViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionCollectionViewController removeFromParentViewController];
    [_boardPositionCollectionViewController release];
    _boardPositionCollectionViewController = nil;
  }
  if (boardPositionCollectionViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionCollectionViewController];
    [boardPositionCollectionViewController didMoveToParentViewController:self];
    [boardPositionCollectionViewController retain];
    _boardPositionCollectionViewController = boardPositionCollectionViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setStatusViewController:(StatusViewController*)statusViewController
{
  if (_statusViewController == statusViewController)
    return;
  if (_statusViewController)
  {
    [_statusViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_statusViewController removeFromParentViewController];
    [_statusViewController release];
    _statusViewController = nil;
  }
  if (statusViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:statusViewController];
    [statusViewController didMoveToParentViewController:self];
    [statusViewController retain];
    _statusViewController = statusViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  if (self.useBoardPositionToolbar)
  {
    [self.view addSubview:self.boardPositionToolbarController.view];
    [self.view addSubview:self.boardPositionTableListViewController.view];
    self.boardPositionToolbarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardPositionTableListViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    viewsDictionary[@"boardPositionToolbar"] = self.boardPositionToolbarController.view;
    viewsDictionary[@"boardPositionTableListView"] = self.boardPositionTableListViewController.view;
    [visualFormats addObject:@"H:|-0-[boardPositionToolbar]-0-|"];
    [visualFormats addObject:@"H:|-0-[boardPositionTableListView]-0-|"];
    // Don't need to specify a height value for boardPositionToolbar because
    // UIToolbar specifies a height value in its intrinsic content size
    [visualFormats addObject:@"V:|-0-[boardPositionToolbar]-0-[boardPositionTableListView]-0-|"];
  }
  else
  {
    [self.view addSubview:self.boardPositionCollectionViewController.view];
    [self.view addSubview:self.statusViewController.view];
    self.boardPositionCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    viewsDictionary[@"boardPositionCollectionView"] = self.boardPositionCollectionViewController.view;
    viewsDictionary[@"statusView"] = self.statusViewController.view;
    [visualFormats addObject:@"H:|-0-[boardPositionCollectionView]-0-|"];
    [visualFormats addObject:@"H:|-0-[statusView]-0-|"];
    [visualFormats addObject:@"V:|-0-[boardPositionCollectionView]-0-[statusView]-0-|"];
  }

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  if (! self.useBoardPositionToolbar)
  {
    // Here we define the statusView height, and by consequence the height of
    // the boardPositionCollectionView. The status view extends upwards from the
    // safe area bottom so that on devices that don't have a physical Home
    // button the actual status view content is not overlapped by the Home
    // indicator. For this to work the status view is required to honor
    // safeAreaLayoutGuide.
    //
    // TODO This does not work if the app directly launches into landscape.
    // It only works after rotating once to portrait and then rotating back to
    // landscape. Tried to move this to viewWillLayoutSubviews, but didn't work.
    UIView* anchorView = self.view;
    NSLayoutYAxisAnchor* bottomAnchor;
    if (@available(iOS 11.0, *))
    {
      UILayoutGuide* layoutGuide = anchorView.safeAreaLayoutGuide;
      bottomAnchor = layoutGuide.bottomAnchor;
    }
    else
    {
      bottomAnchor = anchorView.bottomAnchor;
    }
    // This multiplier was experimentally determined so that even with 4 lines
    // of text there is a comfortable spacing at the top/bottom of the status
    // view label. The multiplier is closely linked to the label's font size.
    CGFloat statusViewContentHeightMultiplier = 1.4f;
    int statusViewContentHeight = [UiElementMetrics tableViewCellContentViewHeight] * statusViewContentHeightMultiplier;
    [self.statusViewController.view.topAnchor constraintEqualToAnchor:bottomAnchor
                                                             constant:-statusViewContentHeight].active = YES;
  }
}

@end
