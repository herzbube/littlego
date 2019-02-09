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
/// @brief Returns the button that represents the specified board navigation.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBoardNavigationButton:(enum BoardPositionNavigationButton)boardPositionNavigationButton withUiApplication:(XCUIApplication*)app
{
  NSString* buttonName;

  switch (boardPositionNavigationButton)
  {
    case BoardPositionNavigationButtonRewindToStart:
      buttonName = @"back";
      break;
    case BoardPositionNavigationButtonPrevious:
      buttonName = @"forward";
      break;
    case BoardPositionNavigationButtonNext:
      buttonName = @"rewindtostart";
      break;
    case BoardPositionNavigationButtonForwardToEnd:
      buttonName = @"forwardtoend";
      break;
    default:
      buttonName = nil;
      break;
  }

  XCUIElement* button = app.collectionViews.buttons[buttonName];
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

// -----------------------------------------------------------------------------
/// @brief Returns the status label.
// -----------------------------------------------------------------------------
- (XCUIElement*) findStatusLabelWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* statusLabel = app.staticTexts[statusLabelAccessibilityIdentifier];
  return statusLabel;
}

// -----------------------------------------------------------------------------
/// @brief Returns the collection view that lists board positions.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBoardPositionCollectionViewWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* boardPositionCollectionView = app.collectionViews[boardPositionCollectionViewAccessibilityIdentifier];
  return boardPositionCollectionView;
}

// -----------------------------------------------------------------------------
/// @brief Returns an array of cells that list board positions. Returns nil
/// if the collection view is currently not visible.
// -----------------------------------------------------------------------------
- (NSArray<XCUIElement*>*) findBoardPositionCellsWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* boardPositionCollectionView = [self findBoardPositionCollectionViewWithUiApplication:app];
  if (boardPositionCollectionView.exists)
  {
    NSArray<XCUIElement*>* boardPositionCells = boardPositionCollectionView.cells.allElementsBoundByIndex;
    return boardPositionCells;
  }
  else
  {
    return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the label that displays the intersection in a board position
/// cell.
// -----------------------------------------------------------------------------
- (XCUIElement*) findIntersectionLabelInBoardPositionCell:(XCUIElement*)boardPositionCell
{
  XCUIElement* intersectionLabel = boardPositionCell.staticTexts[intersectionLabelBoardPositionAccessibilityIdentifier];
  return intersectionLabel;
}

// -----------------------------------------------------------------------------
/// @brief Returns the label that displays the board position in a board
/// position cell.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBoardPositionLabelInBoardPositionCell:(XCUIElement*)boardPositionCell
{
  XCUIElement* intersectionLabel = boardPositionCell.staticTexts[boardPositionLabelBoardPositionAccessibilityIdentifier];
  return intersectionLabel;
}

// -----------------------------------------------------------------------------
/// @brief Returns the label that displays the captured stones in a board
/// position cell.
// -----------------------------------------------------------------------------
- (XCUIElement*) findCapturedStonesLabelInBoardPositionCell:(XCUIElement*)boardPositionCell
{
  XCUIElement* intersectionLabel = boardPositionCell.staticTexts[capturedStonesLabelBoardPositionAccessibilityIdentifier];
  return intersectionLabel;
}

// -----------------------------------------------------------------------------
/// @brief Returns the image view that displays the stone image of the specified
/// color @a color in a board position cell.
// -----------------------------------------------------------------------------
- (XCUIElement*) findStoneImageViewForColor:(enum GoColor)color inBoardPositionCell:(XCUIElement*)boardPositionCell
{
  NSString* accessibilityIdentifier;
  if (color == GoColorBlack)
    accessibilityIdentifier = blackStoneImageViewBoardPositionAccessibilityIdentifier;
  else
    accessibilityIdentifier = whiteStoneImageViewBoardPositionAccessibilityIdentifier;

  XCUIElement* stoneImageView = boardPositionCell.images[accessibilityIdentifier];
  return stoneImageView;
}

@end
