// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LongRunningActionCounter.
// -----------------------------------------------------------------------------
@interface LongRunningActionCounter()
/// @name Private properties
//@{
@property(atomic, assign) bool deliveringNotification;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(atomic, assign, readwrite) int counter;
//@}
@end


@implementation LongRunningActionCounter

// -----------------------------------------------------------------------------
/// @brief Shared instance of LongRunningActionCounter.
// -----------------------------------------------------------------------------
static LongRunningActionCounter* sharedCounter = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared LongRunningActionCounter object.
// -----------------------------------------------------------------------------
+ (LongRunningActionCounter*) sharedCounter
{
  if (! sharedCounter)
    sharedCounter = [[LongRunningActionCounter alloc] init];
  return sharedCounter;
}

// -----------------------------------------------------------------------------
/// @brief Releases the shared LongRunningActionCounter object.
// -----------------------------------------------------------------------------
+ (void) releaseSharedCounter
{
  if (sharedCounter)
  {
    [sharedCounter release];
    sharedCounter = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Initializes a LongRunningActionCounter object.
///
/// @note This is the designated initializer of LongRunningActionCounter.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.counter = 0;
  self.deliveringNotification = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Increments the long-running actions counter.
///
/// Posts #longRunningActionStarts in the main thread context if the counter is
/// incremented to 1.
///
/// Raises an @e NSGenericException if this method is invoked while
/// LongRunningActionCounter is delivering a notification.
// -----------------------------------------------------------------------------
- (void) increment
{
  [self throwIfDeliveringNotification];
  self.counter++;
  if (1 == self.counter)
  {
    [self performSelector:@selector(postLongRunningNotificationOnMainThread:)
                 onThread:[NSThread mainThread]
               withObject:longRunningActionStarts
            waitUntilDone:YES];
  }
}

// -----------------------------------------------------------------------------
/// @brief Decrements the long-running actions counter.
///
/// Posts #longRunningActionEnds in the main thread context if the counter is
/// decremented to 0.
///
/// Raises an @e NSRangeException if an attempt is made to decrement the counter
/// to below 0.
///
/// Raises an @e NSGenericException if this method is invoked while
/// LongRunningActionCounter is delivering a notification.
// -----------------------------------------------------------------------------
- (void) decrement
{
  [self throwIfDeliveringNotification];
  [self throwIfCounterIsZero];
  self.counter--;
  if (0 == self.counter)
  {
    [self performSelector:@selector(postLongRunningNotificationOnMainThread:)
                 onThread:[NSThread mainThread]
               withObject:longRunningActionEnds
            waitUntilDone:YES];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper. Is invoked in the context of the main thread.
// -----------------------------------------------------------------------------
- (void) postLongRunningNotificationOnMainThread:(NSString*)notificationName
{
  self.deliveringNotification = true;
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
  self.deliveringNotification = false;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) throwIfDeliveringNotification
{
  if (self.deliveringNotification)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Cannot start or stop long-running action while delivering a notification"];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) throwIfCounterIsZero
{
  if (0 == self.counter)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Cannot decrement long-running actions counter, it is already 0"];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

@end
