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


// Forward declarations
@class UiTestDeviceInfo;


// -----------------------------------------------------------------------------
/// @brief The UiElementFinder class is used by user interface tests (UI tests)
/// to locate UI elements.
///
/// General notes regarding the use of XCUIElement:
/// - Use the "exists" property to test whether the UI element is actually
///   present
// -----------------------------------------------------------------------------

@interface UiElementFinder : NSObject

- (id) initWithUiTestDeviceInfo:(UiTestDeviceInfo*)uiTestDeviceInfo;

- (XCUIElement*) findGameActionButton:(enum GameAction)gameAction withUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findMoreGameActionButton:(enum MoreGameActionsButton)moreGameActionsButton withUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findBoardNavigationButton:(enum BoardPositionNavigationButton)boardPositionNavigationButton withUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findUiAreaElement:(enum UIArea)uiArea withUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findUiAreaNavigationBar:(enum UIArea)uiArea withUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findMainMenuButtonWithUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findMainMenuNavigationBarWithUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findBackButtonPlayWithUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findBackButtonMainMenuFromUiAreaNavigationBar:(XCUIElement*)uiAreaNavigationBar;
- (XCUIElement*) findStatusLabelWithUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findBoardPositionCollectionViewWithUiApplication:(XCUIApplication*)app;
- (NSArray<XCUIElement*>*) findBoardPositionCellsWithUiApplication:(XCUIApplication*)app;
- (XCUIElement*) findIntersectionLabelInBoardPositionCell:(XCUIElement*)boardPositionCell;
- (XCUIElement*) findBoardPositionLabelInBoardPositionCell:(XCUIElement*)boardPositionCell;
- (XCUIElement*) findCapturedStonesLabelInBoardPositionCell:(XCUIElement*)boardPositionCell;
- (XCUIElement*) findStoneImageViewForColor:(enum GoColor)color inBoardPositionCell:(XCUIElement*)boardPositionCell;

@end
