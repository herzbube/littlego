// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeNumbersLayerDelegate.h"
#import "NodeTreeViewDrawingHelper.h"
#import "../NodeTreeViewMetrics.h"
#import "../canvas/NodeNumbersViewCell.h"
#import "../canvas/NodeTreeViewCanvas.h"
#import "../../model/NodeTreeViewModel.h"
#import "../../../ui/CGDrawingHelper.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeNumbersLayerDelegate.
// -----------------------------------------------------------------------------
@interface NodeNumbersLayerDelegate()
@property(nonatomic, assign) NodeTreeViewCanvas* nodeTreeViewCanvas;
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
@property(nonatomic, retain) NSArray* drawingCellsOnTile;
@property(nonatomic, retain) NSArray* selectedNodePositionsOnTile;
@end


@implementation NodeNumbersLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeNumbersLayerDelegate object.
///
/// @note This is the designated initializer of NodeNumbersLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile
            metrics:(NodeTreeViewMetrics*)metrics
             canvas:(NodeTreeViewCanvas*)nodeTreeViewCanvas
              model:(NodeTreeViewModel*)nodeTreeViewModel
{
  // Call designated initializer of superclass (NodeTreeViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;

  self.nodeTreeViewCanvas = nodeTreeViewCanvas;
  self.nodeTreeViewModel = nodeTreeViewModel;
  self.drawingCellsOnTile = @[];
  self.selectedNodePositionsOnTile = @[];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeNumbersLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.nodeTreeViewCanvas = nil;
  self.nodeTreeViewModel = nil;
  self.drawingCellsOnTile = nil;
  self.selectedNodePositionsOnTile = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NodeTreeViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case NTVLDEventNodeTreeGeometryChanged:
    case NTVLDEventInvalidateContent:
    {
      self.drawingCellsOnTile = [self calculateNodeNumberViewDrawingCellsOnTile];
      self.selectedNodePositionsOnTile = [self calculateSelectedNodePositionsOnTile];
      self.dirty = true;
      break;
    }
    case NTVLDEventAbstractCanvasSizeChanged:
    {
      NSArray* newDrawingCellsOnTile = [self calculateNodeNumberViewDrawingCellsOnTile];
      NSArray* newSelectedNodePositionsOnTile = [self calculateSelectedNodePositionsOnTile];
      if (! [self.drawingCellsOnTile isEqualToArray:newDrawingCellsOnTile] ||
          ! [self.selectedNodePositionsOnTile isEqualToArray:newSelectedNodePositionsOnTile])
      {
        self.drawingCellsOnTile = newDrawingCellsOnTile;
        self.selectedNodePositionsOnTile = newSelectedNodePositionsOnTile;
        self.dirty = true;
      }
      break;
    }
    case NTVLDEventNodeTreeContentChanged:
    case NTVLDEventNodeTreeCondenseMoveNodesChanged:
    case NTVLDEventNodeTreeAlignMoveNodesChanged:
    case NTVLDEventNodeTreeBranchingStyleChanged:
    {
      self.selectedNodePositionsOnTile = [self calculateSelectedNodePositionsOnTile];
      self.dirty = true;
      break;
    }
    case NTVLDEventNodeTreeSelectedNodeChanged:
    {
      NSArray* newSelectedNodePositionsTuple = eventInfo;
      NSArray* newSelectedNodeNumbersViewPositions = newSelectedNodePositionsTuple.lastObject;
      NSArray* newSelectedNodePositionsOnTile = [self calculateSelectedNodePositionsOnTile:newSelectedNodeNumbersViewPositions];
      if (! [self.selectedNodePositionsOnTile isEqualToArray:newSelectedNodePositionsOnTile])
      {
        self.selectedNodePositionsOnTile = newSelectedNodePositionsOnTile;
        // Instead of redrawing the entire tile, we could only redraw the cells
        // for the de-selected node and for the newly selected node. See
        // handling of NTVLDEventNodeTreeNodeSymbolChanged for an example how
        // to calculate the dirty rect for a node's cells.
        self.dirty = true;
      }
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  UIFont* nodeNumberLabelFont = self.nodeTreeViewMetrics.nodeNumberLabelFont;
  if (! nodeNumberLabelFont)
    return;

  bool condenseMoveNodes = self.nodeTreeViewModel.condenseMoveNodes;

  NSDictionary* textAttributesUnselected = @{ NSFontAttributeName : nodeNumberLabelFont,
                                              NSForegroundColorAttributeName : self.nodeTreeViewMetrics.nodeNumberTextColor,
                                              NSShadowAttributeName: self.nodeTreeViewMetrics.nodeNumberTextShadow };
  NSDictionary* textAttributesSelected = @{ NSFontAttributeName : nodeNumberLabelFont,
                                            NSForegroundColorAttributeName : self.nodeTreeViewMetrics.selectedNodeColor };

  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.nodeTreeViewMetrics.tileSize];

  NSMutableDictionary* nodeNumbersAlreadyDrawn = [NSMutableDictionary dictionary];

  for (NodeTreeViewCellPosition* position in self.drawingCellsOnTile)
  {
    NodeNumbersViewCell* cell = [self.nodeTreeViewCanvas nodeNumbersViewCellAtPosition:position];

    int nodeNumber = cell.nodeNumber;
    if (nodeNumber == -1)
      continue;

    NSNumber* nodeNumberAsNumber = @(nodeNumber);
    if ([nodeNumbersAlreadyDrawn objectForKey:nodeNumberAsNumber])
      continue;
    nodeNumbersAlreadyDrawn[nodeNumberAsNumber] = nodeNumberAsNumber;

    NSString* nodeNumberString = [NSString stringWithFormat:@"%d", nodeNumber];
    NSDictionary* textAttributes = cell.isSelected ? textAttributesSelected : textAttributesUnselected;

    if (condenseMoveNodes)
    {
      [NodeTreeViewDrawingHelper drawNodeNumber:nodeNumberString
                                    withContext:context
                                 textAttributes:textAttributes
                                           part:cell.part
                                   partPosition:position
                                 inTileWithRect:tileRect
                                    withMetrics:self.nodeTreeViewMetrics];
    }
    else
    {
      [NodeTreeViewDrawingHelper drawNodeNumber:nodeNumberString
                                    withContext:context
                                 textAttributes:textAttributes
                                     centeredAt:position
                                 inTileWithRect:tileRect
                                    withMetrics:self.nodeTreeViewMetrics];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Examines all NodeTreeViewCellPosition objects in
/// @a selectedNodePositions and returns only those whose canvas rectangle
/// intersects with this tile.
// -----------------------------------------------------------------------------
- (NSArray*) calculateSelectedNodePositionsOnTile:(NSArray*)selectedNodePositions
{
  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.nodeTreeViewMetrics.tileSize];

  NSMutableArray* selectedNodePositionsOnTile = [NSMutableArray array];

  for (NodeTreeViewCellPosition* position in selectedNodePositions)
  {
    CGRect canvasRectForCell = [NodeTreeViewDrawingHelper canvasRectForNodeNumberCellAtPosition:position metrics:self.nodeTreeViewMetrics];
    if (CGRectIntersectsRect(tileRect, canvasRectForCell))
      [selectedNodePositionsOnTile addObject:position];
  }

  return selectedNodePositionsOnTile;
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of NodeTreeViewCellPosition objects which refer to the
/// currently selected node on the node numbers view canvas and whose canvas
/// rectangle intersects with this tile.
// -----------------------------------------------------------------------------
- (NSArray*) calculateSelectedNodePositionsOnTile
{
  NSArray* selectedNodePositions = [self.nodeTreeViewCanvas selectedNodeNodeNumbersViewPositions];
  NSArray* newSelectedNodePositionsOnTile = [self calculateSelectedNodePositionsOnTile:selectedNodePositions];
  return newSelectedNodePositionsOnTile;
}

@end
