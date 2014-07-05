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
#import "CrossHairLinesLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// CrossHairLinesLayerDelegate.
// -----------------------------------------------------------------------------
@interface CrossHairLinesLayerDelegate()
/// @brief Store drawing rectangles between notify:eventInfo:() and
/// drawLayer:inContext:(), and also between drawing cycles.
@property(nonatomic, retain) NSMutableArray* drawingRectangles;
/// @brief Store dirty rect between notify:eventInfo:() and drawLayer().
@property(nonatomic, assign) CGRect dirtyRect;
@end


@implementation CrossHairLinesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CrossHairLinesLayerDelegate object.
///
/// @note This is the designated initializer of CrossHairLinesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  self.drawingRectangles = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
  self.dirtyRect = CGRectZero;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrossHairLinesLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.drawingRectangles = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates all drawing rectangles.
// -----------------------------------------------------------------------------
- (void) invalidateDrawingRectangles
{
  [self.drawingRectangles removeAllObjects];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the dirty rectangle.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyRect
{
  self.dirtyRect = CGRectZero;
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
    case BVLDEventInvalidateContent:
    {
      [self invalidateDrawingRectangles];
      [self invalidateDirtyRect];
      self.dirty = true;
      break;
    }
    case BVLDEventCrossHairChanged:
    {
      // We need to compare the drawing rectangles, not the dirty rects. For
      // instance, if newDrawingRectangles is empty, but oldDrawingRectangles
      // is not, this means that we need to draw to clear the line(s) from the
      // previous drawing cycle. The old and the new dirty rects, however, are
      // the same, so it's clear that we can't just compare those.
      NSMutableArray* oldDrawingRectangles = self.drawingRectangles;
      NSMutableArray* newDrawingRectangles = [self calculateDrawingRectanglesForCrossHairPoint:eventInfo];
      if (! [oldDrawingRectangles isEqualToArray:newDrawingRectangles])
      {
        // Keep oldDrawingRectangles alive, otherwise overwriting the
        // drawingRectangles property value will dealloc oldDrawingRectangles
        [[oldDrawingRectangles retain] autorelease];
        self.drawingRectangles = newDrawingRectangles;

        CGRect oldDirtyRect = [CrossHairLinesLayerDelegate unionRectFromDrawingRectangles:oldDrawingRectangles];
        CGRect newDirtyRect = [CrossHairLinesLayerDelegate unionRectFromDrawingRectangles:newDrawingRectangles];
        self.dirtyRect = CGRectUnion(oldDirtyRect, newDirtyRect);
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
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;
    if (CGRectIsEmpty(self.dirtyRect))
      [self.layer setNeedsDisplay];
    else
      [self.layer setNeedsDisplayInRect:self.dirtyRect];
    [self invalidateDirtyRect];
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  // If we don't have any pre-calculated drawing rectangles we draw nothing
  // which results in an empty layer
  CGContextSetFillColorWithColor(context, self.boardViewMetrics.crossHairColor.CGColor);
  for (NSValue* drawingRectValue in self.drawingRectangles)
  {
    CGRect drawingRect = [drawingRectValue CGRectValue];
    CGContextFillRect(context, drawingRect);
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an array that contains 0-2 rectangles that need to be filled
/// with a color to draw the cross-hair lines that intersect at the specified
/// cross-hair point.
///
/// The array contains 0 rectangles if neither the horizontal nor the vertical
/// cross-hair line intersect with this tile.
///
/// The array contains 1-2 rectangles if either the horizontal or the vertical
/// or both cross-hair lines intersect with this tile.
// -----------------------------------------------------------------------------
- (NSMutableArray*) calculateDrawingRectanglesForCrossHairPoint:(GoPoint*)crossHairPoint
{
  NSMutableArray* drawingRectangles = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
  if (! crossHairPoint)
    return drawingRectangles;

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];
  CGPoint crossHairPointCoordinates = [self.boardViewMetrics coordinatesFromPoint:crossHairPoint];

  for (NSValue* lineRectValue in self.boardViewMetrics.lineRectangles)
  {
    CGRect lineRect = [lineRectValue CGRectValue];
    if (! CGRectContainsPoint(lineRect, crossHairPointCoordinates))
      continue;
    CGRect drawingRect = CGRectIntersection(tileRect, lineRect);
    if (CGRectIsNull(drawingRect))
      continue;
    drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:drawingRect
                                                     inTileWithRect:tileRect];
    [drawingRectangles addObject:[NSValue valueWithCGRect:drawingRect]];
  }

  return drawingRectangles;
}

// -----------------------------------------------------------------------------
/// @brief Returns a CGRect that is the union of all rectangles in
/// @a drawingRectangles.
// -----------------------------------------------------------------------------
+ (CGRect) unionRectFromDrawingRectangles:(NSArray*)drawingRectangles
{
  CGRect unionRect = CGRectZero;
  for (NSValue* drawingRectValue in drawingRectangles)
  {
    CGRect drawingRect = [drawingRectValue CGRectValue];
    if (CGRectIsEmpty(unionRect))
      unionRect = drawingRect;
    else
      unionRect = CGRectUnion(unionRect, drawingRect);
  }
  return unionRect;
}

@end
