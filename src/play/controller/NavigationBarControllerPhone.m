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
#import "NavigationBarControllerPhone.h"
#import "../model/NavigationBarButtonModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// NavigationBarControllerPhone.
// -----------------------------------------------------------------------------
@interface NavigationBarControllerPhone()
@property(nonatomic, assign) UINavigationItem* navigationItem;
@property(nonatomic, retain) NavigationBarButtonModel* navigationBarButtonModel;
@end


@implementation NavigationBarControllerPhone

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NavigationBarControllerPhone object.
///
/// @note This is the designated initializer of NavigationBarControllerPhone.
// -----------------------------------------------------------------------------
- (id) initWithNavigationItem:(UINavigationItem*)navigationItem
{
  // Call designated initializer of superclass (NavigationBarController)
  self = [super init];
  if (! self)
    return nil;
  self.navigationItem = navigationItem;
  self.navigationBar = nil;
  self.navigationBarButtonModel = [[[NavigationBarButtonModel alloc] init] autorelease];
  [GameActionManager sharedGameActionManager].uiDelegate = self;
  [self setupGameActions];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NavigationBarControllerPhone
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.navigationItem = nil;
  self.navigationBar = nil;
  self.navigationBarButtonModel = nil;
  if ([GameActionManager sharedGameActionManager].uiDelegate == self)
    [GameActionManager sharedGameActionManager].uiDelegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupGameActions
{
  [self.navigationBarButtonModel updateVisibleGameActions];
  [self populateNavigationItem];
}

#pragma mark - GameActionManagerUIDelegate overrides

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
       updateVisibleStates:(NSDictionary*)gameActions
{
  [self.navigationBarButtonModel updateVisibleGameActionsWithVisibleStates:gameActions];
  [self populateNavigationItem];
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
                    enable:(BOOL)enable
                gameAction:(enum GameAction)gameAction
{
  NSNumber* gameActionAsNumber = [NSNumber numberWithInt:gameAction];
  UIBarButtonItem* button = self.navigationBarButtonModel.gameActionButtons[gameActionAsNumber];
  button.enabled = enable;
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (UIView*) viewForPresentingMoreGameActionsByGameActionManager:(GameActionManager*)manager
{
  // We need the view that represents the "More Game Actions" bar button item so
  // that we can present an action sheet originating from that view. There is no
  // official API that lets us find the view, but we know that the button is at
  // the right-most end of the navigation bar, so we can find the representing
  // view by examining the frames of all navigation bar subviews.
  UIView* rightMostSubview = nil;
  for (UIView* subview in self.navigationBar.subviews)
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

#pragma mark - Navigation item population

// -----------------------------------------------------------------------------
/// @brief Populates the navigation item with buttons that are appropriate for
/// the current application state.
// -----------------------------------------------------------------------------
- (void) populateNavigationItem
{
  [self populateLeftBarButtonItems];
  [self populateRightBarButtonItems];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBar().
// -----------------------------------------------------------------------------
- (void) populateLeftBarButtonItems
{
  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  for (NSNumber* gameActionAsNumber in self.navigationBarButtonModel.visibleGameActions)
  {
    UIBarButtonItem* button = self.navigationBarButtonModel.gameActionButtons[gameActionAsNumber];
    [barButtonItems addObject:button];
  }
  self.navigationItem.leftBarButtonItems = barButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBar().
// -----------------------------------------------------------------------------
- (void) populateRightBarButtonItems
{
  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  [barButtonItems addObject:self.navigationBarButtonModel.gameActionButtons[[NSNumber numberWithInt:GameActionMoreGameActions]]];
  [barButtonItems addObject:self.navigationBarButtonModel.gameActionButtons[[NSNumber numberWithInt:GameActionGameInfo]]];
  self.navigationItem.rightBarButtonItems = barButtonItems;
}

@end
