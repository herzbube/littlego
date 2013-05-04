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
#import "BoardPositionController.h"
#import "BoardPositionTableListViewController.h"
#import "BoardPositionToolbarController.h"
#import "../../ui/UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardPositionController.
// -----------------------------------------------------------------------------
@interface BoardPositionController()
@property(nonatomic, retain) BoardPositionTableListViewController* boardPositionTableListViewController;
@property(nonatomic, retain) BoardPositionToolbarController* boardPositionToolbarController;
@end


@implementation BoardPositionController

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionController object.
///
/// @note This is the designated initializer of BoardPositionController.
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
/// @brief Deallocates memory allocated by this BoardPositionController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseObjects];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.boardPositionTableListViewController = [[[BoardPositionTableListViewController alloc] init] autorelease];
  self.boardPositionToolbarController = [[[BoardPositionToolbarController alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc and viewDidUnload
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.boardPositionTableListViewController = nil;
  self.boardPositionToolbarController = nil;
  self.view = nil;
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
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  CGRect frame = CGRectZero;
  // Setup of subviews requires that the parent view has a certain minimal
  // height, so we assign an arbitrary height here that will later be expanded
  // to the real height thanks to the autoresizingMask. Note that the height
  // must be greater than a toolbar height + some vertical spacing.
  frame.size.height = 200;
  self.view = [[[UIView alloc] initWithFrame:frame] autorelease];
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

  [self setupBoardPositionToolbar];
  [self setupBoardPositionTableListView];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionToolbar
{
  CGRect toolbarFrame = [self boardPositionToolbarFrame];
  self.boardPositionToolbarController.view.frame = toolbarFrame;
  UIView* superview = [self boardPositionToolbarSuperview];
  [superview addSubview:self.boardPositionToolbarController.view];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (CGRect) boardPositionToolbarFrame
{
  UIView* superview = [self boardPositionToolbarSuperview];
  int toolbarViewX = 0;
  int toolbarViewWidth = superview.bounds.size.width;
  int toolbarViewHeight = [UiElementMetrics toolbarHeight];
  int toolbarViewY;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    toolbarViewY = superview.bounds.size.height - toolbarViewHeight;  // TODO xxx unused
  else
    toolbarViewY = 0;
  return CGRectMake(toolbarViewX, toolbarViewY, toolbarViewWidth, toolbarViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) boardPositionToolbarSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return nil;
  else
    return self.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionTableListView
{
  CGRect boardPositionTableListViewFrame = [self boardPositionTableListViewFrame];
  self.boardPositionTableListViewController.view.frame = boardPositionTableListViewFrame;
  UIView* superview = [self boardPositionToolbarSuperview];
  [superview addSubview:self.boardPositionTableListViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (CGRect) boardPositionTableListViewFrame
{
  UIView* superview = [self boardPositionTableListViewSuperview];
  int viewX = 0;
  int viewWidth = superview.bounds.size.width;
  int viewY = CGRectGetMaxY(self.boardPositionToolbarController.view.frame) + [UiElementMetrics spacingVertical];
  int viewHeight = superview.bounds.size.height - viewY;
  return CGRectMake(viewX, viewY, viewWidth, viewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) boardPositionTableListViewSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return nil;
  else
    return self.view;
}

@end
