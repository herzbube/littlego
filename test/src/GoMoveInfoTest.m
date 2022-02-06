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
#import "GoMoveInfoTest.h"

// Application includes
#import <go/GoMoveInfo.h>


@implementation GoMoveInfoTest

// -----------------------------------------------------------------------------
/// @brief Exercises the @e shortDescription property.
// -----------------------------------------------------------------------------
- (void) testShortDescription
{
  GoMoveInfo* moveInfo = [[[GoMoveInfo alloc] init] autorelease];
  XCTAssertNil(moveInfo.shortDescription);

  NSString* shortDescription = @"foo";
  NSString* expectedShortDescription = @"foo";
  moveInfo.shortDescription = shortDescription;
  XCTAssertEqual(moveInfo.shortDescription, expectedShortDescription);

  shortDescription = @"foo\nbar";
  expectedShortDescription = @"foo bar";
  moveInfo.shortDescription = shortDescription;
  XCTAssertEqualObjects(moveInfo.shortDescription, expectedShortDescription);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e longDescription property.
// -----------------------------------------------------------------------------
- (void) testLongDescription
{
  GoMoveInfo* moveInfo = [[[GoMoveInfo alloc] init] autorelease];
  XCTAssertNil(moveInfo.longDescription);

  NSString* longDescription = @"foo";
  NSString* expectedLongDescription = @"foo";
  moveInfo.longDescription = longDescription;
  XCTAssertEqual(moveInfo.longDescription, expectedLongDescription);

  longDescription = @"foo\nbar";
  expectedLongDescription = @"foo\nbar";
  moveInfo.longDescription = longDescription;
  XCTAssertEqualObjects(moveInfo.longDescription, expectedLongDescription);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e goBoardPositionValuation property.
// -----------------------------------------------------------------------------
- (void) testGoBoardPositionValuation
{
  GoMoveInfo* moveInfo = [[[GoMoveInfo alloc] init] autorelease];
  enum GoBoardPositionValuation expectedGoBoardPositionValuation = GoBoardPositionValuationNone;
  XCTAssertEqual(moveInfo.goBoardPositionValuation, expectedGoBoardPositionValuation);

  enum GoBoardPositionValuation goBoardPositionValuation = GoBoardPositionValuationVeryUnclear;
  expectedGoBoardPositionValuation = GoBoardPositionValuationVeryUnclear;
  moveInfo.goBoardPositionValuation = goBoardPositionValuation;
  XCTAssertEqual(moveInfo.goBoardPositionValuation, expectedGoBoardPositionValuation);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e goBoardPositionHotspotDesignation property.
// -----------------------------------------------------------------------------
- (void) testGoBoardPositionHotspotDesignation
{
  GoMoveInfo* moveInfo = [[[GoMoveInfo alloc] init] autorelease];
  enum GoBoardPositionHotspotDesignation expectedGoBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationNone;
  XCTAssertEqual(moveInfo.goBoardPositionHotspotDesignation, expectedGoBoardPositionHotspotDesignation);

  enum GoBoardPositionHotspotDesignation goBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationYesEmphasized;
  expectedGoBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationYesEmphasized;
  moveInfo.goBoardPositionHotspotDesignation = goBoardPositionHotspotDesignation;
  XCTAssertEqual(moveInfo.goBoardPositionHotspotDesignation, expectedGoBoardPositionHotspotDesignation);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e estimatedScoreSummary property.
// -----------------------------------------------------------------------------
- (void) testEstimatedScoreSummary
{
  GoMoveInfo* moveInfo = [[[GoMoveInfo alloc] init] autorelease];
  enum GoScoreSummary expectedEstimatedScoreSummary = GoScoreSummaryNone;
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e estimatedScoreValue property.
// -----------------------------------------------------------------------------
- (void) testEstimatedScoreValue
{
  GoMoveInfo* moveInfo = [[[GoMoveInfo alloc] init] autorelease];
  double expectedEstimatedScoreValue = 0.0;
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e setEstimatedScoreSummary:value:() method.
// -----------------------------------------------------------------------------
- (void) testSetEstimatedScoreSummaryValue
{
  GoMoveInfo* moveInfo = [[[GoMoveInfo alloc] init] autorelease];
  enum GoScoreSummary expectedEstimatedScoreSummary = GoScoreSummaryNone;
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  double expectedEstimatedScoreValue = 0.0;
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  // Tests using GoScoreSummaryBlackWins
  enum GoScoreSummary estimatedScoreSummary = GoScoreSummaryBlackWins;
  expectedEstimatedScoreSummary = GoScoreSummaryBlackWins;
  double estimatedScoreValue = 42;
  expectedEstimatedScoreValue = 42.0;
  bool success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = 0;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = -42;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  // Tests using GoScoreSummaryWhiteWins
  estimatedScoreSummary = GoScoreSummaryWhiteWins;
  expectedEstimatedScoreSummary = GoScoreSummaryWhiteWins;
  estimatedScoreValue = 42;
  expectedEstimatedScoreValue = 42.0;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = 0;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = -42;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  // Tests using GoScoreSummaryTie
  estimatedScoreSummary = GoScoreSummaryTie;
  expectedEstimatedScoreSummary = GoScoreSummaryTie;
  estimatedScoreValue = 0.0;
  expectedEstimatedScoreValue = 0.0;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = 42.0;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = -42;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertFalse(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  // Tests using GoScoreSummaryNone
  estimatedScoreSummary = GoScoreSummaryNone;
  expectedEstimatedScoreSummary = GoScoreSummaryNone;
  estimatedScoreValue = 0.0;
  expectedEstimatedScoreValue = 0.0;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = 42.0;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);

  estimatedScoreValue = -42;
  success = [moveInfo setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
  XCTAssertTrue(success);
  XCTAssertEqual(moveInfo.estimatedScoreSummary, expectedEstimatedScoreSummary);
  XCTAssertEqual(moveInfo.estimatedScoreValue, expectedEstimatedScoreValue);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e goMoveValuation property.
// -----------------------------------------------------------------------------
- (void) testGoMoveValuation
{
  GoMoveInfo* moveInfo = [[[GoMoveInfo alloc] init] autorelease];
  enum GoMoveValuation expectedGoMoveValuation = GoMoveValuationNone;
  XCTAssertEqual(moveInfo.goMoveValuation, expectedGoMoveValuation);

  enum GoMoveValuation goMoveValuation = GoMoveValuationVeryDoubtful;
  expectedGoMoveValuation = GoMoveValuationVeryDoubtful;
  moveInfo.goMoveValuation = goMoveValuation;
  XCTAssertEqual(moveInfo.goMoveValuation, expectedGoMoveValuation);
}

@end
