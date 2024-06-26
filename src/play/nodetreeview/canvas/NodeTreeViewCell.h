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
/// @brief The NodeTreeViewCell class represents a cell on the abstract node
/// tree view canvas. NodeTreeViewCell contains data that describes the content
/// that should be drawn when the cell is rendered on screen. A NodeTreeViewCell
/// and its position on the node tree view canvas is uniquely identified by a
/// NodeTreeViewCellPosition value.
///
/// NodeTreeViewCell can be either a standalone cell, or it can form, together
/// with other NodeTreeViewCell objects, a multipart cell that extends in
/// x-direction across the canvas. The NodeTreeViewCell objects that form a
/// multipart cell have the same values for those properties that refer to the
/// symbol they depict (@e symbol, @e selected), but the value of the property
/// @e part indicates which section of the symbol should be drawn for that
/// particular NodeTreeViewCell object. Example:
/// - A multipart cell consists of two cells and should render the symbol for
///   a black move.
/// - There are two NodeTreeViewCell objects that make up the multipart cell.
/// - The property @e symbol of all NodeTreeViewCell objects has the value
///   #NodeTreeViewCellSymbolBlackMove.
/// - The property @e part of the first/second NodeTreeViewCell object has the
///   value 1/2.
/// - The rendering process thus knows that it should draw the left/right half
///   of the symbol for the first/second NodeTreeViewCell.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCell : NSObject
{
}

+ (NodeTreeViewCell*) emptyCell;

- (BOOL) isEqualToCell:(NodeTreeViewCell*)otherCell;

/// @brief Value that indicates which symbol should be drawn in the cell. Is
/// #NodeTreeViewCellSymbolNone if no symbol should be drawn in the cell.
///
/// If the value of this property is #NodeTreeViewCellSymbolNone, then the value
/// of the property @e lines should not be #NodeTreeViewCellLineNone.
@property(nonatomic, assign) enum NodeTreeViewCellSymbol symbol;

/// @brief @e true if the cell is currently selected. @e false if the cell is
/// currently not selected.
///
/// If the value of this property is @e true, then the value of the property
/// @e symbol should not be #NodeTreeViewCellSymbolNone.
@property(nonatomic, assign, getter=isSelected) bool selected;

/// @brief Value that indicates which branching lines should be drawn in the
/// cell. Is #NodeTreeViewCellLineNone if no branching lines should be drawn in
/// the cell.
///
/// If the value of this property is #NodeTreeViewCellLineNone, then the value
/// of the property @e symbol should not be #NodeTreeViewCellSymbolNone.
@property(nonatomic, assign) NodeTreeViewCellLines lines;

/// @brief Value that indicates which branching lines in the cell belong to the
/// currently selected game variation. These lines are drawn in a different
/// style than the lines that do not belong to the currently selected game
/// variation. Is #NodeTreeViewCellLineNone if no branching in the cell belong
/// to the currently selected game variation.
///
/// If the value of this property is not #NodeTreeViewCellLineNone, then this
/// property holds a subset of the branching lines stored in the property
/// @e lines.
@property(nonatomic, assign) NodeTreeViewCellLines linesSelectedGameVariation;

/// @brief @e true if the cell is not standalone but belongs to a multipart
/// cell. @e false if the cell is standalone and does not belong to a multipart
/// cell.
///
/// If the value of this property is @e true, then the value of the property
/// @e parts is greater than 1.
@property(nonatomic, assign, readonly, getter=isMultipart) bool multipart;

/// @brief Denotes which part of a multipart cell the cell is. The value of this
/// property is zero-based, i.e. it can be treated like an array index.
@property(nonatomic, assign) unsigned short part;

/// @brief Denotes how many parts the multipart cell that the cell belongs to
/// consists of. Value 1 denotes that the cell is standalone.
@property(nonatomic, assign) unsigned short parts;

@end
