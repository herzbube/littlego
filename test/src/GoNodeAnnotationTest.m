// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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


// Test includes
#import "GoNodeAnnotationTest.h"

// Application includes
#import <go/GoNodeAnnotation.h>


@implementation GoNodeAnnotationTest

// -----------------------------------------------------------------------------
/// @brief Exercises the @e shortDescription property.
// -----------------------------------------------------------------------------
- (void) testShortDescription
{
  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  XCTAssertNil(nodeAnnotation.shortDescription);

  NSString* shortDescription = @"foo";
  NSString* expectedShortDescription = @"foo";
  nodeAnnotation.shortDescription = shortDescription;
  XCTAssertEqual(nodeAnnotation.shortDescription, expectedShortDescription);

  shortDescription = @"foo\nbar";
  expectedShortDescription = @"foo bar";
  nodeAnnotation.shortDescription = shortDescription;
  XCTAssertEqualObjects(nodeAnnotation.shortDescription, expectedShortDescription);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e longDescription property.
// -----------------------------------------------------------------------------
- (void) testLongDescription
{
  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  XCTAssertNil(nodeAnnotation.longDescription);

  NSString* longDescription = @"foo";
  NSString* expectedLongDescription = @"foo";
  nodeAnnotation.longDescription = longDescription;
  XCTAssertEqual(nodeAnnotation.longDescription, expectedLongDescription);

  longDescription = @"foo\nbar";
  expectedLongDescription = @"foo\nbar";
  nodeAnnotation.longDescription = longDescription;
  XCTAssertEqualObjects(nodeAnnotation.longDescription, expectedLongDescription);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e goBoardPositionValuation property.
// -----------------------------------------------------------------------------
- (void) testGoBoardPositionValuation
{
  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  enum GoBoardPositionValuation expectedGoBoardPositionValuation = GoBoardPositionValuationNone;
  XCTAssertEqual(nodeAnnotation.goBoardPositionValuation, expectedGoBoardPositionValuation);

  enum GoBoardPositionValuation goBoardPositionValuation = GoBoardPositionValuationVeryUnclear;
  expectedGoBoardPositionValuation = GoBoardPositionValuationVeryUnclear;
  nodeAnnotation.goBoardPositionValuation = goBoardPositionValuation;
  XCTAssertEqual(nodeAnnotation.goBoardPositionValuation, expectedGoBoardPositionValuation);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e goBoardPositionHotspotDesignation property.
// -----------------------------------------------------------------------------
- (void) testGoBoardPositionHotspotDesignation
{
  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  enum GoBoardPositionHotspotDesignation expectedGoBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationNone;
  XCTAssertEqual(nodeAnnotation.goBoardPositionHotspotDesignation, expectedGoBoardPositionHotspotDesignation);

  enum GoBoardPositionHotspotDesignation goBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationYesEmphasized;
  expectedGoBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationYesEmphasized;
  nodeAnnotation.goBoardPositionHotspotDesignation = goBoardPositionHotspotDesignation;
  XCTAssertEqual(nodeAnnotation.goBoardPositionHotspotDesignation, expectedGoBoardPositionHotspotDesignation);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e estimatedScoreSummary property.
// -----------------------------------------------------------------------------
- (void) testEstimatedScoreSummary
{
  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  enum GoScoreSummary expectedEstimatedScoreSummary = GoScoreSummaryNone;
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e estimatedScoreValue property.
// -----------------------------------------------------------------------------
- (void) testEstimatedScoreValue
{
  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  double expectedEstimatedScoreValue = 0.0;
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e setEstimatedScoreSummary:value:() method.
// -----------------------------------------------------------------------------
- (void) testSetEstimatedScoreSummaryValue
{
  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  enum GoScoreSummary expectedEstimatedScoreSummary = GoScoreSummaryNone;
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  double expectedEstimatedScoreValue = 0.0;
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  // Tests using GoScoreSummaryBlackWins
  enum GoScoreSummary estimatedScoreSummary = GoScoreSummaryBlackWins;
  expectedEstimatedScoreSummary = GoScoreSummaryBlackWins;
  double estimatedScoreValue = 42;
  expectedEstimatedScoreValue = 42.0;
  bool success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = 0;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = -42;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  // Tests using GoScoreSummaryWhiteWins
  estimatedScoreSummary = GoScoreSummaryWhiteWins;
  expectedEstimatedScoreSummary = GoScoreSummaryWhiteWins;
  estimatedScoreValue = 42;
  expectedEstimatedScoreValue = 42.0;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = 0;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = -42;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  // Tests using GoScoreSummaryTie
  estimatedScoreSummary = GoScoreSummaryTie;
  expectedEstimatedScoreSummary = GoScoreSummaryTie;
  estimatedScoreValue = 0.0;
  expectedEstimatedScoreValue = 0.0;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = 42.0;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = -42;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  // Tests using GoScoreSummaryNone
  estimatedScoreSummary = GoScoreSummaryNone;
  expectedEstimatedScoreSummary = GoScoreSummaryNone;
  estimatedScoreValue = 0.0;
  expectedEstimatedScoreValue = 0.0;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = 42.0;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = -42;
  success = [nodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(nodeAnnotation.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(nodeAnnotation.estimatedScoreValue, expectedEstimatedScoreValue);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e isValidEstimatedScoreSummary:value:() method.
// -----------------------------------------------------------------------------
- (void) testIsValidEstimatedScoreSummaryValue
{
  XCTAssertTrue([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryNone value:0]);
  XCTAssertTrue([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryNone value:42]);
  XCTAssertTrue([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryNone value:-42]);

  XCTAssertFalse([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryBlackWins value:0]);
  XCTAssertTrue([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryBlackWins value:42]);
  XCTAssertFalse([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryBlackWins value:-42]);

  XCTAssertFalse([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryWhiteWins value:0]);
  XCTAssertTrue([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryWhiteWins value:42]);
  XCTAssertFalse([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryWhiteWins value:-42]);

  XCTAssertTrue([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryTie value:0]);
  XCTAssertFalse([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryTie value:42]);
  XCTAssertFalse([GoNodeAnnotation isValidEstimatedScoreSummary:GoScoreSummaryTie value:-42]);

  XCTAssertFalse([GoNodeAnnotation isValidEstimatedScoreSummary:(enum GoScoreSummary)42 value:42]);
}

@end
