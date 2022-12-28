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
#import "NodeTreeViewModel.h"
#import "NodeTreeViewCell.h"
#import "NodeTreeViewCellPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoNodeSetup.h"
#import "../../go/GoPlayer.h"


@class BranchTuple;

// TODO xxx document
@interface Branch : NSObject
{
@public
  Branch* lastChildBranch;
  Branch* previousSiblingBranch;
  Branch* parentBranch;
  BranchTuple* parentBranchTupleBranchingNode;
  NSMutableArray* branchTuples;
  unsigned short yPosition;
}
@end

@implementation Branch
@end

// TODO xxx document
@interface BranchTuple : NSObject
{
@public
  unsigned short xPositionOfFirstCell;
  GoNode* node;
  unsigned short numberOfCellsForNode;
  enum NodeTreeViewCellSymbol symbol;
  Branch* branch;
  NSMutableArray* childBranches;
}
@end

@implementation BranchTuple
@end


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewModel.
// -----------------------------------------------------------------------------
@interface NodeTreeViewModel()
@property(nonatomic, retain) NSMutableDictionary* cellsDictionary;
@end


@implementation NodeTreeViewModel

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewModel object with a canvas of size zero.
///
/// @note This is the designated initializer of NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // TODO xxx is this model the correct place for this user preference? if not, then this model must be informed
  // from the outside whether or not it should react to changes in GoNodeModel
  self.displayNodeTreeView = true;
  // TODO xxx user preference?
  self.displayNodeNumbers = true;
  // TODO xxx user preference
  self.condenseTree = true;
  self.alignMoveNodes = true;
  self.branchingStyle = NodeTreeViewBranchingStyleBracket;

  // The number chosen here must fulfill the following criteria:
  // - The number must be greater than 1, so that condensed nodes (which are
  //   represented by a single standalone cell) are drawn smaller than
  //   uncondensed nodes (which are represented by multiple sub-cells that
  //   together make up a multipart cell).
  // - The number must be uneven, so that one of the sub-cells that make up a
  //   multipart cell is at the horizontal center of the multipart cell. This is
  //   important so that vertical lines drawn in the center of the central cell
  //   also appear to be in the center of the entire multipart cell.
  // - The number should be relatively small, because a node symbol is drawn
  //   once for each sub-cell. Many sub-cells would mean that many drawing
  //   operations are necessary to draw a node symbol.
  self.numberOfCellsOfMultipartCell = 3;

  self.canvasSize = CGSizeZero;
  self.cellsDictionary = [NSMutableDictionary dictionary];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.cellsDictionary = nil;

  [super dealloc];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  // TODO xxx implement
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  // TODO xxx implement
}

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

  // TODO xxx check canvas bounds and return nil if out of bounds
  return [NodeTreeViewCell emptyCell];
}

// TODO xxx document
- (NSArray*) cellsInRow:(int)row
{
  // TODO xxx implement
  return nil;
}

#pragma mark - Private API

// TODO xxx document
//typedef struct
//{
//  unsigned short xPositionOfFirstCell;
//  GoNode* node;
//  unsigned short numberOfCellsForNode;
//  enum NodeTreeViewCellSymbol symbol;
//} BranchTuple;
//
//- (NSValue*) valueWithBranchTuple:(BranchTuple)branchTuple
//{
//  return [NSValue valueWithBytes:&branchTuple objCType:@encode(BranchTuple)];
//}
//
//- (BranchTuple) branchTupleValue:(NSValue*)value
//{
//  BranchTuple branchTupleValue;
//
//  if (@available(iOS 11.0, *))
//    [value getValue:&branchTupleValue size:sizeof(BranchTuple)];
//  else
//    [value getValue:&branchTupleValue];
//
//  return branchTupleValue;
//}

// General order of algorithm:
// 1. Iterate tree. Results:
//    - Branches
//    - Depth-first ordering of branches
//    - Ordered list of NodeTreeViewCell objects in each branch, with the
//      following values
//      - NodeTreeViewCellSymbol value
//      - part/parts values => User preference "Condense tree"
//    - NodeTreeViewCellPosition with preliminary x-coordinate. This can still
//      change if user preference "Align move nodes" is enabled.
//    - Preliminary length of a branch, based on the number of NodeTreeViewCell
//      objects
// 2. Iterate branches. Results:
//    - NodeTreeViewCellPosition with final x-coordinate => User preference
//      "Align move nodes"
//    - Updated length of a branch, based on the x-coordinate of the first and
//      last NodeTreeViewCellPosition
//    - NodeTreeViewCellPosition with y-coordinate, based on final
//      x-coordinates and branch lengths
// 3. Iterate branches / NodeTreeViewCell objects. Result:
//    - NodeTreeViewCellLines value for property lines
//    - NodeTreeViewCellLines value for property linesSelectedGameVariation
// 4. Select cell
- (void) recalc1
{
  GoNodeModel* nodeModel = [GoGame sharedGame].nodeModel;

  enum NodeTreeViewBranchingStyle branchingStyle = self.branchingStyle;

  // ----------
  // Part 1: Iterate tree to find out about branches and their ordering
  // ----------
  NSMutableArray* stack = [NSMutableArray array];

  GoNode* currentNode = nodeModel.rootNode;

  // TODO xxx The branches array may no longer be needed
  // Stores branches in depth-first order. Elements are arrays consisting of
  // tuples.
  NSMutableArray* branches = [NSMutableArray array];
  // TODO xxx remove if no longer needed
  // Maps child branches to their parent branches, including the place in the
  // parent branch where the branching point is.
  // Key = Index of child branch in branches array
  // Value = Tuple consisting of
  //         1) Index of parent branch in branches array
  //         2) Index of element in the parent branch that represents the parent
  //            cell in the parent branch. If the parent cell in the parent
  //            branch is a multipart cell this refers to the first part of the
  //            multipart cell.
//  NSMutableDictionary* childToParentBranchMap = [NSMutableDictionary dictionary];
  // Key = NSValue enapsulating a GoNode object. The GoNode is a branching node,
  //       i.e. a node that has multiple child nodes.
  // Value = List with child branches. The parent branch, i.e. the branch in
  //         which the branching node is located, is not in the list.
  NSMutableDictionary* branchingNodeToChildBranchesMap = [NSMutableDictionary dictionary];
  Branch* parentBranch = nil;
  unsigned short xPosition = 0;
  NSMutableArray* moveData = [NSMutableArray array];
  int highestMoveNumberThatAppearsInAtLeastTwoBranches = -1;

  while (true)
  {
    // TODO xxx this description is outdated
    // Elements are tuples consisting of a GoNode object and its associated
    // NodeTreeViewCell object. If the user preference "Condense tree" is
    // enabled then GoNode objects with certain properties will result in
    // multiple tuples with the same GoNode object but different
    // NodeTreeViewCell objects.
    Branch* branch = nil;
    NSUInteger indexOfBranch = -1;
    while (currentNode)
    {
      // TODO xxx node visit start

      // Create the array that holds the branch information only on demand, i.e.
      // when there actually *is* a node in the branch. This requires a
      // nil-check here within the while-loop for every node. A nil-check is
      // still more efficient than creating an array for every node when the
      // outer while loop pops the stack and checks for a next sibling for
      // every node.
      if (! branch)
      {
        branch = [[[Branch alloc] init] autorelease];
        branch->branchTuples = [NSMutableArray array];
        branch->lastChildBranch = nil;
        branch->previousSiblingBranch = nil;
        branch->parentBranch = parentBranch;
        branch->yPosition = 0;

        if (parentBranch)
        {
          // TODO xxx Try to find a faster way how to determine the branching node tuple
          GoNode* branchingNode = currentNode.parent;
          for (BranchTuple* parentBranchTuple in branch->parentBranch->branchTuples)
          {
            if (parentBranchTuple->node == branchingNode)
            {
              branch->parentBranchTupleBranchingNode = parentBranchTuple;
              if (! parentBranchTuple->childBranches)
                parentBranchTuple->childBranches = [NSMutableArray array];
              [parentBranchTuple->childBranches addObject:branch];
              break;
            }
          }

          if (parentBranch->lastChildBranch)
          {
            for (Branch* childBranch = parentBranch->lastChildBranch; childBranch; childBranch = childBranch->previousSiblingBranch)
            {
              if (! childBranch->previousSiblingBranch)
                childBranch->previousSiblingBranch = branch;
            }
          }
          else
          {
            parentBranch->lastChildBranch = branch;
          }
        }
        else
        {
          branch->parentBranchTupleBranchingNode = nil;
        }

        [branches addObject:branch];
        indexOfBranch = branches.count - 1;

        GoNode* branchingNode = currentNode.parent;
        if (branchingNode)
        {
          NSValue* key = [NSValue valueWithNonretainedObject:branchingNode];
          NSMutableArray* childBranches = [branchingNodeToChildBranchesMap objectForKey:key];
          if (! childBranches)
          {
            childBranches = [NSMutableArray array];
            branchingNodeToChildBranchesMap[key] = childBranches;
          }
          [childBranches addObject:branch];
        }
      }

      BranchTuple* branchTuple = [[[BranchTuple alloc] init] autorelease];
      branchTuple->xPositionOfFirstCell = xPosition;
      branchTuple->node = currentNode;
      branchTuple->symbol = [self symbolForNode:currentNode];
      branchTuple->numberOfCellsForNode = [self numberOfCellsForNode:currentNode condenseTree:condenseTree];
      branchTuple->branch = branch;
      branchTuple->childBranches = nil;

      [branch->branchTuples addObject:branchTuple];

      xPosition += branchTuple->numberOfCellsForNode;

      GoMove* move = currentNode.goMove;
      if (move)
      {
        NSMutableArray* moveDataTuples;

        int moveNumber = move.moveNumber;
        if (moveNumber > moveData.count)
        {
          moveDataTuples = [NSMutableArray array];
          [moveData addObject:moveDataTuples];
        }
        else
        {
          moveDataTuples = [moveData objectAtIndex:moveNumber - 1];
        }

        [moveDataTuples addObject:@[branch, branchTuple]];

        if (moveDataTuples.count > 1)
        {
          if (moveNumber > highestMoveNumberThatAppearsInAtLeastTwoBranches)
            highestMoveNumberThatAppearsInAtLeastTwoBranches = moveNumber;
        }
      }

      // TODO xxx node visit end

      [stack addObject:branchTuple];

      currentNode = currentNode.firstChild;
    }

    if (stack.count > 0)
    {
      BranchTuple* branchTuple = stack.lastObject;
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

  // ----------
  // Part 2: Align move nodes
  // ----------
  if (self.alignMoveNodes)
  {
    // Optimization: We only have to align moves that appear in at least two
    // branches.
    for (int indexOfMove = 0; indexOfMove < highestMoveNumberThatAppearsInAtLeastTwoBranches; indexOfMove++)
    {
      NSMutableArray* moveDataTuples = [moveData objectAtIndex:indexOfMove];

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
      if (moveDataTuples.count == 1)
        continue;

      unsigned short highestXPositionCurrentMove = 0;
      bool highestXPositionCurrentMoveWasChanged = false;
      bool currentMoveIsAlignedInAllBranches = true;

      for (NSArray* moveDataTuple in moveDataTuples)
      {
        BranchTuple* branchTuple = moveDataTuple.lastObject;
        if (branchTuple->xPositionOfFirstCell > highestXPositionCurrentMove)
        {
          highestXPositionCurrentMove = branchTuple->xPositionOfFirstCell;

          // Don't set currentMoveIsAlignedInAllBranches to false after we
          // set highestXPositionCurrentMove for the first branch
          if (highestXPositionCurrentMoveWasChanged)
            currentMoveIsAlignedInAllBranches = false;
          else
            highestXPositionCurrentMoveWasChanged = true;
        }
      }

      if (currentMoveIsAlignedInAllBranches)
        continue;

      for (NSArray* moveDataTuple in moveDataTuples)
      {
        NSMutableArray* branch = moveDataTuple.firstObject;
        BranchTuple* branchTuple = moveDataTuple.lastObject;

        // Branch is already aligned
        if (branchTuple->xPositionOfFirstCell == highestXPositionCurrentMove)
          continue;

        NSUInteger indexOfFirstBranchTupleToShift = [branch indexOfObject:branchTuple];
        unsigned short alignOffset = highestXPositionCurrentMove - branchTuple->xPositionOfFirstCell;

        // It is not sufficient to shift only the tuples of the current branch
        // => there may be child branches whose tuple positions also need to be
        // shifted. In the following example, when M2 of the main branch is
        // aligned, the cells of the child branches that contain M3 and M4 also
        // need to be shifted.
        // o---M1---M2---A----A
        //     |    +----M3   +----A----M4
        //     +----A----M2

        NSMutableArray* branchesToShift = [NSMutableArray array];
        [branchesToShift addObject:branch];
        bool shiftingInitialBranch = true;

        // Reusable local function
        void (^shiftBranchTuple) (BranchTuple*) = ^(BranchTuple* branchTupleToShift)
        {
          branchTupleToShift->xPositionOfFirstCell += alignOffset;

          NSValue* key = [NSValue valueWithNonretainedObject:branchTupleToShift->node];
          NSMutableArray* childBranches = [branchingNodeToChildBranchesMap objectForKey:key];
          if (childBranches)
            [branchesToShift addObjectsFromArray:childBranches];
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
          Branch* branchToShift = branchesToShift.firstObject;
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
              BranchTuple* branchTupleToShift = [branchTuplesToShift objectAtIndex:indexOfBranchTupleToShift];
              shiftBranchTuple(branchTupleToShift);
            }
          }
          else
          {
            for (BranchTuple* branchTupleToShift in branchTuplesToShift)
              shiftBranchTuple(branchTupleToShift);
          }
        }
      }
    }
  }

  // ----------
  // Part 3: Determine y-coordinates
  // ----------
//  unsigned short numberOfCellsForBranchingNode = condenseTree ? 1 : 1;  // TODO xxx correct numbers, similar to numberOfCellsForNode
  // In the worst case each branch is on its own y-position => create the array
  // to cater for this worst case
  NSUInteger numberOfBranches = branches.count;
  unsigned short lowestOccupiedXPositionOfRow[numberOfBranches];
  for (NSUInteger indexOfBranch = 0; indexOfBranch < numberOfBranches; indexOfBranch++)
    lowestOccupiedXPositionOfRow[indexOfBranch] = -1;

  // TODO xxx should be empty
  [stack removeAllObjects];

  Branch* currentBranch = branches.firstObject;

  while (true)
  {
    while (currentBranch)
    {
      // Start visit branch
      // The y-position of a child branch is at least one below the y-position
      // of the parent branch
      unsigned short yPosition;
      if (currentBranch->parentBranch)
        yPosition = currentBranch->parentBranch->yPosition + 1;
      else
        yPosition = 0;

      BranchTuple* lastBranchTuple = currentBranch->branchTuples.lastObject;
      unsigned short highestXPositionOfBranch = (lastBranchTuple->xPositionOfFirstCell +
                                                 lastBranchTuple->numberOfCellsForNode -
                                                 1);
      while (highestXPositionOfBranch >= lowestOccupiedXPositionOfRow[yPosition])
        yPosition++;

      currentBranch->yPosition = yPosition;

      unsigned short lowestXPositionOfBranch;
      if (currentBranch->parentBranch)
      {
        lowestXPositionOfBranch = currentBranch->parentBranchTupleBranchingNode->xPositionOfFirstCell;

        // Diagonal branching style allows for a small optimization of the
        // available space on the LAST child branch:
        // A---B---C---D---E---F---G
        //     |   |\--H   \    \--I
        //      \--J\--K    ---L---M
        // The branch with node J fits on the same y-position as the branch with
        // node K because 1) the diagonal branching line leading from C to K
        // does not occupy the space of J, and there is also no vertical
        // branching line to another child node of C that would take the space
        // away from J. The situation is different for the branch with node L
        // and M: Because the branch contains two nodes it is too long and does
        // not fit on the same y-position as the branch with node I.
        if (branchingStyle == NodeTreeViewBranchingStyleDiagonal && currentBranch->parentBranchTupleBranchingNode->childBranches.lastObject == currentBranch)
          lowestXPositionOfBranch += currentBranch->parentBranchTupleBranchingNode->numberOfCellsForNode;
      }
      else
      {
        lowestXPositionOfBranch = 0;
      }

      lowestOccupiedXPositionOfRow[yPosition] = lowestXPositionOfBranch;
      // End visit branch

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

  // ----------
  // Part 4: Determine lines
  // - Add lines to cells that so far contained only symbols
  // - Generate line-only cells to connect move nodes that are no longer
  //   adjacent because they were aligned to the move number
  // - Generate line-only cells that connect branches
  // ----------
  NodeTreeViewCellLine connectingLineToBranchingLine = (branchingStyle == NodeTreeViewBranchingStyleDiagonal
                                                        ? NodeTreeViewCellLineCenterToBottomRight
                                                        : NodeTreeViewCellLineCenterToRight);
  NSMutableDictionary* cellsDictionary = [NSMutableDictionary dictionary];
  for (Branch* branch in branches)
  {
    unsigned short xPositionAfterPreviousBranchTuple;
    if (currentBranch->parentBranch)
    {
      unsigned short xPositionAfterLastCellInBranchingTuple = (currentBranch->parentBranchTupleBranchingNode->xPositionOfFirstCell +
                                                               currentBranch->parentBranchTupleBranchingNode->numberOfCellsForNode);
      xPositionAfterPreviousBranchTuple = xPositionAfterLastCellInBranchingTuple;
    }
    else
    {
      xPositionAfterPreviousBranchTuple = 0;
    }

    BranchTuple* firstBranchTuple = branch->branchTuples.firstObject;
    BranchTuple* lastBranchTuple = branch->branchTuples.lastObject;

    for (BranchTuple* branchTuple in branch->branchTuples)
    {
      // Part 1: Generate cells with lines that connect the node to either its
      // predecessor node in the same branch, or to a branching line that
      // reaches out from the cell with the branching node
      for (unsigned short xPositionOfCell = xPositionAfterPreviousBranchTuple; xPositionOfCell < branchTuple->xPositionOfFirstCell; xPositionOfCell++)
      {
        NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
        if (branchingStyle == NodeTreeViewBranchingStyleDiagonal && branchTuple == firstBranchTuple && xPositionOfCell == xPositionAfterPreviousBranchTuple)
          cell.lines = NodeTreeViewCellLineCenterToTopLeft | NodeTreeViewCellLineCenterToRight;  // connect to branching line
        else
          cell.lines = NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight;

        NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPositionOfCell y:branch->yPosition];
        cellsDictionary[position] = cell;
      }

      // Part 2: If it's a branching node then generate cells below the
      // branching node that contain vertical branching lines.
      if (branchTuple->childBranches)
      {
        Branch* lastChildBranch = branchTuple->childBranches.lastObject;

        // Not every y-position has a branch, so we can't draw a horizontal or
        // diagonal branching line on every y-position. The "next child branch"
        // refers to the upcoming child branch for which we want to draw a
        // horizontal or diagonal branching line.
        NSUInteger indexOfNextChildBranch = 0;
        Branch* nextChildBranch = [branchTuple->childBranches objectAtIndex:indexOfNextChildBranch];

        unsigned short lastYPosition = lastChildBranch->yPosition;

        // Diagonal branching style does not draw a branching line on the
        // y-position of the last child branch
        if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
          lastYPosition--;

        for (unsigned short yPosition = branch->yPosition + 1; yPosition <= lastYPosition; yPosition++)
        {
          NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];

          cell.lines = NodeTreeViewCellLineCenterToTop;

          if (yPosition == nextChildBranch->yPosition)
            cell.lines |= connectingLineToBranchingLine;

          if (yPosition < lastYPosition)
            cell.lines |= NodeTreeViewCellLineCenterToBottom;

          NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:branchTuple->xPositionOfFirstCell y:yPosition];
          cellsDictionary[position] = cell;

          if (branchTuple->numberOfCellsForNode > 1)
          {
            unsigned short xPositionOfLastCell = branchTuple->xPositionOfFirstCell + branchTuple->numberOfCellsForNode - 1;
            for (unsigned short xPosition = branchTuple->xPositionOfFirstCell + 1; xPosition <= xPositionOfLastCell; xPosition++)
            {
              NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
              cell.lines = NodeTreeViewCellLineCenterToLeft | NodeTreeViewCellLineCenterToRight;

              NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition y:yPosition];
              cellsDictionary[position] = cell;
            }
          }

          if (yPosition == nextChildBranch->yPosition && nextChildBranch != lastChildBranch)
          {
            indexOfNextChildBranch++;
            nextChildBranch = [branchTuple->childBranches objectAtIndex:indexOfNextChildBranch];
          }
        }
      }

      // Part 3: Add lines to node cells
      NodeTreeViewCellLines lines = NodeTreeViewCellLineNone;

      if (branchTuple == firstBranchTuple)
      {
        if (branch->yPosition == 0)
        {
          // Root node does not have a connecting line on the left
        }
        else
        {
          if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
            lines = NodeTreeViewCellLineCenterToTopLeft;
          else
            lines = NodeTreeViewCellLineCenterToLeft;
        }
      }

      if (branchTuple != lastBranchTuple)
      {
        lines |= NodeTreeViewCellLineCenterToRight;
      }

      if (branchTuple->childBranches)
      {
        if (branchingStyle == NodeTreeViewBranchingStyleDiagonal)
        {
          Branch* firstChildBranch = branchTuple->childBranches.firstObject;
          if (branchTuple->branch->yPosition + 1 == firstChildBranch->yPosition)
            lines |= NodeTreeViewCellLineCenterToBottomRight;
          else
            lines = NodeTreeViewCellLineCenterToBottom;

          if (branchTuple->childBranches.count > 1)
            lines = NodeTreeViewCellLineCenterToBottom;
        }
        else
        {
          lines = NodeTreeViewCellLineCenterToBottom;
        }
      }


      for (unsigned indexOfCell = 0; indexOfCell < branchTuple->numberOfCellsForNode; indexOfCell++)
      {
        NodeTreeViewCell* cell = [NodeTreeViewCell emptyCell];
        cell.part = indexOfCell;
        cell.parts = branchTuple->numberOfCellsForNode;

        cell.symbol = branchTuple->symbol;
        cell.lines = lines;

        unsigned short xPosition = branchTuple->xPositionOfFirstCell + indexOfCell;
        NodeTreeViewCellPosition* position = [NodeTreeViewCellPosition positionWithX:xPosition y:branch->yPosition];
        cellsDictionary[position] = cell;
      }

      // Part 4: Adjust xPositionAfterPreviousBranchTuple so that the next
      // branch tuple can connect
      xPositionAfterPreviousBranchTuple = branchTuple->xPositionOfFirstCell + branchTuple->numberOfCellsForNode;;
    }
  }

  self.cellsDictionary = cellsDictionary;
  self.canvasSize = CGSizeMake(highestXPosition + 1, highestYPosition + 1);
}

// TODO xxx document
- (unsigned short) lengthOfBranch:(NSArray*)branch
{
  BranchTuple* firstBranchTuple = branch.firstObject;
  BranchTuple* lastBranchTuple = branch.lastObject;
  return (lastBranchTuple->xPositionOfFirstCell +
          lastBranchTuple->numberOfCellsForNode -
          firstBranchTuple->xPositionOfFirstCell);
}

- (unsigned short) highestXPositionOfBranch:(NSArray*)branch
{
  BranchTuple* lastBranchTuple = branch.lastObject;
  return (lastBranchTuple->xPositionOfFirstCell +
          lastBranchTuple->numberOfCellsForNode -
          1);
}

// TODO xxx document
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
  else if (node.goMove)
  {
    if (node.goMove.player.isBlack)
      return NodeTreeViewCellSymbolBlackMove;
    else
      return NodeTreeViewCellSymbolWhiteMove;
  }

  return NodeTreeViewCellSymbolEmpty;
}

// TODO xxx document
- (unsigned short) numberOfCellsForNode:(GoNode*)node condenseTree:(bool)condenseTree
{
  if (! condenseTree)
    return self.numberOfCellsOfMultipartCell;

  // Root node: Because the root node starts the main variation it is considered
  // a branching node
  if (node.isRoot)
    return self.numberOfCellsOfMultipartCell;

  // Branching nodes are uncondensed
  // TODO xxx new property isBranchingNode
  if (node.firstChild != node.lastChild)
    return self.numberOfCellsOfMultipartCell;

  // Child nodes of a branching node
  GoNode* parent = node.parent;
  if (parent.firstChild != parent.lastChild)
    return self.numberOfCellsOfMultipartCell;

  // Leaf nodes
  // TODO xxx new property isLeafNode
  if (! node.hasChildren)
    return self.numberOfCellsOfMultipartCell;

  // Nodes with non-move content
  if (node.goNodeSetup || node.goNodeAnnotation || node.goNodeMarkup)
    return self.numberOfCellsOfMultipartCell;

  return 1;
}

@end
