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


// Project includes
#import "SelectedNodeLayerDelegate.h"
#import "NodeTreeViewCGLayerCache.h"
#import "NodeTreeViewDrawingHelper.h"
#import "../NodeTreeViewMetrics.h"
#import "../canvas/NodeTreeViewCanvas.h"
#import "../canvas/NodeTreeViewCell.h"
#import "../../../ui/CGDrawingHelper.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// SelectedNodeLayerDelegate.
// -----------------------------------------------------------------------------
@interface SelectedNodeLayerDelegate()
@property(nonatomic, assign) NodeTreeViewCanvas* nodeTreeViewCanvas;
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
@property(nonatomic, retain) NSArray* selectedNodePositionsOnTile;
@end


@implementation SelectedNodeLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a SelectedNodeLayerDelegate object.
///
/// @note This is the designated initializer of SelectedNodeLayerDelegate.
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
  self.selectedNodePositionsOnTile = @[];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SelectedNodeLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // There are times when no SelectedNodeLayerDelegate instances are around to
  // react to events that invalidate the cached CGLayers, so the cached CGLayers
  // will inevitably become out-of-date. To prevent this, we invalidate the
  // CGLayers *NOW*.
  [self invalidateLayers];

  self.nodeTreeViewCanvas = nil;
  self.selectedNodePositionsOnTile = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates node selection layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  NodeTreeViewCGLayerCache* cache = [NodeTreeViewCGLayerCache sharedCache];
  [cache invalidateLayerOfType:NodeTreeViewLayerTypeNodeSelectionCondensed];
  [cache invalidateLayerOfType:NodeTreeViewLayerTypeNodeSelectionUncondensed];
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
      [self invalidateLayers];
      self.selectedNodePositionsOnTile = [self calculateSelectedNodePositionsOnTile];
      self.dirty = true;
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
      NSArray* newSelectedNodeTreeViewPositions = newSelectedNodePositionsTuple.firstObject;
      NSArray* newSelectedNodePositionsOnTile = [self calculateSelectedNodePositionsOnTile:newSelectedNodeTreeViewPositions];
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
    case NTVLDEventNodeTreeNodeSelectionStyleChanged:
    {
      [self invalidateLayers];
      if (self.selectedNodePositionsOnTile.count > 0)
        self.dirty = true;
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
  if (self.selectedNodePositionsOnTile.count == 0)
    return;

  [self createLayersIfNecessaryWithContext:context];

  bool condenseMoveNodes = self.nodeTreeViewMetrics.condenseMoveNodes;
  NodeTreeViewCGLayerCache* cache = [NodeTreeViewCGLayerCache sharedCache];
  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.nodeTreeViewMetrics.tileSize];

  for (NodeTreeViewCellPosition* position in self.selectedNodePositionsOnTile)
  {
    NodeTreeViewCell* cell = [self.nodeTreeViewCanvas cellAtPosition:position];
    if (! cell || ! cell.selected)
      continue;

    if (! condenseMoveNodes || cell.isMultipart)
    {
      CGLayerRef layer = [cache layerOfType:NodeTreeViewLayerTypeNodeSelectionUncondensed];
      [NodeTreeViewDrawingHelper drawLayer:layer
                               withContext:context
                                      part:cell.part
                              partPosition:position
                            inTileWithRect:tileRect
                               withMetrics:self.nodeTreeViewMetrics];
    }
    else
    {
      CGLayerRef layer = [cache layerOfType:NodeTreeViewLayerTypeNodeSelectionCondensed];
      [NodeTreeViewDrawingHelper drawLayer:layer
                               withContext:context
                                centeredAt:position
                            inTileWithRect:tileRect
                               withMetrics:self.nodeTreeViewMetrics];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) createLayersIfNecessaryWithContext:(CGContextRef)context
{
  NodeTreeViewCGLayerCache* cache = [NodeTreeViewCGLayerCache sharedCache];

  CGLayerRef nodeSelectionCondensedLayer = [cache layerOfType:NodeTreeViewLayerTypeNodeSelectionCondensed];
  if (! nodeSelectionCondensedLayer)
  {
    nodeSelectionCondensedLayer = CreateNodeSelectionLayer(context, true, self.nodeTreeViewModel, self.nodeTreeViewMetrics);
    [cache setLayer:nodeSelectionCondensedLayer ofType:NodeTreeViewLayerTypeNodeSelectionCondensed];
    CGLayerRelease(nodeSelectionCondensedLayer);
  }

  CGLayerRef nodeSelectionUncondensedLayer = [cache layerOfType:NodeTreeViewLayerTypeNodeSelectionUncondensed];
  if (! nodeSelectionUncondensedLayer)
  {
    nodeSelectionUncondensedLayer = CreateNodeSelectionLayer(context, false, self.nodeTreeViewModel, self.nodeTreeViewMetrics);
    [cache setLayer:nodeSelectionUncondensedLayer ofType:NodeTreeViewLayerTypeNodeSelectionUncondensed];
    CGLayerRelease(nodeSelectionUncondensedLayer);
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
    CGRect canvasRectForCell = [NodeTreeViewDrawingHelper canvasRectForCellAtPosition:position metrics:self.nodeTreeViewMetrics];
    if (CGRectIntersectsRect(tileRect, canvasRectForCell))
      [selectedNodePositionsOnTile addObject:position];
  }

  return selectedNodePositionsOnTile;
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of NodeTreeViewCellPosition objects which refer to the
/// currently selected node on the node tree view canvas and whose canvas
/// rectangle intersects with this tile.
// -----------------------------------------------------------------------------
- (NSArray*) calculateSelectedNodePositionsOnTile
{
  NSArray* selectedNodePositions = [self.nodeTreeViewCanvas selectedNodePositions];
  NSArray* newSelectedNodePositionsOnTile = [self calculateSelectedNodePositionsOnTile:selectedNodePositions];
  return newSelectedNodePositionsOnTile;
}

@end
