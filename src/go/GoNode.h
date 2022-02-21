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
@class GoMove;
@class GoNodeAnnotation;


// -----------------------------------------------------------------------------
/// @brief The GoNode class represents a node in a tree of nodes. The tree model
/// corresponds directly to the one in SgfcKit (and therefore SGF).
///
/// @ingroup go
///
/// The public interface of GoNode has methods that allow to navigate the game
/// tree, but it does not allow to modify the game tree. This functionality is
/// provided by the separate GoNodeAdditions category that enhances the GoNode
/// interface.
///
/// The linking between nodes in the game tree is effected by the three
/// primitive properties @e firstChild, @e nextSibling and @e parent. These
/// three primitive properties are cheap to use and do not incur any calculation
/// overhead. All other properties (e.g. @e previousSibling, @e lastChild,
/// @e children) and methods (e.g. isDescendantOfNode:(), isAncestorOfNode:())
/// are in some way or other based on the three primitive properties and require
/// a certain amount of processing time for calculation.
// -----------------------------------------------------------------------------
@interface GoNode : NSObject <NSCoding>
{
}

+ (GoNode*) node;
+ (GoNode*) nodeWithMove:(GoMove*)goMove;

/// @name Node tree navigation
//@{
/// @brief Returns the node's first child node. Returns @e nil if
/// the node has no children.
@property(nonatomic, retain, readonly) GoNode* firstChild;

/// @brief Returns the node's last child node. Returns @e nil if
/// the node has no children.
@property(nonatomic, retain, readonly) GoNode* lastChild;

/// @brief Returns a collection of child nodes of the node. The collection
/// is ordered, beginning with the first child node and ending with the
/// last child node. The collection is empty if the node has no children.
@property(nonatomic, retain, readonly) NSArray* children;

/// @brief Returns YES if the node has one or more children. Returns
/// false if the node has no children.
@property(nonatomic, readonly) bool hasChildren;

/// @brief Returns the node's next sibling node. Returns @e nil if
/// the node has no next sibling node, i.e. if the node is the last child
/// of its parent.
@property(nonatomic, retain, readonly) GoNode* nextSibling;

/// @brief Returns YES if the node has a next sibling node. Returns false
/// if the node has no next sibling node, i.e. if the node is the last child
/// of its parent.
@property(nonatomic, readonly) bool hasNextSibling;

/// @brief Returns the node's previous sibling node. Returns @e nil if
/// the node has no previous sibling node, i.e. if the node is the first
/// child of its parent.
///
/// Use this property with care. Unlike the properties @e firstChild,
/// @e nextSibling and @e parent the implementation of this property has
/// a substantial processing cost.
@property(nonatomic, retain, readonly) GoNode* previousSibling;

/// @brief Returns YES if the node has a previous sibling node. Returns
/// false if the node has no previous sibling node, i.e. if the node is the
/// first child of its parent.
///
/// Use this property with care. Unlike the properties @e hasFirstChild,
/// @e hasNextSibling and @e hasParent the implementation of this property has
/// a substantial processing cost.
@property(nonatomic, readonly) bool hasPreviousSibling;

/// @brief Returns the node's parent node. Returns @e nil if the node
/// has no parent node, i.e. if the node is the root node of a node tree.
///
/// The reference to the parent node is weak, i.e. child nodes do not retain
/// their parent node. This is important to avoid a retain cycle between a
/// parent node and its first child node.
@property(nonatomic, assign, readonly) GoNode* parent;

/// @brief Returns true if the node has a parent node. Returns false if the
/// node has no parent node, i.e. if the node is the root node of a node
/// tree.
@property(nonatomic, readonly) bool hasParent;

/// @brief Returns true if the node is a descendant of @a node, i.e. if the
/// node is anywhere below @a node in the node tree. Returns false if the
/// node is not a descendant of @a node.
///
/// @exception NSInvalidArgumentException Is raised if @a node is @e nil.
- (bool) isDescendantOfNode:(GoNode*)node;

/// @brief Returns true if the node is an ancestor of @a node, i.e. if the
/// node is a direct or indirect parent of @a node. Returns false if the
/// node is not an ancestor of @a node.
///
/// @exception NSInvalidArgumentException Is raised if @a node is @e nil.
- (bool) isAncestorOfNode:(GoNode*)node;

/// @brief Returns true if the node is the root node of a node tree. Returns
/// false if the node is not the root node of a node tree.
@property(nonatomic, readonly) bool isRoot;
//@}

/// @name Node data
//@{
/// @brief The move data associated with this node. @e nil if this node has no
/// associated move. The default value is @e nil.
@property(nonatomic, retain, readonly) GoMove* goMove;

/// @brief The node annotation data associated with this node. @e nil if this
/// node has no associated node annotation data. The default value is @e nil.
@property(nonatomic, retain) GoNodeAnnotation* goNodeAnnotation;
//@}

/// @name Changing the board based upon the node's data
//@{
/// @brief Modifies the board to reflect the data that is present in this
/// GoNode.
- (void) modifyBoard;

/// @brief Reverts the board to the state it had before modifyBoard() was
/// invoked.
- (void) revertBoard;
//@}

@end
