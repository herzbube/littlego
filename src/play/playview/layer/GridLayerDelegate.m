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
#import "GridLayerDelegate.h"
#import "PlayViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GridLayerDelegate.
// -----------------------------------------------------------------------------
@interface GridLayerDelegate()
@property(nonatomic, assign) CGLayerRef normalLineLayer;
@property(nonatomic, assign) CGLayerRef boundingLineLayer;
@end


@implementation GridLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a GridLayerDelegate object.
///
/// @note This is the designated initializer of GridLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithMainView:(UIView*)mainView metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (PlayViewLayerDelegateBase)
  self = [super initWithMainView:mainView metrics:metrics];
  if (! self)
    return nil;
  _normalLineLayer = nil;
  _boundingLineLayer = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GridLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
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
  GoPoint* pointA1 = [[GoGame sharedGame].board pointAtVertex:@"A1"];
  if (! pointA1)
    return;
  DDLogVerbose(@"GridLayerDelegate is drawing");

  if (! _normalLineLayer)
  {
    _normalLineLayer = CreateLineLayer(context,
                                       self.playViewMetrics.lineColor,
                                       self.playViewMetrics.normalLineWidth,
                                       self.playViewMetrics);
  }
  if (! _boundingLineLayer)
  {
    _boundingLineLayer = CreateLineLayer(context,
                                        self.playViewMetrics.lineColor,
                                        self.playViewMetrics.boundingLineWidth,
                                        self.playViewMetrics);
  }

  for (int lineDirection = 0; lineDirection < 2; ++lineDirection)
  {
    bool isHorizontalLine = (0 == lineDirection) ? true : false;
    GoPoint* previousPoint = nil;
    GoPoint* currentPoint = pointA1;
    while (currentPoint)
    {
      GoPoint* nextPoint;
      if (isHorizontalLine)
        nextPoint = currentPoint.above;
      else
        nextPoint = currentPoint.right;

      CGLayerRef lineLayer;
      bool isBoundingLine = (nil == previousPoint || nil == nextPoint);
      if (isBoundingLine)
        lineLayer = _boundingLineLayer;
      else
        lineLayer = _normalLineLayer;
      [PlayViewDrawingHelper drawLineLayer:lineLayer withContext:context horizontal:isHorizontalLine positionedAtPoint:currentPoint withMetrics:self.playViewMetrics];

      previousPoint = currentPoint;
      currentPoint = nextPoint;
    }
  }
}

@end
