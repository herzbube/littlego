// -----------------------------------------------------------------------------
// Copyright 2012-2022 Patrick Näf (herzbube@herzbube.ch)
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
@property(nonatomic, assign, readwrite) int numberOfNodes;  // exists as a property to allow KVO
@property(nonatomic, assign, readwrite) int numberOfMoves;  // exists as a property to allow KVO
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

  NSDictionary* nodeDictionary = [decoder decodeObjectForKey:goNodeModelNodeDictionaryKey];
  [self restoreTreeLinks:nodeDictionary];

  self.game = [decoder decodeObjectForKey:goNodeModelGameKey];
  self.rootNode = [decoder decodeObjectForKey:goNodeModelRootNodeKey];
  self.nodeList = [decoder decodeObjectForKey:goNodeModelNodeListKey];
  self.numberOfNodes = [decoder decodeIntForKey:goNodeModelNumberOfNodesKey];
  self.numberOfMoves = [decoder decodeIntForKey:goNodeModelNumberOfMovesKey];

  return self;
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

#pragma mark - Public interface

// TODO xxx document
- (void) changeToMainVariation
{
  [self changeToVariationContainingNode:self.rootNode];
}

// TODO xxx document
// the variation consists of the node and all its ancestors up to the root node,
// and all its firstChild descendants
- (void) changeToVariationContainingNode:(GoNode*)node
{
  if (! node)
  {
    NSString* errorMessage = @"changeToVariationContainingNode: failed: node is nil object";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
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
    NSString* errorMessage = @"changeToVariationContainingNode: failed: root node is not at the variation start";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
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

  // TODO xxx do we need to check if the old and the new variations are the same?
  self.nodeList = newNodeList;

  // TODO xxx old and new variation could have the same number of nodes and/or nodes => may need another property to observe, or a notification
  // TODO xxx KVO in GoBoardPosition may do something stupid if currentBoardPosition is newNumberOfNodes - 1 => replace KVO?
  self.numberOfNodes = newNumberOfNodes;  // triggers KVO observers
  self.numberOfMoves = newNumberOfMoves;  // triggers KVO observers
}

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
/// make up the current variation. The root node is at index position 0.
///
/// Raises @e NSInvalidArgumentException if @a node is nil, or if @a node is
/// not in the current variation.
// -----------------------------------------------------------------------------
- (int) indexOfNode:(GoNode*)node
{
  if (! node)
  {
    NSString* errorMessage = @"indexOfNode: failed: node is nil object";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  NSUInteger index = [_nodeList indexOfObject:node];
  if (index == NSNotFound)
  {
    NSString* errorMessage = @"indexOfNode: failed: node not found";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  // Cast is required because NSUInteger and int differ in size in 64-bit.
  // Cast is safe because this app was not made to handle more than
  // pow(2, 31) nodes.
  return (int)index;
}

// -----------------------------------------------------------------------------
/// @brief Adds the GoNode object @a node to the end of the current variation.
///
/// Raises @e NSInvalidArgumentException if @a node is nil, or if @a node is
/// already in the current variation.
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) appendNode:(GoNode*)node
{
  if (! node)
  {
    NSString* errorMessage = @"appendNode: failed: node is nil object";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
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
  self.numberOfNodes = (int)_nodeList.count;  // triggers KVO observers
  if (node.goMove)
    self.numberOfMoves = self.numberOfMoves + 1;  // triggers KVO observers
}

// -----------------------------------------------------------------------------
/// @brief Discards all GoNode objects in the current variation starting with
/// the object at position @a index.
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

  // TODO Variation support: Cutting the tree here not only removes the
  // nodes, it also causes all variations that shared the same path up to here
  // with the current variation to be removed.
  //             +-- new leaf node after all nodes were discarded
  //             |   +-- first node to discard
  //             |   |           +-- current leaf node
  //             v   v           v
  // +---+---+---+---+---+---+---+   <-- current variation
  //              \       \
  //               \|      --+---+   <-- variation is removed
  //                -+---+---+       <-- variation is kept because new leaf node is the branching point
  GoNode* newLeafNode = [_nodeList objectAtIndex:index - 1];
  newLeafNode.firstChild = nil;
  // No GoMove unlinking necessary here, this is done in GoMove::dealloc()

  // Discard nodes only after they were unlinked from the game tree. Reason: The
  // unlinking performs validation. There is currently no known reason why this
  // should fail, but at least we are consistent with how things are done in
  // appendNode:().
  NSUInteger numberOfNodesToDiscard = _nodeList.count - index;
  NSRange rangeToDiscard = NSMakeRange(index, numberOfNodesToDiscard);
  [_nodeList removeObjectsInRange:rangeToDiscard];

  self.game.document.dirty = true;

  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) nodes.
  self.numberOfNodes = (int)_nodeList.count;  // triggers KVO observers
  if (numberOfMovesToDiscard > 0)
    self.numberOfMoves = self.numberOfMoves - numberOfMovesToDiscard;  // triggers KVO observers
}

// -----------------------------------------------------------------------------
/// @brief Discards the leaf GoNode object of the current variation, i.e. the
/// GoNode object at the tip of the game tree branch that is represented by the
/// current variation.
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
  [self discardNodesFromIndex:((int)_nodeList.count - 1)];  // raises exception and posts notification for us
}

// -----------------------------------------------------------------------------
/// @brief Discards all GoNode objects of the current variation beyond the root
/// node.
///
/// Raises @e NSRangeException if there are no GoNode objects in the current
/// variation beyond the root node (the root node cannot be discarded)
///
/// Invoking this method sets the GoGameDocument dirty flag.
// -----------------------------------------------------------------------------
- (void) discardAllNodes
{
  [self discardNodesFromIndex:1];  // raises exception and posts notification for us
}

// -----------------------------------------------------------------------------
// Property is documented in header file
// -----------------------------------------------------------------------------
- (GoNode*) leafNode
{
  return [_nodeList lastObject];
}

@end
