// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayRootViewControllerPhoneAndPad.h"
#import "../annotationview/AnnotationViewController.h"
#import "../boardposition/BoardPositionButtonBoxDataSource.h"
#import "../boardposition/BoardPositionCollectionViewCell.h"
#import "../boardposition/BoardPositionCollectionViewController.h"
#import "../boardview/BoardViewController.h"
#import "../controller/AutoLayoutConstraintHelper.h"
#import "../controller/StatusViewController.h"
#import "../model/NavigationBarButtonModel.h"
#import "../model/NodeTreeViewModel.h"
#import "../nodetreeview/NodeTreeViewController.h"
#import "../splitview/LeftPaneViewController.h"
#import "../splitview/RightPaneViewController.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/ButtonBoxController.h"
#import "../../ui/SplitViewController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayRootViewControllerPhoneAndPad.
// -----------------------------------------------------------------------------
@interface PlayRootViewControllerPhoneAndPad()
/// @name Properties used for both interface orientations
//@{
@property (nonatomic, assign) bool viewsAreInPortraitOrientation;
@property (nonatomic, retain) NSMutableArray* autoLayoutConstraints;
@property (nonatomic, assign) CGFloat splitViewControllerLeftPaneWidthMultiplier;
@property (nonatomic, assign) UIRectEdge splitViewControllerSafeAreaEdges;
@property (nonatomic, assign) CGFloat annotationViewHeightMultiplier;
//@}

/// @name Properties used for portrait
//@{
// Views
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) OrientationChangeNotifyingView* boardContainerView;
@property(nonatomic, retain) UIView* boardPositionButtonBoxAndAnnotationContainerView;
@property(nonatomic, retain) UIView* boardPositionButtonBoxContainerView;
// Controllers and data sources
@property(nonatomic, retain) ResizableStackViewController* resizableStackViewController;
@property(nonatomic, retain) UIViewController* resizablePane1ViewController;
@property(nonatomic, retain) UIViewController* resizablePane2ViewController;
@property(nonatomic, retain) NavigationBarButtonModel* navigationBarButtonModel;
@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) AnnotationViewController* annotationViewController;
@property(nonatomic, retain) BoardPositionCollectionViewController* boardPositionCollectionViewController;
@property(nonatomic, retain) NodeTreeViewController* nodeTreeViewController;
// Other properties
@property(nonatomic, assign) UILayoutConstraintAxis boardViewSmallerDimension;
@property(nonatomic, retain) NSMutableArray* boardViewAutoLayoutConstraints;
@property(nonatomic, assign) CGFloat boardPositionCollectionViewBorderWidth;
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


@implementation PlayRootViewControllerPhoneAndPad

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayRootViewControllerPhoneAndPad object.
/// It adjusts the view layout to the specified @a uiType.
///
/// @note This is the designated initializer of
/// PlayRootViewControllerPhoneAndPad.
// -----------------------------------------------------------------------------
- (id) initWithUiType:(enum UIType)uiType
{
  // Call designated initializer of superclass (PlayRootViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.viewsAreInPortraitOrientation = true;
  self.autoLayoutConstraints = nil;
  self.boardViewSmallerDimension = UILayoutConstraintAxisHorizontal;
  self.boardViewAutoLayoutConstraints = nil;
  self.boardPositionCollectionViewBorderWidth = 1.0f;

  // Multipliers were experimentally determined to result in a good-looking
  // layout. They may freely be changed in the future if needed.
  switch (uiType)
  {
    case UITypePhone:
      // On iPhone devices there is not so much horizontal space available in
      // landscape orientation as on iPad devices, so we can't be wasteful and
      // specify a multiplier 1.0 to use the minimal board position cell width
      // for the left pane.
      self.splitViewControllerLeftPaneWidthMultiplier = 1.0;
      // Align split view with the bottom of the safe area. This prevents it
      // from extending behind the tab bar at the bottom. In theory no alignment
      // would be needed with the top of the safe area because iPhone devices
      // don't display a status bar in landscape orientation. However, this
      // controller is the root VC of a navigation controller, and even though
      // that navigation controller's navigation bar is hidden in landscape
      // orientation, UINavigationController still lays out the view of its
      // root VC (= this VC) to end below the (hidden) navigation bar. By
      // aligning with the top of the safe area we override the
      // UINavigationController's default layouting and force this VC's view to
      // go up to the screen top edge.
      self.splitViewControllerSafeAreaEdges = UIRectEdgeTop | UIRectEdgeBottom;
      // On iPhone devices this multiplier is larger than on iPad devices
      // because the annotation view does not get as much width, which means
      // that the description labels need more vertical space to compensate
      // => they should display most description texts without scrolling.
      self.annotationViewHeightMultiplier = 1.4;
      break;
    case UITypePad:
      // On iPad devices there is a lot of horizontal space available in
      // Landscape orientation. If we use only the minimal board position cell
      // width for the left pane, the annotation view and navigation buttons get
      // too much width, which looks ugly. Specifying a multiplier greater than
      // 1.0 gives the left pane some unneeded space, but the overall layout
      // looks better.
      self.splitViewControllerLeftPaneWidthMultiplier = 1.5;
      // Align split view with the top and bottom of the safe area. This
      // prevents it from extending behind the status bar at the top and the
      // tab bar at the bottom.
      self.splitViewControllerSafeAreaEdges = UIRectEdgeTop | UIRectEdgeBottom;
      // On iPad devices the annotation view gets a lot of horizontal space in
      // portrait orientation, so the multiplier does not need to be large. But
      // it should still be greater than 1.0 to give the annotation view
      // substantial height to make it visible and to make the overall layout
      // look good.
      self.annotationViewHeightMultiplier = 1.25;
      break;
    default:
      [ExceptionUtility throwInvalidUIType:uiType];
      break;
  }

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// PlayRootViewControllerPhoneAndPad object.
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
  // Properties used for both interface orientations
  self.view = nil;
  self.autoLayoutConstraints = nil;

  // Properties used for portrait
  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
  self.boardPositionButtonBoxAndAnnotationContainerView = nil;
  self.boardPositionButtonBoxContainerView = nil;
  self.resizableStackViewController = nil;
  self.resizablePane1ViewController = nil;
  self.resizablePane2ViewController = nil;
  self.navigationBarButtonModel = nil;
  self.statusViewController = nil;
  self.boardViewController = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.annotationViewController = nil;
  self.boardPositionCollectionViewController = nil;
  self.nodeTreeViewController = nil;
  self.boardViewAutoLayoutConstraints = nil;

  // Properties used for landscape
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
    self.navigationBarButtonModel = [[[NavigationBarButtonModel alloc] init] autorelease];
    [GameActionManager sharedGameActionManager].uiDelegate = self;

    // We don't treat this as a child view controller. Reason:
    // - The status view is set as the title view of this container view
    //   controller's navigation item.
    // - This causes UIKit to add the status view as a subview to the navigation
    //   bar of the navigation controller that shows this container view
    //   controller.
    // - When we add StatusViewController as a child VC to this container VC,
    //   UIKit complains with the message that StatusViewController should be a
    //   child VC of the navigation VC.
    // - An attempt to follow this advice failed: When StatusViewController is
    //   made into a child VC of the navigation VC, StatusViewController is also
    //   added to the navigation VC's navigation stack - which is absolutely not
    //   what we want!
    self.statusViewController = [[[StatusViewController alloc] init] autorelease];

    ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
    self.resizablePane1ViewController = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    self.resizablePane2ViewController = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    NSArray* resizablePaneViewControllers = @[self.resizablePane1ViewController, self.resizablePane2ViewController];
    self.resizableStackViewController = [ResizableStackViewController resizableStackViewControllerWithViewControllers:resizablePaneViewControllers
                                                                                                                 axis:UILayoutConstraintAxisVertical];
    self.resizableStackViewController.delegate = self;
    UiSettingsModel* uiSettingsModel = applicationDelegate.uiSettingsModel;
    self.resizableStackViewController.sizes = uiSettingsModel.resizableStackViewControllerInitialSizesUiAreaPlay;
    NSNumber* uiAreaPlayResizablePaneMinimumSizeAsNumber = [NSNumber numberWithDouble:uiAreaPlayResizablePaneMinimumSize];
    self.resizableStackViewController.minimumSizes = @[uiAreaPlayResizablePaneMinimumSizeAsNumber, uiAreaPlayResizablePaneMinimumSizeAsNumber];
    self.resizableStackViewController.resizeStepSize /= 2;
    self.resizableStackViewController.spacingBetweenResizablePanes *= 2;
    self.resizableStackViewController.dragHandleThickness *= 1.5;
    self.resizableStackViewController.dragHandleGrabAreaMargin *= 2;

    self.boardViewController = [[[BoardViewController alloc] init] autorelease];
    self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
    self.annotationViewController = [AnnotationViewController annotationViewController];
    self.boardPositionCollectionViewController = [[[BoardPositionCollectionViewController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
    self.nodeTreeViewController = [[[NodeTreeViewController alloc] initWithModel:applicationDelegate.nodeTreeViewModel
                                                                  darkBackground:false] autorelease];

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

    self.splitViewControllerChild.leftPaneWidth = ceilf(self.splitViewControllerLeftPaneWidthMultiplier * [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero].width);
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all child view controllers from this view controller.
// -----------------------------------------------------------------------------
- (void) removeChildControllers
{
  self.navigationBarButtonModel = nil;
  if ([GameActionManager sharedGameActionManager].uiDelegate == self)
    [GameActionManager sharedGameActionManager].uiDelegate = nil;
  self.statusViewController = nil;
  self.boardViewController = nil;
  self.nodeTreeViewController = nil;

  // Workaround for issue seen on some iOS versions where
  // traitCollectionDidChange is invoked on ButtonBoxController during interface
  // rotation, causing it to reload data and access its data source. This
  // happens after the data source is already deallocated, resulting in a crash.
  self.boardPositionButtonBoxController.buttonBoxControllerDataSource = nil;

  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.annotationViewController = nil;
  self.boardPositionCollectionViewController = nil;
  self.resizableStackViewController = nil;
  self.resizablePane1ViewController = nil;
  self.resizablePane2ViewController = nil;

  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setResizableStackViewController:(ResizableStackViewController*)resizableStackViewController
{
  if (_resizableStackViewController == resizableStackViewController)
    return;
  if (_resizableStackViewController)
  {
    [_resizableStackViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_resizableStackViewController removeFromParentViewController];
    [_resizableStackViewController release];
    _resizableStackViewController = nil;
  }
  if (resizableStackViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:resizableStackViewController];
    [resizableStackViewController didMoveToParentViewController:self];
    [resizableStackViewController retain];
    _resizableStackViewController = resizableStackViewController;
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
    [self.resizablePane1ViewController addChildViewController:boardViewController];
    [boardViewController didMoveToParentViewController:self.resizablePane1ViewController];
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
    [self.resizablePane1ViewController addChildViewController:boardPositionButtonBoxController];
    [boardPositionButtonBoxController didMoveToParentViewController:self.resizablePane1ViewController];
    [boardPositionButtonBoxController retain];
    _boardPositionButtonBoxController = boardPositionButtonBoxController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setAnnotationViewController:(AnnotationViewController*)annotationViewController
{
  if (_annotationViewController == annotationViewController)
    return;
  if (_annotationViewController)
  {
    [_annotationViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_annotationViewController removeFromParentViewController];
    [_annotationViewController release];
    _annotationViewController = nil;
  }
  if (annotationViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self.resizablePane1ViewController addChildViewController:annotationViewController];
    [annotationViewController didMoveToParentViewController:self.resizablePane1ViewController];
    [annotationViewController retain];
    _annotationViewController = annotationViewController;
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
    [self.resizablePane1ViewController addChildViewController:boardPositionCollectionViewController];
    [boardPositionCollectionViewController didMoveToParentViewController:self.resizablePane1ViewController];
    [boardPositionCollectionViewController retain];
    _boardPositionCollectionViewController = boardPositionCollectionViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setNodeTreeViewController:(NodeTreeViewController*)nodeTreeViewController
{
  if (_nodeTreeViewController == nodeTreeViewController)
    return;
  if (_nodeTreeViewController)
  {
    [_nodeTreeViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_nodeTreeViewController removeFromParentViewController];
    [_nodeTreeViewController release];
    _nodeTreeViewController = nil;
  }
  if (nodeTreeViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self.resizablePane2ViewController addChildViewController:nodeTreeViewController];
    [nodeTreeViewController didMoveToParentViewController:self.resizablePane2ViewController];
    [nodeTreeViewController retain];
    _nodeTreeViewController = nodeTreeViewController;
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
  [self setupViewHierarchyForInterfaceOrientation:interfaceOrientation];
  [self configureViewsForInterfaceOrientation:interfaceOrientation];
  [self setupAutoLayoutConstraintsForInterfaceOrientation:interfaceOrientation];
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

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (@available(iOS 12.0, *))
  {
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
      [self updateColors];
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
  [self setupViewHierarchyForInterfaceOrientation:interfaceOrientation];
  [self configureViewsForInterfaceOrientation:interfaceOrientation];
  [self setupAutoLayoutConstraintsForInterfaceOrientation:interfaceOrientation];
}

#pragma mark - View hierarchy handling

// -----------------------------------------------------------------------------
/// @brief Sets up the view hierarchy managed by this view controller to
/// match the specified interface orientation.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchyForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    [self setupWoodenBackgroundView];
    [self setupResizablePane1ViewHierarchy];
    [self setupResizablePane2ViewHierarchy];

    self.navigationItem.titleView = self.statusViewController.view;
    [self.navigationBarButtonModel updateVisibleGameActions];
    [self populateNavigationBar];
  }
  else
  {
    [self.view addSubview:self.splitViewControllerChild.view];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchyForInterfaceOrientation.
// -----------------------------------------------------------------------------
- (void) setupWoodenBackgroundView
{
  // This view provides a wooden texture background not only for the Go board,
  // but for the entire area in which the Go board resides
  self.woodenBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

  [self.view addSubview:self.woodenBackgroundView];

  [self.woodenBackgroundView addSubview:self.resizableStackViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchyForInterfaceOrientation.
// -----------------------------------------------------------------------------
- (void) setupResizablePane1ViewHierarchy
{
  // This is a simple container view that takes up all the unused vertical
  // space and within which the board view is then centered, either horizontally
  // or vertically depending on which dimension gets more space.
  self.boardContainerView = [[[OrientationChangeNotifyingView alloc] initWithFrame:CGRectZero] autorelease];
  self.boardContainerView.delegate = self;
  [self.boardContainerView addSubview:self.boardViewController.view];
  [self.resizablePane1ViewController.view addSubview:self.boardContainerView];

  self.boardPositionButtonBoxContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.boardPositionButtonBoxContainerView addSubview:self.boardPositionButtonBoxController.view];

  self.boardPositionButtonBoxAndAnnotationContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.boardPositionButtonBoxAndAnnotationContainerView addSubview:self.boardPositionButtonBoxContainerView];
  [self.boardPositionButtonBoxAndAnnotationContainerView addSubview:self.annotationViewController.view];
  [self.resizablePane1ViewController.view addSubview:self.boardPositionButtonBoxAndAnnotationContainerView];

  [self.resizablePane1ViewController.view addSubview:self.boardPositionCollectionViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchyForInterfaceOrientation.
// -----------------------------------------------------------------------------
- (void) setupResizablePane2ViewHierarchy
{
  [self.resizablePane2ViewController.view addSubview:self.nodeTreeViewController.view];
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
  self.boardPositionButtonBoxAndAnnotationContainerView = nil;
  self.boardPositionButtonBoxContainerView = nil;

  self.navigationItem.titleView = nil;
  [self depopulateNavigationBar];
}

#pragma mark - View configuration

// -----------------------------------------------------------------------------
/// @brief Configures views as part of the view hierarchy setup process.
// -----------------------------------------------------------------------------
- (void) configureViewsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // self.edgesForExtendedLayout is UIRectEdgeAll, therefore we have to provide
  // a background color that is visible behind the tab bar at the bottom and
  // (in portrait orientation) behind the navigation bar at the top (which
  // extends behind the statusbar).
  //
  // Any sort of whiteish color is OK as long as it doesn't deviate too much
  // from the background colors on the other tabs (typically a table view
  // background color).
  self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

    [self updateColors];
    self.boardPositionCollectionViewController.view.layer.borderWidth = self.boardPositionCollectionViewBorderWidth;

    [self.boardPositionButtonBoxController reloadData];
  }
  else
  {
    // Nothing to configure in landscape orientation - this is all done by
    // child view controllers
  }
}

#pragma mark - Auto layout constraint handling

// -----------------------------------------------------------------------------
/// @brief Sets up the auto layout constraints of the view of this view
/// controller to match the specified interface orientation.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
    [self setupAutoLayoutConstraintsPortrait];
  else
    [self setupAutoLayoutConstraintsLandscape];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// setupAutoLayoutConstraintsForInterfaceOrientation:().
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortrait
{
  self.autoLayoutConstraints = [NSMutableArray array];
  [self setupAutoLayoutConstraintsPortraitMainView];
  [self setupAutoLayoutConstraintsPortraitWoodenBackgroundView];
  [self setupAutoLayoutConstraintsPortraitResizablePane1];
  [self setupAutoLayoutConstraintsPortraitResizablePane2];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsPortrait.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortraitMainView
{
  // Wooden background view is laid out within the safe area of the main view.
  // Especially important are the top/bottom of the safe area - this prevents
  // the wooden background from extending behind the navigation bar at the top
  // or the tab bar at the bottom
  self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  NSArray* constraints = [AutoLayoutUtility fillSafeAreaOfSuperview:self.view withSubview:self.woodenBackgroundView];
  [self.autoLayoutConstraints addObjectsFromArray:constraints];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsPortrait.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortraitWoodenBackgroundView
{
  self.resizableStackViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  viewsDictionary[@"resizableStackView"] = self.resizableStackViewController.view;

  NSMutableArray* visualFormats = [NSMutableArray array];
  [visualFormats addObject:@"H:|-[resizableStackView]-|"];
  [visualFormats addObject:@"V:|-[resizableStackView]-|"];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.resizableStackViewController.view.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsPortrait.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortraitResizablePane1
{
  CGSize buttonBoxSize = self.boardPositionButtonBoxController.buttonBoxSize;
  // The annotation view should be high enough to display most description
  // texts without scrolling. It can't be arbitrarily high because it must
  // leave enough space for the board view. It can't be arbitrarily small
  // because it must have sufficient space to display two vertically stacked
  // buttons.
  int annotationViewHeight = buttonBoxSize.height * self.annotationViewHeightMultiplier;

  CGFloat boardPositionCollectionViewHeight = [self.boardPositionCollectionViewController boardPositionCollectionViewMaximumCellSize].height;
  boardPositionCollectionViewHeight += 2 * self.boardPositionCollectionViewBorderWidth;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.boardContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionButtonBoxAndAnnotationContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  
  viewsDictionary[@"boardContainerView"] = self.boardContainerView;
  viewsDictionary[@"boardPositionButtonBoxAndAnnotationContainerView"] = self.boardPositionButtonBoxAndAnnotationContainerView;
  viewsDictionary[@"boardPositionCollectionView"] = self.boardPositionCollectionViewController.view;

  [visualFormats addObject:@"H:|-0-[boardContainerView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionButtonBoxAndAnnotationContainerView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionCollectionView]-0-|"];
  [visualFormats addObject:@"V:|-[boardContainerView]-[boardPositionButtonBoxAndAnnotationContainerView]-[boardPositionCollectionView]-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionCollectionView(==%f)]", boardPositionCollectionViewHeight]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.boardContainerView.superview];

  [self setupAutoLayoutConstraintsPortraitBoardPositionButtonBoxAndAnnotationContainerView:annotationViewHeight];
  [self setupAutoLayoutConstraintsPortraitBoardPositionButtonBoxContainerView:buttonBoxSize];
  [self setupAutoLayoutConstraintsPortraitBoardContainerView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsPortraitResizablePane1.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortraitBoardPositionButtonBoxAndAnnotationContainerView:(int)annotationViewHeight
{
  // The annotation view height defines the height of the entire
  // boardPositionButtonBoxAndAnnotationContainerView. The button box width is
  // defined elsewhere, the annotation view gets the remaining width.

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.boardPositionButtonBoxContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.annotationViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"boardPositionButtonBoxContainerView"] = self.boardPositionButtonBoxContainerView;
  viewsDictionary[@"annotationView"] = self.annotationViewController.view;

  [visualFormats addObject:@"H:|-0-[boardPositionButtonBoxContainerView]-[annotationView]-0-|"];
  [visualFormats addObject:@"V:|-0-[boardPositionButtonBoxContainerView]-0-|"];
  [visualFormats addObject:@"V:|-0-[annotationView]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[annotationView(==%d)]", annotationViewHeight]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.boardPositionButtonBoxContainerView.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsPortraitResizablePane1.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortraitBoardPositionButtonBoxContainerView:(CGSize)buttonBoxSize
{
  // Here we define the button box width. Also, the button box is expected to be
  // less high than its container view (whose height is defined by the
  // annotation view), so we give the button box a fixed height and position it
  // vertically centered within its container view.

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.boardPositionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"boardPositionButtonBox"] = self.boardPositionButtonBoxController.view;

  [visualFormats addObject:@"H:|-0-[boardPositionButtonBox]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[boardPositionButtonBox(==%f)]", buttonBoxSize.width]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox(==%f)]", buttonBoxSize.height]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.boardPositionButtonBoxController.view.superview];

  [AutoLayoutUtility alignFirstView:self.boardPositionButtonBoxController.view
                     withSecondView:self.boardPositionButtonBoxController.view.superview
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self.boardPositionButtonBoxController.view.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsPortraitResizablePane1.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortraitBoardContainerView
{
  self.boardViewAutoLayoutConstraints = [NSMutableArray array];

  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  
  [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                              ofBoardView:self.boardViewController.view
                                                  forAxis:self.boardViewSmallerDimension
                                         constraintHolder:self.boardViewController.view.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsPortrait.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsPortraitResizablePane2
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.nodeTreeViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"nodeTreeView"] = self.nodeTreeViewController.view;

  [visualFormats addObject:@"H:|-0-[nodeTreeView]-0-|"];
  [visualFormats addObject:@"V:|-[nodeTreeView]-|"];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.nodeTreeViewController.view.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// setupAutoLayoutConstraintsForInterfaceOrientation:().
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsLandscape
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.splitViewControllerChild.view.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"splitView"] = self.splitViewControllerChild.view;
  // Let the split view extend all the way to the left/right edges of our
  // view. The left/right pane controllers take care of the safe area handling.
  [visualFormats addObject:@"H:|-0-[splitView]-0-|"];
  NSArray* visualFormatsConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                                    withViews:viewsDictionary
                                                                       inView:self.view];
  self.autoLayoutConstraints = [NSMutableArray arrayWithArray:visualFormatsConstraints];

  [AutoLayoutUtility alignFirstView:self.splitViewControllerChild.view
                     withSecondView:self.view
                    onSafeAreaEdges:self.splitViewControllerSafeAreaEdges];
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
}

#pragma mark - OrientationChangeNotifyingViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief OrientationChangeNotifyingViewDelegate protocol method.
///
/// This delegate method is important for finding out which is the smaller
/// dimension of the board view after layouting has finished, so that in a final
/// round of layouting the board view can be constrained to be square for that
/// dimension.
///
/// This delegate method handles interface orientation changes while this
/// controller's view hierarchy is visible, and changes that occurred while this
/// controller's view hierarchy was not visible (this method is invoked when the
/// controller's view becomes visible again). Typically an override of
/// the UIViewController method viewWillLayoutSubviews could also be used for
/// this.
///
/// The reason why viewWillLayoutSubviews is not overridden is that UIKit does
/// not invoke viewWillLayoutSubviews every time that the bounds of
/// self.middleColumnView change, so it can't be relied on to find out the
/// board view's smaller dimension.
// -----------------------------------------------------------------------------
- (void) orientationChangeNotifyingView:(OrientationChangeNotifyingView*)orientationChangeNotifyingView
             didChangeToLargerDimension:(UILayoutConstraintAxis)largerDimension
                       smallerDimension:(UILayoutConstraintAxis)smallerDimension
{
  if (self.boardViewSmallerDimension != smallerDimension)
  {
    self.boardViewSmallerDimension = smallerDimension;

    [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                                ofBoardView:self.boardViewController.view
                                                    forAxis:self.boardViewSmallerDimension
                                           constraintHolder:self.boardViewController.view.superview];
  }
}

#pragma mark - GameActionManagerUIDelegate overrides

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
       updateVisibleStates:(NSDictionary*)gameActions
{
  [self.navigationBarButtonModel updateVisibleGameActionsWithVisibleStates:gameActions];
  [self populateNavigationBar];
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
                    enable:(BOOL)enable
                gameAction:(enum GameAction)gameAction
{
  NSNumber* gameActionAsNumber = [NSNumber numberWithInt:gameAction];
  UIBarButtonItem* button = self.navigationBarButtonModel.gameActionButtons[gameActionAsNumber];
  button.enabled = enable;
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
    updateIconOfGameAction:(enum GameAction)gameAction
{
  [self.navigationBarButtonModel updateIconOfGameAction:gameAction];
}

#pragma mark - ResizableStackViewControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ResizableStackViewControllerDelegate method.
// -----------------------------------------------------------------------------
- (void) resizableStackViewController:(ResizableStackViewController*)controller
                   viewSizesDidChange:(NSArray*)newSizes;
{
  // TODO xxx this should save only portrait sizes
  UiSettingsModel* uiSettingsModel = [ApplicationDelegate sharedDelegate].uiSettingsModel;
  uiSettingsModel.resizableStackViewControllerInitialSizesUiAreaPlay = newSizes;
}

#pragma mark - Navigation bar population

// -----------------------------------------------------------------------------
/// @brief Populates the navigation bar with buttons that are appropriate for
/// the current application state.
// -----------------------------------------------------------------------------
- (void) populateNavigationBar
{
  [self populateLeftBarButtonItems];
  [self populateRightBarButtonItems];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBar().
// -----------------------------------------------------------------------------
- (void) populateLeftBarButtonItems
{
  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  for (NSNumber* gameActionAsNumber in self.navigationBarButtonModel.visibleGameActions)
  {
    UIBarButtonItem* button = self.navigationBarButtonModel.gameActionButtons[gameActionAsNumber];
    [barButtonItems addObject:button];
  }
  self.navigationItem.leftBarButtonItems = barButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBar().
// -----------------------------------------------------------------------------
- (void) populateRightBarButtonItems
{
  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  [barButtonItems addObject:self.navigationBarButtonModel.gameActionButtons[[NSNumber numberWithInt:GameActionMoreGameActions]]];
  [barButtonItems addObject:self.navigationBarButtonModel.gameActionButtons[[NSNumber numberWithInt:GameActionGameInfo]]];
  self.navigationItem.rightBarButtonItems = barButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief Removes all buttons from the navigation bar.
// -----------------------------------------------------------------------------
- (void) depopulateNavigationBar
{
  self.navigationItem.leftBarButtonItems = nil;
  self.navigationItem.rightBarButtonItems = nil;
}

#pragma mark - User interface style handling (light/dark mode)

// -----------------------------------------------------------------------------
/// @brief Updates all kinds of colors to match the current
/// UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateColors
{
  UITraitCollection* traitCollection = self.traitCollection;
  [UiUtilities applyTransparentStyleToView:self.boardPositionButtonBoxContainerView traitCollection:traitCollection];
  [UiUtilities applyTransparentStyleToView:self.annotationViewController.view traitCollection:traitCollection];
  [UiUtilities applyTransparentStyleToView:self.nodeTreeViewController.view traitCollection:traitCollection];
}

@end
