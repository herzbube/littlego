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
#import "CrossHairStoneLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"


CGLayerRef blackStoneLayer;
CGLayerRef whiteStoneLayer;
CGLayerRef crossHairStoneLayer;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// CrossHairStoneLayerDelegate.
// -----------------------------------------------------------------------------
@interface BVCrossHairStoneLayerDelegate()
/// @brief Refers to the GoPoint object that marks the focus of the cross-hair.
@property(nonatomic, retain) GoPoint* crossHairPoint;
@end


@implementation BVCrossHairStoneLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairStoneLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairStoneLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTileView:(BoardTileView*)tileView metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTileView:tileView metrics:metrics];
  if (! self)
    return nil;
  self.crossHairPoint = nil;
  blackStoneLayer = NULL;
  whiteStoneLayer = NULL;
  crossHairStoneLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrossHairStoneLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crossHairPoint = nil;
  [self invalidateLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates stone layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  if (blackStoneLayer)
  {
    CGLayerRelease(blackStoneLayer);
    blackStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (whiteStoneLayer)
  {
    CGLayerRelease(whiteStoneLayer);
    whiteStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (crossHairStoneLayer)
  {
    CGLayerRelease(crossHairStoneLayer);
    crossHairStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegateBase method.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case BVLDEventRectangleChanged:
    {
      CGRect layerFrame = CGRectZero;
      layerFrame.size = self.playViewMetrics.tileSize;
      self.layer.frame = layerFrame;
      [self invalidateLayers];
      self.dirty = true;
      break;
    }
    case BVLDEventBoardSizeChanged:
    {
      [self invalidateLayers];
      self.dirty = true;
      break;      
    }
    case BVLDEventCrossHairChanged:
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

  if (! blackStoneLayer)
    blackStoneLayer = BVCreateStoneLayerWithImage(context, stoneBlackImageResource, self.playViewMetrics);
  if (! whiteStoneLayer)
    whiteStoneLayer = BVCreateStoneLayerWithImage(context, stoneWhiteImageResource, self.playViewMetrics);
  if (! crossHairStoneLayer)
    crossHairStoneLayer = BVCreateStoneLayerWithImage(context, stoneCrosshairImageResource, self.playViewMetrics);

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];

  CGLayerRef stoneLayer;
  if (self.crossHairPoint.hasStone)
    stoneLayer = crossHairStoneLayer;
  else
  {
    GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
    if (boardPosition.currentPlayer.isBlack)
      stoneLayer = blackStoneLayer;
    else
      stoneLayer = whiteStoneLayer;
  }
  [BoardViewDrawingHelper drawLayer:stoneLayer
                        withContext:context
                    centeredAtPoint:self.crossHairPoint
                     inTileWithRect:tileRect
                        withMetrics:self.playViewMetrics];
}

@end
