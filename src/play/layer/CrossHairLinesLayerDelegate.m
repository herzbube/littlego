// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for CrossHairLinesLayerDelegate.
// -----------------------------------------------------------------------------
@interface CrossHairLinesLayerDelegate()
- (void) releaseLineLayers;
@property(nonatomic, assign) CGLayerRef normalLineLayer;
@property(nonatomic, assign) CGLayerRef boundingLineLayer;
@end


@implementation CrossHairLinesLayerDelegate

@synthesize crossHairPoint;
@synthesize normalLineLayer;
@synthesize boundingLineLayer;


// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairLinesLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairLinesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:model];
  if (! self)
    return nil;
  self.crossHairPoint = nil;
  self.normalLineLayer = nil;
  self.boundingLineLayer = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrossHairLinesLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crossHairPoint = nil;
  [self releaseLineLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases line layers if they are currently allocated. Otherwise does
/// nothing.
// -----------------------------------------------------------------------------
- (void) releaseLineLayers
{
  if (self.normalLineLayer)
  {
    CGLayerRelease(self.normalLineLayer);
    self.normalLineLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (self.boundingLineLayer)
  {
    CGLayerRelease(self.boundingLineLayer);
    self.boundingLineLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
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
      [self releaseLineLayers];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change -> need to recalculate length of grid lines
    {
      [self releaseLineLayers];
      self.dirty = true;
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
  if (! self.normalLineLayer)
  {
    self.normalLineLayer = [self.playViewMetrics lineLayerWithContext:context
                                                            lineColor:self.playViewModel.crossHairColor
                                                            lineWidth:self.playViewModel.normalLineWidth];
  }
  if (! self.boundingLineLayer)
  {
    self.boundingLineLayer = [self.playViewMetrics lineLayerWithContext:context
                                                              lineColor:self.playViewModel.crossHairColor
                                                              lineWidth:self.playViewModel.boundingLineWidth];
  }

  struct GoVertexNumeric numericVertex = self.crossHairPoint.vertex.numeric;
  CGLayerRef horizontalLineLayer;
  bool isBoundingLineHorizontal = (1 == numericVertex.y || self.playViewMetrics.boardSize == numericVertex.y);
  if (isBoundingLineHorizontal)
    horizontalLineLayer = self.boundingLineLayer;
  else
    horizontalLineLayer = self.normalLineLayer;
  CGLayerRef verticalLineLayer;
  bool isBoundingLineVertical = (1 == numericVertex.x || self.playViewMetrics.boardSize == numericVertex.x);
  if (isBoundingLineVertical)
    verticalLineLayer = self.boundingLineLayer;
  else
    verticalLineLayer = self.normalLineLayer;

  [self.playViewMetrics drawLineLayer:horizontalLineLayer withContext:context horizontal:true positionedAtPoint:self.crossHairPoint];
  [self.playViewMetrics drawLineLayer:verticalLineLayer withContext:context horizontal:false positionedAtPoint:self.crossHairPoint];
}

@end
