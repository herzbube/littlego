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


// Forward declarations
@class NodeTreeViewCell;
@class NodeTreeViewCellPosition;
@class NodeTreeViewModel;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewCanvas class represents an abstract canvas containing
/// the data that needs to be drawn by the NodeTreeView. "Abstract" is meant in
/// the sense that NodeTreeViewCanvas does not provide the canvas data
/// immediately ready for drawing (e.g. by pixel or points) but in a format that
/// conceptually matches the drawing needs of NodeTreeView.
///
/// The abstract canvas that NodeTreeViewCanvas represents is rectangular. It
/// has two dimensions: A width (x-direction) and a height (y-direction). The
/// canvas origin is in the top-left corner.
///
/// The canvas can be seen as a table with columns (x-direction) and rows
/// (y-direction), therefore x/y coordinate pairs can be seen as referring to
/// "cells". NodeTreeViewCellPosition objects are used to store the x/y
/// coordinate pairs that uniquely identify the position of a cell on the
/// canvas. The data that NodeTreeView needs to render for a specific x/y
/// coordinate pair is stored in a NodeTreeViewCell object.
///
/// NodeTreeViewCanvas is responsible for tranforming the data of the underlying
/// GoNodeModel into data that makes up the canvas described above. The
/// transformation process maps every node in the tree of nodes onto one or more
/// horizontally adjacent x/y coordinates (= cells) on the canvas.
/// NodeTreeViewCanvas performs this mapping in a manner so that the tree is in
/// a lying position (i.e. not in an upright position) and has the direction
/// left-to-right. In other words:
/// - The root node is in the top-left corner of the canvas.
/// - The tree‘s height (aka depth) extends in x-direction.
/// - The tree’s width extends in y-direction.
///
/// NodeTreeViewCanvas takes a number of user preferences from NodeTreeViewModel
/// into account during data transformation. Among these the most notable is the
/// "condense move nodes" user preference:
/// - If this is @e false, i.e. move nodes are not condensed, all nodes from the
///   tree of nodes are mapped 1:1 onto cells. In other words: For every node
///   there is exactly one cell, and vice versa.
/// - If this is @e true, i.e. move nodes are condensed, only those nodes from
///   the tree of nodes that are condensed are mapped 1:1 onto cells. Nodes that
///   are uncondensed, however, are spread across multiple horizontally adjacent
///   cells. For uncondensed nodes therefore the mapping is 1:n. Adjacent cells
///   that together represent an uncondensed node are called "sub-cells" of a
///   bigger "multipart" cell. Cells that represent a condensed node, or cells
///   that contain only connection lines between nodes, are called "standalone"
///   cells.
///
/// As initially described, The canvas defined by NodeTreeViewCanvas is abstract
/// and does not reflect the position or direction how the tree of nodes is
/// actually rendered. For instance, the tree might be rendered in upright
/// position, with the root node at the top. For drawing, NodeTreeView therefore
/// needs to map abstract canvas x/y coordinates onto screen coordinates.
/// NodeTreeViewMetrics provides the necessary information to perform this task.
///
/// @par Design and implementation notes
///
/// NodeTreeViewCanvas was designed and implemented according to the following
/// principles:
/// - Lookup by the rendering process via public API should be fast.
/// - When changes in the underlying GoNodeModel occur, updates in
///   NodeTreeViewCanvas should be fast.
/// - Memory usage should be minimized, but processing speed clearly trumps
///   memory consumption, while keeping an eye on the latter.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCanvas : NSObject
{
}

- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel;

- (void) recalculateCanvas;
- (NodeTreeViewCell*) cellAtPosition:(NodeTreeViewCellPosition*)position;
- (NSArray*) selectedNodePositions;

/// @brief The canvas size. Width and height are integral numbers.
///
/// The canvas width corresponds to the height (aka depth) of the node tree. In
/// a tabular model, this can also be seen as the number of columns.
///
/// The canvas height corresponds to the width of the node tree. In a tabular
/// model, this can also be seen as the number of rows.
@property(nonatomic, assign) CGSize canvasSize;

@end
