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
#import "PlayViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// CrossHairLinesLayerDelegate.
// -----------------------------------------------------------------------------
@interface CrossHairLinesLayerDelegate()
@property(nonatomic, assign) CGLayerRef normalLineLayer;
@property(nonatomic, assign) CGLayerRef boundingLineLayer;
@end


@implementation CrossHairLinesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairLinesLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairLinesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithMainView:(UIView*)mainView metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithMainView:mainView metrics:metrics];
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
    case PVLDEventBoardSizeChanged:
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

  if (! _normalLineLayer)
  {
    _normalLineLayer = CreateLineLayer(context,
                                       self.playViewMetrics.crossHairColor,
                                       self.playViewMetrics.normalLineWidth,
                                       self.playViewMetrics);
  }
  if (! _boundingLineLayer)
  {
    _boundingLineLayer = CreateLineLayer(context,
                                         self.playViewMetrics.crossHairColor,
                                         self.playViewMetrics.boundingLineWidth,
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

  [PlayViewDrawingHelper drawLineLayer:horizontalLineLayer withContext:context horizontal:true positionedAtPoint:self.crossHairPoint withMetrics:self.playViewMetrics];
  [PlayViewDrawingHelper drawLineLayer:verticalLineLayer withContext:context horizontal:false positionedAtPoint:self.crossHairPoint withMetrics:self.playViewMetrics];
}

@end
