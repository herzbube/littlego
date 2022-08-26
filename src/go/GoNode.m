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


// Project includes
#import "GoNode.h"
#import "GoMove.h"
#import "GoNodeMarkup.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNode.
// -----------------------------------------------------------------------------
@interface GoNode()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) GoMove* goMove;
//@}
@end


@implementation GoNode

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed GoNode object that has no parent,
/// child or sibling and is not associated with any game.
// -----------------------------------------------------------------------------
+ (GoNode*) node
{
  return [[[self alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed GoNode object that has no parent,
/// child or sibling and is not associated with any game. The supplied GoMove
/// object @a goMove is associated with the node.
// -----------------------------------------------------------------------------
+ (GoNode*) nodeWithMove:(GoMove*)goMove
{
  GoNode* node = [[[self alloc] init] autorelease];
  node.goMove = goMove;
  return node;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an GoNode object that has no parent,
/// child or sibling and is not associated with any game.
///
/// This is the designated initializer of GoNode.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Don't use "self" to avoid the setter methods
  _firstChild = nil;
  _nextSibling = nil;
  _parent = nil;

  self.goMove = nil;
  self.goNodeAnnotation = nil;
  self.goNodeMarkup = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoNode object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // Don't use "self" to avoid the setter methods
  if (_firstChild)
  {
    [_firstChild release];
    _firstChild = nil;
  }
  if (_nextSibling)
  {
    [_nextSibling release];
    _nextSibling = nil;
  }
  if (_parent)
  {
    // No need to release the parent because it is not retained. We don't
    // retain it to avoid a retain cycle between a parent and its first child
    _parent = nil;
  }

  self.goMove = nil;
  self.goNodeAnnotation = nil;
  self.goNodeMarkup = nil;

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

  // TODO xxx Verify that this works with a large number of nodes. The links
  // between GoMove objects could not be archived because a large number of
  // moves caused a stack overflow >>> see GoUtilities::relinkMoves().

  // Don't use "self" to avoid the setter methods
  _firstChild = [[decoder decodeObjectForKey:goNodeFirstChildKey] retain];
  _nextSibling = [[decoder decodeObjectForKey:goNodeNextSiblingKey] retain];
  _parent = [decoder decodeObjectForKey:goNodeParentKey];  // do not retain to avoid retain cycle between parent and its first child
  self.goMove = [decoder decodeObjectForKey:goNodeGoMoveKey];
  self.goNodeAnnotation = [decoder decodeObjectForKey:goNodeGoNodeAnnotationKey];
  self.goNodeMarkup = [decoder decodeObjectForKey:goNodeGoNodeMarkupKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  if (self.firstChild)
    [encoder encodeObject:self.firstChild forKey:goNodeFirstChildKey];
  if (self.nextSibling)
    [encoder encodeObject:self.nextSibling forKey:goNodeNextSiblingKey];
  if (self.parent)
    [encoder encodeObject:self.parent forKey:goNodeParentKey];
  if (self.goMove)
    [encoder encodeObject:self.goMove forKey:goNodeGoMoveKey];
  if (self.goNodeAnnotation)
    [encoder encodeObject:self.goNodeAnnotation forKey:goNodeGoNodeAnnotationKey];
  if (self.goNodeMarkup)
    [encoder encodeObject:self.goNodeMarkup forKey:goNodeGoNodeMarkupKey];
}

#pragma mark - Public API - Game tree navigation

- (GoNode*) lastChild
{
  GoNode* child = self.firstChild;

  while (child)
  {
    if (child.hasNextSibling)
      child = child.nextSibling;
    else
      return child;
  }

  return nil;
}

- (NSArray*) children
{
  NSMutableArray* children = [NSMutableArray arrayWithCapacity:0];

  GoNode* child = self.firstChild;

  while (child)
  {
    [children addObject:child];
    child = child.nextSibling;
  }

  return children;
}

- (bool) hasChildren
{
  return (self.firstChild != nil);
}

- (bool) hasNextSibling
{
  return (self.nextSibling != nil);
}

- (GoNode*) previousSibling
{
  GoNode* parent = self.parent;
  if (! parent)
    return nil;

  GoNode* child = parent.firstChild;
  if (child == self)
    return nil;

  while (child)
  {
    GoNode* nextSibling = child.nextSibling;
    if (nextSibling == self)
      return child;
    else
      child = nextSibling;
  }

  return nil;
}

- (bool) hasPreviousSibling
{
  return (self.previousSibling != nil);
}

- (bool) hasParent
{
  return (self.parent != nil);
}

- (bool) isDescendantOfNode:(GoNode*)node
{
  if (! node)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"isDescendantOfNode: failed: Node argument is null"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return false;
  }

  GoNode* parent = self.parent;

  while (parent)
  {
    if (parent == node)
      return true;
    else
      parent = parent.parent;
  }

  return false;
}

- (bool) isAncestorOfNode:(GoNode*)node
{
  if (! node)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"isAncestorOfNode: failed: Node argument is null"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return false;
  }

  GoNode* parent = node.parent;

  while (parent)
  {
    if (parent == self)
      return true;
    else
      parent = parent.parent;
  }

  return false;
}

- (bool) isRoot
{
  return (self.parent == nil);
}

#pragma mark - Public API - Other operations

- (bool) isEmpty
{
  return ! self.goMove && ! self.goNodeAnnotation && ! self.goNodeMarkup;
}

- (void) modifyBoard
{
  if (self.goMove)
    [self.goMove doIt];
}

- (void) revertBoard
{
  if (self.goMove)
    [self.goMove undo];
}

@end

#pragma mark - Implementation of GoNodeAdditions

// -----------------------------------------------------------------------------
// The GoNodeAdditions implementation requires that the internal setter methods
// setFirstChildInternal:(), setNextSiblingInternal:() and setParentInternal:()
// have access to the synthesized member variables _firstChild, _nextSibling
// and _parent. This member variable access is the reason why the
// GoNodeAdditions implementation must reside within this .m file. If the
// implementation were in another .m file it would be unable to access the
// member variables.
//
// The GoNodeAdditions implementation is an adaptation of the SgfcTreeBuilder
// class in libsgfc++.
// -----------------------------------------------------------------------------

@implementation GoNode(GoNodeAdditions)

// -----------------------------------------------------------------------------
/// @brief Sets the first child node of the receiver node to @a child, replacing
/// everything below the receiver node with @a child (which may be @e nil). Use
/// insertChild:beforeReferenceChild:() if you want to keep the existing nodes
/// below the receiver node.
///
/// If @a child is already part of the game tree in some other location, it is
/// moved, together with the entire sub tree dangling from it, from its current
/// location to the new location.
///
/// The previous first child node, the siblings behind that, and the sub
/// trees dangling from all of these nodes, are discarded once no one holds
/// a reference to them anymore.
///
/// @exception InvalidArgumentException Is thrown if @a child is an ancestor of
/// the receiver node, or if @a child is equal to the receiver node.
// -----------------------------------------------------------------------------
- (void) setFirstChild:(GoNode*)child
{
  if (self == child)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setFirstChild: failed: Child is equal to node"];

  GoNode* oldFirstChild = self.firstChild;
  if (oldFirstChild == child)
    return;  // child is already at the correct position

  if (child && [child isAncestorOfNode:self])
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setFirstChild: failed: Child is ancestor of node"];

  if (oldFirstChild)
  {
    // Modifies not only oldFirstChild, but also self: self.firstChild
    // becomes nil
    [oldFirstChild removeNodeAndAllNextSiblingsFromParent];
  }

  if (! child)
  {
    // self.firstChild is already nil, so if child is also nil
    // we already have achieved the goal
    return;
  }

  // If child was originally a child of self, then at the moment it has no
  // parent because of removeNodeAndAllNextSiblingsFromParent() above. In that
  // case we would not have to make the following call.
  [child removeNodeFromCurrentLocation];

  GoNode* newParent = self;
  GoNode* newNextSibling = self.firstChild;  // always nil
  [child insertNodeAsChildOfNewParent:newParent beforeNewNextSibling:newNextSibling];
}

// -----------------------------------------------------------------------------
/// @brief Adds @a child as the last child to the receiver node. @a child may
/// not be @e nil.
///
/// If @a child is already part of the game tree in some other location, it is
/// moved, together with the entire sub tree dangling from it, from its current
/// location to the new location.
///
/// This method exists for convenience. The operations it performs can also
/// be achieved by invoking insertChild:beforeReferenceChild:() and specifying
/// @e nil as the @a referenceChild argument.
///
/// @exception InvalidArgumentException Is thrown if @a child is @e nil, if
/// @a child is an ancestor of the receiver node, or if @a child is equal to
/// the receiver node.
// -----------------------------------------------------------------------------
- (void) appendChild:(GoNode*)child
{
  if (! child)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"appendChild: failed: Child argument is null"];

  if (self == child)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"appendChild: failed: Child is equal to node"];

  if (child.parent == self && ! child.nextSibling)
    return;  // child is already at the correct position

  if ([child isAncestorOfNode:self])
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"appendChild: failed: Child is ancestor of node"];

  [child removeNodeFromCurrentLocation];

  GoNode* newParent = self;
  GoNode* newNextSibling = nil;
  [child insertNodeAsChildOfNewParent:newParent beforeNewNextSibling:newNextSibling];
}

// -----------------------------------------------------------------------------
/// @brief Inserts @a child as a child to the receiver node, before the
/// reference child node @a referenceChild. @a child may not be @e nil.
/// @a referenceChild may be nil, but if it's not then it must be a
/// child of the receiver node.
///
/// If @a referenceChild is @e nil then @a child is inserted as the last child
/// of the receiver node. The result is the same as if appendChild:() had been
/// invoked on the receiver node.
///
/// If @a child is already part of the game tree in some other location, it is
/// moved, together with the entire sub tree dangling from it, from its current
/// location to the new location.
///
/// @exception InvalidArgumentException Is thrown if @a child is @e nil, if
/// @a referenceChild is not @e nil but it's not a child of the node, if
/// @a child is an ancestor of the receiver node, or if @a child is equal to
/// the receiver node.
// -----------------------------------------------------------------------------
- (void) insertChild:(GoNode*)child beforeReferenceChild:(GoNode*)referenceChild
{
  if (! child)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"insertChild:beforeReferenceChild: failed: Child argument is null"];

  if (self == child)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"insertChild:beforeReferenceChild: failed: Child is equal to node"];

  if (referenceChild && referenceChild.parent != self)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"insertChild:beforeReferenceChild: failed: Reference child is not a child of node"];

  if (child.parent == self && child.nextSibling == referenceChild)
    return;  // child is already at the correct position

  if ([child isAncestorOfNode:self])
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"insertChild:beforeReferenceChild: failed: Child is ancestor of node"];

  [child removeNodeFromCurrentLocation];

  GoNode* newParent = self;
  GoNode* newNextSibling = referenceChild;  // can be nil
  [child insertNodeAsChildOfNewParent:newParent beforeNewNextSibling:newNextSibling];
}

// -----------------------------------------------------------------------------
/// @brief Removes @a child from the receiver node. @a child may not be @e nil.
/// @a child must be a child of the node.
///
/// The game tree is relinked to close the gap.
///
/// @a child and the entire sub tree dangling from it, is discarded once no one
/// holds a reference to it anymore.
///
/// @exception InvalidArgumentException Is thrown if @a child is @e nil, or if
/// @a child is not a child of the receiver node.
// -----------------------------------------------------------------------------
- (void) removeChild:(GoNode*)child
{
  if (! child)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeChild: failed: Child argument is null"];

  if (child.parent != self)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeChild: failed: Child is not a child of node"];

  [child removeNodeFromCurrentLocation];
}

// -----------------------------------------------------------------------------
/// @brief Replaces @a oldChild with @a newChild. @a oldChild and @a newChild
/// may not be @e nil. @a oldChild must be a child of the receiver node.
///
/// If @a newChild is already part of the game tree in some other location, it
/// is moved, together with the entire sub tree dangling from it, from its
/// current location to the new location.
///
/// @a oldChild and the entire sub tree dangling from it, is discarded once no
/// one holds a reference to it anymore.
///
/// @exception InvalidArgumentException Is thrown if @a oldChild or @a newChild
/// are @e nil, if @a oldChild is not a child of the receiver node, if
/// @a newChild is an ancestor of the receiver node, or if @a newChild is equal
/// to the receiver node.
// -----------------------------------------------------------------------------
- (void) replaceChild:(GoNode*)oldChild withNewChild:(GoNode*)newChild
{
  if (! newChild)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"replaceChild:withNewChild: failed: NewChild argument is null"];

  if (! oldChild)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"replaceChild:withNewChild: failed: OldChild argument is null"];

  if (self == newChild)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"replaceChild:withNewChild: failed: NewChild is equal to node"];

  if (oldChild.parent != self)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"replaceChild:withNewChild: failed: OldChild is not a child of node"];

  if (newChild == oldChild)
    return;  // newChild is already at the correct position

  if ([newChild isAncestorOfNode:self])
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"replaceChild:withNewChild: failed: NewChild is ancestor of node"];

  [newChild removeNodeFromCurrentLocation];

  GoNode* newParent = self;
  GoNode* newNextSibling = oldChild;
  [newChild insertNodeAsChildOfNewParent:newParent beforeNewNextSibling:newNextSibling];

  [oldChild removeNodeFromCurrentLocation];
}

// -----------------------------------------------------------------------------
/// @brief Sets the next sibling node of the receiver node to @a nextSibling,
/// replacing the previous next sibling node, the siblings behind that, and
/// the sub trees dangling from all of these siblings with @a nextSibling
/// (which may be @e nil). Use insertChild:beforeReferenceChild:() if you want
/// to keep the next sibling nodes.
///
/// The receiver node must not be the root node of a game tree because a root
/// node by definition can't have siblings.
///
/// If @a nextSibling is already part of the game tree in some other location,
/// it is moved, together with the entire sub tree dangling from it, from its
/// current location to the new location.
///
/// The previous next sibling node, the siblings behind that, and the sub
/// trees dangling from all of these siblings, are discarded once no one
/// holds a reference to them anymore.
///
/// @exception InvalidArgumentException Is thrown if the receiver node is the
/// root node of a game tree, if @a nextSibling is not @e nil and an ancestor
/// of the receiver node, or if @a nextSibling is equal to the receiver node.
// -----------------------------------------------------------------------------
- (void) setNextSibling:(GoNode*)nextSibling
{
  if (self.isRoot)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setNextSibling: failed: Node is root node of game tree"];

  if (self == nextSibling)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setNextSibling: failed: NextSibling is equal to node"];

  if (nextSibling && [nextSibling isAncestorOfNode:self])
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setNextSibling: failed: NextSibling is ancestor of node"];

  GoNode* oldNextSibling = self.nextSibling;
  if (oldNextSibling == nextSibling)
    return;  // nextSibling is already at the correct position

  if (oldNextSibling)
  {
    // Modifies not only oldNextSibling, but also self: self.nextSibling
    // becomes nil
    [oldNextSibling removeNodeAndAllNextSiblingsFromParent];
  }

  if (! nextSibling)
  {
    // self.nextSibling is already nil, so if nextSibling is also nil
    // we already have achieved the goal
    return;
  }

  // If nextSibling was originally an indirect sibling of self, then at
  // the moment it has no parent because of
  // removeNodeAndAllNextSiblingsFromParent() above. In that case we would
  // not have to make the following call.
  [nextSibling removeNodeFromCurrentLocation];

  GoNode* newParent = self.parent;  // can't be nil, we checked for root node
  GoNode* newNextSibling = self.nextSibling;  // always nil
  [nextSibling insertNodeAsChildOfNewParent:newParent beforeNewNextSibling:newNextSibling];
}

// -----------------------------------------------------------------------------
/// @brief Sets the parent node of the receiver node to @a parent. @a parent
/// may be @e nil.
///
/// If @a parent is not @e nil and the receiver node is already a child of
/// @a parent, then this method has no effect.
///
/// If @a parent is not @e nil and the receiver node is not yet a child of
/// @a parent, then the receiver node is added as the last child of @a parent.
/// The result is the same as if appendChild:() had been invoked on @a parent
/// with the receiver node as the argument.
///
/// If @a parent is not @e nil and if the receiver node is already part of the
/// game tree in some other location, the receiver node is moved, together with
/// the entire sub tree dangling from it, from its current location to the
/// new location.
///
/// If @a parent is @e nil then the receiver node and the entire sub tree
/// dangling from it, is discarded once no one holds a reference to it
/// anymore. The game tree is relinked to close the gap. The result is the
/// same as if removeChild:() had been invoked on the node's parent with
/// the receiver node as the argument.
///
/// @exception InvalidArgumentException Is thrown if @a parent is a descendant
/// of the receiver node, or if @a parent is equal to the receiver node.
// -----------------------------------------------------------------------------
- (void) setParent:(GoNode*)parent
{
  if (self == parent)
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setParent: failed: Parent is equal to node"];

  if (self.parent == parent)
    return;  // node is already at the correct position

  if (parent && [parent isDescendantOfNode:self])
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setParent: failed: Parent is descendant of node"];

  [self removeNodeFromCurrentLocation];

  if (parent)
  {
    GoNode* newParent = parent;
    GoNode* newNextSibling = nil;
    [self insertNodeAsChildOfNewParent:newParent beforeNewNextSibling:newNextSibling];
  }
}

#pragma mark - Internal helper methods of GoNodeAdditions

// -----------------------------------------------------------------------------
/// @brief Removes the receiver node from its current location in the game tree
/// and relinks the game tree to fill the gap.
///
/// When control returns to the caller, the receiver node has no parent and no
/// next sibling but retains its first child.
///
/// This is an internal helper method of GoNodeAdditions.
// -----------------------------------------------------------------------------
- (void) removeNodeFromCurrentLocation
{
  if (self.isRoot)
    return;

  GoNode* parent = self.parent;

  if (parent.firstChild == self)
  {
    [parent setFirstChildInternal:self.nextSibling];
  }
  else
  {
    GoNode* previousSibling = self.previousSibling;
    [previousSibling setNextSiblingInternal:self.nextSibling];
  }

  [self setParentInternal:nil];
  // Important: This must happen after we have re-linked the original
  // next sibling, otherwise the next sibling would become deallocated.
  [self setNextSiblingInternal:nil];
}

// -----------------------------------------------------------------------------
/// @brief Removes the receiver node and all of its next siblings from their
/// current location in the game tree.
///
/// When control returns to the caller, the receiver node and all of its next
/// siblings have no parent but retain their first child. The sibling linkage of
/// the receiver node and all of its next siblings is broken so that every node
/// is now a valid root node. This is important in case the nodes are
/// subsequently re-inserted into a game tree: All GoNodeAddition methods have
/// a condition that throws an exception if the node to be inserted already has
/// siblings.
///
/// This is an internal helper method of GoNodeAdditions.
// -----------------------------------------------------------------------------
- (void) removeNodeAndAllNextSiblingsFromParent
{
  GoNode* previousSibling = self.previousSibling;
  if (previousSibling)
    [previousSibling setNextSiblingInternal:nil];

  // We must set the parent's first child only after GetPreviousSibling()
  // has been invoked (see above). Reason: GetPreviousSibling() requires the
  // parent-to-first child link to be intact.
  GoNode* parent = self.parent;
  if (parent)
  {
    if (parent.firstChild == self)
      [parent setFirstChildInternal:nil];
  }

  GoNode* node = self;
  while (node)
  {
    GoNode* nextSibling = node.nextSibling;

    [node setParentInternal:nil];
    [node setNextSiblingInternal:nil];

    node = nextSibling;
  }
}

// -----------------------------------------------------------------------------
/// @brief Inserts the receiver node at the location in the game tree that is
/// defined by @a newParent and @a newNextSibling and relinks the game tree to
/// accommodate the receiver node in its new location. If @a newNextSibling is
/// @e nil the receiver node becomes the last child of @a newParent.
///
/// This method expects that removeNodeFromCurrentLocation() has been
/// previously invoked on the receiver node, i.e. that the receiver node is
/// currently not anywhere in the game tree.
///
/// This is an internal helper method of GoNodeAdditions.
// -----------------------------------------------------------------------------
- (void) insertNodeAsChildOfNewParent:(GoNode*)newParent beforeNewNextSibling:(GoNode*)newNextSibling
{
  if (newParent.firstChild == newNextSibling)
  {
    [newParent setFirstChildInternal:self];
  }
  else
  {
    GoNode* previousSibling;

    // newNextSibling is nil if node should be added as the last
    // child to parent
    if (! newNextSibling)
      previousSibling = newParent.lastChild;
    else
      previousSibling = newNextSibling.previousSibling;

    [previousSibling setNextSiblingInternal:self];
  }

  [self setParentInternal:newParent];
  [self setNextSiblingInternal:newNextSibling];
}

#pragma mark - Internal property setters without logic

// -----------------------------------------------------------------------------
/// @brief Sets the first child node of the receiver node to @a child and
/// retains @a child. The old first child node, if there is one, is released.
/// @a child may be @e nil.
///
/// Along with setNextSiblingInternal:() and setParentInternal:() this is
/// one of the three core setter methods used internally by all GoNodeAdditions
/// methods to achieve their tree manipulation tasks. This setter does not
/// implement any tree manipulation logic - it expects that any such logic has
/// been applied before it was invoked, or will be applied after it was invoked.
// -----------------------------------------------------------------------------
- (void) setFirstChildInternal:(GoNode*)child
{
  if (_firstChild)
  {
    [_firstChild release];
    _firstChild = nil;
  }

  if (child)
  {
    _firstChild = child;
    [_firstChild retain];
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets the next sibling node of the receiver node to @a nextSibling and
/// retains @a nextSibling. The old next sibling node, if there is one, is
/// released. @a nextSibling may be @e nil.
///
/// Along with setFirstChildInternal:() and setParentInternal:() this is
/// one of the three core setter methods used internally by all GoNodeAdditions
/// methods to achieve their tree manipulation tasks. This setter does not
/// implement any tree manipulation logic - it expects that any such logic has
/// been applied before it was invoked, or will be applied after it was invoked.
// -----------------------------------------------------------------------------
- (void) setNextSiblingInternal:(GoNode*)nextSibling
{
  if (_nextSibling)
  {
    [_nextSibling release];
    _nextSibling = nil;
  }

  if (nextSibling)
  {
    _nextSibling = nextSibling;
    [_nextSibling retain];
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets the parent node of the receiver node to @a parent. @a parent
/// may be @e nil.
///
/// Along with setFirstChildInternal:() and setNextSiblingInternal:() this is
/// one of the three core setter methods used internally by all GoNodeAdditions
/// methods to achieve their tree manipulation tasks. This setter does not
/// implement any tree manipulation logic - it expects that any such logic has
/// been applied before it was invoked, or will be applied after it was invoked.
// -----------------------------------------------------------------------------
- (void) setParentInternal:(GoNode*)parent
{
  // Unlike setFirstChildInternal:() and setNextSiblingInternal:() this does
  // NOT retain the parent, to avoid a retain cycle between a parent node and
  // its first child node.
  _parent = parent;
}

@end
