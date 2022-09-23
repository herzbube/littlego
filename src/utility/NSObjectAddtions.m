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


// Project includes
#import "NSObjectAddtions.h"


@implementation NSObject(NSObjectAddtions)

// -----------------------------------------------------------------------------
/// @brief Schedules execution of the block @a callback on the main thread
/// after the specified @a delayInSeconds has elapsed, then control immediately
/// returns to the caller before @a callback is actually executed. Does nothing
/// if @a callback is @e nil.
///
/// Block execution is asynchronous even if @a delayInSeconds is 0 (zero) and
/// this method is invoked on the main thread itself.
///
/// @note This method performs the same service as the Foundation framework
/// methods performSelectorOnMainThread:withObject:waitUntilDone:() and
/// performSelector:withObject:afterDelay:(), but for blocks. Because the
/// implementation uses Grand Central Dispatch (GCD) there are subtle
/// differences in timing between executing a block with this method and
/// executing a selector with one of the above-mentioned Foundation framework
/// methods.
///
/// For details on GCD see
/// https://developer.apple.com/documentation/dispatch?language=objc
// -----------------------------------------------------------------------------
- (void) performBlockOnMainThread:(void(^)(void))callback afterDelay:(double)delayInSeconds
{
  if (! callback)
    return;

  dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(when, dispatch_get_main_queue(), callback);
}

@end
