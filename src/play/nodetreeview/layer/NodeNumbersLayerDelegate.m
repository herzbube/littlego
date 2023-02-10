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
#import "../canvas/NodeTreeViewCanvas.h"
#import "../../../ui/CGDrawingHelper.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeNumbersLayerDelegate.
// -----------------------------------------------------------------------------
@interface NodeNumbersLayerDelegate()
@property(nonatomic, assign) NodeTreeViewCanvas* nodeTreeViewCanvas;
@property(nonatomic, retain) NSArray* drawingCellsOnTile;
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
/// @brief Deallocates memory allocated by this NodeNumbersLayerDelegate object.
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
      self.drawingCellsOnTile = [self calculateNodeNumberViewDrawingCellsOnTile];
      self.dirty = true;
      break;
    }
    case NTVLDEventAbstractCanvasSizeChanged:
    {
      NSArray* newDrawingCellsOnTile = [self calculateNodeNumberViewDrawingCellsOnTile];
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
  UIFont* nodeNumberLabelFont = self.nodeTreeViewMetrics.nodeNumberLabelFont;
  if (! nodeNumberLabelFont)
    return;

  NSDictionary* textAttributes = @{ NSFontAttributeName : nodeNumberLabelFont,
                                    NSForegroundColorAttributeName : self.nodeTreeViewMetrics.nodeNumberTextColor,
                                    NSShadowAttributeName: self.nodeTreeViewMetrics.whiteTextShadow };

  CGRect tileRect = [NodeTreeViewDrawingHelper canvasRectForTile:self.tile
                                                         metrics:self.nodeTreeViewMetrics];

  for (NodeTreeViewCellPosition* position in self.drawingCellsOnTile)
  {
    int nodeNumber = [self.nodeTreeViewCanvas nodeNumberAtPosition:position];
    if (nodeNumber == -1)
      continue;

    NSString* nodeNumberText = [NSString stringWithFormat:@"%d", nodeNumber];

    CGRect canvasRect = [NodeTreeViewDrawingHelper canvasRectForNodeNumberCellAtPosition:position
                                                                                 metrics:self.nodeTreeViewMetrics];
    CGRect drawingRect = [NodeTreeViewDrawingHelper drawingRectFromCanvasRect:canvasRect
                                                               inTileWithRect:tileRect];

    [CGDrawingHelper drawStringWithContext:context
                            centeredInRect:drawingRect
                                    string:nodeNumberText
                            textAttributes:textAttributes];
  }
}

@end
