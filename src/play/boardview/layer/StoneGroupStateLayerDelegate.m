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
#import "BoardViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../model/ScoringModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardRegion.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"
#import "../../../utility/UIColorAdditions.h"


CGLayerRef deadStoneSymbolLayer;
CGLayerRef blackSekiStoneSymbolLayer;
CGLayerRef whiteSekiStoneSymbolLayer;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// StoneGroupStateLayerDelegate.
// -----------------------------------------------------------------------------
@interface BVStoneGroupStateLayerDelegate()
@property(nonatomic, retain) ScoringModel* scoringModel;
@end


@implementation BVStoneGroupStateLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a StoneGroupStateLayerDelegate object.
///
/// @note This is the designated initializer of StoneGroupStateLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTileView:(BoardTileView*)tileView
                metrics:(PlayViewMetrics*)metrics
           scoringModel:(ScoringModel*)theScoringModel
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTileView:tileView metrics:metrics];
  if (! self)
    return nil;
  self.scoringModel = theScoringModel;
  deadStoneSymbolLayer = NULL;
  blackSekiStoneSymbolLayer = NULL;
  whiteSekiStoneSymbolLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StoneGroupStateLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scoringModel = nil;
  [self invalidateLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates layers for marking dead or seki stones.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  if (deadStoneSymbolLayer)
  {
    CGLayerRelease(deadStoneSymbolLayer);
    deadStoneSymbolLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (blackSekiStoneSymbolLayer)
  {
    CGLayerRelease(blackSekiStoneSymbolLayer);
    blackSekiStoneSymbolLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (whiteSekiStoneSymbolLayer)
  {
    CGLayerRelease(whiteSekiStoneSymbolLayer);
    whiteSekiStoneSymbolLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
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
    case BVLDEventScoreCalculationEnds:
    case BVLDEventScoringModeDisabled:
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

  if (! deadStoneSymbolLayer)
    deadStoneSymbolLayer = BVCreateDeadStoneSymbolLayer(context, self.scoringModel.deadStoneSymbolPercentage, self.scoringModel.deadStoneSymbolColor, self.playViewMetrics);
  if (! blackSekiStoneSymbolLayer)
    blackSekiStoneSymbolLayer = BVCreateSquareSymbolLayer(context, self.scoringModel.blackSekiSymbolColor, self.playViewMetrics);
  if (! whiteSekiStoneSymbolLayer)
    whiteSekiStoneSymbolLayer = BVCreateSquareSymbolLayer(context, self.scoringModel.whiteSekiSymbolColor, self.playViewMetrics);

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];

  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    CGLayerRef layerToDraw = 0;
    switch (point.region.stoneGroupState)
    {
      case GoStoneGroupStateDead:
      {
        layerToDraw = deadStoneSymbolLayer;
        break;
      }
      case GoStoneGroupStateSeki:
      {
        switch ([point.region color])
        {
          case GoColorBlack:
            layerToDraw = blackSekiStoneSymbolLayer;
            break;
          case GoColorWhite:
            layerToDraw = whiteSekiStoneSymbolLayer;
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
    if (layerToDraw)
    {
      [BoardViewDrawingHelper drawLayer:layerToDraw
                            withContext:context
                        centeredAtPoint:point
                         inTileWithRect:tileRect
                            withMetrics:self.playViewMetrics];
    }
  }
}

@end
