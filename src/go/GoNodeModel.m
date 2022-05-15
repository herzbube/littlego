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
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.game forKey:goNodeModelGameKey];
  [encoder encodeObject:self.rootNode forKey:goNodeModelRootNodeKey];
  [encoder encodeObject:self.nodeList forKey:goNodeModelNodeListKey];
  [encoder encodeInt:self.numberOfNodes forKey:goNodeModelNumberOfNodesKey];
  [encoder encodeInt:self.numberOfMoves forKey:goNodeModelNumberOfMovesKey];
}

#pragma mark - Public interface

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

  // TODO xxx Variation support: Cutting the tree here not only removes the
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
/// @brief Is invoked to indicate that the annotation data in @a node changed.
///
/// Raises @e NSInvalidArgumentException if @a node is nil, or if @a node is
/// not in the current variation.
///
/// Invoking this method sets the GoGameDocument dirty flag and posts
/// #nodeAnnotationDataDidChange to the default notification center.
// -----------------------------------------------------------------------------
- (void) nodeAnnotationDataDidChange:(GoNode*)node
{
  if (! node)
  {
    NSString* errorMessage = @"nodeAnnotationDataDidChange: failed: node is nil object";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  BOOL containsNode = [_nodeList containsObject:node];
  if (! containsNode)
  {
    NSString* errorMessage = @"nodeAnnotationDataDidChange: failed: node not found";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  self.game.document.dirty = true;

  [[NSNotificationCenter defaultCenter] postNotificationName:nodeAnnotationDataDidChange object:node];
}

// -----------------------------------------------------------------------------
// Property is documented in header file
// -----------------------------------------------------------------------------
- (GoNode*) leafNode
{
  return [_nodeList lastObject];
}

@end
