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
#import "NodeTreeViewCanvas.h"
#import "NodeNumbersViewCell.h"
#import "NodeTreeViewBranch.h"
#import "NodeTreeViewBranchTuple.h"
#import "NodeTreeViewCanvasAdditions.h"
#import "NodeTreeViewCanvasData.h"
#import "NodeTreeViewCell.h"
#import "NodeTreeViewCellPosition.h"
#import "../../model/NodeTreeViewModel.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoMove.h"
#import "../../../go/GoNode.h"
#import "../../../go/GoNodeModel.h"
#import "../../../go/GoNodeSetup.h"
#import "../../../go/GoPlayer.h"
#import "../../../shared/LongRunningActionCounter.h"


// Currently the node numbers view canvas has only one row, so node numbers
// always have y-position 0 (zero).
static const unsigned short yPositionOfNodeNumber = 0;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewCanvas.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCanvas()
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
@property(nonatomic, assign) bool canvasNeedsUpdate;
@property(nonatomic, retain) NSString* notificationToPostAfterCanvasUpdate;
@property(nonatomic, retain) NodeTreeViewCanvasData* canvasData;
@property(nonatomic, assign) bool selectedNodePositionsNeedsUpdate;
@property(nonatomic, retain) NSArray* cachedSelectedNodePositions;
@property(nonatomic, retain) NSArray* cachedSelectedNodeNodeNumbersViewPositions;
@property(nonatomic, assign) bool nodeSelectionStyleNeedsUpdate;
@property(nonatomic, assign) bool nodeSymbolNeedsUpdate;
@property(nonatomic, retain) GoNode* nodeWhoseSymbolNeedsUpdate;
@end


@implementation NodeTreeViewCanvas

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewCanvas object with a canvas of size zero.
///
/// @note This is the designated initializer of NodeTreeViewCanvas.
// -----------------------------------------------------------------------------
- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.nodeTreeViewModel = nodeTreeViewModel;

  self.canvasNeedsUpdate = false;
  self.notificationToPostAfterCanvasUpdate = nil;
  self.canvasSize = CGSizeZero;
  self.canvasData = [[[NodeTreeViewCanvasData alloc] init] autorelease];
  self.selectedNodePositionsNeedsUpdate = false;
  self.cachedSelectedNodePositions = nil;
  self.cachedSelectedNodeNodeNumbersViewPositions = nil;
  self.nodeSelectionStyleNeedsUpdate = false;
  self.nodeSymbolNeedsUpdate = false;
  self.nodeWhoseSymbolNeedsUpdate = nil;

  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewCanvas object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  self.notificationToPostAfterCanvasUpdate = nil;
  self.nodeTreeViewModel = nil;
  self.canvasData = nil;
  self.cachedSelectedNodePositions = nil;
  self.cachedSelectedNodeNodeNumbersViewPositions = nil;
  self.nodeWhoseSymbolNeedsUpdate = nil;

  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goNodeTreeLayoutDidChange:) name:goNodeTreeLayoutDidChange object:nil];
  [center addObserver:self selector:@selector(currentGameVariationDidChange:) name:currentGameVariationDidChange object:nil];
  [center addObserver:self selector:@selector(currentBoardPositionDidChange:) name:currentBoardPositionDidChange object:nil];
  [center addObserver:self selector:@selector(nodeSetupDataDidChange:) name:nodeSetupDataDidChange object:nil];
  [center addObserver:self selector:@selector(nodeAnnotationDataDidChange:) name:nodeAnnotationDataDidChange object:nil];
  [center addObserver:self selector:@selector(nodeMarkupDataDidChange:) name:nodeMarkupDataDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];

  [self.nodeTreeViewModel addObserver:self forKeyPath:@"condenseMoveNodes" options:0 context:NULL];
  [self.nodeTreeViewModel addObserver:self forKeyPath:@"alignMoveNodes" options:0 context:NULL];
  [self.nodeTreeViewModel addObserver:self forKeyPath:@"branchingStyle" options:0 context:NULL];
  [self.nodeTreeViewModel addObserver:self forKeyPath:@"nodeSelectionStyle" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self.nodeTreeViewModel removeObserver:self forKeyPath:@"condenseMoveNodes"];
  [self.nodeTreeViewModel removeObserver:self forKeyPath:@"alignMoveNodes"];
  [self.nodeTreeViewModel removeObserver:self forKeyPath:@"branchingStyle"];
  [self.nodeTreeViewModel removeObserver:self forKeyPath:@"nodeSelectionStyle"];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  self.canvasNeedsUpdate = true;
  self.notificationToPostAfterCanvasUpdate = nodeTreeViewContentDidChange;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goNodeTreeLayoutDidChange notification.
// -----------------------------------------------------------------------------
- (void) goNodeTreeLayoutDidChange:(NSNotification*)notification
{
  self.canvasNeedsUpdate = true;
  self.notificationToPostAfterCanvasUpdate = nodeTreeViewContentDidChange;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentGameVariationDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentGameVariationDidChange:(NSNotification*)notification
{
  // TODO xxx Find a way to update the selected lines properties only instead
  // of brute-force recalculating the entire canvas. Node numbers would also
  // need to be updated.
  self.canvasNeedsUpdate = true;
  self.notificationToPostAfterCanvasUpdate = nodeTreeViewContentDidChange;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentBoardPositionDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentBoardPositionDidChange:(NSNotification*)notification
{
  self.selectedNodePositionsNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeSetupDataDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeSetupDataDidChange:(NSNotification*)notification
{
  self.nodeSymbolNeedsUpdate = true;
  self.nodeWhoseSymbolNeedsUpdate = notification.object;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeAnnotationDataDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeAnnotationDataDidChange:(NSNotification*)notification
{
  self.nodeSymbolNeedsUpdate = true;
  self.nodeWhoseSymbolNeedsUpdate = notification.object;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeMarkupDataDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeMarkupDataDidChange:(NSNotification*)notification
{
  self.nodeSymbolNeedsUpdate = true;
  self.nodeWhoseSymbolNeedsUpdate = notification.object;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"condenseMoveNodes"])
  {
    self.canvasNeedsUpdate = true;
    self.notificationToPostAfterCanvasUpdate = nodeTreeViewCondenseMoveNodesDidChange;
    [self delayedUpdate];
  }
  else if ([keyPath isEqualToString:@"alignMoveNodes"])
  {
    self.canvasNeedsUpdate = true;
    self.notificationToPostAfterCanvasUpdate = nodeTreeViewAlignMoveNodesDidChange;
    [self delayedUpdate];
  }
  else if ([keyPath isEqualToString:@"branchingStyle"])
  {
    self.canvasNeedsUpdate = true;
    self.notificationToPostAfterCanvasUpdate = nodeTreeViewBranchingStyleDidChange;
    [self delayedUpdate];
  }
  else if ([keyPath isEqualToString:@"nodeSelectionStyle"])
  {
    self.nodeSelectionStyleNeedsUpdate = true;
    [self delayedUpdate];
  }
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;

  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(delayedUpdate) withObject:nil waitUntilDone:YES];
    return;
  }

  [self updateCanvas];
  [self updateSelectedNodePositions];
  [self updateNodeSelectionStyle];
  [self updateNodeSymbol];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
// -----------------------------------------------------------------------------
- (void) updateCanvas
{
  if (! self.canvasNeedsUpdate)
    return;
  self.canvasNeedsUpdate = false;

  [self recalculateCanvasPrivate];
  [self invalidateCachedSelectedNodePositions];
  [self invalidateCachedSelectedNodeNodeNumbersViewPositions];

  if (self.notificationToPostAfterCanvasUpdate)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationToPostAfterCanvasUpdate object:nil];
    self.notificationToPostAfterCanvasUpdate = nil;
  }
  else
  {
    DDLogError(@"No notification found to post after node tree view canvas update");
  }
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
// -----------------------------------------------------------------------------
- (void) updateSelectedNodePositions
{
  if (! self.selectedNodePositionsNeedsUpdate)
    return;
  self.selectedNodePositionsNeedsUpdate = false;

  GoNode* previousCurrentBoardPositionNode = self.canvasData.currentBoardPositionNode;
  [self updateSelectedStateOfCellsForNode:previousCurrentBoardPositionNode
                               toNewState:false
                                  nodeMap:self.canvasData.nodeMap
                          cellsDictionary:self.canvasData.cellsDictionary
           nodeNumbersViewCellsDictionary:self.canvasData.nodeNumbersViewCellsDictionary];

  // Update canvasData with the newly selected node NOW, to make sure that if
  // new node number cells are generated their "selected" state is set correctly
  GoNode* newCurrentBoardPositionNode =  [GoGame sharedGame].boardPosition.currentNode;
  self.canvasData.currentBoardPositionNode = newCurrentBoardPositionNode;

  NSArray* positionsTupleOfNewlySelectedCells = [self updateSelectedStateOfCellsForNode:newCurrentBoardPositionNode
                                                                             toNewState:true
                                                                                nodeMap:self.canvasData.nodeMap
                                                                        cellsDictionary:self.canvasData.cellsDictionary
                                                         nodeNumbersViewCellsDictionary:self.canvasData.nodeNumbersViewCellsDictionary];

  NSArray* positionsOfNewlySelectedCells = positionsTupleOfNewlySelectedCells.firstObject;
  NSArray* nodeNumbersViewPositionsOfNewlySelectedCells = positionsTupleOfNewlySelectedCells.lastObject;
  self.cachedSelectedNodePositions = positionsOfNewlySelectedCells;
  self.cachedSelectedNodeNodeNumbersViewPositions = nodeNumbersViewPositionsOfNewlySelectedCells;

  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeViewSelectedNodeDidChange
                                                      object:positionsTupleOfNewlySelectedCells];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
// -----------------------------------------------------------------------------
- (void) updateNodeSelectionStyle
{
  if (! self.nodeSelectionStyleNeedsUpdate)
    return;
  self.nodeSelectionStyleNeedsUpdate = false;

  // Node selection style is purely visual, there's no need to recalculate
  // anything.
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeViewNodeSelectionStyleDidChange object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
// -----------------------------------------------------------------------------
- (void) updateNodeSymbol
{
  if (! self.nodeSymbolNeedsUpdate)
    return;
  self.nodeSymbolNeedsUpdate = false;

  if (! self.nodeWhoseSymbolNeedsUpdate)
    return;

  enum NodeTreeViewCellSymbol newNodeSymbol = [self symbolForNode:self.nodeWhoseSymbolNeedsUpdate];
  NodeTreeViewBranchTuple* branchTuple = [self branchTupleForNode:self.nodeWhoseSymbolNeedsUpdate];

  self.nodeWhoseSymbolNeedsUpdate = nil;

  if (branchTuple->symbol == newNodeSymbol)
    return;

  branchTuple->symbol = newNodeSymbol;

  NSArray* positionsOfNodeWithChangedSymbol = [self positionsForBranchTuple:branchTuple];
  for (NodeTreeViewCellPosition* position in positionsOfNodeWithChangedSymbol)
  {
    NSArray* tuple = [self.canvasData.cellsDictionary objectForKey:position];
    NodeTreeViewCell* cell = tuple.firstObject;
    cell.symbol = newNodeSymbol;

    self.canvasData.cellsDictionary[position] = @[cell, tuple.lastObject];
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeViewNodeSymbolDidChange object:positionsOfNodeWithChangedSymbol];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Returns the NodeTreeViewCell object that is located at position
/// @a position on the canvas. Returns @e nil if @a position denotes a position
/// that is outside the canvas' bounds.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellAtPosition:(NodeTreeViewCellPosition*)position;
{
  NSArray* tuple = [self.canvasData.cellsDictionary objectForKey:position];
  if (tuple)
    return tuple.firstObject;

  if (position.x < self.canvasSize.width && position.y < self.canvasSize.height)
    return [NodeTreeViewCell emptyCell];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object that is represented by the cell that is
/// located at position @a position. Returns @e nil if @a position denotes a
/// position that is outside the canvas' bounds, or if the cell located at
/// position @a position does not represent a GoNode.
// -----------------------------------------------------------------------------
- (GoNode*) nodeAtPosition:(NodeTreeViewCellPosition*)position
{
  NSArray* tuple = [self.canvasData.cellsDictionary objectForKey:position];
  if (! tuple)
    return nil;

  NodeTreeViewBranchTuple* branchTuple = tuple.lastObject;
  if (position.x < branchTuple->xPositionOfFirstCell ||
      position.x > branchTuple->xPositionOfFirstCell + branchTuple->numberOfCellsForNode - 1)
  {
    return nil;
  }

  return branchTuple->node;
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of horizontally consecutive NodeTreeViewCellPosition
/// objects that indicate which cells on the node tree view canvas display the
/// node @a node. The list is empty if @a node is @e nil, or if no positions
/// exist for @a node.
// -----------------------------------------------------------------------------
- (NSArray*) positionsForNode:(GoNode*)node
{
  NodeTreeViewBranchTuple* branchTuple = [self branchTupleForNode:node];
  return [self positionsForBranchTuple:branchTuple];
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of horizontally consecutive NodeTreeViewCellPosition
/// objects that indicate which cells on the node tree view canvas display the
/// node that is currently selected. The list is empty if currently no node is
/// selected.
// -----------------------------------------------------------------------------
- (NSArray*) selectedNodePositions
{
  if (self.cachedSelectedNodePositions)
    return self.cachedSelectedNodePositions;

  NSArray* selectedNodePositions = [self positionsForNode:self.canvasData.currentBoardPositionNode];
  self.cachedSelectedNodePositions = selectedNodePositions;
  return selectedNodePositions;
}

// -----------------------------------------------------------------------------
/// @brief Returns the NodeNumbersViewCell object that is located at position
/// @a position on the node numbers canvas. Returns a NodeNumbersViewCell object
/// with node number -1 if there is no node number to display at position
/// @a position. Returns @e nil if @a position denotes a position that is
/// outside the canvas' bounds.
// -----------------------------------------------------------------------------
- (NodeNumbersViewCell*) nodeNumbersViewCellAtPosition:(NodeTreeViewCellPosition*)position
{
  NodeNumbersViewCell* nodeNumbersViewCell = [self.canvasData.nodeNumbersViewCellsDictionary objectForKey:position];
  if (nodeNumbersViewCell)
    return nodeNumbersViewCell;

  if (position.x < self.canvasSize.width && position.y < 1)
    return [NodeNumbersViewCell emptyCell];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of horizontally consecutive NodeTreeViewCellPosition
/// objects that indicate which cells on the node numbers view canvas display
/// the node number for node @a node. The list is empty if @a node is @e nil, or
/// if no positions exist for @a node.
// -----------------------------------------------------------------------------
- (NSArray*) nodeNumbersViewPositionsForNode:(GoNode*)node
{
  NodeTreeViewBranchTuple* branchTuple = [self branchTupleForNode:node];
  return [self nodeNumbersViewPositionsForBranchTuple:branchTuple];
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of horizontally consecutive NodeTreeViewCellPosition
/// objects that indicate which cells on the node numbers view canvas display
/// the node number for the node that is currently selected. The list is empty
/// if currently no node is selected.
// -----------------------------------------------------------------------------
- (NSArray*) selectedNodeNodeNumbersViewPositions
{
  if (self.cachedSelectedNodeNodeNumbersViewPositions)
    return self.cachedSelectedNodeNodeNumbersViewPositions;

  NSArray* selectedNodeNodeNumbersViewPositions = [self nodeNumbersViewPositionsForNode:self.canvasData.currentBoardPositionNode];
  self.cachedSelectedNodeNodeNumbersViewPositions = selectedNodeNodeNumbersViewPositions;
  return selectedNodeNodeNumbersViewPositions;
}

// -----------------------------------------------------------------------------
/// @brief Triggers a full re-calculation of the node tree view canvas at the
/// next opportunity. Posts #nodeTreeViewContentDidChange to the default
/// notification centre when the re-calculation has finished.
///
/// If no long-running action is currently in progress, the re-calculation is
/// performed synchronously, otherwise the re-calculation will be performed
/// after the long-running action has finished.
///
/// If the re-calculation is performed synchronously, it is guaranteed that it
/// will be performed on the main thread. Also the notification will be posted
/// on the main thread.
// -----------------------------------------------------------------------------
- (void) recalculateCanvas
{
  self.canvasNeedsUpdate = true;
  self.notificationToPostAfterCanvasUpdate = nodeTreeViewContentDidChange;
  [self delayedUpdate];
}

#pragma mark - Private API - Canvas calculation - Main method

// -----------------------------------------------------------------------------
/// @brief Private back-end method to perform a full re-calculation of the
/// node tree view canvas. Does not post a notification when finished.
///
/// The algorithm that performs the calculation can be broken down into several
/// distinct steps that are executed in a specific order. Overview:
/// 1. Iterate depth-first over the tree of nodes provided by GoNodeModel.
///    During the iteration the following pieces of data are collected:
///    - A collection of existing branches, with the following additional data
///      per branch:
///      - The branch's relationships: Parent branch, previous sibling branch,
///        last child branches. Unlike the usual firstChild/nextSibling
///        relationships, the branch relationships are reversed because
///        determining the y-position of branches requires iteration over the
///        branches in reverse order.
///      - The node in the parent branch from which the branch originates.
///    - An ordered list of nodes in each branch, with the following additional
///      data:
///      - NodeTreeViewCellSymbol value
///      - The number of cells that represent the node on the canvas. This is
///        influenced by the user preference "Condense move nodes".
///      - Preliminary x-position of the first cell that represents the node on
///        the canvas. This can still change if the user preference
///        "Align move nodes" is enabled.
///      - List of child branches that branch off of the node (if any).
/// 2. Perform the alignment of move nodes. When this step finds a move node
///    that needs to be aligned, it adjusts the x-position of the first cell
///    that represents the move node and all of the move node's descendants.
///    The result of this step are the final x-positions. Therefore the length
///    of each branch is now also known.
/// 3. Iterate over the branches collected in the first step and determine the
///    y-position of each branch. This requires the knowledge about branch
///    lengths that was obtained in step 2.
/// 4. Iterate over all branches and nodes and generate cells to represent the
///    nodes on the canvas. This step also generates cells that contain only
///    lines, which are used to connect nodes to their predecessor and successor
///    nodes. Line-only cells contain either horizontal lines to connect a node
///    to its predecessor node in the same branch, diagonal and/or horizontal
///    lines to connect a node to its predecessor branching node in the parent
///    branch, or an assortment of vertical, diagonal and/or horizontal lines to
///    connect a branching node to its successor nodes in child branches.
// -----------------------------------------------------------------------------
- (void) recalculateCanvasPrivate
{
  // Game is missing during app launch 
  GoGame* game = [GoGame sharedGame];
  if (! game)
    return;

  DDLogDebug(@"%@: Canvas calculation started", self);

  GoNodeModel* nodeModel = game.nodeModel;
  GoBoardPosition* boardPosition = game.boardPosition;

  bool condenseMoveNodes = self.nodeTreeViewModel.condenseMoveNodes;
  bool alignMoveNodes = self.nodeTreeViewModel.alignMoveNodes;
  enum NodeTreeViewBranchingStyle branchingStyle = self.nodeTreeViewModel.branchingStyle;
  int numberOfCellsOfMultipartCell = self.nodeTreeViewModel.numberOfCellsOfMultipartCell;
  int numberOfNodeNumberCells = [self numberOfNodeNumberCells];

  NodeTreeViewCanvasData* canvasData = [[[NodeTreeViewCanvasData alloc] init] autorelease];
  canvasData.currentBoardPositionNode = boardPosition.currentNode;

  // Step 1: Collect data about branches
  [self collectBranchDataInCanvasData:canvasData
                  fromNodeTreeInModel:nodeModel
                    condenseMoveNodes:condenseMoveNodes
         numberOfCellsOfMultipartCell:numberOfCellsOfMultipartCell
                       alignMoveNodes:alignMoveNodes];

  // Step 2: Align moves nodes
  if (alignMoveNodes)
  {
    [self alignMoveNodes:canvasData];
  }

  // Step 3: Determine y-coordinates of branches
  [self determineYCoordinatesOfBranches:canvasData
                         branchingStyle:branchingStyle];

  // Step 4: Generate cells
  [self generateCells:canvasData
       branchingStyle:branchingStyle];

  // Step 5: Generate node numbers
  [self generateNodeNumbers:canvasData
                  nodeModel:nodeModel
          condenseMoveNodes:condenseMoveNodes
             alignMoveNodes:alignMoveNodes
    numberOfNodeNumberCells:numberOfNodeNumberCells
         nodeNumberInterval:self.nodeTreeViewModel.nodeNumberInterval];

  self.canvasData = canvasData;
  self.canvasSize = CGSizeMake(canvasData.highestXPosition + 1, canvasData.highestYPosition + 1);

  DDLogDebug(@"%@: Canvas calculation finished", self);
}

#pragma mark - Private API - Canvas calculation - Part 1: Collect branch data

// -----------------------------------------------------------------------------
/// @brief Iterates depth-first over the tree of nodes provided by GoNodeModel
/// to collect information about branches.
// -----------------------------------------------------------------------------
- (void) collectBranchDataInCanvasData:(NodeTreeViewCanvasData*)canvasData
                   fromNodeTreeInModel:(GoNodeModel*)nodeModel
                     condenseMoveNodes:(bool)condenseMoveNodes
          numberOfCellsOfMultipartCell:(int)numberOfCellsOfMultipartCell
                        alignMoveNodes:(bool)alignMoveNodes
{
  int highestMoveNumberThatAppearsInAtLeastTwoBranches = canvasData.highestMoveNumberThatAppearsInAtLeastTwoBranches;
  NSMutableArray* branchTuplesForMoveNumbers = canvasData.branchTuplesForMoveNumbers;
  NSMutableDictionary* nodeMap = canvasData.nodeMap;
  NSMutableArray* branches = canvasData.branches;
  GoNode* currentBoardPositionNode = canvasData.currentBoardPositionNode;

  NSMutableArray* stack = [NSMutableArray array];

  GoNode* currentNode = nodeModel.rootNode;

  // If a new branch is created, this must be used as the new branch's parent
  // branch
  NodeTreeViewBranch* parentBranch = nil;
  unsigned short xPosition = 0;
  unsigned short nodeNumber = 0;
  int indexOfNodeFromCurrentGameVariation = 0;
  GoNode* nodeFromCurrentGameVariation = [nodeModel nodeAtIndex:indexOfNodeFromCurrentGameVariation];

  while (true)
  {
    NodeTreeViewBranch* branch = nil;
    NSUInteger indexOfBranch = -1;
    NodeTreeViewBranchTuple* previousBranchTupleInBranch = nil;

    while (currentNode)
    {
      if (! branch)
      {
        branch = [self createBranchWithParentBranch:parentBranch
                                  firstNodeOfBranch:currentNode
                                            nodeMap:nodeMap];

        [branches addObject:branch];
        indexOfBranch = branches.count - 1;
      }

      // The childBranches member variable is initialized by the
      // NodeTreeViewBranchTuple initializer
      NodeTreeViewBranchTuple* branchTuple = [[[NodeTreeViewBranchTuple alloc] init] autorelease];
      branchTuple->xPositionOfFirstCell = xPosition;
      branchTuple->node = currentNode;
      branchTuple->nodeNumber = nodeNumber;
      branchTuple->symbol = [self symbolForNode:currentNode];
      branchTuple->numberOfCellsForNode = [self numberOfCellsForNode:currentNode condenseMoveNodes:condenseMoveNodes numberOfCellsOfMultipartCell:numberOfCellsOfMultipartCell];
      // This assumes that numberOfCellsForNode is always an uneven number
      branchTuple->indexOfCenterCell = floorf(branchTuple->numberOfCellsForNode / 2.0);
      branchTuple->branch = branch;
      branchTuple->nodeIsCurrentBoardPositionNode = (currentNode == currentBoardPositionNode);

      if (currentNode == nodeFromCurrentGameVariation)
      {
        branchTuple->nodeIsInCurrentGameVariation = true;

        indexOfNodeFromCurrentGameVariation++;
        if (indexOfNodeFromCurrentGameVariation < nodeModel.numberOfNodes)
          nodeFromCurrentGameVariation = [nodeModel nodeAtIndex:indexOfNodeFromCurrentGameVariation];
        else
          nodeFromCurrentGameVariation = nil;
      }
      else
      {
        branchTuple->nodeIsInCurrentGameVariation = false;
      }

      [branch->branchTuples addObject:branchTuple];

      if (previousBranchTupleInBranch)
        previousBranchTupleInBranch->nextBranchTupleInBranch = branchTuple;
      previousBranchTupleInBranch = branchTuple;

      NSValue* key = [NSValue valueWithNonretainedObject:currentNode];
      nodeMap[key] = branchTuple;

      // TODO xxx Take user preference "numbering style" into account
      nodeNumber++;
      xPosition += branchTuple->numberOfCellsForNode;

      if (alignMoveNodes)
      {
        GoMove* move = currentNode.goMove;
        if (move)
          [self collectDataFromMove:move branch:branch branchTuple:branchTuple branchTuplesForMoveNumbers:branchTuplesForMoveNumbers highestMoveNumberThatAppearsInAtLeastTwoBranches:&highestMoveNumberThatAppearsInAtLeastTwoBranches];
      }

      [stack addObject:branchTuple];

      currentNode = currentNode.firstChild;
    }

    if (stack.count > 0)
    {
      NodeTreeViewBranchTuple* branchTuple = stack.lastObject;
      [stack removeLastObject];

      currentNode = branchTuple->node;
      nodeNumber = branchTuple->nodeNumber;
      xPosition = branchTuple->xPositionOfFirstCell;
      if (! currentNode.parent || currentNode.parent.firstChild == currentNode)
        parentBranch = branchTuple->branch;
      else
        parentBranch = branchTuple->branch->parentBranch;

      currentNode = currentNode.nextSibling;
    }
    else
    {
      // We're done
      break;
    }
  }

  canvasData.highestMoveNumberThatAppearsInAtLeastTwoBranches = highestMoveNumberThatAppearsInAtLeastTwoBranches;
  canvasData.branchTuplesForMoveNumbers = branchTuplesForMoveNumbers;
  canvasData.nodeMap = nodeMap;
  canvasData.branches = branches;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new NodeTreeViewBranch object when the first node of a
/// branch (@a firstNodeOfBranch) is encountered. Performs all the necessary
/// linkage of the new branch with its sibling and parent branches.
// -----------------------------------------------------------------------------
- (NodeTreeViewBranch*) createBranchWithParentBranch:(NodeTreeViewBranch*)parentBranch
                                   firstNodeOfBranch:(GoNode*)firstNodeOfBranch
                                             nodeMap:(NSMutableDictionary*)nodeMap
{
  // The branchTuples member variable is initialized by the
  // NodeTreeViewBranch initializer
  NodeTreeViewBranch* branch = [[[NodeTreeViewBranch alloc] init] autorelease];
  branch->lastChildBranch = nil;
  branch->previousSiblingBranch = nil;
  branch->parentBranch = parentBranch;
  branch->yPosition = 0;

  // If there is no parent branch this means that the new branch is the main
  // branch => no linkage with other branches is necessary
  if (! parentBranch)
  {
    branch->parentBranchTupleBranchingNode = nil;
    return branch;
  }

  [self linkNewChildBranch:branch
           toBranchingNode:firstNodeOfBranch.parent
            inParentBranch:parentBranch
                   nodeMap:nodeMap];

  [self linkNewChildBranch:branch
            toParentBranch:parentBranch];

  return branch;
}

// -----------------------------------------------------------------------------
/// @brief Links a newly created child branch @a newChildBranch to the branching
/// node @a branchingNode from which the new child branch originates. The
/// branching node is located in parent branch @a parentBranch.
// -----------------------------------------------------------------------------
- (void) linkNewChildBranch:(NodeTreeViewBranch*)newChildBranch
            toBranchingNode:(GoNode*)branchingNode
             inParentBranch:(NodeTreeViewBranch*)parentBranch
                    nodeMap:(NSMutableDictionary*)nodeMap
{
  NSValue* key = [NSValue valueWithNonretainedObject:branchingNode];
  NodeTreeViewBranchTuple* branchingNodeTuple = [nodeMap objectForKey:key];

  newChildBranch->parentBranchTupleBranchingNode = branchingNodeTuple;

  [branchingNodeTuple->childBranches addObject:newChildBranch];
}

// -----------------------------------------------------------------------------
/// @brief Links a newly created child branch @a newChildBranch to the parent
/// branch @a parentBranch and/or the next sibling branch found among the
/// collection of child branches of @a parentBranch.
// -----------------------------------------------------------------------------
- (void) linkNewChildBranch:(NodeTreeViewBranch*)newChildBranch
             toParentBranch:(NodeTreeViewBranch*)parentBranch
{
  if (! parentBranch->lastChildBranch)
  {
    parentBranch->lastChildBranch = newChildBranch;
    return;
  }

  for (NodeTreeViewBranch* existingChildBranch = parentBranch->lastChildBranch;
       existingChildBranch;
       existingChildBranch = existingChildBranch->previousSiblingBranch)
  {
    if (! existingChildBranch->previousSiblingBranch)
    {
      existingChildBranch->previousSiblingBranch = newChildBranch;
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Collects data about @a move, which appears in @a branch in the node
/// represented by @a branchTuple, and stores the data in @a moveData.
// -----------------------------------------------------------------------------
                    - (void) collectDataFromMove:(GoMove*)move
                                          branch:(NodeTreeViewBranch*)branch
                                     branchTuple:(NodeTreeViewBranchTuple*)branchTuple
                      branchTuplesForMoveNumbers:(NSMutableArray*)branchTuplesForMoveNumbers
highestMoveNumberThatAppearsInAtLeastTwoBranches:(int*)highestMoveNumberThatAppearsInAtLeastTwoBranches
{
  NSMutableArray* branchTuplesForMoveNumber;

  int moveNumber = move.moveNumber;
  if (moveNumber > branchTuplesForMoveNumbers.count)
  {
    branchTuplesForMoveNumber = [NSMutableArray array];
    [branchTuplesForMoveNumbers addObject:branchTuplesForMoveNumber];
  }
  else
  {
    branchTuplesForMoveNumber = [branchTuplesForMoveNumbers objectAtIndex:moveNumber - 1];
  }

  [branchTuplesForMoveNumber addObject:branchTuple];

  if (branchTuplesForMoveNumber.count > 1)
  {
    if (moveNumber > *highestMoveNumberThatAppearsInAtLeastTwoBranches)
      *highestMoveNumberThatAppearsInAtLeastTwoBranches = moveNumber;
  }
}

#pragma mark - Private API - Canvas calculation - Part 2: Align move nodes

// -----------------------------------------------------------------------------
/// @brief Iterates over all moves that are present in @a canvasData and aligns
/// the x-position of the first cell that represents the node of each move. In
/// case of multipart cells, the alignment is made along the center cell.
// -----------------------------------------------------------------------------
- (void) alignMoveNodes:(NodeTreeViewCanvasData*)canvasData
{
  int highestMoveNumberThatAppearsInAtLeastTwoBranches = canvasData.highestMoveNumberThatAppearsInAtLeastTwoBranches;
  NSMutableArray* branchTuplesForMoveNumbers = canvasData.branchTuplesForMoveNumbers;

  // Optimization: We only have to align moves that appear in at least two
  // branches.
  for (int indexOfMove = 0;
       indexOfMove < highestMoveNumberThatAppearsInAtLeastTwoBranches;
       indexOfMove++)
  {
    NSMutableArray* branchTuplesForMoveNumber = [branchTuplesForMoveNumbers objectAtIndex:indexOfMove];

    // If the move appears in only a single branch there can be no
    // mis-alignment => we can go to the next move
    // Note: We can't break off the alignment process entirely from this
    // condition. It's entirely possible that for a time there is only a
    // single branch that has moves, and that later on child branches can
    // split off again from that branch so that the count increases again to
    // 2 or more. In the following example we see that although the count is
    // 1 for M1, M3 and M6, the alignment process needs to continue each time.
    // o---M1---M2
    //     +----M2---M3---M4---M5---M6---M7
    //               +----M4---M5   +----M7
    //               +----M4
    //    c=1   c=2  c=1  c=3  c=2  c=1  c=2  [...]
    if (branchTuplesForMoveNumber.count == 1)
      continue;

    unsigned short highestXPositionOfCenterCell = 0;
    bool currentMoveIsAlignedInAllBranches = [self isCurrentMoveAlignedInAllBranches:branchTuplesForMoveNumber
                                                        highestXPositionOfCenterCell:&highestXPositionOfCenterCell];
    if (currentMoveIsAlignedInAllBranches)
      continue;

    [self alignCurrentMoveInAllBranches:branchTuplesForMoveNumber
            targetXPositionOfCenterCell:highestXPositionOfCenterCell];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the data in @a branchTuplesForMoveNumber indicates
/// that all move nodes are aligned. Returns false if the data in
/// @a branchTuplesForMoveNumber indicates that at least one move node is not
/// aligned. The value of the out parameter @a highestXPositionOfCenterCell in
/// this case is filled with the x-position on which the alignment needs to take
/// place.
// -----------------------------------------------------------------------------
- (bool) isCurrentMoveAlignedInAllBranches:(NSMutableArray*)branchTuplesForMoveNumber
              highestXPositionOfCenterCell:(unsigned short*)highestXPositionOfCenterCell
{
  bool isFirstBranch = true;
  bool currentMoveIsAlignedInAllBranches = true;

  for (NodeTreeViewBranchTuple* branchTupleForMoveNumber in branchTuplesForMoveNumber)
  {
    unsigned short xPositionOfCenterCell = (branchTupleForMoveNumber->xPositionOfFirstCell +
                                            branchTupleForMoveNumber->indexOfCenterCell);
    if (isFirstBranch)
    {
      *highestXPositionOfCenterCell = xPositionOfCenterCell;
      isFirstBranch = false;
    }
    else
    {
      if (xPositionOfCenterCell != *highestXPositionOfCenterCell)
      {
        currentMoveIsAlignedInAllBranches = false;
        if (xPositionOfCenterCell > *highestXPositionOfCenterCell)
          *highestXPositionOfCenterCell = xPositionOfCenterCell;
      }
    }
  }

  return currentMoveIsAlignedInAllBranches;
}

// -----------------------------------------------------------------------------
/// @brief Aligns the move nodes in @a branchTuplesForMoveNumber so that for all
/// move nodes the x-position of the center cell that represents the move node
/// on the canvas is equal to @a targetXPositionOfCenterCell. Also shifts the
/// descendant nodes of each move node that is aligned.
// -----------------------------------------------------------------------------
- (void) alignCurrentMoveInAllBranches:(NSMutableArray*)branchTuplesForMoveNumber
           targetXPositionOfCenterCell:(unsigned short)targetXPositionOfCenterCell
{
  for (NodeTreeViewBranchTuple* branchTupleForMoveNumber in branchTuplesForMoveNumber)
  {
    unsigned short xPositionOfCenterCell = (branchTupleForMoveNumber->xPositionOfFirstCell
                                            + branchTupleForMoveNumber->indexOfCenterCell);

    // Branch is already aligned
    if (xPositionOfCenterCell == targetXPositionOfCenterCell)
      continue;

    [self shiftMoveNodeAndDescendantNodes:branchTupleForMoveNumber
             currentXPositionOfCenterCell:xPositionOfCenterCell
              targetXPositionOfCenterCell:targetXPositionOfCenterCell];
  }
}

// -----------------------------------------------------------------------------
/// @brief Shifts the x-position of the first cell of the move node in
/// @a branchTuple so that the center cell has an x-position equal to
/// @a targetXPositionOfCenterCell. The center cell's current x-position is
/// @a currentXPositionOfCenterCell. Also shifts the descendant nodes of the
/// move node.
// -----------------------------------------------------------------------------
- (void) shiftMoveNodeAndDescendantNodes:(NodeTreeViewBranchTuple*)branchTuple
            currentXPositionOfCenterCell:(unsigned short)currentXPositionOfCenterCell
             targetXPositionOfCenterCell:(unsigned short)targetXPositionOfCenterCell
{
  NSUInteger indexOfFirstBranchTupleToShift = [branchTuple->branch->branchTuples indexOfObject:branchTuple];
  unsigned short alignOffset = targetXPositionOfCenterCell - currentXPositionOfCenterCell;

  // It is not sufficient to shift only the tuples of the current branch
  // => there may be child branches whose tuple positions also need to be
  // shifted. In the following example, when M2 of the main branch is
  // aligned, the cells of the child branches that contain M3 and M4 also
  // need to be shifted.
  // o---M1---M2---A----A
  //     |    +----M3   +----A----M4
  //     +----A----M2

  NSMutableArray* branchesToShift = [NSMutableArray array];
  [branchesToShift addObject:branchTuple->branch];
  bool shiftingInitialBranch = true;

  // Reusable local function
  void (^shiftBranchTuple) (NodeTreeViewBranchTuple*) = ^(NodeTreeViewBranchTuple* branchTupleToShift)
  {
    branchTupleToShift->xPositionOfFirstCell += alignOffset;

    if (branchTupleToShift->childBranches.count > 0)
      [branchesToShift addObjectsFromArray:branchTupleToShift->childBranches];
  };

  // We start the shifting process by going through the remaining tuples
  // of the initial branch. When we find a tuple that represents a
  // branching point we add the child branches that branch off of that
  // point to the list. Subsequent iterations of the while-loop will go
  // through the child branches that were added and repeat the process of
  // shifting and looking for child branches. Eventually the branch
  // hierarchy will be exhausted and no further child branches will be
  // added to the list, at which point the while-loop will stop.
  while (branchesToShift.count > 0)
  {
    NodeTreeViewBranch* branchToShift = branchesToShift.firstObject;
    [branchesToShift removeObjectAtIndex:0];
    NSMutableArray* branchTuplesToShift = branchToShift->branchTuples;

    if (shiftingInitialBranch)
    {
      shiftingInitialBranch = false;

      // Enumeration by index is slower than fast enumeration, but we
      // can't avoid using it because we have to start at a non-zero index
      // and fast enumeration does not allow to specify a non-zero start
      // index
      NSUInteger numberOfBranchTuples = branchTuplesToShift.count;
      for (NSUInteger indexOfBranchTupleToShift = indexOfFirstBranchTupleToShift; indexOfBranchTupleToShift < numberOfBranchTuples; indexOfBranchTupleToShift++)
      {
        NodeTreeViewBranchTuple* branchTupleToShift = [branchTuplesToShift objectAtIndex:indexOfBranchTupleToShift];
        shiftBranchTuple(branchTupleToShift);
      }
    }
    else
    {
      for (NodeTreeViewBranchTuple* branchTupleToShift in branchTuplesToShift)
        shiftBranchTuple(branchTupleToShift);
    }
  }
}

#pragma mark - Private API - Canvas calculation - Part 3: Determine y-coordinates

// -----------------------------------------------------------------------------
/// @brief Iterates over the branches that are present in @a canvasData and
/// determines the y-position of each branch. Stores the highest y-position
/// found in the @e height element of the @a canvasSize property in
/// @a canvasData.
// -----------------------------------------------------------------------------
- (void) determineYCoordinatesOfBranches:(NodeTreeViewCanvasData*)canvasData
                          branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  NSMutableArray* branches = canvasData.branches;

  // In the worst case each branch is on its own y-position => create the array
  // to cater for this worst case
  NSUInteger numberOfBranches = branches.count;
  unsigned short lowestOccupiedXPositionOfRow[numberOfBranches];
  for (NSUInteger indexOfBranch = 0; indexOfBranch < numberOfBranches; indexOfBranch++)
    lowestOccupiedXPositionOfRow[indexOfBranch] = -1;

  unsigned short highestYPosition = 0;

  NSMutableArray* stack = [NSMutableArray array];

  NodeTreeViewBranch* currentBranch = branches.firstObject;

  while (true)
  {
    while (currentBranch)
    {
      [self determineYCoordinateOfBranch:currentBranch
            lowestOccupiedXPositionOfRow:lowestOccupiedXPositionOfRow
                          branchingStyle:branchingStyle];

      if (currentBranch->yPosition > highestYPosition)
        highestYPosition = currentBranch->yPosition;

      [stack addObject:currentBranch];

      currentBranch = currentBranch->lastChildBranch;
    }

    if (stack.count > 0)
    {
      currentBranch = stack.lastObject;
      [stack removeLastObject];

      currentBranch = currentBranch->previousSiblingBranch;
    }
    else
    {
      // We're done
      break;
    }
  }

  canvasData.highestYPosition = highestYPosition;
}

// -----------------------------------------------------------------------------
/// @brief Determines the y-position of @a branch.
// -----------------------------------------------------------------------------
- (void) determineYCoordinateOfBranch:(NodeTreeViewBranch*)branch
         lowestOccupiedXPositionOfRow:(unsigned short*)lowestOccupiedXPositionOfRow
                       branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  unsigned short lowestXPositionOfBranchOnIntermediateYPositions;
  unsigned short lowestXPositionOfBranchOnFinalYPosition;
  if (branch->parentBranch)
  {
    lowestXPositionOfBranchOnIntermediateYPositions = branch->parentBranchTupleBranchingNode->xPositionOfFirstCell;

    // Diagonal branching style allows for a small optimization of the
    // available space on the LAST child branch:
    // A---B---C---D---E---F---G
    //     |   |\--H   |    \--I
    //      \--J\--K    \--L---M
    // The branch with node J fits on the same y-position as the branch with
    // node K because 1) the diagonal branching line leading from C to K
    // does not occupy the space of J, and there is also no vertical
    // branching line to another child node of C that would take the space
    // away from J. The situation is different for the branch with node L
    // and M: Because the branch contains two nodes it is too long and does
    // not fit on the same y-position as the branch with node I.
    if (branchingStyle == NodeTreeViewBranchingStyleDiagonal &&
        branch->parentBranchTupleBranchingNode->childBranches.lastObject == branch)
    {
      // The desired space gain would be
      //   currentBranch->parentBranchTupleBranchingNode->numberOfCellsForNode
      // instead of just +1. However, since a diagonal line crosses only a
      // single sub-cell, and there are no sub-cells in y-direction, diagonal
      // branching can only ever gain space that is worth 1 sub-cell. As a
      // result, when move nodes are condensed (which means that a multipart
      // cell's number of sub-cells is >1) the space gain from diagonal
      // branching is never sufficient to fit a branch on an y-position where
      // it would not have fit with right-angle branching.
      lowestXPositionOfBranchOnFinalYPosition = lowestXPositionOfBranchOnIntermediateYPositions + 1;
    }
    else
    {
      lowestXPositionOfBranchOnFinalYPosition = lowestXPositionOfBranchOnIntermediateYPositions;
    }
  }
  else
  {
    lowestXPositionOfBranchOnIntermediateYPositions = 0;
    lowestXPositionOfBranchOnFinalYPosition = 0;
  }

  // The y-position of a child branch is at least one below the y-position
  // of the parent branch
  unsigned short yPosition;
  if (branch->parentBranch)
    yPosition = branch->parentBranch->yPosition + 1;
  else
    yPosition = 0;

  NodeTreeViewBranchTuple* lastBranchTuple = branch->branchTuples.lastObject;
  unsigned short highestXPositionOfBranch = (lastBranchTuple->xPositionOfFirstCell +
                                             lastBranchTuple->numberOfCellsForNode -
                                             1);

  while (highestXPositionOfBranch >= lowestOccupiedXPositionOfRow[yPosition])
  {
    lowestOccupiedXPositionOfRow[yPosition] = lowestXPositionOfBranchOnIntermediateYPositions;
    yPosition++;
  }

  lowestOccupiedXPositionOfRow[yPosition] = lowestXPositionOfBranchOnFinalYPosition;
  branch->yPosition = yPosition;
}

#pragma mark - Private API - Canvas calculation - Part 4: Generate cells

// -----------------------------------------------------------------------------
/// @brief Iterates over all branches and nodes that are present in
/// @a canvasData and generates cells to represent the nodes on the canvas.
///
/// This step not only generates cells for the nodes, it also generates cells
/// that contain only lines, which are used to connect nodes to their
/// predecessor and successor nodes. Line-only cells contain either horizontal
/// lines to connect a node to its predecessor node in the same branch,
/// diagonal and/or horizontal lines to connect a node to its predecessor
/// branching node in the parent branch, or an assortment of vertical, diagonal
/// and/or horizontal lines to connect a branching node to its successor nodes
/// in child branches.
// -----------------------------------------------------------------------------
- (void) generateCells:(NodeTreeViewCanvasData*)canvasData
        branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  unsigned short highestXPosition = 0;
  GoNode* highestXPositionNode = nil;
  NSMutableDictionary* cellsDictionary = canvasData.cellsDictionary;

  NSMutableArray* branches = canvasData.branches;
  for (NodeTreeViewBranch* branch in branches)
  {
    unsigned short xPositionAfterLastCellInBranchingTuple;
    if (branch->parentBranch)
    {
      xPositionAfterLastCellInBranchingTuple = (branch->parentBranchTupleBranchingNode->xPositionOfFirstCell +
                                                branch->parentBranchTupleBranchingNode->numberOfCellsForNode);
    }
    else
    {
      xPositionAfterLastCellInBranchingTuple = 0;
    }

    [self generateCellsForBranch:branch
xPositionAfterLastCellInBranchingTuple:xPositionAfterLastCellInBranchingTuple
                  branchingStyle:branchingStyle
                 cellsDictionary:cellsDictionary
                highestXPosition:&highestXPosition
            highestXPositionNode:&highestXPositionNode];
  }

  canvasData.highestXPosition = highestXPosition;
  canvasData.highestXPositionNode = highestXPositionNode;
}

// -----------------------------------------------------------------------------
/// @brief Generates the cells for the entire branch @a branch.
// -----------------------------------------------------------------------------
       - (void) generateCellsForBranch:(NodeTreeViewBranch*)branch
xPositionAfterLastCellInBranchingTuple:(unsigned short)xPositionAfterLastCellInBranchingTuple
                        branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                       cellsDictionary:(NSMutableDictionary*)cellsDictionary
                      highestXPosition:(unsigned short*)highestXPosition
                  highestXPositionNode:(GoNode**)highestXPositionNode
{
  unsigned short xPositionAfterPreviousBranchTuple = xPositionAfterLastCellInBranchingTuple;

  NodeTreeViewBranchTuple* firstBranchTupleOfBranch = branch->branchTuples.firstObject;
  NodeTreeViewBranchTuple* lastBranchTupleOfBranch = branch->branchTuples.lastObject;

  for (NodeTreeViewBranchTuple* branchTuple in branch->branchTuples)
  {
    // Adjust xPositionAfterPreviousBranchTuple so that the next branch tuple
    // can connect
    xPositionAfterPreviousBranchTuple = [self generateCellsForBranchTuple:branchTuple
                                        xPositionAfterPreviousBranchTuple:xPositionAfterPreviousBranchTuple
                                                        yPositionOfBranch:branch->yPosition
                                                 firstBranchTupleOfBranch:firstBranchTupleOfBranch
                                                  lastBranchTupleOfBranch:lastBranchTupleOfBranch
                                                           branchingStyle:branchingStyle                 cellsDictionary:cellsDictionary
                                                         highestXPosition:highestXPosition
                                                     highestXPositionNode:highestXPositionNode];
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates the cells for the node represented by @a branchTuple. This
/// includes line-only cells on the left and below the node, connecting the node
/// to its predecessor and successor nodes.
///
/// Line-only cells contain either horizontal lines to connect a node to its
/// predecessor node in the same branch, diagonal and/or horizontal lines to
/// connect a node to its predecessor branching node in the parent branch, or
/// an assortment of vertical, diagonal and/or horizontal lines to connect a
/// branching node to its successor nodes in child branches.
// -----------------------------------------------------------------------------
- (unsigned short) generateCellsForBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
             xPositionAfterPreviousBranchTuple:(unsigned short)xPositionAfterPreviousBranchTuple
                             yPositionOfBranch:(unsigned short)yPositionOfBranch
                      firstBranchTupleOfBranch:(NodeTreeViewBranchTuple*)firstBranchTupleOfBranch
                       lastBranchTupleOfBranch:(NodeTreeViewBranchTuple*)lastBranchTupleOfBranch
                                branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                               cellsDictionary:(NSMutableDictionary*)cellsDictionary
                              highestXPosition:(unsigned short*)highestXPosition
                          highestXPositionNode:(GoNode**)highestXPositionNode
{
  bool diagonalConnectionToBranchingLineEstablished = [self generateCellsLeftOfBranchTuple:branchTuple
                                                         xPositionAfterPreviousBranchTuple:xPositionAfterPreviousBranchTuple
                                                                         yPositionOfBranch:yPositionOfBranch
                                                                  firstBranchTupleOfBranch:firstBranchTupleOfBranch
                                                                            branchingStyle:branchingStyle
                                                                           cellsDictionary:cellsDictionary];

  if (branchTuple->childBranches.count > 0)
  {
    [self generateCellsBelowBranchTuple:branchTuple
                      yPositionOfBranch:yPositionOfBranch
                         branchingStyle:branchingStyle
                        cellsDictionary:cellsDictionary];
  }

  [self generateCellsForBranchTuple:branchTuple
                  yPositionOfBranch:yPositionOfBranch
           firstBranchTupleOfBranch:firstBranchTupleOfBranch
            lastBranchTupleOfBranch:(NodeTreeViewBranchTuple*)lastBranchTupleOfBranch
diagonalConnectionToBranchingLineEstablished:diagonalConnectionToBranchingLineEstablished
                     branchingStyle:branchingStyle
                    cellsDictionary:cellsDictionary
                   highestXPosition:highestXPosition
               highestXPositionNode:highestXPositionNode];

  unsigned short xPositionAfterBranchTuple = (branchTuple->xPositionOfFirstCell +
                                              branchTuple->numberOfCellsForNode);
  return xPositionAfterBranchTuple;
}

// -----------------------------------------------------------------------------
/// @brief Generates line-only cells on the left of the node represented by
/// @a branchTuple.
///
/// In the simple case, the cells connect the node to its predecessor node in
/// the same branch.
///
/// In the more complex case, the cells reach out to the vertical branching line
/// to connect the node to its predecessor branching node in the parent branch.
// -----------------------------------------------------------------------------
- (bool) generateCellsLeftOfBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
      xPositionAfterPreviousBranchTuple:(unsigned short)xPositionAfterPreviousBranchTuple
                      yPositionOfBranch:(unsigned short)yPositionOfBranch
               firstBranchTupleOfBranch:(NodeTreeViewBranchTuple*)firstBranchTupleOfBranch
                         branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                        cellsDictionary:(NSMutableDictionary*)cellsDictionary
{
  bool diagonalConnectionToBranchingLineEstablished = false;

  unsigned short xPositionOfFirstCell = xPositionAfterPreviousBranchTuple;
  for (unsigned short xPositionOfCell = xPositionOfFirstCell; xPositionOfCell < branchTuple->xPositionOfFirstCell; xPositionOfCell++)
  {
    NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];

    // A diagonal line connecting to a branching line needs to be drawn in the
    // first cell on the left of firstBranchTupleOfBranch, if, and only if
    // 1) obviously branching style is diagonal; 2) nodes are not represented
    // by multipart cells => for multipart cells the diagonal connecting line
    // is located in a standalone cell below the branching node
    if (xPositionOfCell == xPositionOfFirstCell &&
        branchTuple == firstBranchTupleOfBranch &&
        branchingStyle == NodeTreeViewBranchingStyleDiagonal &&
        branchTuple->numberOfCellsForNode == 1)
    {
      diagonalConnectionToBranchingLineEstablished = true;
      cell.lines = NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight;  // connect to branching line
    }
    else
    {
      cell.lines = NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight;
    }

    if (branchTuple->nodeIsInCurrentGameVariation)
      cell.linesSelectedGameVariation = cell.lines;

    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPositionOfCell y:yPositionOfBranch];
    cellsDictionary[position] = @[cell, branchTuple];
  }

  return diagonalConnectionToBranchingLineEstablished;
}

// -----------------------------------------------------------------------------
/// @brief Generates line-only cells below the branching node represented by
/// @a branchTuple.
///
/// The generated cells form a vertical branching line that reaches out from the
/// branching node towards its child nodes. Appropriate horizontal and/or
/// diagonal stub lines branching away from the vertical line are added.
///
/// The following schematic depicts what kind of lines need to be generated for
/// each branching style when condenseMoveNodes is enabled, i.e. when multipart
/// cells are involved. "N" marks the center cells of multipart cells that
/// represent a node. "o" marks branching line junctions.
///
/// @verbatim
/// NodeTreeViewBranchingStyleDiagonal     NodeTreeViewBranchingStyleRightAngle
///
///     0    1    2    3    4    5           0    1    2    3    4    5
///   +---++---++---+                      +---++---++---+
///   |   ||   ||   |                      |   ||   ||   |
/// 0 |   || N ||   |                      |   || N ||   |
///   |   || |\||   |                      |   || | ||   |
///   +---++-|-++---+                      +---++-|-++---+
///   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
///   |   || | ||\  ||   ||   ||   |       |   || | ||   ||   ||   ||   |
/// 1 |   || o || o---------N ||   |       |   || o--------------N ||   |
///   |   || |\||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
///   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
///   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
///   |   || | ||\  ||   ||   ||   |       |   || | ||   ||   ||   ||   |
/// 2 |   || | || o---------N ||   |       |   || o--------------N ||   |
///   |   || | ||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
///   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
///   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
///   |   || | ||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
/// 3 |   || o ||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
///   |   ||  \||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
///   +---++---++---++---++---++---+       +---++-|-++---++---++---++---+
///   +---++---++---++---++---++---+       +---++-|-++---++---++---++---+
///   |   ||   ||\  ||   ||   ||   |       |   || | ||   ||   ||   ||   |
/// 4 |   ||   || o---------N ||   |       |   || o--------------N ||   |
///   |   ||   ||   ||   ||   ||   |       |   ||   ||   ||   ||   ||   |
///   +---++---++---++---++---++---+       +---++---++---++---++---++---+
///
/// Cells to be generated on each y-position:
/// - y=0: 1/0, 2/0                             1/0, 2/0
/// - y=1  1/1, 2/1                             1/1, 2/1
/// - y=2  1/2                                  1/2
/// - y=3  2/3                                  1/4, 2/4
/// @endverbatim
// -----------------------------------------------------------------------------
- (void) generateCellsBelowBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
                     yPositionOfBranch:(unsigned short)yPositionOfBranch
                        branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                       cellsDictionary:(NSMutableDictionary*)cellsDictionary
{
  NodeTreeViewBranch* lastChildBranch = branchTuple->childBranches.lastObject;

  unsigned short yPositionBelowBranchingNode = yPositionOfBranch + 1;
  unsigned short yPositionOfLastChildBranch = lastChildBranch->yPosition;

  NSUInteger indexOfNextChildBranchToHorizontallyConnect = 0;
  NodeTreeViewBranch* nextChildBranchToHorizontallyConnect = [branchTuple->childBranches objectAtIndex:indexOfNextChildBranchToHorizontallyConnect];
  NSUInteger indexOfNextChildBranchToDiagonallyConnect = -1;
  NodeTreeViewBranch* nextChildBranchToDiagonallyConnect = nil;
  if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
  {
    NodeTreeViewBranch* firstChildBranch = branchTuple->childBranches.firstObject;
    if (firstChildBranch->yPosition > yPositionBelowBranchingNode)
    {
      indexOfNextChildBranchToDiagonallyConnect = 0;
      nextChildBranchToDiagonallyConnect = firstChildBranch;
    }
    // If there is a second child branch it is guaranteed to have an
    // y-position that is greater than yPositionBelowBranchingNode
    else if (branchTuple->childBranches.count > 1)
    {
      indexOfNextChildBranchToDiagonallyConnect = 1;
      nextChildBranchToDiagonallyConnect = [branchTuple->childBranches objectAtIndex:indexOfNextChildBranchToDiagonallyConnect];
    }
  }

  NodeTreeViewBranch* childBranchInCurrentGameVariation = [self childBranchInCurrentGameVariation:branchTuple];

  unsigned int xPositionOfVerticalLineCell = branchTuple->xPositionOfFirstCell + branchTuple->indexOfCenterCell;

  for (unsigned short yPosition = yPositionBelowBranchingNode; yPosition <= yPositionOfLastChildBranch; yPosition++)
  {
    [self generateCellsBelowBranchTuple:branchTuple
                            atYPosition:yPosition
                        lastChildBranch:lastChildBranch
            xPositionOfVerticalLineCell:xPositionOfVerticalLineCell
   nextChildBranchToHorizontallyConnect:nextChildBranchToHorizontallyConnect
     nextChildBranchToDiagonallyConnect:nextChildBranchToDiagonallyConnect
      childBranchInCurrentGameVariation:childBranchInCurrentGameVariation
                         branchingStyle:branchingStyle
                        cellsDictionary:cellsDictionary];

    if (yPosition == nextChildBranchToHorizontallyConnect->yPosition)
    {
      if (yPosition == yPositionOfLastChildBranch)
      {
        indexOfNextChildBranchToHorizontallyConnect = -1;
        nextChildBranchToHorizontallyConnect = nil;
      }
      else
      {
        indexOfNextChildBranchToHorizontallyConnect++;
        nextChildBranchToHorizontallyConnect = [branchTuple->childBranches objectAtIndex:indexOfNextChildBranchToHorizontallyConnect];
      }
    }

    if (nextChildBranchToDiagonallyConnect && yPosition + 1 == nextChildBranchToDiagonallyConnect->yPosition)
    {
      if (nextChildBranchToDiagonallyConnect == lastChildBranch)
      {
        indexOfNextChildBranchToDiagonallyConnect = -1;
        nextChildBranchToDiagonallyConnect = nil;
      }
      else
      {
        indexOfNextChildBranchToDiagonallyConnect++;
        nextChildBranchToDiagonallyConnect = [branchTuple->childBranches objectAtIndex:indexOfNextChildBranchToDiagonallyConnect];
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates line-only cells below the branching node represented by
/// @a branchTuple at the specific y-position @a yPosition.
// -----------------------------------------------------------------------------
- (void) generateCellsBelowBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
                           atYPosition:(unsigned short)yPosition
                       lastChildBranch:(NodeTreeViewBranch*)lastChildBranch
           xPositionOfVerticalLineCell:(unsigned short)xPositionOfVerticalLineCell
  nextChildBranchToHorizontallyConnect:(NodeTreeViewBranch*)nextChildBranchToHorizontallyConnect
    nextChildBranchToDiagonallyConnect:(NodeTreeViewBranch*)nextChildBranchToDiagonallyConnect
     childBranchInCurrentGameVariation:(NodeTreeViewBranch*)childBranchInCurrentGameVariation
                        branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                       cellsDictionary:(NSMutableDictionary*)cellsDictionary
{
  [self generateVerticalLineCellBelowBranchTuple:branchTuple
                                       xPosition:xPositionOfVerticalLineCell
                                       yPosition:yPosition
                                 lastChildBranch:lastChildBranch
            nextChildBranchToHorizontallyConnect:nextChildBranchToHorizontallyConnect
              nextChildBranchToDiagonallyConnect:nextChildBranchToDiagonallyConnect
               childBranchInCurrentGameVariation:childBranchInCurrentGameVariation
                                  branchingStyle:branchingStyle
                                 cellsDictionary:cellsDictionary];

  // If the branching node occupies more than one cell then we need to
  // create additional cells if there is a branch on the y-position
  // that needs a horizontal connection
  if (branchTuple->numberOfCellsForNode > 1 && yPosition == nextChildBranchToHorizontallyConnect->yPosition)
  {
    [self generateCellsRightOfVerticalLineCell:branchTuple
                                   atYPosition:yPosition
                   xPositionOfVerticalLineCell:xPositionOfVerticalLineCell
         successorNodeIsInCurrentGameVariation:(nextChildBranchToHorizontallyConnect == childBranchInCurrentGameVariation)
                                branchingStyle:branchingStyle
                               cellsDictionary:cellsDictionary];
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates a single vertical branching line cell below the branching
/// node represented by @a branchTuple. The cell is located at the specific
/// y-position @a yPosition.
// -----------------------------------------------------------------------------
- (void) generateVerticalLineCellBelowBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
                                        xPosition:(unsigned short)xPosition
                                        yPosition:(unsigned short)yPosition
                                  lastChildBranch:(NodeTreeViewBranch*)lastChildBranch
             nextChildBranchToHorizontallyConnect:(NodeTreeViewBranch*)nextChildBranchToHorizontallyConnect
               nextChildBranchToDiagonallyConnect:(NodeTreeViewBranch*)nextChildBranchToDiagonallyConnect
                childBranchInCurrentGameVariation:(NodeTreeViewBranch*)childBranchInCurrentGameVariation
                                   branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                                  cellsDictionary:(NSMutableDictionary*)cellsDictionary
{
  NodeTreeViewCellLines lines = NodeTreeViewCellLineNone;
  NodeTreeViewCellLines linesSelectedGameVariation = NodeTreeViewCellLineNone;

  if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
  {
    if (yPosition < lastChildBranch->yPosition)
    {
      lines |= NodeTreeViewCellLineCenterToTop;
      if (childBranchInCurrentGameVariation && yPosition < childBranchInCurrentGameVariation->yPosition)
        linesSelectedGameVariation |= NodeTreeViewCellLineCenterToTop;

      if (nextChildBranchToDiagonallyConnect && yPosition + 1 == nextChildBranchToDiagonallyConnect->yPosition)
      {
        lines |= NodeTreeViewCellLineCenterToBottomRight;
        if (childBranchInCurrentGameVariation && nextChildBranchToDiagonallyConnect == childBranchInCurrentGameVariation)
          linesSelectedGameVariation |= NodeTreeViewCellLineCenterToBottomRight;
      }

      if (yPosition + 1 < lastChildBranch->yPosition)
      {
        lines |= NodeTreeViewCellLineCenterToBottom;
        if (childBranchInCurrentGameVariation && yPosition + 1 < childBranchInCurrentGameVariation->yPosition)
          linesSelectedGameVariation |= NodeTreeViewCellLineCenterToBottom;
      }
    }
  }
  else
  {
    lines |= NodeTreeViewCellLineCenterToTop;
    if (childBranchInCurrentGameVariation && yPosition <= childBranchInCurrentGameVariation->yPosition)
      linesSelectedGameVariation |= NodeTreeViewCellLineCenterToTop;

    if (yPosition == nextChildBranchToHorizontallyConnect->yPosition)
    {
      lines |= NodeTreeViewCellLineCenterToRight;
      if (childBranchInCurrentGameVariation && nextChildBranchToHorizontallyConnect == childBranchInCurrentGameVariation)
        linesSelectedGameVariation |= NodeTreeViewCellLineCenterToRight;
    }

    if (yPosition < lastChildBranch->yPosition)
    {
      lines |= NodeTreeViewCellLineCenterToBottom;
      if (childBranchInCurrentGameVariation && yPosition < childBranchInCurrentGameVariation->yPosition)
        linesSelectedGameVariation |= NodeTreeViewCellLineCenterToBottom;
    }
  }

  // For diagonal branching style, no cell needs to be generated on the
  // last y-position
  if (lines != NodeTreeViewCellLineNone)
  {
    NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
    cell.lines = lines;
    cell.linesSelectedGameVariation = linesSelectedGameVariation;

    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition y:yPosition];
    cellsDictionary[position] = @[cell, branchTuple];
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates cells to the right of a single vertical branching line cell
/// below the branching node represented by @a branchTuple. The cells are
/// located at the specific y-position @a yPosition. The cells form a stub line
/// branching away from the vertical line.
// -----------------------------------------------------------------------------
- (void) generateCellsRightOfVerticalLineCell:(NodeTreeViewBranchTuple*)branchTuple
                                  atYPosition:(unsigned short)yPosition
                  xPositionOfVerticalLineCell:(unsigned short)xPositionOfVerticalLineCell
        successorNodeIsInCurrentGameVariation:(bool)successorNodeIsInCurrentGameVariation
                               branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                              cellsDictionary:(NSMutableDictionary*)cellsDictionary
{
  NodeTreeViewCellLines linesOfFirstCell;
  if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
    linesOfFirstCell = NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight;
  else
    linesOfFirstCell = NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight;

  unsigned short xPositionOfFirstCell = xPositionOfVerticalLineCell + 1;
  unsigned short xPositionOfLastCell = branchTuple->xPositionOfFirstCell + branchTuple->numberOfCellsForNode - 1;
  for (unsigned short xPosition = xPositionOfFirstCell; xPosition <= xPositionOfLastCell; xPosition++)
  {
    NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
    if (xPosition == xPositionOfFirstCell)
      cell.lines = linesOfFirstCell;
    else
      cell.lines = NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight;

    if (successorNodeIsInCurrentGameVariation)
      cell.linesSelectedGameVariation = cell.lines;

    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition y:yPosition];
    cellsDictionary[position] = @[cell, branchTuple];
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates cells for the node represented by @a branchTuple.
// -----------------------------------------------------------------------------
- (void) generateCellsForBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
                   yPositionOfBranch:(unsigned short)yPositionOfBranch
            firstBranchTupleOfBranch:(NodeTreeViewBranchTuple*)firstBranchTupleOfBranch
             lastBranchTupleOfBranch:(NodeTreeViewBranchTuple*)lastBranchTupleOfBranch
diagonalConnectionToBranchingLineEstablished:(bool)diagonalConnectionToBranchingLineEstablished
                      branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                     cellsDictionary:(NSMutableDictionary*)cellsDictionary
                    highestXPosition:(unsigned short*)highestXPosition
                highestXPositionNode:(GoNode**)highestXPositionNode
{
  for (unsigned int indexOfCell = 0; indexOfCell < branchTuple->numberOfCellsForNode; indexOfCell++)
  {
    NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
    cell.part = indexOfCell;
    cell.parts = branchTuple->numberOfCellsForNode;

    cell.symbol = branchTuple->symbol;
    [self addLinesToCell:cell
             indexOfCell:indexOfCell
             branchTuple:branchTuple
       yPositionOfBranch:yPositionOfBranch
firstBranchTupleOfBranch:firstBranchTupleOfBranch
 lastBranchTupleOfBranch:lastBranchTupleOfBranch
diagonalConnectionToBranchingLineEstablished:diagonalConnectionToBranchingLineEstablished
          branchingStyle:branchingStyle];
    cell.selected = branchTuple->nodeIsCurrentBoardPositionNode;

    unsigned short xPosition = branchTuple->xPositionOfFirstCell + indexOfCell;
    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition y:yPositionOfBranch];
    cellsDictionary[position] = @[cell, branchTuple];
  }

  unsigned short xPositionOfLastCell = branchTuple->xPositionOfFirstCell + branchTuple->numberOfCellsForNode - 1;
  if (xPositionOfLastCell > *highestXPosition)
  {
    *highestXPosition = xPositionOfLastCell;
    *highestXPositionNode = branchTuple->node;
  }
}

// -----------------------------------------------------------------------------
/// @brief Calculates the lines for the cell @a cell which wholly or partially
/// (in the case of multipart cells) depicts the node represented by
/// @a branchTuple on the canvas.
// -----------------------------------------------------------------------------
                     - (void) addLinesToCell:(NodeTreeViewCell*)cell
                                 indexOfCell:(unsigned int)indexOfCell
                                 branchTuple:(NodeTreeViewBranchTuple*)branchTuple
                           yPositionOfBranch:(unsigned short)yPositionOfBranch
                    firstBranchTupleOfBranch:(NodeTreeViewBranchTuple*)firstBranchTupleOfBranch
                     lastBranchTupleOfBranch:(NodeTreeViewBranchTuple*)lastBranchTupleOfBranch
diagonalConnectionToBranchingLineEstablished:(bool)diagonalConnectionToBranchingLineEstablished
                              branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  bool isCellBeforeOrIncludingCenter = (indexOfCell <= branchTuple->indexOfCenterCell);
  bool isCenterCellForNode = (indexOfCell == branchTuple->indexOfCenterCell);
  bool isCellAfterOrIncludingCenter = (indexOfCell >= branchTuple->indexOfCenterCell);

  // Horizontal connecting lines to previous node in the same branch,
  // or horizontal/diagonal connecting lines to branching node in parent
  // branch
  if (isCellBeforeOrIncludingCenter)
  {
    [self addLinesToCellBeforeOrIncludingCenter:cell
                                    indexOfCell:indexOfCell
                            isCenterCellForNode:isCenterCellForNode
                                    branchTuple:branchTuple
                              yPositionOfBranch:yPositionOfBranch
                       firstBranchTupleOfBranch:firstBranchTupleOfBranch
                        lastBranchTupleOfBranch:lastBranchTupleOfBranch
   diagonalConnectionToBranchingLineEstablished:diagonalConnectionToBranchingLineEstablished
                                 branchingStyle:branchingStyle];
  }

  // Horizontal connecting lines to next node in the same branch
  if (isCellAfterOrIncludingCenter)
  {
    [self addLinesToCellAfterOrIncludingCenter:cell
                                   indexOfCell:indexOfCell
                           isCenterCellForNode:isCenterCellForNode
                                   branchTuple:branchTuple
                       lastBranchTupleOfBranch:lastBranchTupleOfBranch];
  }

  // Vertical and/or diagonal connecting lines to child branches
  if (isCenterCellForNode && branchTuple->childBranches.count > 0)
  {
    [self addLinesToCenterCellConnectingChildBranches:cell
                                          branchTuple:branchTuple
                                       branchingStyle:branchingStyle];
  }
}

// -----------------------------------------------------------------------------
/// @brief Calculates the lines for the cell identified by @a indexOfCell which
/// wholly or partially (in the case of multipart cells) depicts the node
/// represented by @a branchTuple on the canvas. The cell is left of the center
/// of the whole node, or the center cell itself.
// -----------------------------------------------------------------------------
- (void) addLinesToCellBeforeOrIncludingCenter:(NodeTreeViewCell*)cell
                                   indexOfCell:(unsigned int)indexOfCell
                           isCenterCellForNode:(bool)isCenterCellForNode
                                   branchTuple:(NodeTreeViewBranchTuple*)branchTuple
                             yPositionOfBranch:(unsigned short)yPositionOfBranch
                      firstBranchTupleOfBranch:(NodeTreeViewBranchTuple*)firstBranchTupleOfBranch
                       lastBranchTupleOfBranch:(NodeTreeViewBranchTuple*)lastBranchTupleOfBranch
  diagonalConnectionToBranchingLineEstablished:(bool)diagonalConnectionToBranchingLineEstablished
                                branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  NodeTreeViewCellLines lines = NodeTreeViewCellLineNone;

  bool isFirstCellForNode = (indexOfCell == 0);

  if (branchTuple == firstBranchTupleOfBranch && yPositionOfBranch == 0)
  {
    // Root node does not have connecting lines on the left
  }
  else
  {
    if (isFirstCellForNode)
    {
      if (branchTuple == firstBranchTupleOfBranch)
      {
        // A diagonal line connecting to a branching line needs to be
        // drawn if, and only if 1) obviously branching style is
        // diagonal; 2) nodes are not represented by multipart cells
        // (for multipart cells the diagonal connecting line is located
        // in a standalone cell below the branching node); and 3) if a diagonal
        // connecting line has not yet been established due to move
        // node alignment.
        if (branchingStyle == NodeTreeViewBranchingStyleDiagonal && branchTuple->numberOfCellsForNode == 1 && ! diagonalConnectionToBranchingLineEstablished)
          lines |= NodeTreeViewCellLineCenterToTopLeft;
        else
          lines |= NodeTreeViewCellLineCenterToLeft;
      }
      else
      {
        lines |= NodeTreeViewCellLineCenterToLeft;
      }
    }
    else
    {
      lines |= NodeTreeViewCellLineCenterToLeft;
    }

    if (isCenterCellForNode)
    {
      // Whether or not to draw NodeTreeViewCellLineCenterToRight is
      // determined in the block for isCellAfterOrIncludingCenter
    }
    else
    {
      lines |= NodeTreeViewCellLineCenterToRight;
    }
  }

  cell.lines |= lines;

  if (branchTuple->nodeIsInCurrentGameVariation)
    cell.linesSelectedGameVariation |= lines;
}

// -----------------------------------------------------------------------------
/// @brief Calculates the lines for the cell identified by @a indexOfCell which
/// wholly or partially (in the case of multipart cells) depicts the node
/// represented by @a branchTuple on the canvas. The cell is right of the center
/// of the whole node, or the center cell itself.
// -----------------------------------------------------------------------------
- (void) addLinesToCellAfterOrIncludingCenter:(NodeTreeViewCell*)cell
                                  indexOfCell:(unsigned int)indexOfCell
                          isCenterCellForNode:(bool)isCenterCellForNode
                                  branchTuple:(NodeTreeViewBranchTuple*)branchTuple
                      lastBranchTupleOfBranch:(NodeTreeViewBranchTuple*)lastBranchTupleOfBranch
{
  NodeTreeViewCellLines lines = NodeTreeViewCellLineNone;

  if (branchTuple == lastBranchTupleOfBranch)
  {
    // No next node in the same branch => no connecting lines
  }
  else
  {
    lines |= NodeTreeViewCellLineCenterToRight;

    if (isCenterCellForNode)
    {
      // Whether or not to draw NodeTreeViewCellLineCenterToLeft is
      // determined in the block for isCellBeforeOrIncludingCenter
    }
    else
    {
      lines |= NodeTreeViewCellLineCenterToLeft;
    }
  }

  cell.lines |= lines;

  if (branchTuple->nodeIsInCurrentGameVariation &&
      branchTuple->nextBranchTupleInBranch &&
      branchTuple->nextBranchTupleInBranch->nodeIsInCurrentGameVariation)
  {
    cell.linesSelectedGameVariation |= lines;
  }
}

// -----------------------------------------------------------------------------
/// @brief Calculates the lines for the center cell which wholly or partially
/// (in the case of multipart cells) depicts the node represented by
/// @a branchTuple on the canvas. The lines form the start of the vertical
/// branching line that connect the node (which is a branching node) to its
/// child nodes.
// --------------------------x---------------------------------------------------
- (void) addLinesToCenterCellConnectingChildBranches:(NodeTreeViewCell*)cell
                                         branchTuple:(NodeTreeViewBranchTuple*)branchTuple
                                      branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  NodeTreeViewCellLines lines = NodeTreeViewCellLineNone;
  NodeTreeViewCellLines linesSelectedGameVariation = NodeTreeViewCellLineNone;

  NodeTreeViewBranch* childBranchInCurrentGameVariation = [self childBranchInCurrentGameVariation:branchTuple];

  if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
  {
    NodeTreeViewBranch* firstChildBranch = branchTuple->childBranches.firstObject;
    if (branchTuple->branch->yPosition + 1 == firstChildBranch->yPosition)
    {
      lines |= NodeTreeViewCellLineCenterToBottomRight;
      if (childBranchInCurrentGameVariation && childBranchInCurrentGameVariation == firstChildBranch)
        linesSelectedGameVariation |= NodeTreeViewCellLineCenterToBottomRight;

      if (branchTuple->childBranches.count > 1)
      {
        lines |= NodeTreeViewCellLineCenterToBottom;
        if (childBranchInCurrentGameVariation && childBranchInCurrentGameVariation != firstChildBranch)
          linesSelectedGameVariation |= NodeTreeViewCellLineCenterToBottom;
      }
    }
    else
    {
      lines |= NodeTreeViewCellLineCenterToBottom;
      if (childBranchInCurrentGameVariation)
        linesSelectedGameVariation |= NodeTreeViewCellLineCenterToBottom;
    }
  }
  else
  {
    lines |= NodeTreeViewCellLineCenterToBottom;
    if (childBranchInCurrentGameVariation)
      linesSelectedGameVariation |= NodeTreeViewCellLineCenterToBottom;
  }

  cell.lines |= lines;
  cell.linesSelectedGameVariation |= linesSelectedGameVariation;
}

#pragma mark - Private API - Canvas calculation - Part 5: Generate node numbers

// -----------------------------------------------------------------------------
/// @brief Generates node numbers to horizontally label some or all of the cells
/// that represent the nodes on the canvas.
///
/// The following are the rules that govern the node numbering algorithm. In
/// general, if two rules seem to conflict then the earlier rule takes
/// precedence over the later rule.
/// - Rule 1: A node that is a candidate for numbering is numbered only if there
///   is sufficient space to display the node number (e.g. without overlapping
///   with other node numbers).
/// - Rule 2: An uncondensed node is sufficiently wide to provide space for
///   displaying even the highest possible node number.
/// - Rule 3: Numbering uncondensed nodes has higher priority than numbering
///   condensed move nodes. If a decision must be made whether to number a
///   number an uncondensed node or a condensed move node, it is always the
///   uncondensed node that "wins". The reasoning behind this rule (besides the
///   convenient fact that it makes the implementation of the numbering
///   algorithm more manageable) is that condensed move nodes are considered,
///   by definition, less important than uncondensed nodes. This is why they
///   are displayed condensed in the first place, i.e. they are displayed
///   de-emphasized in favor of uncondensed nodes.
/// - Rule 4: Numbering nodes that are closer to the root node has higher
///   priority than numbering nodes that are farther away from the root node.
///   If a decision must be made whether to number two adjacent nodes, the one
///   that is closer to the root node "wins". The reasoning behind this rule is
///   that in general the game logic, and also the user's thought, travels along
///   a line that originates from the root node. The numbering should follow
///   this direction.
/// - Rule 5: The nodes of the current game variation are candidates for
///   numbering. Ideally the node tree is rendered in a tabular fashion so that
///   nodes with the same number are located in the same column - displaying a
///   node number in the column header in that case makes sense for all the
///   nodes in that column even if they are located in different game
///   variations. However, if one or both of the user preferences
///   "Align move nodes" and "Condense move nodes" is enabled, this tabular
///   model breaks down because nodes in different game variations may have
///   different node numbers even if they are rendered in the same x-position.
///   Even in the ideal tabular case, though, we want to number certain nodes
///   to draw attention to them (e.g. branching nodes, see rule 8), and this
///   makes sense only for the current game variation.
/// - Rule 6: Nodes in the current game variation whose number matches the user
///   preference "Numbering interval" are numbered. As a special case, because
///   the root node has node number 0, which always matches the numbering
///   interval, the root node is always numbered. If this were not the case it
///   would be a separate rule.
/// - Rule 7: The leaf node of the current game variation is numbered, even if
///   its node number does not match the numbering interval.
/// - Rule 8: All branching nodes in the current game variation as well as the
///   branching node's child node in the current game variation are numbered,
///   even if their node numbers do not match the numbering interval.
/// - Rule 9: If the current game variation is not the longest game variation,
///   and if none of the user preferences "Align move nodes" and
///   "Condense move nodes" is enabled, then nodes in the longest game variation
///   with an x-position beyond the leaf node of the current game variation also
///   become candidates for numbering. The goal of this rule is that the whole
///   width of the node tree view is numbered so that the user can scroll the
///   node tree view away from the current game variation and still have a rough
///   notion of which depth of the tree she is looking at. This is possible only
///   if the mentioned user preferences are disabled and the tabular model, as
///   explained in rule 5, holds true. Only the leaf node and the nodes that
///   match the user preference "numbering interval" are numbered.
/// - Rule 10: The selected node in the current game variation is numbered, even
///   if its node number does not match the numbering interval. Numbering of the
///   selected node occurs only after all the other node numbers have been
///   generated. The intent of this rule is that the selected node should only
///   be numbered if it has sufficient space after all the other node numbers
///   were already generated, i.e. numbering of the selected node must never
///   take away space so that another node would not be numbered. Reasoning
///   behind the rule: The user should not see other node numbers
///   appear/disappear only because the node selection changes.
// -----------------------------------------------------------------------------
- (void) generateNodeNumbers:(NodeTreeViewCanvasData*)canvasData
                   nodeModel:(GoNodeModel*)nodeModel
           condenseMoveNodes:(bool)condenseMoveNodes
              alignMoveNodes:(bool)alignMoveNodes
     numberOfNodeNumberCells:(int)numberOfNodeNumberCells
          nodeNumberInterval:(int)nodeNumberInterval
{
  NSDictionary* nodeMap = canvasData.nodeMap;
  NSMutableDictionary* nodeNumbersViewCellsDictionary = canvasData.nodeNumbersViewCellsDictionary;
  int numberOfNodeNumberCellsExtendingFromCenter = [self numberOfNodeNumberCellsExtendingFromCenter];

  // Rule 5: Number the current game variation
  NSMutableArray* nodeNumberingTuplesCurrentGameVariation = [self generateNodeNumbersForGameVariation:nodeModel.leafNode
                                                                  gameVariationIsCurrentGameVariation:true
                                                                 nodeNumberingTuplesPreviousVariation:nil
                                                                                              nodeMap:nodeMap
                                                                       nodeNumbersViewCellsDictionary:nodeNumbersViewCellsDictionary
                                                                                    condenseMoveNodes:condenseMoveNodes
                                                                              numberOfNodeNumberCells:numberOfNodeNumberCells
                                                           numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter
                                                                                   nodeNumberInterval:nodeNumberInterval];
  canvasData.nodeNumberingTuples = nodeNumberingTuplesCurrentGameVariation;

  // Rule 9: Number the longest game variation, unless the user preferences
  // prevent it
  if (nodeModel.leafNode != canvasData.highestXPositionNode && ! (condenseMoveNodes || alignMoveNodes))
  {
    NSMutableArray* nodeNumberingTuplesLongestGameVariation = [self generateNodeNumbersForGameVariation:canvasData.highestXPositionNode
                                                                    gameVariationIsCurrentGameVariation:false
                                                                   nodeNumberingTuplesPreviousVariation:nodeNumberingTuplesCurrentGameVariation
                                                                                                nodeMap:nodeMap
                                                                         nodeNumbersViewCellsDictionary:nodeNumbersViewCellsDictionary
                                                                                      condenseMoveNodes:condenseMoveNodes
                                                                                numberOfNodeNumberCells:numberOfNodeNumberCells
                                                             numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter
                                                                                     nodeNumberInterval:nodeNumberInterval];

    [canvasData.nodeNumberingTuples addObjectsFromArray:nodeNumberingTuplesLongestGameVariation];
  }

  // Rule 10: Number selected node after all other nodes were numbered
  [self generateNodeNumberForSelectedNodeIfNoneExistsYet:canvasData.currentBoardPositionNode
                                                 nodeMap:nodeMap
                          nodeNumbersViewCellsDictionary:nodeNumbersViewCellsDictionary
                                 numberOfNodeNumberCells:numberOfNodeNumberCells
              numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter];
}

// -----------------------------------------------------------------------------
/// @brief Generates node numbers for the game variation whose leaf node is
/// @a leafNodeOfGameVariationToNumber. @a gameVariationIsCurrentGameVariation
/// indicates whether the game variation to number is the current game variation
/// (@e true) or the longest game variation (@e false). In the latter case
/// @a nodeNumberingTuplesPreviousVariation is expected to contain the
/// result of numbering the previous game variation (which must have been the
/// current game variation).
///
/// The numbering is performed in two passes: In pass 1 uncondensed nodes are
/// numbered, in pass 2 condensed move nodes are numbered. This satisfies
/// rule 3 (numbering uncondensed nodes has higher priority than numbering
/// condensed move nodes).
///
/// The return value is an array consisting of tuples (NSArray objects). Each
/// tuple has two values: Value 1 is an NodeTreeViewBranchTuple object referring
/// to the node that was considered for numbering. Value 2 is an NSNumber
/// encapsulating a boolean value indicating whether the node was numbered or
/// not.
// -----------------------------------------------------------------------------
- (NSMutableArray*) generateNodeNumbersForGameVariation:(GoNode*)leafNodeOfGameVariationToNumber
                    gameVariationIsCurrentGameVariation:(bool)gameVariationIsCurrentGameVariation
                   nodeNumberingTuplesPreviousVariation:(NSMutableArray*)nodeNumberingTuplesPreviousVariation
                                                nodeMap:(NSDictionary*)nodeMap
                         nodeNumbersViewCellsDictionary:(NSMutableDictionary*)nodeNumbersViewCellsDictionary
                                      condenseMoveNodes:(bool)condenseMoveNodes
                                numberOfNodeNumberCells:(int)numberOfNodeNumberCells
             numberOfNodeNumberCellsExtendingFromCenter:(int)numberOfNodeNumberCellsExtendingFromCenter
                                     nodeNumberInterval:(int)nodeNumberInterval
{
  // Rule 9: Add numbers for the longest game variation. We don't number all
  // nodes, only those that are beyond the leaf node of the previous game
  // variation.
  unsigned short xPositionWherePass1ShouldStop;
  if (! gameVariationIsCurrentGameVariation)
  {
    NSArray* nodeNumberingTupleOfLeafNodeOfPreviousGameVariation = nodeNumberingTuplesPreviousVariation.lastObject;
    NodeTreeViewBranchTuple* branchTupleOfLeafNode = nodeNumberingTupleOfLeafNodeOfPreviousGameVariation.firstObject;
    xPositionWherePass1ShouldStop = branchTupleOfLeafNode->xPositionOfFirstCell + branchTupleOfLeafNode->numberOfCellsForNode;
  }
  else
  {
    xPositionWherePass1ShouldStop = 0;
  }

  // Pass 1: Number uncondensed nodes. A second pass is necessary only if
  // the user preference "condense move nodes" is enabled and pass 1 actually
  // encountered at least one condensed move node.
  bool didFindCondensedMoveNode = false;
  NSMutableArray* nodeNumberingTuples = [self generateNodeNumbersForUncondensedNodes:leafNodeOfGameVariationToNumber
                                                 gameVariationIsCurrentGameVariation:gameVariationIsCurrentGameVariation
                                                                             nodeMap:nodeMap
                                                      nodeNumbersViewCellsDictionary:nodeNumbersViewCellsDictionary
                                                                   condenseMoveNodes:condenseMoveNodes
                                          numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter
                                                                  nodeNumberInterval:nodeNumberInterval
                                                       xPositionWherePass1ShouldStop:xPositionWherePass1ShouldStop
                                                            didFindCondensedMoveNode:&didFindCondensedMoveNode];

  // Pass 2: Number condensed move nodes
  // The iteration progresses from the root node towards the leaf node because
  // we pass the previously collected array nodeNumberingTuples. This satisfies
  // rule 4 (numbering nodes that are closer to the root node has higher
  // priority than numbering nodes that are farther away from the root node).
  // The first pass cannot violate rule 4 because there we don't consider space
  // constraints, i.e. in the first pass all nodes that need numbering are
  // numbered.
  if (didFindCondensedMoveNode)
  {
    [self generateNodeNumbersForCondensedMoveNodes:nodeNumberingTuples
                    nodeNumbersViewCellsDictionary:nodeNumbersViewCellsDictionary
                           numberOfNodeNumberCells:numberOfNodeNumberCells
        numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter
                                nodeNumberInterval:nodeNumberInterval];
  }

  return nodeNumberingTuples;
}

// -----------------------------------------------------------------------------
/// @brief Generates node numbers for all uncondensed nodes in the game
/// variation whose leaf node is @a leafNodeOfGameVariationToNumber.
/// @a gameVariationIsCurrentGameVariation indicates whether the game variation
/// to number is the current game variation (@e true) or the longest game
/// variation (@e false). In the latter case @a xPositionWherePass1ShouldStop
/// is expected to contain a threshold after which this method should stop
/// processing nodes in the game variation.
///
/// The return value is an array consisting of tuples (NSArray objects). Each
/// tuple has two values: Value 1 is an NodeTreeViewBranchTuple object referring
/// to the node that was considered for numbering. Value 2 is an NSNumber
/// encapsulating a boolean value indicating whether the node was numbered or
/// not.
// -----------------------------------------------------------------------------
- (NSMutableArray*) generateNodeNumbersForUncondensedNodes:(GoNode*)leafNodeOfGameVariationToNumber
                       gameVariationIsCurrentGameVariation:(bool)gameVariationIsCurrentGameVariation
                                                   nodeMap:(NSDictionary*)nodeMap
                            nodeNumbersViewCellsDictionary:(NSMutableDictionary*)nodeNumbersViewCellsDictionary
                                         condenseMoveNodes:(bool)condenseMoveNodes
                numberOfNodeNumberCellsExtendingFromCenter:(int)numberOfNodeNumberCellsExtendingFromCenter
                                        nodeNumberInterval:(int)nodeNumberInterval
                             xPositionWherePass1ShouldStop:(unsigned short)xPositionWherePass1ShouldStop
                                  didFindCondensedMoveNode:(bool*)didFindCondensedMoveNode
{
  NSMutableArray* nodeNumberingTuples = [NSMutableArray array];

  for (GoNode* node = leafNodeOfGameVariationToNumber; node; node = node.parent)
  {
    NSValue* key = [NSValue valueWithNonretainedObject:node];
    NodeTreeViewBranchTuple* branchTuple = [nodeMap objectForKey:key];

    if (branchTuple->xPositionOfFirstCell < xPositionWherePass1ShouldStop)
      break;

    // Rule 1: Number nodes only if there is enough space.
    // - For condensed move nodes we delay the check for sufficient space after
    //   all uncondensed nodes were numbered (rule 3).
    // - For uncondensed nodes there is always enough space (rule 2).
    if (condenseMoveNodes && branchTuple->numberOfCellsForNode == 1)
    {
      [nodeNumberingTuples insertObject:@[branchTuple, @false] atIndex:0];
      *didFindCondensedMoveNode = true;
      continue;
    }

    // Rule 8: Number branching nodes and their child node in the current game
    // variation
    if ((gameVariationIsCurrentGameVariation && (node.isBranchingNode || node.parent.isBranchingNode)) ||
        // Rule 7: Always number the leaf node
        node == leafNodeOfGameVariationToNumber ||
        // Rule 6: Number nodes if the numbering interval matches
        branchTuple->nodeNumber % nodeNumberInterval == 0)
    {
      [nodeNumberingTuples insertObject:@[branchTuple, @true] atIndex:0];
      [self generateNodeNumberForBranchTuple:branchTuple
              nodeNumbersViewCellsDictionary:nodeNumbersViewCellsDictionary
                         isCondensedMoveNode:false
            nodeNumberExistsOnlyForSelection:false
  numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter];
    }
    else
    {
      [nodeNumberingTuples insertObject:@[branchTuple, @false] atIndex:0];
    }
  }

  return nodeNumberingTuples;
}

// -----------------------------------------------------------------------------
/// @brief Generates node numbers for all condensed move nodes listed in
/// @a nodeNumberingTuples. If a condensed move node is actually numbered,
/// its tuple in @a nodeNumberingTuples is updated so that the tuple's second
/// value becomes @e true.
// -----------------------------------------------------------------------------
- (void) generateNodeNumbersForCondensedMoveNodes:(NSMutableArray*)nodeNumberingTuples
                   nodeNumbersViewCellsDictionary:(NSMutableDictionary*)nodeNumbersViewCellsDictionary
                          numberOfNodeNumberCells:(int)numberOfNodeNumberCells
       numberOfNodeNumberCellsExtendingFromCenter:(int)numberOfNodeNumberCellsExtendingFromCenter
                               nodeNumberInterval:(int)nodeNumberInterval
{
  NSUInteger numberOfNodeNumberingTuples = nodeNumberingTuples.count;
  for (NSUInteger indexOfNodeNumberingTuple = 0;
       indexOfNodeNumberingTuple < numberOfNodeNumberingTuples;
       indexOfNodeNumberingTuple++)
  {
    NSArray* nodeNumberingResultTuple = [nodeNumberingTuples objectAtIndex:indexOfNodeNumberingTuple];
    NodeTreeViewBranchTuple* branchTuple = nodeNumberingResultTuple.firstObject;

    // If it's not a condensed move node we can skip it => it was already
    // numbered in pass 1
    if (branchTuple->numberOfCellsForNode > 1)
      continue;

    // Rule 6: Number nodes if the numbering interval matches
    if (branchTuple->nodeNumber % nodeNumberInterval != 0)
      continue;

    bool sufficientSpace = [self canGenerateNodeNumberForBranchTuple:branchTuple
                                                 nodeNumberingTuples:nodeNumberingTuples
                                  indexOfCandidateNodeNumberingTuple:indexOfNodeNumberingTuple
                                             numberOfNodeNumberCells:numberOfNodeNumberCells
                          numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter];
    if (! sufficientSpace)
      continue;

    [self generateNodeNumberForBranchTuple:branchTuple
            nodeNumbersViewCellsDictionary:nodeNumbersViewCellsDictionary
                       isCondensedMoveNode:true
          nodeNumberExistsOnlyForSelection:false
numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter];

    // Future iterations need to know that the node was numbered
    [nodeNumberingTuples replaceObjectAtIndex:indexOfNodeNumberingTuple withObject:@[branchTuple, @true]];
  }
}

// -----------------------------------------------------------------------------
/// @brief Checks if there is sufficient space to generate a node number for
/// @a branchTuple. Examines the neighbours of @a branchTuple whether a node
/// number was already generated for them. The information for this is taken
/// from @a nodeNumberingTuples. @a indexOfCandidateNodeNumberingTuple is the
/// index pointing into @a nodeNumberingTuples to the tuple that contains
/// @a branchTuple.
///
/// The "sufficient space checking" algorithm works like this:
/// - It assumes that all node numbers occupy a window with width equal to the
///   number of cells @a numberOfNodeNumberCells.
/// - It determines the node number window for @a branchTuple, specifically
///   the window's x-position on the node number canvas.
/// - It examines the nearest neighbours of @a branchTuple to the left and to
///   the right. A node number window is created for both neighbours.
///   - Important: The neighbouring node number windows's x-position could be
///     anything due to the user preference "Align move nodes".
/// - If the node number window of a neighbour intersects with the node number
///   window of @a branchTuple, a check is made whether the neighbour was
///   numbered.
///   - If the neighbour was numbered, the neighbour's node number occupies some
///     of the space that would be required for the node number for
///     @a branchTuple => Decision: There is not sufficient space to number
///     @a branchTuple and the algorithm returns @e false.
///   - If the neighbour was not numbered, the algorithm continues the search.
///     The next neighbour in the same direction is examined.
/// - If the node number window of a neighbour does not intersect with the node
///   number window of @a branchTuple, the algorithm considers the side on which
///   that neighbour lies to have sufficient space. The algorithm does not
///   continue the search in that direction.
/// - If the algorithm finds that both the left and right side of @a branchTuple
///   have sufficient space, the algorithm returns @e true.
/// - Boundary check: If there are no more neighbours on a side because
///   @a branchTuple is too close to either the start or end of
///   @a nodeNumberingTuples, the algorithm considers that side to have
///   sufficient space.
///
/// @note The reason why all node numbers occupy a window with equal width,
/// regardless of how many digits they have, is the way how the node number
/// drawing code is organized (tiling, each tile is divided into cells of equal
/// width, nodes and therefore node numbers must be represented by an uneven
/// number of cells so that content can be easily centered on the center cell).
///
/// @todo The algorithm here could be made a lot more efficient if it were made
/// stateful, i.e. if it would "remember" from one invocation to the next which
/// cells on either side are occupied.
// -----------------------------------------------------------------------------
- (bool) canGenerateNodeNumberForBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
                         nodeNumberingTuples:(NSMutableArray*)nodeNumberingTuples
          indexOfCandidateNodeNumberingTuple:(NSUInteger)indexOfCandidateNodeNumberingTuple
                     numberOfNodeNumberCells:(int)numberOfNodeNumberCells
  numberOfNodeNumberCellsExtendingFromCenter:(int)numberOfNodeNumberCellsExtendingFromCenter
{
  const NSUInteger numberOfNodeNumberingTuples = nodeNumberingTuples.count;

  // Calculate the window occupied by the node number of branchTuple
  unsigned short xPositionOfCenterCell = branchTuple->xPositionOfFirstCell + branchTuple->indexOfCenterCell;
  unsigned short xPositionOfFirstCell = xPositionOfCenterCell - numberOfNodeNumberCellsExtendingFromCenter;
  unsigned short xPositionOfLastCell = xPositionOfCenterCell + numberOfNodeNumberCellsExtendingFromCenter;

  bool spaceIsSufficient = true;
  bool stopLookingForSpaceOnLeftSide = false;
  bool stopLookingForSpaceOnRightSide = false;

  // The iteration is based on the worst case: That the nodes surrounding the
  // node represented by branchTuple are all only 1 cell wide. This means that
  // the algorithm at maximum has to examine numberOfCellsOfNodeNumber nodes on
  // both sides to come to a conclusion. If surrounding nodes are wider the
  // iteration will end early because the node number windows will no longer
  // intersect.
  for (int distanceFromCandidateNodeNumberingTuple = 1;
       distanceFromCandidateNodeNumberingTuple <= numberOfNodeNumberCells;
       distanceFromCandidateNodeNumberingTuple++)
  {
    if (! stopLookingForSpaceOnLeftSide)
    {
      if (indexOfCandidateNodeNumberingTuple >= distanceFromCandidateNodeNumberingTuple)
      {
        NSUInteger indexOfPrecedingNodeNumberingTuple = indexOfCandidateNodeNumberingTuple - distanceFromCandidateNodeNumberingTuple;

        spaceIsSufficient = [self doesNeighbouringBranchTupleWithIndex:indexOfPrecedingNodeNumberingTuple
                                                               inArray:nodeNumberingTuples
             leaveSufficientSpaceForNodeNumberWithXPositionOfFirstCell:xPositionOfFirstCell
                                                   xPositionOfLastCell:xPositionOfLastCell
                            numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter
                                                   stopLookingForSpace:&stopLookingForSpaceOnLeftSide];
        if (! spaceIsSufficient)
          break;
      }
      else
      {
        stopLookingForSpaceOnLeftSide = true;
      }
    }

    if (! stopLookingForSpaceOnRightSide)
    {
      NSUInteger indexOfSuccedingNodeNumberingTuple = indexOfCandidateNodeNumberingTuple + distanceFromCandidateNodeNumberingTuple;
      if (indexOfSuccedingNodeNumberingTuple < numberOfNodeNumberingTuples)
      {
        NSUInteger indexOfSucceedingNodeNumberingTuple = indexOfCandidateNodeNumberingTuple + distanceFromCandidateNodeNumberingTuple;

        spaceIsSufficient = [self doesNeighbouringBranchTupleWithIndex:indexOfSucceedingNodeNumberingTuple
                                                               inArray:nodeNumberingTuples
             leaveSufficientSpaceForNodeNumberWithXPositionOfFirstCell:xPositionOfFirstCell
                                                   xPositionOfLastCell:xPositionOfLastCell
                            numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter
                                                   stopLookingForSpace:&stopLookingForSpaceOnRightSide];
        if (! spaceIsSufficient)
          break;
      }
      else
      {
        stopLookingForSpaceOnRightSide = true;
      }
    }

    if (stopLookingForSpaceOnLeftSide && stopLookingForSpaceOnRightSide)
      break;
  }

  return spaceIsSufficient;
}

// -----------------------------------------------------------------------------
/// @brief Checks if the branch tuple contained by the node numbering tuple at
/// index position @a indexOfNodeNumberingTuple in @a nodeNumberingTuples leaves
/// sufficient space for a node number that would be rendered in the cells in
/// the x-position range from @a xPositionOfFirstCell to @a xPositionOfLastCell.
///
/// This is a privat helper for the "sufficient space checking" algorithm.
// -----------------------------------------------------------------------------
            - (bool) doesNeighbouringBranchTupleWithIndex:(NSUInteger)indexOfNeighbouringNodeNumberingTuple
                                                  inArray:(NSArray*)nodeNumberingTuples
leaveSufficientSpaceForNodeNumberWithXPositionOfFirstCell:(unsigned short)xPositionOfFirstCell
                                      xPositionOfLastCell:(unsigned short)xPositionOfLastCell
               numberOfNodeNumberCellsExtendingFromCenter:(int)numberOfNodeNumberCellsExtendingFromCenter
                                      stopLookingForSpace:(bool*)stopLookingForSpace
{
  NSArray* neighbouringNodeNumberTuple = [nodeNumberingTuples objectAtIndex:indexOfNeighbouringNodeNumberingTuple];
  NodeTreeViewBranchTuple* neighbouringBranchTuple = neighbouringNodeNumberTuple.firstObject;

  // Calculate the window occupied by the node number of neighbouringBranchTuple
  unsigned short xPositionOfCenterCellNeighbouringBranchTuple = neighbouringBranchTuple->xPositionOfFirstCell + neighbouringBranchTuple->indexOfCenterCell;
  unsigned short xPositionOfFirstCellNeighbouringBranchTuple = xPositionOfCenterCellNeighbouringBranchTuple - numberOfNodeNumberCellsExtendingFromCenter;
  unsigned short xPositionOfLastCellNeighbouringBranchTuple = xPositionOfCenterCellNeighbouringBranchTuple + numberOfNodeNumberCellsExtendingFromCenter;

  bool areNodeNumberWindowsIntersecting = [self areNodeNumberWindowsIntersectingWindow1Start:xPositionOfFirstCell
                                                                                  window1End:xPositionOfLastCell
                                                                                window2Start:xPositionOfFirstCellNeighbouringBranchTuple
                                                                                  window2End:xPositionOfLastCellNeighbouringBranchTuple];
  if (areNodeNumberWindowsIntersecting)
  {
    NSNumber* didNumberNeighbouringBranchTuple = neighbouringNodeNumberTuple.lastObject;
    if (didNumberNeighbouringBranchTuple.boolValue)
      return false;
  }
  else
  {
    *stopLookingForSpace = true;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Returns @e true if the two node number windows defined by the
/// supplied start and end positions intersect. Returns @e false if they do not
/// intersect.
///
/// This is a privat helper for the "sufficient space checking" algorithm.
// -----------------------------------------------------------------------------
- (bool) areNodeNumberWindowsIntersectingWindow1Start:(unsigned short)xPositionOfWindow1Start
                                           window1End:(unsigned short)xPositionOfWindow1End
                                         window2Start:(unsigned short)xPositionOfWindow2Start
                                           window2End:(unsigned short)xPositionOfWindow2End
{
  return ((xPositionOfWindow1Start >= xPositionOfWindow2Start && xPositionOfWindow1Start <= xPositionOfWindow2End) ||
          (xPositionOfWindow1End >= xPositionOfWindow2Start && xPositionOfWindow1End <= xPositionOfWindow2End));
}

// -----------------------------------------------------------------------------
/// @brief Generates NodeNumbersViewCell objects that describe the node number
/// with which to number @a branchTuple. The objects are added to
/// @a nodeNumbersViewCellsDictionary with the appropriate
/// NodeTreeViewCellPosition objects as key.
// -----------------------------------------------------------------------------
 - (void) generateNodeNumberForBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
            nodeNumbersViewCellsDictionary:(NSMutableDictionary*)nodeNumbersViewCellsDictionary
                       isCondensedMoveNode:(bool)isCondensedMoveNode
          nodeNumberExistsOnlyForSelection:(bool)nodeNumberExistsOnlyForSelection
numberOfNodeNumberCellsExtendingFromCenter:(int)numberOfNodeNumberCellsExtendingFromCenter
{
  unsigned short xPositionOfCenterCell = branchTuple->xPositionOfFirstCell + branchTuple->indexOfCenterCell;
  unsigned short xPositionOfFirstCell = xPositionOfCenterCell - numberOfNodeNumberCellsExtendingFromCenter;
  unsigned short xPositionOfLastCell = xPositionOfCenterCell + numberOfNodeNumberCellsExtendingFromCenter;

  for (unsigned short xPositionOfCell = xPositionOfFirstCell; xPositionOfCell <= xPositionOfLastCell; xPositionOfCell++)
  {
    NodeNumbersViewCell* cell = [NodeNumbersViewCell emptyCell];
    cell.nodeNumber = branchTuple->nodeNumber;
    cell.part = xPositionOfCell - xPositionOfFirstCell;
    cell.selected = branchTuple->nodeIsCurrentBoardPositionNode;
    cell.nodeNumberExistsOnlyForSelection = nodeNumberExistsOnlyForSelection;

    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPositionOfCell y:yPositionOfNodeNumber];
    nodeNumbersViewCellsDictionary[position] = cell;
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates a node number for @a selectedNode if none exists yet and
/// there is sufficient space for it.
// -----------------------------------------------------------------------------
- (void) generateNodeNumberForSelectedNodeIfNoneExistsYet:(GoNode*)selectedNode
                                                  nodeMap:(NSDictionary*)nodeMap
                           nodeNumbersViewCellsDictionary:(NSMutableDictionary*)nodeNumbersViewCellsDictionary
                                  numberOfNodeNumberCells:(int)numberOfNodeNumberCells
               numberOfNodeNumberCellsExtendingFromCenter:(int)numberOfNodeNumberCellsExtendingFromCenter
{
  NSValue* key = [NSValue valueWithNonretainedObject:selectedNode];
  NodeTreeViewBranchTuple* branchTuple = [nodeMap objectForKey:key];

  NSMutableArray* positionCellTuples = [NSMutableArray array];

  unsigned short xPositionOfCenterCell = branchTuple->xPositionOfFirstCell + branchTuple->indexOfCenterCell;
  unsigned short xPositionOfFirstCell = xPositionOfCenterCell - numberOfNodeNumberCellsExtendingFromCenter;
  unsigned short xPositionOfLastCell = xPositionOfCenterCell + numberOfNodeNumberCellsExtendingFromCenter;

  for (unsigned short xPositionOfCell = xPositionOfFirstCell; xPositionOfCell <= xPositionOfLastCell; xPositionOfCell++)
  {
    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPositionOfCell y:yPositionOfNodeNumber];
    NodeNumbersViewCell* cell = [nodeNumbersViewCellsDictionary objectForKey:position];
    if (cell)
    {
      // Two scenarios are possible here:
      // - The node number in the cell matches the node number in branchTuple.
      //   In that case someone else has generated the node number cells for us
      //   (including the "selected" property) and we can abort. This scenario
      //   occurs already for the very first cell.
      // - The node number in the cell does not match the node number in
      //   branchTuple. In that case a different node number is occupying the
      //   cell and we can also abort. This scenario can occur in any of the
      //   iterations.
      return;
    }
    else
    {
      NodeNumbersViewCell* cell = [NodeNumbersViewCell emptyCell];
      cell.nodeNumber = branchTuple->nodeNumber;
      cell.part = xPositionOfCell - xPositionOfFirstCell;
      cell.selected = true;
      cell.nodeNumberExistsOnlyForSelection = true;

      // We can't add the cell immediately to nodeNumbersViewCellsDictionary
      // because it may turn out in a later iteration that one of the cells is
      // already occupied by a different node number.
      [positionCellTuples addObject:@[position, cell]];
    }
  }

  // Only now can we be sure that none of the cells is already occupied by a
  // different node number
  assert(positionCellTuples.count == numberOfNodeNumberCells);
  for (NSArray* positionCellTuple in positionCellTuples)
  {
    NodeTreeViewCellPosition* position = positionCellTuple.firstObject;
    NodeNumbersViewCell* cell = positionCellTuple.lastObject;
    nodeNumbersViewCellsDictionary[position] = cell;
  }
}

#pragma mark - Private API - Canvas calculation - Helper methods

// -----------------------------------------------------------------------------
/// @brief Returns the NodeTreeViewCellSymbol enumeration value that represents
/// the node @a node on the canvas.
// --------------------------x---------------------------------------------------
- (enum NodeTreeViewCellSymbol) symbolForNode:(GoNode*)node
{
  GoNodeSetup* nodeSetup = node.goNodeSetup;
  if (nodeSetup)
  {
    bool hasBlackSetupStones = nodeSetup.blackSetupStones;
    bool hasWhiteSetupStones = nodeSetup.whiteSetupStones;
    bool hasNoSetupStones = nodeSetup.noSetupStones;

    if (hasBlackSetupStones)
    {
      if (hasWhiteSetupStones)
      {
        if (hasNoSetupStones)
          return NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones;
        else
          return NodeTreeViewCellSymbolBlackAndWhiteSetupStones;
      }
      else if (hasNoSetupStones)
        return NodeTreeViewCellSymbolBlackAndNoSetupStones;
      else
        return NodeTreeViewCellSymbolBlackSetupStones;
    }
    else if (hasWhiteSetupStones)
    {
      if (hasNoSetupStones)
        return NodeTreeViewCellSymbolWhiteAndNoSetupStones;
      else
        return NodeTreeViewCellSymbolWhiteSetupStones;
    }
    else
    {
      return NodeTreeViewCellSymbolNoSetupStones;
    }
  }
  else if (node.goMove)
  {
    if (node.goMove.player.isBlack)
      return NodeTreeViewCellSymbolBlackMove;
    else
      return NodeTreeViewCellSymbolWhiteMove;
  }
  else if (node.goNodeAnnotation)
  {
    if (node.goNodeMarkup)
      return NodeTreeViewCellSymbolAnnotationsAndMarkup;
    else
      return NodeTreeViewCellSymbolAnnotations;
  }
  else if (node.goNodeMarkup)
  {
    return NodeTreeViewCellSymbolMarkup;
  }
  else if (node.isRoot)
  {
    GoGame* game = [GoGame sharedGame];
    bool hasHandicap = game.handicapPoints.count > 0;
    bool hasKomi = game.komi > 0.0;
    if (hasHandicap && hasKomi)
      return NodeTreeViewCellSymbolHandicapAndKomi;
    else if (hasHandicap)
      return NodeTreeViewCellSymbolHandicap;
    else if (hasKomi)
      return NodeTreeViewCellSymbolKomi;
    else
      return NodeTreeViewCellSymbolRoot;
  }

  return NodeTreeViewCellSymbolEmpty;
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of cells that are needed to represent the node
/// @a node on the canvas.
///
/// If @a condenseMoveNodes is @e false then this method returns 1, i.e. all
/// nodes are represented by a single cell.
///
/// If @a condenseMoveNodes is @e true then this method returns either 1
/// (indicating that the node should be condensed and represented by a single
/// standalone cell), or @a numberOfCellsOfMultipartCell (indicating that the
/// node should be uncondensed and represented by several sub-cells that
/// together form a multipart cell). Which value is returned depends on the
/// content of @a node and/or its position in the tree of nodes. As a summary,
/// only move nodes are condensed, and only those move nodes that do not form
/// the start or end of a sequence of moves.
// --------------------------x---------------------------------------------------
- (unsigned short) numberOfCellsForNode:(GoNode*)node
                      condenseMoveNodes:(bool)condenseMoveNodes
           numberOfCellsOfMultipartCell:(int)numberOfCellsOfMultipartCell
{
  if (! condenseMoveNodes)
    return 1;

  // Root node: Because the root node starts the main variation it is considered
  // a branching node
  if (node.isRoot)
    return numberOfCellsOfMultipartCell;

  // Branching nodes are uncondensed
  if (node.isBranchingNode)
    return numberOfCellsOfMultipartCell;

  // Child nodes of a branching node
  GoNode* parent = node.parent;
  if (parent.isBranchingNode)
    return numberOfCellsOfMultipartCell;

  // Leaf nodes
  if (node.isLeaf)
    return numberOfCellsOfMultipartCell;

  // Nodes with a move => we don't care if they also contain annotations or
  // markup
  // TODO xxx is it correct to not care? e.g. a hotspot should surely be uncodensed? what about annotations/markup in general?
  if (node.goMove)
  {
    // At this point we know the node is neither the root node (i.e. it has a
    // parent) nor a leaf node (i.e. it has a first child), so it is safe to
    // examine the parent and first child content.
    // => Condense the node only if it is sandwiched between two other move
    //    nodes. If either parent or first child don't contain a move then they
    //    will be uncondensed. The move node in this case must also be
    //    uncondensed to indicate the begin or end of a sequence of moves.
    if (parent.goMove && node.firstChild.goMove)
      return 1;
    else
      return numberOfCellsOfMultipartCell;
  }
  // Nodes without a move (including completely empty nodes)
  else
  {
    return numberOfCellsOfMultipartCell;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the child branch of @a branchTuple whose first
/// NodeTreeViewBranchTuple contains a node that is part of the current game
/// variation in GoNodeModel. Returns @e nil if no such child branch exists.
// -----------------------------------------------------------------------------
- (NodeTreeViewBranch*) childBranchInCurrentGameVariation:(NodeTreeViewBranchTuple*)branchTuple
{
  if (! branchTuple->nodeIsInCurrentGameVariation)
    return nil;

  for (NodeTreeViewBranch* childBranch in branchTuple->childBranches)
  {
    NodeTreeViewBranchTuple* firstChildBranchTuple = childBranch->branchTuples.firstObject;
    if (firstChildBranchTuple->nodeIsInCurrentGameVariation)
      return childBranch;
  }

  return nil;
}

#pragma mark - Private API - Other methods

// -----------------------------------------------------------------------------
/// @brief Returns the NodeTreeViewBranchTuple object that corresponds to
/// @a node. Returns @e nil if @a node is @e nil or if no such object exists.
// -----------------------------------------------------------------------------
- (NodeTreeViewBranchTuple*) branchTupleForNode:(GoNode*)node
{
  if (! node)
    return nil;

  NSValue* key = [NSValue valueWithNonretainedObject:node];
  NodeTreeViewBranchTuple* branchTuple = [self.canvasData.nodeMap objectForKey:key];
  return branchTuple;
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of horizontally consecutive NodeTreeViewCellPosition
/// objects that indicate which cells on the node tree view canvas display the
/// node represented by @a branchTuple. The list is empty if @a branchTuple is
/// @e nil, or if no positions exist for @a branchTuple.
// -----------------------------------------------------------------------------
- (NSArray*) positionsForBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
{
  NSMutableArray* positions = [NSMutableArray array];

  if (! branchTuple)
    return positions;

  unsigned short xPositionOfFirstCell = branchTuple->xPositionOfFirstCell;
  unsigned short xPositionOfLastCell = branchTuple->xPositionOfFirstCell + branchTuple->numberOfCellsForNode - 1;
  for (unsigned short xPosition = xPositionOfFirstCell; xPosition <= xPositionOfLastCell; xPosition++)
  {
    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition
                                                                               y:branchTuple->branch->yPosition];
    [positions addObject:position];
  }

  return positions;
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of horizontally consecutive NodeTreeViewCellPosition
/// objects that indicate which cells on the node numbers view canvas display
/// the node number for the node represented by @a branchTuple. The list is
/// empty if @a branchTuple is @e nil, or if no positions exist for
/// @a branchTuple.
// -----------------------------------------------------------------------------
- (NSArray*) nodeNumbersViewPositionsForBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
{
  NSMutableArray* positions = [NSMutableArray array];

  if (! branchTuple)
    return positions;

  int numberOfNodeNumberCellsExtendingFromCenter = [self numberOfNodeNumberCellsExtendingFromCenter];

  unsigned short xPositionOfCenterCell = branchTuple->xPositionOfFirstCell + branchTuple->indexOfCenterCell;
  unsigned short xPositionOfFirstCell = xPositionOfCenterCell - numberOfNodeNumberCellsExtendingFromCenter;
  unsigned short xPositionOfLastCell = xPositionOfCenterCell + numberOfNodeNumberCellsExtendingFromCenter;
  
  for (unsigned short xPositionOfCell = xPositionOfFirstCell; xPositionOfCell <= xPositionOfLastCell; xPositionOfCell++)
  {
    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPositionOfCell y:yPositionOfNodeNumber];
    [positions addObject:position];
  }

  return positions;
}

// -----------------------------------------------------------------------------
/// @brief Updates the @e selected property value of those NodeTreeViewCell and
/// NodeNumbersViewCell objects that display the node @a node on the canvas.
/// Creates or deletes NodeNumbersViewCell objects as necessary. Returns a tuple
/// with two lists of NodeTreeViewCellPosition objects that refer to the
/// positions of the updated cells on the node tree view canvas (first list) and
/// on the node numbers view canvas (second list).
///
/// If @a newSelectedState is false, i.e. @a node is de-selected, the
/// NodeTreeViewCellPosition objects in the second list may refer to cells for
/// which there no longer are any NodeNumbersViewCell objects. This happens if
/// the node number for @a node existed purely to mark @a node as selected.
// -----------------------------------------------------------------------------
- (NSArray*) updateSelectedStateOfCellsForNode:(GoNode*)node
                                    toNewState:(bool)newSelectedState
                                       nodeMap:(NSDictionary*)nodeMap
                               cellsDictionary:(NSDictionary*)cellsDictionary
                nodeNumbersViewCellsDictionary:(NSMutableDictionary*)nodeNumbersViewCellsDictionary
{
  NodeTreeViewBranchTuple* branchTuple = [self branchTupleForNode:node];
  branchTuple->nodeIsCurrentBoardPositionNode = newSelectedState;

  NSArray* positions = [self positionsForBranchTuple:branchTuple];
  for (NodeTreeViewCellPosition* position in positions)
  {
    NSArray* tuple = [cellsDictionary objectForKey:position];
    if (tuple)
    {
      NodeTreeViewCell* cell = tuple.firstObject;
      cell.selected = newSelectedState;
    }
  }

  int numberOfNodeNumberCells = [self numberOfNodeNumberCells];
  int numberOfNodeNumberCellsExtendingFromCenter = [self numberOfNodeNumberCellsExtendingFromCenter];

  NSArray* nodeNumbersViewPositions = [self nodeNumbersViewPositionsForBranchTuple:branchTuple];
  for (NodeTreeViewCellPosition* position in nodeNumbersViewPositions)
  {
    NodeNumbersViewCell* cell = [nodeNumbersViewCellsDictionary objectForKey:position];
    if (cell)
    {
      // If the node number does not match then some other node number is
      // occupying the cell and we can abort immediately
      if (cell.nodeNumber != branchTuple->nodeNumber)
        break;

      cell.selected = newSelectedState;

      // If the node is de-selected and the node number cell exists only for
      // marking the selected node, then the cell can be deleted
      if (! newSelectedState && cell.nodeNumberExistsOnlyForSelection)
        [nodeNumbersViewCellsDictionary removeObjectForKey:position];
    }
    else
    {
      // If the node is selected but is not yet numbered, we now generate the
      // node numbers for it. If the node is de-selected but is not yet numbered
      // this is unexpected.
      if (newSelectedState)
      {
        [self generateNodeNumberForSelectedNodeIfNoneExistsYet:node
                                                       nodeMap:nodeMap
                                nodeNumbersViewCellsDictionary:nodeNumbersViewCellsDictionary
                                       numberOfNodeNumberCells:numberOfNodeNumberCells
                    numberOfNodeNumberCellsExtendingFromCenter:numberOfNodeNumberCellsExtendingFromCenter];
        // All cells were generated, no further need to iterate
        break;
      }
    }
  }

  return @[positions, nodeNumbersViewPositions];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the cached value returned by selectedNodePositions().
// -----------------------------------------------------------------------------
- (void) invalidateCachedSelectedNodePositions
{
  self.cachedSelectedNodePositions = nil;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the cached value returned by
/// selectedNodeNodeNumbersViewPositions().
// -----------------------------------------------------------------------------
- (void) invalidateCachedSelectedNodeNodeNumbersViewPositions
{
  self.cachedSelectedNodeNodeNumbersViewPositions = nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of cells that a node number occupies on the node
/// numbers view view.
// -----------------------------------------------------------------------------
- (int) numberOfNodeNumberCells
{
  if (self.nodeTreeViewModel.condenseMoveNodes)
    return self.nodeTreeViewModel.numberOfCellsOfMultipartCell;
  else
    return 1;
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of cells extending from the center cell of a
/// node number window. The width of the node number window is defined by the
/// return value of the numberOfNodeNumberCells() method.
// -----------------------------------------------------------------------------
- (int) numberOfNodeNumberCellsExtendingFromCenter
{
  int numberOfNodeNumberCells = [self numberOfNodeNumberCells];
  return (numberOfNodeNumberCells - 1) / 2;
}

@end

#pragma mark - Implementation of NodeTreeViewCanvasAdditions

@implementation NodeTreeViewCanvas(NodeTreeViewCanvasAdditions)

#pragma mark - NodeTreeViewCanvasAdditions - Unit testing

// -----------------------------------------------------------------------------
/// @brief Returns the dictionary with the results of the canvas re-calculation.
// -----------------------------------------------------------------------------
- (NSDictionary*) getCellsDictionary
{
  return self.canvasData.cellsDictionary;
}

@end
