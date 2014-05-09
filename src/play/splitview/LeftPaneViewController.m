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
#import "LeftPaneViewController.h"
#import "../boardposition/BoardPositionTableListViewController.h"
#import "../boardposition/BoardPositionToolbarController.h"
#import "../../ui/UiUtilities.h"
#import "../../ui/AutoLayoutUtility.h"


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
  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.boardPositionToolbarController = [[[BoardPositionToolbarController alloc] init] autorelease];
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
    [_boardPositionToolbarController didMoveToParentViewController:self];
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
    [_boardPositionTableListViewController didMoveToParentViewController:self];
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

  [self.view addSubview:self.boardPositionToolbarController.view];
  [self.view addSubview:self.boardPositionTableListViewController.view];

  self.boardPositionToolbarController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionTableListViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.boardPositionToolbarController.view, @"boardPositionToolbar",
                                   self.boardPositionTableListViewController.view, @"boardPositionTableListView",
                                   nil];
  // Don't need to specify height value for boardPositionToolbar because
  // UIToolbar specifies a height value in its intrinsic content size
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-0-[boardPositionToolbar]-0-|",
                            @"H:|-0-[boardPositionTableListView]-0-|",
                            @"V:|-0-[boardPositionToolbar]-[boardPositionTableListView]-0-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  // Set a color (should be the same as the main window's) because we need to
  // paint over the parent split view background color.
  self.view.backgroundColor = [UIColor whiteColor];
}

@end
