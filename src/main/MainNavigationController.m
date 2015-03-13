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
#import "UIAreaInfo.h"
#import "../play/playtab/PlayTabController.h"
#import "../play/splitview/LeftPaneViewController.h"
#import "../ui/SplitViewController.h"
#import "../ui/UiSettingsModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MainNavigationController.
// -----------------------------------------------------------------------------
@interface MainNavigationController()
@property(nonatomic, assign) bool hasPortraitOrientationViewHierarchy;
@property(nonatomic, retain) PlayTabController* playTabController;
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
  [GameActionManager sharedGameActionManager].gameInfoViewControllerPresenter = self;
  [self setupChildControllers];
  [self restoreVisibleUIAreaToUserDefaults];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MainNavigationController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
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
  self.playTabController = nil;
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
  // This check covers the following scenario: The user temporarily changes the
  // interface orientation while on a deeper level of the navigation stack, then
  // changes back to the original interface orientation, then returns to the
  // root view controller. In this case we don't need to switch out the root
  // view controller.
  if (self.viewControllers.count > 0 && isPortraitOrientation == self.hasPortraitOrientationViewHierarchy)
    return;
  self.hasPortraitOrientationViewHierarchy = isPortraitOrientation;

  if (0 == self.viewControllers.count)
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
  }
  else
  {
    // We temporarily pop back to the dummy root view controller. In a moment
    // we will push the *real* root view controller onto the stack.
    [self popToRootViewControllerAnimated:NO];
  }

  UIViewController* realRootViewController;
  if (isPortraitOrientation)
  {
    self.playTabController = [PlayTabController playTabController];
    self.playTabController.uiArea = UIAreaPlay;
    realRootViewController = self.playTabController;

    //xxx
//    self.playTabController.mainMenuPresenter = self;

    self.splitViewControllerChild = nil;
    self.leftPaneViewController = nil;
    self.rightPaneViewController = nil;
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

    self.rightPaneViewController.mainMenuPresenter = self;

    self.playTabController = nil;
  }

  [self pushViewController:realRootViewController animated:NO];
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
  // The method we invoke here detects if no change is necessary
  [self setupChildControllers];
}

#pragma mark - UINavigationControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UINavigationControllerDelegate protocol method.
///
/// This override hides the navigation bar when the root view controller is
/// displayed, and shows the navigation bar when any other view controller is
/// pushed on the stack.
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController
       willShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
  NSUInteger navigationStackSize = self.viewControllers.count;
  if (1 == navigationStackSize)
  {
    // The dummy root view controller is at the top of the stack. This does not
    // interest us, we know that the *real* root view controller will be pushed
    // next, so we wait for that.
    return;
  }
  else if (2 == navigationStackSize)
    self.navigationBarHidden = YES;
  else
    self.navigationBarHidden = NO;

  enum UIArea uiArea = viewController.uiArea;
  if (uiArea != UIAreaUnknown)
    [ApplicationDelegate sharedDelegate].uiSettingsModel.visibleUIArea = uiArea;
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

#pragma mark - Managing visible UIArea

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
  switch (visibleUIArea)
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
      [mainTableViewController presentUIArea:visibleUIArea];
      break;
    }
  }
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Presents the main menu and returns the controller that manages the
/// menu. The caller decides whether presentation occurs animated or not.
// -----------------------------------------------------------------------------
- (MainTableViewController*) presentMainMenuAnimated:(bool)animated
{
  MainTableViewController* mainTableViewController = [[[MainTableViewController alloc] init] autorelease];
  mainTableViewController.uiArea = UIAreaNavigation;
  BOOL animatedAsBOOL = animated ? YES : NO;
  [self pushViewController:mainTableViewController animated:animatedAsBOOL];
  return mainTableViewController;
}

@end
