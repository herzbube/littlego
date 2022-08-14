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


@implementation MarkupUtilities

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
/// @brief Analyzes all label texts in @a nodeMarkup and returns a marker label
/// text of the label type @a labelType. Raises an exception if @a labelType
/// does not refer to a marker type. Returns @e nil if all markers of the
/// requested type are already in use.
///
/// @exception InvalidArgumentException Is thrown if @a labelType is neither
/// #GoMarkupLabelMarkerLetter nor #GoMarkupLabelMarkerNumber.
// -----------------------------------------------------------------------------
+ (NSString*) nextFreeMarkerOfType:(enum GoMarkupLabel)labelType
                      inNodeMarkup:(GoNodeMarkup*)nodeMarkup
                    fillMarkerGaps:(bool)fillMarkerGaps
{
  if (labelType != GoMarkupLabelMarkerLetter && labelType != GoMarkupLabelMarkerNumber)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"nextFreeMarkerOfType:inNodeMarkup:fillMarkerGaps: failed: invalid label type %d" argumentValue:labelType];
    return nil;  // dummy return to make compiler happy
  }

  char nextFreeLetterMarkerValue = 'A';
  int nextFreeNumberMarkerValue = gMinimumNumberMarkerValue;
  bool canUseNextFreeMarkerValue = false;

  NSDictionary* labels = nodeMarkup.labels;
  if (labels)
  {
    std::set<char> usedLetterMarkerValues;
    std::set<char> usedNumberMarkerValues;
    for (NSArray* existingLabelTypeAndText in labels.allValues)
    {
      NSNumber* existingLabelTypeAsNumber = existingLabelTypeAndText.firstObject;
      enum GoMarkupLabel existingLabelType = static_cast<enum GoMarkupLabel>(existingLabelTypeAsNumber.intValue);
      if (existingLabelType != labelType)
        continue;

      NSString* labelText = existingLabelTypeAndText.lastObject;

      char letterMarkerValue;
      int numberMarkerValue;
      [GoNodeMarkup labelTypeOfLabel:labelText
                   letterMarkerValue:&letterMarkerValue
                   numberMarkerValue:&numberMarkerValue];

      if (existingLabelType == GoMarkupLabelMarkerLetter)
        usedLetterMarkerValues.insert(letterMarkerValue);
      else if (existingLabelType == GoMarkupLabelMarkerNumber)
        usedNumberMarkerValues.insert(numberMarkerValue);
    }

    if (labelType == GoMarkupLabelMarkerLetter)
    {
      std::vector<std::pair<char, char> > letterMarkerValueRanges;
      letterMarkerValueRanges.push_back(std::make_pair('A', 'Z'));
      letterMarkerValueRanges.push_back(std::make_pair('a', 'z'));

      for (auto letterMarkerValueRange : letterMarkerValueRanges)
      {
        nextFreeLetterMarkerValue = letterMarkerValueRange.first;
        while (nextFreeLetterMarkerValue <= letterMarkerValueRange.second && ! canUseNextFreeMarkerValue)
        {
          bool nextFreeLetterMarkerValueIsUsed = (usedLetterMarkerValues.erase(nextFreeLetterMarkerValue) != 0);
          if (nextFreeLetterMarkerValueIsUsed)
          {
            nextFreeLetterMarkerValue++;
          }
          else
          {
            if (fillMarkerGaps || usedLetterMarkerValues.empty())
              canUseNextFreeMarkerValue = true;
            else
              nextFreeLetterMarkerValue++;
          }
        }

        if (canUseNextFreeMarkerValue)
          break;
      }
    }
    else
    {
      while (nextFreeNumberMarkerValue <= gMaximumNumberMarkerValue && ! canUseNextFreeMarkerValue)
      {
        bool nextFreeNumberMarkerValueIsUsed = (usedNumberMarkerValues.erase(nextFreeNumberMarkerValue) != 0);
        if (nextFreeNumberMarkerValueIsUsed)
        {
          nextFreeNumberMarkerValue++;
        }
        else
        {
          if (fillMarkerGaps || usedNumberMarkerValues.empty())
            canUseNextFreeMarkerValue = true;
          else
            nextFreeNumberMarkerValue++;
        }
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
    if (labelType == GoMarkupLabelMarkerLetter)
      nextFreeMarker = [NSString stringWithFormat:@"%c" , nextFreeLetterMarkerValue];
    else
      nextFreeMarker = [NSString stringWithFormat:@"%d" , nextFreeNumberMarkerValue];
  }
  return nextFreeMarker;
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
/// If @a ignoreLabels is true this method ignores markup of type
/// #GoMarkupLabelLabel.
// -----------------------------------------------------------------------------
+ (bool) markupExistsOnPoint:(GoPoint*)point forNode:(GoNode*)node ignoreLabels:(bool)ignoreLabels
{
  enum MarkupType firstMarkupType;
  id firstMarkupInfo;
  return [MarkupUtilities markupExistsOnPoint:point
                                      forNode:node
                                 ignoreLabels:ignoreLabels
                              firstMarkupType:&firstMarkupType
                              firstMarkupInfo:&firstMarkupInfo];

}

// -----------------------------------------------------------------------------
/// @brief Returns @e true if @a node has one or more markup elements on
/// @a point. Returns @e false if @a node has no markup elements on @a point.
/// If @a ignoreLabels is true this method ignores markup of type
/// #GoMarkupLabelLabel.
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
/// - Markers and labels. If @a ignoreLabels is true then a label is ignored if
///   one exists, i.e. the label is treated as if it did not exist.
/// - Connections
// -----------------------------------------------------------------------------
+ (bool) markupExistsOnPoint:(GoPoint*)point forNode:(GoNode*)node ignoreLabels:(bool)ignoreLabels firstMarkupType:(enum MarkupType*)firstMarkupType
{
  id firstMarkupInfo;
  return [MarkupUtilities markupExistsOnPoint:point
                                      forNode:node
                                 ignoreLabels:ignoreLabels
                              firstMarkupType:firstMarkupType
                              firstMarkupInfo:&firstMarkupInfo];
}

// -----------------------------------------------------------------------------
/// @brief Returns @e true if @a node has one or more markup elements on
/// @a point. Returns @e false if @a node has no markup elements on @a point.
/// If @a ignoreLabels is true this method ignores markup of type
/// #GoMarkupLabelLabel.
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
///   label. If @a ignoreLabels is true then a label is ignored if one exists,
///   i.e. the label is treated as if it did not exist.
/// - Connections. If a connection is found, @a firstMarkupInfo is set to an
///   NSArray object that contains two NSString objects that define the start
///   and end intersections of the connection.
// -----------------------------------------------------------------------------
+ (bool) markupExistsOnPoint:(GoPoint*)point
                     forNode:(GoNode*)node
                ignoreLabels:(bool)ignoreLabels
             firstMarkupType:(enum MarkupType*)firstMarkupType
             firstMarkupInfo:(id*)firstMarkupInfo
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
    NSArray* existingLabelTypeAndText = labels[intersection];
    if (existingLabelTypeAndText)
    {
      NSNumber* existingLabelTypeAsNumber = existingLabelTypeAndText.firstObject;
      enum GoMarkupLabel existingLabelType = static_cast<enum GoMarkupLabel>(existingLabelTypeAsNumber.intValue);
      if (existingLabelType != GoMarkupLabelLabel || (existingLabelType == GoMarkupLabelLabel && ! ignoreLabels))
      {
        *firstMarkupType = [MarkupUtilities markupTypeForLabel:existingLabelType];
        *firstMarkupInfo = existingLabelTypeAndText.lastObject;
        return true;
      }
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
