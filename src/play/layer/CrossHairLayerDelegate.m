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
#import "CrossHairLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for CrossHairLayerDelegate.
// -----------------------------------------------------------------------------
@interface CrossHairLayerDelegate()
- (void) drawCrossHairPoint:(CGContextRef)context;
- (void) drawCrossHairLines:(CGContextRef)context;
@end


@implementation CrossHairLayerDelegate

@synthesize crossHairPoint;


// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  if (! self.crossHairPoint)
    return;
  [self drawCrossHairPoint:context];
  [self drawCrossHairLines:context];
}

// -----------------------------------------------------------------------------
/// @brief Draws the point at the center of the cross-hair.
// -----------------------------------------------------------------------------
- (void) drawCrossHairPoint:(CGContextRef)context
{
  CGPoint crossHairCenter = [self.playViewMetrics coordinatesFromPoint:self.crossHairPoint];
  [self drawStone:context color:self.playViewModel.crossHairColor coordinates:crossHairCenter];
}

// -----------------------------------------------------------------------------
/// @brief Draws the lines that make up the actual cross-hair.
// -----------------------------------------------------------------------------
- (void) drawCrossHairLines:(CGContextRef)context
{
  CGPoint crossHairCenter = [self.playViewMetrics coordinatesFromPoint:self.crossHairPoint];
  struct GoVertexNumeric vertexNumeric = self.crossHairPoint.vertex.numeric;

  // Two iterations for the two directions horizontal and vertical
  for (int lineDirection = 0; lineDirection < 2; ++lineDirection)
  {
    CGPoint lineStartPoint = crossHairCenter;
    CGPoint lineEndPoint = lineStartPoint;
    int lineWidth = self.playViewModel.normalLineWidth;

    bool drawHorizontalLine = (0 == lineDirection) ? true : false;
    if (drawHorizontalLine)
    {
      lineStartPoint.x = self.playViewMetrics.topLeftPointX;
      lineEndPoint.x = lineStartPoint.x + self.playViewMetrics.lineLength;
      if (0 == vertexNumeric.y || self.playViewMetrics.boardDimension == vertexNumeric.y)
        lineWidth = self.playViewModel.boundingLineWidth;
    }
    else
    {
      lineStartPoint.y = self.playViewMetrics.topLeftPointY;
      lineEndPoint.y = lineStartPoint.y + self.playViewMetrics.lineLength;
      if (0 == vertexNumeric.x || self.playViewMetrics.boardDimension == vertexNumeric.x)
        lineWidth = self.playViewModel.boundingLineWidth;
    }
    
    [self drawLine:context
        startPoint:lineStartPoint
          endPoint:lineEndPoint
             color:self.playViewModel.crossHairColor
             width:lineWidth];
  }
}

@end
