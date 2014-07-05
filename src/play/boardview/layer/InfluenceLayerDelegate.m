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
#import "../../model/BoardViewMetrics.h"
#import "../../model/BoardViewModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"
#import "../../../go/GoScore.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for InfluenceLayerDelegate.
// -----------------------------------------------------------------------------
@interface InfluenceLayerDelegate()
@property(nonatomic, assign) BoardViewModel* boardViewModel;
/// @brief Store list of points to draw between notify:eventInfo:() and
/// drawLayer:inContext:(), and also between drawing cycles.
@property(nonatomic, retain) NSMutableDictionary* drawingPoints;
@end


@implementation InfluenceLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a InfluenceLayerDelegate object.
///
/// @note This is the designated initializer of InfluenceLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile
            metrics:(BoardViewMetrics*)metrics
     boardViewModel:(BoardViewModel*)boardViewModel
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  self.boardViewModel = boardViewModel;
  self.drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this InfluenceLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardViewModel = nil;
  self.drawingPoints = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case BVLDEventBoardGeometryChanged:
    case BVLDEventBoardSizeChanged:
    case BVLDEventGoGameStarted:  // reset statistics to zero (even if board size remains the same)
    case BVLDEventInvalidateContent:
    {
      self.drawingPoints = [self calculateDrawingPoints];
      self.dirty = true;
      break;
    }
    case BVLDEventTerritoryStatisticsChanged:
    {
      NSMutableDictionary* oldDrawingPoints = self.drawingPoints;
      NSMutableDictionary* newDrawingPoints = [self calculateDrawingPoints];
      // The dictionary must contain the influence scores so that the dictionary
      // comparison detects whether any scores changed since the last time.
      //
      // Note: Currently this optimization pretty much never works because the
      // influence scores almost always change between to updates. The reason is
      // that the simulations played out by Fuego between two updates pretty
      // much always result in scores that are different. Even if no moves are
      // played between two updates, the results are different because we send
      // Fuego a "reg_genmove" command to force it to update its territory
      // statistics. This results in additional playouts which, of course, again
      // change the influence scores. The only situation where there is no
      // difference between updates is if a tile is entirely occupied by a stone
      // group that is guaranteed to be alive (in which case the influence
      // scores remain at +1.0f or -1.0f).
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
  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];
  GoBoard* board = [GoGame sharedGame].board;
  [self.drawingPoints enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* influenceScoreAsNumber, BOOL* stop){
    GoPoint* point = [board pointAtVertex:vertexString];
    float influenceScore = [influenceScoreAsNumber floatValue];
    enum GoColor influenceColor = [self influenceColor:influenceScore];
    [self drawInfluenceRectWithContext:context
                               atPoint:point
                    withInfluenceScore:influenceScore
                        influenceColor:influenceColor
                        inTileWithRect:tileRect];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawInfluenceRectWithContext:(CGContextRef)context
                              atPoint:(GoPoint*)point
                   withInfluenceScore:(float)influenceScore
                       influenceColor:(enum GoColor)influenceColor
                       inTileWithRect:(CGRect)tileRect
{
  CGSize influenceSize = [self influenceSizeForScore:influenceScore];
  CGRect influenceRect = [BoardViewDrawingHelper canvasRectForSize:influenceSize
                                                   centeredAtPoint:point
                                                           metrics:self.boardViewMetrics];
  CGRect drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:influenceRect
                                                          inTileWithRect:tileRect];
  [self drawInfluenceRectWithContext:context
                              inRect:drawingRect
                           withColor:influenceColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawInfluenceRectWithContext:atPoint:withInfluenceColor:().
// -----------------------------------------------------------------------------
- (CGSize) influenceSizeForScore:(float)influenceScore
{
  CGSize influenceSize = self.boardViewMetrics.stoneInnerSquareSize;
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
      // This should not happen, we should have filtered out intersections with
      // no color long ago
      assert(false);
      DDLogCError(@"Unknown color %d", influenceColor);
      return nil;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a dictionary that identifies the points whose intersections
/// are located on this tile, and their current influence score.
///
/// The dictionary can be empty for the following reasons:
/// - If the current application state forbids the display of influence (e.g.
///   user preferences).
/// - If none of the intersections located on this tile need drawing. An
///   intersection does not need drawing if its influence score is 0 (i.e.
///   influence is tied), or if it has a stone on it that has the same color as
///   the influence rectangle to be drawn.
///
/// Dictionary keys are NSString objects that contain the intersection vertex.
/// The vertex string can be used to get the GoPoint object that corresponds to
/// the intersection.
///
/// Dictionary values are NSNumber objects that store a float value, which
/// represents the influence score of the intersection identified by the
/// dictionary key.
// -----------------------------------------------------------------------------
- (NSMutableDictionary*) calculateDrawingPoints
{
  NSMutableDictionary* drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
  if (! self.boardViewModel.displayPlayerInfluence)
    return drawingPoints;
  GoGame* game = [GoGame sharedGame];
  if (game.score.scoringEnabled)
    return drawingPoints;

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];
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
                                                                 metrics:self.boardViewMetrics];
    if (! CGRectIntersectsRect(tileRect, stoneRect))
      continue;
    float influenceScore = fabsf(point.territoryStatisticsScore);
    enum GoColor influenceColor = [self influenceColor:influenceScore];
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
    NSNumber* influenceScoreAsNumber = [[[NSNumber alloc] initWithFloat:influenceScore] autorelease];
    [drawingPoints setObject:influenceScoreAsNumber forKey:point.vertex.string];
  }

  return drawingPoints;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for calculateDrawingPoints().
// -----------------------------------------------------------------------------
- (enum GoColor) influenceColor:(float)influenceScore
{
  if (influenceScore > 0.0f)
    return GoColorBlack;
  else if (influenceScore < 0.0f)
    return GoColorWhite;
  else
    return GoColorNone;  // there is no score, or black and white are tied
}

// -----------------------------------------------------------------------------
/// @brief Private helper for calculateDrawingPoints().
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

@end
