// -----------------------------------------------------------------------------
// Copyright 2019-2024 Patrick Näf (herzbube@herzbube.ch)
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
@class UiElementFinder;


// -----------------------------------------------------------------------------
/// @brief The UiTestHelper class is used by user interface tests (UI tests)
/// to run reusable assertions.
// -----------------------------------------------------------------------------

@interface UiTestHelper : NSObject

- (id) initWithUiElementFinder:(UiElementFinder*)uiElementFinder;

- (CGVector) vectorFromStringVertex:(NSString*)vertex
                    onBoardWithSize:(enum GoBoardSize)boardSize;

- (void) tapIntersection:(NSString*)vertex
         onBoardWithSize:(enum GoBoardSize)boardSize
       withUiApplication:(XCUIApplication*)app;

- (void) tapPageControl:(XCUIElement*)pageControl;
- (void) tapPageControl:(XCUIElement*)pageControl
            onRightSide:(bool)shouldTapOnRightSide;

- (bool) verifyWithUiApplication:(XCUIApplication*)app
  doesContentOfBoardPositionCell:(XCUIElement*)boardPositionCell
           matchTextLabelContent:(NSString*)textLabelContent
          detailTextLabelContent:(NSString*)detailTextLabelContent
      capturedStonesLabelContent:(NSString*)capturedStonesLabelContent
                      nodeSymbol:(enum NodeTreeViewCellSymbol)nodeSymbol;

- (bool) verifyWithUiApplication:(XCUIApplication*)app
      matchingUiElementExistsFor:(UIAccessibilityElement*)accessibilityElement;
- (bool) verifyWithUiApplication:(XCUIApplication*)app
  matchingUiElementDoesNotExistFor:(UIAccessibilityElement*)accessibilityElement;

- (void) waitWithUiApplication:(XCUIApplication*)app
            onBehalfOfTestCase:(XCTestCase*)testCase
    forExistsMatchingUiElement:(UIAccessibilityElement*)accessibilityElement
                   waitSeconds:(NSTimeInterval)seconds;

- (void) waitWithUiApplication:(XCUIApplication*)app
            onBehalfOfTestCase:(XCTestCase*)testCase
    forExistsMatchingUiElement:(UIAccessibilityElement*)accessibilityElement;

@end
