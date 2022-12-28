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


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewModel class translates the data of the underlying
/// GoNodeModel into a format that is suitable for NodeTreeView.
///
/// NodeTreeViewModel works with the concept of a rectangular canvas. The canvas
/// has two dimensions: A width (x-direction) and a height (y-direction). The
/// canvas origin is in the top-left corner.
///
/// NodeTreeViewModel maps every node in the tree of nodes onto an x/y
/// coordinate of the canvas. NodeTreeViewModel performs this mapping in a
/// manner so that the tree is in a lying position (i.e. not in an upright
/// position) and has the direction left-to-right. In other words:
/// - The root node is in the top-left corner of the canvas at the coordinates
///   0/0 (= the origin).
/// - The tree‘s height (aka depth) extends in x-direction.
/// - The tree’s width extends in y-direction.
///
/// The canvas defined by NodeTreeViewModel is abstract and does not reflect the
/// position or direction how the tree of nodes is actually rendered. For
/// instance, the tree might be rendered in upright position, with the root node
/// at the top. Abstract canvas coordinates therefore need to be mapped onto
/// render canvas coordinates, and from there onto screen coordinates.
///
/// @par Design and implementation notes
///
/// NodeTreeViewModel was designed and implemented according to the following
/// principles:
/// - Lookup by the rendering process via public API should be fast.
/// - When changes in the underlying GoNodeModel occur, updates in
///   NodeTreeViewModel should be fast.
/// - Memory usage should be minimized, but processing speed clearly trumps
///   memory consumption, while keeping an eye on the latter.
///
/// TODO xxx document more
// -----------------------------------------------------------------------------
@interface NodeTreeViewModel : NSObject
{
}

- (id) init;

- (void) readUserDefaults;
- (void) writeUserDefaults;

- (NodeTreeViewCell*) cellAtPosition:(NodeTreeViewCellPosition*)position;
- (NSArray*) cellsInRow:(int)row;

/// @brief The canvas width. This corresponds to the height (aka depth) of the
/// node tree. In a tabular model, this can also be seen as the number of
/// columns.
@property(nonatomic, assign) int canvasWidth;
/// @brief The canvas height. This corresponds to the width of the node tree.
/// In a tabular model, this can also be seen as the number of rows.
@property(nonatomic, assign) int canvasHeight;

@end
