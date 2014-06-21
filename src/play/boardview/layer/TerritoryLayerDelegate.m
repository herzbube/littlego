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
#import "../BoardTileView.h"
#import "../../model/PlayViewMetrics.h"
#import "../../model/ScoringModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardRegion.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"
#import "../../../go/GoVertex.h"
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
/// @brief Store list of points to draw between notify:eventInfo:() and
/// drawLayer:inContext:(), and also between drawing cycles.
@property(nonatomic, retain) NSMutableDictionary* drawingPoints;
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
  self.drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
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
  self.drawingPoints = nil;
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
      self.drawingPoints = [self calculateDrawingPoints];
      self.dirty = true;
      break;
    }
    case BVLDEventBoardSizeChanged:
    {
      [self invalidateLayers];
      self.drawingPoints = [self calculateDrawingPoints];
      self.dirty = true;
      break;
    }
    case BVLDEventScoreCalculationEnds:
    case BVLDEventInconsistentTerritoryMarkupTypeChanged:
    case BVLDEventScoringModeDisabled:
    {
      NSMutableDictionary* oldDrawingPoints = self.drawingPoints;
      NSMutableDictionary* newDrawingPoints = [self calculateDrawingPoints];
      // The dictionary must contain the territory markup style so that the
      // dictionary comparison detects whether the territory color changed, or
      // the inconsistent territory markup type changed
      if (! [oldDrawingPoints isEqualToDictionary:newDrawingPoints])
      {
        self.drawingPoints = newDrawingPoints;
        // Re-draw the entire layer. Further optimization could be made here
        // by only drawing that rectangle which is actually affected by
        // self.drawingPoints.
        self.dirty = true;
      }
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
  GoBoard* board = [GoGame sharedGame].board;
  [self.drawingPoints enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* territoryLayerTypeAsNumber, BOOL* stop){
    enum TerritoryLayerType territoryLayerType = [territoryLayerTypeAsNumber intValue];
    CGLayerRef layerToDraw = 0;
    switch (territoryLayerType)
    {
      case TerritoryLayerTypeBlack:
        layerToDraw = blackTerritoryLayer;
        break;
      case TerritoryLayerTypeWhite:
        layerToDraw = whiteTerritoryLayer;
        break;
      case TerritoryLayerTypeInconsistentFillColor:
        layerToDraw = inconsistentFillColorTerritoryLayer;
        break;
      case TerritoryLayerTypeInconsistentDotSymbol:
        layerToDraw = inconsistentDotSymbolTerritoryLayer;
        break;
      default:
        return;
    }
    GoPoint* point = [board pointAtVertex:vertexString];
    [BoardViewDrawingHelper drawLayer:layerToDraw
                          withContext:context
                      centeredAtPoint:point
                       inTileWithRect:tileRect
                          withMetrics:self.playViewMetrics];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Returns a dictionary that identifies the points whose intersections
/// are located on this tile, and the markup style that should be used to draw
/// the territory for these points.
///
/// Dictionary keys are NSString objects that contain the intersection vertex.
/// The vertex string can be used to get the GoPoint object that corresponds to
/// the intersection.
///
/// Dictionary values are NSNumber objects that store a TerritoryLayerType enum
/// value. The value identifies the layer that needs to be drawn at the
/// intersection.
// -----------------------------------------------------------------------------
- (NSMutableDictionary*) calculateDrawingPoints
{
  NSMutableDictionary* drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
  GoGame* game = [GoGame sharedGame];
  if (! game.score.scoringEnabled)
    return drawingPoints;

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];
  enum InconsistentTerritoryMarkupType inconsistentTerritoryMarkupType = self.scoringModel.inconsistentTerritoryMarkupType;

  // TODO: Currently we always iterate over all points. This could be
  // optimized: If the tile rect stays the same, we should already know which
  // points intersect with the tile, so we could fall back on a pre-filtered
  // list of points. On a 19x19 board this could save us quite a bit of time:
  // 381 points are iterated on 16 tiles (iPhone), i.e. over 6000 iterations.
  // on iPad where there are more tiles it is even worse.
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:point
                                                                 metrics:self.playViewMetrics];
    if (! CGRectIntersectsRect(tileRect, stoneRect))
      continue;
    enum GoColor territoryColor = point.region.territoryColor;
    enum TerritoryLayerType territoryLayerType;
    switch (territoryColor)
    {
      case GoColorBlack:
      {
        territoryLayerType = TerritoryLayerTypeBlack;
        break;
      }
      case GoColorWhite:
      {
        territoryLayerType = TerritoryLayerTypeWhite;
        break;
      }
      case GoColorNone:
      {
        if (! point.region.territoryInconsistencyFound)
          continue;  // territory is truly neutral, no markup needed
        switch (inconsistentTerritoryMarkupType)
        {
          case InconsistentTerritoryMarkupTypeNeutral:
            continue;  // territory is inconsistent, but user does not want markup
          case InconsistentTerritoryMarkupTypeDotSymbol:
            territoryLayerType = TerritoryLayerTypeInconsistentDotSymbol;
            break;
          case InconsistentTerritoryMarkupTypeFillColor:
            territoryLayerType = TerritoryLayerTypeInconsistentFillColor;
            break;
          default:
            DDLogError(@"Unknown value %d for property ScoringModel.inconsistentTerritoryMarkupType", inconsistentTerritoryMarkupType);
            continue;
        }
        break;
      }
      default:
      {
        DDLogError(@"Unknown value %d for property point.region.territoryColor", territoryColor);
        continue;
      }
    }

    NSNumber* territoryLayerTypeAsNumber = [[[NSNumber alloc] initWithInt:territoryLayerType] autorelease];
    [drawingPoints setObject:territoryLayerTypeAsNumber forKey:point.vertex.string];
  }

  return drawingPoints;
}

@end
