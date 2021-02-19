// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "StoneView.h"
#import "layer/BoardViewCGLayerCache.h"
#import "layer/BoardViewDrawingHelper.h"

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StoneView.
// -----------------------------------------------------------------------------
@interface StoneView()
@property(nonatomic, assign) enum GoColor stoneColor;
@property(nonatomic, retain) BoardViewMetrics* boardViewMetrics;
@end

@implementation StoneView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a StoneView object. The StoneView draws a stone of color
/// @a stoneColor within the rectangle defined by @a frame. @a metrics is used
/// for drawing.
///
/// @note This is the designated initializer of StoneView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)frame stoneColor:(enum GoColor)stoneColor metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:frame];
  if (! self)
    return nil;

  self.stoneColor = stoneColor;
  self.boardViewMetrics = metrics;

  // The UIKit documentation says that the opaque property must be set to NO
  // if a custom view's drawing does not entirely fill the view's bounds. This
  // is the case here because of the rounded shape of the stone that we draw.
  self.opaque = NO;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StoneView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardViewMetrics = nil;
  [super dealloc];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) drawRect:(CGRect)rect
{
  [super drawRect:rect];

  CGContextRef context = UIGraphicsGetCurrentContext();

  // TODO xxx: Here we use the same caching mechanism as in StoneLayerDelegate.
  // This should be a reusable function.
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  CGLayerRef blackStoneLayer = [cache layerOfType:BlackStoneLayerType];
  if (! blackStoneLayer)
  {
    blackStoneLayer = CreateStoneLayerWithImage(context, stoneBlackImageResource, self.boardViewMetrics);
    [cache setLayer:blackStoneLayer ofType:BlackStoneLayerType];
    CGLayerRelease(blackStoneLayer);
  }
  CGLayerRef whiteStoneLayer = [cache layerOfType:WhiteStoneLayerType];
  if (! whiteStoneLayer)
  {
    whiteStoneLayer = CreateStoneLayerWithImage(context, stoneWhiteImageResource, self.boardViewMetrics);
    [cache setLayer:whiteStoneLayer ofType:WhiteStoneLayerType];
    CGLayerRelease(whiteStoneLayer);
  }

  CGLayerRef stoneLayer;
  if (self.stoneColor == GoColorBlack)
    stoneLayer = blackStoneLayer;
  else
    stoneLayer = whiteStoneLayer;

  // Limit the drawing to the rectangle passed to us by CGRect
  CGContextDrawLayerInRect(context, rect, stoneLayer);
}

@end
