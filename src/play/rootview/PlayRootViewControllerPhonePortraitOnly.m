// -----------------------------------------------------------------------------
// Copyright 2013-2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayRootViewControllerPhonePortraitOnly.h"
#import "../annotationview/AnnotationViewController.h"
#import "../boardposition/BoardPositionButtonBoxDataSource.h"
#import "../boardposition/BoardPositionCollectionViewCell.h"
#import "../boardposition/BoardPositionCollectionViewController.h"
#import "../boardview/BoardViewController.h"
#import "../controller/AutoLayoutConstraintHelper.h"
#import "../model/NavigationBarButtonModel.h"
#import "../model/NodeTreeViewModel.h"
#import "../nodetreeview/NodeTreeViewIntegration.h"
#import "../statusarea/StatusAreaViewController.h"
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/ResizableStackViewController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayRootViewControllerPhonePortraitOnly.
// -----------------------------------------------------------------------------
@interface PlayRootViewControllerPhonePortraitOnly()
// Views
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) OrientationChangeNotifyingView* boardContainerView;
@property(nonatomic, retain) UIView* boardPositionButtonBoxAndAnnotationContainerView;
@property(nonatomic, retain) UIView* boardPositionButtonBoxContainerView;
// Controllers and data sources
@property(nonatomic, retain) ResizableStackViewController* resizableStackViewController;
@property(nonatomic, retain) UIViewController* resizablePane1ViewController;
@property(nonatomic, retain) NavigationBarButtonModel* navigationBarButtonModel;
@property(nonatomic, retain) StatusAreaViewController* statusAreaViewController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) AnnotationViewController* annotationViewController;
@property(nonatomic, retain) BoardPositionCollectionViewController* boardPositionCollectionViewController;
@property(nonatomic, retain) NodeTreeViewIntegration* nodeTreeViewIntegration;
@property(nonatomic, assign) UILayoutConstraintAxis boardViewSmallerDimension;
@property(nonatomic, retain) NSMutableArray* boardViewAutoLayoutConstraints;
@property(nonatomic, assign) CGFloat boardPositionCollectionViewBorderWidth;
@end


@implementation PlayRootViewControllerPhonePortraitOnly

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayRootViewControllerPhonePortraitOnly object.
///
/// @note This is the designated initializer of
/// PlayRootViewControllerPhonePortraitOnly.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (PlayRootViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.boardViewSmallerDimension = UILayoutConstraintAxisHorizontal;
  self.boardPositionCollectionViewBorderWidth = 1.0f;
  [self setupChildControllers];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// PlayRootViewControllerPhonePortraitOnly object.
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
  [self removeChildViewControllersFromResizablePane1ViewController];

  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
  self.boardPositionButtonBoxAndAnnotationContainerView = nil;
  self.boardPositionButtonBoxContainerView = nil;

  self.resizableStackViewController = nil;
  self.resizablePane1ViewController = nil;
  self.navigationBarButtonModel = nil;
  self.statusAreaViewController = nil;
  self.boardViewController = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.annotationViewController = nil;
  self.boardPositionCollectionViewController = nil;
  self.nodeTreeViewIntegration = nil;

  self.boardViewAutoLayoutConstraints = nil;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.navigationBarButtonModel = [[[NavigationBarButtonModel alloc] init] autorelease];
  [GameActionManager sharedGameActionManager].uiDelegate = self;

  id<ModelProvider> modelProvider = [Registry sharedRegistry].modelProvider;
  self.resizablePane1ViewController = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];
  NSArray* resizablePaneViewControllers = @[self.resizablePane1ViewController];
  self.resizableStackViewController = [ResizableStackViewController resizableStackViewControllerWithViewControllers:resizablePaneViewControllers
                                                                                                               axis:UILayoutConstraintAxisVertical];
  self.statusAreaViewController = [[[StatusAreaViewController alloc] init] autorelease];
  self.boardViewController = [[[BoardViewController alloc] init] autorelease];
  self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
  self.annotationViewController = [AnnotationViewController annotationViewControllerWithSizeOrientation:SizeOrientationPortrait];
  self.boardPositionCollectionViewController = [[[BoardPositionCollectionViewController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
  [self addChildViewControllersToResizablePane1ViewController];

  self.nodeTreeViewIntegration = [[[NodeTreeViewIntegration alloc] initWithResizableStackViewController:self.resizableStackViewController
                                                                                      nodeTreeViewModel:modelProvider.nodeTreeViewModel
                                                                                        uiSettingsModel:modelProvider.uiSettingsModel] autorelease];

  self.boardPositionButtonBoxDataSource = [[[BoardPositionButtonBoxDataSource alloc] init] autorelease];
  self.boardPositionButtonBoxController.buttonBoxControllerDataSource = self.boardPositionButtonBoxDataSource;
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
/// @brief Adds all view controllers whose views are displayed in the view of
/// @e resizablePane1ViewController as child view controllers to
/// @e resizablePane1ViewController. Does nothing if view controllers to not
/// exist, or @e resizablePane1ViewController does not exist.
// -----------------------------------------------------------------------------
- (void) addChildViewControllersToResizablePane1ViewController
{
  if (! self.resizablePane1ViewController)
    return;

  NSArray* resizablePane1ChildViewControllers = [self resizablePane1ChildViewControllers];
  for (UIViewController* childViewController in resizablePane1ChildViewControllers)
  {
    // Automatically calls willMoveToParentViewController:
    [self.resizablePane1ViewController addChildViewController:childViewController];
    [childViewController didMoveToParentViewController:self.resizablePane1ViewController];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all view controllers whose views are displayed in the view of
/// @e resizablePane1ViewController from their parent view controller (which
/// implicitly is @e resizablePane1ViewController). Does nothing if view
/// controllers do not exist.
// -----------------------------------------------------------------------------
- (void) removeChildViewControllersFromResizablePane1ViewController
{
  NSArray* resizablePane1ChildViewControllers = [self resizablePane1ChildViewControllers];
  for (UIViewController* childViewController in resizablePane1ChildViewControllers)
  {
    [childViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [childViewController removeFromParentViewController];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of controllers whose views are displayed in the view
/// of @e resizablePane1ViewController. Returns an empty list if view
/// controllers do not exist.
// -----------------------------------------------------------------------------
- (NSArray*) resizablePane1ChildViewControllers
{
  NSMutableArray* resizablePane1ChildViewControllers = [NSMutableArray array];

  if (self.statusAreaViewController)
    [resizablePane1ChildViewControllers addObject:self.statusAreaViewController];
  if (self.boardViewController)
    [resizablePane1ChildViewControllers addObject:self.boardViewController];
  if (self.boardPositionButtonBoxController)
    [resizablePane1ChildViewControllers addObject:self.boardPositionButtonBoxController];
  if (self.annotationViewController)
    [resizablePane1ChildViewControllers addObject:self.annotationViewController];
  if (self.boardPositionCollectionViewController)
    [resizablePane1ChildViewControllers addObject:self.boardPositionCollectionViewController];

  return resizablePane1ChildViewControllers;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupViewHierarchy];
  [self configureViews];
  [self setupAutoLayoutConstraints];
  [self.nodeTreeViewIntegration performIntegration];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
    [self updateColors];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self setupWoodenBackgroundView];
  [self setupResizablePane1ViewHierarchy];
  [self setupNavigationBar];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchy.
// -----------------------------------------------------------------------------
- (void) setupWoodenBackgroundView
{
  self.woodenBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

  [self.view addSubview:self.woodenBackgroundView];

  [self.woodenBackgroundView addSubview:self.resizableStackViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchy.
// -----------------------------------------------------------------------------
- (void) setupResizablePane1ViewHierarchy
{
  [self.resizablePane1ViewController.view addSubview:self.statusAreaViewController.view];

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
/// @brief Private helper for setupViewHierarchy.
// -----------------------------------------------------------------------------
- (void) setupNavigationBar
{
  [self.navigationBarButtonModel updateVisibleGameActions];
  [self populateNavigationBar];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  // self.edgesForExtendedLayout is UIRectEdgeAll, therefore we have to provide
  // a background color that is visible behind the tab bar at the bottom and
  // (in portrait orientation) behind the navigation bar at the top (which
  // extends behind the statusbar).
  //
  // Any sort of whiteish color is OK as long as it doesn't deviate too much
  // from the background colors on the other tabs (typically a table view
  // background color).
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

  self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

  [self updateColors];
  self.boardPositionCollectionViewController.view.layer.borderWidth = self.boardPositionCollectionViewBorderWidth;

  [self.boardPositionButtonBoxController reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  [self setupAutoLayoutConstraintsMainView];
  [self setupAutoLayoutConstraintsWoodenBackgroundView];
  [self setupAutoLayoutConstraintsResizablePane1];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsMainView
{
  // Wooden background view is laid out within the safe area of the main view.
  // Especially important are the top/bottom of the safe area - this prevents
  // the wooden background from extending behind the navigation bar at the top
  // or the tab bar at the bottom
  self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSafeAreaOfSuperview:self.view withSubview:self.woodenBackgroundView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsWoodenBackgroundView
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.resizableStackViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"resizableStackView"] = self.resizableStackViewController.view;

  [visualFormats addObject:@"H:|-[resizableStackView]-|"];
  [visualFormats addObject:@"V:|-[resizableStackView]-|"];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.resizableStackViewController.view.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsResizablePane1
{
  CGSize buttonBoxSize = self.boardPositionButtonBoxController.buttonBoxSize;
  // The annotation view should be high enough to display most description
  // texts without scrolling. It can't be arbitrarily high because it must
  // leave enough space for the board view. It can't be arbitrarily small
  // because it must have sufficient space to display two vertically stacked
  // buttons.
  // Note: In older versions of the app where the navigation buttons were
  // substantially smaller, the multiplier used to be greater than 1.
  int annotationViewHeight = buttonBoxSize.height * 1.0;

  CGFloat boardPositionCollectionViewHeight = [self.boardPositionCollectionViewController boardPositionCollectionViewMaximumCellSize].height;
  boardPositionCollectionViewHeight += 2 * self.boardPositionCollectionViewBorderWidth;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.statusAreaViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionButtonBoxAndAnnotationContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"statusAreaView"] = self.statusAreaViewController.view;
  viewsDictionary[@"boardContainerView"] = self.boardContainerView;
  viewsDictionary[@"boardPositionButtonBoxAndAnnotationContainerView"] = self.boardPositionButtonBoxAndAnnotationContainerView;
  viewsDictionary[@"boardPositionCollectionView"] = self.boardPositionCollectionViewController.view;

  [visualFormats addObject:@"H:|-0-[statusAreaView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardContainerView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionButtonBoxAndAnnotationContainerView]-0-|"];
  [visualFormats addObject:@"H:|-0-[boardPositionCollectionView]-0-|"];
  [visualFormats addObject:@"V:|-[statusAreaView]-[boardContainerView]-[boardPositionButtonBoxAndAnnotationContainerView]-[boardPositionCollectionView]-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionCollectionView(==%f)]", boardPositionCollectionViewHeight]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.boardContainerView.superview];

  [self setupAutoLayoutConstraintsBoardPositionButtonBoxAndAnnotationContainerView:annotationViewHeight];
  [self setupAutoLayoutConstraintsBoardPositionButtonBoxContainerView:buttonBoxSize];
  [self setupAutoLayoutConstraintsBoardContainerView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsResizablePane1.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsBoardPositionButtonBoxAndAnnotationContainerView:(int)annotationViewHeight
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
/// @brief Private helper for setupAutoLayoutConstraintsResizablePane1.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsBoardPositionButtonBoxContainerView:(CGSize)buttonBoxSize
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
/// @brief Private helper for setupAutoLayoutConstraintsResizablePane1.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsBoardContainerView
{
  self.boardViewAutoLayoutConstraints = [NSMutableArray array];

  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                              ofBoardView:self.boardViewController.view
                                                  forAxis:self.boardViewSmallerDimension
                                         constraintHolder:self.boardViewController.view.superview];
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
/// This delegate method handles the following known cases:
/// - Interface orientation changes while this controller's view hierarchy is
///   visible.
/// - Interface orientation changes changes that occurred while this
///   controller's view hierarchy was not visible (this method is invoked when
///   the controller's view becomes visible again).
/// - When the user interactively resizes board view / node tree view and causes
///   the board view's orientation to change.
/// - Other changes to the board view's bounds that cause the board view's
///   orientation to change. This may occur when this view controller's view
///   hierarchy becomes visible for the first time and the initial layouting
///   of the view hierarchy takes place.
///
/// An override of the UIViewController method viewWillLayoutSubviews cannot
/// be used to reliably handle all of these cases. The first two cases would be
/// OK, but not the last two - UIKit does not invoke viewWillLayoutSubviews
/// every time that the bounds of a subview change.
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
  [self.nodeTreeViewIntegration updateColors:traitCollection];
}

@end
