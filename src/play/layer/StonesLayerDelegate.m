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
#import "StonesLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardRegion.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for StonesLayerDelegate.
// -----------------------------------------------------------------------------
@interface StonesLayerDelegate()
- (void) drawStone:(CGContextRef)context color:(UIColor*)color point:(GoPoint*)point;
- (void) drawStone:(CGContextRef)context color:(UIColor*)color vertex:(GoVertex*)vertex;
- (void) drawStone:(CGContextRef)context color:(UIColor*)color vertexX:(int)vertexX vertexY:(int)vertexY;
- (void) drawEmpty:(CGContextRef)context point:(GoPoint*)point;
@end


@implementation StonesLayerDelegate


// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    if (point.hasStone)
    {
      UIColor* color;
      if (point.blackStone)
        color = [UIColor blackColor];
      else
        color = [UIColor whiteColor];
      [self drawStone:context color:color vertex:point.vertex];
    }
    else
    {
      // TODO remove this or make it into something that can be turned on
      // at runtime for debugging
//      [self drawEmpty:context point:point];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Draws a single stone at intersection @a point, using color @a color.
// -----------------------------------------------------------------------------
- (void) drawStone:(CGContextRef)context color:(UIColor*)color point:(GoPoint*)point
{
  [self drawStone:context color:color vertex:point.vertex];
}

// -----------------------------------------------------------------------------
/// @brief Draws a single stone at intersection @a vertex, using color @a color.
// -----------------------------------------------------------------------------
- (void) drawStone:(CGContextRef)context color:(UIColor*)color vertex:(GoVertex*)vertex
{
  struct GoVertexNumeric numericVertex = vertex.numeric;
  [self drawStone:context color:color vertexX:numericVertex.x vertexY:numericVertex.y];
}

// -----------------------------------------------------------------------------
/// @brief Draws a single stone at the intersection identified by @a vertexX
/// and @a vertexY, using color @a color.
// -----------------------------------------------------------------------------
- (void) drawStone:(CGContextRef)context color:(UIColor*)color vertexX:(int)vertexX vertexY:(int)vertexY
{
  [self drawStone:context color:color coordinates:[self.playViewMetrics coordinatesFromVertexX:vertexX vertexY:vertexY]];
}

// -----------------------------------------------------------------------------
/// @brief Draws a small circle at intersection @a point, when @a point does
/// not have a stone on it. The color of the circle is different for different
/// regions.
///
/// This method is a debugging aid to see how GoBoardRegions are calculated.
// -----------------------------------------------------------------------------
- (void) drawEmpty:(CGContextRef)context point:(GoPoint*)point
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  CGPoint coordinates = [self.playViewMetrics coordinatesFromVertexX:numericVertex.x vertexY:numericVertex.y];
	CGContextSetFillColorWithColor(context, point.region.randomColor.CGColor);
  
  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  int circleRadius = floor(self.playViewMetrics.stoneRadius / 2);
  CGContextAddArc(context, coordinates.x + gHalfPixel, coordinates.y + gHalfPixel, circleRadius, startRadius, endRadius, clockwise);
  CGContextFillPath(context);
}

@end
