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
#import "TerritoryLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../model/ScoringModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardRegion.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"
#import "../../../ui/UiUtilities.h"
#import "../../../utility/UIColorAdditions.h"


CGLayerRef blackTerritoryLayer;
CGLayerRef whiteTerritoryLayer;
CGLayerRef inconsistentFillColorTerritoryLayer;
CGLayerRef inconsistentDotSymbolTerritoryLayer;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TerritoryLayerDelegate.
// -----------------------------------------------------------------------------
@interface BVTerritoryLayerDelegate()
@property(nonatomic, retain) ScoringModel* scoringModel;
@property(nonatomic, retain) UIColor* territoryColorBlack;
@property(nonatomic, retain) UIColor* territoryColorWhite;
@property(nonatomic, retain) UIColor* territoryColorInconsistent;
@end


@implementation BVTerritoryLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a TerritoryLayerDelegate object.
///
/// @note This is the designated initializer of TerritoryLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTileView:(BoardTileView*)tileView
                metrics:(PlayViewMetrics*)metrics
           scoringModel:(ScoringModel*)scoringModel
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTileView:tileView metrics:metrics];
  if (! self)
    return nil;
  self.scoringModel = scoringModel;
  self.territoryColorBlack = [UIColor colorWithWhite:0.0 alpha:scoringModel.alphaTerritoryColorBlack];
  self.territoryColorWhite = [UIColor colorWithWhite:1.0 alpha:scoringModel.alphaTerritoryColorWhite];
  self.territoryColorInconsistent = [scoringModel.inconsistentTerritoryFillColor colorWithAlphaComponent:scoringModel.inconsistentTerritoryFillColorAlpha];
  blackTerritoryLayer = NULL;
  whiteTerritoryLayer = NULL;
  inconsistentFillColorTerritoryLayer = NULL;
  inconsistentDotSymbolTerritoryLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TerritoryLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scoringModel = nil;
  self.territoryColorBlack = nil;
  self.territoryColorWhite = nil;
  self.territoryColorInconsistent = nil;
  [self invalidateLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the layers for marking up territory.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  if (blackTerritoryLayer)
  {
    CGLayerRelease(blackTerritoryLayer);
    blackTerritoryLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (whiteTerritoryLayer)
  {
    CGLayerRelease(whiteTerritoryLayer);
    whiteTerritoryLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (inconsistentFillColorTerritoryLayer)
  {
    CGLayerRelease(inconsistentFillColorTerritoryLayer);
    inconsistentFillColorTerritoryLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (inconsistentDotSymbolTerritoryLayer)
  {
    CGLayerRelease(inconsistentDotSymbolTerritoryLayer);
    inconsistentDotSymbolTerritoryLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
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
    case BVLDEventInconsistentTerritoryMarkupTypeChanged:
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
  DDLogVerbose(@"TerritoryLayerDelegate is drawing");

  if (! blackTerritoryLayer)
    blackTerritoryLayer = BVCreateTerritoryLayer(context, TerritoryLayerTypeBlack, self.territoryColorBlack, 0, self.playViewMetrics);
  if (! whiteTerritoryLayer)
    whiteTerritoryLayer = BVCreateTerritoryLayer(context, TerritoryLayerTypeWhite, self.territoryColorWhite, 0, self.playViewMetrics);
  if (! inconsistentFillColorTerritoryLayer)
    inconsistentFillColorTerritoryLayer = BVCreateTerritoryLayer(context, TerritoryLayerTypeInconsistentFillColor, self.territoryColorInconsistent, 0, self.playViewMetrics);
  if (! inconsistentDotSymbolTerritoryLayer)
    inconsistentDotSymbolTerritoryLayer = BVCreateTerritoryLayer(context,
                                                                 TerritoryLayerTypeInconsistentDotSymbol,
                                                                 self.scoringModel.inconsistentTerritoryDotSymbolColor,
                                                                 self.scoringModel.inconsistentTerritoryDotSymbolPercentage,
                                                                 self.playViewMetrics);

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                            metrics:self.playViewMetrics];

  CGLayerRef inconsistentTerritoryLayer = NULL;
  enum InconsistentTerritoryMarkupType inconsistentTerritoryMarkupType = self.scoringModel.inconsistentTerritoryMarkupType;
  switch (inconsistentTerritoryMarkupType)
  {
    case InconsistentTerritoryMarkupTypeDotSymbol:
    {
      inconsistentTerritoryLayer = inconsistentDotSymbolTerritoryLayer;
      break;
    }
    case InconsistentTerritoryMarkupTypeFillColor:
    {
      inconsistentTerritoryLayer = inconsistentFillColorTerritoryLayer;
      break;
    }
    case InconsistentTerritoryMarkupTypeNeutral:
    {
      inconsistentTerritoryLayer = NULL;
      break;
    }
    default:
    {
      DDLogError(@"Unknown value %d for property ScoringModel.inconsistentTerritoryMarkupType", inconsistentTerritoryMarkupType);
      break;
    }
  }

  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    CGLayerRef layerToDraw = 0;
    switch (point.region.territoryColor)
    {
      case GoColorBlack:
        layerToDraw = blackTerritoryLayer;
        break;
      case GoColorWhite:
        layerToDraw = whiteTerritoryLayer;
        break;
      case GoColorNone:
        if (! point.region.territoryInconsistencyFound)
          continue;  // territory is truly neutral, no markup needed
        else if (InconsistentTerritoryMarkupTypeNeutral == inconsistentTerritoryMarkupType)
          continue;  // territory is inconsistent, but user does not want markup
        else
          layerToDraw = inconsistentTerritoryLayer;
        break;
      default:
        continue;
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
