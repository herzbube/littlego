// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
  if (self.useBoardPositionToolbar)
    self.boardPositionToolbarController = nil;
  else
    self.statusViewController = nil;
  self.boardPositionTableListViewController = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for initializer.
// -----------------------------------------------------------------------------
- (void) setupUseBoardPositionToolbar
{
  if ([LayoutManager sharedManager].uiType == UITypePhone)
  {
    bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    self.useBoardPositionToolbar = isPortraitOrientation;
  }
  else
  {
    self.useBoardPositionToolbar = true;
  }
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  if (self.useBoardPositionToolbar)
    self.boardPositionToolbarController = [[[BoardPositionToolbarController alloc] init] autorelease];
  else
    self.statusViewController = [[[StatusViewController alloc] init] autorelease];
  self.boardPositionTableListViewController = [[[BoardPositionTableListViewController alloc] init] autorelease];
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

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self.view addSubview:self.boardPositionTableListViewController.view];
  self.boardPositionTableListViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          self.boardPositionTableListViewController.view, @"boardPositionTableListView",
                                          nil];
  NSMutableArray* visualFormats = [NSMutableArray arrayWithObjects:
                                   @"H:|-0-[boardPositionTableListView]-0-|",
                                   nil];

  if (self.useBoardPositionToolbar)
  {
    [self.view addSubview:self.boardPositionToolbarController.view];
    self.boardPositionToolbarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.boardPositionToolbarController.view forKey:@"boardPositionToolbar"];
    [visualFormats addObject:@"H:|-0-[boardPositionToolbar]-0-|"];
    // Don't need to specify a height value for boardPositionToolbar because
    // UIToolbar specifies a height value in its intrinsic content size
    [visualFormats addObject:@"V:|-0-[boardPositionToolbar]-0-[boardPositionTableListView]-0-|"];
  }
  else
  {
    [self.view addSubview:self.statusViewController.view];
    self.statusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.statusViewController.view forKey:@"statusView"];
    [visualFormats addObject:@"H:|-0-[statusView]-0-|"];
    // Above the status view there are table view cells. It looks pretty good
    // if the status view has the same height (although it's a bit wasteful of
    // vertical space).
    int statusViewHeight = [UiElementMetrics tableViewCellContentViewHeight];
    [visualFormats addObject:[NSString stringWithFormat:@"V:|-0-[boardPositionTableListView]-0-[statusView(==%d)]-0-|", statusViewHeight]];
  }

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  // Set a color (should be the same as the main window's) because we need to
  // paint over the parent split view background color.
  self.view.backgroundColor = [UIColor whiteColor];
}

@end
