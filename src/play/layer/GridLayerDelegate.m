// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "GridLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GridLayerDelegate.
// -----------------------------------------------------------------------------
@interface GridLayerDelegate()
@end


@implementation GridLayerDelegate


// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case PVLDEventRectangleChanged:
    {
      self.layer.frame = self.playViewMetrics.rect;
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // board size possibly changes
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
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  enum GoBoardSize boardSize = self.playViewMetrics.boardSize;
  if (GoBoardSizeUndefined == boardSize)
    return;

  // Bounding grid lines are usually thicker than normal grid lines. We add
  // the surplus thickness to the outside of the normal board boundary.
  int boundingLineWidthSurplus = self.playViewModel.boundingLineWidth - self.playViewModel.normalLineWidth;
  assert(boundingLineWidthSurplus >= 0);

  // Two iterations for the two directions horizontal and vertical
  for (int lineDirection = 0; lineDirection < 2; ++lineDirection)
  {
    CGPoint lineStartPoint = CGPointMake(self.playViewMetrics.topLeftPointX, self.playViewMetrics.topLeftPointY);

    bool drawHorizontalLine = (0 == lineDirection) ? true : false;
    if (drawHorizontalLine)
      lineStartPoint.x -= boundingLineWidthSurplus;
    else
      lineStartPoint.y -= boundingLineWidthSurplus;

    for (int lineCounter = 0; lineCounter < boardSize; ++lineCounter)
    {
      // -1 because the end point will also be stroked
      CGPoint lineEndPoint = lineStartPoint;
      if (drawHorizontalLine)
        lineEndPoint.x += self.playViewMetrics.lineLength - 1;
      else
        lineEndPoint.y += self.playViewMetrics.lineLength - 1;

      int lineWidth;
      if (0 == lineCounter || (boardSize - 1) == lineCounter)
        lineWidth = self.playViewModel.boundingLineWidth;
      else
        lineWidth = self.playViewModel.normalLineWidth;

      [self drawLine:context
          startPoint:lineStartPoint
            endPoint:lineEndPoint
               color:self.playViewModel.lineColor
               width:lineWidth];

      if (drawHorizontalLine)
        lineStartPoint.y += self.playViewMetrics.pointDistance;
      else
        lineStartPoint.x += self.playViewMetrics.pointDistance;
    }
  }
}

@end
