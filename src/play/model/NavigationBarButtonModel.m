// -----------------------------------------------------------------------------
// Copyright 2015-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "NavigationBarButtonModel.h"
#import "../gameaction/GameActionManager.h"
#import "../model/BoardViewModel.h"
#import "../model/MarkupModel.h"
#import "../../main/ApplicationDelegate.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NavigationBarButtonModel.
// -----------------------------------------------------------------------------
@interface NavigationBarButtonModel()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSDictionary* gameActionButtons;
@property(nonatomic, retain, readwrite) NSArray* buttonOrderList;
@property(nonatomic, retain, readwrite) NSArray* visibleGameActions;
//@}
@end


@implementation NavigationBarButtonModel

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NavigationBarButtonModel object.
///
/// @note This is the designated initializer of NavigationBarButtonModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.gameActionButtons = [NavigationBarButtonModel gameActionButtons];
  self.buttonOrderList = [NavigationBarButtonModel buttonOrderList];
  self.visibleGameActions = [NSArray array];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NavigationBarButtonModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameActionButtons = nil;
  self.buttonOrderList = nil;
  self.visibleGameActions = nil;
  [super dealloc];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Updates the content of property @e visibleGameActions to match the
/// current application state.
// -----------------------------------------------------------------------------
- (void) updateVisibleGameActions
{
  NSDictionary* visibleStates = [[GameActionManager sharedGameActionManager] visibleStatesOfGameActions];
  [self updateForVisibleGameActions:visibleStates];
}

// -----------------------------------------------------------------------------
/// @brief Updates the content of property @e visibleGameActions to match the
/// states in @a visibleStates.
// -----------------------------------------------------------------------------
- (void) updateVisibleGameActionsWithVisibleStates:(NSDictionary*)visibleStates
{
  [self updateForVisibleGameActions:visibleStates];
}

// -----------------------------------------------------------------------------
/// @brief Updates the the icon of the button that corresponds to @a gameAction.
// -----------------------------------------------------------------------------
- (void) updateIconOfGameAction:(enum GameAction)gameAction
{
  NSString* imageResourceName;
  switch (gameAction)
  {
    case GameActionSelectMarkupType:
      imageResourceName = [NavigationBarButtonModel imageResourceNameForGameActionSelectMarkupType];
      break;
    case GameActionMoves:
      return;   // obsolete game action
    default:
      imageResourceName = [UIImage iconResourceNameForGameAction:gameAction];
      break;
  }

  NSNumber* gameActionAsNumber = [NSNumber numberWithInt:gameAction];
  UIBarButtonItem* barButtonItem = self.gameActionButtons[gameActionAsNumber];
  barButtonItem.image = [UIImage imageNamed:imageResourceName];
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
    UIBarButtonItem* button = [NavigationBarButtonModel buttonForGameAction:gameAction];
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
    case GameActionSelectMarkupType:
      imageResourceName = [NavigationBarButtonModel imageResourceNameForGameActionSelectMarkupType];
      selector = [GameActionManager handlerForGameAction:gameAction];
      break;
    case GameActionMoves:
      return nil;   // obsolete game action
    default:
      imageResourceName = [UIImage iconResourceNameForGameAction:gameAction];
      selector = [GameActionManager handlerForGameAction:gameAction];
      break;
  }

  UIBarButtonItem* button = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageResourceName]
                                                              style:UIBarButtonItemStylePlain
                                                             target:[GameActionManager sharedGameActionManager]
                                                             action:selector] autorelease];
  button.tag = gameAction;
  button.accessibilityIdentifier = imageResourceName;
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
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionScoringStart]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionPlayStart]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionSwitchSetupStoneColorToWhite]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionSwitchSetupStoneColorToBlack]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionDiscardAllSetupStones]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionSelectMarkupType]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionDiscardAllMarkup]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionPass]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionComputerPlay]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionComputerSuggestMove]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionDiscardBoardPosition]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionPause]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionContinue]];
  [buttonOrderList addObject:[NSNumber numberWithInt:GameActionInterrupt]];
  return buttonOrderList;
}

#pragma mark - Private helpers - Game action visible state

// -----------------------------------------------------------------------------
/// @brief Updates the internal state of this NavigationBarButtonModel to match
/// the dictionary @a gameActions.
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

#pragma mark - Private helpers - Icon resources

// -----------------------------------------------------------------------------
/// @brief Returns the resource name of the icon image to be used for
/// #GameActionSelectMarkupType. The resource name is dynamic and depends on a
/// user preference.
// -----------------------------------------------------------------------------
+ (NSString*) imageResourceNameForGameActionSelectMarkupType
{
  MarkupModel* markupModel = [ApplicationDelegate sharedDelegate].markupModel;
  BoardViewModel* boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
  return [UIImage iconResourceNameForMarkupType:markupModel.markupType selectedSymbolMarkupStyle:boardViewModel.selectedSymbolMarkupStyle];
}

@end
