// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoMoveInfo.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoMoveInfo.
// -----------------------------------------------------------------------------
@interface GoMoveInfo()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoScoreSummary estimatedScoreSummary;
@property(nonatomic, assign, readwrite) double estimatedScoreValue;
//@}
@end


@implementation GoMoveInfo

// -----------------------------------------------------------------------------
/// @brief Initializes a GoMoveInfo object with default values.
///
/// @note This is the designated initializer of GoMoveInfo.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.shortDescription = nil;
  self.longDescription = nil;
  self.goBoardPositionValuation = GoBoardPositionValuationNone;
  self.goBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationNone;
  self.estimatedScoreSummary = GoScoreSummaryNone;
  self.estimatedScoreValue = 0.0;
  self.goMoveValuation = GoMoveValuationNone;

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

  self.shortDescription = [decoder decodeObjectForKey:goMoveInfoShortDescriptionKey];
  self.longDescription = [decoder decodeObjectForKey:goMoveInfoLongDescriptionKey];
  self.goBoardPositionValuation = [decoder decodeIntForKey:goMoveInfoGoBoardPositionValuationKey];
  self.goBoardPositionHotspotDesignation = [decoder decodeIntForKey:goMoveInfoGoBoardPositionHotspotDesignationKey];
  self.estimatedScoreSummary = [decoder decodeIntForKey:goMoveInfoEstimatedScoreSummaryKey];
  self.estimatedScoreValue = [decoder decodeDoubleForKey:goMoveInfoEstimatedScoreValueKey];
  self.goMoveValuation = [decoder decodeIntForKey:goMoveInfoGoMoveValuationKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoMoveInfo object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.shortDescription forKey:goMoveInfoShortDescriptionKey];
  [encoder encodeObject:self.longDescription forKey:goMoveInfoLongDescriptionKey];
  [encoder encodeInt:self.goBoardPositionValuation forKey:goMoveInfoGoBoardPositionValuationKey];
  [encoder encodeInt:self.goBoardPositionHotspotDesignation forKey:goMoveInfoGoBoardPositionHotspotDesignationKey];
  [encoder encodeInt:self.estimatedScoreSummary forKey:goMoveInfoEstimatedScoreSummaryKey];
  [encoder encodeDouble:self.estimatedScoreValue forKey:goMoveInfoEstimatedScoreValueKey];
  [encoder encodeInt:self.goMoveValuation forKey:goMoveInfoGoMoveValuationKey];
}

// -----------------------------------------------------------------------------
// Method is documented in header file.
// -----------------------------------------------------------------------------
- (bool) setEstimatedScoreSummary:(enum GoScoreSummary)goScoreSummary value:(double)goScoreValue
{
  switch (goScoreSummary)
  {
    case GoScoreSummaryNone:
      goScoreValue = 0.0;
      break;
    case GoScoreSummaryBlackWins:
    case GoScoreSummaryWhiteWins:
      if (goScoreValue <= 0.0)
        return false;
      break;
    case GoScoreSummaryTie:
      if (goScoreValue != 0.0)
        return false;
      break;
    default:
      DDLogError(@"%@: Unexpected go score summary %d", self, goScoreSummary);
      assert(0);
      return false;
  }

  self.estimatedScoreSummary = goScoreSummary;
  self.estimatedScoreValue = goScoreValue;

  return true;
}

// -----------------------------------------------------------------------------
// Property setter is documented in header file.
// -----------------------------------------------------------------------------
- (void) setShortDescription:(NSString*)shortDescription
{
  if (_shortDescription)
  {
    [_shortDescription autorelease];
    _shortDescription = nil;
  }

  if (shortDescription)
    _shortDescription = [[shortDescription stringByReplacingOccurrencesOfString:@"\n" withString:@" "] retain];
}

@end
