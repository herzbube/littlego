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
#import "../play/gameaction/GameActionManager.h"
#import "../play/splitview/LeftPaneViewController.h"
#import "../play/splitview/RightPaneViewController.h"
#import "../ui/SplitViewController.h"
#import "../ui/AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MainNavigationController.
// -----------------------------------------------------------------------------
@interface MainNavigationController()
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
  // Call designated initializer of superclass (PlayTabController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.navigationBarHidden = YES;
  [self setupChildControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MainNavigationController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  GameActionManager* gameActionManager = [GameActionManager sharedGameActionManager];
  if (gameActionManager.navigationController == self)
    gameActionManager.navigationController = nil;
  [self releaseObjects];
  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.splitViewControllerChild = [[[SplitViewController alloc] init] autorelease];
  [self pushViewController:self.splitViewControllerChild animated:NO];

  // These are not child controllers of our own. We are setting them up on
  // behalf of the generic SplitViewController because we don't want to create a
  // subclass.
  self.leftPaneViewController = [[[LeftPaneViewController alloc] init] autorelease];
  self.rightPaneViewController = [[[RightPaneViewController alloc] init] autorelease];
  self.splitViewControllerChild.viewControllers = [NSArray arrayWithObjects:self.leftPaneViewController, self.rightPaneViewController, nil];

  [GameActionManager sharedGameActionManager].navigationController = self;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
}

@end
