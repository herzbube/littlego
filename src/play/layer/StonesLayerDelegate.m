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
#import "StonesLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardRegion.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../ui/UiUtilities.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for StonesLayerDelegate.
// -----------------------------------------------------------------------------
@interface StonesLayerDelegate()
- (void) releaseLayers;
- (void) drawEmpty:(CGContextRef)context point:(GoPoint*)point;
@property(nonatomic, assign) CGLayerRef blackStoneLayer;
@property(nonatomic, assign) CGLayerRef whiteStoneLayer;
@end


@implementation StonesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a StonesLayerDelegate object.
///
/// @note This is the designated initializer of StonesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:model];
  if (! self)
    return nil;
  _blackStoneLayer = NULL;
  _whiteStoneLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StonesLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases stone layers if they are currently allocated. Otherwise
/// does nothing.
// -----------------------------------------------------------------------------
- (void) releaseLayers
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
      [self releaseLayers];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change + place handicap stones
    {
      [self releaseLayers];
      self.dirty = true;
      break;      
    }
    case PVLDEventBoardPositionChanged:
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

  if (! _blackStoneLayer)
    _blackStoneLayer = CreateStoneLayerWithImage(context, stoneBlackImageResource, self.playViewMetrics);
  if (! _whiteStoneLayer)
    _whiteStoneLayer = CreateStoneLayerWithImage(context, stoneWhiteImageResource, self.playViewMetrics);

  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    if (point.hasStone)
    {
      if (point.blackStone)
        [self.playViewMetrics drawLayer:_blackStoneLayer withContext:context centeredAtPoint:point];
      else
        [self.playViewMetrics drawLayer:_whiteStoneLayer withContext:context centeredAtPoint:point];
    }
    else
    {
      // TODO remove this or make it into something that can be turned on
      // at runtime for debugging
//      [self drawEmpty:context point:point];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Draws a small circle at intersection @a point, when @a point does
/// not have a stone on it. The color of the circle is different for different
/// regions.
///
/// This method is a debugging aid to see how GoBoardRegions are calculated.
// -----------------------------------------------------------------------------
- (void) drawEmpty:(CGContextRef)context point:(GoPoint*)point
{
  CGPoint coordinates = [self.playViewMetrics coordinatesFromPoint:point];
	CGContextSetFillColorWithColor(context, point.region.randomColor.CGColor);
  
  const int startRadius = [UiUtilities radians:0];
  const int endRadius = [UiUtilities radians:360];
  const int clockwise = 0;
  int circleRadius = floor(self.playViewMetrics.stoneRadius / 2);
  CGContextAddArc(context, coordinates.x + gHalfPixel, coordinates.y + gHalfPixel, circleRadius, startRadius, endRadius, clockwise);
  CGContextFillPath(context);
}

@end
