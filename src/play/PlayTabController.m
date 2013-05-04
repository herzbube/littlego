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
#import "PlayTabController.h"
#import "PlayView.h"
#import "PlayViewController.h"
#import "boardposition/BoardPositionController.h"
#import "boardposition/BoardPositionToolbarController.h"
#import "controller/DiscardFutureMovesAlertController.h"
#import "controller/NavigationBarController.h"
#import "controller/StatusViewController.h"
#import "gesture/PanGestureController.h"
#import "scrollview/ScrollViewController.h"
#import "splitview/LeftPaneViewController.h"
#import "splitview/RightPaneViewController.h"
#import "../ui/UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayTabController.
// -----------------------------------------------------------------------------
@interface PlayTabController()
@property(nonatomic, retain) UISplitViewController* splitViewController;
@property(nonatomic, retain) LeftPaneViewController* leftPaneViewController;
@property(nonatomic, retain) RightPaneViewController* rightPaneViewController;
@property(nonatomic, retain) DiscardFutureMovesAlertController* discardFutureMovesAlertController;
@end


@implementation PlayTabController

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayTabController object.
///
/// @note This is the designated initializer of PlayTabController.
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
/// @brief Deallocates memory allocated by this PlayTabController object.
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

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    self.boardPositionController = [[[BoardPositionToolbarController alloc] init] autorelease];
//xxx    self.boardPositionController.currentBoardPositionViewController.delegate = self.scrollViewController.playViewController;
  }
  else
  {
    self.splitViewController = [[[UISplitViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    [self addChildViewController:self.splitViewController];
    [self.splitViewController didMoveToParentViewController:self];

    // Must assign a delegate, otherwise UISplitViewController will not react to
    // swipe gestures (tested in 5.1 and 6.0 simulator; 5.0 does not support the
    // swipe anyway). Reported to Apple with problem ID 13133575.
    self.splitViewController.delegate = self.navigationBarController;
    self.leftPaneViewController = [[[LeftPaneViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    self.rightPaneViewController = [[[RightPaneViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    self.splitViewController.viewControllers = [NSArray arrayWithObjects:self.leftPaneViewController, self.rightPaneViewController, nil];

    self.boardPositionController = [[[BoardPositionController alloc] init] autorelease];
  }

  self.discardFutureMovesAlertController = [[[DiscardFutureMovesAlertController alloc] init] autorelease];
  self.scrollViewController.playViewController.panGestureController.delegate = self.discardFutureMovesAlertController;
  self.navigationBarController.delegate = self.discardFutureMovesAlertController;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc and viewDidUnload
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.view = nil;
  self.splitViewController = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
  self.navigationBarController = nil;
  self.scrollViewController = nil;
  self.boardPositionController = nil;
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
- (void) setBoardPositionController:(UIViewController*)boardPositionController
{
  if (_boardPositionController == boardPositionController)
    return;
  if (_boardPositionController)
  {
    [_boardPositionController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionController removeFromParentViewController];
    [_boardPositionController release];
    _boardPositionController = nil;
  }
  if (boardPositionController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionController];
    [boardPositionController didMoveToParentViewController:self];
    [boardPositionController retain];
    _boardPositionController = boardPositionController;
  }
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  // Note: If the user is holding the device in landscape orientation while the
  // application is starting up, iOS will first start up in portrait orientation
  // and then initiate an auto-rotation to landscape orientation. Because the
  // main view and its subviews have an autoresizing mask, they will have the
  // correct size when they are finally displayed.
  [self setupMainView];

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    [self setupNavigationBar];
    [self setupBoardPositionToolbar];  // set up before scroll view because scroll view depends on toolbar position
    [self setupScrollView];
    // TODO xxx shouldn't the scrollviewcontroller be responsible for this?
    [self setupCoordinateLabelScrollViews];
  }
  else
  {
    [self setupSplitView];
    [self setupNavigationBar];
    [self setupScrollView];
    // TODO xxx shouldn't the scrollviewcontroller be responsible for this?
    [self setupCoordinateLabelScrollViews];
    [self setupBoardPositionView];
  }

  // TODO xxx Should we know statusviewcontroller and playViewController?
  self.navigationBarController.statusViewController.playView = self.scrollViewController.playViewController.playView;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by loadView().
// -----------------------------------------------------------------------------
- (void) setupMainView
{
  CGRect mainViewFrame = [self mainViewFrame];
  self.view = [[[UIView alloc] initWithFrame:mainViewFrame] autorelease];
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:woodenBackgroundImageResource]];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupMainView().
// -----------------------------------------------------------------------------
- (CGRect) mainViewFrame
{
  int mainViewX = 0;
  int mainViewY = 0;
  int mainViewWidth = [UiElementMetrics screenWidth];
  int mainViewHeight = ([UiElementMetrics screenHeight]
                        - [UiElementMetrics tabBarHeight]
                        - [UiElementMetrics statusBarHeight]);
  return CGRectMake(mainViewX, mainViewY, mainViewWidth, mainViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (void) setupSplitView
{
  CGRect splitViewControllerViewFrame = [self splitViewFrame];
  self.splitViewController.view.frame = splitViewControllerViewFrame;
  UIView* superview = [self splitViewSuperview];
  [superview addSubview:self.splitViewController.view];

  // Set left/right panes to use the same height as the split view
  CGRect leftPaneViewFrame = CGRectMake(0, 0, [UiElementMetrics splitViewLeftPaneWidth], [UiElementMetrics splitViewHeight]);
  leftPaneViewFrame.size.height = splitViewControllerViewFrame.size.height;
  self.leftPaneViewController.view.frame = leftPaneViewFrame;
  CGRect rightPaneViewFrame = CGRectMake(0, 0, [UiElementMetrics splitViewRightPaneWidth], [UiElementMetrics splitViewHeight]);
  rightPaneViewFrame.size.height = splitViewControllerViewFrame.size.height;
  self.rightPaneViewController.view.frame = rightPaneViewFrame;

  self.rightPaneViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:woodenBackgroundImageResource]];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupMainView().
// -----------------------------------------------------------------------------
- (CGRect) splitViewFrame
{
  UIView* superview = [self splitViewSuperview];
  return superview.bounds;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) splitViewSuperview
{
  return self.view;
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
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return self.view;
  else
    return self.rightPaneViewController.view;
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
  int viewHeight;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    viewHeight = (superviewSize.height
                  - self.navigationBarController.view.frame.size.height
                  - self.boardPositionController.view.frame.size.height);
  }
  else
  {
    viewHeight = (superviewSize.height
                  - self.navigationBarController.view.frame.size.height);
  }
  return CGRectMake(viewX, viewY, viewWidth, viewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) scrollViewSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return self.view;
  else
    return self.rightPaneViewController.view;
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
  self.boardPositionController.view.frame = toolbarFrame;
  UIView* superview = [self boardPositionToolbarSuperview];
  [superview addSubview:self.boardPositionController.view];
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
    toolbarViewY = superview.bounds.size.height - toolbarViewHeight;
  else
    toolbarViewY = 0;  // TODO xxx unused
  return CGRectMake(toolbarViewX, toolbarViewY, toolbarViewWidth, toolbarViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) boardPositionToolbarSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return self.view;
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionView
{
  CGRect boardPositionViewFrame = [self boardPositionViewFrame];
  self.boardPositionController.view.frame = boardPositionViewFrame;
  UIView* superview = [self boardPositionViewSuperview];
  [superview addSubview:self.boardPositionController.view];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (CGRect) boardPositionViewFrame
{
  UIView* superview = [self boardPositionViewSuperview];
  return superview.bounds;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the view hierarchy is
/// created.
// -----------------------------------------------------------------------------
- (UIView*) boardPositionViewSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return nil;
  else
    return self.leftPaneViewController.view;
}

@end
