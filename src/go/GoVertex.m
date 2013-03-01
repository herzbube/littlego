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
/// @brief Class extension with private methods for GoVertex.
// -----------------------------------------------------------------------------
@interface GoVertex()
/// @name Initialization and deallocation
//@{
- (id) init;
- (id) initWithString:(NSString*)stringVertex numeric:(struct GoVertexNumeric)numericVertex;
- (void) dealloc;
//@}
/// @name NSCoding protocol
//@{
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
//@}
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSString* string;
@property(nonatomic, assign, readwrite) struct GoVertexNumeric numeric;
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
  unichar charVertexX = charA + numericValue.x - 1; // -1 because numeric vertex is not zero-based
  if (charVertexX > charH)
    charVertexX++;                                // +1 because "I" is never used
  NSString* vertexX = [NSString stringWithCharacters:&charVertexX length:1];
  NSString* vertexY = [NSString stringWithFormat:@"%d", numericValue.y];
  NSString* stringValue = [vertexX stringByAppendingString:vertexY];

  GoVertex* vertex = [[GoVertex alloc] initWithString:stringValue numeric:numericValue];
  if (vertex)
    [vertex autorelease];
  return vertex;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoVertex instance from
/// @a stringValue.
///
/// Raises an @e NSRangeException if one of the vertex compounds stored in
/// @a stringValue is outside the supported range of values. Raises an
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
  NSString* vertexX = [stringValue substringWithRange:NSMakeRange(0, 1)];
  NSString* vertexY = [stringValue substringFromIndex:1];
  unichar charVertexX = [vertexX characterAtIndex:0];
  const unichar charA = [@"A" characterAtIndex:0];
  const unichar charH = [@"H" characterAtIndex:0];
  const unichar charI = [@"I" characterAtIndex:0];

  if (charVertexX == charI)
  {
    NSString* errorMessage = @"Letter 'I' may not be used";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  struct GoVertexNumeric numericValue;
  numericValue.x = charVertexX - charA + 1;  // +1 because vertex is not zero-based
  if (charVertexX > charH)
    numericValue.x--;                        // -1 because "I" is never used
  numericValue.y = [vertexY intValue];       // no @try needed, intValue does not throw any exceptions

  if (numericValue.x < 1 || numericValue.x > 19 || numericValue.y < 1 || numericValue.y > 19)
  {
    NSString* errorMessage = @"String vertex is invalid";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoVertex* vertex = [[GoVertex alloc] initWithString:stringValue numeric:numericValue];
  if (vertex)
    [vertex autorelease];
  return vertex;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoVertex object. The object is a "null" vertex, i.e.
/// it refers to an invalid position.
// -----------------------------------------------------------------------------
- (id) init
{
  // TODO: do we need this initializer?
  struct GoVertexNumeric numericValue;
  numericValue.x = 0;
  numericValue.y = 0;
  return [self initWithString:@"" numeric:numericValue];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoVertex object with both the string and the numeric
/// representation of the same vertex.
///
/// @note This is the designated initializer of GoVertex.
// -----------------------------------------------------------------------------
- (id) initWithString:(NSString*)stringVertex numeric:(struct GoVertexNumeric)numericVertex
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.string = stringVertex;
  self.numeric = numericVertex;

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
  self.string = [decoder decodeObjectForKey:goVertexStringKey];
  struct GoVertexNumeric numericVertex;
  numericVertex.x = [decoder decodeIntForKey:goVertexNumericXKey];
  numericVertex.y = [decoder decodeIntForKey:goVertexNumericYKey];
  self.numeric = numericVertex;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoVertex object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.string = nil;
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

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.string forKey:goVertexStringKey];
  [encoder encodeInt:self.numeric.x forKey:goVertexNumericXKey];
  [encoder encodeInt:self.numeric.y forKey:goVertexNumericYKey];
}

@end
