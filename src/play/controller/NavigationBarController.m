// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "NavigationBarController.h"
#import "StatusViewController.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NavigationBarController.
// -----------------------------------------------------------------------------
@interface NavigationBarController()
@property(nonatomic, assign) bool variableNavigationbarWidths;
@property(nonatomic, retain) NSDictionary* gameActionButtons;
@property(nonatomic, retain) NSArray* buttonOrderList;
@property(nonatomic, retain) NSArray* visibleGameActions;
@property(nonatomic, retain) UINavigationBar* leftNavigationBar;
@property(nonatomic, retain) UINavigationBar* centerNavigationBar;
@property(nonatomic, retain) UINavigationBar* rightNavigationBar;
@property(nonatomic, retain) NSLayoutConstraint* leftNavigationBarWidthConstraint;
@property(nonatomic, retain) NSLayoutConstraint* rightNavigationBarWidthConstraint;
@property(nonatomic, assign) UIBarButtonItem* barButtonItemForShowingTheHiddenViewController;
@end


@implementation NavigationBarController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NavigationBarController object.
///
/// @note This is the designated initializer of NavigationBarController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  if ([LayoutManager sharedManager].uiType != UITypePad)
    self.variableNavigationbarWidths = true;
  else
      self.variableNavigationbarWidths = false;
  self.gameActionButtons = [NavigationBarController gameActionButtons];
  self.buttonOrderList = [NavigationBarController buttonOrderList];
  self.visibleGameActions = [NSArray array];
  [self releaseObjects];
  [self setupChildControllers];
  [GameActionManager sharedGameActionManager].uiDelegate = self;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NavigationBarController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseObjects];
  self.statusViewController = nil;
  self.gameActionButtons = nil;
  self.buttonOrderList = nil;
  self.visibleGameActions = nil;
  if ([GameActionManager sharedGameActionManager].uiDelegate == self)
    [GameActionManager sharedGameActionManager].uiDelegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.leftNavigationBar = nil;
  self.centerNavigationBar = nil;
  self.rightNavigationBar = nil;
  self.leftNavigationBarWidthConstraint = nil;
  self.rightNavigationBarWidthConstraint = nil;
  self.barButtonItemForShowingTheHiddenViewController = nil;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.statusViewController = [[[StatusViewController alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setStatusViewController:(StatusViewController*)statusViewController
{
  if (_statusViewController == statusViewController)
    return;
  if (_statusViewController)
  {
    [_statusViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_statusViewController removeFromParentViewController];
    [_statusViewController release];
    _statusViewController = nil;
  }
  if (statusViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:statusViewController];
    [statusViewController didMoveToParentViewController:self];
    [statusViewController retain];
    _statusViewController = statusViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [self createViews];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self setupGameActions];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createViews
{
  [super loadView];
  self.leftNavigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectZero] autorelease];
  self.centerNavigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectZero] autorelease];
  self.rightNavigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectZero] autorelease];
  [self.leftNavigationBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:@""] autorelease]
                                    animated:NO];
  [self.centerNavigationBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:@""] autorelease]
                                      animated:NO];
  [self.rightNavigationBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:@""] autorelease]
                                     animated:NO];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.leftNavigationBar];
  [self.view addSubview:self.centerNavigationBar];
  [self.view addSubview:self.rightNavigationBar];
  [self.view addSubview:self.statusViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.leftNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.centerNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.rightNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.statusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.leftNavigationBar, @"leftNavigationBar",
                                   self.centerNavigationBar, @"centerNavigationBar",
                                   self.rightNavigationBar, @"rightNavigationBar",
                                   self.statusViewController.view, @"statusView",
                                   nil];
  // Some notes:
  // - On the iPad we simply give each navigation bar the same width.
  // - On the iPhone there is not enough horizontal space to do the same, so
  //   further down we set up some width constraints, which will then be managed
  //   dynamically each time after the navigation bars are populated with
  //   buttons.
  // - Furthermore, we only need the center navigation bar to get the same
  //   translucent background for the status view, so we set up the status view
  //   to "hover" over the center navigation bar. In iOS 8 it would be possible
  //   achieve this simply by making the status view a subview of the center
  //   navigation bar and fill up the entirety of its superview. But in iOS 7
  //   the Auto Layout engine can't handle this for some reason. Since we still
  //   support iOS 7 we must therefore fall back to the solution of making the
  //   status view a subview of the main view and provide constraints that let
  //   the status view use the exact same position and size as the navigation
  //   bar over which it must "hover".
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            (self.variableNavigationbarWidths
                             ? @"H:|-0-[leftNavigationBar]-0-[centerNavigationBar]-0-[rightNavigationBar]-0-|"
                             : @"H:|-0-[leftNavigationBar]-0-[centerNavigationBar(==leftNavigationBar)]-0-[rightNavigationBar(==leftNavigationBar)]-0-|"),
                            @"H:[leftNavigationBar]-0-[statusView(==centerNavigationBar)]",
                            @"V:|-0-[leftNavigationBar]-0-|",
                            @"V:|-0-[centerNavigationBar]-0-|",
                            @"V:|-0-[rightNavigationBar]-0-|",
                            @"V:|-0-[statusView]-0-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];

  if (self.variableNavigationbarWidths)
  {
    self.leftNavigationBarWidthConstraint = [NSLayoutConstraint constraintWithItem:self.leftNavigationBar
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeWidth
                                                                        multiplier:0.0f
                                                                          constant:0.0f];
    [self.view addConstraint:self.leftNavigationBarWidthConstraint];
    self.rightNavigationBarWidthConstraint = [NSLayoutConstraint constraintWithItem:self.rightNavigationBar
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeWidth
                                                                         multiplier:0.0f
                                                                           constant:0.0f];
    [self.view addConstraint:self.rightNavigationBarWidthConstraint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupGameActions
{
  NSDictionary* visibleStates = [[GameActionManager sharedGameActionManager] visibleStatesOfGameActions];
  [self updateForVisibleGameActions:visibleStates];
  [self populateNavigationBars];
}

#pragma mark - SplitViewControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief SplitViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) splitViewController:(SplitViewController*)svc
      willHideViewController:(UIViewController*)aViewController
           withBarButtonItem:(UIBarButtonItem*)barButtonItem
{
  self.barButtonItemForShowingTheHiddenViewController = barButtonItem;
  barButtonItem.title = @"Moves";
  [self populateNavigationBars];
}

// -----------------------------------------------------------------------------
/// @brief SplitViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) splitViewController:(SplitViewController*)svc
      willShowViewController:(UIViewController*)aViewController
   invalidatingBarButtonItem:(UIBarButtonItem*)button
{
  self.barButtonItemForShowingTheHiddenViewController = nil;
  [self populateNavigationBars];
}

#pragma mark - Navigation bar population

// -----------------------------------------------------------------------------
/// @brief Populates the navigation bars with buttons that are appropriate for
/// the current application state.
// -----------------------------------------------------------------------------
- (void) populateNavigationBars
{
  [self populateLeftNavigationBar];
  [self populateRightNavigationBar];
  if (self.variableNavigationbarWidths)
    [self updateNavigationBarWidths];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBars().
// -----------------------------------------------------------------------------
- (void) populateLeftNavigationBar
{
  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  for (NSNumber* gameActionAsNumber in self.visibleGameActions)
  {
    UIBarButtonItem* button = self.gameActionButtons[gameActionAsNumber];
    [barButtonItems addObject:button];
  }
  self.leftNavigationBar.topItem.leftBarButtonItems = barButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBars().
// -----------------------------------------------------------------------------
- (void) populateRightNavigationBar
{
  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  [barButtonItems addObject:self.gameActionButtons[[NSNumber numberWithInt:GameActionMoreGameActions]]];
  [barButtonItems addObject:self.gameActionButtons[[NSNumber numberWithInt:GameActionGameInfo]]];
  if (self.barButtonItemForShowingTheHiddenViewController)
    [barButtonItems addObject:self.barButtonItemForShowingTheHiddenViewController];
  self.rightNavigationBar.topItem.rightBarButtonItems = barButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBars().
// -----------------------------------------------------------------------------
- (void) updateNavigationBarWidths
{
  // This method is only called on the iPhone. We know that on the iPhone we can
  // never have more than 5 buttons that are simultaneously shown. With 16% per
  // button the following calculations leave 100 - (5 * 16) = 20% width for the
  // status view. This has has been experimentally determined to be sufficient
  // for all texts that can appear in the 5-button scenario.
  CGFloat widthPercentagePerButton = 0.16f;
  CGFloat leftNavigationBarWidthPercentage = (self.leftNavigationBar.topItem.leftBarButtonItems.count
                                              * widthPercentagePerButton);
  CGFloat rightNavigationBarWidthPercentage = (self.rightNavigationBar.topItem.rightBarButtonItems.count
                                               * widthPercentagePerButton);

  NSMutableArray* constraintsToRemove = [NSMutableArray array];
  NSMutableArray* constraintsToAdd = [NSMutableArray array];
  if (self.leftNavigationBarWidthConstraint.multiplier != leftNavigationBarWidthPercentage)
  {
    [constraintsToRemove addObject:self.leftNavigationBarWidthConstraint];
    self.leftNavigationBarWidthConstraint = [NSLayoutConstraint constraintWithItem:self.leftNavigationBar
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeWidth
                                                                        multiplier:leftNavigationBarWidthPercentage
                                                                          constant:0.0f];
    [constraintsToAdd addObject:self.leftNavigationBarWidthConstraint];
  }
  if (self.rightNavigationBarWidthConstraint.multiplier != rightNavigationBarWidthPercentage)
  {
    [constraintsToRemove addObject:self.rightNavigationBarWidthConstraint];
    self.rightNavigationBarWidthConstraint = [NSLayoutConstraint constraintWithItem:self.rightNavigationBar
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeWidth
                                                                         multiplier:rightNavigationBarWidthPercentage
                                                                           constant:0.0f];
    [constraintsToAdd addObject:self.rightNavigationBarWidthConstraint];
  }
  [self.view removeConstraints:constraintsToRemove];
  [self.view addConstraints:constraintsToAdd];
}

#pragma mark - GameActionManagerUIDelegate overrides

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
       updateVisibleStates:(NSDictionary*)gameActions
{
  [self updateForVisibleGameActions:gameActions];
  [self populateNavigationBars];
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
                    enable:(BOOL)enable
                gameAction:(enum GameAction)gameAction
{
  NSNumber* gameActionAsNumber = [NSNumber numberWithInt:gameAction];
  UIBarButtonItem* button = self.gameActionButtons[gameActionAsNumber];
  button.enabled = enable;
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (UIView*) viewForPresentingMoreGameActionsByGameActionManager:(GameActionManager*)manager
{
  // We need the view that represents the "Game Actions" bar button item in the
  // navigation bar so that we can present an action sheet originating from that
  // view. There is no official API that lets us find the view, but we know that
  // the button is at the right-most end of the navigation bar, so we can find
  // the representing view by examining the frames of all navigation bar
  // subviews.
  UIView* rightMostSubview = nil;
  for (UIView* subview in self.rightNavigationBar.subviews)
  {
    if (rightMostSubview)
    {
      if (subview.frame.origin.x > rightMostSubview.frame.origin.x)
        rightMostSubview = subview;
    }
    else
    {
      rightMostSubview = subview;
    }
  }
  return rightMostSubview;
}

#pragma mark - Private helpers - UIBarButtonItem creation

// -----------------------------------------------------------------------------
/// @brief Returns a dictionary with one key/value pair for each value in the
/// GameAction enumeration. The key is an NSNumber encapsulating the value from
/// the GameAction enumeration, the value is a UIBarButtonItem object
/// corresponding to the GameAction value.
// -----------------------------------------------------------------------------
+ (NSDictionary*) gameActionButtons
{
  NSMutableDictionary* gameActionButtons = [NSMutableDictionary dictionary];
  for (enum GameAction gameAction = GameActionFirst; gameAction <= GameActionLast; ++gameAction)
  {
    UIBarButtonItem* button = [NavigationBarController buttonForGameAction:gameAction];
    NSNumber* gameActionAsNumber = [NSNumber numberWithInt:gameAction];
    gameActionButtons[gameActionAsNumber] = button;
  }
  return gameActionButtons;
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly instantiated UIBarButtonItem object that has its
/// properties set up to match the specified @a gameAction.
// -----------------------------------------------------------------------------
+ (UIBarButtonItem*) buttonForGameAction:(enum GameAction)gameAction
{
  NSString* imageResourceName;
  SEL selector;
  switch (gameAction)
  {
    case GameActionPass:
    {
      imageResourceName = passButtonIconResource;
      selector = @selector(pass:);
      break;
    }
    case GameActionDiscardBoardPosition:
    {
      imageResourceName = discardButtonIconResource;
      selector = @selector(discardBoardPosition:);
      break;
    }
    case GameActionComputerPlay:
    {
      imageResourceName = computerPlayButtonIconResource;
      selector = @selector(computerPlay:);
      break;
    }
    case GameActionPause:
    {
      imageResourceName = pauseButtonIconResource;
      selector = @selector(pause:);
      break;
    }
    case GameActionContinue:
    {
      imageResourceName = continueButtonIconResource;
      selector = @selector(continue:);
      break;
    }
    case GameActionInterrupt:
    {
      imageResourceName = interruptButtonIconResource;
      selector = @selector(interrupt:);
      break;
    }
    case GameActionScoringDone:
    {
      imageResourceName = nil;
      selector = @selector(scoringDone:);
      break;
    }
    case GameActionGameInfo:
    {
      imageResourceName = gameInfoButtonIconResource;
      selector = @selector(gameInfo:);
      break;
    }
    case GameActionMoreGameActions:
    {
      imageResourceName = nil;
      selector = @selector(moreGameActions:);
      break;
    }
    default:
    {
      return nil;
    }
  }

  UIBarButtonItem* button;
  if (GameActionScoringDone == gameAction)
  {
    // TODO xxx provide an icon
    button = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                            target:[GameActionManager sharedGameActionManager]
                                                            action:selector] autorelease];
    button.style = UIBarButtonItemStyleBordered;
  }
  else if (GameActionMoreGameActions == gameAction)
  {
    // TODO xxx provide an icon
    button = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                            target:[GameActionManager sharedGameActionManager]
                                                            action:selector] autorelease];
    button.style = UIBarButtonItemStyleBordered;
  }
  else
  {
    button = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageResourceName]
                                               style:UIBarButtonItemStyleBordered
                                              target:[GameActionManager sharedGameActionManager]
                                              action:selector] autorelease];
  }
  button.tag = gameAction;
  return button;
}

#pragma mark - Private helpers - Button order

// -----------------------------------------------------------------------------
/// @brief Returns an array with NSNumber objects, each NSNumber encapsulating
/// a value from the GameAction enumeration. The array elements appear in the
/// order in which UIBarButtonItem objects corresponding to those GameAction
/// values should be displayed in the UI.
// -----------------------------------------------------------------------------
+ (NSArray*) buttonOrderList
{
  NSMutableArray* buttonOrderList = [NSMutableArray array];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionScoringDone]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionPass]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionComputerPlay]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionDiscardBoardPosition]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionPause]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionContinue]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionInterrupt]];
  return buttonOrderList;
}

#pragma mark - Private helpers - Game action visible state

// -----------------------------------------------------------------------------
/// @brief Updates the internal state of this NavigationBarController to match
/// the dictionary @a gameActions. Returns true if there are any changes to the
/// current visibility of game actions. Returns false if there are no changes.
///
/// The supplied dictionary is expected to contain one key/value pair for each
/// game action that should become visible in the UI. Game actions not in the
/// dictionary will not be visible after the next UI update.
///
/// The dictionary key is an NSNumber encapsulating a value from the GameAction
/// enumeration. The dictionary value is an NSNumber encapsulating a BOOL value,
/// indicating the initial enabled state that the button should have when the
/// button will become visible the next time.
///
/// This method sets the property @e visibleGameActions with an array that
/// contains the game actions that are currently visible. The objects appear
/// in the array in the order defined by the property @e buttonOrderList.
/// Actually, @e visibleGameActions is nothing but a subset of the content of
/// @e buttonOrderList.
///
/// As a side-effect, this method also sets the initial enabled state of each
/// button that is about to become visible.
// -----------------------------------------------------------------------------
- (void) updateForVisibleGameActions:(NSDictionary*)gameActions
{
  NSMutableArray* visibleGameActions = [NSMutableArray array];
  for (NSNumber* gameActionAsNumber in self.buttonOrderList)
  {
    NSNumber* enabledState = [gameActions objectForKey:gameActionAsNumber];
    if (! enabledState)
    {
      // Game action does not appear in the supplied dictionary, so it should
      // not become visible
      continue;
    }
    [visibleGameActions addObject:gameActionAsNumber];
    // Setup initial enabled state
    UIBarButtonItem* button = self.gameActionButtons[gameActionAsNumber];
    button.enabled = [enabledState boolValue];
  }
  self.visibleGameActions = visibleGameActions;
}

@end
