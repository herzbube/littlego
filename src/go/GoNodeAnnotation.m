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
#import "GoNodeAnnotation.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeAnnotation.
// -----------------------------------------------------------------------------
@interface GoNodeAnnotation()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoScoreSummary estimatedScoreSummary;
@property(nonatomic, assign, readwrite) double estimatedScoreValue;
//@}
@end


@implementation GoNodeAnnotation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoNodeAnnotation object with default values.
///
/// @note This is the designated initializer of GoNodeAnnotation.
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

  self.shortDescription = [decoder decodeObjectForKey:goNodeAnnotationShortDescriptionKey];
  self.longDescription = [decoder decodeObjectForKey:goNodeAnnotationLongDescriptionKey];
  self.goBoardPositionValuation = [decoder decodeIntForKey:goNodeAnnotationGoBoardPositionValuationKey];
  self.goBoardPositionHotspotDesignation = [decoder decodeIntForKey:goNodeAnnotationGoBoardPositionHotspotDesignationKey];
  self.estimatedScoreSummary = [decoder decodeIntForKey:goNodeAnnotationEstimatedScoreSummaryKey];
  self.estimatedScoreValue = [decoder decodeDoubleForKey:goNodeAnnotationEstimatedScoreValueKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoNodeAnnotation object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.shortDescription = nil;
  self.longDescription = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.shortDescription forKey:goNodeAnnotationShortDescriptionKey];
  [encoder encodeObject:self.longDescription forKey:goNodeAnnotationLongDescriptionKey];
  [encoder encodeInt:self.goBoardPositionValuation forKey:goNodeAnnotationGoBoardPositionValuationKey];
  [encoder encodeInt:self.goBoardPositionHotspotDesignation forKey:goNodeAnnotationGoBoardPositionHotspotDesignationKey];
  [encoder encodeInt:self.estimatedScoreSummary forKey:goNodeAnnotationEstimatedScoreSummaryKey];
  [encoder encodeDouble:self.estimatedScoreValue forKey:goNodeAnnotationEstimatedScoreValueKey];
}

// -----------------------------------------------------------------------------
// Method is documented in header file.
// -----------------------------------------------------------------------------
- (bool) setEstimatedScoreSummary:(enum GoScoreSummary)goScoreSummary value:(double)goScoreValue
{
  if (! [GoNodeAnnotation isValidEstimatedScoreSummary:goScoreSummary value:goScoreValue])
    return false;

  if (goScoreSummary == GoScoreSummaryNone)
    goScoreValue = 0.0f;

  self.estimatedScoreSummary = goScoreSummary;
  self.estimatedScoreValue = goScoreValue;

  return true;
}

// -----------------------------------------------------------------------------
// Method is documented in header file.
// -----------------------------------------------------------------------------
+ (bool) isValidEstimatedScoreSummary:(enum GoScoreSummary)goScoreSummary value:(double)goScoreValue
{
  switch (goScoreSummary)
  {
    case GoScoreSummaryNone:
      return true;
    case GoScoreSummaryBlackWins:
    case GoScoreSummaryWhiteWins:
      return (goScoreValue > 0.0f);
    case GoScoreSummaryTie:
      return (goScoreValue == 0.0f);
    default:
      DDLogError(@"%@: Unexpected go score summary %d", self, goScoreSummary);
      assert(0);
      return false;
  }
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
