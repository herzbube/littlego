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

// TODO xxx Move margin handling into ResizableStackViewController - we do this
// mainly to provide space for drag handles, but even when resizingEnabled is
// false it is usually desirable to have a spacing between resizable panes.
static int spacingBetweenResizablePanes = 4;

// TODO xxx The initial size for the node tree view, should be a user preference
static NSArray* resizableStackViewControllerInitialSizes = nil;

// TODO xxx Will become part of a future controller of some sort that will
// handle the content switching for all PlayRootViewController subclasses.
enum ResizablePane2Content
{
  ResizablePane2ContentBoardPositionCollectionView,
  ResizablePane2ContentNodeTreeView,
};

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
#import "../nodetreeview/NodeTreeViewController.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/ResizableStackViewController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayRootViewControllerPhonePortraitOnly.
// -----------------------------------------------------------------------------
@interface PlayRootViewControllerPhonePortraitOnly()
@property(nonatomic, retain) NavigationBarButtonModel* navigationBarButtonModel;
@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, retain) ResizableStackViewController* resizableStackViewController;
@property(nonatomic, retain) UIViewController* resizablePane1ViewController;
@property(nonatomic, retain) UIViewController* resizablePane2ViewController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) AnnotationViewController* annotationViewController;
@property(nonatomic, retain) BoardPositionCollectionViewController* boardPositionCollectionViewController;
@property(nonatomic, retain) NodeTreeViewController* nodeTreeViewController;
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) OrientationChangeNotifyingView* boardContainerView;
@property(nonatomic, retain) UIView* boardPositionButtonBoxAndAnnotationContainerView;
@property(nonatomic, retain) UIView* boardPositionButtonBoxContainerView;
@property(nonatomic, retain) UIButton* switchContentInResizablePane2Button;
@property(nonatomic, retain) NSMutableArray* resizablePane2ContentAutoLayoutConstraints;
@property(nonatomic, assign) enum ResizablePane2Content currentResizablePane2Content;
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

  if (! resizableStackViewControllerInitialSizes)
  {
    CGFloat resizablePane1Size = 1.0f - uiAreaPlayResizablePaneMinimumSize;
    NSNumber* resizablePane1SizeAsNumber = [NSNumber numberWithDouble:resizablePane1Size];
    NSNumber* resizablePane2SizeAsNumber = [NSNumber numberWithDouble:uiAreaPlayResizablePaneMinimumSize];
    resizableStackViewControllerInitialSizes = @[resizablePane1SizeAsNumber, resizablePane2SizeAsNumber];
  }

  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  NodeTreeViewModel* nodeTreeViewModel = applicationDelegate.nodeTreeViewModel;

  self.resizablePane2ContentAutoLayoutConstraints = [NSMutableArray array];
  self.currentResizablePane2Content = nodeTreeViewModel.displayNodeTreeView ? ResizablePane2ContentNodeTreeView : ResizablePane2ContentBoardPositionCollectionView;
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
  self.navigationBarButtonModel = nil;
  self.statusViewController = nil;
  self.resizableStackViewController = nil;
  self.resizablePane1ViewController = nil;
  self.resizablePane2ViewController = nil;
  self.boardViewController = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.annotationViewController = nil;
  self.boardPositionCollectionViewController = nil;
  self.nodeTreeViewController = nil;
  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
  self.boardPositionButtonBoxAndAnnotationContainerView = nil;
  self.boardPositionButtonBoxContainerView = nil;
  self.switchContentInResizablePane2Button = false;
  self.resizablePane2ContentAutoLayoutConstraints = nil;
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

  self.resizablePane1ViewController = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];
  self.resizablePane2ViewController = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];
  NSArray* resizablePaneViewControllers = @[self.resizablePane1ViewController, self.resizablePane2ViewController];
  self.resizableStackViewController = [ResizableStackViewController resizableStackViewControllerWithViewControllers:resizablePaneViewControllers
                                                                                                               axis:UILayoutConstraintAxisVertical];
  self.resizableStackViewController.sizes = resizableStackViewControllerInitialSizes;
  NSNumber* uiAreaPlayResizablePaneMinimumSizeAsNumber = [NSNumber numberWithDouble:uiAreaPlayResizablePaneMinimumSize];
  self.resizableStackViewController.minimumSizes = @[uiAreaPlayResizablePaneMinimumSizeAsNumber, uiAreaPlayResizablePaneMinimumSizeAsNumber];

  self.boardViewController = [[[BoardViewController alloc] init] autorelease];
  self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
  self.annotationViewController = [AnnotationViewController annotationViewController];

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
    [self.resizablePane2ViewController addChildViewController:boardPositionCollectionViewController];
    [boardPositionCollectionViewController didMoveToParentViewController:self.resizablePane2ViewController];
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

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  // Static setup
  [self setupViewHierarchy];
  [self configureViews];
  [self setupAutoLayoutConstraints];

  // Dynamic setup
  [self setupContentInResizablePane2:self.currentResizablePane2Content isInitialSetup:true];
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

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self setupWoodenBackgroundView];
  [self setupResizablePane1ViewHierarchy];
  [self setupResizablePane2ViewHierarchy];
  [self setupSwitchContentInResizablePane2Button];
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

  self.boardPositionButtonBoxAndAnnotationContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.boardPositionButtonBoxContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

  [self.resizablePane1ViewController.view addSubview:self.boardContainerView];
  [self.resizablePane1ViewController.view addSubview:self.boardPositionButtonBoxAndAnnotationContainerView];

  [self.boardContainerView addSubview:self.boardViewController.view];

  [self.boardPositionButtonBoxAndAnnotationContainerView addSubview:self.boardPositionButtonBoxContainerView];
  [self.boardPositionButtonBoxAndAnnotationContainerView addSubview:self.annotationViewController.view];

  [self.boardPositionButtonBoxContainerView addSubview:self.boardPositionButtonBoxController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchy.
// -----------------------------------------------------------------------------
- (void) setupResizablePane2ViewHierarchy
{
  [self.resizablePane2ViewController.view addSubview:self.boardPositionCollectionViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchy.
// -----------------------------------------------------------------------------
- (void) setupSwitchContentInResizablePane2Button
{
  self.switchContentInResizablePane2Button = [UIButton buttonWithType:UIButtonTypeSystem];

  // Add button to a superview where it is completely inside the superview
  // bounds => only then does the full button area react to touch events
  [self.woodenBackgroundView addSubview:self.switchContentInResizablePane2Button];
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
  self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

  self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

  [self updateColors];
  self.boardPositionCollectionViewController.view.layer.borderWidth = self.boardPositionCollectionViewBorderWidth;

  [self.boardPositionButtonBoxController reloadData];

  [self.switchContentInResizablePane2Button addTarget:self
                                               action:@selector(switchContentInResizablePane2:)
                                     forControlEvents:UIControlEventTouchUpInside];
}


// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  CGSize buttonBoxSize = self.boardPositionButtonBoxController.buttonBoxSize;
  // The annotation view should be high enough to display most description
  // texts without scrolling. It can't be arbitrarily high because it must
  // leave enough space for the board view. It can't be arbitrarily small
  // because it must have sufficient space to display two vertically stacked
  // buttons.
  int annotationViewHeight = buttonBoxSize.height * 1.1;

  [self setupAutoLayoutConstraintsMainView];
  [self setupAutoLayoutConstraintsWoodenBackgroundView];
  [self setupAutoLayoutConstraintsResizablePane1];
  [self setupAutoLayoutConstraintsBoardPositionButtonBoxAndAnnotationContainerView:annotationViewHeight];
  [self setupAutoLayoutConstraintsBoardPositionButtonBoxContainerView:buttonBoxSize];
  [self setupAutoLayoutConstraintsBoardContainerView];
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
  self.resizableStackViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  viewsDictionary[@"resizableStackViewController"] = self.resizableStackViewController.view;

  NSMutableArray* visualFormats = [NSMutableArray array];
  [visualFormats addObject:@"H:|-[resizableStackViewController]-|"];
  [visualFormats addObject:@"V:|-[resizableStackViewController]-|"];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.resizableStackViewController.view.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsResizablePane1
{
  // boardContainerView height:
  // - When the board position collection view is visible, boardContainerView
  //   gets the remaining height due to the fixed height of the collection view
  // - When the node tree view is visible, the user can interactively resize and
  //   boardContainerView shares the height with the node tree view

  self.boardContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionButtonBoxAndAnnotationContainerView.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  viewsDictionary[@"boardContainerView"] = self.boardContainerView;
  viewsDictionary[@"boardPositionButtonBoxAndAnnotationContainerView"] = self.boardPositionButtonBoxAndAnnotationContainerView;

  NSMutableArray* visualFormats = [NSMutableArray array];
  [visualFormats addObject:@"H:|-0-[boardContainerView]-0-|"];
  [visualFormats addObject:@"H:|-[boardPositionButtonBoxAndAnnotationContainerView]-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-[boardContainerView]-[boardPositionButtonBoxAndAnnotationContainerView]-%d-|", spacingBetweenResizablePanes]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.boardContainerView.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsBoardPositionButtonBoxAndAnnotationContainerView:(int)annotationViewHeight
{
  // The annotation view height defines the height of the entire
  // boardPositionButtonBoxAndAnnotationContainerView. The button box width is
  // defined elsewhere, the annotation view gets the remaining width.

  self.boardPositionButtonBoxContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.annotationViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  viewsDictionary[@"boardPositionButtonBoxContainerView"] = self.boardPositionButtonBoxContainerView;
  viewsDictionary[@"annotationView"] = self.annotationViewController.view;

  NSMutableArray* visualFormats = [NSMutableArray array];
  [visualFormats addObject:@"H:|-0-[boardPositionButtonBoxContainerView]-[annotationView]-0-|"];
  [visualFormats addObject:@"V:|-0-[boardPositionButtonBoxContainerView]-0-|"];
  [visualFormats addObject:@"V:|-0-[annotationView]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[annotationView(==%d)]", annotationViewHeight]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.boardPositionButtonBoxContainerView.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsBoardPositionButtonBoxContainerView:(CGSize)buttonBoxSize
{
  // Here we define the button box width. Also, the button box is expected to be
  // less high than its container view (whose height is defined by the
  // annotation view), so we give the button box a fixed height and position it
  // vertically centered within its container view.

  self.boardPositionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  viewsDictionary[@"boardPositionButtonBox"] = self.boardPositionButtonBoxController.view;

  NSMutableArray* visualFormats = [NSMutableArray array];
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
/// @brief Private helper for setupAutoLayoutConstraints.
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

#pragma mark - Switching contents in resizable pane 2

// -----------------------------------------------------------------------------
/// @brief Initiates switching content in the resizable pane 2.
// -----------------------------------------------------------------------------
- (void) switchContentInResizablePane2:(id)sender
{
  if (self.currentResizablePane2Content == ResizablePane2ContentBoardPositionCollectionView)
    self.currentResizablePane2Content = ResizablePane2ContentNodeTreeView;
  else
    self.currentResizablePane2Content = ResizablePane2ContentBoardPositionCollectionView;

  [self setupContentInResizablePane2:self.currentResizablePane2Content
                      isInitialSetup:false];
}

// -----------------------------------------------------------------------------
/// @brief Handles setting up content in the resizable pane 2 to the new content
/// of type @a resizablePane2Content. @a isInitialSetup is @e true if the setup
/// is invoked as part of the initial view hierarchy setup. @a isInitialSetup
/// is @e false if the setup is invoked as part of a switch operation.
///
/// Resizable pane 2 alternatively shows one of the the following contents:
/// - Either the board position collection view,
/// - Or the node tree view
///
/// Content setup consists of the following operations:
/// - Only when switching, i.e. @e isInitialSetup is @e false
///   - Removing Auto Layout constraints for the current content view
///   - Removing the current content view from the view hierarchy
///   - Deallocating the current content view controller
/// - Setting resizableStackViewController.resizingEnabled to the correct value
///   for the new content
/// - Allocating the new content view controller
/// - Adding the new content view to the view hierarchy
/// - Adding Auto Layout constraints for the new content view
/// - Configuring the button that initiates a switch with the appropriate icon
// -----------------------------------------------------------------------------
- (void) setupContentInResizablePane2:(enum ResizablePane2Content)resizablePane2Content
                       isInitialSetup:(bool)isInitialSetup
{
  if (resizablePane2Content == ResizablePane2ContentBoardPositionCollectionView)
  {
    if (! isInitialSetup)
    {
      for (NSLayoutConstraint* constraint in self.resizablePane2ContentAutoLayoutConstraints)
        constraint.active = NO;
      [self.resizablePane2ContentAutoLayoutConstraints removeAllObjects];
      [self.nodeTreeViewController.view removeFromSuperview];
      self.nodeTreeViewController = nil;
    }

    self.resizableStackViewController.resizingEnabled = false;

    self.boardPositionCollectionViewController = [[[BoardPositionCollectionViewController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
    UIView* boardPositionCollectionView = self.boardPositionCollectionViewController.view;

    [self.resizablePane2ViewController.view addSubview:boardPositionCollectionView];
    [self setupAutoLayoutConstraintsForContentInResizablePane2:boardPositionCollectionView
                                         resizablePane2Content:ResizablePane2ContentBoardPositionCollectionView];

    [self.switchContentInResizablePane2Button setImage:[UIImage imageNamed:nodeSequenceIconResource]
                                              forState:UIControlStateNormal];
  }
  else
  {
    if (! isInitialSetup)
    {
      for (NSLayoutConstraint* constraint in self.resizablePane2ContentAutoLayoutConstraints)
        constraint.active = NO;
      [self.resizablePane2ContentAutoLayoutConstraints removeAllObjects];
      [self.boardPositionCollectionViewController.view removeFromSuperview];
      self.boardPositionCollectionViewController = nil;
    }

    self.resizableStackViewController.resizingEnabled = true;

    self.nodeTreeViewController = [[[NodeTreeViewController alloc] init] autorelease];
    UIView* nodeTreeView = self.nodeTreeViewController.view;
    // TODO xxx Remove this when the node tree view properly draws its content
    nodeTreeView.backgroundColor = [UIColor lightGrayColor];

    [self.resizablePane2ViewController.view addSubview:nodeTreeView];
    [self setupAutoLayoutConstraintsForContentInResizablePane2:nodeTreeView
                                         resizablePane2Content:ResizablePane2ContentNodeTreeView];

    [self.switchContentInResizablePane2Button setImage:[UIImage imageNamed:nodeTreeSmallIconResource]
                                              forState:UIControlStateNormal];
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and activates Auto Layout constraints for the content view
/// @a contentView which is currently displayed in the resizable pane 2. The
/// value of @a resizablePane2Content indicates what kind of content is
/// displayed by @a contentView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsForContentInResizablePane2:(UIView*)contentView
                                        resizablePane2Content:(enum ResizablePane2Content)resizablePane2Content
{
  [self.resizablePane2ContentAutoLayoutConstraints removeAllObjects];

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  contentView.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"contentView"] = contentView;
  // Horizontal margin is important to provide the space for the switch button
  [visualFormats addObject:@"H:|-[contentView]-|"];
  // Top vertical margin is important to provide half the space for the drag
  // handle (the other half is provided by the bottom vertical margin of the
  // resizable pane 1).
  // Vertical margin at the bottom can be zero because the main resizable view
  // is already providing a margin.
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-%d-[contentView]-0-|", spacingBetweenResizablePanes]];

  if (resizablePane2Content == ResizablePane2ContentBoardPositionCollectionView)
  {
    CGFloat boardPositionCollectionViewHeight = [self.boardPositionCollectionViewController boardPositionCollectionViewMaximumCellSize].height;
    boardPositionCollectionViewHeight += 2 * self.boardPositionCollectionViewBorderWidth;
    [visualFormats addObject:[NSString stringWithFormat:@"V:[contentView(==%f)]", boardPositionCollectionViewHeight]];
  }

  NSArray* visualFormatsConstraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:contentView.superview];
  [self.resizablePane2ContentAutoLayoutConstraints addObjectsFromArray:visualFormatsConstraints];

  self.switchContentInResizablePane2Button.translatesAutoresizingMaskIntoConstraints = NO;
  NSLayoutConstraint* constraint;
  constraint = [NSLayoutConstraint constraintWithItem:self.switchContentInResizablePane2Button
                                            attribute:NSLayoutAttributeLeft
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:contentView
                                            attribute:NSLayoutAttributeRight
                                           multiplier:1.0f
                                             constant:2.0f];
  constraint.active = YES;
  [self.resizablePane2ContentAutoLayoutConstraints addObject:constraint];
  constraint = [NSLayoutConstraint constraintWithItem:self.switchContentInResizablePane2Button
                                            attribute:NSLayoutAttributeBottom
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:contentView
                                            attribute:NSLayoutAttributeBottom
                                           multiplier:1.0f
                                             constant:0.0f];
  constraint.active = YES;
  [self.resizablePane2ContentAutoLayoutConstraints addObject:constraint];
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
  [UiUtilities applyTintColorToButton:self.switchContentInResizablePane2Button traitCollection:traitCollection];
}

@end
