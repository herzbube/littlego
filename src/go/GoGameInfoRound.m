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
#import "GoGameInfoRound.h"
#import "../utility/ExceptionUtility.h"


@implementation GoGameInfoRound

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRound object with
/// #GoGameInfoRoundDataTypeNone.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithDataType:GoGameInfoRoundDataTypeNone
                      sgfString:nil
                      roundType:nil
                    roundNumber:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRound object with the supplied @a sgfString.
// -----------------------------------------------------------------------------
- (id) initWithSgfString:(NSString*)sgfString
{
  return [self initWithDataType:GoGameInfoRoundDataTypeSgfString
                      sgfString:sgfString
                      roundType:nil
                    roundNumber:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRound object with the supplied @a roundType
/// and @a roundNumber.
// -----------------------------------------------------------------------------
- (id) initWithRoundType:(NSString*)roundType roundNumber:(NSString*)roundNumber
{
  return [self initWithDataType:GoGameInfoRoundDataTypeStructuredData
                      sgfString:nil
                      roundType:roundType
                    roundNumber:roundNumber];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoRound object with the supplied values.
///
/// @note This is the designated initializer of GoGameInfoRound.
// -----------------------------------------------------------------------------
- (id) initWithDataType:(enum GoGameInfoRoundDataType)dataType
              sgfString:(NSString*)sgfString
              roundType:(NSString*)roundType
            roundNumber:(NSString*)roundNumber
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.dataType = dataType;
  self.sgfString = sgfString;
  self.roundType = roundType;
  self.roundNumber = roundNumber;

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

  self.dataType = [decoder decodeIntForKey:goGameInfoRoundDataTypeKey];
  if (self.dataType == GoGameInfoRoundDataTypeSgfString)
  {
    self.sgfString = [[decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoRoundSgfStringKey] retain];
  }
  else if (self.dataType == GoGameInfoRoundDataTypeStructuredData)
  {
    self.roundType = [[decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoRoundRoundTypeKey] retain];
    self.roundNumber = [[decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoRoundRoundNumberKey] retain];
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
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];

  [encoder encodeInt:self.dataType forKey:goGameInfoRoundDataTypeKey];
  if (self.dataType == GoGameInfoRoundDataTypeSgfString)
  {
    [encoder encodeObject:self.sgfString forKey:goGameInfoRoundSgfStringKey];
  }
  else if (self.dataType == GoGameInfoRoundDataTypeStructuredData)
  {
    [encoder encodeObject:self.roundType forKey:goGameInfoRoundRoundTypeKey];
    [encoder encodeObject:self.roundNumber forKey:goGameInfoRoundRoundNumberKey];
  }
}

@end
