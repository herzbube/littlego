// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNodeMarkup.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeMarkup.
// -----------------------------------------------------------------------------
@interface GoNodeMarkup()
@property(nonatomic, retain) NSMutableDictionary* mutableSymbols;
@property(nonatomic, retain) NSMutableDictionary* mutableConnections;
@property(nonatomic, retain) NSMutableDictionary* mutableLabels;
@property(nonatomic, retain) NSMutableArray* mutableDimmings;
//@}
@end


@implementation GoNodeMarkup

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoNodeMarkup object with default values.
///
/// @note This is the designated initializer of GoNodeMarkup.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.mutableSymbols = nil;
  self.mutableConnections = nil;
  self.mutableLabels = nil;
  self.mutableDimmings = nil;

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

  self.mutableSymbols = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableDictionary class], [NSString class], [NSNumber class]]] forKey:goNodeMarkupSymbolsKey];
  self.mutableConnections = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableDictionary class], [NSArray class], [NSString class], [NSNumber class]]] forKey:goNodeMarkupConnectionsKey];
  self.mutableLabels = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableDictionary class], [NSString class], [NSArray class], [NSNumber class]]] forKey:goNodeMarkupLabelsKey];
  self.mutableDimmings = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableArray class], [NSString class]]] forKey:goNodeMarkupDimmingsKey];

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
/// @brief Deallocates memory allocated by this GoNodeMarkup object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.mutableSymbols = nil;
  self.mutableConnections = nil;
  self.mutableLabels = nil;
  self.mutableDimmings = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.mutableSymbols forKey:goNodeMarkupSymbolsKey];
  [encoder encodeObject:self.mutableConnections forKey:goNodeMarkupConnectionsKey];
  [encoder encodeObject:self.mutableLabels forKey:goNodeMarkupLabelsKey];
  [encoder encodeObject:self.mutableDimmings forKey:goNodeMarkupDimmingsKey];
}

#pragma mark - General methods

// -----------------------------------------------------------------------------
/// @brief Returns true if the GoNodeMarkup object contains any markup. Returns
/// false if the GoNodeMarkjup object does not contain any markup.
// -----------------------------------------------------------------------------
- (bool) hasMarkup
{
  return (self.mutableSymbols != nil ||
          self.mutableConnections != nil ||
          self.mutableLabels != nil ||
          self.mutableDimmings != nil);
}

#pragma mark - Symbol methods

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSDictionary*) symbols
{
  return self.mutableSymbols;
}

// -----------------------------------------------------------------------------
/// @brief Sets the symbol of type @a symbol at the intersection @a vertex.
///
/// Invoking this method adds or replaces an entry in the dictionary that is the
/// value of property @e symbols. The key of the entry is @a vertex, the value
/// is an NSNumber encapsulating @e symbol.
///
/// If the property value is @e nil, a new dictionary is created.
///
/// @exception NSInvalidArgumentException Is raised if @a vertex is @e nil.
// -----------------------------------------------------------------------------
- (void) setSymbol:(enum GoMarkupSymbol)symbol atVertex:(NSString*)vertex
{
  if (! vertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setSymbol:atVertex: failed: vertex argument is nil"];
    return;
  }

  NSNumber* symbolAsNumber = [NSNumber numberWithInt:symbol];

  if (self.mutableSymbols)
    self.mutableSymbols[vertex] = symbolAsNumber;
  else
    self.mutableSymbols = [NSMutableDictionary dictionaryWithObject:symbolAsNumber forKey:vertex];
}

// -----------------------------------------------------------------------------
/// @brief Removes the symbol at the intersection @a vertex. Does nothing if
/// there is no symbol at the intersection @a vertex.
///
/// Invoking this method removes an entry from the dictionary that is the
/// value of property @e symbols. The key of the entry is @a vertex. If the
/// dictionary becomes empty due to the removal, the property value is set to
/// @e nil and the dictionary is discarded.
///
/// Invoking this method does nothing if the property value already is @e nil.
///
/// @exception NSInvalidArgumentException Is raised if @a vertex is @e nil.
// -----------------------------------------------------------------------------
- (void) removeSymbolAtVertex:(NSString*)vertex
{
  if (! vertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeSymbolAtVertex: failed: Vertex argument is nil"];
    return;
  }

  if (! self.mutableSymbols)
    return;

  [self.mutableSymbols removeObjectForKey:vertex];

  if (self.mutableSymbols.count == 0)
    self.mutableSymbols = nil;
}

// -----------------------------------------------------------------------------
/// @brief Replaces all existing symbols with the symbols in @a symbols.
///
/// Invoking this method clears all entries from the dictionary that is the
/// value of property @e symbols, then adds all entries from @a symbols to the
/// dictionary.
///
/// If the property value is @e nil, a new dictionary is created.
///
/// If @a symbols does not contain any entries, or is @e nil, the effect is the
/// same as if @e removeAllSymbols() had been invoked.
// -----------------------------------------------------------------------------
- (void) replaceSymbols:(NSDictionary*)symbols
{
  if (! symbols || symbols.count == 0)
    [self removeAllSymbols];
  else
    self.mutableSymbols = [NSMutableDictionary dictionaryWithDictionary:symbols];
}

// -----------------------------------------------------------------------------
/// @brief Removes all existing symbols.
///
/// Invoking this method sets the value of property @e symbols to @e nil and
/// discards the existing dictionary. Invoking this method does nothing if the
/// property value already is @e nil.
// -----------------------------------------------------------------------------
- (void) removeAllSymbols
{
  self.mutableSymbols = nil;
}

#pragma mark - Connection methods

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSDictionary*) connections
{
  return self.mutableConnections;
}

// -----------------------------------------------------------------------------
/// @brief Sets the connection of type @a connection between the intersections
/// @a fromVertex and @a toVertex.
///
/// Invoking this method adds or replaces an entry in the dictionary that is the
/// value of property @e connections. The key of the entry is an NSArray
/// consisting of @a fromVertex and @a toVertex, the value is an NSNumber
/// encapsulating @e connection.
///
/// If the property value is @e nil, a new dictionary is created.
///
/// @exception NSInvalidArgumentException Is raised if @a fromVertex or
/// @a toVertex is @e nil, or if @a fromVertex and @a toVertex refer to the
/// same intersection (the SGF standard does not allow arrows or lines that have
/// the same start and end point).
// -----------------------------------------------------------------------------
- (void) setConnection:(enum GoMarkupConnection)connection fromVertex:(NSString*)fromVertex toVertex:(NSString*)toVertex
{
  if (! fromVertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setConnection:fromVertex:toVertex: failed: fromVertex argument is nil"];
    return;
  }
  if (! toVertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setConnection:fromVertex:toVertex: failed: toVertex argument is nil"];
    return;
  }
  if ([fromVertex isEqualToString:toVertex])
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:[@"setConnection:fromVertex:toVertex: failed: fromVertex argument and toVertex argument refer to the same intersection " stringByAppendingString:fromVertex]];
    return;
  }

  NSArray* vertices = @[fromVertex, toVertex];
  NSNumber* connectionAsNumber = [NSNumber numberWithInt:connection];

  if (self.mutableConnections)
    self.mutableConnections[vertices] = connectionAsNumber;
  else
    self.mutableConnections = [NSMutableDictionary dictionaryWithObject:connectionAsNumber forKey:vertices];
}

// -----------------------------------------------------------------------------
/// @brief Removes the connection between the intersections @a fromVertex and
/// @a toVertex. Does nothing if there is no such connection.
///
/// Invoking this method removes an entry from the dictionary that is the
/// value of property @e connections. The key of the entry is an NSArray
/// consisting of @a fromVertex and @a toVertex. If the dictionary becomes empty
/// due to the removal, the property value is set to @e nil and the dictionary
/// is discarded.
///
/// Invoking this method does nothing if the property value already is @e nil.
///
/// @exception NSInvalidArgumentException Is raised if @a fromVertex or
/// @a toVertex is @e nil.
// -----------------------------------------------------------------------------
- (void) removeConnectionFromVertex:(NSString*)fromVertex toVertex:(NSString*)toVertex
{
  if (! fromVertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeConnectionFromVertex:toVertex: failed: fromVertex argument is nil"];
    return;
  }
  if (! toVertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeConnectionFromVertex:toVertex: failed: toVertex argument is nil"];
    return;
  }

  if (! self.mutableConnections)
    return;

  NSArray* vertices = @[fromVertex, toVertex];

  [self.mutableConnections removeObjectForKey:vertices];

  if (self.mutableConnections.count == 0)
    self.mutableConnections = nil;
}

// -----------------------------------------------------------------------------
/// @brief Replaces all existing connections with the connections in
/// @a connections.
///
/// Invoking this method clears all entries from the dictionary that is the
/// value of property @e connections, then adds all entries from @a connections
/// to the dictionary.
///
/// If the property value is @e nil, a new dictionary is created.
///
/// If @a connections does not contain any entries, or is @e nil, the effect is
/// the same as if @e removeAllConnections() had been invoked.
///
/// @exception NSInvalidArgumentException Is raised if @a connections is not
/// @e nil and contains a key where @e fromVertex and @e toVertex refer to the
/// same intersection (the SGF standard does not allow arrows or lines that have
/// the same start and end point).
// -----------------------------------------------------------------------------
- (void) replaceConnections:(NSDictionary*)connections
{
  if (! connections || connections.count == 0)
  {
    [self removeAllConnections];
  }
  else
  {
    for (NSArray* vertices in connections.allKeys)
    {
      NSString* fromVertex = vertices.firstObject;
      NSString* toVertex = vertices.lastObject;
      if ([fromVertex isEqualToString:toVertex])
      {
        [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:[@"replaceConnections: failed: dictionary argument contains an entry where fromVertex and toVertex refer to the same intersection " stringByAppendingString:fromVertex]];
        return;
      }
    }
    self.mutableConnections = [NSMutableDictionary dictionaryWithDictionary:connections];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all existing connections.
///
/// Invoking this method sets the value of property @e connections to @e nil and
/// discards the existing dictionary. Invoking this method does nothing if the
/// property value already is @e nil.
// -----------------------------------------------------------------------------
- (void) removeAllConnections
{
  self.mutableConnections = nil;
}

#pragma mark - Label methods

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSDictionary*) labels
{
  return self.mutableLabels;
}

// -----------------------------------------------------------------------------
/// @brief Sets a label of type @a label with the text @a labelText at the
/// intersection @a vertex. Invokes removeNewlinesAndTrimLabel:() on
/// @a labelText to trim leading and trailing whitespace characters and replace
/// any remaining newline charactes with space characters. The resulting string
/// must not be zero length.
///
/// Invoking this method adds or replaces an entry in the dictionary that is the
/// value of property @e labels. The key of the entry is @a vertex, the value
/// is an NSArray that consist of two objects: An NSNumber object that
/// encapsulates @a label, and @e labelText.
///
/// If the property value is @e nil, a new dictionary is created.
///
/// @exception NSInvalidArgumentException Is raised if @a labelText or
/// @a vertex is @e nil, or if @a labelText is a zero length string (after
/// newline replacement and trimming has taken place), or if @a labelText does
/// not match the specified type @a label.
// -----------------------------------------------------------------------------
- (void) setLabel:(enum GoMarkupLabel)label labelText:(NSString*)labelText atVertex:(NSString*)vertex
{
  if (! labelText)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setLabel:labelText:atVertex: failed: labelText argument is nil"];
    return;
  }
  if (! vertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setLabel:labelText:atVertex: failed: vertex argument is nil"];
    return;
  }

  labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:labelText];

  if (labelText.length == 0)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setLabel:labelText:atVertex: failed: labelText argument is a zero length string"];
    return;
  }

  enum GoMarkupLabel actualLabelType = [GoNodeMarkup labelTypeOfLabel:labelText];
  if (actualLabelType != label)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"setLabel:labelText:atVertex: failed: labelText argument '%@' does not match label type %d, actual label type is %d", labelText, label, actualLabelType];
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
    return;
  }

  NSArray* dictionaryValue = @[[NSNumber numberWithInt:label], labelText];

  if (self.mutableLabels)
    self.mutableLabels[vertex] = dictionaryValue;
  else
    self.mutableLabels = [NSMutableDictionary dictionaryWithObject:dictionaryValue forKey:vertex];
}

// -----------------------------------------------------------------------------
/// @brief Removes the label at the intersection @a vertex. Does nothing if
/// there is no such label.
///
/// Invoking this method removes an entry from the dictionary that is the
/// value of property @e labels. The key of the entry is @a vertex. If the
/// dictionary becomes empty due to the removal, the property value is set to
/// @e nil and the dictionary is discarded.
///
/// Invoking this method does nothing if the property value already is @e nil.
///
/// @exception NSInvalidArgumentException Is raised if @a vertex is @e nil.
// -----------------------------------------------------------------------------
- (void) removeLabelAtVertex:(NSString*)vertex
{
  if (! vertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeLabelAtVertex failed: vertex argument is nil"];
    return;
  }

  if (! self.mutableLabels)
    return;

  [self.mutableLabels removeObjectForKey:vertex];

  if (self.mutableLabels.count == 0)
    self.mutableLabels = nil;
}

// -----------------------------------------------------------------------------
/// @brief Replaces all existing labels with the labels in @a labels. Invokes
/// removeNewlinesAndTrimLabel:() on all label texts in @a labels. The resulting
/// strings must not be zero length. Label types in @a labels are ignored,
/// instead the actual label type is determined by examining the trimmed label
/// texts.
///
/// Invoking this method clears all entries from the dictionary that is the
/// value of property @e labels, then adds all entries from @a labels to the
/// dictionary.
///
/// If the property value is @e nil, a new dictionary is created.
///
/// If @a labels does not contain any entries, or is @e nil, the effect is the
/// same as if @e removeAllLabels() had been invoked.
///
/// @exception NSInvalidArgumentException Is raised if @a labels is not @e nil
/// and contains labels that are zero length strings (after newline replacement
/// and trimming has taken place).
// -----------------------------------------------------------------------------
- (void) replaceLabels:(NSDictionary*)labels
{
  if (! labels || labels.count == 0)
  {
    [self removeAllLabels];
  }
  else
  {
    NSMutableDictionary* newMutableLabels = [NSMutableDictionary dictionary];

    [labels enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSArray* labelTypeAndText, BOOL* stop)
    {
      NSString* labelText = labelTypeAndText.lastObject;
      labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:labelText];
      if (labelText.length == 0)
      {
        [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"replaceLabels: failed: labels argument contains a label text that is a zero length string"];
        return;
      }

      enum GoMarkupLabel labelType = [GoNodeMarkup labelTypeOfLabel:labelText];
      newMutableLabels[vertexString] = @[[NSNumber numberWithInt:labelType], labelText];
    }];

    self.mutableLabels = newMutableLabels;
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all existing labels.
///
/// Invoking this method sets the value of property @e labels to @e nil and
/// discards the existing dictionary. Invoking this method does nothing if the
/// property value already is @e nil.
// -----------------------------------------------------------------------------
- (void) removeAllLabels
{
  self.mutableLabels = nil;
}

// -----------------------------------------------------------------------------
/// @brief Trims leading and trailing whitespace characters from @a labelText
/// and replaces all remaining newline characters with space characters.
///
/// This method can be used to clean up a label text so that it can be checked
/// for zero length before passing it to setLabel:labelText:atVertex:().
///
/// @exception NSInvalidArgumentException Is raised if @a labelText is @e nil.
// -----------------------------------------------------------------------------
+ (NSString*) removeNewlinesAndTrimLabel:(NSString*)labelText
{
  if (! labelText)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeNewlinesAndTrimLabel: failed: labelText argument is nil"];
    return nil;
  }

  labelText = [labelText stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
  labelText = [labelText stringByReplacingOccurrencesOfString:@"\r" withString:@" "];

  // Trimming after replacement catches leading/trailing newlines
  labelText = [labelText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  return labelText;
}

// -----------------------------------------------------------------------------
/// @brief Analyzes the string value @a labelText and returns a value from the
/// enumeration #GoMarkupLabel that describes the string value.
///
/// If @a label contains a single letter A-Z or a-z from the latin alphabet,
/// the return value is #GoMarkupLabelMarkerLetter.
///
/// If @a label contains only digit characters that form an integer number in
/// the range between #gMinimumNumberMarkerValue and #gMaximumNumberMarkerValue,
/// the return value is #GoMarkupLabelMarkerNumber
///
/// In all other cases the return value is #GoMarkupLabelLabel.
// -----------------------------------------------------------------------------
+ (enum GoMarkupLabel) labelTypeOfLabel:(NSString*)labelText
{
  char letterMarkerValue;
  int numberMarkerValue;
  return [GoNodeMarkup labelTypeOfLabel:labelText
                      letterMarkerValue:&letterMarkerValue
                      numberMarkerValue:&numberMarkerValue];
}

// -----------------------------------------------------------------------------
/// @brief Analyzes the string value @a labelText and returns a value from the
/// enumeration #GoMarkupLabel that describes the string value. In addition,
/// if the label is one of the marker types, fills the corresponding out
/// variable with the underlying @e char or @e int value.

/// If @a label contains a single letter A-Z or a-z from the latin alphabet,
/// the return value is #GoMarkupLabelMarkerLetter and this method fills the out
/// variable @a letterMarkerValue with the char value of the single letter.
///
/// If @a label contains only digit characters that form an integer number in
/// the range between #gMinimumNumberMarkerValue and #gMaximumNumberMarkerValue,
/// the return value is #GoMarkupLabelMarkerNumber and this method fills the
/// out variable @a numberMarkerValue with the int value of the integer number.
///
/// In all other cases the return value is #GoMarkupLabelLabel and the value of
/// both out variables is undefined.
// -----------------------------------------------------------------------------
+ (enum GoMarkupLabel) labelTypeOfLabel:(NSString*)labelText
                      letterMarkerValue:(char*)letterMarkerValue
                      numberMarkerValue:(int*)numberMarkerValue;
{
  NSUInteger labelTextLength = labelText.length;

  if (labelTextLength == 0)
  {
    return GoMarkupLabelLabel;
  }
  if (labelTextLength == 1)
  {
    // Code in this branch should hopefully be faster than using regex

    static unichar charUppercaseA = 0;
    static unichar charuppercaseZ = 0;
    static unichar charLowercaseA = 0;
    static unichar charLowercaseZ = 0;
    static unichar charZero = 0;
    static unichar charNine = 0;
    if (charUppercaseA == 0)
    {
      charUppercaseA = [@"A" characterAtIndex:0];
      charuppercaseZ = [@"Z" characterAtIndex:0];
      charLowercaseA = [@"a" characterAtIndex:0];
      charLowercaseZ = [@"z" characterAtIndex:0];
      charZero = [@"0" characterAtIndex:0];
      charNine = [@"9" characterAtIndex:0];
    }

    unichar labelCharacter = [labelText characterAtIndex:0];
    if (labelCharacter >= charUppercaseA && labelCharacter <= charuppercaseZ)
    {
      *letterMarkerValue = labelCharacter - charUppercaseA + 'A';
      return GoMarkupLabelMarkerLetter;
    }
    else if (labelCharacter >= charLowercaseA && labelCharacter <= charLowercaseZ)
    {
      *letterMarkerValue = labelCharacter - charLowercaseA + 'a';
      return GoMarkupLabelMarkerLetter;
    }
    else if (labelCharacter >= charZero && labelCharacter <= charNine)
    {
      *numberMarkerValue = labelCharacter - charZero;
      if (*numberMarkerValue >= gMinimumNumberMarkerValue && *numberMarkerValue <= gMaximumNumberMarkerValue)
        return GoMarkupLabelMarkerNumber;
      else
        return GoMarkupLabelLabel;
    }
    else
    {
      return GoMarkupLabelLabel;
    }
  }
  else
  {
    NSRegularExpression* regexNumbers = [[[NSRegularExpression alloc] initWithPattern:@"^[0-9]+$" options:0 error:nil] autorelease];
    NSRange allCharactersRange = NSMakeRange(0, labelTextLength);
    if ([regexNumbers numberOfMatchesInString:labelText options:0 range:allCharactersRange] > 0)
    {
      *numberMarkerValue = [self labelAsNumberMarkerValue:labelText];
      if (*numberMarkerValue != -1)
        return GoMarkupLabelMarkerNumber;
      else
        return GoMarkupLabelLabel;
    }
    else
    {
      return GoMarkupLabelLabel;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the number marker value that corresponds to @a labelText.
/// Returns -1 if conversion of @a labelText fails, indicating that @a labelText
/// does not represent a valid number marker value.
///
/// This method expects that a previous step has verified that @a labelText is
/// not empty and does not contain any characters that are not digits. If this
/// is not the case, then the NSNumberFormatter that is used by the
/// implementation of this method will gracefully handle leading/trailing space
/// characters and locale-specific group or decimal separators.
// -----------------------------------------------------------------------------
+ (int) labelAsNumberMarkerValue:(NSString*)labelText
{
  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
  // Parses the text as an integer number
  numberFormatter.numberStyle = NSNumberFormatterNoStyle;
  // If the string contains any characters other than numerical digits or
  // locale-appropriate group or decimal separators, parsing will fail.
  // Leading/trailing space is ignored.
  // Returns nil if parsing fails.
  NSNumber* number = [numberFormatter numberFromString:labelText];
  if (! number)
    return -1;

  int numberMarkerValue = [number intValue];
  if (numberMarkerValue >= gMinimumNumberMarkerValue && numberMarkerValue <= gMaximumNumberMarkerValue)
    return numberMarkerValue;
  else
    return -1;
}

#pragma mark - Dimming methods

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSArray*) dimmings
{
  return self.mutableDimmings;
}

// -----------------------------------------------------------------------------
/// @brief Sets a dimming at the intersection @a vertex.
///
/// Invoking this method adds an element to the array that is the value of
/// property @e dimmings. The element is @a vertex.
///
/// Invoking this method does nothing if the array already contains @a vertex.
///
/// If the property value is @e nil, a new array is created.
///
/// @exception NSInvalidArgumentException Is raised if @a vertes is @e nil.
// -----------------------------------------------------------------------------
- (void) setDimmingAtVertex:(NSString*)vertex
{
  if (! vertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setDimmingAtVertex: failed: vertex argument is nil"];
    return;
  }

  if (self.mutableDimmings)
  {
    if (! [self.mutableDimmings containsObject:vertex])
      [self.mutableDimmings addObject:vertex];
  }
  else
  {
    self.mutableDimmings = [NSMutableArray arrayWithObject:vertex];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes the dimming at the intersection @a vertex. Does nothing if
/// there is no such dimming.
///
/// Invoking this method removes @a vertex from the array that is the value of
/// property @e dimmings. If the array becomes empty due to the removal, the
/// property value is set to @e nil and the array is discarded.
///
/// Invoking this method does nothing if the property value already is @e nil.
///
/// @exception NSInvalidArgumentException Is raised if @a vertes is @e nil.
// -----------------------------------------------------------------------------
- (void) removeDimmingAtVertex:(NSString*)vertex
{
  if (! vertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeDimmingAtVertex: failed: vertex argument is nil"];
    return;
  }

  if (! self.mutableDimmings)
    return;

  [self.mutableDimmings removeObject:vertex];

  if (self.mutableDimmings.count == 0)
    self.mutableDimmings = nil;
}

// -----------------------------------------------------------------------------
/// @brief Replaces all existing dimmings with the dimmings in @a dimmings.
///
/// Invoking this method clears all elements from the array that is the
/// value of property @e dimmings, then adds all elements from @a dimmings to
/// the array.
///
/// If the property value is @e nil, a new array is created.
///
/// If @a dimmings does not contain any elements, or is @e nil, the effect is
/// the same as if @e removeAllDimmings() had been invoked.
// -----------------------------------------------------------------------------
- (void) replaceDimmings:(NSArray*)dimmings
{
  if (! dimmings || dimmings.count == 0)
    [self removeAllDimmings];
  else
    self.mutableDimmings = [NSMutableArray arrayWithArray:dimmings];
}

// -----------------------------------------------------------------------------
/// @brief Undims everything.
///
/// Invoking this method removes all elements from the array that is the
/// value of property @e dimmings.
///
/// If the property value is @e nil, a new empty array is created.
// -----------------------------------------------------------------------------
- (void) undimEverything
{
  if (self.mutableDimmings)
    [self.mutableDimmings removeAllObjects];
  else
    self.mutableDimmings = [NSMutableArray array];
}

// -----------------------------------------------------------------------------
/// @brief Removes all existing dimmings.
///
/// Invoking this method sets the value of property @e dimmings to @e nil and
/// discards the existing array. Invoking this method does nothing if the
/// property value already is @e nil.
// -----------------------------------------------------------------------------
- (void) removeAllDimmings
{
  self.mutableDimmings = nil;
}

@end
