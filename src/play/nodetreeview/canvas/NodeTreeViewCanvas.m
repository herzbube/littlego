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
#import "NodeTreeViewCanvasAdditions.h"
#import "NodeTreeViewBranch.h"
#import "NodeTreeViewBranchTuple.h"
#import "NodeTreeViewCell.h"
#import "NodeTreeViewCellPosition.h"
#import "../../model/NodeTreeViewModel.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoMove.h"
#import "../../../go/GoNode.h"
#import "../../../go/GoNodeModel.h"
#import "../../../go/GoNodeSetup.h"
#import "../../../go/GoPlayer.h"
#import "../../../shared/LongRunningActionCounter.h"


/// @brief Collects information about branches and nodes that make up those
/// branches.
struct CollectBranchDataResult
{
  /// @brief Maps GoNode objects to NodeTreeViewBranchTuple objects.
  ///
  /// The dictionary key is an NSValue object that enapsulates a GoNode object
  /// (because GoNode does not support being used directly as a dictionary key).
  /// The GoNode is a branching node, i.e. a node that has multiple child nodes,
  /// each of which is the start of a new branch.
  ///
  /// The dictionary value is the NodeTreeViewBranchTuple object that represents
  /// the GoNode.
  NSMutableDictionary* branchingNodeMap;
  /// @brief Stores branches in depth-first order. Elements are
  /// NodeTreeViewBranch objects.
  NSMutableArray* branches;
  /// @brief Index position = Move number - 1 (e.g. first move is at index
  /// position 0). Element at index position = List of NodeTreeViewBranchTuple
  /// objects, each of which represents a node in a different branch that
  /// refers to a move with the same move number.
  NSMutableArray* branchTuplesForMoveNumbers;
  int highestMoveNumberThatAppearsInAtLeastTwoBranches;
};

/// @brief Collects the multiple pieces of information that form the result of
/// generating cells at the end of the canvas calculation process.
struct GenerateCellsResult
{
  NSMutableDictionary* cellsDictionary;
  unsigned short highestXPosition;
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewCanvas.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCanvas()
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
@property(nonatomic, assign) bool canvasNeedsUpdate;
@property(nonatomic, retain) NSMutableDictionary* cellsDictionary;
@end


@implementation NodeTreeViewCanvas

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewCanvas object with a canvas of size zero.
///
/// @note This is the designated initializer of NodeTreeViewCanvas.
// -----------------------------------------------------------------------------
- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel;
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.nodeTreeViewModel = nodeTreeViewModel;

  self.canvasNeedsUpdate = false;
  self.canvasSize = CGSizeZero;
  self.cellsDictionary = [NSMutableDictionary dictionary];

  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewCanvas object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  self.nodeTreeViewModel = nil;
  self.cellsDictionary = nil;

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
  [center addObserver:self selector:@selector(nodeTreeLayoutDidChange:) name:nodeTreeLayoutDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];

  [self.nodeTreeViewModel addObserver:self forKeyPath:@"condenseMoveNodes" options:0 context:NULL];
  [self.nodeTreeViewModel addObserver:self forKeyPath:@"alignMoveNodes" options:0 context:NULL];
  [self.nodeTreeViewModel addObserver:self forKeyPath:@"branchingStyle" options:0 context:NULL];
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
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  self.canvasNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeLayoutDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeLayoutDidChange:(NSNotification*)notification
{
  self.canvasNeedsUpdate = true;
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
    [self delayedUpdate];
  }
  else if ([keyPath isEqualToString:@"alignMoveNodes"])
  {
    self.canvasNeedsUpdate = true;
    [self delayedUpdate];
  }
  else if ([keyPath isEqualToString:@"branchingStyle"])
  {
    self.canvasNeedsUpdate = true;
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
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
// -----------------------------------------------------------------------------
- (void) updateCanvas
{
  if (! self.canvasNeedsUpdate)
    return;
  self.canvasNeedsUpdate = false;

  [self recalculateCanvas];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Returns the NodeTreeViewCell object that is located at position
/// @a position on the canvas. Returns @e nil if @a position denotes a position
/// that is outside the canvas' bounds.
// -----------------------------------------------------------------------------
- (NodeTreeViewCell*) cellAtPosition:(NodeTreeViewCellPosition*)position;
{
  NodeTreeViewCell* cell = [self.cellsDictionary objectForKey:position];
  if (cell)
    return cell;

  if (position.x < self.canvasSize.width && position.y < self.canvasSize.height)
    return [NodeTreeViewCell emptyCell];
  else
    return nil;
}

#pragma mark - Public API - Canvas calculation - Main method

// -----------------------------------------------------------------------------
/// @brief Performs a full re-calculation of the node tree view canvas.
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
- (void) recalculateCanvas
{
  GoNodeModel* nodeModel = [GoGame sharedGame].nodeModel;

  bool condenseMoveNodes = self.nodeTreeViewModel.condenseMoveNodes;
  bool alignMoveNodes = self.nodeTreeViewModel.alignMoveNodes;
  enum NodeTreeViewBranchingStyle branchingStyle = self.nodeTreeViewModel.branchingStyle;
  int numberOfCellsOfMultipartCell = self.nodeTreeViewModel.numberOfCellsOfMultipartCell;

  // Step 1: Collect data about branches
  struct CollectBranchDataResult collectBranchDataResult = [self collectBranchDataFromNodeTreeInModel:nodeModel
                                                                                    condenseMoveNodes:condenseMoveNodes
                                                                         numberOfCellsOfMultipartCell:numberOfCellsOfMultipartCell
                                                                                       alignMoveNodes:alignMoveNodes];

  // Step 2: Align moves nodes
  if (alignMoveNodes)
  {
    [self alignMoveNodes:collectBranchDataResult];
  }

  // Step 3: Determine y-coordinates of branches
  unsigned short highestYPosition = [self determineYCoordinatesOfBranches:collectBranchDataResult
                                                           branchingStyle:branchingStyle];

  // Step 4: Generate cells
  struct GenerateCellsResult generateCellsResult = [self generateCells:collectBranchDataResult
                                                      highestYPosition:highestYPosition
                                                        branchingStyle:branchingStyle];

  self.cellsDictionary = generateCellsResult.cellsDictionary;
  self.canvasSize = CGSizeMake(generateCellsResult.highestXPosition + 1, highestYPosition + 1);

  // TODO xxx Currently each and every change causes a full redraw => optimize
  [[NSNotificationCenter defaultCenter] postNotificationName:nodeTreeViewContentDidChange object:nil];
}

#pragma mark - Private API - Canvas calculation - Part 1: Collect branch data

// -----------------------------------------------------------------------------
/// @brief Iterates depth-first over the tree of nodes provided by GoNodeModel
/// to collect information about branches.
// -----------------------------------------------------------------------------
- (struct CollectBranchDataResult) collectBranchDataFromNodeTreeInModel:(GoNodeModel*)nodeModel
                                                      condenseMoveNodes:(bool)condenseMoveNodes
                                           numberOfCellsOfMultipartCell:(int)numberOfCellsOfMultipartCell
                                                         alignMoveNodes:(bool)alignMoveNodes
{
  struct CollectBranchDataResult collectBranchDataResult;
  collectBranchDataResult.highestMoveNumberThatAppearsInAtLeastTwoBranches = -1;
  collectBranchDataResult.branchTuplesForMoveNumbers = [NSMutableArray array];
  collectBranchDataResult.branchingNodeMap = [NSMutableDictionary dictionary];
  collectBranchDataResult.branches = [NSMutableArray array];

  NSMutableArray* stack = [NSMutableArray array];

  GoNode* currentNode = nodeModel.rootNode;

  // If a new branch is created, this must be used as the new branch's parent
  // branch
  NodeTreeViewBranch* parentBranch = nil;
  unsigned short xPosition = 0;

  while (true)
  {
    NodeTreeViewBranch* branch = nil;
    NSUInteger indexOfBranch = -1;

    while (currentNode)
    {
      if (! branch)
      {
        branch = [self createBranchWithParentBranch:parentBranch
                                  firstNodeOfBranch:currentNode
                                   branchingNodeMap:collectBranchDataResult.branchingNodeMap];

        [collectBranchDataResult.branches addObject:branch];
        indexOfBranch = collectBranchDataResult.branches.count - 1;
      }

      NodeTreeViewBranchTuple* branchTuple = [[[NodeTreeViewBranchTuple alloc] init] autorelease];
      branchTuple->xPositionOfFirstCell = xPosition;
      branchTuple->node = currentNode;
      branchTuple->symbol = [self symbolForNode:currentNode];
      branchTuple->numberOfCellsForNode = [self numberOfCellsForNode:currentNode condenseMoveNodes:condenseMoveNodes numberOfCellsOfMultipartCell:numberOfCellsOfMultipartCell];
      // This assumes that numberOfCellsForNode is always an uneven number
      branchTuple->indexOfCenterCell = floorf(branchTuple->numberOfCellsForNode / 2.0);
      branchTuple->branch = branch;
      branchTuple->childBranches = nil;

      [branch->branchTuples addObject:branchTuple];

      if (currentNode.isBranchingNode)
      {
        NSValue* key = [NSValue valueWithNonretainedObject:currentNode];
        collectBranchDataResult.branchingNodeMap[key] = branchTuple;
      }

      xPosition += branchTuple->numberOfCellsForNode;

      if (alignMoveNodes)
      {
        GoMove* move = currentNode.goMove;
        if (move)
          [self collectDataFromMove:move branch:branch branchTuple:branchTuple collectBranchDataResult:&collectBranchDataResult];
      }

      [stack addObject:branchTuple];

      currentNode = currentNode.firstChild;
    }

    if (stack.count > 0)
    {
      NodeTreeViewBranchTuple* branchTuple = stack.lastObject;
      [stack removeLastObject];

      currentNode = branchTuple->node;
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

  return collectBranchDataResult;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new NodeTreeViewBranch object when the first node of a
/// branch (@a firstNodeOfBranch) is encountered. Performs all the necessary
/// linkage of the new branch with its sibling and parent branches.
// -----------------------------------------------------------------------------
- (NodeTreeViewBranch*) createBranchWithParentBranch:(NodeTreeViewBranch*)parentBranch
                                   firstNodeOfBranch:(GoNode*)firstNodeOfBranch
                                    branchingNodeMap:(NSMutableDictionary*)branchingNodeMap
{
  NodeTreeViewBranch* branch = [[[NodeTreeViewBranch alloc] init] autorelease];

  branch->branchTuples = [NSMutableArray array];
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
          branchingNodeMap:branchingNodeMap];

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
           branchingNodeMap:(NSMutableDictionary*)branchingNodeMap
{
  NSValue* key = [NSValue valueWithNonretainedObject:branchingNode];
  NodeTreeViewBranchTuple* branchingNodeTuple = [branchingNodeMap objectForKey:key];

  newChildBranch->parentBranchTupleBranchingNode = branchingNodeTuple;

  if (! branchingNodeTuple->childBranches)
    branchingNodeTuple->childBranches = [NSMutableArray array];

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
     collectBranchDataResult:(struct CollectBranchDataResult*)collectBranchDataResult
{
  NSMutableArray* branchTuplesForMoveNumber;

  int moveNumber = move.moveNumber;
  if (moveNumber > collectBranchDataResult->branchTuplesForMoveNumbers.count)
  {
    branchTuplesForMoveNumber = [NSMutableArray array];
    [collectBranchDataResult->branchTuplesForMoveNumbers addObject:branchTuplesForMoveNumber];
  }
  else
  {
    branchTuplesForMoveNumber = [collectBranchDataResult->branchTuplesForMoveNumbers objectAtIndex:moveNumber - 1];
  }

  [branchTuplesForMoveNumber addObject:branchTuple];

  if (branchTuplesForMoveNumber.count > 1)
  {
    if (moveNumber > collectBranchDataResult->highestMoveNumberThatAppearsInAtLeastTwoBranches)
      collectBranchDataResult->highestMoveNumberThatAppearsInAtLeastTwoBranches = moveNumber;
  }
}

#pragma mark - Private API - Canvas calculation - Part 2: Align move nodes

// -----------------------------------------------------------------------------
/// @brief Iterates over all moves that are present in
/// @a collectBranchDataResult and aligns the x-position of the first cell that
/// represents the node of each move. In case of multipart cells, the alignment
/// is made along the center cell.
// -----------------------------------------------------------------------------
- (void) alignMoveNodes:(struct CollectBranchDataResult)collectBranchDataResult
{
  // Optimization: We only have to align moves that appear in at least two
  // branches.
  for (int indexOfMove = 0;
       indexOfMove < collectBranchDataResult.highestMoveNumberThatAppearsInAtLeastTwoBranches;
       indexOfMove++)
  {
    NSMutableArray* branchTuplesForMoveNumber = [collectBranchDataResult.branchTuplesForMoveNumbers objectAtIndex:indexOfMove];

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

    if (branchTupleToShift->childBranches)
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
/// @brief Iterates over the branches that are present in
/// @a collectBranchDataResult and determines the y-position of each branch.
/// Returns the highest y-position found.
// -----------------------------------------------------------------------------
- (unsigned short) determineYCoordinatesOfBranches:(struct CollectBranchDataResult)collectBranchDataResult
                                    branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  // In the worst case each branch is on its own y-position => create the array
  // to cater for this worst case
  NSUInteger numberOfBranches = collectBranchDataResult.branches.count;
  unsigned short lowestOccupiedXPositionOfRow[numberOfBranches];
  for (NSUInteger indexOfBranch = 0; indexOfBranch < numberOfBranches; indexOfBranch++)
    lowestOccupiedXPositionOfRow[indexOfBranch] = -1;

  unsigned short highestYPosition = 0;

  NSMutableArray* stack = [NSMutableArray array];

  NodeTreeViewBranch* currentBranch = collectBranchDataResult.branches.firstObject;

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

  return highestYPosition;
}

// -----------------------------------------------------------------------------
/// @brief Determines the y-position of @a branch.
// -----------------------------------------------------------------------------
- (void) determineYCoordinateOfBranch:(NodeTreeViewBranch*)branch
         lowestOccupiedXPositionOfRow:(unsigned short*)lowestOccupiedXPositionOfRow
                       branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
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
    yPosition++;

  branch->yPosition = yPosition;

  unsigned short lowestXPositionOfBranch;
  if (branch->parentBranch)
  {
    lowestXPositionOfBranch = branch->parentBranchTupleBranchingNode->xPositionOfFirstCell;

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
      //   lowestXPositionOfBranch += currentBranch->parentBranchTupleBranchingNode->numberOfCellsForNode;
      // However since a diagonal line crosses only a single sub-cell, and
      // there are no sub-cells in y-direction, diagonal branching can only
      // ever gain space that is worth 1 sub-cell. As a result, when move nodes
      // are condensed (which means that a multipart cell's number of
      // sub-cells is >1) the space gain from diagonal branching is never
      // sufficient to fit a branch on an y-position where it would not have
      // fit with right-angle branching.
      lowestXPositionOfBranch += 1;
    }
  }
  else
  {
    lowestXPositionOfBranch = 0;
  }

  lowestOccupiedXPositionOfRow[yPosition] = lowestXPositionOfBranch;
}

#pragma mark - Private API - Canvas calculation - Part 4: Generate cells

// -----------------------------------------------------------------------------
/// @brief Iterates over all branches and nodes that are present in
/// @a collectBranchDataResult and generates cells to represent the nodes on
/// the canvas.
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
- (struct GenerateCellsResult) generateCells:(struct CollectBranchDataResult)collectBranchDataResult
                            highestYPosition:(unsigned short)highestYPosition
                              branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  struct GenerateCellsResult generateCellsResult;
  generateCellsResult.highestXPosition = 0;
  generateCellsResult.cellsDictionary = [NSMutableDictionary dictionary];

  for (NodeTreeViewBranch* branch in collectBranchDataResult.branches)
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
             generateCellsResult:&generateCellsResult];
  }

  return generateCellsResult;
}

// -----------------------------------------------------------------------------
/// @brief Generates the cells for the entire branch @a branch.
// -----------------------------------------------------------------------------
- (void) generateCellsForBranch:(NodeTreeViewBranch*)branch
xPositionAfterLastCellInBranchingTuple:(unsigned short)xPositionAfterLastCellInBranchingTuple
                 branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
            generateCellsResult:(struct GenerateCellsResult*)generateCellsResult
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
                                                           branchingStyle:branchingStyle
                                                      generateCellsResult:generateCellsResult];
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates the cells for the node represented by @a branchTuple. This
/// includes line-only cells on the left and below the node, connecting the node
/// to its predecessor and successor nodes.
///
/// Line-only cells contain either horizontal lines to connect a node to its predecessor node in the same branch,
/// diagonal and/or horizontal lines to connect a node to its predecessor
/// branching node in the parent branch, or an assortment of vertical, diagonal
/// and/or horizontal lines to connect a branching node to its successor nodes
/// in child branches.
// -----------------------------------------------------------------------------
- (unsigned short) generateCellsForBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
             xPositionAfterPreviousBranchTuple:(unsigned short)xPositionAfterPreviousBranchTuple
                             yPositionOfBranch:(unsigned short)yPositionOfBranch
                      firstBranchTupleOfBranch:(NodeTreeViewBranchTuple*)firstBranchTupleOfBranch
                       lastBranchTupleOfBranch:(NodeTreeViewBranchTuple*)lastBranchTupleOfBranch
                                branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                           generateCellsResult:(struct GenerateCellsResult*)generateCellsResult
{
  bool diagonalConnectionToBranchingLineEstablished = [self generateCellsLeftOfBranchTuple:branchTuple
                                                         xPositionAfterPreviousBranchTuple:xPositionAfterPreviousBranchTuple
                                                                         yPositionOfBranch:yPositionOfBranch
                                                                  firstBranchTupleOfBranch:firstBranchTupleOfBranch
                                                                            branchingStyle:branchingStyle
                                                                       generateCellsResult:generateCellsResult];

  if (branchTuple->childBranches)
  {
    [self generateCellsBelowBranchTuple:branchTuple
                      yPositionOfBranch:yPositionOfBranch
                         branchingStyle:branchingStyle
                    generateCellsResult:generateCellsResult];
  }

  [self generateCellsForBranchTuple:branchTuple
                  yPositionOfBranch:yPositionOfBranch
           firstBranchTupleOfBranch:firstBranchTupleOfBranch
            lastBranchTupleOfBranch:(NodeTreeViewBranchTuple*)lastBranchTupleOfBranch
diagonalConnectionToBranchingLineEstablished:diagonalConnectionToBranchingLineEstablished
                     branchingStyle:branchingStyle
                generateCellsResult:generateCellsResult];

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
                    generateCellsResult:(struct GenerateCellsResult*)generateCellsResult
{
  bool diagonalConnectionToBranchingLineEstablished = false;

  // Part 1: Generate cells with lines that connect the node to either its
  // predecessor node in the same branch (only if alignMoveNodes is true),
  // or to a branching line that reaches out from the cell with the
  // branching node (only if condenseMoveNodes is true)
  for (unsigned short xPositionOfCell = xPositionAfterPreviousBranchTuple; xPositionOfCell < branchTuple->xPositionOfFirstCell; xPositionOfCell++)
  {
    NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
    if (branchingStyle == NodeTreeViewBranchingStyleDiagonal && branchTuple == firstBranchTupleOfBranch && xPositionOfCell == xPositionAfterPreviousBranchTuple)
    {
      diagonalConnectionToBranchingLineEstablished = true;
      cell.lines = NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight;  // connect to branching line
    }
    else
    {
      cell.lines = NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight;
    }

    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPositionOfCell y:yPositionOfBranch];
    generateCellsResult->cellsDictionary[position] = cell;
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
// -----------------------------------------------------------------------------
- (void) generateCellsBelowBranchTuple:(NodeTreeViewBranchTuple*)branchTuple
                     yPositionOfBranch:(unsigned short)yPositionOfBranch
                        branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                   generateCellsResult:(struct GenerateCellsResult*)generateCellsResult
{
  // Part 2: If it's a branching node then generate cells below the
  // branching node that contain the branching lines needed to connect the
  // branching node to its child nodes. The following schematic depicts what
  // kind of lines need to be generated for each branching style when
  // condenseMoveNodes is enabled, i.e. when multipart cells are involved.
  // "N" marks the center cells of multipart cells that represent a node.
  // "o" marks branching line junctions.
  //
  // NodeTreeViewBranchingStyleDiagonal     NodeTreeViewBranchingStyleRightAngle
  //
  //     0    1    2    3    4    5           0    1    2    3    4    5
  //   +---++---++---+                      +---++---++---+
  //   |   ||   ||   |                      |   ||   ||   |
  // 0 |   || N ||   |                      |   || N ||   |
  //   |   || |\||   |                      |   || | ||   |
  //   +---++-|-++---+                      +---++-|-++---+
  //   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
  //   |   || | ||\  ||   ||   ||   |       |   || | ||   ||   ||   ||   |
  // 1 |   || o || o---------N ||   |       |   || o--------------N ||   |
  //   |   || |\||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
  //   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
  //   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
  //   |   || | ||\  ||   ||   ||   |       |   || | ||   ||   ||   ||   |
  // 2 |   || | || o---------N ||   |       |   || o--------------N ||   |
  //   |   || | ||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
  //   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
  //   +---++-|-++---++---++---++---+       +---++-|-++---++---++---++---+
  //   |   || | ||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
  // 3 |   || o ||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
  //   |   ||  \||   ||   ||   ||   |       |   || | ||   ||   ||   ||   |
  //   +---++---++---++---++---++---+       +---++-|-++---++---++---++---+
  //   +---++---++---++---++---++---+       +---++-|-++---++---++---++---+
  //   |   ||   ||\  ||   ||   ||   |       |   || | ||   ||   ||   ||   |
  // 4 |   ||   || o---------N ||   |       |   || o--------------N ||   |
  //   |   ||   ||   ||   ||   ||   |       |   ||   ||   ||   ||   ||   |
  //   +---++---++---++---++---++---+       +---++---++---++---++---++---+
  //
  // Cells to be generated on each y-position:
  // - y=0: 1/0, 2/0                             1/0, 2/0
  // - y=1  1/1, 2/1                             1/1, 2/1
  // - y=2  1/2                                  1/2
  // - y=3  2/3                                  1/4, 2/4

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
      nextChildBranchToDiagonallyConnect = [branchTuple->childBranches objectAtIndex:1];
    }
  }

  unsigned int xPositionOfVerticalLineCell = branchTuple->xPositionOfFirstCell + branchTuple->indexOfCenterCell;

  for (unsigned short yPosition = yPositionBelowBranchingNode; yPosition <= yPositionOfLastChildBranch; yPosition++)
  {
    [self generateCellsBelowBranchTuple:branchTuple
                            atYPosition:yPosition
             yPositionOfLastChildBranch:yPositionOfLastChildBranch
            xPositionOfVerticalLineCell:xPositionOfVerticalLineCell
   nextChildBranchToHorizontallyConnect:nextChildBranchToHorizontallyConnect
     nextChildBranchToDiagonallyConnect:nextChildBranchToDiagonallyConnect
                         branchingStyle:branchingStyle
                    generateCellsResult:generateCellsResult];

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
            yPositionOfLastChildBranch:(unsigned short)yPositionOfLastChildBranch
           xPositionOfVerticalLineCell:(unsigned short)xPositionOfVerticalLineCell
  nextChildBranchToHorizontallyConnect:(NodeTreeViewBranch*)nextChildBranchToHorizontallyConnect
    nextChildBranchToDiagonallyConnect:(NodeTreeViewBranch*)nextChildBranchToDiagonallyConnect
                        branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                   generateCellsResult:(struct GenerateCellsResult*)generateCellsResult
{
  [self generateVerticalLineCellWithXPosition:xPositionOfVerticalLineCell
                                    yPosition:yPosition
                   yPositionOfLastChildBranch:yPositionOfLastChildBranch
         nextChildBranchToHorizontallyConnect:nextChildBranchToHorizontallyConnect
           nextChildBranchToDiagonallyConnect:nextChildBranchToDiagonallyConnect
                               branchingStyle:branchingStyle
                          generateCellsResult:generateCellsResult];

  // If the branching node occupies more than one cell then we need to
  // create additional cells if there is a branch on the y-position
  // that needs a horizontal connection
  if (branchTuple->numberOfCellsForNode > 1 && yPosition == nextChildBranchToHorizontallyConnect->yPosition)
  {
    [self generateCellsRightOfVerticalLineCell:branchTuple
                                   atYPosition:yPosition
                   xPositionOfVerticalLineCell:xPositionOfVerticalLineCell
                                branchingStyle:branchingStyle
                           generateCellsResult:generateCellsResult];
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates a single vertical branching line cell below the branching
/// node represented by @a branchTuple. The cell is located at the specific
/// y-position @a yPosition.
// -----------------------------------------------------------------------------
- (void) generateVerticalLineCellWithXPosition:(unsigned short)xPosition
                                     yPosition:(unsigned short)yPosition
                    yPositionOfLastChildBranch:(unsigned short)yPositionOfLastChildBranch
          nextChildBranchToHorizontallyConnect:(NodeTreeViewBranch*)nextChildBranchToHorizontallyConnect
            nextChildBranchToDiagonallyConnect:(NodeTreeViewBranch*)nextChildBranchToDiagonallyConnect
                                branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                           generateCellsResult:(struct GenerateCellsResult*)generateCellsResult
{
  NodeTreeViewCellLines lines = NodeTreeViewCellLineNone;

  if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
  {
    if (yPosition < yPositionOfLastChildBranch)
    {
      lines |= NodeTreeViewCellLineCenterToTop;

      if (nextChildBranchToDiagonallyConnect && yPosition + 1 == nextChildBranchToDiagonallyConnect->yPosition)
        lines |= NodeTreeViewCellLineCenterToBottomRight;

      if (yPosition + 1 < yPositionOfLastChildBranch)
        lines |= NodeTreeViewCellLineCenterToBottom;
    }
  }
  else
  {
    lines |= NodeTreeViewCellLineCenterToTop;

    if (yPosition == nextChildBranchToHorizontallyConnect->yPosition)
      lines |= NodeTreeViewCellLineCenterToRight;

    if (yPosition < yPositionOfLastChildBranch)
      lines |= NodeTreeViewCellLineCenterToBottom;
  }

  // For diagonal branching style, no cell needs to be generated on the
  // last y-position
  if (lines != NodeTreeViewCellLineNone)
  {
    NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
    cell.lines = lines;

    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition y:yPosition];
    generateCellsResult->cellsDictionary[position] = cell;
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
                               branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
                          generateCellsResult:(struct GenerateCellsResult*)generateCellsResult
{
  NodeTreeViewCellLines linesOfFirstCell;
  if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
    linesOfFirstCell = NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight;
  else
    linesOfFirstCell = NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight;

  unsigned short xPositionOfLastCell = branchTuple->xPositionOfFirstCell + branchTuple->numberOfCellsForNode - 1;
  for (unsigned short xPosition = xPositionOfVerticalLineCell + 1; xPosition <= xPositionOfLastCell; xPosition++)
  {
    NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
    if (xPosition == xPositionOfVerticalLineCell + 1)
      cell.lines = linesOfFirstCell;
    else
      cell.lines = NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight;

    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition y:yPosition];
    generateCellsResult->cellsDictionary[position] = cell;
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
                 generateCellsResult:(struct GenerateCellsResult*)generateCellsResult
{
  for (unsigned int indexOfCell = 0; indexOfCell < branchTuple->numberOfCellsForNode; indexOfCell++)
  {
    NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
    cell.part = indexOfCell;
    cell.parts = branchTuple->numberOfCellsForNode;

    cell.symbol = branchTuple->symbol;
    cell.lines = [self linesForCell:indexOfCell
                        branchTuple:branchTuple
                  yPositionOfBranch:yPositionOfBranch
           firstBranchTupleOfBranch:firstBranchTupleOfBranch
            lastBranchTupleOfBranch:lastBranchTupleOfBranch
diagonalConnectionToBranchingLineEstablished:diagonalConnectionToBranchingLineEstablished
                     branchingStyle:branchingStyle];


    unsigned short xPosition = branchTuple->xPositionOfFirstCell + indexOfCell;
    NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition y:yPositionOfBranch];
    generateCellsResult->cellsDictionary[position] = cell;

    if (xPosition > generateCellsResult->highestXPosition)
      generateCellsResult->highestXPosition = xPosition;
  }
}

// -----------------------------------------------------------------------------
/// @brief Calculates the lines for the cell identified by @a indexOfCell which
/// wholly or partially (in the case of multipart cells) depicts the node
/// represented by @a branchTuple on the canvas.
// -----------------------------------------------------------------------------
- (NodeTreeViewCellLines) linesForCell:(unsigned int)indexOfCell
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

  NodeTreeViewCellLines lines = NodeTreeViewCellLineNone;

  // Horizontal connecting lines to previous node in the same branch,
  // or horizontal/diagonal connecting lines to branching node in parent
  // branch
  if (isCellBeforeOrIncludingCenter)
  {
    lines |= [self linesForCellBeforeOrIncludingCenter:indexOfCell
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
    lines |= [self linesForCellAfterOrIncludingCenter:indexOfCell
                                  isCenterCellForNode:isCenterCellForNode
                                          branchTuple:branchTuple
                              lastBranchTupleOfBranch:lastBranchTupleOfBranch];
  }

  // Vertical and/or diagonal connecting lines to child branches
  if (isCenterCellForNode && branchTuple->childBranches)
  {
    lines |= [self linesForCenterCellConnectingChildBranches:branchTuple
                                              branchingStyle:branchingStyle];
  }

  return lines;
}

// -----------------------------------------------------------------------------
/// @brief Calculates the lines for the cell identified by @a indexOfCell which
/// wholly or partially (in the case of multipart cells) depicts the node
/// represented by @a branchTuple on the canvas. The cell is left of the center
/// of the whole node, or the center cell itself.
// -----------------------------------------------------------------------------
- (NodeTreeViewCellLines) linesForCellBeforeOrIncludingCenter:(unsigned int)indexOfCell
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
        // in a standalone cell somewhere on the left, before the first
        // sub-cell of the multipart cell); and 3) if a diagonal
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

  return lines;
}

// -----------------------------------------------------------------------------
/// @brief Calculates the lines for the cell identified by @a indexOfCell which
/// wholly or partially (in the case of multipart cells) depicts the node
/// represented by @a branchTuple on the canvas. The cell is right of the center
/// of the whole node, or the center cell itself.
// -----------------------------------------------------------------------------
- (NodeTreeViewCellLines) linesForCellAfterOrIncludingCenter:(unsigned int)indexOfCell
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

  return lines;
}

// -----------------------------------------------------------------------------
/// @brief Calculates the lines for the center cell which wholly or partially
/// (in the case of multipart cells) depicts the node represented by
/// @a branchTuple on the canvas. The lines form the start of the vertical
/// branching line that connect the node (which is a branching node) to its
/// child nodes.
// --------------------------x---------------------------------------------------
- (NodeTreeViewCellLines) linesForCenterCellConnectingChildBranches:(NodeTreeViewBranchTuple*)branchTuple
                                                     branchingStyle:(enum NodeTreeViewBranchingStyle)branchingStyle
{
  NodeTreeViewCellLines lines = NodeTreeViewCellLineNone;

  if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
  {
    NodeTreeViewBranch* firstChildBranch = branchTuple->childBranches.firstObject;
    if (branchTuple->branch->yPosition + 1 == firstChildBranch->yPosition)
      lines |= NodeTreeViewCellLineCenterToBottomRight;
    else
      lines |= NodeTreeViewCellLineCenterToBottom;

    if (branchTuple->childBranches.count > 1)
      lines |= NodeTreeViewCellLineCenterToBottom;
  }
  else
  {
    lines |= NodeTreeViewCellLineCenterToBottom;
  }

  return lines;
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

@end

#pragma mark - Implementation of NodeTreeViewCanvasAdditions

@implementation NodeTreeViewCanvas(NodeTreeViewCanvasAdditions)

#pragma mark - NodeTreeViewCanvasAdditions - Unit testing

// -----------------------------------------------------------------------------
/// @brief Returns the dictionary with the results of the canvas re-calculation.
// -----------------------------------------------------------------------------
- (NSDictionary*) getCellsDictionary
{
  return [[_cellsDictionary retain] autorelease];
}

@end
