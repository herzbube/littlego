// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoVertex.
// -----------------------------------------------------------------------------
@interface GoVertex()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSString* string;
@property(nonatomic, assign, readwrite) struct GoVertexNumeric numeric;
@property(nonatomic, retain, readwrite) NSString* letterAxisCompound;
@property(nonatomic, retain, readwrite) NSString* numberAxisCompound;
//@}
@end


@implementation GoVertex

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoVertex instance from the numeric
/// compounds in @a numericValue.
///
/// Raises an @e NSRangeException if one of the vertex compounds stored in
/// @a numericValue is outside the supported range of values.
// -----------------------------------------------------------------------------
+ (GoVertex*) vertexFromNumeric:(struct GoVertexNumeric)numericValue
{
  if (numericValue.x < 1 || numericValue.x > 19 || numericValue.y < 1 || numericValue.y > 19)
  {
    NSString* errorMessage = @"Numeric vertex is invalid";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  unichar charA = [@"A" characterAtIndex:0];
  unichar charH = [@"H" characterAtIndex:0];
  unichar charLetterAxisCompound = charA + numericValue.x - 1; // -1 because numeric vertex is not zero-based
  if (charLetterAxisCompound > charH)
    charLetterAxisCompound++;                                // +1 because "I" is never used
  NSString* letterAxisCompound = [NSString stringWithCharacters:&charLetterAxisCompound length:1];
  NSString* numberAxisCompound = [NSString stringWithFormat:@"%d", numericValue.y];

  GoVertex* vertex = [[GoVertex alloc] initWithLetterAxisCompound:letterAxisCompound
                                               numberAxisCompound:numberAxisCompound
                                                          numeric:numericValue];
  if (vertex)
    [vertex autorelease];
  return vertex;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoVertex instance from
/// @a stringValue.
///
/// Raises an @e NSRangeException if one of the vertex compounds stored in
/// @a stringValue are outside the supported range of values. Raises an
/// @e NSInvalidArgumentException if @a stringValue is nil or otherwise
/// fundamentally malformed.
// -----------------------------------------------------------------------------
+ (GoVertex*) vertexFromString:(NSString*)stringValue;
{
  if (! stringValue || [stringValue length] < 2 || [stringValue length] > 3)
  {
    NSString* errorMessage = @"String vertex is nil or otherwise malformed";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  stringValue = [stringValue uppercaseString];
  NSString* letterAxisCompound = [stringValue substringWithRange:NSMakeRange(0, 1)];
  NSString* numberAxisCompound = [stringValue substringFromIndex:1];
  unichar charLetterAxisCompound = [letterAxisCompound characterAtIndex:0];
  const unichar charA = [@"A" characterAtIndex:0];
  const unichar charH = [@"H" characterAtIndex:0];
  const unichar charI = [@"I" characterAtIndex:0];

  if (charLetterAxisCompound == charI)
  {
    NSString* errorMessage = @"Letter 'I' may not be used";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  struct GoVertexNumeric numericValue;
  numericValue.x = charLetterAxisCompound - charA + 1;  // +1 because vertex is not zero-based
  if (charLetterAxisCompound > charH)
    numericValue.x--;                               // -1 because "I" is never used
  numericValue.y = [numberAxisCompound intValue];   // no @try needed, intValue does not throw any exceptions

  if (numericValue.x < 1 || numericValue.x > 19 || numericValue.y < 1 || numericValue.y > 19)
  {
    NSString* errorMessage = @"String vertex is invalid";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoVertex* vertex = [[GoVertex alloc] initWithLetterAxisCompound:letterAxisCompound
                                               numberAxisCompound:numberAxisCompound
                                                          numeric:numericValue];
  if (vertex)
    [vertex autorelease];
  return vertex;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoVertex object with both the string and the numeric
/// representation of the same vertex.
///
/// @note This is the designated initializer of GoVertex.
// -----------------------------------------------------------------------------
- (id) initWithLetterAxisCompound:(NSString*)letterAxisCompound
               numberAxisCompound:(NSString*)numberAxisCompound
                          numeric:(struct GoVertexNumeric)numericVertex
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.string = [letterAxisCompound stringByAppendingString:numberAxisCompound];
  self.numeric = numericVertex;
  self.letterAxisCompound = letterAxisCompound;
  self.numberAxisCompound = numberAxisCompound;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoVertex object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.string = nil;
  self.letterAxisCompound = nil;
  self.numberAxisCompound = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoVertex object.
///
/// This method is invoked when GoVertex needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoVertex(%p): %@", self, _string];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a vertex refers to the same intersection as this
/// GoVertex object.
// -----------------------------------------------------------------------------
- (bool) isEqualToVertex:(GoVertex*)vertex
{
  struct GoVertexNumeric myNumericValue = self.numeric;
  struct GoVertexNumeric otherNumericValue = vertex.numeric;
  return (myNumericValue.x == otherNumericValue.x &&
          myNumericValue.y == otherNumericValue.y);
}

@end
