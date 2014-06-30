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
#import "PlayTabControllerPhone.h"
#import "../boardposition/BoardPositionToolbarController.h"
#import "../boardview/BoardViewController.h"
#import "../controller/DiscardFutureMovesAlertController.h"
#import "../controller/NavigationBarController.h"
#import "../controller/StatusViewController.h"
#import "../gesture/PanGestureController.h"
#import "../playview/PlayViewController.h"
#import "../playview/ScrollViewController.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayTabControllerPhone.
// -----------------------------------------------------------------------------
@interface PlayTabControllerPhone()
@property(nonatomic, retain) NavigationBarController* navigationBarController;
@property(nonatomic, retain) ScrollViewController* scrollViewController;
@property(nonatomic, retain) BoardPositionToolbarController* boardPositionToolbarController;
@property(nonatomic, retain) DiscardFutureMovesAlertController* discardFutureMovesAlertController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@end


@implementation PlayTabControllerPhone

#pragma mark - Initialization and deallocation

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
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.navigationBarController = nil;
  self.scrollViewController = nil;
  self.boardPositionToolbarController = nil;
  self.discardFutureMovesAlertController = nil;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.navigationBarController = [[[NavigationBarController alloc] init] autorelease];
  self.scrollViewController = [[[ScrollViewController alloc] init] autorelease];
  self.boardPositionToolbarController = [[[BoardPositionToolbarController alloc] init] autorelease];
  self.discardFutureMovesAlertController = [[[DiscardFutureMovesAlertController alloc] init] autorelease];
  self.boardViewController = [[[BoardViewController alloc] init] autorelease];

  self.scrollViewController.playViewController.panGestureController.delegate = self.discardFutureMovesAlertController;
  self.navigationBarController.delegate = self.discardFutureMovesAlertController;
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
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardViewController:(BoardViewController*)boardViewController
{
  if (_boardViewController == boardViewController)
    return;
  if (_boardViewController)
  {
    [_boardViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardViewController removeFromParentViewController];
    [_boardViewController release];
    _boardViewController = nil;
  }
  if (boardViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardViewController];
    [boardViewController didMoveToParentViewController:self];
    [boardViewController retain];
    _boardViewController = boardViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureControllers];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.navigationBarController.view];
  [self.view addSubview:self.boardPositionToolbarController.view];
  if (useTiling)
    [self.view addSubview:self.boardViewController.view];
  else
    [self.view addSubview:self.scrollViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.edgesForExtendedLayout = UIRectEdgeNone;
  if (useTiling)
    self.automaticallyAdjustsScrollViewInsets = NO;

  self.navigationBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionToolbarController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary;
  NSArray* visualFormats;
  if (useTiling)
  {
    viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                       self.navigationBarController.view, @"navigationBarView",
                       self.boardPositionToolbarController.view, @"boardPositionToolbarView",
                       self.boardViewController.view, @"boardView",
                       nil];
    visualFormats = [NSArray arrayWithObjects:
                     @"H:|-0-[navigationBarView]-0-|",
                     @"H:|-0-[boardView]-0-|",
                     @"H:|-0-[boardPositionToolbarView]-0-|",
                     [NSString stringWithFormat:@"V:|-%d-[navigationBarView]", [UiElementMetrics statusBarHeight]],
                     @"V:[boardPositionToolbarView]-0-|",
                     nil];
  }
  else
  {
    viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                       self.navigationBarController.view, @"navigationBarView",
                       self.scrollViewController.view, @"scrollViewControllerView",
                       self.boardPositionToolbarController.view, @"boardPositionToolbarView",
                       nil];
    visualFormats = [NSArray arrayWithObjects:
                     @"H:|-0-[navigationBarView]-0-|",
                     @"H:|-0-[scrollViewControllerView]-0-|",
                     @"H:|-0-[boardPositionToolbarView]-0-|",
                     [NSString stringWithFormat:@"V:|-%d-[navigationBarView]-0-[scrollViewControllerView]-0-[boardPositionToolbarView]-0-|", [UiElementMetrics statusBarHeight]],
                     nil];
  }
  for (NSString* visualFormat in visualFormats)
  {
    NSArray* constraint = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:viewsDictionary];
    [self.view addConstraints:constraint];
  }
}

- (void) viewDidLayoutSubviews
{
  if (! useTiling)
    return;
  static bool constraintsNotYetInstalled = true;
  if (constraintsNotYetInstalled)
  {
    constraintsNotYetInstalled = false;
    NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                     self.navigationBarController.view, @"navigationBarView",
                                     self.boardViewController.view, @"boardView",
                                     self.boardPositionToolbarController.view, @"boardPositionToolbarView",
                                     //self.bottomLayoutGuide, @"bottomLayoutGuide",
                                     nil];
    NSArray* visualFormats = [NSArray arrayWithObjects:
                              @"V:[navigationBarView]-0-[boardView]-0-[boardPositionToolbarView]",
                              nil];
    [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
    // We must call this to avoid a crash; this is as per documentation of the
    // topLayoutGuide and bottomLayoutGuide properties.
    [self.view layoutSubviews];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureControllers
{
  // TODO xxx replace this with a notification to remove the direct coupling;
  // also check if there are other couplings, e.g. in the iPad controller
  self.navigationBarController.statusViewController.playView = self.scrollViewController.playViewController.playView;
}

@end
