// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
  _normalLineLayer = nil;
  _boundingLineLayer = nil;
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
  if (_normalLineLayer)
  {
    CGLayerRelease(_normalLineLayer);
    _normalLineLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (_boundingLineLayer)
  {
    CGLayerRelease(_boundingLineLayer);
    _boundingLineLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
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
  DDLogVerbose(@"CrossHairLinesLayerDelegate is drawing");

  if (! _normalLineLayer)
  {
    _normalLineLayer = CreateLineLayer(context,
                                       self.playViewModel.crossHairColor,
                                       self.playViewModel.normalLineWidth,
                                       self.playViewMetrics);
  }
  if (! _boundingLineLayer)
  {
    _boundingLineLayer = CreateLineLayer(context,
                                         self.playViewModel.crossHairColor,
                                         self.playViewModel.boundingLineWidth,
                                         self.playViewMetrics);
  }

  struct GoVertexNumeric numericVertex = self.crossHairPoint.vertex.numeric;
  CGLayerRef horizontalLineLayer;
  bool isBoundingLineHorizontal = (1 == numericVertex.y || self.playViewMetrics.boardSize == numericVertex.y);
  if (isBoundingLineHorizontal)
    horizontalLineLayer = _boundingLineLayer;
  else
    horizontalLineLayer = _normalLineLayer;
  CGLayerRef verticalLineLayer;
  bool isBoundingLineVertical = (1 == numericVertex.x || self.playViewMetrics.boardSize == numericVertex.x);
  if (isBoundingLineVertical)
    verticalLineLayer = _boundingLineLayer;
  else
    verticalLineLayer = _normalLineLayer;

  [self.playViewMetrics drawLineLayer:horizontalLineLayer withContext:context horizontal:true positionedAtPoint:self.crossHairPoint];
  [self.playViewMetrics drawLineLayer:verticalLineLayer withContext:context horizontal:false positionedAtPoint:self.crossHairPoint];
}

@end
