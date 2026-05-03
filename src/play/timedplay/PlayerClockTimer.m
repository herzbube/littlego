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
#import "PlayerClockTimer.h"
#import "../../utility/ExceptionUtility.h"


static double timerIntervalOneSecond = 1.0;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayerClockTimer.
// -----------------------------------------------------------------------------
@interface PlayerClockTimer()
@property(nonatomic, assign) id<PlayerClockTimerDelegate> delegate;
@property(nonatomic, retain) NSTimer* timer;
@end


@implementation PlayerClockTimer

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayerClockTimer object with @a delegate.
///
/// @note This is the designated initializer of PlayerClockTimer.
// -----------------------------------------------------------------------------
- (id) initWithDelegate:(id<PlayerClockTimerDelegate>)delegate
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.delegate = delegate;
  self.timer = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayerClockTimer object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;

  // dealloc can never be invoked if an NSTimer is still scheduled, because
  // NSTimer retains its target, i.e. this PlayerClockTimer. So we cannot
  // invalidate the timer here. Also setting self.timer to nil is pointless,
  // that is already done when the timer fires. In effect, to be deallocated
  // we need an outside source to invoke invalidateTimerIfOneIsScheduled().

  // Despite the above, we set self.timer to nil here to silence a warning
  // from Xcode Analyze.
  self.timer = nil;

  [super dealloc];
}

#pragma mark - Public interface

// -----------------------------------------------------------------------------
/// @brief Schedules a timer. While this method executes, PlayerClockTimer
/// invokes timeInSecondsUntilNextFullSecond:() on its delegate to obtain the
/// time when the timer should fire.
///
/// Raises an @e NSInternalInconsistencyException if another timer is already
/// running.
// -----------------------------------------------------------------------------
- (void) scheduleTimer
{
  @synchronized(self)
  {
    if (self.timer)
    {
      NSString* errorMessage = @"Failed to schedule timer, another timer is already running";
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }

    // We want to make sure that the timer is scheduled on the main thread so
    // that the timer also fires on the main thread, and time data updates are
    // done (including posting notifications) on the main thread.
    if ([NSThread currentThread] != [NSThread mainThread])
    {
      [self performSelectorOnMainThread:@selector(scheduleTimer)
                             withObject:nil
                          waitUntilDone:YES];
      return;
    }

    // Asking the delegate for the time until the next full second helps us
    // with "catching up" if a timer fires with a delay. See the class
    // documentation for more information on why we implement this "catch up"
    // mechanism.
    double timerInterval = [self.delegate timeInSecondsUntilNextFullSecond:self];

    // Ideally we would like to get an unsigned value because a value less than
    // zero logically does not make sense. Because there is no such thing as
    // "unsigned double", we keep the less-than-zero check to cover all possible
    // cases. Because we don't want to have yet another branching point in our
    // time critical code, we conflate the check with the equal-to-zero check.
    if (timerInterval <= 0)
      timerInterval = timerIntervalOneSecond;

    self.timer = [NSTimer scheduledTimerWithTimeInterval:timerInterval
                                                  target:self
                                                selector:@selector(timerHasElapsed)
                                                userInfo:nil
                                                 repeats:NO];
  }
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the currently scheduled timer. Does nothing if no timer
/// is scheduled. This method guarantees that after it returns no further timers
/// will fire.
///
/// This method blocks if a timer is currently being scheduled with
/// scheduleTimer(). Once scheduleTimer() returns, this method will immediately
/// invalidate the timer that was just scheduled.
///
/// This method also blocks if a timer currently fires. Once the timer firing
/// handler has finished executing, this method will immediately invalidate
/// the timer that the firing handler scheduled (if any).
// -----------------------------------------------------------------------------
- (void) invalidateTimerIfOneIsScheduled
{
  @synchronized(self)
  {
    if (! self.timer)
      return;

    // The timer must be invalidated on the same thread where it was scheduled
    if ([NSThread currentThread] != [NSThread mainThread])
    {
      [self performSelectorOnMainThread:@selector(invalidateTimerIfOneIsScheduled)
                             withObject:nil
                          waitUntilDone:YES];
      return;
    }

    [self.timer invalidate];
    self.timer = nil;
  }
}

#pragma mark - Timer handling

// -----------------------------------------------------------------------------
/// @brief Is invoked when the scheduled timer fires.
// -----------------------------------------------------------------------------
- (void) timerHasElapsed
{
  @synchronized(self)
  {
    // The timer was invalidated at the same time it was firing. This means we
    // should not continue.
    //
    // Since timer invalidation occurs on the main thread, and the timer also
    // fires on the main thread, the scenario of the two events occurring
    // simultaneously may be impossible. But we cannot rely on that because we
    // don't know the internals of the Foundation framework, and even if we did,
    // those internals might change.
    if (! self.timer)
      return;
    self.timer = nil;

    bool shouldScheduleNextTimer = [self.delegate timerDidFire:self];

    if (shouldScheduleNextTimer)
      [self scheduleTimer];
  }
}

@end
