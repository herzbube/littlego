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
#import "NodeSymbolLayerDelegate.h"
#import "NodeTreeViewCGLayerCache.h"
#import "NodeTreeViewDrawingHelper.h"
#import "../NodeTreeViewMetrics.h"
#import "../canvas/NodeTreeViewCanvas.h"
#import "../canvas/NodeTreeViewCell.h"
#import "../canvas/NodeTreeViewCellPosition.h"
#import "../../../ui/Tile.h"
#import "../../../utility/NSArrayAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeSymbolLayerDelegate.
// -----------------------------------------------------------------------------
@interface NodeSymbolLayerDelegate()
@property(nonatomic, assign) NodeTreeViewCanvas* nodeTreeViewCanvas;
@property(nonatomic, retain) NSArray* drawingCellsOnTile;
/// @brief The dirty rect calculated by notify:eventInfo:() that later needs to
/// be used by drawLayer(). Used only when drawing is required because of a
/// node symbol change.
@property(nonatomic, assign) CGRect dirtyRectForNodeSymbolChanged;
@property(nonatomic, retain) NSArray* nodeSymbolChangedPositionsOnTile;
@end


@implementation NodeSymbolLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeSymbolLayerDelegate object.
///
/// @note This is the designated initializer of NodeSymbolLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile
            metrics:(NodeTreeViewMetrics*)metrics
             canvas:(NodeTreeViewCanvas*)nodeTreeViewCanvas
{
  // Call designated initializer of superclass (NodeTreeViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;

  self.nodeTreeViewCanvas = nodeTreeViewCanvas;
  self.drawingCellsOnTile = @[];
  self.dirtyRectForNodeSymbolChanged = CGRectZero;
  self.nodeSymbolChangedPositionsOnTile = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeSymbolLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // There are times when no NodeSymbolLayerDelegate instances are around to
  // react to events that invalidate the cached CGLayers, so the cached CGLayers
  // will inevitably become out-of-date. To prevent this, we invalidate the
  // CGLayers *NOW*.
  [self invalidateLayers];

  self.nodeTreeViewCanvas = nil;
  self.drawingCellsOnTile = nil;
  self.nodeSymbolChangedPositionsOnTile = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates node symbol layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  NodeTreeViewCGLayerCache* cache = [NodeTreeViewCGLayerCache sharedCache];
  [cache invalidateAllNodeSymbolLayers];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the "node symbol changed" dirty rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyRectForNodeSymbolChanged
{
  self.dirtyRectForNodeSymbolChanged = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief NodeTreeViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  // TODO xxx remove
  int row = self.tile.row;
  int column = self.tile.column;
  if (row == 0 && column == 0)
  {
    int i = 99;
  }
  else if (row == 0 && column == 1)
  {
    int i = 99;
  }
  else if (row == 1 && column == 0)
  {
    int i = 99;
  }
  else if (row == 1 && column == 1)
  {
    int i = 99;
  }

  switch (event)
  {
    case NTVLDEventNodeTreeGeometryChanged:
    case NTVLDEventInvalidateContent:
    {
      [self invalidateLayers];
      self.drawingCellsOnTile = [self calculateDrawingCellsOnTile];
      [self invalidateDirtyRectForNodeSymbolChanged];
      self.nodeSymbolChangedPositionsOnTile = nil;
      self.dirty = true;
      break;
    }
    case NTVLDEventAbstractCanvasSizeChanged:
    {
      NSArray* newDrawingCellsOnTile = [self calculateDrawingCellsOnTile];
      if (! [self.drawingCellsOnTile isEqualToArray:newDrawingCellsOnTile])
      {
        self.drawingCellsOnTile = newDrawingCellsOnTile;
        [self invalidateDirtyRectForNodeSymbolChanged];
        self.nodeSymbolChangedPositionsOnTile = nil;
        self.dirty = true;
      }
      break;
    }
    case NTVLDEventNodeTreeContentChanged:
    case NTVLDEventNodeTreeCondenseMoveNodesChanged:
    case NTVLDEventNodeTreeAlignMoveNodesChanged:
    case NTVLDEventNodeTreeBranchingStyleChanged:
    {
      [self invalidateDirtyRectForNodeSymbolChanged];
      self.nodeSymbolChangedPositionsOnTile = nil;
      self.dirty = true;
      break;
    }
    case NTVLDEventNodeTreeNodeSymbolChanged:
    {
      NSArray* newNodeSymbolChangedPositionsOnTile = [self.drawingCellsOnTile intersectionWithArray:eventInfo];
      if (newNodeSymbolChangedPositionsOnTile.count > 0)
      {
        NodeTreeViewCellPosition* position = newNodeSymbolChangedPositionsOnTile.firstObject;
        NodeTreeViewCell* cell = [self.nodeTreeViewCanvas cellAtPosition:position];
        if (cell.isMultipart)
        {
          self.dirtyRectForNodeSymbolChanged = [NodeTreeViewDrawingHelper drawingRectForTile:self.tile
                                                                           multipartCellPart:cell.part
                                                                                partPosition:position
                                                                                     metrics:self.nodeTreeViewMetrics];
        }
        else
        {
          self.dirtyRectForNodeSymbolChanged = [NodeTreeViewDrawingHelper drawingRectForTile:self.tile
                                                                              cellAtPosition:position
                                                                                     metrics:self.nodeTreeViewMetrics];
        }
        self.nodeSymbolChangedPositionsOnTile = newNodeSymbolChangedPositionsOnTile;
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
/// @brief NodeTreeViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;

    if (CGRectIsEmpty(self.dirtyRectForNodeSymbolChanged))
      [self.layer setNeedsDisplay];
    else
      [self.layer setNeedsDisplayInRect:self.dirtyRectForNodeSymbolChanged];

    [self invalidateDirtyRectForNodeSymbolChanged];
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  // TODO xxx remove
  int row = self.tile.row;
  int column = self.tile.column;
  if (row == 0 && column == 0)
  {
    int i = 99;
  }
  else if (row == 0 && column == 1)
  {
    int i = 99;
  }
  else if (row == 1 && column == 0)
  {
    int i = 99;
  }
  else if (row == 1 && column == 1)
  {
    int i = 99;
  }
  else if (row == 0 && column == 4)
  {
    int i = 99;
  }
  [self createLayersIfNecessaryWithContext:context];

  bool condenseMoveNodes = self.nodeTreeViewMetrics.condenseMoveNodes;
  NodeTreeViewCGLayerCache* cache = [NodeTreeViewCGLayerCache sharedCache];
  CGRect tileRect = [NodeTreeViewDrawingHelper canvasRectForTile:self.tile
                                                         metrics:self.nodeTreeViewMetrics];

  NSArray* positionsToDraw;
  if (self.nodeSymbolChangedPositionsOnTile)
  {
    positionsToDraw = [[self.nodeSymbolChangedPositionsOnTile retain] autorelease];
    self.nodeSymbolChangedPositionsOnTile = nil;
  }
  else
  {
    positionsToDraw = self.drawingCellsOnTile;
  }

  for (NodeTreeViewCellPosition* position in positionsToDraw)
  {
    NodeTreeViewCell* cell = [self.nodeTreeViewCanvas cellAtPosition:position];
    if (! cell || cell.symbol == NodeTreeViewCellSymbolNone)
      continue;

    enum NodeTreeViewLayerType layerType = [self layerTypeForSymbol:cell.symbol
                                                cellIsMultipartCell:cell.isMultipart
                                                  condenseMoveNodes:condenseMoveNodes];
    CGLayerRef layer = [cache layerOfType:layerType];

    if (cell.isMultipart)
    {
      [NodeTreeViewDrawingHelper drawLayer:layer
                               withContext:context
                                      part:cell.part
                              partPosition:position
                            inTileWithRect:tileRect
                               withMetrics:self.nodeTreeViewMetrics];
    }
    else
    {
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

  for (enum NodeTreeViewLayerType layerType = NodeTreeViewLayerTypeNodeSymbolFirst;
       layerType <= NodeTreeViewLayerTypeNodeSymbolLast;
       layerType++)
  {
    CGLayerRef layer = [cache layerOfType:layerType];
    if (! layer)
    {
      enum NodeTreeViewCellSymbol symbolType = [self symbolTypeForLayerType:layerType];
      bool condensed = layerType == NodeTreeViewLayerTypeBlackMoveCondensed || layerType == NodeTreeViewLayerTypeWhiteMoveCondensed;
      layer = CreateNodeSymbolLayer(context, symbolType, condensed, self.nodeTreeViewMetrics);
      [cache setLayer:layer ofType:layerType];
      CGLayerRelease(layer);
    }
  }
}

// TODO xxx document
- (enum NodeTreeViewCellSymbol) symbolTypeForLayerType:(enum NodeTreeViewLayerType)layerType
{
  switch (layerType)
  {
    case NodeTreeViewLayerTypeEmpty:
      return NodeTreeViewCellSymbolEmpty;
    case NodeTreeViewLayerTypeBlackSetupStones:
      return NodeTreeViewCellSymbolBlackSetupStones;
    case NodeTreeViewLayerTypeWhiteSetupStones:
      return NodeTreeViewCellSymbolWhiteSetupStones;
    case NodeTreeViewLayerTypeNoSetupStones:
      return NodeTreeViewCellSymbolNoSetupStones;
    case NodeTreeViewLayerTypeBlackAndWhiteSetupStones:
      return NodeTreeViewCellSymbolBlackAndWhiteSetupStones;
    case NodeTreeViewLayerTypeBlackAndNoSetupStones:
      return NodeTreeViewCellSymbolBlackAndNoSetupStones;
    case NodeTreeViewLayerTypeWhiteAndNoSetupStones:
      return NodeTreeViewCellSymbolWhiteAndNoSetupStones;
    case NodeTreeViewLayerTypeBlackAndWhiteAndNoSetupStones:
      return NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones;
    case NodeTreeViewLayerTypeBlackMoveCondensed:
    case NodeTreeViewLayerTypeBlackMoveUncondensed:
      return NodeTreeViewCellSymbolBlackMove;
    case NodeTreeViewLayerTypeWhiteMoveCondensed:
    case NodeTreeViewLayerTypeWhiteMoveUncondensed:
      return NodeTreeViewCellSymbolWhiteMove;
    case NodeTreeViewLayerTypeAnnotations:
      return NodeTreeViewCellSymbolAnnotations;
    case NodeTreeViewLayerTypeMarkup:
      return NodeTreeViewCellSymbolMarkup;
    case NodeTreeViewLayerTypeAnnotationsAndMarkup:
      return NodeTreeViewCellSymbolAnnotationsAndMarkup;
    case NodeTreeViewLayerTypeHandicap:
      return NodeTreeViewCellSymbolHandicap;
    case NodeTreeViewLayerTypeKomi:
      return NodeTreeViewCellSymbolKomi;
    case NodeTreeViewLayerTypeHandicapAndKomi:
      return NodeTreeViewCellSymbolHandicapAndKomi;
    case NodeTreeViewLayerTypeRoot:
      return NodeTreeViewCellSymbolRoot;
    default:
      assert(0);
      return NodeTreeViewCellSymbolNone;
  }
}

- (enum NodeTreeViewLayerType) layerTypeForSymbol:(enum NodeTreeViewCellSymbol)symbolType
                              cellIsMultipartCell:(bool)cellIsMultipartCell
                                condenseMoveNodes:(bool)condenseMoveNodes
{
  switch (symbolType)
  {
    case NodeTreeViewCellSymbolEmpty:
      return NodeTreeViewLayerTypeEmpty;
    case NodeTreeViewCellSymbolBlackSetupStones:
      return NodeTreeViewLayerTypeBlackSetupStones;
    case NodeTreeViewCellSymbolWhiteSetupStones:
      return NodeTreeViewLayerTypeWhiteSetupStones;
    case NodeTreeViewCellSymbolNoSetupStones:
      return NodeTreeViewLayerTypeNoSetupStones;
    case NodeTreeViewCellSymbolBlackAndWhiteSetupStones:
      return NodeTreeViewLayerTypeBlackAndWhiteSetupStones;
    case NodeTreeViewCellSymbolBlackAndNoSetupStones:
      return NodeTreeViewLayerTypeBlackAndNoSetupStones;
    case NodeTreeViewCellSymbolWhiteAndNoSetupStones:
      return NodeTreeViewLayerTypeWhiteAndNoSetupStones;
    case NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones:
      return NodeTreeViewLayerTypeBlackAndWhiteAndNoSetupStones;
    case NodeTreeViewCellSymbolBlackMove:
      if (condenseMoveNodes)
        return cellIsMultipartCell ? NodeTreeViewLayerTypeBlackMoveUncondensed : NodeTreeViewLayerTypeBlackMoveCondensed;
      else
        return NodeTreeViewLayerTypeBlackMoveUncondensed;
    case NodeTreeViewCellSymbolWhiteMove:
      if (condenseMoveNodes)
        return cellIsMultipartCell ? NodeTreeViewLayerTypeWhiteMoveUncondensed : NodeTreeViewLayerTypeWhiteMoveCondensed;
      else
        return NodeTreeViewLayerTypeWhiteMoveUncondensed;
    case NodeTreeViewCellSymbolAnnotations:
      return NodeTreeViewLayerTypeAnnotations;
    case NodeTreeViewCellSymbolMarkup:
      return NodeTreeViewLayerTypeMarkup;
    case NodeTreeViewCellSymbolAnnotationsAndMarkup:
      return NodeTreeViewLayerTypeAnnotationsAndMarkup;
    case NodeTreeViewCellSymbolHandicap:
      return NodeTreeViewLayerTypeHandicap;
    case NodeTreeViewCellSymbolKomi:
      return NodeTreeViewLayerTypeKomi;
    case NodeTreeViewCellSymbolHandicapAndKomi:
      return NodeTreeViewLayerTypeHandicapAndKomi;
    case NodeTreeViewCellSymbolRoot:
      return NodeTreeViewLayerTypeRoot;
    default:
      assert(0);
      return NodeTreeViewLayerTypeBlackSetupStones;  // dummy return
  }
}

@end
