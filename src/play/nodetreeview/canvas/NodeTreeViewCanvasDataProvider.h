// -----------------------------------------------------------------------------
// Copyright 2024 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoNode;
@class NodeTreeViewCellPosition;

// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewCanvasDataProvider protocol defines the properties
/// and operations needed by consumers of node tree view canvas data.
// -----------------------------------------------------------------------------
@protocol NodeTreeViewCanvasDataProvider <NSObject>

@required

/// @brief The canvas size. Width and height are integral numbers.
///
/// The canvas width corresponds to the height (aka depth) of the node tree. In
/// a tabular model, this can also be seen as the number of columns.
///
/// The canvas height corresponds to the width of the node tree. In a tabular
/// model, this can also be seen as the number of rows.
@property(nonatomic, assign, readonly) CGSize canvasSize;

/// @brief Returns the GoNode object that is represented by the cell that is
/// located at position @a position. Returns @e nil if @a position denotes a
/// position that is outside the canvas' bounds, or if the cell located at
/// position @a position does not represent a GoNode.
- (GoNode*) nodeAtPosition:(NodeTreeViewCellPosition*)position;

@end
