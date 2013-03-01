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
#import "StarPointsLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../ui/UiUtilities.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for StarPointsLayerDelegate.
// -----------------------------------------------------------------------------
@interface StarPointsLayerDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (void) releaseLayer;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) CGLayerRef starPointLayer;
//@}
@end


@implementation StarPointsLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a StarPointsLayerDelegate object.
///
/// @note This is the designated initializer of StarPointsLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:model];
  if (! self)
    return nil;
  _starPointLayer = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StarPointsLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseLayer];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases the star point layer if it is currently allocated. Otherwise
/// does nothing.
// -----------------------------------------------------------------------------
- (void) releaseLayer
{
  if (_starPointLayer)
  {
    CGLayerRelease(_starPointLayer);
    _starPointLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
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
  if (! _starPointLayer)
    _starPointLayer = CreateStarPointLayer(context, self);

  for (GoPoint* starPoint in [GoGame sharedGame].board.starPoints)
    [self.playViewMetrics drawLayer:_starPointLayer withContext:context centeredAtPoint:starPoint];
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a star
/// point.
///
/// All sizes are taken from the current values in self.playViewMetrics.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateStarPointLayer(CGContextRef context, StarPointsLayerDelegate* delegate)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = delegate.playViewMetrics.pointCellSize;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
  const int startRadius = [UiUtilities radians:0];
  const int endRadius = [UiUtilities radians:360];
  const int clockwise = 0;
  CGContextAddArc(layerContext,
                  layerCenter.x,
                  layerCenter.y,
                  delegate.playViewModel.starPointRadius,
                  startRadius,
                  endRadius,
                  clockwise);
	CGContextSetFillColorWithColor(layerContext, delegate.playViewModel.starPointColor.CGColor);
  CGContextFillPath(layerContext);
  
  return layer;
}

@end
