// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "UiElementFinder.h"


@implementation UiElementFinder

// -----------------------------------------------------------------------------
/// @brief Returns the navigation bar of the root view of #UIAreaPlay.
///
/// @see PlayRootViewController.
// -----------------------------------------------------------------------------
- (XCUIElement*) findPlayRootViewNavigationBar:(XCUIApplication*)app
{
  XCUIElement* playRootViewNavigationBar = app.navigationBars[@"PlayRootView"];
  return playRootViewNavigationBar;
}

// -----------------------------------------------------------------------------
/// @brief Returns the button that represents the specified game action.
// -----------------------------------------------------------------------------
- (XCUIElement*) findGameActionButton:(enum GameAction)gameAction withUiApplication:(XCUIApplication*)app
{
  NSString* buttonName;

  switch (gameAction)
  {
    case GameActionPass:
      buttonName = @"pass";
      break;
    case GameActionDiscardBoardPosition:
      buttonName = @"discard";
      break;
    case GameActionComputerPlay:
      buttonName = @"computer play";
      break;
    case GameActionPause:
      buttonName = @"pause";
      break;
    case GameActionContinue:
      buttonName = @"continue";
      break;
    case GameActionInterrupt:
      buttonName = @"interrupt";
      break;
    case GameActionScoringStart:
      buttonName = @"scoring";
      break;
    case GameActionPlayStart:
      buttonName = @"gogrid2x2";
      break;
    case GameActionSwitchSetupStoneColorToWhite:
      buttonName = @"stone black icon";
      break;
    case GameActionSwitchSetupStoneColorToBlack:
      buttonName = @"stone white icon";
      break;
    case GameActionDiscardAllSetupStones:
      buttonName = @"discard";
      break;
    case GameActionGameInfo:
      buttonName = @"game info";
      break;
    case GameActionMoreGameActions:
      buttonName = @"more game actions";
      break;
    default:
      buttonName = nil;
      break;
  }

  XCUIElement* playRootViewNavigationBar = [self findPlayRootViewNavigationBar:app];
  XCUIElement* button = playRootViewNavigationBar.buttons[buttonName];
  return button;
}

// -----------------------------------------------------------------------------
/// @brief Returns the button in the UI area "Play" that that pops up the main
/// menu.
// -----------------------------------------------------------------------------
- (XCUIElement*) findMainMenuButtonWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* playRootViewNavigationBar = [self findPlayRootViewNavigationBar:app];
  XCUIElement* button = playRootViewNavigationBar.buttons[@"main menu"];
  return button;
}

@end
