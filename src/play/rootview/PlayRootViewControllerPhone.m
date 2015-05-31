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
#import "../../utility/UiColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayRootViewControllerPhone.
// -----------------------------------------------------------------------------
@interface PlayRootViewControllerPhone()
@property(nonatomic, assign) bool hasPortraitOrientationViewHierarchy;
/// @name Properties used for landscape
//@{
@property(nonatomic, retain) NSArray* constraints;
// Cannot name this property splitViewController, there already is a property
// of that name in UIViewController, and it has a different meaning
@property(nonatomic, retain) SplitViewController* splitViewControllerChild;
@property(nonatomic, retain) LeftPaneViewController* leftPaneViewController;
@property(nonatomic, retain) RightPaneViewController* rightPaneViewController;
//@}
/// @name Properties used for portrait
//@{
@property(nonatomic, retain) UIView* woodenBackgroundView;
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
  [self setupChildControllers];
  self.constraints = nil;
  self.woodenBackgroundView = nil;
  self.boardViewAutoLayoutConstraints = [NSMutableArray array];
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(statusBarOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
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
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.constraints = nil;
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
  self.woodenBackgroundView = nil;
  self.navigationBarController = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.boardPositionCollectionViewController = nil;
  self.statusViewController = nil;
  self.boardViewController = nil;
  self.boardViewAutoLayoutConstraints = nil;
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

  if (self.hasPortraitOrientationViewHierarchy)
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
/// @brief Removes child controllers if the current setup does NOT match
/// @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (void) removeChildControllersIfNotMatchingInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation == self.hasPortraitOrientationViewHierarchy)
    return;

  if (self.hasPortraitOrientationViewHierarchy)
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

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureViews];
  self.navigationBarController.navigationBar = self.navigationController.navigationBar;
  [self.boardPositionButtonBoxController reloadData];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This override exists to update Auto Layout constraints when the view of this
/// controller is resized.
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  if (self.hasPortraitOrientationViewHierarchy)
  {
    [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                                ofBoardView:self.boardViewController.view
                                    forInterfaceOrientation:self.interfaceOrientation
                                           constraintHolder:self.woodenBackgroundView];
  }
  [super viewWillLayoutSubviews];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  if (self.hasPortraitOrientationViewHierarchy)
  {
    self.woodenBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

    [self.view addSubview:self.woodenBackgroundView];
    [self.view addSubview:self.boardPositionCollectionViewController.view];
    [self.view addSubview:self.statusViewController.view];

    [self.woodenBackgroundView addSubview:self.boardPositionButtonBoxController.view];
    [self.woodenBackgroundView addSubview:self.boardViewController.view];
  }
  else
  {
    [self.view addSubview:self.splitViewControllerChild.view];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.edgesForExtendedLayout = UIRectEdgeNone;
  if (self.hasPortraitOrientationViewHierarchy)
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

  self.boardPositionCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  self.statusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  CGFloat boardPositionCollectionViewHeight = [self.boardPositionCollectionViewController boardPositionCollectionViewMaximumCellSize].height;
  int statusViewHeight = [UiElementMetrics tableViewCellContentViewHeight];
  viewsDictionary[@"woodenBackgroundView"] = self.woodenBackgroundView;
  viewsDictionary[@"boardPositionCollectionView"] = self.boardPositionCollectionViewController.view;
  viewsDictionary[@"statusView"] = self.statusViewController.view;
  [visualFormats addObject:@"H:|-0-[woodenBackgroundView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionCollectionView]-0-|"];
  [visualFormats addObject:@"H:|-0-[statusView]-0-|"];
  [visualFormats addObject:@"V:|-0-[woodenBackgroundView]-0-[boardPositionCollectionView]-0-[statusView]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionCollectionView(==%f)]", boardPositionCollectionViewHeight]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[statusView(==%d)]", statusViewHeight]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                              ofBoardView:self.boardViewController.view
                                  forInterfaceOrientation:self.interfaceOrientation
                                         constraintHolder:self.woodenBackgroundView];

  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  self.boardPositionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
  int horizontalSpacingButtonBox = [AutoLayoutUtility horizontalSpacingSiblings];
  int verticalSpacingButtonBox = [AutoLayoutUtility verticalSpacingSiblings];
  CGSize buttonBoxSize = self.boardPositionButtonBoxController.buttonBoxSize;
  viewsDictionary[@"boardPositionButtonBox"] = self.boardPositionButtonBoxController.view;
  [visualFormats addObject:[NSString stringWithFormat:@"H:|-%d-[boardPositionButtonBox]", horizontalSpacingButtonBox]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox]-%d-|", verticalSpacingButtonBox]];
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
  self.constraints = [AutoLayoutUtility fillSuperview:self.view withSubview:self.splitViewControllerChild.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) tearDownViewHierarchy
{
  if (self.hasPortraitOrientationViewHierarchy)
  {
    [self.woodenBackgroundView removeFromSuperview];
    [self.boardPositionCollectionViewController.view removeFromSuperview];
    [self.statusViewController.view removeFromSuperview];
  }
  else
  {
    [self.splitViewControllerChild.view removeFromSuperview];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeAutoLayoutConstraints
{
  if (self.hasPortraitOrientationViewHierarchy)
  {
    //xxx
    // let's hope UIKit cleans up after us; we should remove the constraints
    // for
    // - self.woodenBackgroundView
    // - self.boardPositionCollectionViewController.view
    // - self.statusViewController.view
  }
  else
  {
    [self.view removeConstraints:self.constraints];
    self.constraints = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  if (self.hasPortraitOrientationViewHierarchy)
  {
    // This view provides a wooden texture background not only for the Go board,
    // but for the entire area in which the Go board resides
    self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

    [self.boardPositionButtonBoxController applyTransparentStyle];
  }
  else
  {
    // RightPaneViewController internally does the same as we do for portrait
  }
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
  [self configureViews];
}

@end
