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
#import "StarPointsLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for StarPointsLayerDelegate.
// -----------------------------------------------------------------------------
@interface StarPointsLayerDelegate()
@end


@implementation StarPointsLayerDelegate


// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
	CGContextSetFillColorWithColor(context, self.playViewModel.starPointColor.CGColor);
  
  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  for (GoPoint* starPoint in [GoGame sharedGame].board.starPoints)
  {
    struct GoVertexNumeric numericVertex = starPoint.vertex.numeric;
    int starPointCenterPointX = self.playViewMetrics.topLeftPointX + (self.playViewMetrics.pointDistance * (numericVertex.x - 1));
    int starPointCenterPointY = self.playViewMetrics.topLeftPointY + (self.playViewMetrics.pointDistance * (numericVertex.y - 1));
    CGContextAddArc(context, starPointCenterPointX + gHalfPixel, starPointCenterPointY + gHalfPixel, self.playViewModel.starPointRadius, startRadius, endRadius, clockwise);
    CGContextFillPath(context);
  }
}

@end
