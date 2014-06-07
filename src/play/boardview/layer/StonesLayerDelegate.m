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
#import "StonesLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardRegion.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"
#import "../../../ui/UiUtilities.h"


CGLayerRef blackStoneLayer;
CGLayerRef whiteStoneLayer;


@implementation BVStonesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a StonesLayerDelegate object.
///
/// @note This is the designated initializer of StonesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTileView:(BoardTileView*)tileView metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTileView:tileView metrics:metrics];
  if (! self)
    return nil;
  blackStoneLayer = NULL;
  whiteStoneLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StonesLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self invalidateLayer];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the stone layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayer
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
}

// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method.
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
      [self invalidateLayer];
      self.dirty = true;
      break;
    }
    case BVLDEventGoGameStarted:  // place handicap stones
    {
      self.dirty = true;
      break;
    }
    case BVLDEventBoardSizeChanged:
    {
      [self invalidateLayer];
      self.dirty = true;
      break;      
    }
    case BVLDEventBoardPositionChanged:
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
  DDLogVerbose(@"StonesLayerDelegate is drawing");

  if (! blackStoneLayer)
    blackStoneLayer = BVCreateStoneLayerWithImage(context, stoneBlackImageResource, self.playViewMetrics);
  if (! whiteStoneLayer)
    whiteStoneLayer = BVCreateStoneLayerWithImage(context, stoneWhiteImageResource, self.playViewMetrics);

  CGRect canvasRectTile = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                                metrics:self.playViewMetrics];

  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    if (! point.hasStone)
      continue;
    CGLayerRef stoneLayer;
    if (point.blackStone)
      stoneLayer = blackStoneLayer;
    else
      stoneLayer = whiteStoneLayer;
    [BoardViewDrawingHelper drawLayer:stoneLayer
                          withContext:context
                      centeredAtPoint:point
                       inTileWithRect:canvasRectTile
                          withMetrics:self.playViewMetrics];
  }
}

@end
