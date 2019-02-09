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


// -----------------------------------------------------------------------------
/// @brief The UiAreaPortraitTest class tests the #UIAreaPlay when the user
/// interface is in portrait mode.
// -----------------------------------------------------------------------------
@interface UiAreaPortraitTest : XCTestCase
@property(nonatomic, strong) UiElementFinder* uiElementFinder;
@end


@implementation UiAreaPortraitTest

#pragma mark - setUp and tearDown

// -----------------------------------------------------------------------------
/// @brief Sets the environment up for a test.
// -----------------------------------------------------------------------------
- (void) setUp
{
  self.continueAfterFailure = NO;

  [[[XCUIApplication alloc] init] launch];

  self.uiElementFinder = [[UiElementFinder alloc] init];
}

// -----------------------------------------------------------------------------
/// @brief Tears the environment down after a test.
// -----------------------------------------------------------------------------
- (void) tearDown
{
  self.uiElementFinder = nil;
}

#pragma mark - Tests

// -----------------------------------------------------------------------------
/// @brief Test that when the app starts up a number of UI elements are present
/// and have the correct state.
// -----------------------------------------------------------------------------
- (void) testUiAreaPlayDefaultState
{
  XCUIApplication* app = [[XCUIApplication alloc] init];

  // Game actions
  XCUIElement* passButton = [self.uiElementFinder findGameActionButton:GameActionPass withUiApplication:app];
  XCTAssertTrue(passButton.enabled);
  XCUIElement* computerPlayButton = [self.uiElementFinder findGameActionButton:GameActionComputerPlay withUiApplication:app];
  XCTAssertTrue(computerPlayButton.enabled);
  XCUIElement* gameInfoButton = [self.uiElementFinder findGameActionButton:GameActionGameInfo withUiApplication:app];
  XCTAssertTrue(gameInfoButton.enabled);
  XCUIElement* moreGameActionsButton = [self.uiElementFinder findGameActionButton:GameActionMoreGameActions withUiApplication:app];
  XCTAssertTrue(moreGameActionsButton.enabled);

  /// Main menu
  XCUIElement* mainMenuButton = [self.uiElementFinder findMainMenuButtonWithUiApplication:app];
  XCTAssertTrue(mainMenuButton.enabled);

  // Board position navigation
  XCUIElement* rewindToStartButton = [self.uiElementFinder findBoardNavigationButton:BoardPositionNavigationButtonRewindToStart withUiApplication:app];
  XCTAssertFalse(rewindToStartButton.enabled);
  XCUIElement* previousButton = [self.uiElementFinder findBoardNavigationButton:BoardPositionNavigationButtonPrevious withUiApplication:app];
  XCTAssertFalse(previousButton.enabled);
  XCUIElement* nextButton = [self.uiElementFinder findBoardNavigationButton:BoardPositionNavigationButtonNext withUiApplication:app];
  XCTAssertFalse(nextButton.enabled);
  XCUIElement* forwardToEndButton = [self.uiElementFinder findBoardNavigationButton:BoardPositionNavigationButtonForwardToEnd withUiApplication:app];
  XCTAssertFalse(forwardToEndButton.enabled);
}

@end
