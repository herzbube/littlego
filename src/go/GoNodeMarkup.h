// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The GoNodeMarkup class extends a game tree node with properties that
/// define extra markup to be drawn on the Go board, besides the basic move
/// information, for the board position defined by the node.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoNodeMarkup : NSObject <NSSecureCoding>
{
}

- (bool) hasMarkup;

- (void) setSymbol:(enum GoMarkupSymbol)symbol atVertex:(NSString*)vertex;
- (void) removeSymbolAtVertex:(NSString*)vertex;
- (void) replaceSymbols:(NSDictionary*)symbols;
- (void) removeAllSymbols;

- (void) setConnection:(enum GoMarkupConnection)connection fromVertex:(NSString*)fromVertex toVertex:(NSString*)toVertex;
- (void) removeConnectionFromVertex:(NSString*)fromVertex toVertex:(NSString*)toVertex;
- (void) replaceConnections:(NSDictionary*)connections;
- (void) removeAllConnections;

- (void) setLabel:(enum GoMarkupLabel)label labelText:(NSString*)labelText atVertex:(NSString*)vertex;
- (void) removeLabelAtVertex:(NSString*)vertex;
- (void) replaceLabels:(NSDictionary*)labels;
- (void) removeAllLabels;
+ (NSString*) removeNewlinesAndTrimLabel:(NSString*)labelText;
+ (enum GoMarkupLabel) labelTypeOfLabel:(NSString*)labelText;
+ (enum GoMarkupLabel) labelTypeOfLabel:(NSString*)labelText
                      letterMarkerValue:(char*)letterMarkerValue
                      numberMarkerValue:(int*)numberMarkerValue;

- (void) setDimmingAtVertex:(NSString*)vertex;
- (void) removeDimmingAtVertex:(NSString*)vertex;
- (void) replaceDimmings:(NSArray*)dimmings;
- (void) undimEverything;
- (void) removeAllDimmings;

/// @brief Symbols to draw at specific intersections on the board. Key =
/// vertex string indicating the intersection where to draw the symbol, value =
/// NSNumber encapsulating a value from the enumeration #GoMarkupSymbol,
/// indicating the type of symbol to draw. The default property value is @e nil,
/// indicating that no symbols should be drawn for the node.
///
/// The property value @e nil is the same as an empty dictionary. The value
/// @e nil is preferred because it is cheaper to serialize (both in terms of
/// processing overhead and storage capacity).
///
/// This property corresponds to the SGF markup properties CR, SQ, TR, MA, and
/// SL.
@property(nonatomic, retain, readonly) NSDictionary* symbols;

/// @brief Connections to draw between intersections on the board. Key = NSArray
/// consisting of two vertex strings that indicate the intersections to connect,
/// value = NSNumber encapsulating a value from the enumeration
/// #GoMarkupConnectionType, indicating the type of connection to be drawn (e.g.
/// arrow, line). The default property value is @e nil, indicating that no
/// connections should be drawn for the node.
///
/// The property value @e nil is the same as an empty dictionary. The value
/// @e nil is preferred because it is cheaper to serialize (both in terms of
/// processing overhead and storage capacity).
///
/// This property corresponds to the SGF markup properties AR and LN.
///
/// @note The SGF standard allows that the same pair of points can appear both
/// in the AR and in the LN property. GoNodeMarkup was designed, though, to only
/// support one connection between the same (ordered) pair of points. It simply
/// does not make sense to draw an arrow @b and a line for the same pair of
/// points. As a consequence, the data in an SGF file from an external source
/// may not be preserved in its entirety.
///
/// @note The SGF standard does not allow AR or LN property values that have the
/// same start and end point. Consequently the @e connections property value
/// can never contain a key where the NSArray contains two equal vertex strings.
@property(nonatomic, retain, readonly) NSDictionary* connections;

/// @brief Labels to draw at specific intersections on the board. Key = vertex
/// string indicating the intersection where to draw the label, value = NSArray
/// consisting of two objects: 1) An NSNumber object that encapsulates a value
/// from the enumeration #GoMarkupLabel, indicating the type of label to draw;
/// and 2) An NSString object containing the label text to draw. Label texts
/// have non-zero length and do not contain newlines or leading/trailing
/// whitespace. The default property value is @e nil, indicating that no labels
/// should be drawn for the node.
///
/// The property value @e nil is the same as an empty dictionary. The value
/// @e nil is preferred because it is cheaper to serialize (both in terms of
/// processing overhead and storage capacity).
///
/// This property corresponds to the SGF markup property LB.
///
/// @note The SGF standard allows zero-length labels. GoNodeMarkup was designed,
/// though, to only support labels that contain at least one non-whitespace
/// character. It simply does not make sense to draw an empty label or a label
/// with non-visible characters. As a consequence, the data in an SGF file from
/// an external source may not be preserved in its entirety.
///
/// @note The reason for the "no newlines" rule for label texts is that the SGF
/// standard specifies the data type for label texts to be SimpleText, and that
/// data type does not allow newlines.
@property(nonatomic, retain, readonly) NSDictionary* labels;

/// @brief Intersections to dim (grey out). Elements are string vertices,
/// indicating which intersections to dim (grey out). Dimmed intersections
/// accumulate from one node to the next. An empty array undims everything, i.e.
/// accumulated dimmings from previous nodes no longer have an effect from.
/// Value @e nil indicates no change in dimming, i.e. accumulated dimmings from
/// previous nodes still take effect. The default property value is @e nil.
///
/// This property corresponds to the SGF markup property DD.
@property(nonatomic, retain, readonly) NSArray* dimmings;

@end
