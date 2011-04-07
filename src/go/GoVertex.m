// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite, retain) NSString* string;
@property(readwrite) struct GoVertexNumeric numeric;
//@}
@end


@implementation GoVertex

@synthesize string;
@synthesize numeric;

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoVertex instance from the numeric
/// compounds in @a numericValue.
// -----------------------------------------------------------------------------
+ (GoVertex*) vertexFromNumeric:(struct GoVertexNumeric)numericValue
{
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
// -----------------------------------------------------------------------------
+ (GoVertex*) vertexFromString:(NSString*)stringValue;
{
  NSString* vertexX = [stringValue substringWithRange:NSMakeRange(0, 1)];
  NSString* vertexY = [stringValue substringFromIndex:1];
  unichar charVertexX = [vertexX characterAtIndex:0];
  unichar charA = [@"A" characterAtIndex:0];
  unichar charH = [@"H" characterAtIndex:0];

  struct GoVertexNumeric numericValue;
  numericValue.x = charVertexX - charA + 1;  // +1 because vertex is not zero-based
  if (charVertexX > charH)
    numericValue.x--;                        // -1 because "I" is never used
  numericValue.y = [vertexY intValue];

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
/// @brief Deallocates memory allocated by this GoVertex object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.string = nil;
  [super dealloc];
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
