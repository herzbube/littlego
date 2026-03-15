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
#import "GoGameInfoDates.h"


@implementation GoGameInfoDates

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoDates object with
/// #GoGameInfoDatesDataTypeNone.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithDataType:GoGameInfoDatesDataTypeNone
                      sgfString:nil
                 dateComponents:@[]];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoDates object with the supplied @a sgfString.
// -----------------------------------------------------------------------------
- (id) initWithSgfString:(NSString*)sgfString
{
  return [self initWithDataType:GoGameInfoDatesDataTypeSgfString
                      sgfString:sgfString
                 dateComponents:@[]];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoDates object with the supplied @a roundType
/// and @a roundNumber.
// -----------------------------------------------------------------------------
- (id) initWithDateComponents:(NSArray*)dateComponents
{
  return [self initWithDataType:GoGameInfoDatesDataTypeStructuredData
                      sgfString:nil
                 dateComponents:dateComponents];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfoDates object with the supplied values.
///
/// @note This is the designated initializer of GoGameInfoDates.
// -----------------------------------------------------------------------------
- (id) initWithDataType:(enum GoGameInfoDatesDataType)dataType
              sgfString:(NSString*)sgfString
         dateComponents:(NSArray*)dateComponents
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.dataType = dataType;
  self.sgfString = sgfString;
  self.dateComponents = dateComponents;

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

  self.dataType = [decoder decodeIntForKey:goGameInfoDatesDataTypeKey];
  if (self.dataType == GoGameInfoDatesDataTypeSgfString)
  {
    self.sgfString = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoDatesSgfStringKey];
    self.dateComponents = @[];
  }
  else if (self.dataType == GoGameInfoDatesDataTypeStructuredData)
  {
    self.sgfString = nil;
    self.dateComponents = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSArray class], [NSDateComponents class]]] forKey:goGameInfoDatesDateComponentsKey];
  }
  else
  {
    self.sgfString = nil;
    self.dateComponents = @[];
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
/// @brief Deallocates memory allocated by this GoGameInfoDates object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sgfString = nil;
  self.dateComponents = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];

  [encoder encodeInt:self.dataType forKey:goGameInfoDatesDataTypeKey];
  if (self.dataType == GoGameInfoDatesDataTypeSgfString)
  {
    [encoder encodeObject:self.sgfString forKey:goGameInfoDatesSgfStringKey];
  }
  else if (self.dataType == GoGameInfoDatesDataTypeStructuredData)
  {
    [encoder encodeObject:self.dateComponents forKey:goGameInfoDatesDateComponentsKey];
  }
}

#pragma mark - Public API - Property setters

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDateComponents:(NSArray*)newValue
{
  if (_dateComponents == newValue)
    return;

  // The sole purpose of this custom setter implementation is that we can
  // guarantee that the object we store is an NSArray, and not an NSMutableArray
  // or some other subclass of NSArray. The reason: initWithCoder decodes the
  // archived value assuming the encoded value was an NSArray. Without this
  // setter implementation, the archived value could be an NSMutableArray, in
  // which case it's not 100% clear whether the decoding would work.
  if (newValue)
    newValue = [NSArray arrayWithArray:newValue];

  if (_dateComponents)
    [_dateComponents release];

  _dateComponents = newValue;

  if (_dateComponents)
    [_dateComponents retain];
}

@end
