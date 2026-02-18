// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNodeTimeDataTest.h"

// Application includes
#import <go/GoNodeTimeData.h>


@implementation GoNodeTimeDataTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoNodeTimeData object.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoNodeTimeData* nodeTimeData = [[[GoNodeTimeData alloc] init] autorelease];
  XCTAssertTrue(nodeTimeData.isTimeDataForBlackPlayer);
  XCTAssertTrue(nodeTimeData.isRemainingTimeAbsoluteTime);
  XCTAssertEqual(nodeTimeData.remainingTimeInSeconds, 0.0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfMoves, 0);
  XCTAssertEqual(nodeTimeData.remainingNumberOfPeriods, 0);
}

@end
