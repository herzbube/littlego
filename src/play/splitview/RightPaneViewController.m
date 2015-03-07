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
  self.boardViewAutoLayoutConstraints = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for initializer.
// -----------------------------------------------------------------------------
- (void) setupUseNavigationBar
{
  switch ([LayoutManager sharedManager].uiType)
  {
    case UITypePhone:
    {
      bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
      self.useNavigationBar = isPortraitOrientation;
      break;
    }
    default:
    {
      self.useNavigationBar = true;
      break;
    }
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
    self.navigationBarController = [[[NavigationBarController alloc] init] autorelease];
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
  self.automaticallyAdjustsScrollViewInsets = NO;

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
    // TODO xxx proper placement
    [visualFormats addObject:@"H:|-15-[boardPositionButtonBox]"];
    [visualFormats addObject:@"V:[boardPositionButtonBox]-15-|"];
    [visualFormats addObject:[NSString stringWithFormat:@"H:[boardPositionButtonBox(==%f)]", self.boardPositionButtonBoxController.buttonBoxSize.width]];
    [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox(==%f)]", self.boardPositionButtonBoxController.buttonBoxSize.height]];
    [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.leftColumnView];

    [viewsDictionary removeAllObjects];
    [visualFormats removeAllObjects];
    self.mainMenuButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.gameActionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.mainMenuButton forKey:@"mainMenuButton"];
    [viewsDictionary setObject:self.gameActionButtonBoxController.view forKey:@"gameActionButtonBox"];
    // TODO xxx proper placement
    [visualFormats addObject:@"V:|-15-[mainMenuButton]"];
    [visualFormats addObject:@"H:[gameActionButtonBox]-15-|"];
    [visualFormats addObject:@"V:[gameActionButtonBox]-15-|"];
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

// TODO xxx document
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

// TODO xxx document
- (void) updateBoardViewAutoLayoutConstraints
{
  if (self.boardViewAutoLayoutConstraints)
    [self.woodenBackgroundView removeConstraints:self.boardViewAutoLayoutConstraints];

  NSMutableArray* boardViewAutoLayoutConstraints = [NSMutableArray array];
  
  CGSize superViewSize = self.woodenBackgroundView.bounds.size;
  CGFloat dimension = MIN(superViewSize.width, superViewSize.height);
  bool superviewHasPortraitOrientation = (superViewSize.height > superViewSize.width);

  // todo xxx remove if not needed
  CGSize destinationSize = CGSizeMake(dimension, dimension);
  NSLog(@"current size = %@, destination size = %@, bgview size = %@",
        NSStringFromCGSize(self.boardViewController.view.bounds.size),
        NSStringFromCGSize(destinationSize),
        NSStringFromCGSize(superViewSize));

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
                                                               withSecondView:self.woodenBackgroundView
                                                                  onAttribute:dimensionToConstrain
                                                             constraintHolder:self.woodenBackgroundView];
  [boardViewAutoLayoutConstraints addObject:dimensionConstraint];

  NSLayoutConstraint* alignConstraint = [AutoLayoutUtility alignFirstView:self.boardViewController.view
                                                           withSecondView:self.woodenBackgroundView
                                                              onAttribute:alignConstraintAxis
                                                         constraintHolder:self.woodenBackgroundView];
  [boardViewAutoLayoutConstraints addObject:alignConstraint];

  NSLayoutConstraint* centerConstraint = [AutoLayoutUtility centerSubview:self.boardViewController.view
                                                              inSuperview:self.woodenBackgroundView
                                                                   onAxis:centerConstraintAxis];
  [boardViewAutoLayoutConstraints addObject:centerConstraint];

  // Remember constraints so that we can remove them when a layout change occurs
  self.boardViewAutoLayoutConstraints = boardViewAutoLayoutConstraints;

  // BoardViewController relies on viewDidLayoutSubviews to update the content
  // size of its scroll view
  // todo xxx remove if not needed
//  [self.boardViewController.view setNeedsLayout];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  // Set a color (should be the same as the main window's) because we need to
  // paint over the parent split view background color.
  self.view.backgroundColor = [UIColor whiteColor];
  self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

  // TODO xxx proper colors
  //  self.boardPositionButtonBoxController.view.backgroundColor = [UIColor navigationbarBackgroundColor];
//  self.boardPositionButtonBoxController.view.backgroundColor = [UIColor whiteColor];
//  self.boardPositionButtonBoxController.view.layer.borderWidth = 1;
//  self.boardPositionButtonBoxController.view.alpha = 0.20f;
  self.boardPositionButtonBoxController.collectionView.backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.boardPositionButtonBoxController.collectionView.backgroundView.backgroundColor = [UIColor whiteColor];
  self.boardPositionButtonBoxController.collectionView.backgroundView.layer.borderWidth = 1;
  self.boardPositionButtonBoxController.collectionView.backgroundView.alpha = 0.6f;

//  self.gameActionButtonBoxController.view.backgroundColor = [UIColor navigationbarBackgroundColor];
//  self.gameActionButtonBoxController.view.backgroundColor = [UIColor whiteColor];
//  self.gameActionButtonBoxController.view.layer.borderWidth = 1;
//  self.gameActionButtonBoxController.view.alpha = 0.80f;
  self.gameActionButtonBoxController.collectionView.backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.gameActionButtonBoxController.collectionView.backgroundView.backgroundColor = [UIColor whiteColor];
  self.gameActionButtonBoxController.collectionView.backgroundView.layer.borderWidth = 1;
  self.gameActionButtonBoxController.collectionView.backgroundView.alpha = 0.6f;

  [self.mainMenuButton setImage:[UIImage imageNamed:mainMenuIconResource]
                       forState:UIControlStateNormal];
  [self.mainMenuButton addTarget:self
                          action:@selector(presentMainMenu:)
                forControlEvents:UIControlEventTouchUpInside];
  // TODO xxx same tint as button box
  self.mainMenuButton.tintColor = [UIColor blackColor];
}

#pragma mark - UIViewController overrides

/// xxx document
- (void) viewDidLayoutSubviews
{
  [self updateBoardViewAutoLayoutConstraints];
}

#pragma mark - ButtonBoxControllerDataDelegate overrides

// TODO xxx do we really need this? can't we install an auto layout constraint
// that has flexible height? problem is the border/background of the box that
// makes it obvious that the box gets too much height. the button box controller
// view would have to have an intrinsic height.
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
