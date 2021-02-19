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
#import "UiTestDeviceInfo.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for UiElementFinder.
// -----------------------------------------------------------------------------
@interface UiElementFinder()
@property(nonatomic, weak) UiTestDeviceInfo* uiTestDeviceInfo;
@end


@implementation UiElementFinder

// -----------------------------------------------------------------------------
/// @brief Initializes a UiElementFinder object.
///
/// @note This is the designated initializer of UiElementFinder.
// -----------------------------------------------------------------------------
- (id) initWithUiTestDeviceInfo:(UiTestDeviceInfo*)uiTestDeviceInfo
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.uiTestDeviceInfo = uiTestDeviceInfo;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Returns the navigation bar of the root view of #UIAreaPlay. This
/// method returns the correct result only if the UI type is #UITypePhone.
/// Raises NSInternalInconsistencyException if the UI type is not #UITypePhone.
///
/// @see PlayRootViewController.
// -----------------------------------------------------------------------------
- (XCUIElement*) findPlayRootViewNavigationBar:(XCUIApplication*)app
{
  if (self.uiTestDeviceInfo.uiType != UITypePhone)
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unsupported UIType in findPlayRootViewNavigationBar" userInfo:nil];

  XCUIElement* playRootViewNavigationBar = app.navigationBars[@"PlayRootView"];
  return playRootViewNavigationBar;
}

// -----------------------------------------------------------------------------
/// @brief Returns the navigation bar of the root view of #UIAreaPlay that
/// contains the specified game action. This method returns the correct result
/// only if the UI type is #UITypePhonePortraitOnly or #UITypePad. Raises
/// NSInternalInconsistencyException if the UI type is neither
/// #UITypePhonePortraitOnly nor #UITypePad.
///
/// @see NavigationBarControllerPhonePortraitOnly.
// -----------------------------------------------------------------------------
- (XCUIElement*) findPlayRootViewNavigationBarContainingGameAction:(enum GameAction)gameAction
                                                 withUiApplication:(XCUIApplication*)app
{
  if (self.uiTestDeviceInfo.uiType == UITypePhone)
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unsupported UIType in findPlayRootViewNavigationBarContainingGameAction" userInfo:nil];

  NSString* navigationBarName;

  switch (gameAction)
  {
    case GameActionPass:
    case GameActionDiscardBoardPosition:
    case GameActionComputerPlay:
    case GameActionComputerSuggestMove:
    case GameActionPause:
    case GameActionContinue:
    case GameActionInterrupt:
    case GameActionScoringStart:
    case GameActionPlayStart:
    case GameActionSwitchSetupStoneColorToWhite:
    case GameActionSwitchSetupStoneColorToBlack:
    case GameActionDiscardAllSetupStones:
      navigationBarName = leftNavigationBarAccessibilityIdentifier;
      break;
    case GameActionMoves:
    case GameActionGameInfo:
    case GameActionMoreGameActions:
      navigationBarName = rightNavigationBarAccessibilityIdentifier;
      break;
    default:
      navigationBarName = nil;
      break;
  }

  XCUIElement* playRootViewNavigationBar = app.navigationBars[navigationBarName];
  return playRootViewNavigationBar;
}

// -----------------------------------------------------------------------------
/// @brief Returns the navigation bar of the main menu view. This is available
/// only when the UI type is #UITypePhone.
// -----------------------------------------------------------------------------
- (XCUIElement*) findMainMenuViewNavigationBar:(XCUIApplication*)app
{
  XCUIElement* mainMenuViewNavigationBar = app.navigationBars[@"Main Menu"];
  return mainMenuViewNavigationBar;
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
    case GameActionComputerSuggestMove:
      buttonName = @"computer suggest move";
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
    case GameActionMoves:
      buttonName = @"Moves";
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

  XCUIElement* playRootViewNavigationBar;
  if (self.uiTestDeviceInfo.uiType == UITypePhone)
    playRootViewNavigationBar = [self findPlayRootViewNavigationBar:app];
  else
    playRootViewNavigationBar = [self findPlayRootViewNavigationBarContainingGameAction:gameAction withUiApplication:app];

  XCUIElement* button = playRootViewNavigationBar.buttons[buttonName];
  return button;
}

// -----------------------------------------------------------------------------
/// @brief Returns the specified button in the "More game actions" alert.
/// The alert must be displayed in order for this method to return something
/// useful.
// -----------------------------------------------------------------------------
- (XCUIElement*) findMoreGameActionButton:(enum MoreGameActionsButton)moreGameActionsButton withUiApplication:(XCUIApplication*)app
{
  NSString* buttonName;

  switch (moreGameActionsButton)
  {
    case MoreGameActionsButtonSetupFirstMove:
      buttonName = @"Set up a side to play first";
      break;
    case MoreGameActionsButtonBoardSetup:
      buttonName = @"Set up board";
      break;
    case MoreGameActionsButtonScore:
      buttonName = @"Score";
      break;
    case MoreGameActionsButtonMarkAsSeki:
      buttonName = @"Start marking as seki";
      break;
    case MoreGameActionsButtonMarkAsDead:
      buttonName = @"Start marking as dead";
      break;
    case MoreGameActionsButtonUpdatePlayerInfluence:
      buttonName = @"Update player influence";
      break;
    case MoreGameActionsButtonSetBlackToMove:
      buttonName = @"Set black to move";
      break;
    case MoreGameActionsButtonSetWhiteToMove:
      buttonName = @"Set white to move";
      break;
    case MoreGameActionsButtonResumePlay:
      buttonName = @"Resume play";
      break;
    case MoreGameActionsButtonResign:
      buttonName = @"Resign";
      break;
    case MoreGameActionsButtonUndoResign:
      buttonName = @"Undo resign";
      break;
    case MoreGameActionsButtonUndoTimeout:
      buttonName = @"Undo timeout";
      break;
    case MoreGameActionsButtonUndoForfeit:
      buttonName = @"Undo forfeit";
      break;
    case MoreGameActionsButtonSaveGame:
      buttonName = @"Save game";
      break;
    case MoreGameActionsButtonNewGame:
      buttonName = @"New game";
      break;
    case MoreGameActionsButtonCancel:
      buttonName = @"Cancel";
      break;
    default:
      buttonName = nil;
      break;
  }

  XCUIElement* button = app.sheets[@"Game actions"].buttons[buttonName];
  return button;
}

// -----------------------------------------------------------------------------
/// @brief Returns the container that contains board position navigation
/// buttons.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBoardPositionNavigationButtonContainerWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* boardPositionNavigationButtonContainer;

  if (self.uiTestDeviceInfo.uiType == UITypePhone)
    boardPositionNavigationButtonContainer = app.collectionViews[boardPositionNavigationButtonContainerAccessibilityIdentifier];
  else
    boardPositionNavigationButtonContainer = app.toolbars[boardPositionNavigationButtonContainerAccessibilityIdentifier];

  return boardPositionNavigationButtonContainer;
}

// -----------------------------------------------------------------------------
/// @brief Returns the button that represents the specified board position
/// navigation.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBoardPositionNavigationButton:(enum BoardPositionNavigationButton)boardPositionNavigationButton
                                 withUiApplication:(XCUIApplication*)app
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

  XCUIElement* boardPositionNavigationButtonContainer =
    [self findBoardPositionNavigationButtonContainerWithUiApplication:app];

  XCUIElement* button = boardPositionNavigationButtonContainer.buttons[buttonName];
  return button;
}

// -----------------------------------------------------------------------------
/// @brief Returns the UI element that can be tapped to switch to the specified
/// UI area.
// -----------------------------------------------------------------------------
- (XCUIElement*) findUiAreaElement:(enum UIArea)uiArea withUiApplication:(XCUIApplication*)app
{
  NSString* uiElementName;

  switch (uiArea)
  {
    case UIAreaPlay:
      if (self.uiTestDeviceInfo.uiType == UITypePhone)
        uiElementName = nil;  // has no UI element
      else
        uiElementName = @"Play";
      break;
    case UIAreaSettings:
      uiElementName = @"Settings";
      break;
    case UIAreaArchive:
      uiElementName = @"Archive";
      break;
    case UIAreaDiagnostics:
      uiElementName = @"Diagnostics";
      break;
    case UIAreaHelp:
      uiElementName = @"Help";
      break;
    case UIAreaAbout:
      uiElementName = @"About";
      break;
    case UIAreaSourceCode:
      uiElementName = @"Source Code";
      break;
    case UIAreaLicenses:
      uiElementName = @"Licenses";
      break;
    case UIAreaCredits:
      uiElementName = @"Credits";
      break;
    case UIAreaChangelog:
      uiElementName = @"Changelog";
      break;
    case UIAreaNavigation:
      if (self.uiTestDeviceInfo.uiType == UITypePhone)
        uiElementName = nil;  // has no UI element
      else
        uiElementName = @"More";
      break;
    default:
      uiElementName = nil;
      break;
  }

  XCUIElement* uiElement;

  if (self.uiTestDeviceInfo.uiType == UITypePhone)
  {
    uiElement = app.tables.cells.staticTexts[uiElementName];
  }
  else
  {
    uiElement = app.tabBars.buttons[uiElementName];
    if (! uiElement.exists)
      uiElement = app.cells.staticTexts[uiElementName];
  }

  return uiElement;
}

// -----------------------------------------------------------------------------
/// @brief Returns the navigation bar for the specified UI area. The UI area
/// must be active.
// -----------------------------------------------------------------------------
- (XCUIElement*) findUiAreaNavigationBar:(enum UIArea)uiArea withUiApplication:(XCUIApplication*)app
{
  NSString* navigationBarName;

  switch (uiArea)
  {
    case UIAreaSettings:
      navigationBarName = @"Settings";
      break;
    case UIAreaArchive:
      navigationBarName = @"Archive";
      break;
    case UIAreaDiagnostics:
      navigationBarName = @"Diagnostics";
      break;
    case UIAreaHelp:
      navigationBarName = @"Help";
      break;
    case UIAreaAbout:
      navigationBarName = @"About";
      break;
    case UIAreaSourceCode:
      navigationBarName = @"Source Code";
      break;
    case UIAreaLicenses:
      navigationBarName = @"Licenses";
      break;
    case UIAreaCredits:
      navigationBarName = @"Credits";
      break;
    case UIAreaChangelog:
      navigationBarName = @"Changelog";
      break;
    case UIAreaPlay:  // has no navigation bar
    default:
      navigationBarName = nil;
      break;
  }

  XCUIElement* navigationBar = app.navigationBars[navigationBarName];
  return navigationBar;
}

// -----------------------------------------------------------------------------
/// @brief Returns the button in the UI area "Play" that that pops up the main
/// menu. This method returns the correct result only if the UI type is
/// #UITypePhone. Raises NSInternalInconsistencyException if the UI type is not
/// #UITypePhone.
// -----------------------------------------------------------------------------
- (XCUIElement*) findMainMenuButtonWithUiApplication:(XCUIApplication*)app
{
  if (self.uiTestDeviceInfo.uiType != UITypePhone)
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unsupported UIType in findMainMenuButtonWithUiApplication" userInfo:nil];

  XCUIElement* playRootViewNavigationBar = [self findPlayRootViewNavigationBar:app];
  XCUIElement* button = playRootViewNavigationBar.buttons[@"main menu"];
  return button;
}

// -----------------------------------------------------------------------------
/// @brief Returns the main menu navigation bar. This method returns the correct
/// result only if the UI type is #UITypePhone. Raises
/// NSInternalInconsistencyException if the UI type is not #UITypePhone.
// -----------------------------------------------------------------------------
- (XCUIElement*) findMainMenuNavigationBarWithUiApplication:(XCUIApplication*)app
{
  if (self.uiTestDeviceInfo.uiType != UITypePhone)
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unsupported UIType in findMainMenuNavigationBarWithUiApplication" userInfo:nil];

  XCUIElement* navigationBar = app.navigationBars[@"Main Menu"];
  return navigationBar;
}

// -----------------------------------------------------------------------------
/// @brief Returns the back button in the main menu that returns the user to the
/// UI area "Play".
// -----------------------------------------------------------------------------
- (XCUIElement*) findBackButtonPlayWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* mainMenuViewNavigationBar = [self findMainMenuViewNavigationBar:app];
  XCUIElement* button = mainMenuViewNavigationBar.buttons[@"Play"];
  return button;
}

// -----------------------------------------------------------------------------
/// @brief Returns the back button in the specified UI area navigation bar that
/// returns the user to the main menu.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBackButtonMainMenuFromUiAreaNavigationBar:(XCUIElement*)uiAreaNavigationBar
{
  XCUIElement* button = uiAreaNavigationBar.buttons[@"Main Menu"];
  return button;
}

// -----------------------------------------------------------------------------
/// @brief Returns the back button in the specified UI area navigation bar that
/// returns the user to the "More" navigation controller.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBackButtonMoreFromUiAreaNavigationBar:(XCUIElement*)uiAreaNavigationBar
{
  XCUIElement* button = uiAreaNavigationBar.buttons[@"More"];
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
/// @brief Returns the cell that displays the current board position. This
/// method returns the correct result only if the UI type is
/// #UITypePhonePortraitOnly or #UITypePad. Raises
/// NSInternalInconsistencyException if the UI type is neither
/// #UITypePhonePortraitOnly nor #UITypePad.
// -----------------------------------------------------------------------------
- (XCUIElement*) findCurrentBoardPositionCellWithUiApplication:(XCUIApplication*)app
{
  if (self.uiTestDeviceInfo.uiType == UITypePhone)
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unsupported UIType in findCurrentBoardPositionViewWithUiApplication" userInfo:nil];

  if (self.uiTestDeviceInfo.uiType == UITypePhonePortraitOnly)
  {
    XCUIElement* boardPositionNavigationButtonContainer =
    [self findBoardPositionNavigationButtonContainerWithUiApplication:app];

    XCUIElement* currentBoardPositionView = boardPositionNavigationButtonContainer.cells[currentBoardPositionViewAccessibilityIdentifier];
    return currentBoardPositionView;
  }
  else
  {
    XCUIElement* currentBoardPositionView = app.tables[currentBoardPositionViewAccessibilityIdentifier].cells.firstMatch;
    return currentBoardPositionView;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the container that lists board positions.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBoardPositionCellContainerWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* boardPositionCellContainer;

  if (self.uiTestDeviceInfo.uiType == UITypePad)
    boardPositionCellContainer = app.tables[boardPositionTableViewAccessibilityIdentifier];
  else
    boardPositionCellContainer = app.collectionViews[boardPositionCollectionViewAccessibilityIdentifier];

  return boardPositionCellContainer;
}

// -----------------------------------------------------------------------------
/// @brief Returns an array of cells that list board positions. Returns nil
/// if the collection view is currently not visible.
// -----------------------------------------------------------------------------
- (NSArray<XCUIElement*>*) findBoardPositionCellsWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* boardPositionCellContainer = [self findBoardPositionCellContainerWithUiApplication:app];
  if (boardPositionCellContainer.exists)
  {
    NSArray<XCUIElement*>* boardPositionCells = boardPositionCellContainer.cells.allElementsBoundByIndex;
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
  XCUIElement* boardPositionLabel = boardPositionCell.staticTexts[boardPositionLabelBoardPositionAccessibilityIdentifier];
  return boardPositionLabel;
}

// -----------------------------------------------------------------------------
/// @brief Returns the label that displays the captured stones in a board
/// position cell.
// -----------------------------------------------------------------------------
- (XCUIElement*) findCapturedStonesLabelInBoardPositionCell:(XCUIElement*)boardPositionCell
{
  XCUIElement* capturedStonesLabel = boardPositionCell.staticTexts[capturedStonesLabelBoardPositionAccessibilityIdentifier];
  return capturedStonesLabel;
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
