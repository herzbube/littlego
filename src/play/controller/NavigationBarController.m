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
#import "NavigationBarControllerPhonePortraitOnly.h"
#import "../../shared/LayoutManager.h"
#import "../../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NavigationBarController.
// -----------------------------------------------------------------------------
@interface NavigationBarController()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSDictionary* gameActionButtons;
@property(nonatomic, retain, readwrite) NSArray* buttonOrderList;
@property(nonatomic, retain, readwrite) NSArray* visibleGameActions;
//@}
@end


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
    case UITypePhone:
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
  self.gameActionButtons = [NavigationBarController gameActionButtons];
  self.buttonOrderList = [NavigationBarController buttonOrderList];
  self.visibleGameActions = [NSArray array];
  [GameActionManager sharedGameActionManager].uiDelegate = self;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NavigationBarController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameActionButtons = nil;
  self.buttonOrderList = nil;
  self.visibleGameActions = nil;
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
  [self updateForVisibleGameActions:gameActions];
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
  UIBarButtonItem* button = self.gameActionButtons[gameActionAsNumber];
  button.enabled = enable;
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (UIView*) viewForPresentingMoreGameActionsByGameActionManager:(GameActionManager*)manager
{
  // We need the view that represents the "Game Actions" bar button item so that
  /// we can present an action sheet originating from that view. There is no
  /// official API that lets us find the view, but we know that the button is at
  /// the right-most end of whichever navigation bar the bar button item was
  /// added to, so we can find the representing view by examining the frames of
  /// all navigation bar subviews.
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
  return nil;  // make compiler happy (compiler does not see the above method throws an exception)
}

#pragma mark - Methods to override by subclasses

// -----------------------------------------------------------------------------
/// @brief Updates the content of property @e visibleGameActions to match the
/// current application state.
// -----------------------------------------------------------------------------
- (void) updateVisibleGameActions
{
  NSDictionary* visibleStates = [[GameActionManager sharedGameActionManager] visibleStatesOfGameActions];
  [self updateForVisibleGameActions:visibleStates];
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
    UIBarButtonItem* button = [NavigationBarControllerPhonePortraitOnly buttonForGameAction:gameAction];
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
/// @brief Updates the internal state of this
/// NavigationBarControllerPhonePortraitOnly to match the dictionary
/// @a gameActions. Returns true if there are any changes to the current
/// visibility of game actions. Returns false if there are no changes.
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
