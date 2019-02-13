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
// -----------------------------------------------------------------------------
- (bool) verifyBoardPositionCellLabel:(XCUIElement*)label
                       matchesContent:(NSString*)content
{
  if (content)
    return ([label.label isEqualToString:content] == YES);
  else
    return (label.exists == NO);
}

@end
