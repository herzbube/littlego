// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayRootViewControllerPad.h"
#import "../boardposition/BoardPositionButtonBoxDataSource.h"
#import "../boardposition/BoardPositionCollectionViewCell.h"
#import "../boardposition/BoardPositionCollectionViewController.h"
#import "../boardview/BoardViewController.h"
#import "../controller/AutoLayoutConstraintHelper.h"
#import "../controller/NavigationBarController.h"
#import "../splitview/LeftPaneViewController.h"
#import "../splitview/RightPaneViewController.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/ButtonBoxController.h"
#import "../../ui/SplitViewController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayRootViewControllerPad.
// -----------------------------------------------------------------------------
@interface PlayRootViewControllerPad()
/// @name Properties used for both interface orientations
//@{
@property (nonatomic, assign) bool viewsAreInPortraitOrientation;
@property (nonatomic, retain) NSArray* autoLayoutConstraints;
@property (nonatomic, retain) NSLayoutConstraint* topAnchorAutoLayoutConstraint;
@property(nonatomic, retain) NSMutableArray* boardViewAutoLayoutConstraints;
//@}

/// @name Properties used for portrait
//@{
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) UIView* boardContainerView;
// Cannot name this property navigationBarController, there already is a
// property of that name in UIViewController, and it has a different meaning
@property(nonatomic, retain) NavigationBarController* navigationBarControllerChild;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) BoardPositionCollectionViewController* boardPositionCollectionViewController;
//@}

/// @name Properties used for landscape
//@{
// Cannot name this property splitViewController, there already is a property
// of that name in UIViewController, and it has a different meaning
@property(nonatomic, retain) SplitViewController* splitViewControllerChild;
@property(nonatomic, retain) LeftPaneViewController* leftPaneViewController;
@property(nonatomic, retain) RightPaneViewController* rightPaneViewController;
//@}
@end


@implementation PlayRootViewControllerPad

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayRootViewControllerPad object.
///
/// @note This is the designated initializer of PlayRootViewControllerPad.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (PlayRootViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.viewsAreInPortraitOrientation = true;
  self.autoLayoutConstraints = nil;
  self.topAnchorAutoLayoutConstraint = nil;
  self.boardViewAutoLayoutConstraints = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayRootViewControllerPad
/// object.
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
  self.view = nil;
  self.autoLayoutConstraints = nil;
  self.topAnchorAutoLayoutConstraint = nil;
  self.boardViewAutoLayoutConstraints = nil;
  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
  self.navigationBarControllerChild = nil;
  self.boardViewController = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.boardPositionCollectionViewController = nil;
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// @brief Updates the child view controllers hierarchy managed by this view
/// controller to match the specified interface orientation.
// -----------------------------------------------------------------------------
- (void) setupChildControllersForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    self.navigationBarControllerChild = [NavigationBarController navigationBarController];
    self.boardViewController = [[[BoardViewController alloc] init] autorelease];
    self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
    self.boardPositionCollectionViewController = [[[BoardPositionCollectionViewController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];

    self.boardPositionButtonBoxDataSource = [[[BoardPositionButtonBoxDataSource alloc] init] autorelease];
    self.boardPositionButtonBoxController.buttonBoxControllerDataSource = self.boardPositionButtonBoxDataSource;
  }
  else
  {
    self.splitViewControllerChild = [[[SplitViewController alloc] init] autorelease];

    // These are not direct child controllers. We are setting them up on behalf
    // of UISplitViewController because we don't want to create a
    // UISplitViewController subclass.
    self.leftPaneViewController = [[[LeftPaneViewController alloc] init] autorelease];
    self.rightPaneViewController = [[[RightPaneViewController alloc] init] autorelease];
    self.splitViewControllerChild.viewControllers = [NSArray arrayWithObjects:self.leftPaneViewController, self.rightPaneViewController, nil];
    // Apply an experimentally determined factor - the navigation buttons at
    // the top of the left pane are squashed together too tightly if we use the
    // minimal cell width.
    self.splitViewControllerChild.leftPaneWidth = ceilf(1.5 * [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero].width);

    // Cast is safe because we know that the NavigationBarController object
    // is a subclass of NavigationBarController that adopts the
    // SplitViewControllerDelegate protocol
    self.splitViewControllerChild.delegate = (id<SplitViewControllerDelegate>)self.rightPaneViewController.navigationBarController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all child view controllers from this view controller.
// -----------------------------------------------------------------------------
- (void) removeChildControllers
{
  self.navigationBarControllerChild = nil;
  self.boardViewController = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.boardPositionCollectionViewController = nil;
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setNavigationBarControllerChild:(NavigationBarController*)navigationBarControllerChild
{
  if (_navigationBarControllerChild == navigationBarControllerChild)
    return;
  if (_navigationBarControllerChild)
  {
    [_navigationBarControllerChild willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_navigationBarControllerChild removeFromParentViewController];
    [_navigationBarControllerChild release];
    _navigationBarControllerChild = nil;
  }
  if (navigationBarControllerChild)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:navigationBarControllerChild];
    [navigationBarControllerChild didMoveToParentViewController:self];
    [navigationBarControllerChild retain];
    _navigationBarControllerChild = navigationBarControllerChild;
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
- (void) setSplitViewControllerChild:(SplitViewController*)splitViewControllerChild
{
  if (_splitViewControllerChild == splitViewControllerChild)
    return;
  if (_splitViewControllerChild)
  {
    [_splitViewControllerChild willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_splitViewControllerChild removeFromParentViewController];
    [_splitViewControllerChild release];
    _splitViewControllerChild = nil;
  }
  if (splitViewControllerChild)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:splitViewControllerChild];
    [splitViewControllerChild didMoveToParentViewController:self];
    [splitViewControllerChild retain];
    _splitViewControllerChild = splitViewControllerChild;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  UIInterfaceOrientation interfaceOrientation = [UiElementMetrics interfaceOrientation];
  [self setupChildControllersForInterfaceOrientation:interfaceOrientation];
  [self updateViewHierarchyForInterfaceOrientation:interfaceOrientation];
  [self configureViewsForInterfaceOrientation:interfaceOrientation];
  [self updateAutoLayoutConstraintsForInterfaceOrientation:interfaceOrientation];
  [self viewLayoutDidChangeToInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This override handles interface orientation changes while this controller's
/// view hierarchy is visible, and changes that occurred while this controller's
/// view hierarchy was not visible (this method is invoked when the controller's
/// view becomes visible again).
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  UIInterfaceOrientation interfaceOrientation = [UiElementMetrics interfaceOrientation];
  if ([self isViewLayoutChangeRequiredForInterfaceOrientation:interfaceOrientation])
  {
    [self prepareForInterfaceOrientationChange:interfaceOrientation];
    [self completeInterfaceOrientationChange:interfaceOrientation];
    [self viewLayoutDidChangeToInterfaceOrientation:interfaceOrientation];
  }
}

#pragma mark - Interface orientation change handling

// -----------------------------------------------------------------------------
/// @brief Returns true if rotating to the specified interface orientation
/// requires a change to the view layout of this view controller.
// -----------------------------------------------------------------------------
- (bool) isViewLayoutChangeRequiredForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool newOrientationIsPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  return (self.viewsAreInPortraitOrientation != newOrientationIsPortraitOrientation);
}

// -----------------------------------------------------------------------------
/// @brief Updates the internal state of this view controller to remember
/// that the current view layout now matches @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (void) viewLayoutDidChangeToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  self.viewsAreInPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

// -----------------------------------------------------------------------------
/// @brief Prepares this view controller for an upcoming interface orientation
/// change. The new orientation is @a interfaceOrientation.
///
/// This method should only be invoked if
/// isViewLayoutChangeRequiredForInterfaceOrientation:() returns true for the
/// specified interface orientation.
// -----------------------------------------------------------------------------
- (void) prepareForInterfaceOrientationChange:(UIInterfaceOrientation)interfaceOrientation
{
  // Remove constraints before views are resized (at the time
  // willAnimateRotationToInterfaceOrientation:duration:() is invoked it is too
  // late, views are already resized to match the new interface orientation). If
  // we don't remove constraints here, Auto Layout will have trouble resizing
  // views (although the reason why is unknown).
  [self removeAutoLayoutConstraints];
  // Since we don't have any constraints anymore, we must also remove the view
  // hierarchy
  [self removeViewHierarchy];
  [self removeChildControllers];
}

// -----------------------------------------------------------------------------
/// @brief Completes the interface orientation change that was begun when
/// prepareForInterfaceOrientationChange:() was invoked. The new orientation is
/// @a interfaceOrientation.
///
/// This method should only be invoked if
/// isViewLayoutChangeRequiredForInterfaceOrientation:() returns true for the
/// specified interface orientation.
///
/// Clients that invoke this method must have previously also called
/// prepareForInterfaceOrientationChange:() to perform the first step of the
/// orientation change.
// -----------------------------------------------------------------------------
- (void) completeInterfaceOrientationChange:(UIInterfaceOrientation)interfaceOrientation
{
  [self setupChildControllersForInterfaceOrientation:interfaceOrientation];
  [self updateViewHierarchyForInterfaceOrientation:interfaceOrientation];
  [self configureViewsForInterfaceOrientation:interfaceOrientation];
  [self updateAutoLayoutConstraintsForInterfaceOrientation:interfaceOrientation];
}

#pragma mark - View hierarchy handling

// -----------------------------------------------------------------------------
/// @brief Updates the view hierarchy managed by this view controller to
/// match the specified interface orientation.
// -----------------------------------------------------------------------------
- (void) updateViewHierarchyForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    // This view provides a wooden texture background not only for the Go board,
    // but for the entire area in which the Go board resides
    self.woodenBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

    // This is a simple container view that takes up all the unused vertical
    // space and within which the board view is then vertically centered.
    self.boardContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

    [self.view addSubview:self.navigationBarControllerChild.view];
    [self.view addSubview:self.woodenBackgroundView];
    [self.view addSubview:self.boardPositionCollectionViewController.view];

    [self.woodenBackgroundView addSubview:self.boardContainerView];
    [self.woodenBackgroundView addSubview:self.boardPositionButtonBoxController.view];

    [self.boardContainerView addSubview:self.boardViewController.view];
  }
  else
  {
    [self.view addSubview:self.splitViewControllerChild.view];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all subviews from the view of this view controller.
// -----------------------------------------------------------------------------
- (void) removeViewHierarchy
{
  for (UIView* subview in self.view.subviews)
    [subview removeFromSuperview];

  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
}

#pragma mark - View configuration

// -----------------------------------------------------------------------------
/// @brief Configures views as part of the view hierarchy setup process.
// -----------------------------------------------------------------------------
- (void) configureViewsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // The main view's background color is visible behind the statusbar. Use the
  // same color that is used for the navigation bar at the top.
  self.view.backgroundColor = [UIColor navigationbarBackgroundColor];

  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

    [self.boardPositionButtonBoxController applyTransparentStyle];

    [self.boardPositionButtonBoxController reloadData];
  }
  else
  {
  }
}

#pragma mark - Auto layout constraint handling

// -----------------------------------------------------------------------------
/// @brief Sets up the auto layout constraints of the view of this view
/// controller to match the specified interface orientation.
// -----------------------------------------------------------------------------
- (void) updateAutoLayoutConstraintsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
    [self updateAutoLayoutConstraintsPortrait];
  else
    [self updateAutoLayoutConstraintsLandscape];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// updateAutoLayoutConstraintsForInterfaceOrientation:().
// -----------------------------------------------------------------------------
- (void) updateAutoLayoutConstraintsPortrait
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.navigationBarControllerChild.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  CGFloat boardPositionCollectionViewHeight = [self.boardPositionCollectionViewController boardPositionCollectionViewMaximumCellSize].height;
  viewsDictionary[@"navigationBarView"] = self.navigationBarControllerChild.view;
  viewsDictionary[@"woodenBackgroundView"] = self.woodenBackgroundView;
  viewsDictionary[@"boardPositionCollectionView"] = self.boardPositionCollectionViewController.view;
  [visualFormats addObject:@"H:|-0-[navigationBarView]-0-|"];
  [visualFormats addObject:@"H:|-0-[woodenBackgroundView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionCollectionView]-0-|"];
  [visualFormats addObject:@"V:[navigationBarView]-0-[woodenBackgroundView]-0-[boardPositionCollectionView]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionCollectionView(==%f)]", boardPositionCollectionViewHeight]];
  self.autoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                             withViews:viewsDictionary
                                                                inView:self.view];

  self.topAnchorAutoLayoutConstraint = [AutoLayoutUtility alignFirstView:self.navigationBarControllerChild.view
                                                          withSecondView:self.view
                                             onSafeAreaLayoutGuideAnchor:NSLayoutAttributeTop];

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

  self.boardViewAutoLayoutConstraints = [NSMutableArray array];
  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                              ofBoardView:self.boardViewController.view
                                  forInterfaceOrientation:UIInterfaceOrientationPortrait
                                         constraintHolder:self.boardViewController.view.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// updateAutoLayoutConstraintsForInterfaceOrientation:().
// -----------------------------------------------------------------------------
- (void) updateAutoLayoutConstraintsLandscape
{
  self.splitViewControllerChild.view.translatesAutoresizingMaskIntoConstraints = NO;
  
  self.autoLayoutConstraints = [AutoLayoutUtility fillAreaBetweenLayoutGuidesOfSuperview:self.view
                                                                             withSubview:self.splitViewControllerChild.view];
}

// -----------------------------------------------------------------------------
/// @brief Removes all auto layout constraints from the view of this view
/// controller.
// -----------------------------------------------------------------------------
- (void) removeAutoLayoutConstraints
{
  if (self.autoLayoutConstraints)
  {
    [self.view removeConstraints:self.autoLayoutConstraints];
    self.autoLayoutConstraints = nil;
  }

  if (self.topAnchorAutoLayoutConstraint)
  {
    [self.view removeConstraint:self.topAnchorAutoLayoutConstraint];
    self.topAnchorAutoLayoutConstraint = nil;
  }
}

@end
