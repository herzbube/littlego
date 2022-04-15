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
#import "../annotationview/AnnotationViewController.h"
#import "../boardposition/BoardPositionButtonBoxDataSource.h"
#import "../boardposition/BoardPositionCollectionViewCell.h"
#import "../boardposition/BoardPositionCollectionViewController.h"
#import "../boardview/BoardViewController.h"
#import "../controller/AutoLayoutConstraintHelper.h"
#import "../controller/StatusViewController.h"
#import "../model/NavigationBarButtonModel.h"
#import "../splitview/LeftPaneViewController.h"
#import "../splitview/RightPaneViewController.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/ButtonBoxController.h"
#import "../../ui/SplitViewController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayRootViewControllerPhone.
// -----------------------------------------------------------------------------
@interface PlayRootViewControllerPhone()
/// @name Properties used for both interface orientations
//@{
@property (nonatomic, assign) bool viewsAreInPortraitOrientation;
@property (nonatomic, retain) NSMutableArray* autoLayoutConstraints;
@property(nonatomic, retain) NSMutableArray* boardViewAutoLayoutConstraints;
//@}

/// @name Properties used for portrait
//@{
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) UIView* boardContainerView;
@property(nonatomic, retain) UIView* boardPositionButtonBoxContainerView;
@property(nonatomic, retain) NavigationBarButtonModel* navigationBarButtonModel;
@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) AnnotationViewController* annotationViewController;
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
  self.viewsAreInPortraitOrientation = true;
  self.autoLayoutConstraints = nil;
  self.boardViewAutoLayoutConstraints = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayRootViewControllerPhone
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
  self.boardViewAutoLayoutConstraints = nil;
  self.annotationViewController = nil;
  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
  self.boardPositionButtonBoxContainerView = nil;
  self.navigationBarButtonModel = nil;
  self.statusViewController = nil;
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
    self.boardViewController = [[[BoardViewController alloc] init] autorelease];
    self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
    self.annotationViewController = [AnnotationViewController annotationViewController];
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
    self.splitViewControllerChild.leftPaneWidth = [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero].width;
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
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.annotationViewController = nil;
  self.boardPositionCollectionViewController = nil;
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
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
    [self addChildViewController:annotationViewController];
    [annotationViewController didMoveToParentViewController:self];
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

    // This container view contains the button box and the annotation view.
    // The higher of the two determines how much vertical space the container
    // view consumes.
    self.boardPositionButtonBoxContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

    [self.view addSubview:self.woodenBackgroundView];
    [self.view addSubview:self.boardPositionCollectionViewController.view];

    [self.woodenBackgroundView addSubview:self.boardContainerView];
    [self.woodenBackgroundView addSubview:self.boardPositionButtonBoxContainerView];

    [self.boardContainerView addSubview:self.boardViewController.view];

    [self.boardPositionButtonBoxContainerView addSubview:self.boardPositionButtonBoxController.view];
    [self.boardPositionButtonBoxContainerView addSubview:self.annotationViewController.view];

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
/// @brief Removes all subviews from the view of this view controller.
// -----------------------------------------------------------------------------
- (void) removeViewHierarchy
{
  for (UIView* subview in self.view.subviews)
    [subview removeFromSuperview];

  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
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

    [self.boardPositionButtonBoxController applyTransparentStyle];
    [self.annotationViewController applyTransparentStyle];

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

  self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  CGFloat boardPositionCollectionViewHeight = [self.boardPositionCollectionViewController boardPositionCollectionViewMaximumCellSize].height;
  viewsDictionary[@"woodenBackgroundView"] = self.woodenBackgroundView;
  viewsDictionary[@"boardPositionCollectionView"] = self.boardPositionCollectionViewController.view;
  [visualFormats addObject:@"H:|-0-[woodenBackgroundView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionCollectionView]-0-|"];
  [visualFormats addObject:@"V:[woodenBackgroundView]-0-[boardPositionCollectionView]"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionCollectionView(==%f)]", boardPositionCollectionViewHeight]];
  NSArray* visualFormatsConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                                    withViews:viewsDictionary
                                                                       inView:self.view];
  self.autoLayoutConstraints = [NSMutableArray arrayWithArray:visualFormatsConstraints];

  // Align views with the top/bottom of the safe area - this prevents them from
  // extending behind the navigation bar at the top or the tab bar at the bottom
  NSLayoutConstraint* topConstraint = [AutoLayoutUtility alignFirstView:self.woodenBackgroundView
                                                         withSecondView:self.view
                                            onSafeAreaLayoutGuideAnchor:NSLayoutAttributeTop];
  [self.autoLayoutConstraints addObject:topConstraint];
  NSLayoutConstraint* bottomConstraint = [AutoLayoutUtility alignFirstView:self.boardPositionCollectionViewController.view
                                                            withSecondView:self.view
                                               onSafeAreaLayoutGuideAnchor:NSLayoutAttributeBottom];
  [self.autoLayoutConstraints addObject:bottomConstraint];

  // Here we define the layout of the container views within the wooden
  // background view. The height of the button box container view is defined
  // further down. The board container view gets the remaining height.
  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  self.boardContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionButtonBoxContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"boardContainerView"] = self.boardContainerView;
  viewsDictionary[@"boardPositionButtonBoxContainerView"] = self.boardPositionButtonBoxContainerView;
  [visualFormats addObject:@"H:|-0-[boardContainerView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionButtonBoxContainerView]-0-|"];
  [visualFormats addObject:@"V:|-0-[boardContainerView]-0-[boardPositionButtonBoxContainerView]-0-|"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.woodenBackgroundView];

  // Here we define the height and positioning of the annotation view and the
  // button box in the button box container view. The height of the annotation
  // view defines the height of the button box container view itself.
  CGSize buttonBoxSize = self.boardPositionButtonBoxController.buttonBoxSize;
  // The annotation view should be high enough to display most description
  // texts without scrolling. It can't be arbitrarily high because it must
  // leave enough space for the board view.
  int annotationViewHeight = buttonBoxSize.height * 1.5;
  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  self.boardPositionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.annotationViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"boardPositionButtonBox"] = self.boardPositionButtonBoxController.view;
  viewsDictionary[@"annotationView"] = self.annotationViewController.view;
  [visualFormats addObject:[NSString stringWithFormat:@"H:|-[boardPositionButtonBox]-[annotationView]-|"]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox]-|"]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-[annotationView]-|"]];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[boardPositionButtonBox(==%f)]", buttonBoxSize.width]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox(==%f)]", buttonBoxSize.height]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[annotationView(==%d)]", annotationViewHeight]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.boardPositionButtonBoxController.view.superview];

  self.boardViewAutoLayoutConstraints = [NSMutableArray array];
  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                              ofBoardView:self.boardViewController.view
                                                  forAxis:UILayoutConstraintAxisHorizontal
                                         constraintHolder:self.boardViewController.view.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// updateAutoLayoutConstraintsForInterfaceOrientation:().
// -----------------------------------------------------------------------------
- (void) updateAutoLayoutConstraintsLandscape
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.splitViewControllerChild.view.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"splitView"] = self.splitViewControllerChild.view;
  // Let the split view extend all the way to the left/right edges of our
  // view. The left/right pane controllers take care of the safe area handling.
  [visualFormats addObject:@"H:|-0-[splitView]-0-|"];
  [visualFormats addObject:@"V:|-0-[splitView]"];
  NSArray* visualFormatsConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                                    withViews:viewsDictionary
                                                                       inView:self.view];
  self.autoLayoutConstraints = [NSMutableArray arrayWithArray:visualFormatsConstraints];

  // Align split view with the bottom of the safe area - this prevents it from
  // extending behind the tab bar at the bottom
  [AutoLayoutUtility alignFirstView:self.splitViewControllerChild.view
                     withSecondView:self.view
                    onSafeAreaEdges:UIRectEdgeBottom];
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

@end
