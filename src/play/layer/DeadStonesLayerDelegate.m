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
#import "DeadStonesLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../model/PlayViewModel.h"
#import "../model/ScoringModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardRegion.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for DeadStonesLayerDelegate.
// -----------------------------------------------------------------------------
@interface DeadStonesLayerDelegate()
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
@property(nonatomic, retain) ScoringModel* scoringModel;
@property(nonatomic, assign) CGLayerRef deadStoneSymbolLayer;
//@}
@end


@implementation DeadStonesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a DeadStonesLayerDelegate object.
///
/// @note This is the designated initializer of DeadStonesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithMainView:(UIView*)mainView metrics:(PlayViewMetrics*)metrics playViewModel:(PlayViewModel*)playViewModel scoringModel:(ScoringModel*)theScoringModel
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithMainView:mainView metrics:metrics model:playViewModel];
  if (! self)
    return nil;
  self.scoringModel = theScoringModel;
  _deadStoneSymbolLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DeadStonesLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scoringModel = nil;
  [self releaseLayer];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases layers for marking up territory if they are currently
/// allocated. Otherwise does nothing.
// -----------------------------------------------------------------------------
- (void) releaseLayer
{
  if (_deadStoneSymbolLayer)
  {
    CGLayerRelease(_deadStoneSymbolLayer);
    _deadStoneSymbolLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
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
      [self releaseLayer];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change
    {
      [self releaseLayer];
      self.dirty = true;
      break;
    }
    case PVLDEventScoreCalculationEnds:
    case PVLDEventScoringModeDisabled:
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
  if (! self.scoringModel.scoringMode)
    return;
  DDLogVerbose(@"DeadStonesLayerDelegate is drawing");

  if (! _deadStoneSymbolLayer)
    _deadStoneSymbolLayer = CreateDeadStoneSymbolLayer(context, self);

  NSEnumerator* enumerator = [[GoGame sharedGame].board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    if (point.region.deadStoneGroup)
      [self.playViewMetrics drawLayer:_deadStoneSymbolLayer withContext:context centeredAtPoint:point];
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a "dead
/// stone" symbol.
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
CGLayerRef CreateDeadStoneSymbolLayer(CGContextRef context, DeadStonesLayerDelegate* delegate)
{
  // The symbol for marking a dead stone is an "x"; we draw this as the two
  // diagonals of a Go stone's "inner square". We make the diagonals shorter by
  // making the square's size slightly smaller
  CGSize layerSize = delegate.playViewMetrics.stoneInnerSquareSize;
  CGFloat inset = floor(layerSize.width * (1.0 - delegate.scoringModel.deadStoneSymbolPercentage));
  layerSize.width -= inset;
  layerSize.height -= inset;

  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = layerSize;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGContextBeginPath(layerContext);
  CGContextMoveToPoint(layerContext, layerRect.origin.x, layerRect.origin.y);
  CGContextAddLineToPoint(layerContext, layerRect.origin.x + layerRect.size.width, layerRect.origin.y + layerRect.size.width);
  CGContextMoveToPoint(layerContext, layerRect.origin.x, layerRect.origin.y + layerRect.size.width);
  CGContextAddLineToPoint(layerContext, layerRect.origin.x + layerRect.size.width, layerRect.origin.y);
  CGContextSetStrokeColorWithColor(layerContext, delegate.scoringModel.deadStoneSymbolColor.CGColor);
  CGContextSetLineWidth(layerContext, delegate.playViewModel.normalLineWidth);
  CGContextStrokePath(layerContext);

  return layer;
}

@end
