// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "CrossHairLinesLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// CrossHairLinesLayerDelegate.
// -----------------------------------------------------------------------------
@interface BVCrossHairLinesLayerDelegate()
/// @brief Refers to the GoPoint object that marks the focus of the cross-hair.
@property(nonatomic, retain) GoPoint* crossHairPoint;
@end


@implementation BVCrossHairLinesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairLinesLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairLinesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTileView:(BoardTileView*)tileView metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTileView:tileView metrics:metrics];
  if (! self)
    return nil;
  self.crossHairPoint = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrossHairLinesLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crossHairPoint = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegateBase method.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case BVLDEventRectangleChanged:
    {
      CGRect layerFrame = CGRectZero;
      layerFrame.size = self.playViewMetrics.tileSize;
      self.layer.frame = layerFrame;
      self.dirty = true;
      break;
    }
    case BVLDEventBoardSizeChanged:
    {
      self.dirty = true;
      break;
    }
    case BVLDEventCrossHairChanged:
    {
      self.crossHairPoint = eventInfo;
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
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  if (! self.crossHairPoint)
    return;

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];
  CGPoint crossHairPointCoordinates = [self.playViewMetrics coordinatesFromPoint:self.crossHairPoint];

  for (NSValue* lineRectValue in self.playViewMetrics.lineRectangles)
  {
    CGRect lineRect = [lineRectValue CGRectValue];
    if (! CGRectContainsPoint(lineRect, crossHairPointCoordinates))
      continue;
    CGRect drawingRect = CGRectIntersection(tileRect, lineRect);
    if (CGRectIsNull(drawingRect))
      continue;
    drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:drawingRect
                                                     inTileWithRect:tileRect];
    CGContextSetFillColorWithColor(context, self.playViewMetrics.crossHairColor.CGColor);
    CGContextFillRect(context, drawingRect);
  }
}

@end
