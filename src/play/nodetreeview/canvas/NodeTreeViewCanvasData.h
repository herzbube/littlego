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
@class GoNode;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewCanvasData class is a collection of data elements
/// that are the result of the canvas calculation algorithm implemented by
/// NodeTreeViewCanvas.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCanvasData : NSObject
{
}

/// @brief Maps GoNode objects to NodeTreeViewBranchTuple objects.
///
/// The dictionary key is an NSValue object that enapsulates a GoNode object
/// (because GoNode does not support being used directly as a dictionary key).
///
/// The dictionary value is the NodeTreeViewBranchTuple object that represents
/// the GoNode.
@property(nonatomic, retain) NSMutableDictionary* nodeMap;

/// @brief Stores branches in depth-first order. Elements are
/// NodeTreeViewBranch objects.
@property(nonatomic, retain) NSMutableArray* branches;

/// @brief Index position = Move number - 1 (e.g. first move is at index
/// position 0). Element at index position = List of NodeTreeViewBranchTuple
/// objects, each of which represents a node in a different branch that
/// refers to a move with the same move number.
@property(nonatomic, retain) NSMutableArray* branchTuplesForMoveNumbers;

/// @brief The highest move number (1-based) of any move that appears in two
/// or more branches. -1 if there are no moves that appear in two or more
/// branches.
@property(nonatomic, assign) int highestMoveNumberThatAppearsInAtLeastTwoBranches;

/// @brief Stores a reference to the GoNode object whose content is shown by
/// the current board position.
@property(nonatomic, retain) GoNode* currentBoardPositionNode;

/// @brief Maps NodeTreeViewCellPosition objects to NodeTreeViewCell objects.
///
/// This dictionary provides the data that is consumed by the node tree view's
/// drawing routines.
@property(nonatomic, retain) NSMutableDictionary* cellsDictionary;

/// @brief The highest x-position of any cell in @a cellsDictionary, i.e. the
/// zero-based width of the canvas.
@property(nonatomic, assign) unsigned short highestXPosition;

/// @brief A GoNode object which is represented by a cell in @a cellsDictionary
/// whose x-position is equal to @e highestXPosition.
@property(nonatomic, assign) GoNode* highestXPositionNode;

/// @brief The highest y-position of any cell in @a cellsDictionary, i.e. the
/// zero-based height of the canvas.
@property(nonatomic, assign) unsigned short highestYPosition;

/// @brief Maps NodeTreeViewCellPosition objects to NodeNumbersViewCell objects.
///
/// This dictionary provides the data that is consumed by the node numbers
/// view's drawing routines.
@property(nonatomic, retain) NSMutableDictionary* nodeNumbersViewCellsDictionary;

/// @brief Ordered list of tuples describing which node numbers were generated.
/// List elements are NSArray objects, each representing a tuple. Each tuple
/// has two values: Value 1 (index position 0 in the tuple NSArray) is an
/// NodeTreeViewBranchTuple object referring to the node that was considered
/// for numbering. Value 2 (index position 1 in the tuple NSArray) is an
/// NSNumber encapsulating a boolean value that indicates whether the node was
/// numbered or not.
///
/// The first <n> tuples in the ordered list are guaranteed to refer to the
/// nodes in the current game variation, in the order in which they appear in
/// the current game variation. The tuple at index position 0 therefore refers
/// to the root node, the tuple at index position <n-1> refers to the leaf node
/// of the current game variation.
///
/// The ordered list may contain more than <n> tuples. If that is the case, the
/// tuples at index positions <n> and beyond refer to nodes in the longest game
/// variation. See rule 9 of the node numbering algorithm for details.
///
/// @note If a node number is generated solely to mark the selected node, the
/// tuple that refers to the selected node is not updated to have @e true as
/// the tuple value 2.
@property(nonatomic, retain) NSMutableArray* nodeNumberingTuples;

@end
