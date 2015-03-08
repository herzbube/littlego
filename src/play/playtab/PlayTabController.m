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
#import "PlayTabController.h"
#import "PlayTabControllerPad.h"
#import "PlayTabControllerPhone.h"
#import "../../shared/LayoutManager.h"


@implementation PlayTabController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a UI type-dependent controller
/// object that knows how to set up the correct view hierarchy for the current
/// UI type.
// -----------------------------------------------------------------------------
+ (PlayTabController*) playTabController
{
  PlayTabController* playTabController;
  if ([LayoutManager sharedManager].uiType != UITypePad)
    playTabController = [[[PlayTabControllerPhone alloc] init] autorelease];
  else
    playTabController = [[[PlayTabControllerPad alloc] init] autorelease];
  playTabController.edgesForExtendedLayout = UIRectEdgeNone;
  playTabController.automaticallyAdjustsScrollViewInsets = NO;
  return playTabController;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayTabController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  GameActionManager* gameActionManager = [GameActionManager sharedGameActionManager];
  if (gameActionManager.gameInfoViewControllerPresenter == self)
    gameActionManager.gameInfoViewControllerPresenter = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) willMoveToParentViewController:(UIViewController*)parent
{
  // We know that our parent must be a UINavigationController. We don't try
  // to access the property navigationController because we don't know (and
  // don't try to assume) whether the property has already been set.
  UINavigationController* parentAsNavigationController = (UINavigationController*)parent;
  // We need to be the delegate so that we can control navigation bar
  // visibility. Our willShowViewController... override expects to be called
  // when we ourselves are pushed to the navigation stack, so the timing for
  // setting ourselves as the delegate is critical. If we do it in
  // willMoveToParentViewController:() the timing is right, if we were to do it
  // in didMoveToParentViewController:() it would be too late.
  parentAsNavigationController.delegate = self;

  [GameActionManager sharedGameActionManager].gameInfoViewControllerPresenter = self;
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
  if (viewController == self)
    navigationController.navigationBarHidden = YES;
  else
    navigationController.navigationBarHidden = NO;
}

#pragma mark - GameInfoViewControllerPresenter overrides

// -----------------------------------------------------------------------------
/// @brief GameInfoViewControllerPresenter protocol method.
// -----------------------------------------------------------------------------
- (void) presentGameInfoViewController:(UIViewController*)gameInfoViewController
{
  [self.navigationController pushViewController:gameInfoViewController animated:YES];

}

// -----------------------------------------------------------------------------
/// @brief GameInfoViewControllerPresenter protocol method.
// -----------------------------------------------------------------------------
- (void) dismissGameInfoViewController:(UIViewController*)gameInfoViewController
{
  if (self.navigationController.visibleViewController == gameInfoViewController)
    [self.navigationController popViewControllerAnimated:YES];
}

@end
