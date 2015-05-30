// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayUiAreaController.h"
#import "../boardposition/BoardPositionCollectionViewCell.h"
#import "../rootview/PlayRootViewController.h"
#import "../splitview/LeftPaneViewController.h"
#import "../splitview/RightPaneViewController.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/SplitViewController.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayUiAreaController.
// -----------------------------------------------------------------------------
@interface PlayUiAreaController()
@property(nonatomic, retain) NSArray* constraints;
@property(nonatomic, assign) bool hasPortraitOrientationViewHierarchy;
@property(nonatomic, retain) PlayRootViewController* playRootViewController;
// Cannot name this property splitViewController, there already is a property
// of that name in UIViewController, and it has a different meaning
@property(nonatomic, retain) SplitViewController* splitViewControllerChild;
@property(nonatomic, retain) LeftPaneViewController* leftPaneViewController;
@property(nonatomic, retain) RightPaneViewController* rightPaneViewController;
/// @brief Depending on the interface orientation, this references either
/// playRootViewController (portrait) or splitViewControllerChild (landscape).
@property(nonatomic, assign) UIViewController* rootViewController;
@end


@implementation PlayUiAreaController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayUiAreaController object.
///
/// @note This is the designated initializer of PlayUiAreaController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupChildControllers];
  self.constraints = nil;
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(statusBarOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayUiAreaController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.constraints = nil;
  self.playRootViewController = nil;
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// @brief Internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  // Set self.hasPortraitOrientationViewHierarchy to a value that guarantees
  // that addChildControllersForInterfaceOrientation:() will do something
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
  self.hasPortraitOrientationViewHierarchy = !isPortraitOrientation;
  [self addChildControllersForInterfaceOrientation:self.interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief Adds child controllers that match @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (void) addChildControllersForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation == self.hasPortraitOrientationViewHierarchy)
    return;
  self.hasPortraitOrientationViewHierarchy = isPortraitOrientation;

  if (isPortraitOrientation)
  {
    self.playRootViewController = [PlayRootViewController playRootViewController];
    self.rootViewController = self.playRootViewController;
  }
  else
  {
    self.splitViewControllerChild = [[[SplitViewController alloc] init] autorelease];
    self.rootViewController = self.splitViewControllerChild;

    // These are not child controllers of our own. We are setting them up on
    // behalf of the generic SplitViewController.
    self.leftPaneViewController = [[[LeftPaneViewController alloc] init] autorelease];
    self.rightPaneViewController = [[[RightPaneViewController alloc] init] autorelease];
    self.splitViewControllerChild.viewControllers = [NSArray arrayWithObjects:self.leftPaneViewController, self.rightPaneViewController, nil];
    self.splitViewControllerChild.leftPaneWidth = [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero].width;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setRootViewController:(UIViewController*)rootViewController
{
  if (_rootViewController == rootViewController)
    return;
  if (_rootViewController)
  {
    [_rootViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_rootViewController removeFromParentViewController];
    [_rootViewController release];
    _rootViewController = nil;
  }
  if (rootViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:rootViewController];
    [rootViewController didMoveToParentViewController:self];
    [rootViewController retain];
    _rootViewController = rootViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes child controllers if the current setup does NOT match
/// @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (void) removeChildControllersIfNotMatchingInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation == self.hasPortraitOrientationViewHierarchy)
    return;

  self.rootViewController = nil;
  if (self.hasPortraitOrientationViewHierarchy)
  {
    self.playRootViewController = nil;
  }
  else
  {
    // TODO xxx it looks as if this can actually be removed now that the
    // UINavigationController is no longer responsible for setting up the
    // view hierarchy

    // TODO This should be removed, it is a HACK! Reason for the hack:
    // - The Auto Layout constraints in RightPaneViewController are made so that
    //   they fit landscape orientation. In portrait orientation the constraints
    //   cause the Auto Layout engine to print warnings into the Debug console.
    // - Now here's the strange thing: Despite the fact that here we remove all
    //   references to the RightPaneViewController object, and that object is
    //   properly deallocated later on, the deallocation takes place too late
    //   so that RightPaneViewController's view hierarchy still takes part in
    //   the view layout process after the interface orientation change.
    //   Something - presumably it's UINavigationController - keeps
    //   RightPaneViewController around too long.
    // - The only way I have found to get rid of the Auto Layout warnings is to
    //   explicitly tell RightPaneViewController to remove the offending
    //   constraints NOW!
    //
    // Perhaps the hack can be eliminated once we drop iOS 7 support and can
    // start to work with size classes.
    [self.rightPaneViewController removeDynamicConstraints];

    self.splitViewControllerChild = nil;
    self.leftPaneViewController = nil;
    self.rightPaneViewController = nil;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the
/// #UIApplicationDidChangeStatusBarOrientationNotification notification.
/// Sets up the view hierarchy for the new user interface orientation.
///
/// The board view that is a subview located somewhere in the view hierarchy
/// is set up with Auto Layout constraints that work only for one interface
/// orientation (the constraint that is tied to the interface orientation is the
/// one that defines the board view width or height). If the interface
/// orientation changes, but the constraints do not, the Auto Layout subsystem
/// prints a warning because it has to break a constraint.
///
/// The consequence is that when the the interface orientation changes, we must
/// setup the view hierarchy for the new interface orientation as soon as
/// possible, before the Auto Layout system has a chance to complain. Responding
/// to #UIApplicationDidChangeStatusBarOrientationNotification is the only
/// reliable way that I have found that catches the interface orientation change
/// early enough in ***ALL*** circumstances. The trickiest circumstance is this:
/// - Display #UIAreaPlay. This sets up the view hierarchy.
/// - Display #UIAreaNavigation. This hides #UIAreaPlay.
/// - Change interface orientation. Because #UIAreaPlay is hidden, no overrides
///   in this controller are invoked (e.g. willRotateToInterfaceOrientation,
///   viewWillLayoutSubviews).
/// - Display #UIAreaPlay. Some overrides in this controller are invoked
///   (viewWillLayoutSubviews, viewWillAppear), but they are all invoked too
///   late - the Auto Layout subsystem has already detected the problem and
///   printed its warning.
///
/// Because we are responding to
/// #UIApplicationDidChangeStatusBarOrientationNotification, we are changing
/// the view hierarchy even though this controller's view may not be visible.
/// This is unfortunate, but unavoidable.
// -----------------------------------------------------------------------------
- (void) statusBarOrientationDidChange:(NSNotification*)notification
{
  // Can't use self.interfaceOrientation, that property does not yet have the
  // correct value
  UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
  [self tearDownViewHierarchy];
  [self removeAutoLayoutConstraints];
  [self removeChildControllersIfNotMatchingInterfaceOrientation:interfaceOrientation];

  [self addChildControllersForInterfaceOrientation:interfaceOrientation];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
}

#pragma mark - View setup

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.edgesForExtendedLayout = UIRectEdgeNone;
  [self.view addSubview:self.rootViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.rootViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.constraints = [AutoLayoutUtility fillSuperview:self.view withSubview:self.rootViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) tearDownViewHierarchy
{
  [self.rootViewController.view removeFromSuperview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeAutoLayoutConstraints
{
  [self.view removeConstraints:self.constraints];
  self.constraints = nil;
}

@end
