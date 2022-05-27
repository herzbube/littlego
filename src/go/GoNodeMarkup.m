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

  self.mutableSymbols = [decoder decodeObjectForKey:goNodeMarkupSymbolsKey];
  self.mutableConnections = [decoder decodeObjectForKey:goNodeMarkupConnectionsKey];
  self.mutableLabels = [decoder decodeObjectForKey:goNodeMarkupLabelsKey];
  self.mutableDimmings = [decoder decodeObjectForKey:goNodeMarkupDimmingsKey];

  return self;
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
/// Private getter implementation, property is documented in the header file.
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
/// Private getter implementation, property is documented in the header file.
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
/// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSDictionary*) labels
{
  return self.mutableLabels;
}

// -----------------------------------------------------------------------------
/// @brief Sets a label with the text @a labelText at the intersection
/// @a vertex. Invokes removeNewlinesAndTrimLabel:() on @a labelText to trim
/// leading and trailing whitespace characters and replace any remaining
/// newline charactes with space characters. The resulting string must not be
/// zero length.
///
/// Invoking this method adds or replaces an entry in the dictionary that is the
/// value of property @e labels. The key of the entry is @a vertex, the value
/// is @e labelText.
///
/// If the property value is @e nil, a new dictionary is created.
///
/// @exception NSInvalidArgumentException Is raised if @a labelText or
/// @a vertex is @e nil, or if @a labelText is a zero length string (after
/// newline replacement and trimming has taken place).
// -----------------------------------------------------------------------------
- (void) setLabel:(NSString*)labelText atVertex:(NSString*)vertex
{
  if (! labelText)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setLabel:atVertex: failed: labelText argument is nil"];
    return;
  }
  if (! vertex)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setLabel:atVertex: failed: vertex argument is nil"];
    return;
  }

  labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:labelText];

  if (labelText.length == 0)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setLabel:atVertex: failed: labelText argument is a zero length string"];
    return;
  }

  if (self.mutableLabels)
    self.mutableLabels[vertex] = labelText;
  else
    self.mutableLabels = [NSMutableDictionary dictionaryWithObject:labelText forKey:vertex];
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
/// strings must not be zero length.
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

    [labels enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSString* labelText, BOOL* stop)
    {
      labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:labelText];
      if (labelText.length == 0)
      {
        [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"replaceLabels: failed: labels argument contains a label text that is a zero length string"];
        return;
      }

      newMutableLabels[vertexString] = labelText;
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
/// for zero length before passing it to setLabel:atVertex:().
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

#pragma mark - Dimming methods

// -----------------------------------------------------------------------------
/// Private getter implementation, property is documented in the header file.
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
