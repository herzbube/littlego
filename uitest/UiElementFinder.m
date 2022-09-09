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
/// @brief Returns the navigation bar of the root view of #UIAreaPlay.
///
/// @see PlayRootViewController.
// -----------------------------------------------------------------------------
- (XCUIElement*) findPlayRootViewNavigationBar:(XCUIApplication*)app
{
  XCUIElement* playRootViewNavigationBar = app.navigationBars[playRootViewNavigationBarAccessibilityIdentifier];
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
      buttonName = passButtonIconResource;
      break;
    case GameActionDiscardBoardPosition:
      buttonName = discardButtonIconResource;
      break;
    case GameActionComputerPlay:
      buttonName = computerPlayButtonIconResource;
      break;
    case GameActionComputerSuggestMove:
      buttonName = computerSuggestMoveButtonIconResource;
      break;
    case GameActionPause:
      buttonName = pauseButtonIconResource;
      break;
    case GameActionContinue:
      buttonName = continueButtonIconResource;
      break;
    case GameActionInterrupt:
      buttonName = interruptButtonIconResource;
      break;
    case GameActionScoringStart:
      buttonName = scoringStartButtonIconResource;
      break;
    case GameActionPlayStart:
      buttonName = playStartButtonIconResource;
      break;
    case GameActionSwitchSetupStoneColorToWhite:
      buttonName = stoneBlackButtonIconResource;
      break;
    case GameActionSwitchSetupStoneColorToBlack:
      buttonName = stoneWhiteButtonIconResource;
      break;
    case GameActionDiscardAllSetupStones:
      buttonName = discardButtonIconResource;
      break;
    case GameActionMoves:
      buttonName = @"Moves";
      break;
    case GameActionGameInfo:
      buttonName = gameInfoButtonIconResource;
      break;
    case GameActionMoreGameActions:
      buttonName = menuHamburgerButtonIconResource;
      break;
    default:
      return nil;
  }

  XCUIElement* playRootViewNavigationBar = [self findPlayRootViewNavigationBar:app];
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
      return nil;
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
  boardPositionNavigationButtonContainer = app.collectionViews[boardPositionNavigationButtonContainerAccessibilityIdentifier];
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
      return nil;
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
      uiElementName = @"More";
      break;
    default:
      return nil;
  }

  XCUIElement* uiElement = app.tabBars.buttons[uiElementName];
  if (! uiElement.exists)
    uiElement = app.cells.staticTexts[uiElementName];

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
    case UIAreaPlay:
      navigationBarName = playRootViewNavigationBarAccessibilityIdentifier;
      break;
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
    case UIAreaNavigation:
      navigationBarName = @"More";
      break;
    default:
      return nil;
  }

  XCUIElement* navigationBar = app.navigationBars[navigationBarName];
  return navigationBar;
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
/// @brief Returns the container that lists board positions.
// -----------------------------------------------------------------------------
- (XCUIElement*) findBoardPositionCellContainerWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* boardPositionCellContainer;
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

// -----------------------------------------------------------------------------
/// @brief Returns the page indicator that controls paging in the annotation
/// view.
// -----------------------------------------------------------------------------
- (XCUIElement*) findAnnotationViewPageControlWithUiApplication:(XCUIApplication*)app
{
  XCUIElement* pageIndicator = app.pageIndicators[annotationViewPageControlAccessibilityIdentifier];
  return pageIndicator;
}

// -----------------------------------------------------------------------------
/// @brief Returns the specified page in the annotation view.
// -----------------------------------------------------------------------------
- (XCUIElement*) findAnnotationViewPage:(enum AnnotationViewPage)annotationViewPage withUiApplication:(XCUIApplication*)app
{
  NSString* annotationViewPageName;

  switch (annotationViewPage)
  {
    case AnnotationViewPageValuation:
      annotationViewPageName = annotationViewValuationPageAccessibilityIdentifier;
      break;
    case AnnotationViewPageDescription:
      annotationViewPageName = annotationViewDescriptionPageAccessibilityIdentifier;
      break;
    default:
      return nil;
  }

  XCUIElement* annotationViewPageElement = app.otherElements[annotationViewPageName];
  return annotationViewPageElement;
}

// -----------------------------------------------------------------------------
/// @brief Returns the specified UI element on the valuation page in the
/// annotation view.
// -----------------------------------------------------------------------------
- (XCUIElement*) findValuationPageUiElement:(enum ValuationPageUiElement)valuationPageUiElement withUiApplication:(XCUIApplication*)app
{
  NSString* uiElementName;

  switch (valuationPageUiElement)
  {
    case ValuationPageUiElementPositionValuationButton:
      uiElementName = annotationViewPositionValuationButtonAccessibilityIdentifier;
      break;
    case ValuationPageUiElementMoveValuationButton:
      uiElementName = annotationViewMoveValuationButtonAccessibilityIdentifier;
      break;
    case ValuationPageUiElementHotspotDesignationButton:
      uiElementName = annotationViewHotspotDesignationButtonAccessibilityIdentifier;
      break;
    case ValuationPageUiElementEstimatedScoreButton:
      uiElementName = annotationViewEstimatedScoreButtonAccessibilityIdentifier;
      break;
    default:
      return nil;
  }

  XCUIElement* annotationViewPage = [self findAnnotationViewPage:AnnotationViewPageValuation withUiApplication:app];
  XCUIElement* uiElement = annotationViewPage.buttons[uiElementName];
  return uiElement;
}

// -----------------------------------------------------------------------------
/// @brief Returns the specified UI element on the description page in the
/// annotation view.
// -----------------------------------------------------------------------------
- (XCUIElement*) findDescriptionPageUiElement:(enum DescriptionPageUiElement)descriptionPageUiElement withUiApplication:(XCUIApplication*)app
{
  NSString* uiElementName;
  bool uiElementIsLabel;

  switch (descriptionPageUiElement)
  {
    case DescriptionPageUiElementShortDescriptionLabel:
      uiElementName = annotationViewShortDescriptionLabelAccessibilityIdentifier;
      uiElementIsLabel = true;
      break;
    case DescriptionPageUiElementLongDescriptionLabel:
      uiElementName = annotationViewLongDescriptionLabelAccessibilityIdentifier;
      uiElementIsLabel = true;
      break;
    case DescriptionPageUiElementEditDescriptionButton:
      uiElementName = annotationViewEditDescriptionButtonAccessibilityIdentifier;
      uiElementIsLabel = false;
      break;
    case DescriptionPageUiElementRemoveDescriptionButton:
      uiElementName = annotationViewRemoveDescriptionButtonAccessibilityIdentifier;
      uiElementIsLabel = false;
      break;
    default:
      return nil;
  }

  XCUIElement* annotationViewPage = [self findAnnotationViewPage:AnnotationViewPageDescription withUiApplication:app];
  XCUIElement* uiElement;
  if (uiElementIsLabel)
    uiElement = annotationViewPage.staticTexts[uiElementName];
  else
    uiElement = annotationViewPage.buttons[uiElementName];
  return uiElement;
}

@end
