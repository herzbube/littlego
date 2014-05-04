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
#import "../playview/CoordinateLabelsView.h"
#import "../playview/PlayView.h"
#import "../playview/PlayViewController.h"
#import "../playview/ScrollViewController.h"
#import "../../ui/UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MaxMemoryController.
// -----------------------------------------------------------------------------
@interface PlayTabControllerPhone()
@property(nonatomic, assign) UIView* backgroundView;
@property(nonatomic, assign) UIScrollView* coordinateLabelsLetterViewScrollView;
@property(nonatomic, assign) CoordinateLabelsView* coordinateLabelsLetterView;
@property(nonatomic, assign) UIScrollView* coordinateLabelsNumberViewScrollView;
@property(nonatomic, assign) CoordinateLabelsView* coordinateLabelsNumberView;
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
  self.backgroundView = nil;
  self.coordinateLabelsLetterViewScrollView = nil;
  self.coordinateLabelsLetterView = nil;
  self.coordinateLabelsNumberViewScrollView = nil;
  self.coordinateLabelsNumberView = nil;
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

  self.scrollViewController.playViewController.panGestureController.delegate = self.discardFutureMovesAlertController;
  self.navigationBarController.delegate = self.discardFutureMovesAlertController;
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

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.coordinateLabelsLetterViewScrollView = [[[UIScrollView alloc] initWithFrame:CGRectZero] autorelease];
  self.coordinateLabelsNumberViewScrollView = [[[UIScrollView alloc] initWithFrame:CGRectZero] autorelease];
  self.coordinateLabelsLetterView = [[[CoordinateLabelsView alloc] initWithAxis:CoordinateLabelAxisLetter] autorelease];
  self.coordinateLabelsNumberView = [[[CoordinateLabelsView alloc] initWithAxis:CoordinateLabelAxisNumber] autorelease];

  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureViews];
  [self configureControllers];
}

#pragma mark - Private helpers for view setup

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.backgroundView];
  [self.view addSubview:self.navigationBarController.view];
  [self.view addSubview:self.boardPositionToolbarController.view];
  [self.view addSubview:self.scrollViewController.view];
  [self.view addSubview:self.coordinateLabelsLetterViewScrollView];
  [self.view addSubview:self.coordinateLabelsNumberViewScrollView];
  [self.coordinateLabelsLetterViewScrollView addSubview:self.coordinateLabelsLetterView];
  [self.coordinateLabelsNumberViewScrollView addSubview:self.coordinateLabelsNumberView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  self.navigationBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.coordinateLabelsLetterViewScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.coordinateLabelsNumberViewScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionToolbarController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.coordinateLabelsLetterView.translatesAutoresizingMaskIntoConstraints = NO;
  self.coordinateLabelsNumberView.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.backgroundView, @"backgroundView",
                                   self.navigationBarController.view, @"navigationBarView",
                                   self.scrollViewController.view, @"scrollView",
                                   self.coordinateLabelsLetterViewScrollView, @"coordinateLabelsLetterViewScrollView",
                                   self.coordinateLabelsNumberViewScrollView, @"coordinateLabelsNumberViewScrollView",
                                   self.boardPositionToolbarController.view, @"boardPositionToolbarView",
                                   self.coordinateLabelsLetterView, @"coordinateLabelsLetterView",
                                   self.coordinateLabelsNumberView, @"coordinateLabelsNumberView",
                                   nil];
  // Don't need to specify height values because UINavigationBar and UIToolbar
  // specify a height value in their intrinsic content size
  // TODO xxx should not need to specify 20 for the status bar.
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-0-[backgroundView]-0-|",
                            @"H:|-0-[navigationBarView]-0-|",
                            @"H:|-0-[scrollView]-0-|",
                            @"H:|-0-[boardPositionToolbarView]-0-|",
                            @"H:|-0-[coordinateLabelsLetterViewScrollView]-0-|",
                            @"H:|-0-[coordinateLabelsNumberViewScrollView]-0-|",
                            @"V:|-20-[navigationBarView]-0-[scrollView]-0-[boardPositionToolbarView]-0-|",
                            @"V:[navigationBarView]-0-[backgroundView]-0-[boardPositionToolbarView]",
                            @"V:|-20-[navigationBarView]-0-[coordinateLabelsLetterViewScrollView]-0-[boardPositionToolbarView]-0-|",
                            @"V:|-20-[navigationBarView]-0-[coordinateLabelsNumberViewScrollView]-0-[boardPositionToolbarView]-0-|",
                            nil];
  for (NSString* visualFormat in visualFormats)
  {
    NSArray* constraint = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:viewsDictionary];
    [self.view addConstraints:constraint];
  }

  visualFormats = [NSArray arrayWithObjects:
                   @"H:|-0-[coordinateLabelsLetterView]",
                   @"V:|-0-[coordinateLabelsLetterView]",
                   nil];
  for (NSString* visualFormat in visualFormats)
  {
    NSArray* constraint = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:viewsDictionary];
    [self.coordinateLabelsLetterViewScrollView addConstraints:constraint];
  }

  visualFormats = [NSArray arrayWithObjects:
                   @"H:|-0-[coordinateLabelsNumberView]",
                   @"V:|-0-[coordinateLabelsNumberView]",
                   nil];
  for (NSString* visualFormat in visualFormats)
  {
    NSArray* constraint = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:viewsDictionary];
    [self.coordinateLabelsNumberViewScrollView addConstraints:constraint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  [self.view sendSubviewToBack:self.backgroundView];
  self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:woodenBackgroundImageResource]];

  // TODO xxx remove this; coordinate label views should observe
  // PlayViewMetrics and listen for notifications
  PlayView* playView = self.scrollViewController.playViewController.playView;
  playView.coordinateLabelsLetterView = self.coordinateLabelsLetterView;
  playView.coordinateLabelsNumberView = self.coordinateLabelsNumberView;

  self.coordinateLabelsLetterViewScrollView.backgroundColor = [UIColor clearColor];
  self.coordinateLabelsNumberViewScrollView.backgroundColor = [UIColor clearColor];
  self.coordinateLabelsLetterViewScrollView.userInteractionEnabled = NO;
  self.coordinateLabelsNumberViewScrollView.userInteractionEnabled = NO;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureControllers
{
  // TODO xxx replace this with a notification to remove the direct coupling;
  // also check if there are other couplings, e.g. in the iPad controller
  self.navigationBarController.statusViewController.playView = self.scrollViewController.playViewController.playView;

  self.scrollViewController.coordinateLabelsLetterViewScrollView = self.coordinateLabelsLetterViewScrollView;
  self.scrollViewController.coordinateLabelsLetterView = self.coordinateLabelsLetterView;
  self.scrollViewController.coordinateLabelsNumberViewScrollView = self.coordinateLabelsNumberViewScrollView;
  self.scrollViewController.coordinateLabelsNumberView = self.coordinateLabelsNumberView;
}

@end
