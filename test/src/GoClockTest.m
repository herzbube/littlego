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
#import "GoClockTest.h"

// Application includes
#import <go/GoClock.h>


@implementation GoClockTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoClock object.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoClock* clock = [[[GoClock alloc] init] autorelease];
  XCTAssertEqual(clock.state, GoClockStateStopped);
  XCTAssertEqual(clock.suspendedReason, GoClockSuspendedReasonNotSuspended);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the start() method.
// -----------------------------------------------------------------------------
- (void) testStart
{
  GoClock* clock = [[[GoClock alloc] init] autorelease];

  [clock start];
  XCTAssertEqual(clock.state, GoClockStateStarted);
  XCTAssertEqual(clock.suspendedReason, GoClockSuspendedReasonNotSuspended);

  XCTAssertThrowsSpecificNamed([clock start],
                               NSException, NSInternalInconsistencyException, @"clock is not stopped (started)");

  [clock suspend:GoClockSuspendedReasonUserAction];
  XCTAssertThrowsSpecificNamed([clock start],
                               NSException, NSInternalInconsistencyException, @"clock is not stopped (suspended)");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the suspend:() method.
// -----------------------------------------------------------------------------
- (void) testSuspend
{
  GoClock* clock = [[[GoClock alloc] init] autorelease];

  XCTAssertThrowsSpecificNamed([clock suspend:GoClockSuspendedReasonUserAction],
                               NSException, NSInternalInconsistencyException, @"clock is not started (stopped)");

  [clock start];
  NSTimeInterval sleepTimeInSeconds = 0.1;
  [NSThread sleepForTimeInterval:sleepTimeInSeconds];

  double elapsedTimeInSeconds = [clock suspend:GoClockSuspendedReasonUserAction];
  XCTAssertTrue(elapsedTimeInSeconds >= sleepTimeInSeconds);
  XCTAssertEqual(clock.state, GoClockStateSuspended);
  XCTAssertEqual(clock.suspendedReason, GoClockSuspendedReasonUserAction);

  XCTAssertThrowsSpecificNamed([clock suspend:GoClockSuspendedReasonUserAction],
                               NSException, NSInternalInconsistencyException, @"clock is not started (suspended)");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the resume() method.
// -----------------------------------------------------------------------------
- (void) testResume
{
  GoClock* clock = [[[GoClock alloc] init] autorelease];

  XCTAssertThrowsSpecificNamed([clock resume],
                               NSException, NSInternalInconsistencyException, @"clock is not suspended (stopped)");

  [clock start];
  XCTAssertThrowsSpecificNamed([clock resume],
                               NSException, NSInternalInconsistencyException, @"clock is not suspended (started)");

  [clock suspend:GoClockSuspendedReasonUserAction];
  [clock resume];
  XCTAssertEqual(clock.state, GoClockStateStarted);
  XCTAssertEqual(clock.suspendedReason, GoClockSuspendedReasonNotSuspended);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the stop() method.
// -----------------------------------------------------------------------------
- (void) testStop
{
  GoClock* clock = [[[GoClock alloc] init] autorelease];

  XCTAssertThrowsSpecificNamed([clock stop],
                               NSException, NSInternalInconsistencyException, @"clock is not started or suspended");

  [clock start];
  NSTimeInterval sleepTimeInSeconds = 0.1;
  [NSThread sleepForTimeInterval:sleepTimeInSeconds];

  double elapsedTimeInSeconds = [clock stop];
  XCTAssertTrue(elapsedTimeInSeconds >= sleepTimeInSeconds);
  XCTAssertEqual(clock.state, GoClockStateStopped);
  XCTAssertEqual(clock.suspendedReason, GoClockSuspendedReasonNotSuspended);

  [clock start];
  [NSThread sleepForTimeInterval:sleepTimeInSeconds];
  [clock suspend:GoClockSuspendedReasonUserAction];
  [NSThread sleepForTimeInterval:sleepTimeInSeconds];
  elapsedTimeInSeconds = [clock stop];
  XCTAssertEqual(elapsedTimeInSeconds, 0.0);
  XCTAssertEqual(clock.state, GoClockStateStopped);
  XCTAssertEqual(clock.suspendedReason, GoClockSuspendedReasonNotSuspended);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the restart() method.
// -----------------------------------------------------------------------------
- (void) testRestart
{
  GoClock* clock = [[[GoClock alloc] init] autorelease];

  XCTAssertThrowsSpecificNamed([clock restart],
                               NSException, NSInternalInconsistencyException, @"clock is not started or suspended");

  [clock start];
  NSTimeInterval sleepTimeInSeconds = 0.1;
  [NSThread sleepForTimeInterval:sleepTimeInSeconds];

  double elapsedTimeInSeconds = [clock restart];
  XCTAssertTrue(elapsedTimeInSeconds >= sleepTimeInSeconds);
  XCTAssertEqual(clock.state, GoClockStateStarted);
  XCTAssertEqual(clock.suspendedReason, GoClockSuspendedReasonNotSuspended);

  [clock suspend:GoClockSuspendedReasonUserAction];
  [NSThread sleepForTimeInterval:sleepTimeInSeconds];
  elapsedTimeInSeconds = [clock restart];
  XCTAssertEqual(elapsedTimeInSeconds, 0.0);
  XCTAssertEqual(clock.state, GoClockStateStarted);
  XCTAssertEqual(clock.suspendedReason, GoClockSuspendedReasonNotSuspended);
}

@end
