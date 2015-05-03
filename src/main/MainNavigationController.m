// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "MainNavigationController.h"
#import "ApplicationDelegate.h"
#import "MainTableViewController.h"
#import "MainUtility.h"
#import "UIAreaInfo.h"
#import "../play/boardposition/BoardPositionCollectionViewCell.h"
#import "../play/rootview/PlayRootViewController.h"
#import "../play/splitview/LeftPaneViewController.h"
#import "../play/splitview/RightPaneViewController.h"
#import "../ui/SplitViewController.h"
#import "../ui/UiSettingsModel.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MainNavigationController.
// -----------------------------------------------------------------------------
@interface MainNavigationController()
@property(nonatomic, assign) bool hasPortraitOrientationViewHierarchy;
@property(nonatomic, retain) PlayRootViewController* playRootViewController;
// Cannot name this property splitViewController, there already is a property
// of that name in UIViewController, and it has a different meaning
@property(nonatomic, retain) SplitViewController* splitViewControllerChild;
@property(nonatomic, retain) LeftPaneViewController* leftPaneViewController;
@property(nonatomic, retain) RightPaneViewController* rightPaneViewController;
@end


@implementation MainNavigationController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a MainNavigationController object.
///
/// @note This is the designated initializer of MainNavigationController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UINavigationController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.delegate = self;
  [MainMenuPresenter sharedPresenter].mainMenuPresenterDelegate = self;
  [GameActionManager sharedGameActionManager].gameInfoViewControllerPresenter = self;
  [self setupChildControllers];
  [self restoreVisibleUIAreaToUserDefaults];
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(statusBarOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
  // TODO xxx We should not fake this color, we should somehow get a real
  // navigation bar to place itself behind the statusbar.
  self.view.backgroundColor = [UIColor navigationbarBackgroundColor];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MainNavigationController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  MainMenuPresenter* mainMenuPresenter = [MainMenuPresenter sharedPresenter];
  if (mainMenuPresenter.mainMenuPresenterDelegate == self)
    mainMenuPresenter.mainMenuPresenterDelegate = nil;
  GameActionManager* gameActionManager = [GameActionManager sharedGameActionManager];
  if (gameActionManager.gameInfoViewControllerPresenter == self)
    gameActionManager.gameInfoViewControllerPresenter = nil;
  [self releaseObjects];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.playRootViewController = nil;
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// @brief Internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  // We must be able to switch between different root view controllers when
  // the interface orientation changes because we have entirely different view
  // hierarchies for each orientation. Unfortunately UINavigationController
  // does not let us change the root view controller once we have set it up
  // (i.e. we can't completely empty the navigation stack). For this reason
  // we set up a dummy root view controller which will remain in place
  // forever.
  UIViewController* dummyRootViewController = [[[UIViewController alloc] init] autorelease];
  [self pushViewController:dummyRootViewController animated:NO];

  // Set self.hasPortraitOrientationViewHierarchy to a value that guarantees
  // that addChildControllersForInterfaceOrientation:() will do something
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
  self.hasPortraitOrientationViewHierarchy = !isPortraitOrientation;
  [self addChildControllersForInterfaceOrientation:self.interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief Adds child controllers that match @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (void) addChildControllersForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation == self.hasPortraitOrientationViewHierarchy)
    return;
  self.hasPortraitOrientationViewHierarchy = isPortraitOrientation;

  UIViewController* realRootViewController;
  if (isPortraitOrientation)
  {
    self.playRootViewController = [PlayRootViewController playRootViewController];
    self.playRootViewController.uiArea = UIAreaPlay;
    realRootViewController = self.playRootViewController;
  }
  else
  {
    self.splitViewControllerChild = [[[SplitViewController alloc] init] autorelease];
    self.splitViewControllerChild.uiArea = UIAreaPlay;
    realRootViewController = self.splitViewControllerChild;

    // These are not child controllers of our own. We are setting them up on
    // behalf of the generic SplitViewController.
    self.leftPaneViewController = [[[LeftPaneViewController alloc] init] autorelease];
    self.rightPaneViewController = [[[RightPaneViewController alloc] init] autorelease];
    self.splitViewControllerChild.viewControllers = [NSArray arrayWithObjects:self.leftPaneViewController, self.rightPaneViewController, nil];
    self.splitViewControllerChild.leftPaneWidth = [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero].width;
  }

  [self pushViewController:realRootViewController animated:NO];
}

// -----------------------------------------------------------------------------
/// @brief Removes child controllers if the current setup does NOT match
/// @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (void) removeChildControllersIfNotMatchingInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation == self.hasPortraitOrientationViewHierarchy)
    return;

  // We temporarily pop back to the dummy root view controller. The *real* root
  // view controllwer will be pushed onto the stack a little later.
  [self popToRootViewControllerAnimated:NO];
  if (self.hasPortraitOrientationViewHierarchy)
  {
    self.playRootViewController = nil;
  }
  else
  {
    // TODO This should be removed, it is a HACK! Reason for the hack:
    // - The Auto Layout constraints in RightPaneViewController are made so that
    //   they fit landscape orientation. In portrait orientation the constraints
    //   cause the Auto Layout engine to print warnings into the Debug console.
    // - Now here's the strange thing: Despite the fact that here we remove all
    //   references to the RightPaneViewController object, and that object is
    //   properly deallocated later on, the deallocation takes place too late
    //   so that RightPaneViewController's view hierarchy still takes part in
    //   the view layout process after the interface orientation change.
    //   Something - presumably it's UINavigationController - keeps
    //   RightPaneViewController around too long.
    // - The only way I have found to get rid of the Auto Layout warnings is to
    //   explicitly tell RightPaneViewController to remove the offending
    //   constraints NOW!
    //
    // Perhaps the hack can be eliminated once we drop iOS 7 support and can
    // start to work with size classes.
    [self.rightPaneViewController removeDynamicConstraints];

    self.splitViewControllerChild = nil;
    self.leftPaneViewController = nil;
    self.rightPaneViewController = nil;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
///
/// This override handles interface orientation changes.
///
/// @note This override is also called if a view controller is pushed onto, or
/// popped from the navigation stack.
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  // We install a new root view controller only if the root view controller is
  // actually visible
  NSUInteger navigationStackSize = self.viewControllers.count;
  if (navigationStackSize > 2)
    return;

  // These calls are necessary in case the interface orientation changed while
  // the user was on a deeper level of the navigation stack, and now returns to
  // the root view controller level of the navigation stack.
  [self removeChildControllersIfNotMatchingInterfaceOrientation:self.interfaceOrientation];
  [self addChildControllersForInterfaceOrientation:self.interfaceOrientation];
  [self updateNavigationBarVisibility];
  [self updateNavigationItemBackButtonTitle];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the
/// #UIApplicationDidChangeStatusBarOrientationNotification notification.
///
/// This notification handler is required because we can't override
/// didRotateFromInterfaceOrientation:(). Reason: There appears to be a
/// bug in iOS 8 which causes that override not to be called for subclasses of
/// UINavigationController. Experimentally determined: The override is called
/// correctly in the iOS 7.1 simulator.
// -----------------------------------------------------------------------------
- (void) statusBarOrientationDidChange:(NSNotification*)notification
{
  // We install a new root view controller only if the root view controller is
  // actually visible
  NSUInteger navigationStackSize = self.viewControllers.count;
  if (navigationStackSize > 2)
    return;

  // Can't use self.interfaceOrientation, that property does not yet have the
  // correct value
  UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
  [self removeChildControllersIfNotMatchingInterfaceOrientation:interfaceOrientation];
  [self addChildControllersForInterfaceOrientation:interfaceOrientation];
  [self updateNavigationBarVisibility];
  [self updateNavigationItemBackButtonTitle];
}

#pragma mark - UINavigationControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UINavigationControllerDelegate protocol method.
///
/// Writes the visible UI area to the user defaults.
///
/// In landscape also hides the navigation bar when the root view controller is
/// displayed, and shows the navigation bar when any other view controller is
/// pushed on the stack.
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController
       willShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
  // The view controller about to be shown is already on the stack
  NSUInteger navigationStackSize = self.viewControllers.count;
  if (1 == navigationStackSize)
  {
    // The dummy root view controller is at the top of the stack. This does not
    // interest us, we know that the *real* root view controller will be pushed
    // next, so we wait for that.
    return;
  }

  [self updateNavigationBarVisibility];
  [self updateNavigationItemBackButtonTitle];
  enum UIArea uiArea = viewController.uiArea;
  if (uiArea != UIAreaUnknown)
    [MainUtility mainApplicationViewController:self didDisplayUIArea:uiArea];
}

#pragma mark - GameInfoViewControllerPresenter overrides

// -----------------------------------------------------------------------------
/// @brief GameInfoViewControllerPresenter protocol method.
// -----------------------------------------------------------------------------
- (void) presentGameInfoViewController:(UIViewController*)gameInfoViewController
{
  [self pushViewController:gameInfoViewController animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief GameInfoViewControllerPresenter protocol method.
// -----------------------------------------------------------------------------
- (void) dismissGameInfoViewController:(UIViewController*)gameInfoViewController
{
  if (self.visibleViewController == gameInfoViewController)
    [self popViewControllerAnimated:YES];
}

#pragma mark - MainMenuPresenter overrides

// -----------------------------------------------------------------------------
/// @brief MainMenuPresenter protocol method.
// -----------------------------------------------------------------------------
- (void) presentMainMenu
{
  [self presentMainMenuAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief MainMenuPresenter protocol method.
// -----------------------------------------------------------------------------
- (void) dismissMainMenu
{
  NSString* errorMessage = @"Not implemented";
  DDLogError(@"%@: %@", self, errorMessage);
  NSException* exception = [NSException exceptionWithName:NSGenericException
                                                   reason:errorMessage
                                                 userInfo:nil];
  @throw exception;
}

#pragma mark - UIArea management

// -----------------------------------------------------------------------------
/// @brief Restores the currently visible UI area to the value stored in the
/// user defaults.
///
/// This method should be invoked before the navigation controller's view
/// appears, otherwise the user will be able to see the appearance change.
// -----------------------------------------------------------------------------
- (void) restoreVisibleUIAreaToUserDefaults
{
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  enum UIArea visibleUIArea = applicationDelegate.uiSettingsModel.visibleUIArea;
  [self activateUIArea:visibleUIArea];
}

// -----------------------------------------------------------------------------
/// @brief Activates the UI area @a uiArea, making it visible to the user.
// -----------------------------------------------------------------------------
- (void) activateUIArea:(enum UIArea)uiArea
{
  [self popNavigationStackToUIAreaPlay];
  switch (uiArea)
  {
    case UIAreaPlay:
    {
      break;
    }
    case UIAreaNavigation:
    {
      [self presentMainMenuAnimated:NO];
      break;
    }
    default:
    {
      MainTableViewController* mainTableViewController = [self presentMainMenuAnimated:NO];
      [mainTableViewController presentUIArea:uiArea];
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the root view of the view hierarchy that makes up
/// #UIAreaPlay.
// -----------------------------------------------------------------------------
- (UIView*) rootViewForUIAreaPlay
{
  UIViewController* rootViewControllerForUIAreaPlay = self.viewControllers[1];
  return rootViewControllerForUIAreaPlay.view;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Presents the main menu and returns the controller that manages the
/// menu. The caller decides whether presentation occurs animated or not.
// -----------------------------------------------------------------------------
- (MainTableViewController*) presentMainMenuAnimated:(bool)animated
{
  MainTableViewController* mainTableViewController = [[[MainTableViewController alloc] init] autorelease];
  mainTableViewController.title = [MainUtility titleStringForUIArea:UIAreaNavigation];
  mainTableViewController.uiArea = UIAreaNavigation;
  BOOL animatedAsBOOL = animated ? YES : NO;
  [self pushViewController:mainTableViewController animated:animatedAsBOOL];
  return mainTableViewController;
}

// -----------------------------------------------------------------------------
/// @brief In portrait: Always shows the navigation bar. In landscape: Hides the
/// navigation bar when the root view controller is displayed, and shows the
/// navigation bar when any other view controller is pushed on the stack.
// -----------------------------------------------------------------------------
- (void) updateNavigationBarVisibility
{
  // Don't use self.interfaceOrientation, this method may be called at a time
  // when this property does not have the correct value
  if (self.hasPortraitOrientationViewHierarchy)
  {
    self.navigationBarHidden = NO;
  }
  else
  {
    NSUInteger navigationStackSize = self.viewControllers.count;
    if (2 == navigationStackSize)
      self.navigationBarHidden = YES;
    else
      self.navigationBarHidden = NO;
  }
}

// -----------------------------------------------------------------------------
/// @brief Temporarily assign a title to the #UIAreaPlay root view controller
/// while the main menu is shown. This causes the back button to display that
/// title. Remove the title when the navigation stack is popped back to
/// #UIAreaPlay (there the navigation item shows buttons that don't leave enough
/// space for a title).
// -----------------------------------------------------------------------------
- (void) updateNavigationItemBackButtonTitle
{
  NSUInteger navigationStackSize = self.viewControllers.count;
  switch (navigationStackSize)
  {
    case 2:
      self.topViewController.title = nil;
      break;
    case 3:
      ((UIViewController*)self.viewControllers[1]).title = [MainUtility titleStringForUIArea:UIAreaPlay];
      break;
    default:
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Pops the navigation stack back to #UIAreaPlay.
// -----------------------------------------------------------------------------
- (void) popNavigationStackToUIAreaPlay
{
  while (true)
  {
    NSUInteger navigationStackSize = self.viewControllers.count;
    if (2 == navigationStackSize)
      break;
    [self popViewControllerAnimated:NO];
  }
}

@end
