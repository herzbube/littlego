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

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for CrossHairLayerDelegate.
// -----------------------------------------------------------------------------
@interface CrossHairLayerDelegate()
- (void) releaseStoneLayer;
- (void) drawCrossHairLines:(CGContextRef)context;
@property(nonatomic, assign) CGLayerRef crossHairStoneLayer;
@end


@implementation CrossHairLayerDelegate

@synthesize crossHairPoint;
@synthesize crossHairStoneLayer;


// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:model];
  if (! self)
    return nil;
  
  self.crossHairStoneLayer = NULL;
  
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrossHairLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseStoneLayer];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases stone layer if it is currently allocated. Otherwise does
/// nothing.
// -----------------------------------------------------------------------------
- (void) releaseStoneLayer
{
  if (self.crossHairStoneLayer)
  {
    CGLayerRelease(self.crossHairStoneLayer);
    self.crossHairStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
}

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
      [self releaseStoneLayer];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change -> need to recalculate size of cross-hair stone
    {
      [self releaseStoneLayer];
      break;      
    }
    case PVLDEventCrossHairChanged:
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
  if (! self.crossHairStoneLayer)
    self.crossHairStoneLayer = [self.playViewMetrics stoneLayerWithContext:context stoneColor:self.playViewModel.crossHairColor];

  [self.playViewMetrics drawLayer:self.crossHairStoneLayer withContext:context centeredAtPoint:self.crossHairPoint];
  [self drawCrossHairLines:context];
}

// -----------------------------------------------------------------------------
/// @brief Draws the lines that make up the actual cross-hair.
// -----------------------------------------------------------------------------
- (void) drawCrossHairLines:(CGContextRef)context
{
  CGPoint crossHairCenter = [self.playViewMetrics coordinatesFromPoint:self.crossHairPoint];
  struct GoVertexNumeric vertexNumeric = self.crossHairPoint.vertex.numeric;

  // Bounding grid lines are usually thicker than normal grid lines. We add
  // the surplus thickness to the outside of the normal board boundary.
  int boundingLineWidthSurplus = self.playViewModel.boundingLineWidth - self.playViewModel.normalLineWidth;
  assert(boundingLineWidthSurplus >= 0);

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
      lineStartPoint.x -= boundingLineWidthSurplus;
      lineEndPoint.x = lineStartPoint.x + self.playViewMetrics.lineLength;
      if (1 == vertexNumeric.y || self.playViewMetrics.boardSize == vertexNumeric.y)
        lineWidth = self.playViewModel.boundingLineWidth;
    }
    else
    {
      lineStartPoint.y = self.playViewMetrics.topLeftPointY;
      lineStartPoint.y -= boundingLineWidthSurplus;
      lineEndPoint.y = lineStartPoint.y + self.playViewMetrics.lineLength;
      if (1 == vertexNumeric.x || self.playViewMetrics.boardSize == vertexNumeric.x)
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
