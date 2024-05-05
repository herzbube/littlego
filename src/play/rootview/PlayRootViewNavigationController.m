// -----------------------------------------------------------------------------
// Copyright 2015-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayRootViewNavigationController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UIViewControllerAdditions.h"


@implementation PlayRootViewNavigationController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayRootViewNavigationController object.
///
/// @note This is the designated initializer of
/// PlayRootViewNavigationController.
// -----------------------------------------------------------------------------
- (id) initWithRootViewController:(UIViewController*)rootViewController
{
  // Call designated initializer of superclass (UINavigationController)
  self = [super initWithRootViewController:rootViewController];
  if (! self)
    return nil;
  self.delegate = self;
  [GameActionManager sharedGameActionManager].viewControllerPresenterDelegate = self;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// PlayRootViewNavigationController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  GameActionManager* gameActionManager = [GameActionManager sharedGameActionManager];
  if (gameActionManager.viewControllerPresenterDelegate == self)
    gameActionManager.viewControllerPresenterDelegate = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  self.navigationBar.accessibilityIdentifier = playRootViewNavigationBarAccessibilityIdentifier;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This override handles interface orientation changes while this controller's
/// view hierarchy is visible, and changes that occurred while this controller's
/// view hierarchy was not visible (this method is invoked when the controller's
/// view becomes visible again).
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  UIInterfaceOrientation interfaceOrientation = [UiElementMetrics interfaceOrientation];
  [self updateNavigationBarHiddenForInterfaceOrientation:interfaceOrientation];
}

#pragma mark - UINavigationControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UINavigationControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController
       willShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
  UIInterfaceOrientation interfaceOrientation = [UiElementMetrics interfaceOrientation];
  [self updateNavigationBarHiddenForInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief Private helper that is invoked from several places and that updates
/// the value of property self.navigationBarHidden.
///
/// In portrait orientation the navigation bar is always shown. When the root
/// view controller is diplayed this is necessary because game actions and the
/// status view are displayed in the navigation bar.
///
/// In landscape orientation the navigation bar is hidden when the root view
/// controller is displayed (game actions and status view are displayed
/// somewhere else than in the navigation bar, to provide more vertical room for
/// the board), and shown when any other view controller is pushed on the stack.
// -----------------------------------------------------------------------------
- (void) updateNavigationBarHiddenForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    self.navigationBarHidden = NO;
  }
  else
  {
    NSUInteger navigationStackSize = self.viewControllers.count;
    if (1 == navigationStackSize)
      self.navigationBarHidden = YES;
    else
      self.navigationBarHidden = NO;
  }
}

#pragma mark - GameActionManagerViewControllerPresenterDelegate overrides

// -----------------------------------------------------------------------------
/// @brief GameActionManagerViewControllerPresenterDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)gameActionManager
        pushViewController:(UIViewController*)viewController
{
  [self pushViewController:viewController animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerViewControllerPresenterDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)gameActionManager
         popViewController:(UIViewController*)viewController
{
  // This check is needed because this method is invoked in a secondary thread
  // when a game is loaded from the archive and the game info screen is visible
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    SEL selector = @selector(gameActionManager:popViewController:);
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:self];
    [invocation setArgument:&gameActionManager atIndex:2];
    [invocation setArgument:&viewController atIndex:3];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
    return;
  }

  if (self.topViewController == viewController)
    [self popViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerViewControllerPresenterDelegate protocol method.
// -----------------------------------------------------------------------------
                       - (void) gameActionManager:(GameActionManager*)gameActionManager
presentNavigationControllerWithRootViewController:(UIViewController*)rootViewController
                                usingPopoverStyle:(bool)usePopoverStyle
                                popoverSourceView:(UIView*)sourceView
                             popoverBarButtonItem:(UIBarButtonItem*)barButtonItem
{
  [self presentNavigationControllerWithRootViewController:rootViewController
                                        usingPopoverStyle:usePopoverStyle
                                        popoverSourceView:sourceView
                                     popoverBarButtonItem:barButtonItem];
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerViewControllerPresenterDelegate protocol method.
// -----------------------------------------------------------------------------
                       - (void) gameActionManager:(GameActionManager*)gameActionManager
dismissNavigationControllerWithRootViewController:(UIViewController*)rootViewController
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
