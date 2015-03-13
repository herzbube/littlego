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
#import "PlayTabNavigationController.h"


@implementation PlayTabNavigationController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayTabNavigationController object.
///
/// @note This is the designated initializer of PlayTabNavigationController.
// -----------------------------------------------------------------------------
- (id) initWithRootViewController:(UIViewController*)rootViewController
{
  // Call designated initializer of superclass (UINavigationController)
  self = [super initWithRootViewController:rootViewController];
  if (! self)
    return nil;
  self.delegate = self;
  [GameActionManager sharedGameActionManager].gameInfoViewControllerPresenter = self;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayTabNavigationController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  GameActionManager* gameActionManager = [GameActionManager sharedGameActionManager];
  if (gameActionManager.gameInfoViewControllerPresenter == self)
    gameActionManager.gameInfoViewControllerPresenter = nil;
  [super dealloc];
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
    self.navigationBarHidden = YES;
  else
    self.navigationBarHidden = NO;
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

@end
