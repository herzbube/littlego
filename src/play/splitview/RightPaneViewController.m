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
@property(nonatomic, retain) DiscardFutureMovesAlertController* discardFutureMovesAlertController;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) ButtonBoxController* gameActionButtonBoxController;
@property(nonatomic, retain) GameActionButtonBoxDataSource* gameActionButtonBoxDataSource;
@property(nonatomic, retain) NSArray* gameActionButtonBoxAutoLayoutConstraints;
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
  self.gameActionButtonBoxAutoLayoutConstraints = nil;
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
    self.boardPositionButtonBoxController = nil;
    self.boardPositionButtonBoxDataSource = nil;
    self.gameActionButtonBoxController = nil;
    self.gameActionButtonBoxDataSource = nil;
    self.gameActionButtonBoxAutoLayoutConstraints = nil;
  }
  self.mainMenuPresenter = nil;
  self.discardFutureMovesAlertController = nil;
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
  [self setupMainMenuButton];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.boardViewController.view];
  if (self.useNavigationBar)
  {
    [self.view addSubview:self.navigationBarController.view];
  }
  else
  {
    [self.view addSubview:self.boardPositionButtonBoxController.view];
    [self.view addSubview:self.gameActionButtonBoxController.view];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.automaticallyAdjustsScrollViewInsets = NO;

  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          self.boardViewController.view, @"boardView",
                                          nil];
  NSMutableArray* visualFormats = [NSMutableArray arrayWithObjects:
                                   @"H:|-0-[boardView]-0-|",
                                   nil];

  if (self.useNavigationBar)
  {
    self.navigationBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.navigationBarController.view forKey:@"navigationBarView"];
    [visualFormats addObject:@"H:|-0-[navigationBarView]-0-|"];
    // Don't need to specify height value for navigationBarView because
    // UINavigationBar specifies a height value in its intrinsic content size
    [visualFormats addObject:@"V:|-0-[navigationBarView]-0-[boardView]-0-|"];
  }
  else
  {
    self.boardPositionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.gameActionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewsDictionary setObject:self.boardPositionButtonBoxController.view forKey:@"boardPositionButtonBox"];
    [viewsDictionary setObject:self.gameActionButtonBoxController.view forKey:@"gameActionButtonBox"];
    [visualFormats addObject:@"V:|-0-[boardView]-0-|"];
    // TODO xxx proper placement
    [visualFormats addObject:[NSString stringWithFormat:@"H:|-15-[boardPositionButtonBox(==%f)]", self.boardPositionButtonBoxController.buttonBoxSize.width]];
    [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox(==%f)]-15-|", self.boardPositionButtonBoxController.buttonBoxSize.height]];
    [visualFormats addObject:@"H:[gameActionButtonBox]-15-|"];
    [visualFormats addObject:@"V:[gameActionButtonBox]-15-|"];
  }

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  if (! self.useNavigationBar)
    [self updateGameActionButtonBoxAutoLayoutConstraints];
}

// TODO xxx document
- (void) updateGameActionButtonBoxAutoLayoutConstraints
{
  if (self.gameActionButtonBoxAutoLayoutConstraints)
    [self.view removeConstraints:self.gameActionButtonBoxAutoLayoutConstraints];

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.gameActionButtonBoxController.view, @"gameActionButtonBox",
                                   nil];
  NSMutableArray* visualFormats = [NSMutableArray arrayWithObjects:
                                   [NSString stringWithFormat:@"H:[gameActionButtonBox(==%f)]", self.gameActionButtonBoxController.buttonBoxSize.width],
                                   [NSString stringWithFormat:@"V:[gameActionButtonBox(==%f)]", self.gameActionButtonBoxController.buttonBoxSize.height],
                                   nil];
  self.gameActionButtonBoxAutoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  // Set a color (should be the same as the main window's) because we need to
  // paint over the parent split view background color.
  self.view.backgroundColor = [UIColor whiteColor];

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
/// @brief Creates a button that when tapped causes a main menu to be be
/// presented that allows the user to navigate away from the Go board to other
/// main areas of the application.
// -----------------------------------------------------------------------------
- (void) setupMainMenuButton
{
  if (self.useNavigationBar)
    return;
  UIButton* mainMenuButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [mainMenuButton setImage:[UIImage imageNamed:mainMenuIconResource]
                  forState:UIControlStateNormal];
  [mainMenuButton addTarget:self
                     action:@selector(presentMainMenu:)
           forControlEvents:UIControlEventTouchUpInside];
  // TODO xxx same tint as button box
  mainMenuButton.tintColor = [UIColor blackColor];

  [self.view addSubview:mainMenuButton];
  mainMenuButton.translatesAutoresizingMaskIntoConstraints = NO;
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          mainMenuButton, @"mainMenuButton",
                                          nil];
  // TODO xxx same distances as button box
  NSMutableArray* visualFormats = [NSMutableArray arrayWithObjects:
                                   @"H:[mainMenuButton]-15-|",
                                   @"V:|-15-[mainMenuButton]",
                                   nil];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
}


// -----------------------------------------------------------------------------
/// @brief Handles a tap on the "main menu" button. Causes the main menu to be
/// presented.
// -----------------------------------------------------------------------------
- (void) presentMainMenu:(id)sender
{
  [self.mainMenuPresenter presentMainMenu];
}

@end
