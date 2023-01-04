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
#import "LinesLayerDelegate.h"
//#import "NodeTreeViewCGLayerCache.h"
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
  // There are times when no LinesLayerDelegate instances are around to
  // react to events that invalidate the cached CGLayers, so the cached CGLayers
  // will inevitably become out-of-date. To prevent this, we invalidate the
  // CGLayers *NOW*.
  // TODO xxx is this needed?
//  [self invalidateLayers];

  self.nodeTreeViewCanvas = nil;
  self.drawingCellsOnTile = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates node symbol layers.
// -----------------------------------------------------------------------------
// TODO xxx remove if not needed
//- (void) invalidateLayers
//{
//  NodeTreeViewCGLayerCache* cache = [NodeTreeViewCGLayerCache sharedCache];
//  // TODO xxx As long as the only layers are for node symbols this is correct
//  [cache invalidateAllLayers];
//}

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
      self.drawingCellsOnTile = [self calculateDrawingCellsOnTile];
      self.dirty = true;
      break;
    }
    case NTVLDEventAbstractCanvasSizeChanged:
    {
      NSArray* newDrawingCellsOnTile = [self calculateDrawingCellsOnTile];
      if (! [self.drawingCellsOnTile isEqualToArray:newDrawingCellsOnTile])
      {
        self.drawingCellsOnTile = newDrawingCellsOnTile;
        self.dirty = true;
      }
      break;
    }
    case NTVLDEventNodeTreeContentChanged:
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
//    return;
  }
  else if (row == 1 && column == 0)
  {
    int i = 99;
//    return;
  }
  else if (row == 1 && column == 1)
  {
    int i = 99;
//    return;
  }
  else
  {
//    return;
  }

  bool condenseMoveNodes = self.nodeTreeViewMetrics.condenseMoveNodes;
  CGRect tileRect = [NodeTreeViewDrawingHelper canvasRectForTile:self.tile
                                                         metrics:self.nodeTreeViewMetrics];

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
    CGRect drawingRectForCell = canvasRectForCell;
    // TODO xxx do we have a method in drawing helper for this?
    drawingRectForCell.origin.x = canvasRectForCell.origin.x - tileRect.origin.x;
    drawingRectForCell.origin.y = canvasRectForCell.origin.y - tileRect.origin.y;
    CGPoint centerOfDrawingRectForCell = CGPointMake(CGRectGetMidX(drawingRectForCell), CGRectGetMidY(drawingRectForCell));

    bool didSetClippingPath = false;
    if (cell.symbol != NodeTreeViewCellSymbolNone)
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
      [self drawLineFromPoint:CGPointMake(drawingRectForCell.origin.x, centerOfDrawingRectForCell.y)
                      toPoint:centerOfDrawingRectForCell
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    if (lines & NodeTreeViewCellLineCenterToRight)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToRight;
      [self drawLineFromPoint:centerOfDrawingRectForCell
                      toPoint:CGPointMake(CGRectGetMaxX(drawingRectForCell), centerOfDrawingRectForCell.y)
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    if (lines & NodeTreeViewCellLineCenterToTop)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToTop;
      [self drawLineFromPoint:CGPointMake(centerOfDrawingRectForCell.x, drawingRectForCell.origin.y)
                      toPoint:centerOfDrawingRectForCell
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    if (lines & NodeTreeViewCellLineCenterToBottom)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToBottom;
      [self drawLineFromPoint:centerOfDrawingRectForCell
                      toPoint:CGPointMake(centerOfDrawingRectForCell.x, CGRectGetMaxY(drawingRectForCell))
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    if (lines & NodeTreeViewCellLineCenterToTopLeft)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToTopLeft;
      [self drawLineFromPoint:drawingRectForCell.origin
                      toPoint:centerOfDrawingRectForCell
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    if (lines & NodeTreeViewCellLineCenterToBottomRight)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToBottomRight;
      [self drawLineFromPoint:centerOfDrawingRectForCell
                      toPoint:CGPointMake(CGRectGetMaxX(drawingRectForCell), CGRectGetMaxY(drawingRectForCell))
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    if (didSetClippingPath)
    {
      [self removeClippingPathInContext:context];
    }
  }
}

// TODO xxx document
// The goal is that lines are not drawn within the area where the node symbol
// is drawn by another layer
- (void) setClippingPathInContext:(CGContextRef)context
                             cell:(NodeTreeViewCell*)cell
                         position:(NodeTreeViewCellPosition*)position
                canvasRectForCell:(CGRect)canvasRectForCell
                condenseMoveNodes:condenseMoveNodes
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

  CGRect drawingRectForFullCell = canvasRectForFullCell;
  // TODO xxx do we have a method in drawing helper for this?
  drawingRectForFullCell.origin.x = canvasRectForFullCell.origin.x - tileRect.origin.x;
  drawingRectForFullCell.origin.y = canvasRectForFullCell.origin.y - tileRect.origin.y;
  CGPoint centerOfDrawingRectForFullCell = CGPointMake(CGRectGetMidX(drawingRectForFullCell),
                                                       CGRectGetMidY(drawingRectForFullCell));
  CGFloat clippingRadius = MIN(symbolSize.width, symbolSize.height) / 2.0;

  [CGDrawingHelper setCircularClippingPathWithContext:context
                                               center:centerOfDrawingRectForFullCell
                                               radius:clippingRadius
                                       outerRectangle:drawingRectForFullCell];
}

// TODO xxx document
- (void) removeClippingPathInContext:(CGContextRef)context
{
  [CGDrawingHelper removeClippingPathWithContext:context];
}

// TODO xxx document
- (void) drawLineFromPoint:(CGPoint)lineStartPoint
                   toPoint:(CGPoint)lineEndPoint
                 withColor:(UIColor*)lineColor
                 withWidth:(CGFloat)lineWidth
                 inContext:(CGContextRef)context
{
  // TODO xxx intersection of drawing rect with tile rect => see GridLinesLayerDelegate

  CGContextBeginPath(context);

  CGContextMoveToPoint(context, lineStartPoint.x, lineStartPoint.y);
  CGContextAddLineToPoint(context, lineEndPoint.x, lineEndPoint.y);

  CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
  CGContextSetLineWidth(context, lineWidth);
  CGContextStrokePath(context);
}

@end
