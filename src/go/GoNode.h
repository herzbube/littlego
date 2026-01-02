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
@class GoGame;
@class GoMove;
@class GoNodeAnnotation;
@class GoNodeMarkup;
@class GoNodeSetup;
@class GoNodeTimeData;


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
///
///
/// @par Time data validity
///
/// The properties @e isTimeDataValid and @e timeDataInvalidReason store
/// information about the validity of time data in the node and all of its
/// @b predecessor nodes on the path back to the root node. Time validity is
/// stored on the node level, and not in GoNodeTimeData as one might expect,
/// because one of the reasons why time data can be invalid is that
/// GoNodeTimeData is missing.
///
/// The reason why time data is not valid applies to the first node on the path
/// @b from the root node whose @e isTimeDataValid property has value false.
/// Note that there are a few invalid reasons that refer to a problem with the
/// game's time system(s) - in these cases the invalidity is not caused by the
/// time data in the node. In these cases, already the root node will indicate
/// that time data is invalid. Because the root node never has a GoNodeTimeData
/// object, this is another reason why time validity is not stored in
/// GoNodeTimeData.
///
/// Time data validity information is important when new moves are played.
/// If time data is valid up to the currently selected node at the time when a
/// move is played, then it makes sense to continue recording time data for the
/// new move. To optimize decisions in various places whether or not to record
/// time data, the validity information is stored per node. The information is
/// not archived, because it can be easily recalculated upon unarchiving.
///
/// Time data is considered valid if it allows the app to support timed play.
/// Specifically this means all of the following conditions must be met:
/// - There is at least one time system that is supported by the app.
/// - And there is no time system that the app does not support.
/// - And the time data in a node and all of its predecessor nodes is
///   consistent.
/// - And the time data in a node and all of its predecessor nodes does not
///   contradict the rules of the time system(s).
///
/// Time data is considered invalid if it prevents the app from supporting
/// timed play. Specifically this means one or more of the following
/// conditions are met:
/// - There is no time system.
/// - Or there is a custom time system that the app does not understand.
/// - Or the time data in a node, or in one of its predecessor nodes, is
///   inconsistent.
/// - Or the time data in a node, or in one of its predecessor nodes,
///   contradicts the rules of the time system(s).
///
/// After initialization, the time data in a GoNode object is considered
/// invalid. The properties @e isTimeDataValid and @e invalidReason hold the
/// values @e true and -1, respectively, which corresponds to the values of the
/// constant #GoTimeDataValidationResultInvalid. Once the time data in a node
/// has been validated, the two properties receive their actual values.
// -----------------------------------------------------------------------------
@interface GoNode : NSObject <NSSecureCoding>
{
}

/// @name Initialization
//@{
+ (GoNode*) node;
//@}

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

/// @brief Returns @e true if the node has one or more children. Returns
/// @e false if the node has no children, i.e. if it is a leaf node.
@property(nonatomic, readonly) bool hasChildren;

/// @brief Returns @e true if the node is a branching node, i.e. if it has more
/// than one child. Returns @e false if the node is not a branching node.
@property(nonatomic, readonly) bool isBranchingNode;

/// @brief Returns the node's next sibling node. Returns @e nil if
/// the node has no next sibling node, i.e. if the node is the last child
/// of its parent.
@property(nonatomic, retain, readonly) GoNode* nextSibling;

/// @brief Returns @e true if the node has a next sibling node. Returns @e false
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

/// @brief Returns @e true if the node has a previous sibling node. Returns
/// @e false if the node has no previous sibling node, i.e. if the node is the
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

/// @brief Returns @e true if the node has a parent node. Returns @e false if
/// the node has no parent node, i.e. if the node is the root node of a node
/// tree.
@property(nonatomic, readonly) bool hasParent;

/// @brief Returns @e true if the node is a descendant of @a node, i.e. if the
/// node is anywhere below @a node in the node tree. Returns @e false if the
/// node is not a descendant of @a node.
///
/// @exception NSInvalidArgumentException Is raised if @a node is @e nil.
- (bool) isDescendantOfNode:(GoNode*)node;

/// @brief Returns @e true if the node is an ancestor of @a node, i.e. if the
/// node is a direct or indirect parent of @a node. Returns @e false if the
/// node is not an ancestor of @a node.
///
/// @exception NSInvalidArgumentException Is raised if @a node is @e nil.
- (bool) isAncestorOfNode:(GoNode*)node;

/// @brief Returns @e true if the node is the root node of a node tree, i.e. if
/// the node has no parent. Returns @e false if the node is not the root node
/// of a node tree.
@property(nonatomic, readonly) bool isRoot;

/// @brief Returns @e true if the node is a leaf node, i.e. if the node has no
/// children. Returns @e false if the node is not a leaf node.
@property(nonatomic, readonly) bool isLeaf;
//@}

/// @name Node data
//@{
/// @brief @e true if the node is empty and contains no data, @e false if the
/// node is not empty and contains some data.
///
/// A node is empty if it has no setup data (property @e goNodeSetup is @e nil
/// or the GoNodeSetup object's property @e isEmpty is @e true), no move data
/// (property @e goMove is @e nil), no annotation data (property
/// @e goNodeAnnotation is @e nil), no markup data (property @e goNodeMarkup
/// is @e nil or the GoNodeMarkup object's property @e hasMarkup is @e false)
/// and no time data (property @e goNodeTimeData is @e nil).
@property(nonatomic, assign, getter=isEmpty, readonly) bool empty;

/// @brief The game setup data associated with this node. @e nil if this node
/// has no associated game setup data. The default value is @e nil.
@property(nonatomic, retain) GoNodeSetup* goNodeSetup;

/// @brief The move data associated with this node. @e nil if this node has no
/// associated move. The default value is @e nil.
@property(nonatomic, retain) GoMove* goMove;

/// @brief The node annotation data associated with this node. @e nil if this
/// node has no associated node annotation data. The default value is @e nil.
@property(nonatomic, retain) GoNodeAnnotation* goNodeAnnotation;

/// @brief The markup data associated with this node. @e nil if this
/// node has no associated markup data. The default value is @e nil.
@property(nonatomic, retain) GoNodeMarkup* goNodeMarkup;

/// @brief The time data associated with this node. @e nil if this
/// node has no associated time data. The default value is @e nil.
@property(nonatomic, retain) GoNodeTimeData* goNodeTimeData;
//@}

/// @brief Zobrist hash that identifies the board position created by this node.
/// Zobrist hashes are used to detect ko, and especially superko.
@property(nonatomic, assign) long long zobristHash;

/// @name Time data validity
//@{
/// @brief True if the time data in this node and all of its predecessor nodes
/// is valid. False if time data is not valid. In the latter case, the value of
/// property @e timeDataInvalidReason indicates the reason why the time data is
/// not valid.
///
/// The default value after initialization is false.
///
/// See the class documentation for details about time (in)validity.
@property(nonatomic, assign) bool isTimeDataValid;

/// @brief If property @e isTimeDataValid is false, indicates the reason why
/// the time data is not valid. If property @e isTimeDataValid is true, this
/// property has value -1.
///
/// The default value after initialization is -1.
///
/// See the class documentation for details about time (in)validity.
@property(nonatomic, assign) enum GoTimeDataInvalidReason timeDataInvalidReason;
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

/// @name Calculating the Zobrist hash
//@{
/// @brief Calculates the node's Zobrist hash and updates the property
/// @e zobristHash with the new Zobrist hash.
///
/// The Zobrist hash calculation uses the parent node's Zobrist hash as the base
/// and combines it with the current board state. See GoZobristTable for
/// details.
///
/// @attention A new node must have been added to the node tree when this method
/// is invoked, otherwise the parent node is not known.
- (void) calculateZobristHash:(GoGame*)game;
//@}

@end
