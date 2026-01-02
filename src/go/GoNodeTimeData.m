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
#import "GoNodeTimeData.h"

// TODO xxx Add unit tests


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeTimeData.
// -----------------------------------------------------------------------------
@interface GoNodeTimeData()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) bool isTimeDataForBlackPlayer;
//@}
@end


@implementation GoNodeTimeData

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoNodeTimeData object with zero values.
/// @a isTimeDataForBlackPlayer indicates whether the object holds data for the
/// black or the white player.
///
/// @note This is the designated initializer of GoNodeTimeData.
// -----------------------------------------------------------------------------
- (id) initWithIsTimeDataForBlackPlayer:(bool)isTimeDataForBlackPlayer
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.isTimeDataForBlackPlayer = isTimeDataForBlackPlayer;
  self.isRemainingTimeAbsoluteTime = false;
  self.remainingTimeInSeconds = 0;
  self.remainingNumberOfMoves = 0;
  self.remainingNumberOfPeriods = 0;

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

  self.isTimeDataForBlackPlayer = [decoder decodeBoolForKey:goNodeTimeDataIsTimeDataForBlackPlayerKey];
  self.isRemainingTimeAbsoluteTime = [decoder decodeBoolForKey:goNodeTimeDataIsRemainingTimeAbsoluteTimeKey];
  self.remainingTimeInSeconds = [decoder decodeDoubleForKey:goNodeTimeDataRemainingTimeInSecondsKey];
  self.remainingNumberOfMoves = [decoder decodeIntForKey:goNodeTimeDataRemainingNumberOfMovesKey];
  self.remainingNumberOfPeriods = [decoder decodeIntForKey:goNodeTimeDataRemainingNumberOfPeriodsKey];

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
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeBool:self.isTimeDataForBlackPlayer forKey:goNodeTimeDataIsTimeDataForBlackPlayerKey];
  [encoder encodeBool:self.isRemainingTimeAbsoluteTime forKey:goNodeTimeDataIsRemainingTimeAbsoluteTimeKey];
  [encoder encodeDouble:self.remainingTimeInSeconds forKey:goNodeTimeDataRemainingTimeInSecondsKey];
  [encoder encodeInt:self.remainingNumberOfMoves forKey:goNodeTimeDataRemainingNumberOfMovesKey];
  [encoder encodeInt:self.remainingNumberOfPeriods forKey:goNodeTimeDataRemainingNumberOfPeriodsKey];
}

#pragma mark - NSObject overrides

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoNodeTimeData object.
///
/// This method is invoked when GoNodeTimeData needs to be represented as a
/// string, i.e. by NSLog, or when the debugger command "po" is used on the
/// object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoNodeTimeData(%p): isTimeDataForBlackPlayer = %d, isRemainingTimeAbsoluteTime = %d, remainingTimeInSeconds = %f, remainingNumberOfMoves = %d, remainingNumberOfPeriods = %d", self, _isTimeDataForBlackPlayer, _isRemainingTimeAbsoluteTime, _remainingTimeInSeconds, _remainingNumberOfMoves, _remainingNumberOfPeriods];
}

@end
