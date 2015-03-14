// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "RightPaneViewController.h"
#import "../boardposition/BoardPositionButtonBoxDataSource.h"
#import "../boardposition/BoardPositionNavigationManager.h"
#import "../boardview/BoardViewController.h"
#import "../controller/DiscardFutureMovesAlertController.h"
#import "../controller/NavigationBarController.h"
#import "../controller/StatusViewController.h"
#import "../gameaction/GameActionButtonBoxDataSource.h"
#import "../gameaction/GameActionManager.h"
#import "../gesture/PanGestureController.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/ButtonBoxController.h"
#import "../../utility/UiColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for RightPaneViewController.
// -----------------------------------------------------------------------------
@interface RightPaneViewController()
@property(nonatomic, assign) bool useNavigationBar;
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) UIView* leftColumnView;
@property(nonatomic, retain) UIView* rightColumnView;
@property(nonatomic, retain) DiscardFutureMovesAlertController* discardFutureMovesAlertController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) ButtonBoxController* gameActionButtonBoxController;
@property(nonatomic, retain) GameActionButtonBoxDataSource* gameActionButtonBoxDataSource;
@property(nonatomic, retain) NSArray* boardViewAutoLayoutConstraints;
@property(nonatomic, retain) NSArray* gameActionButtonBoxAutoLayoutConstraints;
@property(nonatomic, retain) UIButton* mainMenuButton;
@end


@implementation RightPaneViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a RightPaneViewController object.
///
/// @note This is the designated initializer of RightPaneViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupUseNavigationBar];
  [self setupChildControllers];
  self.mainMenuPresenter = nil;
  self.woodenBackgroundView = nil;
  self.leftColumnView = nil;
  self.rightColumnView = nil;
  self.boardViewAutoLayoutConstraints = nil;
  self.gameActionButtonBoxAutoLayoutConstraints = nil;
  self.mainMenuButton = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this RightPaneViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (self.useNavigationBar)
  {
    self.navigationBarController = nil;
  }
  else
  {
    self.leftColumnView = nil;
    self.rightColumnView = nil;
    self.boardPositionButtonBoxController = nil;
    self.boardPositionButtonBoxDataSource = nil;
    self.gameActionButtonBoxController = nil;
    self.gameActionButtonBoxDataSource = nil;
    self.gameActionButtonBoxAutoLayoutConstraints = nil;
    self.mainMenuButton = nil;
  }
  self.mainMenuPresenter = nil;
  self.woodenBackgroundView = nil;
  self.discardFutureMovesAlertController = nil;
  self.boardViewController = nil;
  self.boardViewAutoLayoutConstraints = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for initializer.
// -----------------------------------------------------------------------------
- (void) setupUseNavigationBar
{
  if ([LayoutManager sharedManager].uiType == UITypePhone)
  {
    bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    self.useNavigationBar = isPortraitOrientation;
  }
  else
  {
    self.useNavigationBar = true;
  }
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  if (self.useNavigationBar)
  {
    self.navigationBarController = [NavigationBarController navigationBarController];
  }
  else
  {
    self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] init] autorelease];
    self.gameActionButtonBoxController = [[[ButtonBoxController alloc] init] autorelease];
  }
  self.discardFutureMovesAlertController = [[[DiscardFutureMovesAlertController alloc] init] autorelease];
  self.boardViewController = [[[BoardViewController alloc] init] autorelease];

  self.boardViewController.panGestureController.delegate = self.discardFutureMovesAlertController;
  if (! self.useNavigationBar)
  {
    self.boardPositionButtonBoxDataSource = [[[BoardPositionButtonBoxDataSource alloc] init] autorelease];
    self.boardPositionButtonBoxController.buttonBoxControllerDataSource = self.boardPositionButtonBoxDataSource;
    self.gameActionButtonBoxDataSource = [[[GameActionButtonBoxDataSource alloc] init] autorelease];
    self.gameActionButtonBoxDataSource.buttonBoxController = self.gameActionButtonBoxController;
    self.gameActionButtonBoxController.buttonBoxControllerDataSource = self.gameActionButtonBoxDataSource;
    self.gameActionButtonBoxController.buttonBoxControllerDelegate = self;
  }
  [GameActionManager sharedGameActionManager].commandDelegate = self.discardFutureMovesAlertController;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setNavigationBarController:(NavigationBarController*)navigationBarController
{
  if (_navigationBarController == navigationBarController)
    return;
  if (_navigationBarController)
  {
    [_navigationBarController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_navigationBarController removeFromParentViewController];
    [_navigationBarController release];
    _navigationBarController = nil;
  }
  if (navigationBarController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:navigationBarController];
    [navigationBarController didMoveToParentViewController:self];
    [navigationBarController retain];
    _navigationBarController = navigationBarController;
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
- (void) setGameActionButtonBoxController:(ButtonBoxController*)gameActionButtonBoxController
{
  if (_gameActionButtonBoxController == gameActionButtonBoxController)
    return;
  if (_gameActionButtonBoxController)
  {
    [_gameActionButtonBoxController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_gameActionButtonBoxController removeFromParentViewController];
    [_gameActionButtonBoxController release];
    _gameActionButtonBoxController = nil;
  }
  if (gameActionButtonBoxController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:gameActionButtonBoxController];
    [gameActionButtonBoxController didMoveToParentViewController:self];
    [gameActionButtonBoxController retain];
    _gameActionButtonBoxController = gameActionButtonBoxController;
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
  [self setupAutoLayoutConstraints];
  [self configureViews];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This override exists to update Auto Layout constraints when the interface
/// orientation rotates.
// -----------------------------------------------------------------------------
- (void) viewDidLayoutSubviews
{
  [self updateBoardViewAutoLayoutConstraints];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.woodenBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.woodenBackgroundView];
  [self.woodenBackgroundView addSubview:self.boardViewController.view];
  if (self.useNavigationBar)
  {
    [self.view addSubview:self.navigationBarController.view];
  }
  else
  {
    self.leftColumnView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    [self.woodenBackgroundView addSubview:self.leftColumnView];
    [self.leftColumnView addSubview:self.boardPositionButtonBoxController.view];

    self.rightColumnView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    [self.woodenBackgroundView addSubview:self.rightColumnView];
    [self.rightColumnView addSubview:self.gameActionButtonBoxController.view];

    self.mainMenuButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.rightColumnView addSubview:self.mainMenuButton];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  // The board view should be square. This is only the aspect ratio, we still
  // need the actual dimension.
  [AutoLayoutUtility makeSquare:self.boardViewController.view constraintHolder:self.woodenBackgroundView];
  // We determine the dimension of the square dynamically by looking at the size
  // of the superview
  [self updateBoardViewAutoLayoutConstraints];

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];
  if (self.useNavigationBar)
  {
    self.navigationBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.navigationBarController.view forKey:@"navigationBarView"];
    [viewsDictionary setObject:self.woodenBackgroundView forKey:@"woodenBackgroundView"];
    [visualFormats addObject:@"H:|-0-[navigationBarView]-0-|"];
    [visualFormats addObject:@"H:|-0-[woodenBackgroundView]-0-|"];
    // Don't need to specify height value for navigationBarView because
    // UINavigationBar specifies a height value in its intrinsic content size
    [visualFormats addObject:@"V:|-0-[navigationBarView]-0-[woodenBackgroundView]-0-|"];
    [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
  }
  else
  {
    int horizontalSpacingButtonBox = [AutoLayoutUtility horizontalSpacingSiblings];
    int verticalSpacingButtonBox = [AutoLayoutUtility verticalSpacingSiblings];

    self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [AutoLayoutUtility fillSuperview:self.view withSubview:self.woodenBackgroundView];

    // The board view is square and horizontally centered, which means that
    // there is a dynamic amount of width left. We need left/right columns that
    // can horizontally expand and take up that width. The button boxes have
    // fixed width, so we need to wrap them in superviews that can expand.
    self.leftColumnView.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightColumnView.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.leftColumnView forKey:@"leftColumnView"];
    [viewsDictionary setObject:self.boardViewController.view forKey:@"boardView"];
    [viewsDictionary setObject:self.rightColumnView forKey:@"rightColumnView"];
    // The board view is anchored at the horizontal center and has a defined
    // width. By aligning the column edges with the board view edges and by NOT
    // specifying any column widths we guarantee that the column views will
    // horizontally expand.
    [visualFormats addObject:@"H:|-0-[leftColumnView]-0-[boardView]-0-[rightColumnView]-0-|"];
    [visualFormats addObject:@"V:|-0-[leftColumnView]-0-|"];
    [visualFormats addObject:@"V:|-0-[rightColumnView]-0-|"];
    [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.woodenBackgroundView];

    [viewsDictionary removeAllObjects];
    [visualFormats removeAllObjects];
    self.boardPositionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.boardPositionButtonBoxController.view forKey:@"boardPositionButtonBox"];
    [visualFormats addObject:[NSString stringWithFormat:@"H:|-%d-[boardPositionButtonBox]", horizontalSpacingButtonBox]];
    [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox]-%d-|", verticalSpacingButtonBox]];
    [visualFormats addObject:[NSString stringWithFormat:@"H:[boardPositionButtonBox(==%f)]", self.boardPositionButtonBoxController.buttonBoxSize.width]];
    [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox(==%f)]", self.boardPositionButtonBoxController.buttonBoxSize.height]];
    [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.leftColumnView];

    [viewsDictionary removeAllObjects];
    [visualFormats removeAllObjects];
    self.mainMenuButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.gameActionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.mainMenuButton forKey:@"mainMenuButton"];
    [viewsDictionary setObject:self.gameActionButtonBoxController.view forKey:@"gameActionButtonBox"];
    [visualFormats addObject:[NSString stringWithFormat:@"V:|-%d-[mainMenuButton]", verticalSpacingButtonBox]];
    [visualFormats addObject:[NSString stringWithFormat:@"H:[gameActionButtonBox]-%d-|", horizontalSpacingButtonBox]];
    [visualFormats addObject:[NSString stringWithFormat:@"V:[gameActionButtonBox]-%d-|", verticalSpacingButtonBox]];
    [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.rightColumnView];
    // The main menu button is not in a box, so has not the same width as the
    // game action button box. To make it look good we horizontally center it on
    // the game action button box.
    [AutoLayoutUtility alignFirstView:self.mainMenuButton
                       withSecondView:self.gameActionButtonBoxController.view
                          onAttribute:NSLayoutAttributeCenterX
                     constraintHolder:self.rightColumnView];

    // Size (specifically height) of gameActionButtonBox is variable,
    // constraints are managed dynamically
    [self updateGameActionButtonBoxAutoLayoutConstraints];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  // Set a color (should be the same as the main window's) because we need to
  // paint over the parent split view background color.
  self.view.backgroundColor = [UIColor whiteColor];

  // This view provides a wooden texture background not only for the Go board,
  // but for the entire area in which the Go board resides
  self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

  [self configureButtonBoxController:self.boardPositionButtonBoxController];
  [self configureButtonBoxController:self.gameActionButtonBoxController];


  [self.mainMenuButton setImage:[UIImage imageNamed:mainMenuIconResource]
                       forState:UIControlStateNormal];
  [self.mainMenuButton addTarget:self
                          action:@selector(presentMainMenu:)
                forControlEvents:UIControlEventTouchUpInside];
  // Same tint as button box
  self.mainMenuButton.tintColor = [UIColor blackColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for configureViews.
// -----------------------------------------------------------------------------
- (void) configureButtonBoxController:(ButtonBoxController*)buttonBoxController
{
  buttonBoxController.collectionView.backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  buttonBoxController.collectionView.backgroundView.backgroundColor = [UIColor whiteColor];
  buttonBoxController.collectionView.backgroundView.layer.borderWidth = 1;
  buttonBoxController.collectionView.backgroundView.alpha = 0.6f;
}

#pragma mark - Dynamic Auto Layout constraint handling

// -----------------------------------------------------------------------------
/// @brief Updates Auto Layout constraints that manage the size of the
/// Game Action button box. The new constraints use the current size values
/// provided by the button box controller.
// -----------------------------------------------------------------------------
- (void) updateGameActionButtonBoxAutoLayoutConstraints
{
  if (self.gameActionButtonBoxAutoLayoutConstraints)
    [self.rightColumnView removeConstraints:self.gameActionButtonBoxAutoLayoutConstraints];

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.gameActionButtonBoxController.view, @"gameActionButtonBox",
                                   nil];
  NSMutableArray* visualFormats = [NSMutableArray arrayWithObjects:
                                   [NSString stringWithFormat:@"H:[gameActionButtonBox(==%f)]", self.gameActionButtonBoxController.buttonBoxSize.width],
                                   [NSString stringWithFormat:@"V:[gameActionButtonBox(==%f)]", self.gameActionButtonBoxController.buttonBoxSize.height],
                                   nil];
  self.gameActionButtonBoxAutoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                                                withViews:viewsDictionary
                                                                                   inView:self.rightColumnView];
}

// -----------------------------------------------------------------------------
/// @brief Updates Auto Layout constraints that manage the size and placement of
/// the board view. The new constraints use the current size values
/// provided by the button box controller.
// -----------------------------------------------------------------------------
- (void) updateBoardViewAutoLayoutConstraints
{
  if (self.boardViewAutoLayoutConstraints)
    [self.woodenBackgroundView removeConstraints:self.boardViewAutoLayoutConstraints];

  NSMutableArray* boardViewAutoLayoutConstraints = [NSMutableArray array];

  UIView* superviewOfBoardView = self.woodenBackgroundView;
  CGSize superviewSize = superviewOfBoardView.bounds.size;
  bool superviewHasPortraitOrientation = (superviewSize.height > superviewSize.width);

  // Choose whichever is the superview's smaller dimension. We know that the
  // board view is constrained to be square, so we need to constrain only one
  // dimension to define the view size.
  NSLayoutAttribute dimensionToConstrain;
  // We also need to place the board view. The first part is to align it to one
  // of the superview edges from which it can freely flow to take up the entire
  // extent of the superview.
  NSLayoutAttribute alignConstraintAxis;
  // The second part of placing the board view is to center it on the axis on
  // which it won't take up the entire extent of the superview. This evenly
  // distributes the remaining space not taken up by the board view. Other
  // content can then be placed into that space.
  UILayoutConstraintAxis centerConstraintAxis;
  if (superviewHasPortraitOrientation)
  {
    dimensionToConstrain = NSLayoutAttributeWidth;
    alignConstraintAxis = NSLayoutAttributeLeft;
    centerConstraintAxis = UILayoutConstraintAxisVertical;
  }
  else
  {
    dimensionToConstrain = NSLayoutAttributeHeight;
    alignConstraintAxis = NSLayoutAttributeTop;
    centerConstraintAxis = UILayoutConstraintAxisHorizontal;
  }

  NSLayoutConstraint* dimensionConstraint = [AutoLayoutUtility alignFirstView:self.boardViewController.view
                                                               withSecondView:superviewOfBoardView
                                                                  onAttribute:dimensionToConstrain
                                                             constraintHolder:superviewOfBoardView];
  [boardViewAutoLayoutConstraints addObject:dimensionConstraint];

  NSLayoutConstraint* alignConstraint = [AutoLayoutUtility alignFirstView:self.boardViewController.view
                                                           withSecondView:superviewOfBoardView
                                                              onAttribute:alignConstraintAxis
                                                         constraintHolder:superviewOfBoardView];
  [boardViewAutoLayoutConstraints addObject:alignConstraint];

  NSLayoutConstraint* centerConstraint = [AutoLayoutUtility centerSubview:self.boardViewController.view
                                                              inSuperview:superviewOfBoardView
                                                                   onAxis:centerConstraintAxis];
  [boardViewAutoLayoutConstraints addObject:centerConstraint];

  self.boardViewAutoLayoutConstraints = boardViewAutoLayoutConstraints;
}

// -----------------------------------------------------------------------------
/// @brief Removes all dynamically managed Auto Layout constraints.
///
/// TODO This should be removed, it is a HACK! See documentation at call site
/// for more information.
// -----------------------------------------------------------------------------
- (void) removeDynamicConstraints
{
  [self.woodenBackgroundView removeConstraints:self.boardViewAutoLayoutConstraints];
  self.boardViewAutoLayoutConstraints = nil;
  [self.rightColumnView removeConstraints:self.gameActionButtonBoxAutoLayoutConstraints];
  self.gameActionButtonBoxAutoLayoutConstraints = nil;
}

#pragma mark - ButtonBoxControllerDataDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) buttonBoxButtonsWillChange
{
  [self updateGameActionButtonBoxAutoLayoutConstraints];
}

#pragma mark - Main menu handling

// -----------------------------------------------------------------------------
/// @brief Handles a tap on the "main menu" button. Causes the main menu to be
/// presented.
// -----------------------------------------------------------------------------
- (void) presentMainMenu:(id)sender
{
  [self.mainMenuPresenter presentMainMenu];
}

@end
