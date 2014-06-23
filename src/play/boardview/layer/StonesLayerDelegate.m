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
#import "StonesLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/PlayViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardRegion.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"
#import "../../../ui/UiUtilities.h"


CGLayerRef blackStoneLayer;
CGLayerRef whiteStoneLayer;

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BVStonesLayerDelegate.
// -----------------------------------------------------------------------------
@interface BVStonesLayerDelegate()
/// @brief Store list of points to draw between notify:eventInfo:() and
/// drawLayer:inContext:(), and also between drawing cycles.
@property(nonatomic, retain) NSMutableDictionary* drawingPoints;
@end


@implementation BVStonesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a StonesLayerDelegate object.
///
/// @note This is the designated initializer of StonesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTileView:(BoardTileView*)tileView metrics:(PlayViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTileView:tileView metrics:metrics];
  if (! self)
    return nil;
  self.drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
  blackStoneLayer = NULL;
  whiteStoneLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StonesLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.drawingPoints = nil;
  [self invalidateLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the stone layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  if (blackStoneLayer)
  {
    CGLayerRelease(blackStoneLayer);
    blackStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (whiteStoneLayer)
  {
    CGLayerRelease(whiteStoneLayer);
    whiteStoneLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case BVLDEventBoardGeometryChanged:
    {
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
    case BVLDEventGoGameStarted:  // place handicap stones
    {
      self.drawingPoints = [self calculateDrawingPoints];
      self.dirty = true;
      break;
    }
    case BVLDEventBoardPositionChanged:
    {
      NSMutableDictionary* oldDrawingPoints = self.drawingPoints;
      NSMutableDictionary* newDrawingPoints = [self calculateDrawingPoints];
      // The dictionary must contain the intersection state so that the
      // dictionary comparison detects whether a stone was placed or captured
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
  if (! blackStoneLayer)
    blackStoneLayer = BVCreateStoneLayerWithImage(context, stoneBlackImageResource, self.playViewMetrics);
  if (! whiteStoneLayer)
    whiteStoneLayer = BVCreateStoneLayerWithImage(context, stoneWhiteImageResource, self.playViewMetrics);

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];
  GoBoard* board = [GoGame sharedGame].board;
  [self.drawingPoints enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* stoneStateAsNumber, BOOL* stop){
    // Ignore stoneStateAsNumber, get the current values directly from the
    // GoPoint object
    GoPoint* point = [board pointAtVertex:vertexString];
    if (! point.hasStone)
      return;
    CGLayerRef stoneLayer;
    if (point.blackStone)
      stoneLayer = blackStoneLayer;
    else
      stoneLayer = whiteStoneLayer;
    [BoardViewDrawingHelper drawLayer:stoneLayer
                          withContext:context
                      centeredAtPoint:point
                       inTileWithRect:tileRect
                          withMetrics:self.playViewMetrics];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Returns a dictionary that identifies the points whose intersections
/// are located on this tile, and their current states.
///
/// Dictionary keys are NSString objects that contain the intersection vertex.
/// The vertex string can be used to get the GoPoint object that corresponds to
/// the intersection.
///
/// Dictionary values are NSNumber objects that store a GoColor enum value. The
/// value identifies what needs to be drawn at the intersection (i.e. a black
/// or white stone, or nothing).
// -----------------------------------------------------------------------------
- (NSMutableDictionary*) calculateDrawingPoints
{
  NSMutableDictionary* drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTileView:self.tileView
                                                          metrics:self.playViewMetrics];

  // TODO: Currently we always iterate over all points. This could be
  // optimized: If the tile rect stays the same, we should already know which
  // points intersect with the tile, so we could fall back on a pre-filtered
  // list of points. On a 19x19 board this could save us quite a bit of time:
  // 381 points are iterated on 16 tiles (iPhone), i.e. over 6000 iterations.
  // on iPad where there are more tiles it is even worse.
  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:point
                                                                 metrics:self.playViewMetrics];
    if (! CGRectIntersectsRect(tileRect, stoneRect))
      continue;
    NSNumber* stoneStateAsNumber = [[[NSNumber alloc] initWithInt:point.stoneState] autorelease];
    [drawingPoints setObject:stoneStateAsNumber forKey:point.vertex.string];
  }

  return drawingPoints;
}

@end
