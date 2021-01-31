// -----------------------------------------------------------------------------
// Copyright 2015-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameActionButtonBoxDataSource.h"


/// @brief Enumerates the button box sections that this
/// GameActionButtonBoxDataSource provides.
enum ButtonBoxSection
{
  VariableButtonBoxSection,  ///< @brief A section with a variable number of buttons
  FixedButtonBoxSection,     ///< @brief A section with a fixed number of buttons
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// GameActionButtonBoxDataSource.
// -----------------------------------------------------------------------------
@interface GameActionButtonBoxDataSource()
@property(nonatomic, retain) NSDictionary* gameActionButtons;
@property(nonatomic, retain) NSDictionary* buttonOrderDictionary;
@property(nonatomic, retain) NSDictionary* visibleGameActions;
@end


@implementation GameActionButtonBoxDataSource

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameActionButtonBoxDataSource object.
///
/// @note This is the designated initializer of GameActionButtonBoxDataSource.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.gameActionButtons = [GameActionButtonBoxDataSource gameActionButtons];
  self.buttonOrderDictionary = [GameActionButtonBoxDataSource buttonOrderDictionary];
  [GameActionManager sharedGameActionManager].uiDelegate = self;
  NSDictionary* visibleStates = [[GameActionManager sharedGameActionManager] visibleStatesOfGameActions];
  [self updateForVisibleGameActions:visibleStates];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameActionButtonBoxDataSource
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameActionButtons = nil;
  self.buttonOrderDictionary = nil;
  self.visibleGameActions = nil;
  if ([GameActionManager sharedGameActionManager].uiDelegate == self)
    [GameActionManager sharedGameActionManager].uiDelegate = nil;
  [super dealloc];
}

#pragma mark - ButtonBoxControllerDataSource overrides

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (NSString*) accessibilityIdentifierInButtonBoxController:(ButtonBoxController*)buttonBoxController
{
  return gameActionButtonContainerAccessibilityIdentifier;
}

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (int) numberOfSectionsInButtonBoxController:(ButtonBoxController*)buttonBoxController
{
  return (int)self.visibleGameActions.count;
}

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (int) buttonBoxController:(ButtonBoxController*)buttonBoxController numberOfRowsInSection:(NSInteger)section
{
  NSNumber* sectionAsNumber = [NSNumber numberWithInteger:section];
  NSArray* visibleGameActionsInSection = self.visibleGameActions[sectionAsNumber];
  return (int)visibleGameActionsInSection.count;
}

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (int) buttonBoxController:(ButtonBoxController*)buttonBoxController numberOfColumnsInSection:(NSInteger)section
{
  return 1;
}

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (UIButton*) buttonBoxController:(ButtonBoxController*)buttonBoxController buttonAtIndexPath:(NSIndexPath*)indexPath
{
  NSNumber* sectionAsNumber = [NSNumber numberWithInteger:indexPath.section];
  NSArray* visibleGameActionsInSection = self.visibleGameActions[sectionAsNumber];
  NSNumber* gameActionAsNumber = visibleGameActionsInSection[indexPath.row];
  UIButton* button = self.gameActionButtons[gameActionAsNumber];
  return button;
}

#pragma mark - GameActionManagerUIDelegate overrides

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
       updateVisibleStates:(NSDictionary*)gameActions
{
  [self updateForVisibleGameActions:gameActions];
  [self.buttonBoxController reloadData];
}

// -----------------------------------------------------------------------------
/// @brief GameActionManagerUIDelegate method.
// -----------------------------------------------------------------------------
- (void) gameActionManager:(GameActionManager*)manager
                    enable:(BOOL)enable
                gameAction:(enum GameAction)gameAction
{
  NSNumber* gameActionAsNumber = [NSNumber numberWithInt:gameAction];
  UIButton* button = self.gameActionButtons[gameActionAsNumber];
  button.enabled = enable;
}

#pragma mark - Private helpers - UIButton creation

// -----------------------------------------------------------------------------
/// @brief Returns a dictionary with one key/value pair for each value in the
/// GameAction enumeration. The key is an NSNumber encapsulating the value from
/// the GameAction enumeration, the value is a UIButton object corresponding to
/// the GameAction value.
// -----------------------------------------------------------------------------
+ (NSDictionary*) gameActionButtons
{
  NSMutableDictionary* gameActionButtons = [NSMutableDictionary dictionary];
  for (enum GameAction gameAction = GameActionFirst; gameAction <= GameActionLast; ++gameAction)
  {
    UIButton* button = [GameActionButtonBoxDataSource buttonForGameAction:gameAction];
    button.enabled = NO;
    NSNumber* gameActionAsNumber = [NSNumber numberWithInt:gameAction];
    gameActionButtons[gameActionAsNumber] = button;
  }
  return gameActionButtons;
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly instantiated UIButton object that has its properties
/// set up to match the specified @a gameAction.
// -----------------------------------------------------------------------------
+ (UIButton*) buttonForGameAction:(enum GameAction)gameAction
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
    case GameActionScoringStart:
    {
      imageResourceName = scoringStartButtonIconResource;
      selector = @selector(scoringStart:);
      break;
    }
    case GameActionPlayStart:
    {
      imageResourceName = playStartButtonIconResource;
      selector = @selector(playStart:);
      break;
    }
    case GameActionSwitchSetupStoneColorToWhite:
    {
      imageResourceName = stoneBlackButtonIconResource;
      selector = @selector(switchSetupStoneColorToWhite:);
      break;
    }
    case GameActionSwitchSetupStoneColorToBlack:
    {
      imageResourceName = stoneWhiteButtonIconResource;
      selector = @selector(switchSetupStoneColorToBlack:);
      break;
    }
    case GameActionDiscardAllSetupStones:
    {
      imageResourceName = discardButtonIconResource;
      selector = @selector(discardAllSetupStones:);
      break;
    }
    case GameActionMoves:
    {
      // We don't have support for this game action
      return nil;
    }
    case GameActionGameInfo:
    {
      imageResourceName = gameInfoButtonIconResource;
      selector = @selector(gameInfo:);
      break;
    }
    case GameActionMoreGameActions:
    {
      imageResourceName = moreGameActionsButtonIconResource;
      selector = @selector(moreGameActions:);
      break;
    }
    default:
    {
      return nil;
    }
  }

  UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.tag = gameAction;
  [button setImage:[UIImage imageNamed:imageResourceName]
          forState:UIControlStateNormal];
  [button addTarget:[GameActionManager sharedGameActionManager]
             action:selector
   forControlEvents:UIControlEventTouchUpInside];
  return button;
}

#pragma mark - Private helpers - Button order

// -----------------------------------------------------------------------------
/// @brief Returns a dictionary whose content specifies the order in which
/// buttons should be displayed in the UI.
///
/// Dictionary keys are NSNumber objects, each encapsulating a value that
/// denotes the index of a button box. Dictionary values are NSArray objects,
/// each specifying the order in which buttons should be displayed in the UI in
/// the corresponding button box.
///
/// Array elements are NSNumber objects, each NSNumber encapsulating a value
/// from the GameAction enumeration. The array elements appear in the order in
/// which UIButton objects corresponding to those GameAction values should be
/// displayed in the UI in the corresponding button box.
// -----------------------------------------------------------------------------
+ (NSDictionary*) buttonOrderDictionary
{
  NSMutableArray* variableButtonBoxSectionOrder = [NSMutableArray array];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionScoringStart]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionPlayStart]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionSwitchSetupStoneColorToWhite]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionSwitchSetupStoneColorToBlack]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionDiscardAllSetupStones]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionPass]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionComputerPlay]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionDiscardBoardPosition]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionPause]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionContinue]];
  [variableButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionInterrupt]];

  NSMutableArray* fixedButtonBoxSectionOrder = [NSMutableArray array];
  [fixedButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionGameInfo]];
  [fixedButtonBoxSectionOrder addObject:[NSNumber numberWithInt:GameActionMoreGameActions]];

  NSMutableDictionary* buttonOrderDictionary = [NSMutableDictionary dictionary];
  buttonOrderDictionary[[NSNumber numberWithInt:VariableButtonBoxSection]] = variableButtonBoxSectionOrder;
  buttonOrderDictionary[[NSNumber numberWithInt:FixedButtonBoxSection]] = fixedButtonBoxSectionOrder;
  return buttonOrderDictionary;
}

#pragma mark - Private helpers - Game action visible state

// -----------------------------------------------------------------------------
/// @brief Updates the internal state of this GameActionButtonBoxDataSource to
/// match the dictionary @a gameActions.
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
  NSMutableDictionary* visibleGameActionsDictionary = [NSMutableDictionary dictionary];

  for (NSNumber* buttonBoxSectionAsNumber in self.buttonOrderDictionary)
  {
    NSMutableArray* buttonBoxSectionOrder = self.buttonOrderDictionary[buttonBoxSectionAsNumber];

    NSMutableArray* visibleGameActions = [NSMutableArray array];
    for (NSNumber* gameActionAsNumber in buttonBoxSectionOrder)
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
      UIButton* button = self.gameActionButtons[gameActionAsNumber];
      button.enabled = [enabledState boolValue];
    }

    visibleGameActionsDictionary[buttonBoxSectionAsNumber] = visibleGameActions;
  }
  self.visibleGameActions = visibleGameActionsDictionary;
}

@end
