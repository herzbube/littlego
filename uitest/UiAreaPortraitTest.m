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


// See the section "Automated UI tests" in the document TESTING for details
// about how UI testing works.


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

  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[uiTestModeLaunchArgument];
  [app launch];

  [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;

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

  // Status view
  XCUIElement* statusLabel = [self.uiElementFinder findStatusLabelWithUiApplication:app];
  XCTAssertTrue([statusLabel.label isEqualToString:@"Game started Black to move"]);  // Newline character is converted to space

  // Board positions
  NSArray* boardPositionCells = [self.uiElementFinder findBoardPositionCellsWithUiApplication:app];
  XCTAssertEqual(boardPositionCells.count, 1);
  XCUIElement* firstBoardPositionCell = boardPositionCells[0];
  XCUIElement* intersectionLabel = [self.uiElementFinder findIntersectionLabelInBoardPositionCell:firstBoardPositionCell];
  XCTAssertTrue([intersectionLabel.label isEqualToString:@"Start of the game"]);
  XCUIElement* boardPositionLabel = [self.uiElementFinder findBoardPositionLabelInBoardPositionCell:firstBoardPositionCell];
  XCTAssertTrue([boardPositionLabel.label isEqualToString:@"Handicap: 0, Komi: 7½"]);
  XCUIElement* capturedStonesLabel = [self.uiElementFinder findCapturedStonesLabelInBoardPositionCell:firstBoardPositionCell];
  XCTAssertFalse(capturedStonesLabel.exists);
  XCTAssertEqual(firstBoardPositionCell.images.count, 0);
  XCTAssertTrue(firstBoardPositionCell.selected);
}

// -----------------------------------------------------------------------------
/// @brief Test that all UI areas can be activated.
// -----------------------------------------------------------------------------
- (void) testActivateAllUiAreas
{
  XCUIApplication* app = [[XCUIApplication alloc] init];

  // Go to main menu
  XCUIElement* mainMenuButton = [self.uiElementFinder findMainMenuButtonWithUiApplication:app];
  XCTAssertTrue(mainMenuButton.enabled);
  [mainMenuButton tap];

  // Check that we have arrived
  XCUIElement* mainMenuNavigationBar = [self.uiElementFinder findMainMenuNavigationBarWithUiApplication:app];
  XCTAssertTrue(mainMenuNavigationBar.exists);

  // Loop through all UI areas and go to each one, then return to the main menu
  for (enum UIArea uiArea = UIAreaSettings; uiArea <= UIAreaChangelog; ++uiArea)
  {
    XCUIElement* uiAreaElement = [self.uiElementFinder findUiAreaElement:uiArea withUiApplication:app];
    [uiAreaElement tap];

    XCUIElement* uiAreaNavigationBar = [self.uiElementFinder findUiAreaNavigationBar:uiArea withUiApplication:app];
    XCTAssertTrue(uiAreaNavigationBar.exists);

    XCUIElement* backButton = [self.uiElementFinder findBackButtonMainMenuFromUiAreaNavigationBar:uiAreaNavigationBar];
    [backButton tap];

    mainMenuNavigationBar = [self.uiElementFinder findMainMenuNavigationBarWithUiApplication:app];
    XCTAssertTrue(mainMenuNavigationBar.exists);
  }

  // Return to the UI area "Play"
  XCUIElement* backButton = [self.uiElementFinder findBackButtonPlayWithUiApplication:app];
  XCTAssertTrue(backButton.enabled);
  [backButton tap];
}

@end
