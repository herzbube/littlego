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
#import "CrossHairStoneLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../model/PlayViewModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for CrossHairStoneLayerDelegate.
// -----------------------------------------------------------------------------
@interface CrossHairStoneLayerDelegate()
- (void) releaseStoneLayers;
@property(nonatomic, assign) CGLayerRef blackStoneLayer;
@property(nonatomic, assign) CGLayerRef whiteStoneLayer;
@property(nonatomic, assign) CGLayerRef crossHairStoneLayer;
@end


@implementation CrossHairStoneLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairStoneLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairStoneLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithMainView:(UIView*)mainView metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithMainView:mainView metrics:metrics model:model];
  if (! self)
    return nil;
  self.crossHairPoint = nil;
  _blackStoneLayer = NULL;
  _whiteStoneLayer = NULL;
  _crossHairStoneLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrossHairStoneLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crossHairPoint = nil;
  [self releaseStoneLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases stone layers if they are currently allocated. Otherwise does
/// nothing.
// -----------------------------------------------------------------------------
- (void) releaseStoneLayers
{
  if (_blackStoneLayer)
  {
    CGLayerRelease(_blackStoneLayer);
    _blackStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (_whiteStoneLayer)
  {
    CGLayerRelease(_whiteStoneLayer);
    _whiteStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (_crossHairStoneLayer)
  {
    CGLayerRelease(_crossHairStoneLayer);
    _crossHairStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
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
      [self releaseStoneLayers];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change -> need to recalculate size of cross-hair stone
    {
      [self releaseStoneLayers];
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
  DDLogVerbose(@"CrossHairStoneLayerDelegate is drawing");

  if (! _blackStoneLayer)
    _blackStoneLayer = CreateStoneLayerWithImage(context, stoneBlackImageResource, self.playViewMetrics);
  if (! _whiteStoneLayer)
    _whiteStoneLayer = CreateStoneLayerWithImage(context, stoneWhiteImageResource, self.playViewMetrics);
  if (! _crossHairStoneLayer)
    _crossHairStoneLayer = CreateStoneLayerWithImage(context, stoneCrosshairImageResource, self.playViewMetrics);

  CGLayerRef stoneLayer;
  if (self.crossHairPoint.hasStone)
    stoneLayer = _crossHairStoneLayer;
  else
  {
    GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
    if (boardPosition.currentPlayer.isBlack)
      stoneLayer = _blackStoneLayer;
    else
      stoneLayer = _whiteStoneLayer;
  }
  [self.playViewMetrics drawLayer:stoneLayer withContext:context centeredAtPoint:self.crossHairPoint];
}

@end
