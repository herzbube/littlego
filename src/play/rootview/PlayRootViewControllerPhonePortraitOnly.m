// -----------------------------------------------------------------------------
// Copyright 2013-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "../controller/StatusViewController.h"
#import "../model/NavigationBarButtonModel.h"
#import "../model/NodeTreeViewModel.h"
#import "../nodetreeview/NodeTreeViewIntegration.h"
#import "../../main/ApplicationDelegate.h"
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
@property(nonatomic, retain) StatusViewController* statusViewController;
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
  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
  self.boardPositionButtonBoxAndAnnotationContainerView = nil;
  self.boardPositionButtonBoxContainerView = nil;

  self.resizableStackViewController = nil;
  self.resizablePane1ViewController = nil;
  self.navigationBarButtonModel = nil;
  self.statusViewController = nil;
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
  NSArray* resizablePaneViewControllers = @[self.resizablePane1ViewController];
  self.resizableStackViewController = [ResizableStackViewController resizableStackViewControllerWithViewControllers:resizablePaneViewControllers
                                                                                                               axis:UILayoutConstraintAxisVertical];
  self.boardViewController = [[[BoardViewController alloc] init] autorelease];
  self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
  self.annotationViewController = [AnnotationViewController annotationViewController];
  self.boardPositionCollectionViewController = [[[BoardPositionCollectionViewController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
  self.nodeTreeViewIntegration = [[[NodeTreeViewIntegration alloc] initWithResizableStackViewController:self.resizableStackViewController
                                                                                      nodeTreeViewModel:applicationDelegate.nodeTreeViewModel
                                                                                        uiSettingsModel:applicationDelegate.uiSettingsModel] autorelease];

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
  self.navigationItem.titleView = self.statusViewController.view;
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
  int annotationViewHeight = buttonBoxSize.height * 1.1;

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
  [self.nodeTreeViewIntegration updateColors];
}

@end
