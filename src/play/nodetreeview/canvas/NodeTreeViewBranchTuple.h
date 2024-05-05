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


// Forward declarations
@class GoNode;
@class NodeTreeViewBranch;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewBranchTuple class is a class that collects
/// information about a node and its representation on the canvas.
///
/// All member variables of NodeTreeViewBranchTuple are publicly accessible,
/// i.e. without intermediate property getter/setter methods, so that the
/// expensive canvas calculation algorithm can operate as fast and efficient as
/// possible.
// -----------------------------------------------------------------------------
@interface NodeTreeViewBranchTuple : NSObject
{
@public
  /// @brief The node that the NodeTreeViewBranchTuple represents.
  GoNode* node;
  /// @brief The 0-based number to display for the node at the top of the node
  /// tree view. The user preference "numbering style" determines the meaning
  /// of the node number.
  int nodeNumber;
  /// @brief The x-position on the canvas of the first cell that has content
  /// representing @e node.
  unsigned short xPositionOfFirstCell;
  /// @brief The number of cells that are needed to represent  @a node on the
  /// canvas.
  unsigned short numberOfCellsForNode;
  /// @brief Index position of the cell that is at the horizontal center of all
  /// cells that together represent @e node on the canvas.
  ///
  /// It is expected that @e numberOfCellsForNode is an uneven number so that
  /// the center cell is at the @b exact geometric center. This is important
  /// later on when vertical branching lines are drawn at the geometric center
  /// of the center cell.
  unsigned short indexOfCenterCell;
  /// @brief The NodeTreeViewCellSymbol enumeration value that represents
  /// @e node on the canvas.
  enum NodeTreeViewCellSymbol symbol;
  /// @brief @e true if @e node is part of the game variation that GoNodeModel
  /// is currently configured with.
  bool nodeIsInCurrentGameVariation;
  /// @brief @e true if @e node is the node whose content is shown by the
  /// current board position.
  bool nodeIsCurrentBoardPositionNode;
  /// @brief The branch that @e node belongs to.
  NodeTreeViewBranch* branch;
  /// @brief List of child branches (NodeTreeViewBranch objects) that originate
  /// from @e node. The list is empty if no child branches originate from
  /// @e node.
  NSMutableArray* childBranches;
  /// @brief The next NodeTreeViewBranchTuple object in @e branch after this
  /// NodeTreeViewBranchTuple.
  NodeTreeViewBranchTuple* nextBranchTupleInBranch;
}

@end
