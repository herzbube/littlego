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
#import "StoneGroupStateLayerDelegate.h"
#import "PlayViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../model/ScoringModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardRegion.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"
#import "../../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// StoneGroupStateLayerDelegate.
// -----------------------------------------------------------------------------
@interface StoneGroupStateLayerDelegate()
@property(nonatomic, retain) ScoringModel* scoringModel;
@property(nonatomic, assign) CGLayerRef deadStoneSymbolLayer;
@property(nonatomic, assign) CGLayerRef blackSekiStoneSymbolLayer;
@property(nonatomic, assign) CGLayerRef whiteSekiStoneSymbolLayer;
@end


@implementation StoneGroupStateLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a StoneGroupStateLayerDelegate object.
///
/// @note This is the designated initializer of StoneGroupStateLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithMainView:(UIView*)mainView
                metrics:(PlayViewMetrics*)metrics
           scoringModel:(ScoringModel*)theScoringModel
{
  // Call designated initializer of superclass (PlayViewLayerDelegateBase)
  self = [super initWithMainView:mainView metrics:metrics];
  if (! self)
    return nil;
  self.scoringModel = theScoringModel;
  _deadStoneSymbolLayer = NULL;
  _blackSekiStoneSymbolLayer = NULL;
  _whiteSekiStoneSymbolLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StoneGroupStateLayerDelegate
/// object.
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
  if (_blackSekiStoneSymbolLayer)
  {
    CGLayerRelease(_blackSekiStoneSymbolLayer);
    _blackSekiStoneSymbolLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (_whiteSekiStoneSymbolLayer)
  {
    CGLayerRelease(_whiteSekiStoneSymbolLayer);
    _whiteSekiStoneSymbolLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
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
    case PVLDEventBoardSizeChanged:
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
  GoGame* game = [GoGame sharedGame];
  if (! game.score.scoringEnabled)
    return;
  DDLogVerbose(@"StoneGroupStateLayerDelegate is drawing");

  if (! _deadStoneSymbolLayer)
    _deadStoneSymbolLayer = CreateDeadStoneSymbolLayer(context, self);
  if (! _blackSekiStoneSymbolLayer)
    _blackSekiStoneSymbolLayer = CreateSquareSymbolLayer(context, self.scoringModel.blackSekiSymbolColor, self.playViewMetrics);
  if (! _whiteSekiStoneSymbolLayer)
    _whiteSekiStoneSymbolLayer = CreateSquareSymbolLayer(context, self.scoringModel.whiteSekiSymbolColor, self.playViewMetrics);

  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    switch (point.region.stoneGroupState)
    {
      case GoStoneGroupStateDead:
      {
        [PlayViewDrawingHelper drawLayer:_deadStoneSymbolLayer withContext:context centeredAtPoint:point withMetrics:self.playViewMetrics];
        break;
      }
      case GoStoneGroupStateSeki:
      {
        switch ([point.region color])
        {
          case GoColorBlack:
            [PlayViewDrawingHelper drawLayer:_blackSekiStoneSymbolLayer withContext:context centeredAtPoint:point withMetrics:self.playViewMetrics];
            break;
          case GoColorWhite:
            [PlayViewDrawingHelper drawLayer:_whiteSekiStoneSymbolLayer withContext:context centeredAtPoint:point withMetrics:self.playViewMetrics];
            break;
          default:
            break;
        }
        break;
      }
      default:
      {
        break;
      }
    }
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
CGLayerRef CreateDeadStoneSymbolLayer(CGContextRef context, StoneGroupStateLayerDelegate* delegate)
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
  CGContextSetLineWidth(layerContext, delegate.playViewMetrics.normalLineWidth);
  CGContextStrokePath(layerContext);

  return layer;
}

@end
