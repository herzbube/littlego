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
#import "PlayRootViewControllerPhonePortraitOnly.h"
#import "../boardposition/BoardPositionButtonBoxDataSource.h"
#import "../boardposition/BoardPositionCollectionViewCell.h"
#import "../boardposition/BoardPositionCollectionViewController.h"
#import "../boardview/BoardViewController.h"
#import "../controller/AutoLayoutConstraintHelper.h"
#import "../controller/StatusViewController.h"
#import "../model/NavigationBarButtonModel.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayRootViewControllerPhonePortraitOnly.
// -----------------------------------------------------------------------------
@interface PlayRootViewControllerPhonePortraitOnly()
@property(nonatomic, retain) NavigationBarButtonModel* navigationBarButtonModel;
@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) BoardPositionCollectionViewController* boardPositionCollectionViewController;
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) UIView* boardContainerView;
@property(nonatomic, retain) NSMutableArray* boardViewAutoLayoutConstraints;
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
  self.boardViewController = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.boardPositionCollectionViewController = nil;
  self.woodenBackgroundView = nil;
  self.boardContainerView = nil;
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

  self.boardViewController = [[[BoardViewController alloc] init] autorelease];

  self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];
  self.boardPositionCollectionViewController = [[[BoardPositionCollectionViewController alloc] initWithScrollDirection:UICollectionViewScrollDirectionHorizontal] autorelease];

  self.boardPositionButtonBoxDataSource = [[[BoardPositionButtonBoxDataSource alloc] init] autorelease];
  self.boardPositionButtonBoxController.buttonBoxControllerDataSource = self.boardPositionButtonBoxDataSource;
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
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  // This view provides a wooden texture background not only for the Go board,
  // but for the entire area in which the Go board resides
  self.woodenBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

  // This is a simple container view that takes up all the unused vertical
  // space and within which the board view is then vertically centered.
  self.boardContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

  [self.view addSubview:self.woodenBackgroundView];
  [self.view addSubview:self.boardPositionCollectionViewController.view];

  [self.woodenBackgroundView addSubview:self.boardContainerView];
  [self.woodenBackgroundView addSubview:self.boardPositionButtonBoxController.view];

  [self.boardContainerView addSubview:self.boardViewController.view];

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

  [self.boardPositionButtonBoxController applyTransparentStyle];

  [self.boardPositionButtonBoxController reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
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
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  // Align views with the top/bottom of the safe area - this prevents them from
  // extending behind the navigation bar at the top or the tab bar at the bottom
  [AutoLayoutUtility alignFirstView:self.woodenBackgroundView
                     withSecondView:self.view
        onSafeAreaLayoutGuideAnchor:NSLayoutAttributeTop];
  [AutoLayoutUtility alignFirstView:self.boardPositionCollectionViewController.view
                     withSecondView:self.view
        onSafeAreaLayoutGuideAnchor:NSLayoutAttributeBottom];

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
