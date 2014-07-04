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
#import "RightPaneViewController.h"
#import "../boardview/BoardViewController.h"
#import "../controller/DiscardFutureMovesAlertController.h"
#import "../controller/NavigationBarController.h"
#import "../controller/StatusViewController.h"
#import "../gesture/PanGestureController.h"
#import "../playview/PlayView.h"
#import "../playview/PlayViewController.h"
#import "../playview/ScrollViewController.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for RightPaneViewController.
// -----------------------------------------------------------------------------
@interface RightPaneViewController()
@property(nonatomic, retain) ScrollViewController* scrollViewController;
@property(nonatomic, retain) DiscardFutureMovesAlertController* discardFutureMovesAlertController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@end


@implementation RightPaneViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a RightPaneViewController object.
///
/// @note This is the designated initializer of RightPaneViewController.
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
/// @brief Deallocates memory allocated by this RightPaneViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.navigationBarController = nil;
  self.scrollViewController = nil;
  self.discardFutureMovesAlertController = nil;
  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.navigationBarController = [[[NavigationBarController alloc] init] autorelease];
  self.scrollViewController = [[[ScrollViewController alloc] init] autorelease];
  self.discardFutureMovesAlertController = [[[DiscardFutureMovesAlertController alloc] init] autorelease];
  self.boardViewController = [[[BoardViewController alloc] init] autorelease];

  if (useTiling)
    self.boardViewController.panGestureController.delegate = self.discardFutureMovesAlertController;
  else
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
  [self configureViews];
  [self configureControllers];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.navigationBarController.view];
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
  if (useTiling)
    self.automaticallyAdjustsScrollViewInsets = NO;

  self.navigationBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary;
  NSArray* visualFormats;
  if (useTiling)
  {
    viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                       self.navigationBarController.view, @"navigationBarView",
                       self.boardViewController.view, @"boardView",
                       nil];
    // Don't need to specify height value for navigationBarView because
    // UINavigationBar specifies a height value in its intrinsic content size
    visualFormats = [NSArray arrayWithObjects:
                     @"H:|-0-[navigationBarView]-0-|",
                     @"H:|-0-[boardView]-0-|",
                     @"V:|-0-[navigationBarView]-0-[boardView]-0-|",
                     nil];
  }
  else
  {
    viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                       self.navigationBarController.view, @"navigationBarView",
                       self.scrollViewController.view, @"scrollViewControllerView",
                       nil];
    // Don't need to specify height value for navigationBarView because
    // UINavigationBar specifies a height value in its intrinsic content size
    visualFormats = [NSArray arrayWithObjects:
                     @"H:|-0-[navigationBarView]-0-|",
                     @"H:|-0-[scrollViewControllerView]-0-|",
                     @"V:|-0-[navigationBarView]-0-[scrollViewControllerView]-0-|",
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

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  // Set a color (should be the same as the main window's) because we need to
  // paint over the parent split view background color.
  self.view.backgroundColor = [UIColor whiteColor];
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
