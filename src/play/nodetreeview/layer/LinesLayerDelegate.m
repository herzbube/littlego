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
#import "../NodeTreeViewCell.h"
#import "../NodeTreeViewCellPosition.h"
#import "../../model/NodeTreeViewMetrics.h"
#import "../../model/NodeTreeViewModel.h"
#import "../../../ui/Tile.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LinesLayerDelegate.
// -----------------------------------------------------------------------------
@interface LinesLayerDelegate()
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
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
  nodeTreeViewModel:(NodeTreeViewModel*)nodeTreeViewModel
{
  // Call designated initializer of superclass (NodeTreeViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;

  self.nodeTreeViewModel = nodeTreeViewModel;
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

  CGRect tileRect = [NodeTreeViewDrawingHelper canvasRectForTile:self.tile
                                                         metrics:self.nodeTreeViewMetrics];

  UIColor* normalLineColor = self.nodeTreeViewMetrics.normalLineColor;
  UIColor* selectedLineColor = self.nodeTreeViewMetrics.selectedLineColor;

  CGFloat horizontalLineLength = self.nodeTreeViewMetrics.nodeTreeViewCellSize.width / 2.0;
  CGFloat verticalLineLength = self.nodeTreeViewMetrics.nodeTreeViewCellSize.height / 2.0;
  CGFloat normalLineWidth = self.nodeTreeViewMetrics.normalLineWidth;
  CGFloat selectedLineWidth = self.nodeTreeViewMetrics.selectedLineWidth;

  CGSize horizontalNormalLineSize = CGSizeMake(horizontalLineLength, normalLineWidth);
  CGSize horizontalSelectedLineSize = CGSizeMake(horizontalLineLength, selectedLineWidth);
  CGSize verticalNormalLineSize = CGSizeMake(normalLineWidth, verticalLineLength);
  CGSize verticalSelectedLineSize = CGSizeMake(selectedLineWidth, verticalLineLength);

  for (NodeTreeViewCellPosition* position in self.drawingCellsOnTile)
  {
    NodeTreeViewCell* cell = [self.nodeTreeViewModel cellAtPosition:position];
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

    // TODO xxx start at bounding box of symbol if the cell contains a symbol, otherwise center is ok
    if (lines & NodeTreeViewCellLineCenterToLeft)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToLeft;
      [self drawLineFromPoint:CGPointMake(drawingRectForCell.origin.x, centerOfDrawingRectForCell.y)
                      toPoint:centerOfDrawingRectForCell
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    // TODO xxx start at bounding box of symbol if the cell contains a symbol, otherwise center is ok
    if (lines & NodeTreeViewCellLineCenterToRight)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToRight;
      [self drawLineFromPoint:centerOfDrawingRectForCell
                      toPoint:CGPointMake(CGRectGetMaxX(drawingRectForCell), centerOfDrawingRectForCell.y)
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    // TODO xxx start at bounding box of symbol if the cell contains a symbol, otherwise center is ok
    // TODO xxx start at right edge if number of cells per symbol is even, otherwise center is ok
    if (lines & NodeTreeViewCellLineCenterToTop)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToTop;
      [self drawLineFromPoint:CGPointMake(centerOfDrawingRectForCell.x, drawingRectForCell.origin.y)
                      toPoint:centerOfDrawingRectForCell
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    // TODO xxx start at bounding box of symbol if the cell contains a symbol, otherwise center is ok
    // TODO xxx start at right edge if number of cells per symbol is even, otherwise center is ok
    if (lines & NodeTreeViewCellLineCenterToBottom)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToBottom;
      [self drawLineFromPoint:centerOfDrawingRectForCell
                      toPoint:CGPointMake(centerOfDrawingRectForCell.x, CGRectGetMaxY(drawingRectForCell))
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    // TODO xxx start at bounding box of symbol if the cell contains a symbol, otherwise center is ok
    if (lines & NodeTreeViewCellLineCenterToTopLeft)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToTopLeft;
      isLineSelected = true;  // todo xxx
      [self drawLineFromPoint:drawingRectForCell.origin
                      toPoint:centerOfDrawingRectForCell
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

    if (lines & NodeTreeViewCellLineCenterToBottomRight)
    {
      bool isLineSelected = linesSelected & NodeTreeViewCellLineCenterToBottomRight;
      isLineSelected = true;  // todo xxx
      [self drawLineFromPoint:centerOfDrawingRectForCell
                      toPoint:CGPointMake(CGRectGetMaxX(drawingRectForCell), CGRectGetMaxY(drawingRectForCell))
                    withColor:isLineSelected ? selectedLineColor : normalLineColor
                    withWidth:isLineSelected ? selectedLineWidth : normalLineWidth
                    inContext:context];
    }

//    CGRect lineRect = [lineRectValue CGRectValue];
//    CGRect drawingRect = CGRectIntersection(tileRect, lineRect);
//    // Rectangles that are adjacent and share a side *do* intersect: The
//    // intersection rectangle has either zero width or zero height, depending on
//    // which side the two intersecting rectangles share. For this reason, we
//    // must check CGRectIsEmpty() in addition to CGRectIsNull().
//    if (CGRectIsNull(drawingRect) || CGRectIsEmpty(drawingRect))
//      continue;
//    drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:drawingRect
//                                                     inTileWithRect:tileRect];
//    CGContextSetFillColorWithColor(context, self.boardViewMetrics.lineColor.CGColor);
//    CGContextFillRect(context, drawingRect);

//
//    [NodeTreeViewDrawingHelper drawLayer:layer
//                             withContext:context
//                              centeredAt:position
//                          inTileWithRect:tileRect
//                             withMetrics:self.nodeTreeViewMetrics];
  }
}

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
