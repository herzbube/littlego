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
@class NodeTreeViewBranchTuple;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewBranch class represents a branch to be drawn in the
/// node tree view.
///
/// All member variables of NodeTreeViewBranch are publicly accessible,
/// i.e. without intermediate property getter/setter methods, so that the
/// expensive canvas calculation algorithm can operate as fast and efficient as
/// possible.
// -----------------------------------------------------------------------------
@interface NodeTreeViewBranch : NSObject
{
@public
  /// @brief The last child branch of this NodeTreeViewBranch. Is @e nil if
  /// this NodeTreeViewBranch has no child branches.
  NodeTreeViewBranch* lastChildBranch;
  /// @brief The previous sibling branch of this NodeTreeViewBranch. Is @e nil
  /// if this NodeTreeViewBranch has no previous sibling branches, i.e. if this
  /// NodeTreeViewBranch is the first child branch of @e parentBranch.
  NodeTreeViewBranch* previousSiblingBranch;
  /// @brief The parent branch of this NodeTreeViewBranch. Is @e nil if
  /// this NodeTreeViewBranch has no parent branch, i.e. if this
  /// NodeTreeViewBranch is the main branch.
  NodeTreeViewBranch* parentBranch;
  /// @brief The NodeTreeViewBranchTuple in @e parentBranch that contains the
  /// branching node from which this NodeTreeViewBranch is originating.
  NodeTreeViewBranchTuple* parentBranchTupleBranchingNode;
  /// @brief List of NodeTreeViewBranchTuple objects that make up the content
  /// of this NodeTreeViewBranch. Contains always at least one object.
  NSMutableArray* branchTuples;
  /// @brief The y-position on the canvas of the branch.
  unsigned short yPosition;
}

@end
