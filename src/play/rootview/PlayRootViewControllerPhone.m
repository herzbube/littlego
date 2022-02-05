// -----------------------------------------------------------------------------
// Copyright 2015-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayRootViewControllerPhone.h"
#import "../boardposition/BoardPositionButtonBoxDataSource.h"
#import "../boardposition/BoardPositionCollectionViewCell.h"
#import "../boardposition/BoardPositionCollectionViewController.h"
#import "../boardview/BoardViewController.h"
#import "../controller/AutoLayoutConstraintHelper.h"
#import "../controller/NavigationBarControllerPhone.h"
#import "../controller/StatusViewController.h"
#import "../splitview/LeftPaneViewController.h"
#import "../splitview/RightPaneViewController.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/ButtonBoxController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/SplitViewController.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/UIColorAdditions.h"


/// @brief Enumerates the states that the view hierarchy of
/// PlayRootViewControllerPhone can have.
enum ViewHierarchyState
{
  ViewHierarchyNotSetup,
  ViewHierarchyPortrait,
  ViewHierarchyLandscape
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayRootViewControllerPhone.
// -----------------------------------------------------------------------------
@interface PlayRootViewControllerPhone()
/// @name Properties not related to a specific orientation
//@{
@property(nonatomic, assign) enum ViewHierarchyState viewHierarchyState;
//@}
/// @name Properties used for landscape
//@{
// Cannot name this property splitViewController, there already is a property
// of that name in UIViewController, and it has a different meaning
@property(nonatomic, retain) SplitViewController* splitViewControllerChild;
@property(nonatomic, retain) LeftPaneViewController* leftPaneViewController;
@property(nonatomic, retain) RightPaneViewController* rightPaneViewController;
//@}
/// @name Properties used for portrait
//@{
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) UIView* boardContainerView;
@property(nonatomic, retain) NavigationBarControllerPhone* navigationBarController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) BoardPositionCollectionViewController* boardPositionCollectionViewController;
@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) NSMutableArray* boardViewAutoLayoutConstraints;
//@}
@end


@implementation PlayRootViewControllerPhone

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayRootViewControllerPhone object.
///
/// @note This is the designated initializer of PlayRootViewControllerPhone.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (PlayRootViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.viewHierarchyState = ViewHierarchyNotSetup;
  [self releaseObjects];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayRootViewControllerPhone
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self releaseObjects];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper during initialization.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
  self.navigationBarController = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.boardPositionCollectionViewController = nil;
  self.statusViewController = nil;
  self.boardViewController = nil;
  self.boardViewAutoLayoutConstraints = nil;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(statusBarOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

  // If the view hierarchy setup is performed synchronously then the
  // safeAreaLayoutGuide is not honored in subviews when the app launches while
  // the device is held in Landscape orientation. The reason is not known.
  // Try & error resulted in the workaround that setting up the view hierarchy
  // with a minimal delay fixes the problem.
  // TODO: This workaround should not be necessary!
  [self performSelector:@selector(setupViewHierarchyForInterfaceOrientationAsync:) withObject:[NSNumber numberWithLong:[UiElementMetrics interfaceOrientation]] afterDelay:0];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
///
/// This method is invoked when the interface orientation is about to change
/// AND the view hierarchy of this view controller is visible.
///
/// This method immediately tears down the current view hierarchy to prevent any
/// complaints by the Auto Layout subsystem about constraints that are currently
/// in place but cannot be satisfied in the new interface orientation.
///
/// This method then queues the setup of a new hierarchy in an asynchronous
/// manner. The new view hierarchy cannot be setup immediately because the Auto
/// Layout subsystem would complain about constraints that cannot be satisfied
/// while the old interface orientation is still in place.
///
/// This override is NOT invoked if the view hierarchy of this view controller
/// is not visible, e.g. because it is buried in a navigation controller's
/// stack. In this situation, a combination of statusBarOrientationDidChange:()
/// and viewWillAppear:() will perform the tasks that this method usually
/// performs:
/// - statusBarOrientationDidChange:() immediately tears down the old view
///   hierarchy
/// - viewWillAppear:() sets up the new view hierarchy
///
/// @note If the user rotates back to the original interface orientation while
/// the view hierarchy of this view controller is not visible, the teardown of
/// the view hierarchy by statusBarOrientationDidChange:() has been unnecessary.
/// This is unfortunate, but unavoidable because the teardown cannot be delayed:
/// Besides #UIApplicationDidChangeStatusBarOrientationNotification there is no
/// other override or event that occurs early enough to trigger the teardown
/// before the Auto Layout subsystem starts complaininig.
///
/// Some background information about why this complicated view hierarchy
/// management is necessary:
/// - The Auto Layout constraints required for the landscape view hierarchy are
///   at the root of the problem.
/// - A combination of the constraints required for sizing/placement of the
///   board view, and the constraints required for sizing/placement of the
///   left/right columns that flank the board view, confuse the Auto Layout
///   subsystem so much that it has to temporarily break one of those
///   constraints during interface orientation changes. While running the app
///   in debug mode, the result is the notorious warning printed by the Auto
///   Layout subsystem to the debug output.
/// - After exhaustive analsys it seems clear to me that the constraints should
///   be valid. This reasoning is supported by the fact that the Auto Layout
///   subsystem accepts the constraints without complaint if the app is launched
///   directly into landscape.
/// - Due to timing issues, the view hierarchy management process had to be
///   split into two parts: teardown and setup.
/// - Teardown must occur as early as possible during the interface orientation
///   change, while the app is still in a state that largely matches the old
///   interface orientation, and the Auto Layout subsystem has not had a chance
///   to detect any flaws in the constraints.
/// - Setup must occur as late as possible during the interface orientation
///   change, when the app is already in a state that matches the new interface
///   orientation, and the Auto Layout subsystem accepts the constraints as
///   valid.
/// - Unfortunately the gap between teardown and setup is visible by the user
// -----------------------------------------------------------------------------
- (void) viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator :(id<UIViewControllerTransitionCoordinator>)coordinator
{
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

  // This override is called even if the view has not been loaded yet. We don't
  // want to be the cause of the view being loaded, so we abort here. A scenario
  // where the view is not yet loaded is when the app launches directly into the
  // main menu, without first showing UIAreaPlay.
  if (! self.isViewLoaded)
    return;

  // This override is called even if the the view hierarchy of this view
  // controller is not visible (e.g. buried in a navigation controller's stack).
  //
  // Because we already have the statusBarOrientationDidChange:() and
  // viewWillAppear:() combination that takes care of the interface rotation
  // in the "view hierarchy is not visible" scenario, we simply abort here.
  //
  // Also note: If the view hierarchy is not visible, the size parameter is
  // still set to dimensions that match the interface orientation before the
  // rotation. This totally screws up the logic below that attempts to derive
  // the target interface orientation from the size.
  if (!self.view.window)
    return;

  UIInterfaceOrientation toInterfaceOrientation;
  if (size.height > size.width)
    toInterfaceOrientation = UIInterfaceOrientationPortrait;
  else
    toInterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
  [self tearDownViewHierarchyIfNotInterfaceOrientation:toInterfaceOrientation];
  [self performSelector:@selector(setupViewHierarchyForInterfaceOrientationAsync:) withObject:[NSNumber numberWithLong:toInterfaceOrientation] afterDelay:0];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
///
/// This override performs part of the tasks usually performed by
/// viewWillTransitionToSize:withTransitionCoordinator:() - see the
/// documentation of that method for details.
// -----------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  UIInterfaceOrientation toInterfaceOrientation = [UiElementMetrics interfaceOrientation];
  [self performSelector:@selector(setupViewHierarchyForInterfaceOrientationAsync:) withObject:[NSNumber numberWithLong:toInterfaceOrientation] afterDelay:0];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the
/// #UIApplicationDidChangeStatusBarOrientationNotification notification.
///
/// This notification handler performs part of the tasks usually performed by
/// viewWillTransitionToSize:withTransitionCoordinator:() - see the
/// documentation of that method for details.
// -----------------------------------------------------------------------------
- (void) statusBarOrientationDidChange:(NSNotification*)notification
{
  // Checking the presence of self.view.window is how we check for view
  // visibility. Checking self.isViewLoaded is necessary because we don't want
  // to trigger view loading by accessing self.view. A scenario where the view
  // is not yet loaded is when the app launches directly into the main menu,
  // without first showing UIAreaPlay.
  //
  // Note: This notification handler is also invoked if a view controller is
  // modally presented on iPhone while in
  // UIInterfaceOrientationPortraitUpsideDown. This is unexpected, but not
  // harmful because the statusbar orientation did not really change from
  // portrait to landscape, so the teardown method will not do anything.
  if (self.isViewLoaded && ! self.view.window)
  {
    UIInterfaceOrientation toInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [self tearDownViewHierarchyIfNotInterfaceOrientation:toInterfaceOrientation];
    // Now that the teardown is complete, a new view hierarchy needs to be
    // created, but this is the responsibility of viewWillAppear:().
  }
}

#pragma mark - View hierarchy setup and teardown

// -----------------------------------------------------------------------------
/// @brief Directs the setup of a new view hierarchy whose state will match
/// @a interfaceOrientation. Does nothing the current view hierarchy already
/// matches @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchyForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([self viewHierarchyStateMatchesInterfaceOrientation:interfaceOrientation])
    return;
  [self updateViewHierarchyStateToInterfaceOrientation:interfaceOrientation];

  [self setupChildControllers];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureViews];
}

// -----------------------------------------------------------------------------
/// @brief Extracts a UIInterfaceOrientation value from @a interfaceOrientation
/// and invokes setupViewHierarchyForInterfaceOrientation:() using that value as
/// the parameter.
///
/// This is a helper method that is intended to be invoked by one of NSObject's
/// delayed execution helpers (e.g. performSelector:withObject:afterDelay:()).
// -----------------------------------------------------------------------------
- (void) setupViewHierarchyForInterfaceOrientationAsync:(NSNumber*)interfaceOrientation
{
  [self setupViewHierarchyForInterfaceOrientation:[interfaceOrientation longValue]];
}

// -----------------------------------------------------------------------------
/// @brief Tears down the currently set up view hierarchy if it does not match
/// @a interfaceOrientation. Afterwards the view hierarchy state is
/// #ViewHierarchyNotSetup. Does nothing if the view hierarchy state already is
/// #ViewHierarchyNotSetup.
// -----------------------------------------------------------------------------
- (void) tearDownViewHierarchyIfNotInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if (self.viewHierarchyState == ViewHierarchyNotSetup)
    return;
  if ([self viewHierarchyStateMatchesInterfaceOrientation:interfaceOrientation])
    return;

  [self removeAutoLayoutConstraints];
  [self tearDownViewHierarchy];
  [self removeChildControllers];

  self.viewHierarchyState = ViewHierarchyNotSetup;
}

#pragma mark - Child view controller setup and removal

// -----------------------------------------------------------------------------
/// @brief Sets up child controllers as part of the view hierarchy setup
/// process. The current view hierarchy state is examined to determine whether a
/// portrait or a landscape view hierarchy is desired.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  if ([self hasPortraitOrientationViewHierarchy])
  {
    self.navigationBarController = [[[NavigationBarControllerPhone alloc] initWithNavigationItem:self.navigationItem] autorelease];
    self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
    self.boardPositionCollectionViewController = [[[BoardPositionCollectionViewController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
    self.statusViewController = [[[StatusViewController alloc] init] autorelease];
    self.boardViewController = [[[BoardViewController alloc] init] autorelease];

    self.boardPositionButtonBoxDataSource = [[[BoardPositionButtonBoxDataSource alloc] init] autorelease];
    self.boardPositionButtonBoxController.buttonBoxControllerDataSource = self.boardPositionButtonBoxDataSource;
  }
  else
  {
    self.splitViewControllerChild = [[[SplitViewController alloc] init] autorelease];

    // These are not child controllers of our own. We are setting them up on
    // behalf of the generic SplitViewController.
    self.leftPaneViewController = [[[LeftPaneViewController alloc] init] autorelease];
    self.rightPaneViewController = [[[RightPaneViewController alloc] init] autorelease];
    self.splitViewControllerChild.viewControllers = [NSArray arrayWithObjects:self.leftPaneViewController, self.rightPaneViewController, nil];
    self.splitViewControllerChild.leftPaneWidth = [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero].width;
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes child controllers as part of the view hierarchy teardown
/// process. The current view hierarchy state is examined to determine whether a
/// portrait or a landscape view hierarchy is in place.
// -----------------------------------------------------------------------------
- (void) removeChildControllers
{
  if ([self hasPortraitOrientationViewHierarchy])
  {
    self.navigationBarController = nil;
    self.boardPositionButtonBoxController = nil;
    self.boardPositionCollectionViewController = nil;
    self.statusViewController = nil;
    self.boardViewController = nil;
    self.boardPositionButtonBoxDataSource = nil;
  }
  else
  {
    self.splitViewControllerChild = nil;
    self.leftPaneViewController = nil;
    self.rightPaneViewController = nil;
  }
}

#pragma mark - Child view controller setters

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardPositionButtonBoxController:(ButtonBoxController*)boardPositionButtonBoxController
{
  if (_boardPositionButtonBoxController == boardPositionButtonBoxController)
    return;
  if (_boardPositionButtonBoxController)
  {
    [_boardPositionButtonBoxController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionButtonBoxController removeFromParentViewController];
    [_boardPositionButtonBoxController release];
    _boardPositionButtonBoxController = nil;
  }
  if (boardPositionButtonBoxController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionButtonBoxController];
    [boardPositionButtonBoxController didMoveToParentViewController:self];
    [boardPositionButtonBoxController retain];
    _boardPositionButtonBoxController = boardPositionButtonBoxController;
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

#pragma mark - View hierarchy setup and teardown

// -----------------------------------------------------------------------------
/// @brief Sets up the actual view hierarchy as part of the view hierarchy setup
/// process. The current view hierarchy state is examined to determine whether a
/// portrait or a landscape view hierarchy is desired.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  if ([self hasPortraitOrientationViewHierarchy])
  {
    // This view provides a wooden texture background not only for the Go board,
    // but for the entire area in which the Go board resides
    self.woodenBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

    // This is a simple container view that takes up all the unused vertical
    // space and within which the board view is then vertically centered.
    self.boardContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

    [self.view addSubview:self.woodenBackgroundView];
    [self.view addSubview:self.boardPositionCollectionViewController.view];
    [self.view addSubview:self.statusViewController.view];

    [self.woodenBackgroundView addSubview:self.boardContainerView];
    [self.woodenBackgroundView addSubview:self.boardPositionButtonBoxController.view];

    [self.boardContainerView addSubview:self.boardViewController.view];
  }
  else
  {
    [self.view addSubview:self.splitViewControllerChild.view];
  }

  // Now that the view hierarchy is in place we can remove the transitional
  // background image that was installed by tearDownViewHierarchy
  self.view.backgroundColor = nil;
}

// -----------------------------------------------------------------------------
/// @brief Tears down the actual view hierarchy as part of the view hierarchy
/// teardown process. The current view hierarchy state is examined to determine
/// whether a portrait or a landscape view hierarchy is in place.
// -----------------------------------------------------------------------------
- (void) tearDownViewHierarchy
{
  // Removing subviews from their superviews also removes the Auto Layout
  // constraints associated with those subviews from the superview
  if ([self hasPortraitOrientationViewHierarchy])
  {
    [self.woodenBackgroundView removeFromSuperview];
    self.woodenBackgroundView = nil;
    [self.boardPositionCollectionViewController.view removeFromSuperview];
    [self.statusViewController.view removeFromSuperview];
  }
  else
  {
    [self.splitViewControllerChild.view removeFromSuperview];
  }

  // Installing this generic and repeating background image makes the transition
  // from the old to the new view hierarchy much less jarring. Without the
  // background image, only a simple gray background is visible. Obviously, a
  // nice rotation animation would be better, but also more difficult to
  // implement.
  self.view.backgroundColor = [UIColor woodenBackgroundColor];
}

#pragma mark - Auto Layout constraints setup and removal

// -----------------------------------------------------------------------------
/// @brief Sets up auto layout constraints as part of the view hierarchy setup
/// process. The current view hierarchy state is examined to determine whether a
/// portrait or a landscape view hierarchy is desired.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  if ([self hasPortraitOrientationViewHierarchy])
    [self setupAutoLayoutConstraintsPortrait];
  else
    [self setupAutoLayoutConstraintsLandscape];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortrait
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.boardViewAutoLayoutConstraints = [NSMutableArray array];
  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                              ofBoardView:self.boardViewController.view
                                  forInterfaceOrientation:(self.hasPortraitOrientationViewHierarchy ? UIInterfaceOrientationPortrait : UIInterfaceOrientationLandscapeLeft)
                                         constraintHolder:self.boardViewController.view.superview];

  self.boardPositionCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  self.statusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  CGFloat boardPositionCollectionViewHeight = [self.boardPositionCollectionViewController boardPositionCollectionViewMaximumCellSize].height;
  viewsDictionary[@"woodenBackgroundView"] = self.woodenBackgroundView;
  viewsDictionary[@"boardPositionCollectionView"] = self.boardPositionCollectionViewController.view;
  viewsDictionary[@"statusView"] = self.statusViewController.view;
  [visualFormats addObject:@"H:|-0-[woodenBackgroundView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionCollectionView]-0-|"];
  [visualFormats addObject:@"H:|-0-[statusView]-0-|"];
  [visualFormats addObject:@"V:|-0-[woodenBackgroundView]-0-[boardPositionCollectionView]-0-[statusView]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionCollectionView(==%f)]", boardPositionCollectionViewHeight]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  // Here we define the statusView height, and by consequence the height of
  // the woodenBackgroundView. The status view extends upwards from the safe
  // area bottom so that on devices that don't have a physical Home button the
  // actual status view content is not overlapped by the Home indicator. For
  // this to work the status view is required to honor safeAreaLayoutGuide.
  NSLayoutYAxisAnchor* bottomAnchor;
  if (@available(iOS 11.0, *))
    bottomAnchor = self.view.safeAreaLayoutGuide.bottomAnchor;
  else
    bottomAnchor = self.view.bottomAnchor;
  int statusViewContentHeight = [UiElementMetrics tableViewCellContentViewHeight];
  [self.statusViewController.view.topAnchor constraintEqualToAnchor:bottomAnchor
                                                           constant:-statusViewContentHeight].active = YES;

  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  self.boardContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
  int horizontalSpacingButtonBox = [AutoLayoutUtility horizontalSpacingSiblings];
  int verticalSpacingButtonBox = [AutoLayoutUtility verticalSpacingSiblings];
  CGSize buttonBoxSize = self.boardPositionButtonBoxController.buttonBoxSize;
  viewsDictionary[@"boardContainerView"] = self.boardContainerView;
  viewsDictionary[@"boardPositionButtonBox"] = self.boardPositionButtonBoxController.view;
  [visualFormats addObject:[NSString stringWithFormat:@"H:|-0-[boardContainerView]-0-|"]];
  [visualFormats addObject:[NSString stringWithFormat:@"H:|-%d-[boardPositionButtonBox]", horizontalSpacingButtonBox]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-0-[boardContainerView]-0-[boardPositionButtonBox]-%d-|", verticalSpacingButtonBox]];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[boardPositionButtonBox(==%f)]", buttonBoxSize.width]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox(==%f)]", buttonBoxSize.height]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.woodenBackgroundView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsLandscape
{
  self.splitViewControllerChild.view.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.splitViewControllerChild.view];
}

// -----------------------------------------------------------------------------
/// @brief Removes auto layout constraints as part of the view hierarchy
/// teardown process. The current view hierarchy state is examined to determine
/// whether a portrait or a landscape view hierarchy is in place.
// -----------------------------------------------------------------------------
- (void) removeAutoLayoutConstraints
{
  if ([self hasPortraitOrientationViewHierarchy])
  {
    self.boardViewAutoLayoutConstraints = nil;
  }
  else
  {
  }
}

#pragma mark - View configuration

// -----------------------------------------------------------------------------
/// @brief Configures views as part of the view hierarchy setup process. The
/// current view hierarchy state is examined to determine whether a portrait or
/// a landscape view hierarchy is desired.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  if ([self hasPortraitOrientationViewHierarchy])
  {
    self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

    [self.boardPositionButtonBoxController applyTransparentStyle];

    self.navigationBarController.navigationBar = self.navigationController.navigationBar;
    [self.boardPositionButtonBoxController reloadData];
  }
  else
  {
  }
}

#pragma mark - View hierarchy state helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if the view hierarchy is currently in a state that
/// matches @a interfaceOrientation. Returns false otherwise. Always returns
/// false if the view hierarchy is currently not set up because this state is
/// neither portrait nor landscape.
///
/// @a interfaceOrientation must describe either a portrait or a landscape
/// orientation. If #UIInterfaceOrientationUnknown is specified the result is
/// not defined.
// -----------------------------------------------------------------------------
- (bool) viewHierarchyStateMatchesInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  switch (self.viewHierarchyState)
  {
    case ViewHierarchyNotSetup:
      return false;
    case ViewHierarchyPortrait:
      return isPortraitOrientation;
    case ViewHierarchyLandscape:
      return !isPortraitOrientation;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the property @e viewHierarchyState to a value that matches
/// @a interfaceOrientation.
///
/// @a interfaceOrientation must describe either a portrait or a landscape
/// orientation. If #UIInterfaceOrientationUnknown is specified the content of
/// the property is not defined.
// -----------------------------------------------------------------------------
- (void) updateViewHierarchyStateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
    self.viewHierarchyState = ViewHierarchyPortrait;
  else
    self.viewHierarchyState = ViewHierarchyLandscape;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the view hierarchy is currently in a state that
/// matches a portrait orientation, false if it is in a state that matches a
/// landscape orientation. Throws an exception if the view hierarchy is
/// currently not set up.
///
/// This method must only be invoked after a target view hierarchy state has
/// been determined. The usual places to invoke this method are during setup of
/// a new view hierarchy, or during teardown of the existing view hierarchy.
// -----------------------------------------------------------------------------
- (bool) hasPortraitOrientationViewHierarchy
{
  switch (self.viewHierarchyState)
  {
    case ViewHierarchyPortrait:
      return true;
    case ViewHierarchyLandscape:
      return false;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"hasPortraitOrientationViewHierarchy: Invalid view hierarchy state %d"
                                                  argumentValue:self.viewHierarchyState];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
      return false;
  }
}

@end
