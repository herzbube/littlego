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
#import "BoardViewDrawingHelper.h"
#import "../BoardTileView.h"
#import "../../model/PlayViewMetrics.h"
#import "../../model/PlayViewModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for InfluenceLayerDelegate.
// -----------------------------------------------------------------------------
@interface BVInfluenceLayerDelegate()
@property(nonatomic, assign) PlayViewModel* playViewModel;
@end


@implementation BVInfluenceLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a InfluenceLayerDelegate object.
///
/// @note This is the designated initializer of InfluenceLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTileView:(BoardTileView*)tileView
                metrics:(PlayViewMetrics*)metrics
          playViewModel:(PlayViewModel*)playViewModel
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTileView:tileView metrics:metrics];
  if (! self)
    return nil;
  self.playViewModel = playViewModel;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this InfluenceLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.playViewModel = nil;
  [super dealloc];
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
      self.dirty = true;
      break;
    }
    case BVLDEventGoGameStarted:  // reset statistics to zero
    {
      self.dirty = true;
      break;
    }
    case BVLDEventBoardSizeChanged:
    {
      self.dirty = true;
      break;
    }
    case BVLDEventTerritoryStatisticsChanged:
    {
      self.dirty = true;
      break;
    }
    case BVLDEventScoringModeEnabled:
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
  if (! self.playViewModel.displayPlayerInfluence)
    return;
  GoGame* game = [GoGame sharedGame];
  if (game.score.scoringEnabled)
    return;
  DDLogVerbose(@"InfluenceLayerDelegate is drawing");

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];

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
    [self drawInfluenceRectWithContext:context
                               atPoint:point
                    withInfluenceColor:influenceColor
                        inTileWithRect:tileRect];
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
- (void) drawInfluenceRectWithContext:(CGContextRef)context
                              atPoint:(GoPoint*)point
                   withInfluenceColor:(enum GoColor)influenceColor
                       inTileWithRect:(CGRect)tileRect
{
  CGSize influenceSize = [self influenceSizeAtPoint:point];
  CGRect influenceRect = [BoardViewDrawingHelper canvasRectForSize:influenceSize
                                                   centeredAtPoint:point
                                                           metrics:self.playViewMetrics];
  if (! CGRectIntersectsRect(tileRect, influenceRect))
    return;
  CGRect drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:influenceRect
                                                          inTileWithRect:tileRect];
  [self drawInfluenceRectWithContext:context
                              inRect:drawingRect
                           withColor:influenceColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawInfluenceRectWithContext:atPoint:withInfluenceColor:().
// -----------------------------------------------------------------------------
- (CGSize) influenceSizeAtPoint:(GoPoint*)point
{
  float influenceScore = fabsf(point.territoryStatisticsScore);
  CGSize influenceSize = self.playViewMetrics.stoneInnerSquareSize;
  influenceSize.width *= influenceScore;
  influenceSize.height *= influenceScore;
  return influenceSize;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawInfluenceRectWithContext:atPoint:withInfluenceColor:().
// -----------------------------------------------------------------------------
- (void) drawInfluenceRectWithContext:(CGContextRef)context
                               inRect:(CGRect)rect
                            withColor:(enum GoColor)influenceColor
{
  UIColor* influenceRectColor = [self influenceRectColor:influenceColor];
  if (! influenceRectColor)
    return;
  CGContextSetFillColorWithColor(context, influenceRectColor.CGColor);
  CGContextAddRect(context, rect);
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGContextFillPath(context);
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
