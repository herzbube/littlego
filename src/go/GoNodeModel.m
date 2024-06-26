// -----------------------------------------------------------------------------
// Copyright 2012-2024 Patrick Näf (herzbube@herzbube.ch)
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


// Project includes
#import "GoNodeModel.h"
#import "GoGame.h"
#import "GoNodeAdditions.h"
#import "GoGameDocument.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeModel.
// -----------------------------------------------------------------------------
@interface GoNodeModel()
/// @name Private properties
//@{
@property(nonatomic, assign) GoGame* game;
@property(nonatomic, retain) NSMutableArray* nodeList;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) GoNode* rootNode;
@property(nonatomic, assign, readwrite) int numberOfNodes;
@property(nonatomic, assign, readwrite) int numberOfMoves;
//@}
@end


@implementation GoNodeModel

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoNodeModel object that is associated with @a game.
/// The GoNodeModel object is initialized with an empty root node.
///
/// @note This is the designated initializer of GoNodeModel.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)game
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.game = game;
  self.rootNode = [GoNode node];
  self.nodeList = [NSMutableArray arrayWithObject:self.rootNode];
  self.numberOfNodes = 1;
  self.numberOfMoves = 0;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoNodeModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  self.rootNode = nil;
  self.nodeList = nil;

  [super dealloc];
}

#pragma mark - NSCoding overrides

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;

  NSDictionary* nodeDictionary = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSNumber class], [GoNode class]]] forKey:goNodeModelNodeDictionaryKey];
  [self restoreTreeLinks:nodeDictionary];

  self.game = [decoder decodeObjectOfClass:[GoGame class] forKey:goNodeModelGameKey];
  self.rootNode = [decoder decodeObjectOfClass:[GoNode class] forKey:goNodeModelRootNodeKey];
  self.nodeList = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableArray class], [GoNode class]]] forKey:goNodeModelNodeListKey];
  self.numberOfNodes = [decoder decodeIntForKey:goNodeModelNumberOfNodesKey];
  self.numberOfMoves = [decoder decodeIntForKey:goNodeModelNumberOfMovesKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  // Archive a flat data structure (dictionary) constructed on-the-fly instead
  // of the actual in-memory tree data structure, because archiving the tree
  // data structure would result in a stack overflow when the tree is very deep
  // (e.g. many hundreds of nodes). See the GoNode archiving/unarchiving
  // implementation for more details.
  // Important: Generate the dictionary before archiving self.rootNode so that
  // the root node uses the correct first child node ID when it archives itself.
  NSDictionary* nodeDictionary = [self generateNodeDictionaryForEncoding];
  [encoder encodeObject:nodeDictionary forKey:goNodeModelNodeDictionaryKey];

  // From here on the GoNode objects' nodeID property value is no longer needed.
  // Resetting it is wasted CPU cycles, though, because the memory for storing
  // the unsigned integer value will still be used.

  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.game forKey:goNodeModelGameKey];
  [encoder encodeObject:self.rootNode forKey:goNodeModelRootNodeKey];
  // Storing self.nodeList in the archive increases the archive size slightly,
  // but not significantly. Measured: maximum-number-of-moves.sgf with over
  // a thousand moves causes a size increase of roughly 3 KB, which at the time
  // when it was measured was only 1.1% of the entire archive size (ca. 282 KB).
  [encoder encodeObject:self.nodeList forKey:goNodeModelNodeListKey];
  [encoder encodeInt:self.numberOfNodes forKey:goNodeModelNumberOfNodesKey];
  [encoder encodeInt:self.numberOfMoves forKey:goNodeModelNumberOfMovesKey];
}

#pragma mark - NSCoding support

// -----------------------------------------------------------------------------
/// @brief Helper method for encoding an archive. Generates a dictionary with
/// all GoNode objects in the node tree. Key = NSNumber holding the GoNode
/// object's unique node ID (an unsigned int value), value = GoNode object.
///
/// Every time this method is invoked it iterates over the node tree and
/// generates new node IDs to be used as dictionary keys. It also assigns the
/// node ID to each GoNode object's @e nodeID property.
///
/// When the dictionary returned by this method is archived, each GoNode object
/// is archived as well. The GoNode archives the node ID of its first child,
/// next sibling and parent instead of the actual GoNode object, thus avoiding
/// the stack overflow that would occur if objects were archived and the node
/// tree were deep. The GoNode can archive the mentioned node IDs because (as
/// mentioned above) this method assigns each GoNode object a node ID.
// -----------------------------------------------------------------------------
- (NSDictionary*) generateNodeDictionaryForEncoding
{
  NSMutableDictionary* nodeDictionaryForEncoding = [NSMutableDictionary dictionary];

  // The current implementation of this method uses depth-first iteration over
  // the node tree, starting with the root node. The implementation could use
  // any other iteration algorithm, though, and it would not even need to start
  // with the root node, because node IDs are simply looked up in the
  // dictionary upon unarchiving.

  NSMutableArray* stack = [NSMutableArray array];

  GoNode* currentNode = self.rootNode;
  unsigned int nodeID = gNoObjectReferenceNodeID;

  while (true)
  {
    while (currentNode)
    {
      nodeID++;
      currentNode.nodeID = nodeID;
      NSNumber* nodeIDAsNumber = [NSNumber numberWithUnsignedInt:nodeID];
      nodeDictionaryForEncoding[nodeIDAsNumber] = currentNode;

      [stack addObject:currentNode];

      currentNode = currentNode.firstChild;
    }

    if (stack.count > 0)
    {
      currentNode = stack.lastObject;
      [stack removeLastObject];

      currentNode = currentNode.nextSibling;
    }
    else
    {
      // We're done
      break;
    }
  }

  return nodeDictionaryForEncoding;
}

// -----------------------------------------------------------------------------
/// @brief Helper method for decoding an archive. Iterates over all entries in
/// @a nodeDictionary and invokes GoNode::restoreTreeLinks:() on each GoNode
/// object. Key = NSNumber holding the GoNode object's unique node ID (an
/// unsigned int value), value = GoNode object.
///
/// This method performs the necessary second step after decoding an archive
/// to restore GoNode objects to a usable state. When a GoNode object is decoded
/// from an archive it only contains node IDs as references to its first child,
/// next sibling and parent node. These node IDs need to be "converted" to
/// actual object references by performing a lookup in @a nodeDictionary to
/// find the actual GoNode object whose reference is needed.
// -----------------------------------------------------------------------------
- (void) restoreTreeLinks:(NSDictionary*)nodeDictionary
{
  [nodeDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber* nodeIDAsNumber, GoNode* node, BOOL* stop)
  {
    [node restoreTreeLinks:nodeDictionary];
  }];
}

#pragma mark - Public interface - Variations

// -----------------------------------------------------------------------------
/// @brief Creates a new game tree variation by inserting @a node into the game
/// tree so that @a parent becomes the parent node of @a node, and
/// @a nextSibling becomes the next sibling node of @a node.
///
/// If @a nextSibling is @e nil then @a child is inserted as the last child of
/// @a parent.
///
/// @exception InvalidArgumentException Is thrown if @a node is @e nil, if
/// @a nextSibling is not @e nil but is not a child of @a parent, if @a node
/// is equal to @a parent, or if @a node is already part of a game tree.
// -----------------------------------------------------------------------------
- (void) createVariationWithNode:(GoNode*)node
                     nextSibling:(GoNode*)nextSibling
                          parent:(GoNode*)parent
{
  if (! node)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"createVariationWithNode:nextSibling:parent: failed: node is nil object"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  if (node.parent || node.nextSibling || node.firstChild)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"createVariationWithNode:nextSibling:parent: failed: node is already part of a game tree"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  // GoNode performs most of the error handling for us
  [parent insertChild:node beforeReferenceChild:nextSibling];
}

// -----------------------------------------------------------------------------
/// @brief Configures GoNodeModel with the main variation of the game tree, i.e.
/// the variation that consists of the root node of the game tree and all of
/// its @e firstChild descendants.
// -----------------------------------------------------------------------------
- (void) changeToMainVariation
{
  [self changeToVariationContainingNode:self.rootNode];
}

// -----------------------------------------------------------------------------
/// @brief Configures GoNodeModel with the variation of the game tree that
/// consists of @a node, all of @a node's ancestors up to the root node of the
/// game tree, and all of @a node's @e firstChild descendants.
///
/// Raises @e NSInvalidArgumentException if @a node is @e nil, or if @a node is
/// not in the same game tree as the root node accessible via property
/// @e rootNode.
// -----------------------------------------------------------------------------
- (void) changeToVariationContainingNode:(GoNode*)node
{
  if (! node)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"changeToVariationContainingNode: failed: node is nil object"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  NSMutableArray* newNodeList = [NSMutableArray arrayWithObject:node];
  int newNumberOfMoves = node.goMove ? 1 : 0;

  GoNode* parent = node.parent;
  while (parent)
  {
    [newNodeList insertObject:parent atIndex:0];

    if (parent.goMove)
      newNumberOfMoves++;

    parent = parent.parent;
  }

  if (newNodeList.firstObject != self.rootNode)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"changeToVariationContainingNode: failed: root node is not at the variation start"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  GoNode* firstChild = node.firstChild;
  while (firstChild)
  {
    [newNodeList addObject:firstChild];

    if (firstChild.goMove)
      newNumberOfMoves++;

    firstChild = firstChild.firstChild;
  }

  int newNumberOfNodes = (int)newNodeList.count;

  self.nodeList = newNodeList;

  self.numberOfNodes = newNumberOfNodes;
  self.numberOfMoves = newNumberOfMoves;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object that is the nearest ancestor of @a node
/// and that is also part of the current variation of the game tree. Returns
/// @a node itself if it is part of the current variation. Returns the root
/// node of the game tree if no nearer ancestor exists.
///
/// Raises @e NSInvalidArgumentException if @a node is @e nil, or if @a node is
/// not in the same game tree as the root node accessible via property
/// @e rootNode.
// -----------------------------------------------------------------------------
- (GoNode*) ancestorOfNodeInCurrentVariation:(GoNode*)node
{
  if (! node)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"ancestorOfNodeInCurrentVariation: failed: node is nil object"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return nil;
  }

  while (node)
  {
    NSUInteger index = [_nodeList indexOfObject:node];
    if (index != NSNotFound)
      return node;
    node = node.parent;
  }

  [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"ancestorOfNodeInCurrentVariation: failed: node is not in the game tree that contains the current variation"];
  // Dummy return to make compiler happy (compiler does not see that an
  // exception is thrown)
  return nil;
}

#pragma mark - Public interface - Current variation

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object located at index position @a index. The
/// index position is a location within the sequence of nodes that make up the
/// current variation. The root node is at index position 0.
///
/// Raises @e NSRangeException if @a index is <0 or exceeds the number of GoNode
/// objects in the current variation.
// -----------------------------------------------------------------------------
- (GoNode*) nodeAtIndex:(int)index
{
  return [_nodeList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Returns the index position at which the GoNode object @a node is
/// located. The index position is a location within the sequence of nodes that
/// make up the current variation. The root node is at index position 0. Returns
/// -1 if @a node is not in the current variation.
///
/// Raises @e NSInvalidArgumentException if @a node is @e nil.
// -----------------------------------------------------------------------------
- (int) indexOfNode:(GoNode*)node
{
  if (! node)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"indexOfNode: failed: node is nil object"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return -1;
  }

  NSUInteger index = [_nodeList indexOfObject:node];
  if (index == NSNotFound)
    return -1;

  // Cast is required because NSUInteger and int differ in size in 64-bit.
  // Cast is safe because this app was not made to handle more than
  // pow(2, 31) nodes.
  return (int)index;
}

// -----------------------------------------------------------------------------
/// @brief Adds the GoNode object @a node to the end of the current variation.
///
/// Raises @e NSInvalidArgumentException if @a node is @e nil, or if @a node is
/// already in the current variation.
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) appendNode:(GoNode*)node
{
  if (! node)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"appendNode: failed: node is nil object"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  GoNode* leafNode = _nodeList.lastObject;
  leafNode.firstChild = node;
  // No GoMove linking necessary here, this is done when the GoMove object is
  // constructed

  // Add node only after it was linked into the game tree. Reason: The linking
  // performs validation that detects e.g. if the node is already an ancestor
  // of the leaf node, i.e. if it is already part of the variation.
  [_nodeList addObject:node];

  self.game.document.dirty = true;

  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) nodes.
  self.numberOfNodes = (int)_nodeList.count;
  if (node.goMove)
    self.numberOfMoves = self.numberOfMoves + 1;
}

// -----------------------------------------------------------------------------
/// @brief Discards all GoNode objects in the current variation starting with
/// the GoNode object at position @a index. If the GoNode object at position
/// @a index has a next or previous sibling, that next or previous sibling and
/// its @e firstChild descendants become part of the current variation in place
/// of the GoNode object at position @a index. If both a next and a previous
/// sibling exist, the next sibling is preferred.
///
/// Raises @e NSRangeException if @a index is < 1 (the root node cannot be
/// discarded) or exceeds the number of GoNode objects in the current variation.
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) discardNodesFromIndex:(int)index
{
  if (index < 1)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Index %d must not be <1", index];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (index >= _nodeList.count)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Index %d must not exceed number of nodes %lu", index, (unsigned long)_nodeList.count];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  int numberOfMovesToDiscard = 0;
  for (int indexOfNodeToDiscard = index; indexOfNodeToDiscard < _nodeList.count; ++indexOfNodeToDiscard)
  {
    GoNode* node = [_nodeList objectAtIndex:indexOfNodeToDiscard];
    if (node.goMove)
      numberOfMovesToDiscard++;
  }

  // Variation support: Discarding node B not only removes the node and its
  // child nodes, it also causes all variations that shared the same path up to
  // node B to be discarded. Node H (the next sibling of node B) and its
  // children will replace node B and its children in the current variation.
  //
  //      +-- branching node
  //      |    +-- first node to discard
  //      |    |              +-- current leaf node
  //      v    v              v
  // o----A----B----C----D----E   <-- current variation
  //      |         |
  //      |         +----F----G   <-- variation is deleted
  //      +----H----I----J        <-- variation becomes the new current variation
  //      |    ^         ^
  //      |    |         +-- new leaf node after all nodes were discarded
  //      |    +-- next sibling of first node to discard => replaces node to discard
  //      +----K                  <-- variation does not become the new current variation
  //
  // Alternative scenario: Discarding node K. In that case node H (the previous
  // sibling of node K) and its children will replace node K in the current
  // variation.
  //
  // If the node to discard has both a next sibling and a previous sibling, then
  // the preference is to use the next sibling as replacement of the node to
  // discard.
  GoNode* firstNodeToDiscard = [_nodeList objectAtIndex:index];
  GoNode* parentNode = firstNodeToDiscard.parent;
  GoNode* nextSiblingOfFirstNodeToDiscard = firstNodeToDiscard.nextSibling;
  GoNode* previousSiblingOfFirstNodeToDiscard = nil;
  if (! nextSiblingOfFirstNodeToDiscard)
    previousSiblingOfFirstNodeToDiscard = firstNodeToDiscard.previousSibling;
  [parentNode removeChild:firstNodeToDiscard];
  // No GoMove unlinking necessary here, this is done in GoMove::dealloc()

  // Discard nodes only after they were unlinked from the game tree. Reason: The
  // unlinking performs validation. There is currently no known reason why this
  // should fail, but at least we are consistent with how things are done in
  // appendNode:().
  NSUInteger numberOfNodesToDiscard = _nodeList.count - index;
  NSRange rangeToDiscard = NSMakeRange(index, numberOfNodesToDiscard);
  [_nodeList removeObjectsInRange:rangeToDiscard];

  GoNode* nodeToAdd = nextSiblingOfFirstNodeToDiscard ? nextSiblingOfFirstNodeToDiscard : previousSiblingOfFirstNodeToDiscard;
  while (nodeToAdd)
  {
    [_nodeList addObject:nodeToAdd];

    if (nodeToAdd.goMove)
      numberOfMovesToDiscard--;  // can become negative

    nodeToAdd = nodeToAdd.firstChild;
  }

  self.game.document.dirty = true;

  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) nodes.
  self.numberOfNodes = (int)_nodeList.count;
  if (numberOfMovesToDiscard != 0)
    self.numberOfMoves = self.numberOfMoves - numberOfMovesToDiscard;
}

// -----------------------------------------------------------------------------
/// @brief Discards the leaf GoNode object of the current variation, i.e. the
/// GoNode object at the tip of the game tree branch that is represented by the
/// current variation. If the leaf GoNode object has a next or previous sibling,
/// that next or previous sibling and its @e firstChild descendants become part
/// of the current variation in place of the discarded leaf GoNode object. If
/// both a next and a previous sibling exist, the next sibling is preferred.
///
/// Raises @e NSRangeException if there are no GoNode objects in the current
/// variation beyond the root node (the root node cannot be discarded)
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) discardLeafNode
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) nodes.
  [self discardNodesFromIndex:((int)_nodeList.count - 1)];  // raises exception for us
}

// -----------------------------------------------------------------------------
/// @brief Discards all GoNode objects of the current variation starting with
/// the GoNode object that is the direct child of the root node. If the root
/// node's direct child GoNode object has a next or previous sibling, that next
/// or previous sibling and its @e firstChild descendants become part of the
/// current variation in place of the discarded root node's direct child GoNode
/// object. If both a next and a previous sibling exist, the next sibling is
/// preferred.
///
/// Raises @e NSRangeException if there are no GoNode objects in the current
/// variation beyond the root node (the root node cannot be discarded)
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) discardAllNodes
{
  [self discardNodesFromIndex:1];  // raises exception for us
}

// -----------------------------------------------------------------------------
// Property is documented in header file
// -----------------------------------------------------------------------------
- (GoNode*) leafNode
{
  return [_nodeList lastObject];
}

@end
