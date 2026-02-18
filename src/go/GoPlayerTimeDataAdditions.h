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


// Project includes
#import "GoPlayerTimeData.h"

// Forward declarations
@class GoTimeSystem;


// -----------------------------------------------------------------------------
/// @brief The GoPlayerTimeDataAdditions category enhances GoPlayerTimeData by
/// adding methods for unit testing support.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoPlayerTimeData(GoPlayerTimeDataAdditions)

/// @name Unit testing
//@{
- (GoTimeSettings*) goTimeSettings;
- (void) setIsRemainingTimeAbsoluteTime:(bool)isRemainingTimeAbsoluteTime;
- (void) setRemainingTimeInSeconds:(double)remainingTimeInSeconds;
- (void) setRemainingNumberOfMoves:(unsigned long)remainingNumberOfMoves;
- (void) setRemainingNumberOfPeriods:(unsigned long)remainingNumberOfPeriods;
- (enum GoPeriodDurationElapsedResultType) deductElapsedTimeInSeconds:(double)elapsedTimeInSeconds;
- (bool) performPeriodResetIfNecessary:(GoTimeSystem*)timeSystem;
//@}

@end
