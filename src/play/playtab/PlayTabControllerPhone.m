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
#import "PlayTabControllerPhone.h"
#import "../boardposition/BoardPositionToolbarController.h"
#import "../controller/DiscardFutureMovesAlertController.h"
#import "../controller/NavigationBarController.h"
#import "../controller/StatusViewController.h"
#import "../gesture/PanGestureController.h"
#import "../playview/PlayView.h"
#import "../playview/PlayViewController.h"
#import "../playview/ScrollViewController.h"
#import "../../ui/UiElementMetrics.h"


@implementation PlayTabControllerPhone

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayTabControllerPhone object.
///
/// @note This is the designated initializer of PlayTabControllerPhone.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (PlayTabController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupChildControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayTabControllerPhone object.
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
  self.navigationBarController = [[[NavigationBarController alloc] init] autorelease];
  self.scrollViewController = [[[ScrollViewController alloc] init] autorelease];
  self.boardPositionToolbarController = [[[BoardPositionToolbarController alloc] init] autorelease];
  self.discardFutureMovesAlertController = [[[DiscardFutureMovesAlertController alloc] init] autorelease];

//xxx    self.boardPositionToolbarController.currentBoardPositionViewController.delegate = self.scrollViewController.playViewController;
  self.scrollViewController.playViewController.panGestureController.delegate = self.discardFutureMovesAlertController;
  self.navigationBarController.delegate = self.discardFutureMovesAlertController;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc and viewDidUnload
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.navigationBarController = nil;
  self.scrollViewController = nil;
  self.boardPositionToolbarController = nil;
  self.discardFutureMovesAlertController = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setNavigationBarController:(NavigationBarController*)navigationBarController
{
  if (_navigationBarController == navigationBarController)
    return;
  if (_navigationBarController)
  {
    [_navigationBarController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_navigationBarController removeFromParentViewController];
    [_navigationBarController release];
    _navigationBarController = nil;
  }
  if (navigationBarController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:navigationBarController];
    [_navigationBarController didMoveToParentViewController:self];
    [navigationBarController retain];
    _navigationBarController = navigationBarController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setScrollViewController:(ScrollViewController*)scrollViewController
{
  if (_scrollViewController == scrollViewController)
    return;
  if (_scrollViewController)
  {
    [_scrollViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_scrollViewController removeFromParentViewController];
    [_scrollViewController release];
    _scrollViewController = nil;
  }
  if (scrollViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:scrollViewController];
    [scrollViewController didMoveToParentViewController:self];
    [scrollViewController retain];
    _scrollViewController = scrollViewController;
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
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:woodenBackgroundImageResource]];

  [self setupNavigationBar];
  // Set up before scroll view because scroll view height depends on toolbar
  // position
  [self setupBoardPositionToolbar];
  [self setupScrollView];
  // TODO xxx shouldn't the scrollviewcontroller be responsible for this?
  // if yes, then it should also be responsible for setting width/height
  [self setupCoordinateLabelScrollViews];

  // TODO xxx Should we know statusviewcontroller and playViewController?
  self.navigationBarController.statusViewController.playView = self.scrollViewController.playViewController.playView;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (void) setupNavigationBar
{
  CGRect navigationBarFrame = [self navigationBarFrame];
  self.navigationBarController.view.frame = navigationBarFrame;
  UIView* superview = [self navigationBarSuperview];
  [superview addSubview:self.navigationBarController.view];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (CGRect) navigationBarFrame
{
  UIView* superview = [self navigationBarSuperview];
  int viewX = 0;
  int viewY = 0;
  int viewWidth = superview.bounds.size.width;
  int viewHeight = [UiElementMetrics navigationBarHeight];
  return CGRectMake(viewX, viewY, viewWidth, viewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) navigationBarSuperview
{
  return self.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (void) setupScrollView
{
  CGRect scrollViewFrame = [self scrollViewFrame];
  self.scrollViewController.view.frame = scrollViewFrame;
  UIView* superview = [self scrollViewSuperview];
  [superview addSubview:self.scrollViewController.view];

  // TODO xxx should this not be the responsibility of self.scrollViewController?
  self.scrollViewController.scrollView.contentSize = scrollViewFrame.size;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (CGRect) scrollViewFrame
{
  UIView* superview = [self scrollViewSuperview];
  CGSize superviewSize = superview.bounds.size;
  int viewX = 0;
  int viewY = CGRectGetMaxY(self.navigationBarController.view.frame);
  int viewWidth = superviewSize.width;
  int viewHeight = (superviewSize.height
                    - self.navigationBarController.view.frame.size.height
                    - self.boardPositionToolbarController.view.frame.size.height);
  return CGRectMake(viewX, viewY, viewWidth, viewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) scrollViewSuperview
{
  return self.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (void) setupCoordinateLabelScrollViews
{
  UIView* superview = [self coordinateLabelScrollViewsSuperview];
  NSArray* scrollViews = [NSArray arrayWithObjects:
                          self.scrollViewController.playViewController.playView.coordinateLabelsLetterViewScrollView,
                          self.scrollViewController.playViewController.playView.coordinateLabelsNumberViewScrollView,
                          nil];
  for (UIView* scrollView in scrollViews)
  {
    CGRect scrollViewFrame = scrollView.frame;
    scrollViewFrame.origin = self.scrollViewController.view.frame.origin;
    scrollView.frame = scrollViewFrame;
    [superview addSubview:scrollView];
  }
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) coordinateLabelScrollViewsSuperview
{
  return [self scrollViewSuperview];
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
  int toolbarViewY = superview.bounds.size.height - toolbarViewHeight;
  return CGRectMake(toolbarViewX, toolbarViewY, toolbarViewWidth, toolbarViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) boardPositionToolbarSuperview
{
  return self.view;
}

@end
