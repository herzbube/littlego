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
#import "LinesLayerDelegate.h"
#import "NodeTreeViewDrawingHelper.h"
#import "../NodeTreeViewMetrics.h"
#import "../canvas/NodeTreeViewCanvas.h"
#import "../canvas/NodeTreeViewCell.h"
#import "../canvas/NodeTreeViewCellPosition.h"
#import "../../../ui/Tile.h"
#import "../../../ui/CGDrawingHelper.h"
#import "../../../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LinesLayerDelegate.
// -----------------------------------------------------------------------------
@interface LinesLayerDelegate()
@property(nonatomic, assign) NodeTreeViewCanvas* nodeTreeViewCanvas;
@property(nonatomic, retain) NSArray* drawingCellsOnTile;
@end


@implementation LinesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a LinesLayerDelegate object.
///
/// @note This is the designated initializer of LinesLayerDelegate.
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

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LinesLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.nodeTreeViewCanvas = nil;
  self.drawingCellsOnTile = nil;

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
      self.drawingCellsOnTile = [self calculateNodeTreeViewDrawingCellsOnTile];
      self.dirty = true;
      break;
    }
    case NTVLDEventAbstractCanvasSizeChanged:
    {
      NSArray* newDrawingCellsOnTile = [self calculateNodeTreeViewDrawingCellsOnTile];
      if (! [self.drawingCellsOnTile isEqualToArray:newDrawingCellsOnTile])
      {
        self.drawingCellsOnTile = newDrawingCellsOnTile;
        self.dirty = true;
      }
      break;
    }
    case NTVLDEventNodeTreeContentChanged:
    case NTVLDEventNodeTreeCondenseMoveNodesChanged:
    case NTVLDEventNodeTreeAlignMoveNodesChanged:
    case NTVLDEventNodeTreeBranchingStyleChanged:
    case NTVLDEventNodeTreeSelectedGameVariationChanged:
    {
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
  bool condenseMoveNodes = self.nodeTreeViewMetrics.condenseMoveNodes;
  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.nodeTreeViewMetrics.tileSize];

  UIColor* normalLineColor = self.nodeTreeViewMetrics.normalLineColor;
  UIColor* selectedLineColor = self.nodeTreeViewMetrics.selectedLineColor;

  CGFloat normalLineWidth = self.nodeTreeViewMetrics.normalLineWidth;
  CGFloat selectedLineWidth = self.nodeTreeViewMetrics.selectedLineWidth;

  for (NodeTreeViewCellPosition* position in self.drawingCellsOnTile)
  {
    NodeTreeViewCell* cell = [self.nodeTreeViewCanvas cellAtPosition:position];
    if (! cell || cell.lines == NodeTreeViewCellLineNone)
      continue;

    NodeTreeViewCellLines lines = cell.lines;
    NodeTreeViewCellLines linesSelected = cell.linesSelectedGameVariation;

    CGRect canvasRectForCell = [NodeTreeViewDrawingHelper canvasRectForCellAtPosition:position metrics:self.nodeTreeViewMetrics];

    // If we are drawing exactly within the cell boundaries then diagonal
    // branching lines of two diagonally adjacent cells do not join seamlessly
    // at the corner points because the joining is clipped by the cell rectangle
    // boundaries. This is especially visible for selected lines because they
    // are wider than normal lines.
    //
    // Two diagonal lines from different    The same two lines where the joining
    // cells joining seamlessly             is clipped by the cell rectangle
    //     o                                    o  |
    //    / \                                  / \ |
    //   o   \                                o   \|
    //    \   \                                \   |
    //     \   o                                \  |o
    //      \ / o                           -------+ o
    //       o / \                                o +-------
    //        o   \                                o|  \
    //         \   \                                |   \
    //          \   o                               |\   o
    //           \ /                                | \ /
    //            o                                 |  o
    //
    // By making the rectangle slightly larger we allow the lines drawing to
    // take place sightly outside of the area that is strictly necessary. This
    // causes the lines drawn for adjacent cells to slightly overlap, which for
    // diagonal lines makes sure that the clipped line endings are not visible
    // because they are covered by the overlapping. We are using the selected
    // line width to enlarge the rectangle because it is wider than the regular
    // line width, so both line types can be safely drawn.
    //
    // Notes:
    // - We have to enlarge the canvas rect, not the drawing rect, because the
    //   canvas rect may be used for setting up a clipping path.
    // - Enlarging the cell rectangle is necessary only if diagonally adjacent
    //   cell rectangles are square, because only then are lines joined in the
    //   corners of the cell rectangles. If "condense move nodes" is enabled,
    //   cell rectangles are NOT square, hence no enlargement is needed. In fact
    //   enlargement must NOT be done, because it would change the aspect ratio
    //   of the cell rectangle, which would cause lines to not join at all.
    if (! condenseMoveNodes)
      canvasRectForCell = CGRectInset(canvasRectForCell, -selectedLineWidth, -selectedLineWidth);

    CGRect drawingRectForCell = [CGDrawingHelper drawingRectFromCanvasRect:canvasRectForCell
                                                            inTileWithRect:tileRect];
    CGPoint centerOfDrawingRectForCell = CGPointMake(CGRectGetMidX(drawingRectForCell), CGRectGetMidY(drawingRectForCell));

    bool didSetClippingPath = false;
    enum NodeTreeViewCellSymbol symbol = cell.symbol;
    if (symbol != NodeTreeViewCellSymbolNone &&
        symbol != NodeTreeViewCellSymbolBlackMove &&
        symbol != NodeTreeViewCellSymbolWhiteMove)
    {
      [self setClippingPathInContext:context
                                cell:cell
                            position:position
                   canvasRectForCell:canvasRectForCell
                   condenseMoveNodes:condenseMoveNodes
                            tileRect:tileRect];
      didSetClippingPath = true;
    }

    if (lines & NodeTreeViewCellLineCenterToLeft)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToLeft;
      [CGDrawingHelper drawLineWithContext:context
                                 fromPoint:CGPointMake(drawingRectForCell.origin.x, centerOfDrawingRectForCell.y)
                                   toPoint:centerOfDrawingRectForCell
                               strokeColor:isLineSelected ? selectedLineColor : normalLineColor
                           strokeLineWidth:isLineSelected ? selectedLineWidth : normalLineWidth];
    }

    if (lines & NodeTreeViewCellLineCenterToRight)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToRight;
      [CGDrawingHelper drawLineWithContext:context
                                 fromPoint:centerOfDrawingRectForCell
                                   toPoint:CGPointMake(CGRectGetMaxX(drawingRectForCell), centerOfDrawingRectForCell.y)
                               strokeColor:isLineSelected ? selectedLineColor : normalLineColor
                           strokeLineWidth:isLineSelected ? selectedLineWidth : normalLineWidth];
    }

    if (lines & NodeTreeViewCellLineCenterToTop)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToTop;
      [CGDrawingHelper drawLineWithContext:context
                                 fromPoint:CGPointMake(centerOfDrawingRectForCell.x, drawingRectForCell.origin.y)
                                   toPoint:centerOfDrawingRectForCell
                               strokeColor:isLineSelected ? selectedLineColor : normalLineColor
                           strokeLineWidth:isLineSelected ? selectedLineWidth : normalLineWidth];
    }

    if (lines & NodeTreeViewCellLineCenterToBottom)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToBottom;
      [CGDrawingHelper drawLineWithContext:context
                                 fromPoint:centerOfDrawingRectForCell
                                   toPoint:CGPointMake(centerOfDrawingRectForCell.x, CGRectGetMaxY(drawingRectForCell))
                               strokeColor:isLineSelected ? selectedLineColor : normalLineColor
                           strokeLineWidth:isLineSelected ? selectedLineWidth : normalLineWidth];
    }

    if (lines & NodeTreeViewCellLineCenterToTopLeft)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToTopLeft;
      [CGDrawingHelper drawLineWithContext:context
                                 fromPoint:drawingRectForCell.origin
                                   toPoint:centerOfDrawingRectForCell
                               strokeColor:isLineSelected ? selectedLineColor : normalLineColor
                           strokeLineWidth:isLineSelected ? selectedLineWidth : normalLineWidth];
    }

    if (lines & NodeTreeViewCellLineCenterToBottomRight)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToBottomRight;
      [CGDrawingHelper drawLineWithContext:context
                                 fromPoint:centerOfDrawingRectForCell
                                   toPoint:CGPointMake(CGRectGetMaxX(drawingRectForCell), CGRectGetMaxY(drawingRectForCell))
                               strokeColor:isLineSelected ? selectedLineColor : normalLineColor
                           strokeLineWidth:isLineSelected ? selectedLineWidth : normalLineWidth];
    }

    if (didSetClippingPath)
    {
      [self removeClippingPathInContext:context];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
///
/// This method set a clipping path that prevents lines (or anything else) from
/// being drawn within the area where the node symbol is drawn by the node
/// symbol layer. We can't rely on the symbol covering any lines that are drawn
/// within the symbol area because many symbols contain transparent parts.
// -----------------------------------------------------------------------------
- (void) setClippingPathInContext:(CGContextRef)context
                             cell:(NodeTreeViewCell*)cell
                         position:(NodeTreeViewCellPosition*)position
                canvasRectForCell:(CGRect)canvasRectForCell
                condenseMoveNodes:(bool)condenseMoveNodes
                         tileRect:(CGRect)tileRect
{
  CGRect canvasRectForFullCell;
  CGSize symbolSize;
  if (cell.isMultipart)
  {
    canvasRectForFullCell = [NodeTreeViewDrawingHelper canvasRectForMultipartCellPart:cell.part
                                                                         partPosition:position
                                                                              metrics:self.nodeTreeViewMetrics];
    symbolSize = self.nodeTreeViewMetrics.uncondensedNodeSymbolSize;
  }
  else
  {
    canvasRectForFullCell = canvasRectForCell;
    if (condenseMoveNodes)
      symbolSize = self.nodeTreeViewMetrics.condensedNodeSymbolSize;
    else
      symbolSize = self.nodeTreeViewMetrics.uncondensedNodeSymbolSize;
  }

  CGRect drawingRectForFullCell = [CGDrawingHelper drawingRectFromCanvasRect:canvasRectForFullCell
                                                              inTileWithRect:tileRect];
  CGPoint centerOfDrawingRectForFullCell = CGPointMake(CGRectGetMidX(drawingRectForFullCell),
                                                       CGRectGetMidY(drawingRectForFullCell));
  CGFloat clippingRadius = MIN(symbolSize.width, symbolSize.height) / 2.0;

  [CGDrawingHelper setCircularClippingPathWithContext:context
                                               center:centerOfDrawingRectForFullCell
                                               radius:clippingRadius
                                       outerRectangle:drawingRectForFullCell];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
///
/// Removes a previously configured node symbol clipping path from the
/// drawing context @a context. Invocation of this method balances a previous
/// invocation of the
/// setClippingPathInContext:cell:position:canvasRectForCell:condenseMoveNodes:tileRect:()
/// method.
// -----------------------------------------------------------------------------
- (void) removeClippingPathInContext:(CGContextRef)context
{
  [CGDrawingHelper removeClippingPathWithContext:context];
}

@end
