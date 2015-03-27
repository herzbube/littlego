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
#import "NavigationBarController.h"
#import "NavigationBarControllerPhone.h"
#import "NavigationBarControllerPhonePortraitOnly.h"
#import "../model/NavigationBarButtonModel.h"
#import "../../shared/LayoutManager.h"
#import "../../utility/ExceptionUtility.h"


@implementation NavigationBarController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a UI type-dependent controller
/// object that knows how to set up the correct view hierarchy for the current
/// UI type.
// -----------------------------------------------------------------------------
+ (NavigationBarController*) navigationBarController
{
  NavigationBarController* navigationBarController;
  switch ([LayoutManager sharedManager].uiType)
  {
    case UITypePhonePortraitOnly:
      navigationBarController = [[[NavigationBarControllerPhonePortraitOnly alloc] init] autorelease];
      break;
    case UITypePad:
      navigationBarController = [[[NavigationBarControllerPhonePortraitOnly alloc] init] autorelease];
      break;
    default:
      [ExceptionUtility throwInvalidUIType:[LayoutManager sharedManager].uiType];
  }
  return navigationBarController;
}

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
  self.navigationBarButtonModel = [[[NavigationBarButtonModel alloc] init] autorelease];
  [GameActionManager sharedGameActionManager].uiDelegate = self;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NavigationBarController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.navigationBarButtonModel = nil;
  if ([GameActionManager sharedGameActionManager].uiDelegate == self)
    [GameActionManager sharedGameActionManager].uiDelegate = nil;
  [super dealloc];
}

#pragma mark - GameActionManagerUIDelegate overrides

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
       updateVisibleStates:(NSDictionary*)gameActions
{
  [self.navigationBarButtonModel updateVisibleGameActionsWithVisibleStates:gameActions];
  [self populateNavigationBar];
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
  // the right-most end of whichever navigation bar the bar button item was
  // added to, so we can find the representing view by examining the frames of
  // all navigation bar subviews.
  UIView* rightMostSubview = nil;
  for (UIView* subview in [self moreGameActionsNavigationBar].subviews)
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

#pragma mark - Methods to override by subclasses

// -----------------------------------------------------------------------------
/// @brief Populates the navigation bar with buttons that are appropriate for
/// the current application state.
///
/// This is an "abstract" method, i.e. subclasses MUST override this method. If
/// invoked the default implementation throws an exception.
// -----------------------------------------------------------------------------
- (void) populateNavigationBar
{
  [ExceptionUtility throwAbstractMethodException];
}

// -----------------------------------------------------------------------------
/// @brief Returns the direct superview of the view that represents the
/// "More Game Actions" bar button item.
///
/// This is an "abstract" method, i.e. subclasses MUST override this method. If
/// invoked the default implementation throws an exception.
// -----------------------------------------------------------------------------
- (UIView*) moreGameActionsNavigationBar
{
  [ExceptionUtility throwAbstractMethodException];
  return nil;  // make compiler happy (compiler does not see the above method throws an exception and we don't really need a return value)
}

@end
