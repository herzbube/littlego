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
#import "../ui/UiElementMetrics.h"
#import "../ui/UiSettingsModel.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MainNavigationController.
// -----------------------------------------------------------------------------
@interface MainNavigationController()
@property(nonatomic, assign) UIViewController* rootViewController;
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
  self.rootViewController = [MainUtility rootViewControllerForUIArea:UIAreaPlay];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MainNavigationController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  MainMenuPresenter* mainMenuPresenter = [MainMenuPresenter sharedPresenter];
  if (mainMenuPresenter.mainMenuPresenterDelegate == self)
    mainMenuPresenter.mainMenuPresenterDelegate = nil;
  GameActionManager* gameActionManager = [GameActionManager sharedGameActionManager];
  if (gameActionManager.gameInfoViewControllerPresenter == self)
    gameActionManager.gameInfoViewControllerPresenter = nil;
  self.rootViewController = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  // TODO We should not fake this color, we should somehow get a real
  // navigation bar to place itself behind the statusbar.
  self.view.backgroundColor = [UIColor navigationbarBackgroundColor];

  if ([ApplicationDelegate sharedDelegate].launchImageModeEnabled)
    return;
  
  [self pushViewController:self.rootViewController animated:NO];
  [self restoreVisibleUIAreaToUserDefaults];

  // Disable the swipe-to-left gesture that pops the top of the navigation
  // stack. iOS does a very poor job of implementing this gesture, so disabling
  // the gesture entirely is not only simpler but also less error-prone than
  // attempting to deal with its shortcomings. Known problems:
  // - When the gesture starts, the delegate method
  //   navigationController:willShowViewController:animated:() is invoked. But
  //   if the user cancels the gesture halfway through, the top view controller
  //   is restored WITHOUT the delegate method being invoked. One workaround for
  //   this is to override viewWillLayoutSubviews(), which is invoked even if
  //   the delegate method is not.
  // - This controller hides the navigation bar if the user pops back to the
  //   root view controller, but if the gesture is cancelled so that the main
  //   menu remains visible, the navigation bar must be re-shown by
  //   viewWillLayoutSubviews(). Doing this causes UINavigationController to
  //   become confused, so when later the settings UI area is displayed the
  //   back button and navigation title are wrong.
  self.interactivePopGestureRecognizer.enabled = NO;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
///
/// This override contains navigation bar handling that must be executed when
/// the interface orientation changes while #UIAreaPlay is shown. The change
/// effected is that the navigation item must be made visible when rotating to
/// portrait orientation, and hidden when rotating to landscape orientation.
///
/// This override is also responsible for handling navigation bar updates when
/// the navigation stack is changed programmatically via activateUIArea:(). In
/// this case, both navigation bar visibility and back button title must be
/// updated. One example where this is relevant: When the user loads a game from
/// the archive, the UI area is programmatically changed back to #UIAreaPlay.
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
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
  if ([ApplicationDelegate sharedDelegate].launchImageModeEnabled)
    return;

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
  return self.rootViewController.view;
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
  if ([UiElementMetrics interfaceOrientationIsPortrait])
  {
    self.navigationBarHidden = NO;
  }
  else
  {
    NSUInteger navigationStackSize = self.viewControllers.count;
    if (1 == navigationStackSize || [ApplicationDelegate sharedDelegate].launchImageModeEnabled)
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
    case 1:
      self.rootViewController.title = nil;
      break;
    case 2:
      self.rootViewController.title = [MainUtility titleStringForUIArea:UIAreaPlay];
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
  [self popToRootViewControllerAnimated:NO];
}

@end
