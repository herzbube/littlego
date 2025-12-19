// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoClock.h"
#import "../utility/ExceptionUtility.h"

// TODO xxx Add unit tests

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoClock.
// -----------------------------------------------------------------------------
@interface GoClock()
/// @brief Timestamp when the clock was started.
@property(nonatomic, retain) NSDate* startDate;
/// @brief Every time the clock is suspended the elapsed time since the clock
/// was started is calculated and added to this property. If the clock is
/// suspended multiple times, this property stores the cumulated elapsed times.
@property(nonatomic, assign) double elapsedTimeInSeconds;
@end


@implementation GoClock

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoClock object with state #GoClockStateStopped.
///
/// @note This is the designated initializer of GoClock.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.state = GoClockStateStopped;
  self.suspendedReason = GoClockSuspendedReasonNotSuspended;
  self.startDate = nil;
  self.elapsedTimeInSeconds = 0.0;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;

  self.state = [decoder decodeIntForKey:goClockStateKey];
  self.suspendedReason = [decoder decodeIntForKey:goClockSuspendedReasonKey];
  // TODO xxx don't restore the start date - see comment in encodeWithCoder:()
  self.startDate = [decoder decodeObjectOfClass:[NSDate class] forKey:goClockStartDateKey];
  self.elapsedTimeInSeconds = [decoder decodeDoubleForKey:goClockElapsedTimeInSecondsKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoClock object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.startDate = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeInt:self.state forKey:goClockStateKey];
  [encoder encodeInt:self.suspendedReason forKey:goClockSuspendedReasonKey];
  // TODO xxx There's no point in placing the start date in the archive: if the
  // app is suspended, we expect that this clock is also suspended; if the app
  // crashes, we don't want to restore the start date when the app is started
  // the next time, because any amount of time could have elapsed since the
  // crash
  [encoder encodeObject:self.startDate forKey:goClockStartDateKey];
  [encoder encodeDouble:self.elapsedTimeInSeconds forKey:goClockElapsedTimeInSecondsKey];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Starts the clock when it is stopped.
///
/// Raises an @e NSInternalInconsistencyException if the clock is not stopped,
/// i.e. if it is started or suspended.
// -----------------------------------------------------------------------------
- (void) start;
{
  NSString* operationName = @"start";
  [self throwIfClockDoesNotHaveState:GoClockStateStopped operationName:operationName];

  [self startUnconditionally];
}

// -----------------------------------------------------------------------------
/// @brief Suspends the clock when it is started, because of @a reason.
///
/// Keeps an internal record of how much time has elapsed since the clock was
/// last started. If the clock is suspended multiple times, the elapsed times
/// are cumulated.
///
/// Raises an @e NSInternalInconsistencyException if the clock is not started,
/// i.e. if it is stopped or suspended.
// -----------------------------------------------------------------------------
- (void) suspend:(enum GoClockSuspendedReason)reason
{
  NSString* operationName = @"suspend";
  [self throwIfClockDoesNotHaveState:GoClockStateStarted operationName:operationName];

  double totalElapsedTimeInSeconds = [self totalElapsedTimeInSecondsSinceClockWasStarted:operationName];

  self.state = GoClockStateSuspended;
  self.suspendedReason = reason;
  self.startDate = nil;
  self.elapsedTimeInSeconds = totalElapsedTimeInSeconds;
}

// -----------------------------------------------------------------------------
/// @brief Resumes the clock when it is suspended.
///
/// Raises an @e NSInternalInconsistencyException if the clock is not suspended,
/// i.e. if it is stopped or started.
// -----------------------------------------------------------------------------
- (void) resume
{
  NSString* operationName = @"resume";
  [self throwIfClockDoesNotHaveState:GoClockStateSuspended operationName:operationName];

  self.state = GoClockStateStarted;
  self.suspendedReason = GoClockSuspendedReasonNotSuspended;
  self.startDate = [NSDate now];
}

// -----------------------------------------------------------------------------
/// @brief Stops the clock when it is started or suspended. Returns the time in
/// seconds that has elapsed since the clock was last started (excluding time
/// during which the clock was suspended).
///
/// Raises an @e NSInternalInconsistencyException if the clock is not started
/// or suspended, i.e. if it is stopped.
// -----------------------------------------------------------------------------
- (double) stop
{
  NSString* operationName = @"stop";
  [self throwIfClockHasState:GoClockStateStopped operationName:operationName];

  double totalElapsedTimeInSeconds = [self totalElapsedTimeInSecondsSinceClockWasStarted:operationName];

  self.state = GoClockStateStopped;
  self.suspendedReason = GoClockSuspendedReasonNotSuspended;
  self.startDate = nil;
  self.elapsedTimeInSeconds = 0;

  return totalElapsedTimeInSeconds;
}

// -----------------------------------------------------------------------------
/// @brief Restarts the clock when it is started or suspended. Returns the time
/// in seconds that has elapsed since the clock was last started (excluding time
/// during which the clock was suspended).
///
/// This method is a convenience method, equivalent to invoking stop() and
/// then start().
///
/// Raises an @e NSInternalInconsistencyException if the clock is not started or
/// suspended, i.e. if it is stopped.
// -----------------------------------------------------------------------------
- (double) restart
{
  NSString* operationName = @"restart";
  [self throwIfClockHasState:GoClockStateStopped operationName:operationName];

  double totalElapsedTimeInSeconds = [self totalElapsedTimeInSecondsSinceClockWasStarted:operationName];

  [self startUnconditionally];

  return totalElapsedTimeInSeconds;
}

// -----------------------------------------------------------------------------
/// @brief Property getter implementation. See property documentation in header
/// file.
// -----------------------------------------------------------------------------
- (double) totalElapsedTimeInSecondsSinceClockWasStarted
{
  if (self.state == GoClockStateStopped)
    return 0.0;

  NSString* operationName = @"totalElapsedTimeInSecondsSinceClockWasStarted";
  return [self totalElapsedTimeInSecondsSinceClockWasStarted:operationName];
}

#pragma mark - Private helper methods

// -----------------------------------------------------------------------------
/// @brief Starts the clock regardless of what its previous state was and
/// forgets about any elapsed time that was recorded by previous suspend
/// operations.
// -----------------------------------------------------------------------------
- (void) startUnconditionally
{
  self.state = GoClockStateStarted;
  self.suspendedReason = GoClockSuspendedReasonNotSuspended;
  self.startDate = [NSDate now];
  self.elapsedTimeInSeconds = 0;
}

// -----------------------------------------------------------------------------
/// @brief Calculates and returns the time in seconds that has elapsed since the
/// clock was last started (excluding time during which the clock was
/// suspended). The calculation is performed on behalf of the operation named
/// @a operationName.
// -----------------------------------------------------------------------------
- (double) totalElapsedTimeInSecondsSinceClockWasStarted:(NSString*)operationName
{
  double totalElapsedTimeInSeconds = self.elapsedTimeInSeconds;

  if (self.state == GoClockStateStarted)
  {
    [self throwIfStartDateIsMissing:operationName];
    totalElapsedTimeInSeconds += [[NSDate now] timeIntervalSinceDate:self.startDate];
  }

  return totalElapsedTimeInSeconds;
}

// -----------------------------------------------------------------------------
/// @brief Raises an @e NSInternalInconsistencyException if self.state is
/// not @a state. The exception is raised on behalf of the operation named
/// @a operationName.
// -----------------------------------------------------------------------------
- (void) throwIfClockDoesNotHaveState:(enum GoClockState)expectedState
                        operationName:(NSString*)operationName
{
  if (self.state == expectedState)
    return;

  NSString* expectedStateAsString = [GoClock stringForState:expectedState];
  NSString* actualStateAsString = [GoClock stringForState:self.state];
  NSString* errorMessage = [NSString stringWithFormat:@"%@ failed, clock expected to be %@, but is %@", operationName, expectedStateAsString, actualStateAsString];
  [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
}

// -----------------------------------------------------------------------------
/// @brief Raises an @e NSInternalInconsistencyException if self.state is
/// @a state. The exception is raised on behalf of the operation named
/// @a operationName.
// -----------------------------------------------------------------------------
- (void) throwIfClockHasState:(enum GoClockState)unexpectedState
                operationName:(NSString*)operationName
{
  if (self.state != unexpectedState)
    return;

  NSString* unexpectedStateAsString = [GoClock stringForState:unexpectedState];
  NSString* errorMessage = [NSString stringWithFormat:@"%@ failed, clock expected not to be %@, but is %@", operationName, unexpectedStateAsString, unexpectedStateAsString];
  [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
}

// -----------------------------------------------------------------------------
/// @brief Raises an @e NSInternalInconsistencyException if self.startDate is
/// @e nil. The exception is raised on behalf of the operation named
/// @a operationName.
// -----------------------------------------------------------------------------
- (void) throwIfStartDateIsMissing:(NSString*)operationName
{
  if (self.startDate)
    return;

  NSString* errorMessage = [NSString stringWithFormat:@"%@ failed, clock is running but start date is missing", operationName];
  [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a state.
///
/// Raises an @e NSInternalInconsistencyException if @a state is not an element
/// of the enumeration #GoClockState.
// -----------------------------------------------------------------------------
+ (NSString*) stringForState:(enum GoClockState)state
{
  switch (state)
  {
    case GoClockStateStopped:
      return @"stopped";
    case GoClockStateStarted:
      return @"started";
    case GoClockStateSuspended:
      return @"suspended";
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Invalid clock state %d"
                                                  argumentValue:state];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
      return @"";
  }
}

@end
