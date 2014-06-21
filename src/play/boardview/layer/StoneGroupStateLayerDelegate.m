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
#import "../BoardTileView.h"
#import "../../model/PlayViewMetrics.h"
#import "../../model/ScoringModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardRegion.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"
#import "../../../go/GoVertex.h"
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
/// @brief Store list of points to draw between notify:eventInfo:() and
/// drawLayer:inContext:(), and also between drawing cycles.
@property(nonatomic, retain) NSMutableDictionary* drawingPoints;
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
  self.drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
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
  self.drawingPoints = nil;
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
    case BVLDEventScoringModeDisabled:
    {
      NSMutableDictionary* oldDrawingPoints = self.drawingPoints;
      NSMutableDictionary* newDrawingPoints = [self calculateDrawingPoints];
      // The dictionary must contain the stone group state so that the
      // dictionary comparison detects whether a state change occurred
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
  if (! deadStoneSymbolLayer)
    deadStoneSymbolLayer = BVCreateDeadStoneSymbolLayer(context, self.scoringModel.deadStoneSymbolPercentage, self.scoringModel.deadStoneSymbolColor, self.playViewMetrics);
  if (! blackSekiStoneSymbolLayer)
    blackSekiStoneSymbolLayer = BVCreateSquareSymbolLayer(context, self.scoringModel.blackSekiSymbolColor, self.playViewMetrics);
  if (! whiteSekiStoneSymbolLayer)
    whiteSekiStoneSymbolLayer = BVCreateSquareSymbolLayer(context, self.scoringModel.whiteSekiSymbolColor, self.playViewMetrics);

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];
  GoBoard* board = [GoGame sharedGame].board;
  [self.drawingPoints enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* stoneGroupStateAsNumber, BOOL* stop){
    GoPoint* point = [board pointAtVertex:vertexString];
    enum GoStoneGroupState stoneGroupState = [stoneGroupStateAsNumber intValue];
    CGLayerRef layerToDraw = 0;
    switch (stoneGroupState)
    {
      case GoStoneGroupStateDead:
      {
        layerToDraw = deadStoneSymbolLayer;
        break;
      }
      case GoStoneGroupStateSeki:
      {
        switch (point.stoneState)
        {
          case GoColorBlack:
            layerToDraw = blackSekiStoneSymbolLayer;
            break;
          case GoColorWhite:
            layerToDraw = whiteSekiStoneSymbolLayer;
            break;
          default:
            DDLogError(@"Unknown value %d for property point.stoneState", point.stoneState);
            return;
        }
        break;
      }
      default:
      {
        DDLogError(@"Unknown value %d for property point.region.stoneGroupState", stoneGroupState);
        return;
      }
    }
    [BoardViewDrawingHelper drawLayer:layerToDraw
                          withContext:context
                      centeredAtPoint:point
                       inTileWithRect:tileRect
                          withMetrics:self.playViewMetrics];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Returns a dictionary that identifies the points whose intersections
/// are located on this tile, and the stone group state of the region that each
/// point belongs to.
///
/// Dictionary keys are NSString objects that contain the intersection vertex.
/// The vertex string can be used to get the GoPoint object that corresponds to
/// the intersection.
///
/// Dictionary values are NSNumber objects that store a GoStoneGroupState enum
/// value.
// -----------------------------------------------------------------------------
- (NSMutableDictionary*) calculateDrawingPoints
{
  NSMutableDictionary* drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
  GoGame* game = [GoGame sharedGame];
  if (! game.score.scoringEnabled)
    return drawingPoints;

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];

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
    if (! point.hasStone)
      continue;
    CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:point
                                                                 metrics:self.playViewMetrics];
    if (! CGRectIntersectsRect(tileRect, stoneRect))
      continue;
    enum GoStoneGroupState stoneGroupState = point.region.stoneGroupState;
    NSNumber* stoneGroupStateAsNumber = [[[NSNumber alloc] initWithInt:stoneGroupState] autorelease];
    [drawingPoints setObject:stoneGroupStateAsNumber forKey:point.vertex.string];
  }

  return drawingPoints;
}

@end
