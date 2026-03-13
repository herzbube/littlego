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
#import "GoGameInfoRank.h"


@implementation GoGameInfoRank

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRank object with
/// #GoGameInfoRankDataTypeNone.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithDataType:GoGameInfoRankDataTypeNone
                      sgfString:nil
                       rankType:GoGameInfoRankTypeKyu
                           rank:30
                     ratingType:GoGameInfoRatingTypeUnspecified];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRank object with the supplied @a sgfString.
// -----------------------------------------------------------------------------
- (id) initWithSgfString:(NSString*)sgfString
{
  return [self initWithDataType:GoGameInfoRankDataTypeSgfString
                      sgfString:sgfString
                       rankType:GoGameInfoRankTypeKyu
                           rank:30
                     ratingType:GoGameInfoRatingTypeUnspecified];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRank object with the supplied @a rankType
/// @a rank and @a ratingType.
// -----------------------------------------------------------------------------
- (id) initWithRankType:(enum GoGameInfoRankType)rankType
                   rank:(long)rank
             ratingType:(enum GoGameInfoRatingType)ratingType
{
  return [self initWithDataType:GoGameInfoRankDataTypeStructuredData
                      sgfString:nil
                       rankType:rankType
                           rank:rank
                     ratingType:ratingType];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRank object with the supplied values.
///
/// @note This is the designated initializer of GoGameInfoRank.
// -----------------------------------------------------------------------------
- (id) initWithDataType:(enum GoGameInfoRankDataType)dataType
              sgfString:(NSString*)sgfString
               rankType:(enum GoGameInfoRankType)rankType
                   rank:(long)rank
             ratingType:(enum GoGameInfoRatingType)ratingType
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.dataType = dataType;
  self.sgfString = sgfString;
  self.rankType = rankType;
  self.rank = rank;
  self.ratingType = ratingType;

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

  self.dataType = [decoder decodeIntForKey:goGameInfoRankDataTypeKey];
  if (self.dataType == GoGameInfoRankDataTypeSgfString)
  {
    self.sgfString = [[decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoRankSgfStringKey] retain];
    self.rankType = GoGameInfoRankTypeKyu;
    self.rank = 30;
    self.ratingType = GoGameInfoRatingTypeUnspecified;
  }
  else if (self.dataType == GoGameInfoRankDataTypeStructuredData)
  {
    self.sgfString = nil;
    self.rankType = [decoder decodeIntForKey:goGameInfoRankRankTypeKey];
    self.rank = [decoder decodeInt64ForKey :goGameInfoRankRankKey];
    self.ratingType = [decoder decodeIntForKey:goGameInfoRankRatingTypeKey];
  }
  else
  {
    self.sgfString = nil;
    self.rankType = GoGameInfoRankTypeKyu;
    self.rank = 30;
    self.ratingType = GoGameInfoRatingTypeUnspecified;
  }

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
/// @brief Deallocates memory allocated by this GoGameInfoRank object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sgfString = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];

  [encoder encodeInt:self.dataType forKey:goGameInfoRankDataTypeKey];
  if (self.dataType == GoGameInfoRankDataTypeSgfString)
  {
    [encoder encodeObject:self.sgfString forKey:goGameInfoRankSgfStringKey];
  }
  else if (self.dataType == GoGameInfoRankDataTypeStructuredData)
  {
    [encoder encodeInt:self.rankType forKey:goGameInfoRankRankTypeKey];
    [encoder encodeInt64:self.rank forKey:goGameInfoRankRankKey];
    [encoder encodeInt:self.ratingType forKey:goGameInfoRankRatingTypeKey];
  }
}

@end
