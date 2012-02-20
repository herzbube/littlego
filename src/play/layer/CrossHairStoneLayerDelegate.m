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
#import "CrossHairStoneLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
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

@synthesize crossHairPoint;
@synthesize blackStoneLayer;
@synthesize whiteStoneLayer;
@synthesize crossHairStoneLayer;


// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairStoneLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairStoneLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:model];
  if (! self)
    return nil;
  self.crossHairPoint = nil;
  self.blackStoneLayer = NULL;
  self.whiteStoneLayer = NULL;
  self.crossHairStoneLayer = NULL;
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
  if (self.blackStoneLayer)
  {
    CGLayerRelease(self.blackStoneLayer);
    self.blackStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (self.whiteStoneLayer)
  {
    CGLayerRelease(self.whiteStoneLayer);
    self.whiteStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
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
  if (! self.blackStoneLayer)
    self.blackStoneLayer = [self.playViewMetrics stoneLayerWithContext:context stoneColor:[UIColor blackColor]];
  if (! self.whiteStoneLayer)
    self.whiteStoneLayer = [self.playViewMetrics stoneLayerWithContext:context stoneColor:[UIColor whiteColor]];
  if (! self.crossHairStoneLayer)
    self.crossHairStoneLayer = [self.playViewMetrics stoneLayerWithContext:context stoneColor:self.playViewModel.crossHairColor];

  CGLayerRef stoneLayer;
  if (self.crossHairPoint.hasStone)
    stoneLayer = self.crossHairStoneLayer;
  else
  {
    if ([GoGame sharedGame].currentPlayer.isBlack)
      stoneLayer = self.blackStoneLayer;
    else
      stoneLayer = self.whiteStoneLayer;
  }
  [self.playViewMetrics drawLayer:stoneLayer withContext:context centeredAtPoint:self.crossHairPoint];
}

@end
