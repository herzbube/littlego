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
#import "UiTestHelper.h"
#import "UiElementFinder.h"
#import "../src/go/GoVertex.h"
#import "../src/utility/AccessibilityUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for UiTestHelper.
// -----------------------------------------------------------------------------
@interface UiTestHelper()
@property(nonatomic, weak) UiElementFinder* uiElementFinder;
@end


@implementation UiTestHelper

// -----------------------------------------------------------------------------
/// @brief Initializes a UiTestHelper object.
///
/// @note This is the designated initializer of UiTestHelper.
// -----------------------------------------------------------------------------
- (id) initWithUiElementFinder:(UiElementFinder*)uiElementFinder
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.uiElementFinder = uiElementFinder;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Calculates and returns a CGVector that refers to the intersection
/// identified by @a vertex on a Go board with size @a boardSize. The CGVector
/// can be used to obtain an XCUICoordinate which in turn can be used for
/// tapping on the intersection, e.g. in order to place a stone.
// -----------------------------------------------------------------------------
- (CGVector) vectorFromStringVertex:(NSString*)vertex
                    onBoardWithSize:(enum GoBoardSize)boardSize
{
  // The CGVector expresses a percentage in x/y direction, so we need to
  // calculate the point distance in percent, too. We need to subtract 1 from
  // the board size because the board size is the number of lines, but we want
  // the distance ***BETWEEN* each line.
  CGFloat pointDistancePercent = 1.0f / (boardSize - 1);

  GoVertex* goVertex = [GoVertex vertexFromString:vertex];
  int vertexX = goVertex.numeric.x;
  // Invert the y axis because the origin of the UIKit coordinate system is in
  // the top-left corner
  int vertexY = boardSize - goVertex.numeric.y + 1;

  // For the multiplication the numeric vertex components obviously must be
  // zero-based so that the vector for the top-left corner points to 0/0.
  int zeroBasedVertexX = vertexX - 1;
  int zeroBasedVertexY = vertexY - 1;

  CGVector vector = CGVectorMake(pointDistancePercent * zeroBasedVertexX,
                                 pointDistancePercent * zeroBasedVertexY);
  return vector;
}

// -----------------------------------------------------------------------------
/// @brief Taps on the intersection identified by @a vertex on a Go board with
/// size @a boardSize. If the intersection is empty the expected result is that
/// a stone is placed on the intersection.
// -----------------------------------------------------------------------------
- (void) tapIntersection:(NSString*)vertex
         onBoardWithSize:(enum GoBoardSize)boardSize
       withUiApplication:(XCUIApplication*)app
{
  UIAccessibilityElement* lineGridAccessibilityElement =
    [AccessibilityUtility uiAccessibilityElementInContainer:self forLineGridWithSize:boardSize];

  XCUIElement* lineGridUiElement = app.otherElements[lineGridAccessibilityElement.accessibilityIdentifier];

  CGVector vector = [self vectorFromStringVertex:vertex
                                 onBoardWithSize:boardSize];
  XCUICoordinate* coordinate = [lineGridUiElement coordinateWithNormalizedOffset:vector];

  // The press might not be registered If we use the exact delay
  NSTimeInterval duration = gGoBoardLongPressDelay * 1.5;
  [coordinate pressForDuration:duration];
}

// -----------------------------------------------------------------------------
/// @brief Verifies with the help of @a app that @a boardPositionCell contains
/// @a boardPositionLabelContent, @a intersectionLabelContent,
/// @a capturedStonesLabelContent and an image that matches @a moveColor.
/// Returns true if @a boardPositionCell meets all expectations. Returns false
/// if @a @a boardPositionCell fails to meet any expectation.
///
/// If any one of @a boardPositionLabelContent, @a intersectionLabelContent or
/// @a capturedStonesLabelContent is nil, this method verifies that the
/// corresponding label UI element does not exist.
///
/// If @a moveColor is #GoColorNone, this method verifies that the board
/// position cell does not contain an image.
// -----------------------------------------------------------------------------
- (bool) verifyWithUiApplication:(XCUIApplication*)app
  doesContentOfBoardPositionCell:(XCUIElement*)boardPositionCell
  matchBoardPositionLabelContent:(NSString*)boardPositionLabelContent
        intersectionLabelContent:(NSString*)intersectionLabelContent
      capturedStonesLabelContent:(NSString*)capturedStonesLabelContent
                       moveColor:(enum GoColor)moveColor
{
  XCUIElement* boardPositionLabel = [self.uiElementFinder findBoardPositionLabelInBoardPositionCell:boardPositionCell];
  if (! [self verifyBoardPositionCellLabel:boardPositionLabel matchesContent:boardPositionLabelContent])
    return false;

  XCUIElement* intersectionLabel = [self.uiElementFinder findIntersectionLabelInBoardPositionCell:boardPositionCell];
  if (! [self verifyBoardPositionCellLabel:intersectionLabel matchesContent:intersectionLabelContent])
    return false;

  XCUIElement* capturedStonesLabel = [self.uiElementFinder findCapturedStonesLabelInBoardPositionCell:boardPositionCell];
  if (! [self verifyBoardPositionCellLabel:capturedStonesLabel matchesContent:capturedStonesLabelContent])
    return false;

  if (moveColor == GoColorNone)
  {
    if (boardPositionCell.images.count != 0)
      return false;
  }
  else
  {
    // TODO: Add proper verification code
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Verifies that @a label, which is a UILabel inside a board position
/// cell, contains @a content. Returns true if @a label meets all expectations.
/// Returns false if @a @a label fails to meet any expectation.
///
/// If @a content is nil, this method verifies that @a label does not exist.
///
/// This is an internal helper.
// -----------------------------------------------------------------------------
- (bool) verifyBoardPositionCellLabel:(XCUIElement*)label
                       matchesContent:(NSString*)content
{
  if (content)
    return ([label.label isEqualToString:content] == YES);
  else
    return (label.exists == NO);
}

// -----------------------------------------------------------------------------
/// @brief Verifies that a UI element exists that matches
/// @a accessibilityElement. The UI element must have the same accessibility
/// identifier and accessibility value. Returns true if a UI element exists
/// that meets all expectations. Returns false if no UI element exists that
/// meets all expectations.
// -----------------------------------------------------------------------------
- (bool) verifyWithUiApplication:(XCUIApplication*)app
      matchingUiElementExistsFor:(UIAccessibilityElement*)accessibilityElement
{
  XCUIElement* uiElement = app.otherElements[accessibilityElement.accessibilityIdentifier];
  if (uiElement.exists)
    return ([uiElement.value isEqualToString:accessibilityElement.accessibilityValue] == YES);
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Verifies that a UI element that has the same identifier as
/// @a accessibilityElement does not exist. Returns true if a UI element with
/// the same identifier does not exist. Returns false if a UI element with the
/// same identifier exists.
// -----------------------------------------------------------------------------
- (bool) verifyWithUiApplication:(XCUIApplication*)app
matchingUiElementDoesNotExistFor:(UIAccessibilityElement*)accessibilityElement
{
  XCUIElement* uiElement = app.otherElements[accessibilityElement.accessibilityIdentifier];
  return (uiElement.exists == NO);
}

// -----------------------------------------------------------------------------
/// @brief Waits for @a accessibilityElement to come into existence. Control
/// returns to the caller if @a accessibilityElement comes into existence within
/// the specified time interval @a seconds. Generates a test failure if
/// @a accessibilityElement does not exist after the time interval @a seconds
/// has expired. Note that the content of @a accessibilityElement is ignored
/// by this method.
// -----------------------------------------------------------------------------
- (void) waitWithUiApplication:(XCUIApplication*)app
            onBehalfOfTestCase:(XCTestCase*)testCase
    forExistsMatchingUiElement:(UIAccessibilityElement*)accessibilityElement
                   waitSeconds:(NSTimeInterval)seconds
{
  NSPredicate* predicate = [NSPredicate predicateWithFormat:@"exists == true"];

  // We always search in "otherElements" because at the moment there simply are
  // no tests that look for accessibility elements somewhere else
  XCUIElement* uiElement = app.otherElements[accessibilityElement.accessibilityIdentifier];

  XCTestExpectation* expectation = [testCase expectationForPredicate:predicate
                                                 evaluatedWithObject:uiElement
                                                             handler:nil];
  [testCase waitForExpectations:@[expectation] timeout:seconds];
}

// -----------------------------------------------------------------------------
/// @brief Waits for @a accessibilityElement to come into existence. Control
/// returns to the caller if @a accessibilityElement comes into existence within
/// the default time interval. Generates a test failure if
/// @a accessibilityElement does not exist after the default time interval has
/// expired. Note that the content of @a accessibilityElement is ignored by
/// this method.
// -----------------------------------------------------------------------------
- (void) waitWithUiApplication:(XCUIApplication*)app
            onBehalfOfTestCase:(XCTestCase*)testCase
    forExistsMatchingUiElement:(UIAccessibilityElement*)accessibilityElement
{
  [self waitWithUiApplication:app
           onBehalfOfTestCase:testCase
   forExistsMatchingUiElement:accessibilityElement
                  waitSeconds:10];
}

@end
