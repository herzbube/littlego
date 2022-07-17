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
#import "BoardViewLayerDelegateBase.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"


@implementation BoardViewLayerDelegateBase

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// BoardViewLayerDelegate protocol.
@synthesize layer = _layer;
@synthesize tile = _tile;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardViewLayerDelegateBase object. Creates a new
/// CALayer that uses this BoardViewLayerDelegateBase as its delegate.
///
/// @note This is the designated initializer of BoardViewLayerDelegateBase.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.layer = [CALayer layer];
  self.tile = tile;
  self.boardViewMetrics = metrics;
  self.dirty = false;

  CGRect layerFrame = CGRectZero;
  layerFrame.size = self.boardViewMetrics.tileSize;
  self.layer.frame = layerFrame;

  self.layer.delegate = self;
  // Without this, all manner of drawing looks blurry on Retina displays
  self.layer.contentsScale = metrics.contentsScale;

  // This disables the implicit animation that normally occurs when the layer
  // delegate is drawing. As always, stackoverflow.com is our friend:
  // http://stackoverflow.com/questions/2244147/disabling-implicit-animations-in-calayer-setneedsdisplayinrect
  NSMutableDictionary* newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"contents", nil];
  self.layer.actions = newActions;
  [newActions release];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardViewLayerDelegateBase
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.layer = nil;
  self.tile = nil;
  self.boardViewMetrics = nil;
  [super dealloc];
}

#pragma mark - BoardViewLayerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method. See the BoardViewLayerDelegateBase
/// class documentation for details about this implementation.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;
    [self.layer setNeedsDisplay];
  }
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method. See the BoardViewLayerDelegateBase
/// class documentation for details about this implementation.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  // empty "do-nothing" implementation
}

#pragma mark - Helper methods for subclasses

// -----------------------------------------------------------------------------
/// @brief Returns an array that identifies the points whose intersections
/// are located on this tile. Array elements are GoPoint objects.
// -----------------------------------------------------------------------------
- (NSArray*) calculateDrawingPointsOnTile
{
  return [self calculateDrawingPointsOnTileWithCallback:nil];
}

// -----------------------------------------------------------------------------
/// @brief Returns an array that identifies the points whose intersections
/// are located on this tile. Array elements are GoPoint objects. If @a callback
/// is not @e nil, invokes @a callback for each GoPoint object that is found to
/// be on this tile.
///
/// The callback must return a boolean value that indicates whether the point
/// should be used or not. Value @e true indicates that the point should be
/// added to the NSArray that is returned, value @e false indicates that the
/// point should not be added (although the point is on this tile).
///
/// The callback can set @a stop to @e true to stop the search for further
/// points before all points have been examined.
///
/// @note Use GoUtilities::pointsInBothFirstArray:andSecondArray:() to find the
/// intersection between the GoPoints returned by this method and some other
/// collection of GoPoints.
// -----------------------------------------------------------------------------
- (NSArray*) calculateDrawingPointsOnTileWithCallback:(bool (^)(GoPoint* point, bool* stop))callback
{
  bool stop = false;
  NSMutableArray* drawingPoints = [NSMutableArray array];

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];

  GoGame* game = [GoGame sharedGame];
  // TODO xxx Optimize this routine instead of doing a brute force iteration
  // over all points. Ideally reverse calculations should be possible to find
  // diagonally opposed corner points. Also if the algorithm is documented
  // callbacks can make assumptions about the order of iteration.
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (! stop && (point = [enumerator nextObject]))
  {
    CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:point
                                                                 metrics:self.boardViewMetrics];
    if (! CGRectIntersectsRect(tileRect, stoneRect))
      continue;

    bool shouldAddPoint = true;
    if (callback)
      shouldAddPoint = callback(point, &stop);

    if (shouldAddPoint)
      [drawingPoints addObject:point];
  }

  return drawingPoints;
}

@end
