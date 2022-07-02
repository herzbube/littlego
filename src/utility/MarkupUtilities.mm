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
#import "MarkupUtilities.h"
#import "ExceptionUtility.h"
#import "../go/GoNode.h"
#import "../go/GoNodeMarkup.h"
#import "../go/GoPoint.h"
#import "../go/GoVertex.h"

// C++ standard library
#include <set>
#include <utility>  // for std::pair
#include <vector>

// First invocation of the HandleMarkupEditingInteractionCommand initializer
// will initialize these static variables.
static unichar charUppercaseA = 0;
static unichar charuppercaseZ = 0;
static unichar charLowercaseA = 0;
static unichar charLowercaseZ = 0;
static unichar charZero = 0;
static unichar charNine = 0;
static int minimumNumberMarkerValue = 0;
static int maximumNumberMarkerValue = 0;
static std::vector<std::pair<char, char> > letterMarkerValueRanges;


@implementation MarkupUtilities

// -----------------------------------------------------------------------------
/// @brief Initializes static variables if they have not yet been initialized.
// -----------------------------------------------------------------------------
+ (void) setupStaticVariablesIfNotYetSetup
{
  if (charUppercaseA != 0)
    return;

  charUppercaseA = [@"A" characterAtIndex:0];
  charuppercaseZ = [@"Z" characterAtIndex:0];
  charLowercaseA = [@"a" characterAtIndex:0];
  charLowercaseZ = [@"z" characterAtIndex:0];
  charZero = [@"0" characterAtIndex:0];
  charNine = [@"9" characterAtIndex:0];
  minimumNumberMarkerValue = 1;
  maximumNumberMarkerValue = 999;
  letterMarkerValueRanges.push_back(std::make_pair('A', 'Z'));
  letterMarkerValueRanges.push_back(std::make_pair('a', 'z'));
}

// -----------------------------------------------------------------------------
/// @brief Maps a value @a markupType from the enumeration #MarkupType to a
/// value from the enumeration #MarkupTool and returns the mapped value.
// -----------------------------------------------------------------------------
+ (enum MarkupTool) markupToolForMarkupType:(enum MarkupType)markupType
{
  switch (markupType)
  {
    case MarkupTypeSymbolCircle:
    case MarkupTypeSymbolSquare:
    case MarkupTypeSymbolTriangle:
    case MarkupTypeSymbolX:
    case MarkupTypeSymbolSelected:
    {
      return MarkupToolSymbol;
    }
    case MarkupTypeMarkerNumber:
    case MarkupTypeMarkerLetter:
    {
      return MarkupToolMarker;
    }
    case MarkupTypeLabel:
    {
      return MarkupToolLabel;
    }
    case MarkupTypeConnectionLine:
    case MarkupTypeConnectionArrow:
    {
      return MarkupToolConnection;
    }
    case MarkupTypeEraser:
    {
      return MarkupToolEraser;
    }
    default:
    {
      [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:@"markupToolForMarkupType: failed, markup type has invalid value %d" argumentValue:markupType];
      return MarkupToolSymbol;   // dummy return to make compiler happy
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps a value @a markupType from the enumeration #MarkupType to a
/// value from the enumeration #GoMarkupSymbol and returns the mapped value.
/// Raises an exception if mapping is not possible.
///
/// @exception InvalidArgumentException Is thrown if @a markupType cannot be
/// mapped. Only markup types for symbols can be mapped.
// -----------------------------------------------------------------------------
+ (enum GoMarkupSymbol) symbolForMarkupType:(enum MarkupType)markupType
{
  switch (markupType)
  {
    case MarkupTypeSymbolCircle:
      return GoMarkupSymbolCircle;
    case MarkupTypeSymbolSquare:
      return GoMarkupSymbolSquare;
    case MarkupTypeSymbolTriangle:
      return GoMarkupSymbolTriangle;
    case MarkupTypeSymbolX:
      return GoMarkupSymbolX;
    case MarkupTypeSymbolSelected:
      return GoMarkupSymbolSelected;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"symbolForMarkupType failed: invalid markup type %d" argumentValue:markupType];
      return GoMarkupSymbolCircle;  // dummy return to make compiler happy
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps a value @a symbol from the enumeration #GoMarkupSymbol to a
/// value from the enumeration #MarkupType and returns the mapped value.
// -----------------------------------------------------------------------------
+ (enum MarkupType) markupTypeForSymbol:(enum GoMarkupSymbol)symbol
{
  switch (symbol)
  {
    case GoMarkupSymbolCircle:
      return MarkupTypeSymbolCircle;
    case GoMarkupSymbolSquare:
      return MarkupTypeSymbolSquare;
    case GoMarkupSymbolTriangle:
      return MarkupTypeSymbolTriangle;
    case GoMarkupSymbolX:
      return MarkupTypeSymbolX;
    case GoMarkupSymbolSelected:
      return MarkupTypeSymbolSelected;
    default:
      [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:@"markupTypeForSymbol failed: invalid symbol %d" argumentValue:symbol];
      return MarkupTypeSymbolCircle;  // dummy return to make compiler happy
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the next symbol in enumeration #GoMarkupSymbol after
/// @a symbol. Returns the first symbol when @a symbol is the last symbol.
// -----------------------------------------------------------------------------
+ (enum GoMarkupSymbol) nextSymbolAfterSymbol:(enum GoMarkupSymbol)symbol
{
  switch (symbol)
  {
    case GoMarkupSymbolCircle:
      return GoMarkupSymbolSquare;
    case GoMarkupSymbolSquare:
      return GoMarkupSymbolTriangle;
    case GoMarkupSymbolTriangle:
      return GoMarkupSymbolX;
    case GoMarkupSymbolX:
      return GoMarkupSymbolSelected;
    case GoMarkupSymbolSelected:
      return GoMarkupSymbolCircle;
    default:
      [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:@"nextSymbolAfterSymbol failed: invalid symbol %d" argumentValue:symbol];
      return GoMarkupSymbolCircle;  // dummy return to make compiler happy
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps a value @a markupType from the enumeration #MarkupType to a
/// value from the enumeration #GoMarkupConnection and returns the mapped value.
/// Raises an exception if mapping is not possible.
///
/// @exception InvalidArgumentException Is thrown if @a markupType cannot be
/// mapped. Only markup types for connections can be mapped.
// -----------------------------------------------------------------------------
+ (enum GoMarkupConnection) connectionForMarkupType:(enum MarkupType)markupType
{
  switch (markupType)
  {
    case MarkupTypeConnectionLine:
      return GoMarkupConnectionLine;
    case MarkupTypeConnectionArrow:
      return GoMarkupConnectionArrow;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"connectionForMarkupType failed: invalid markup type %d" argumentValue:markupType];
      return GoMarkupConnectionLine;  // dummy return to make compiler happy
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps a value @a connection from the enumeration #GoMarkupConnection
/// to a value from the enumeration #MarkupType and returns the mapped value.
// -----------------------------------------------------------------------------
+ (enum MarkupType) markupTypeForConnection:(enum GoMarkupConnection)connection
{
  switch (connection)
  {
    case GoMarkupConnectionArrow:
      return MarkupTypeConnectionArrow;
    case GoMarkupConnectionLine:
      return MarkupTypeConnectionLine;
    default:
      [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:@"markupTypeForConnection failed: invalid connection %d" argumentValue:connection];
      return MarkupTypeConnectionArrow;  // dummy return to make compiler happy
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps a value @a markupType from the enumeration #MarkupType to a
/// value from the enumeration #GoMarkupLabel and returns the mapped value.
/// Raises an exception if mapping is not possible.
///
/// @exception InvalidArgumentException Is thrown if @a markupType cannot be
/// mapped. Only markup types for labels can be mapped.
// -----------------------------------------------------------------------------
+ (enum GoMarkupLabel) labelForMarkupType:(enum MarkupType)markupType
{
  switch (markupType)
  {
    case MarkupTypeMarkerNumber:
      return GoMarkupLabelMarkerNumber;
    case MarkupTypeMarkerLetter:
      return GoMarkupLabelMarkerLetter;
    case MarkupTypeLabel:
      return GoMarkupLabelLabel;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"labelForMarkupType failed: invalid markup type %d" argumentValue:markupType];
      return GoMarkupLabelLabel;  // dummy return to make compiler happy
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps a value @a label from the enumeration #GoMarkupLabel
/// to a value from the enumeration #MarkupType and returns the mapped value.
// -----------------------------------------------------------------------------
+ (enum MarkupType) markupTypeForLabel:(enum GoMarkupLabel)label
{
  switch (label)
  {
    case GoMarkupLabelMarkerNumber:
      return MarkupTypeMarkerNumber;
    case GoMarkupLabelMarkerLetter:
      return MarkupTypeMarkerLetter;
    case GoMarkupLabelLabel:
      return MarkupTypeLabel;
    default:
      [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:@"markupTypeForLabel failed: invalid label %d" argumentValue:label];
      return MarkupTypeLabel;  // dummy return to make compiler happy
  }
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx
// -----------------------------------------------------------------------------
+ (NSString*) nextFreeMarkerOfType:(enum MarkupType)markupType
                    onIntersection:(NSString*)intersection
                      inNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  [MarkupUtilities setupStaticVariablesIfNotYetSetup];

  char nextFreeLetterMarkerValue = letterMarkerValueRanges.front().first;
  int nextFreeNumberMarkerValue = minimumNumberMarkerValue;
  bool canUseNextFreeMarkerValue = false;

  NSDictionary* labels = nodeMarkup.labels;
  if (labels)
  {
    std::set<char> usedLetterMarkerValues;
    std::set<char> usedNumberMarkerValues;
    for (NSString* label in labels.allValues)
    {
      char letterMarkerValue;
      int numberMarkerValue;
      enum MarkupType markupTypeOfLabel = [MarkupUtilities markupTypeOfLabel:label
                                                           letterMarkerValue:&letterMarkerValue
                                                           numberMarkerValue:&numberMarkerValue];
      if (markupTypeOfLabel == MarkupTypeMarkerLetter)
        usedLetterMarkerValues.insert(letterMarkerValue);
      else if (markupTypeOfLabel == MarkupTypeMarkerNumber)
        usedNumberMarkerValues.insert(numberMarkerValue);
    }

    if (markupType == MarkupTypeMarkerLetter)
    {
      for (auto letterMarkerValueRange : letterMarkerValueRanges)
      {
        nextFreeLetterMarkerValue = letterMarkerValueRange.first;
        while (nextFreeLetterMarkerValue <= letterMarkerValueRange.second && ! canUseNextFreeMarkerValue)
        {
          if (usedLetterMarkerValues.find(nextFreeLetterMarkerValue) != usedLetterMarkerValues.end())
            nextFreeLetterMarkerValue++;
          else
            canUseNextFreeMarkerValue = true;
        }

        if (canUseNextFreeMarkerValue)
          break;
      }
    }
    else
    {
      while (nextFreeNumberMarkerValue <= maximumNumberMarkerValue && ! canUseNextFreeMarkerValue)
      {
        if (usedNumberMarkerValues.find(nextFreeNumberMarkerValue) != usedNumberMarkerValues.end())
          nextFreeNumberMarkerValue++;
        else
          canUseNextFreeMarkerValue = true;
      }
    }
  }
  else
  {
    canUseNextFreeMarkerValue = true;
  }

  NSString* nextFreeMarker = nil;
  if (canUseNextFreeMarkerValue)
  {
    if (markupType == MarkupTypeMarkerLetter)
      nextFreeMarker = [NSString stringWithFormat:@"%c" , nextFreeLetterMarkerValue];
    else
      nextFreeMarker = [NSString stringWithFormat:@"%d" , nextFreeNumberMarkerValue];
  }
  return nextFreeMarker;
}

// -----------------------------------------------------------------------------
/// @brief TODO xxx
// -----------------------------------------------------------------------------
+ (enum MarkupType) markupTypeOfLabel:(NSString*)label
{
  [MarkupUtilities setupStaticVariablesIfNotYetSetup];

  char letterMarkerValue;
  int numberMarkerValue;
  enum MarkupType markupTypeOfLabel = [MarkupUtilities markupTypeOfLabel:label
                                                       letterMarkerValue:&letterMarkerValue
                                                       numberMarkerValue:&numberMarkerValue];
  return markupTypeOfLabel;
}

// -----------------------------------------------------------------------------
/// @brief Returns the markup type that @a label corresponds to and fills one
/// of the out variables if appropriate.
///
/// If @a label contains a single letter A-Z or a-z from the latin alphabet,
/// the return value is #MarkupTypeMarkerLetter and this method fills the out
/// variable @a letterMarkerValue with the char value of the single letter.
///
/// If @a label contains only digit characters that form an integer number in
/// the range of 1-999, the return value is #MarkupTypeMarkerNumber and this
/// method fills the out variable @a numberMarkerValue with the int value of the
/// integer number.
///
/// In all other cases the return value is #MarkupTypeLabel and the value of
/// both out variables is undefined.
// -----------------------------------------------------------------------------
+ (enum MarkupType) markupTypeOfLabel:(NSString*)label
                    letterMarkerValue:(char*)letterMarkerValue
                    numberMarkerValue:(int*)numberMarkerValue
{
  // No need to invoke MarkupUtilities::setupStaticVariablesIfNotYetSetup(),
  // this method is not part of the public API.

  NSUInteger labelLength = label.length;
  if (labelLength == 1)
  {
    // Code in this branch should hopefully be faster than using regex

    unichar labelCharacter = [label characterAtIndex:0];
    if (labelCharacter >= charUppercaseA && labelCharacter <= charuppercaseZ)
    {
      *letterMarkerValue = labelCharacter - charUppercaseA + 'A';
      return MarkupTypeMarkerLetter;
    }
    else if (labelCharacter >= charLowercaseA && labelCharacter <= charLowercaseZ)
    {
      *letterMarkerValue = labelCharacter - charLowercaseA + 'a';
      return MarkupTypeMarkerLetter;
    }
    else if (labelCharacter >= charZero && labelCharacter <= charNine)
    {
      *numberMarkerValue = labelCharacter - charZero;
      if (*numberMarkerValue >= minimumNumberMarkerValue && *numberMarkerValue <= maximumNumberMarkerValue)
        return MarkupTypeMarkerNumber;
      else
        return MarkupTypeLabel;
    }
    else
    {
      return MarkupTypeLabel;
    }
  }
  else
  {
    NSRegularExpression* regexNumbers = [[NSRegularExpression alloc] initWithPattern:@"^[0-9]+$" options:0 error:nil];
    NSRange allCharactersRange = NSMakeRange(0, labelLength);
    if ([regexNumbers numberOfMatchesInString:label options:0 range:allCharactersRange] > 0)
    {
      *numberMarkerValue = [self labelAsNumberMarkerValue:label];
      if (*numberMarkerValue != -1)
        return MarkupTypeMarkerNumber;
      else
        return MarkupTypeLabel;
    }
    else
    {
      return MarkupTypeLabel;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the number marker value that corresponds to @a label.
/// Returns -1 if conversion of @a label fails, indicating that @a label does
/// not represent a valid number marker value.
///
/// This method expects that a previous step has verified that @a label is not
/// empty and does not contain any characters that are not digits. If this is
/// not the case, then the NSNumberFormatter that is used by the implementation
/// of this method will gracefully handle leading/trailing space characters and
/// locale-specific group or decimal separators.
// -----------------------------------------------------------------------------
+ (int) labelAsNumberMarkerValue:(NSString*)label
{
  [MarkupUtilities setupStaticVariablesIfNotYetSetup];

  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
  // Parses the text as an integer number
  numberFormatter.numberStyle = NSNumberFormatterNoStyle;
  // If the string contains any characters other than numerical digits or
  // locale-appropriate group or decimal separators, parsing will fail.
  // Leading/trailing space is ignored.
  // Returns nil if parsing fails.
  NSNumber* number = [numberFormatter numberFromString:label];
  if (! number)
    return -1;

  int numberMarkerValue = [number intValue];
  if (numberMarkerValue >= minimumNumberMarkerValue && numberMarkerValue <= maximumNumberMarkerValue)
    return numberMarkerValue;
  else
    return -1;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the content of @a node warrants showing a "markup"
/// indicator to the user when displaying an overview of @a node.
// -----------------------------------------------------------------------------
+ (bool) shouldDisplayMarkupIndicatorForNode:(GoNode*)node
{
  GoNodeMarkup* nodeMarkup = node.goNodeMarkup;
  if (! nodeMarkup)
    return false;
  else
    return [nodeMarkup hasMarkup];
}

// -----------------------------------------------------------------------------
/// @brief Returns @e true if @a node has one or more markup elements on
/// @a point. Returns @e false if @a node has no markup elements on @a point.
// -----------------------------------------------------------------------------
+ (bool) markupExistsOnPoint:(GoPoint*)point forNode:(GoNode*)node
{
  enum MarkupType firstMarkupType;
  id firstMarkupInfo;
  return [MarkupUtilities markupExistsOnPoint:point
                                      forNode:node
                              firstMarkupType:&firstMarkupType
                              firstMarkupInfo:&firstMarkupInfo];

}

// -----------------------------------------------------------------------------
/// @brief Returns @e true if @a node has one or more markup elements on
/// @a point. Returns @e false if @a node has no markup elements on @a point.
///
/// If this method returns @e true, it also fills the out variable
/// @a firstMarkupType with the markup type of the first markup element that
/// was found.
///
/// If this method returns @e false, the value of @a firstMarkupType is not
/// defined.
///
/// This method looks for markup elements in this order:
/// - Symbols
/// - Markers and labels
/// - Connections
// -----------------------------------------------------------------------------
+ (bool) markupExistsOnPoint:(GoPoint*)point forNode:(GoNode*)node firstMarkupType:(enum MarkupType*)firstMarkupType
{
  id firstMarkupInfo;
  return [MarkupUtilities markupExistsOnPoint:point
                                      forNode:node
                              firstMarkupType:firstMarkupType
                              firstMarkupInfo:&firstMarkupInfo];
}

// -----------------------------------------------------------------------------
/// @brief Returns @e true if @a node has one or more markup elements on
/// @a point. Returns @e false if @a node has no markup elements on @a point.
///
/// If this method returns @e true, it also fills the out variables
/// @a firstMarkupType and @a firstMarkupInfo. @a firstMarkupType is filled with
/// the markup type of the first markup element that was found.
/// @a firstMarkupInfo is filled with an object that contains additional
/// information about the first markup element that was found.
///
/// If this method returns @e false, the values of @a firstMarkupType and
/// @a firstMarkupInfo are not defined.
///
/// This method looks for markup elements in this order:
/// - Symbols. If a symbol is found @a firstMarkupInfo is set to @e nil.
/// - Markers and labels. If a marker or label is found @a firstMarkupInfo is
///   set to an NSString object that contains the label text of the marker or
///   label.
/// - Connections. If a connection is found, @a firstMarkupInfo is set to an
///   NSArray object that contains two NSString objects that define the start
///   and end intersections of the connection.
// -----------------------------------------------------------------------------
+ (bool) markupExistsOnPoint:(GoPoint*)point forNode:(GoNode*)node firstMarkupType:(enum MarkupType*)firstMarkupType firstMarkupInfo:(id*)firstMarkupInfo
{
  GoNodeMarkup* nodeMarkup = node.goNodeMarkup;
  if (! nodeMarkup)
    return false;

  NSString* intersection = point.vertex.string;

  NSDictionary* symbols = nodeMarkup.symbols;
  if (symbols)
  {
    NSNumber* symbolAsNumber = symbols[intersection];
    if (symbolAsNumber)
    {
      enum GoMarkupSymbol symbol = static_cast<enum GoMarkupSymbol>(symbolAsNumber.intValue);
      *firstMarkupType = [MarkupUtilities markupTypeForSymbol:symbol];
      *firstMarkupInfo = nil;
      return true;
    }
  }

  NSDictionary* labels = nodeMarkup.labels;
  if (labels)
  {
    NSString* label = labels[intersection];
    if (label)
    {
      *firstMarkupType = [MarkupUtilities markupTypeOfLabel:label];
      *firstMarkupInfo = label;
      return true;
    }
  }

  NSDictionary* connections = nodeMarkup.connections;
  if (connections)
  {
    for (NSArray* key in connections.allKeys)
    {
      if ([key containsObject:intersection])
      {
        NSNumber* connectionAsNumber = connections[key];
        enum GoMarkupConnection connection = static_cast<enum GoMarkupConnection>(connectionAsNumber.intValue);
        *firstMarkupType = [MarkupUtilities markupTypeForConnection:connection];
        *firstMarkupInfo = key;
        return true;
      }
    }
  }

  // Dummy values, to avoid crashes due to uninitialized variables
  *firstMarkupType = MarkupTypeSymbolCircle;
  *firstMarkupInfo = nil;

  return false;
}

@end
