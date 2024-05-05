// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewCGLayerCache.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoUtilities.h"
#import "../../../go/GoVertex.h"
#import "../../../ui/CGDrawingHelper.h"
#import "../../../ui/Tile.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StonesLayerDelegate.
// -----------------------------------------------------------------------------
@interface StonesLayerDelegate()
/// @brief List of points whose intersections are located on this tile.
@property(nonatomic, retain) NSMutableDictionary* drawingPoints;
/// @brief Refers to the GoPoint object that marks the current focus of the
/// cross-hair (even if the point is not on this tile).
@property(nonatomic, assign) GoPoint* currentCrossHairPoint;
/// @brief The rectangle for drawing @e currentCrossHairPoint. Is CGRectZero
/// if the cross-hair point is not on this tile.
@property(nonatomic, assign) CGRect drawingRectForCrossHairPoint;
/// @brief The dirty rect calculated by notify:eventInfo:() that later needs to
/// be used by drawLayer(). Used only when drawing is required because of a
/// cross-hair change.
@property(nonatomic, assign) CGRect dirtyRectForCrossHairPoint;
/// @brief The list of GoPoint objects whose intersections are within
/// @e dirtyRectForCrossHairPoint. Calculated by notify:eventInfo:() and later
/// used by drawLayer:inContext:(). Is nil if drawing is not triggered because
/// of a cross-hair change.
@property(nonatomic, retain) NSArray* dirtyPointsForCrossHairPoint;
/// @brief The dirty rect calculated by notify:eventInfo:() that later needs to
/// be used by drawLayer(). Used only when drawing is required because of a
/// setup point change.
@property(nonatomic, assign) CGRect dirtyRectForSetupPoint;
/// @brief The GoPoint object whose intersection is within
/// @e dirtyRectForSetupPoint. Calculated by notify:eventInfo:() and later
/// used by drawLayer:inContext:(). Is nil if drawing is not triggered because
/// of a setup point change.
@property(nonatomic, retain) GoPoint* dirtySetupPoint;
@end


@implementation StonesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a StonesLayerDelegate object.
///
/// @note This is the designated initializer of StonesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  self.drawingPoints = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
  self.currentCrossHairPoint = nil;
  self.drawingRectForCrossHairPoint = CGRectZero;
  self.dirtyRectForCrossHairPoint = CGRectZero;
  self.dirtyPointsForCrossHairPoint = nil;
  self.dirtyRectForSetupPoint = CGRectZero;
  self.dirtySetupPoint = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StonesLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.drawingPoints = nil;
  self.currentCrossHairPoint = nil;
  self.dirtyPointsForCrossHairPoint = nil;
  self.dirtySetupPoint = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the stone layers.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  [cache invalidateLayerOfType:BlackStoneLayerType];
  [cache invalidateLayerOfType:WhiteStoneLayerType];
  [cache invalidateLayerOfType:CrossHairStoneLayerType];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the cross-hair point.
// -----------------------------------------------------------------------------
- (void) invalidateCrossHairPoint
{
  self.currentCrossHairPoint = nil;
  self.drawingRectForCrossHairPoint = CGRectZero;
  self.dirtyPointsForCrossHairPoint = nil;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the cross-hair point dirty rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyRectForCrossHairPoint
{
  self.dirtyRectForCrossHairPoint = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the setup point.
// -----------------------------------------------------------------------------
- (void) invalidateDirtySetupPoint
{
  self.dirtySetupPoint = nil;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the setup point dirty rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyRectForSetupPoint
{
  self.dirtyRectForSetupPoint = CGRectZero;
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
    {
      [self invalidateLayers];
      [self invalidateCrossHairPoint];
      [self invalidateDirtyRectForCrossHairPoint];
      [self invalidateDirtySetupPoint];
      [self invalidateDirtyRectForSetupPoint];
      self.drawingPoints = [self calculateDrawingPoints];
      self.dirty = true;
      break;
    }
    case BVLDEventGoGameStarted:  // place handicap stones
    case BVLDEventInvalidateContent:
    {
      [self invalidateCrossHairPoint];
      [self invalidateDirtyRectForCrossHairPoint];
      [self invalidateDirtySetupPoint];
      [self invalidateDirtyRectForSetupPoint];
      self.drawingPoints = [self calculateDrawingPoints];
      self.dirty = true;
      break;
    }
    case BVLDEventBoardPositionChanged:
    case BVLDEventAllSetupStonesDiscarded:
    {
      [self invalidateCrossHairPoint];
      [self invalidateDirtyRectForCrossHairPoint];
      [self invalidateDirtySetupPoint];
      [self invalidateDirtyRectForSetupPoint];
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
    case BVLDEventPlayStoneDidChange:
    {
      GoPoint* oldCrossHairPoint = self.currentCrossHairPoint;
      GoPoint* newCrossHairPoint = eventInfo;
      if (oldCrossHairPoint == newCrossHairPoint)
        break;
      CGRect oldDrawingRect = self.drawingRectForCrossHairPoint;
      CGRect newDrawingRect = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                         centeredAtPoint:newCrossHairPoint
                                                             withMetrics:self.boardViewMetrics];
      // We need to compare the drawing rectangles, not the cross-hair points.
      // The points may have changed, but if BOTH the old and the new point are
      // not on this tile, the old and the new drawing rectangle have NOT
      // changed - which is exactly what we want.
      if (CGRectEqualToRect(oldDrawingRect, newDrawingRect))
        break;
      // Change both member variables together and without intervening logic so
      // that they cannot get out of sync
      self.currentCrossHairPoint = newCrossHairPoint;
      self.drawingRectForCrossHairPoint = newDrawingRect;
      self.dirty = true;
      if (CGRectIsEmpty(newDrawingRect))
      {
        if (oldCrossHairPoint)
        {
          // The cross-hair stone is no longer visible on this tile (we don't
          // care if moved to a different tile, or if it is gone entirely), so
          // we need to clear the stone from the previous drawing cycle
          self.dirtyRectForCrossHairPoint = oldDrawingRect;
          self.dirtyPointsForCrossHairPoint = [NSArray arrayWithObject:oldCrossHairPoint];
        }
        else
        {
          // The condition that leads to this branch was implemented as part of
          // the attempt to fix issue 242, where without the condition we had a
          // crash because oldCrossHairPoint was nil and we tried to initialize
          // an array with a nil object. Despite extensive code analysis, I did
          // not find out how oldCrossHairPoint can be nil at this point. Though
          // I feel bad about it, I decided to add a bit of defensive
          // programming here, just to make 100% sure that the crash no longer
          // occurs and I can make a quick bugfix release that will make the
          // masses happy.
          // TODO Try to find out how oldCrossHairPoint could be nil at this
          // point. Check the original source (!) because this bit of defensive
          // programming was not the only change. Remove the defensive
          // programming bit if it can be proven that oldCrossHairPoint can
          // never be nil at this point.
          // TODO The scenario described in issue 245 caused this code path to
          // be executed. The issue has been fixed.
          assert(false);
          DDLogError(@"%@: Re-draw entire tile (%d, %d) to clear previous cross-hair point; oldDrawingRect = %@, newDrawingRect = %@",
                     self,
                     self.tile.row,
                     self.tile.column,
                     NSStringFromCGRect(oldDrawingRect),
                     NSStringFromCGRect(newDrawingRect));
          self.dirtyRectForCrossHairPoint = CGRectZero;
          self.dirtyPointsForCrossHairPoint = nil;
        }
      }
      else if (CGRectIsEmpty(oldDrawingRect))
      {
        if (newCrossHairPoint)
        {
          // The cross-hair stone was not visible on this tile in the previous
          // drawing cycle, but now it is
          self.dirtyRectForCrossHairPoint = newDrawingRect;
          self.dirtyPointsForCrossHairPoint = [NSArray arrayWithObject:newCrossHairPoint];
        }
        else
        {
          // This is part of the attempt to fix issue 242. The extensive comment
          // above has the details.
          // TODO The scenario described in issue 245 did NOT cause this code
          // path to be executed.
          assert(false);
          DDLogError(@"%@: Re-draw entire tile (%d, %d) to draw current cross-hair point; oldDrawingRect = %@, newDrawingRect = %@",
                     self,
                     self.tile.row,
                     self.tile.column,
                     NSStringFromCGRect(oldDrawingRect),
                     NSStringFromCGRect(newDrawingRect));
          self.dirtyRectForCrossHairPoint = CGRectZero;  // re-draw the entire tile
          self.dirtyPointsForCrossHairPoint = nil;
        }
      }
      else
      {
        // The cross-hair stone was and still is visible on this tile
        self.dirtyRectForCrossHairPoint = CGRectUnion(oldDrawingRect, newDrawingRect);
        self.dirtyPointsForCrossHairPoint = [GoUtilities pointsInRectangleDelimitedByCornerPoint:oldCrossHairPoint
                                                                             oppositeCornerPoint:newCrossHairPoint
                                                                                          inGame:[GoGame sharedGame]];
      }
      break;
    }
    case BVLDEventHandicapPointChanged:
    case BVLDEventSetupPointChanged:
    {
      GoPoint* setupPoint = eventInfo;
      CGRect drawingRect = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                      centeredAtPoint:setupPoint
                                                          withMetrics:self.boardViewMetrics];
      if (CGRectIsEmpty(drawingRect))
        break;

      self.dirty = true;
      self.dirtySetupPoint = setupPoint;
      self.dirtyRectForSetupPoint = drawingRect;
      self.drawingPoints = [self calculateDrawingPoints];

      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;

    if (CGRectIsEmpty(self.dirtyRectForCrossHairPoint) && CGRectIsEmpty(self.dirtyRectForSetupPoint))
      [self.layer setNeedsDisplay];
    else if (CGRectIsEmpty(self.dirtyRectForCrossHairPoint))
      [self.layer setNeedsDisplayInRect:self.dirtyRectForSetupPoint];
    else
      [self.layer setNeedsDisplayInRect:self.dirtyRectForCrossHairPoint];

    [self invalidateDirtyRectForCrossHairPoint];
    [self invalidateDirtyRectForSetupPoint];
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  CGLayerRef blackStoneLayer = [BoardViewDrawingHelper cachedBlackStoneLayerWithContext:context withMetrics:self.boardViewMetrics];
  CGLayerRef whiteStoneLayer = [BoardViewDrawingHelper cachedWhiteStoneLayerWithContext:context withMetrics:self.boardViewMetrics];
  CGLayerRef crossHairStoneLayer = [BoardViewDrawingHelper cachedCrossHairStoneLayerWithContext:context withMetrics:self.boardViewMetrics];

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;
  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.boardViewMetrics.tileSize];

  [self.drawingPoints enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* stoneStateAsNumber, BOOL* stop)
   {
     // Ignore stoneStateAsNumber, get the current values directly from the
     // GoPoint object
     GoPoint* point = [board pointAtVertex:vertexString];

     // If self.dirtyPointsForCrossHairPoint or self.dirtySetupPoint are set
     // they act as a filter: We don't want to draw more points than those that
     // are within the clipping path that was set up when our implementation of
     // drawLayer() invoked setNeedsDisplayInRect:().
     if (self.dirtyPointsForCrossHairPoint)
     {
       if (! [self.dirtyPointsForCrossHairPoint containsObject:point])
         return;
     }
     else if (self.dirtySetupPoint)
     {
       if (self.dirtySetupPoint != point)
         return;
     }

     CGLayerRef stoneLayer;
     if (point == self.currentCrossHairPoint)
     {
       if (self.currentCrossHairPoint.hasStone)
       {
         stoneLayer = crossHairStoneLayer;
       }
       else
       {
         if (GoColorBlack == game.nextMoveColor)
           stoneLayer = blackStoneLayer;
         else
           stoneLayer = whiteStoneLayer;
       }
     }
     else
     {
       if (! point.hasStone)
         return;
       if (point.blackStone)
         stoneLayer = blackStoneLayer;
       else
         stoneLayer = whiteStoneLayer;
     }
     [BoardViewDrawingHelper drawLayer:stoneLayer
                           withContext:context
                       centeredAtPoint:point
                        inTileWithRect:tileRect
                           withMetrics:self.boardViewMetrics];
  }];

  self.dirtyPointsForCrossHairPoint = nil;
  self.dirtySetupPoint = nil;
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

  CGRect tileRect = [CGDrawingHelper canvasRectForTile:self.tile
                                              withSize:self.boardViewMetrics.tileSize];

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
                                                                 metrics:self.boardViewMetrics];
    if (! CGRectIntersectsRect(tileRect, stoneRect))
      continue;
    NSNumber* stoneStateAsNumber = [[[NSNumber alloc] initWithInt:point.stoneState] autorelease];
    [drawingPoints setObject:stoneStateAsNumber forKey:point.vertex.string];
  }

  return drawingPoints;
}

@end
