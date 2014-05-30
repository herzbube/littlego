// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "InfluenceLayerDelegate.h"
#import "PlayViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../model/PlayViewModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"

// System includes
#import <QuartzCore/QuartzCore.h>


@implementation InfluenceLayerDelegate

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
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change
    {
      self.dirty = true;
      break;
    }
    case PVLDEventTerritoryStatisticsChanged:
    {
      self.dirty = true;
      break;
    }
    case PVLDEventScoringModeEnabled:
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
  if (! self.playViewModel.displayPlayerInfluence)
    return;
  GoGame* game = [GoGame sharedGame];
  if (game.score.scoringEnabled)
    return;
  DDLogVerbose(@"InfluenceLayerDelegate is drawing");

  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    enum GoColor influenceColor = [self influenceColor:point];
    if (GoColorNone == influenceColor)
      continue;
    enum GoColor intersectionOwner = [self intersectionOwner:point];
    if (intersectionOwner == influenceColor)
    {
      // Don't draw if the player who has more influence on the intersection
      // already has a stone on the intersection (the rectangle would be almost
      // invisible against the stone's background)
      continue;
    }
    [self drawInfluenceRectWithContext:context atPoint:point withInfluenceColor:influenceColor];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (enum GoColor) influenceColor:(GoPoint*)point
{
  if (point.territoryStatisticsScore > 0.0f)
    return GoColorBlack;
  else if (point.territoryStatisticsScore < 0.0f)
    return GoColorWhite;
  else
    return GoColorNone;  // there is no score, or black and white are tied
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (enum GoColor) intersectionOwner:(GoPoint*)point
{
  if (! point.hasStone)
    return GoColorNone;
  else if (point.blackStone)
    return GoColorBlack;
  else
    return GoColorWhite;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawInfluenceRectWithContext:(CGContextRef)context atPoint:(GoPoint*)point withInfluenceColor:(enum GoColor)influenceColor
{
  CGRect influenceLayerRect = [self influenceLayerRectAtPoint:point];
  CGLayerRef influenceLayer = CGLayerCreateWithContext(context, influenceLayerRect.size, NULL);
  [self drawInfluenceRectInLayer:influenceLayer withRect:influenceLayerRect withColor:influenceColor];
  [PlayViewDrawingHelper drawLayer:influenceLayer withContext:context centeredAtPoint:point withMetrics:self.playViewMetrics];
  CGLayerRelease(influenceLayer);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawInfluenceRectWithContext:atPoint:withInfluenceColor:().
// -----------------------------------------------------------------------------
- (CGRect) influenceLayerRectAtPoint:(GoPoint*)point
{
  float influenceScore = fabsf(point.territoryStatisticsScore);
  CGRect influenceLayerRect;
  influenceLayerRect.origin = CGPointZero;
  influenceLayerRect.size = self.playViewMetrics.stoneInnerSquareSize;
  influenceLayerRect.size.width *= influenceScore;
  influenceLayerRect.size.height *= influenceScore;
  return influenceLayerRect;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawInfluenceRectWithContext:atPoint:withInfluenceColor:().
// -----------------------------------------------------------------------------
- (void) drawInfluenceRectInLayer:(CGLayerRef)layer withRect:(CGRect)layerRect withColor:(enum GoColor)influenceColor
{
  UIColor* influenceRectColor = [self influenceRectColor:influenceColor];
  if (! influenceRectColor)
    return;
  CGContextRef layerContext = CGLayerGetContext(layer);
  CGContextSetFillColorWithColor(layerContext, influenceRectColor.CGColor);
  CGContextAddRect(layerContext, layerRect);
  CGContextSetBlendMode(layerContext, kCGBlendModeNormal);
  CGContextFillPath(layerContext);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawInfluenceRectInLayer:withRect:withColor:().
// -----------------------------------------------------------------------------
- (UIColor*) influenceRectColor:(enum GoColor)influenceColor
{
  switch (influenceColor)
  {
    case GoColorBlack:
    {
      return [UIColor colorWithWhite:0.0 alpha:gInfluenceColorAlphaBlack];
    }
    case GoColorWhite:
    {
      return [UIColor colorWithWhite:1.0 alpha:gInfluenceColorAlphaWhite];
    }
    default:
    {
      DDLogCError(@"Unknown color %d", influenceColor);
      return nil;
    }
  }
}

@end
