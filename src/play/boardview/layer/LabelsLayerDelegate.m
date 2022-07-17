// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "LabelsLayerDelegate.h"
#import "BoardViewCGLayerCache.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoNode.h"
#import "../../../go/GoNodeMarkup.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"
#import "../../../utility/MarkupUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LabelsLayerDelegate.
// -----------------------------------------------------------------------------
@interface LabelsLayerDelegate()
/// @brief List of Go board rows that have intersections with this tile. Each
/// element of the array is an NSNumber object encapsulating an int value that
/// is a row number. Row numbers start at 1. See the GoVertex docs for details
/// on the coordinate system of the Go board.
@property(nonatomic, retain) NSArray* drawingRowsOnTile;
@property(nonatomic, retain) GoPoint* pointWithChangedMarkup;
@property(nonatomic, assign) CGRect dirtyRect;
@property(nonatomic, assign) CGRect temporaryMarkupDrawingRectangle;
@property(nonatomic, assign) bool shouldDrawRowWithTemporaryMarkup;
@property(nonatomic, assign) bool shouldDrawRowWithOriginalMarkup;
@property(nonatomic, retain) GoPoint* drawingPointTemporaryMarkup;
@property(nonatomic, retain) GoPoint* drawingPointOriginalMarkup;
@property(nonatomic, assign) CGRect dirtyRectTemporaryLabel;
@property(nonatomic, assign) CGRect dirtyRectOriginalLabel;
@property(nonatomic, assign) enum MarkupTool temporaryMarkupCategory;
@property(nonatomic, retain) NSString* temporaryLabelText;
@end


@implementation LabelsLayerDelegate

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a LabelsLayerDelegate object.
///
/// @note This is the designated initializer of LabelsLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;

  self.drawingRowsOnTile = nil;
  self.pointWithChangedMarkup = nil;
  self.dirtyRect = CGRectZero;
  self.temporaryMarkupDrawingRectangle = CGRectZero;
  self.shouldDrawRowWithTemporaryMarkup = false;
  self.shouldDrawRowWithOriginalMarkup = false;
  self.drawingPointTemporaryMarkup = nil;
  self.drawingPointOriginalMarkup = nil;
  self.dirtyRectTemporaryLabel = CGRectZero;
  self.dirtyRectOriginalLabel = CGRectZero;
  self.temporaryMarkupCategory = MarkupToolSymbol;
  self.temporaryLabelText = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LabelsLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.drawingRowsOnTile = nil;
  self.pointWithChangedMarkup = nil;
  self.drawingPointTemporaryMarkup = nil;
  self.drawingPointOriginalMarkup = nil;
  self.temporaryLabelText = nil;

  [super dealloc];
}

#pragma mark - State invalidation

// -----------------------------------------------------------------------------
/// @brief Invalidates all drawing rectangles.
// -----------------------------------------------------------------------------
- (void) invalidateDrawingRectangles
{
  self.temporaryMarkupDrawingRectangle = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates all dirty rectangles.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyRects
{
  self.dirtyRect = CGRectZero;
  self.dirtyRectTemporaryLabel = CGRectZero;
  self.dirtyRectOriginalLabel = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates all dirty data.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyData
{
  self.pointWithChangedMarkup = nil;

  self.shouldDrawRowWithTemporaryMarkup = false;
  self.shouldDrawRowWithOriginalMarkup = false;
  self.drawingPointTemporaryMarkup = nil;
  self.drawingPointOriginalMarkup = nil;
  self.temporaryLabelText = nil;
}

#pragma mark - BoardViewLayerDelegate overrides

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
      [self invalidateDrawingRectangles];
      [self invalidateDirtyRects];
      [self invalidateDirtyData];
      [self calculateDrawingRowsOnTile];
      self.dirty = true;
      break;
    }
    case BVLDEventInvalidateContent:
    {
      [self invalidateDrawingRectangles];
      [self invalidateDirtyRects];
      [self invalidateDirtyData];
      [self calculateDrawingRowsOnTile];
      self.dirty = true;
      break;
    }
    // The layer is removed/added dynamically as a result of scoring mode
    // becoming enabled/disabled. This is the only event we get after being
    // added, so we react to it to trigger a redraw.
    case BVLDEventUIAreaPlayModeChanged:
    {
      if (! self.drawingRowsOnTile)
      {
        [self calculateDrawingRowsOnTile];
        self.dirty = true;
      }
      break;
    }
    case BVLDEventBoardPositionChanged:
    case BVLDEventAllMarkupDiscarded:
    {
      [self invalidateDrawingRectangles];
      [self invalidateDirtyRects];
      [self invalidateDirtyData];
      self.dirty = true;
      break;
    }
    case BVLDEventMarkupOnPointsDidChange:
    {
      [self invalidateDirtyRects];
      [self invalidateDirtyData];

      NSArray* eventInfoAsArray = eventInfo;
      NSUInteger eventInfoAsArrayCount = eventInfoAsArray.count;
      if (eventInfoAsArrayCount == 0)
      {
        self.pointWithChangedMarkup = nil;
        self.dirtyRect = CGRectZero;
        self.dirty = true;
      }
      else if (eventInfoAsArrayCount == 1 || eventInfoAsArrayCount == 2)
      {
        // If the point is in one of the rows on this tile then we have to
        // redraw the row even if the thing that changed was something else than
        // a label. Reason: The thing could be a symbol or marker that has
        // REPLACED a label that we drew in a previous drawing cycle, i.e. we
        // have to REMOVE that label now. Unfortunately we don't know anything
        // about the previous content to make any optimizations.

        GoPoint* pointWithChangedMarkup = eventInfoAsArray.firstObject;
        CGRect drawingRect = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                   inRowContainingPoint:pointWithChangedMarkup
                                                            withMetrics:self.boardViewMetrics];
        // TODO xxx we could also calculate the point's row and look it up in self.drawingRowsOnTile
        if (CGRectIsEmpty(drawingRect))
          break;

        self.pointWithChangedMarkup = pointWithChangedMarkup;
        self.dirtyRect = drawingRect;
        self.dirty = true;
      }

      break;
    }
    // We do drawing for temporary markup even if it's a symbol or marker that
    // is being moved => the symbol or marker could be moved over a label, in
    // which case we don't draw the label (to indicate that it would be replaced
    // if the panning gesture ended now).
    case BVLDEventMarkupSymbolDidMove:
    case BVLDEventMarkupMarkerDidMove:
    case BVLDEventMarkupLabelDidMove:
    {
      NSArray* eventInfoAsArray = eventInfo;
      bool eventInfoIsEmpty = eventInfoAsArray.count == 0;

      GoPoint* newDrawingPointTemporaryMarkup;
      NSString* newTemporaryLabelText = nil;
      enum MarkupTool newTemporaryMarkupCategory;
      if (event == BVLDEventMarkupSymbolDidMove)
      {
        newDrawingPointTemporaryMarkup = eventInfoIsEmpty ? nil : [eventInfoAsArray objectAtIndex:1];
        newTemporaryMarkupCategory = MarkupToolSymbol;
      }
      else
      {
        newDrawingPointTemporaryMarkup = eventInfoIsEmpty ? nil : [eventInfoAsArray objectAtIndex:2];
        newTemporaryMarkupCategory = (event == BVLDEventMarkupMarkerDidMove) ? MarkupToolMarker : MarkupToolLabel;

        if (event == BVLDEventMarkupLabelDidMove)
          newTemporaryLabelText = eventInfoIsEmpty ? nil : [eventInfoAsArray objectAtIndex:1];
      }

      if (newDrawingPointTemporaryMarkup == self.drawingPointTemporaryMarkup)
        break;

      // IMPORTANT: The following logic only works if there is a drawing cycle
      // between each notify:eventInfo: that changes something on this tile.
      // If there is no drawing cycle then we will forget about original
      // content to be restored.

      self.drawingPointOriginalMarkup = self.drawingPointTemporaryMarkup;
      self.drawingPointTemporaryMarkup = newDrawingPointTemporaryMarkup;

      self.temporaryMarkupCategory = newTemporaryMarkupCategory;
      self.temporaryLabelText = newTemporaryLabelText;

      CGRect oldTemporaryMarkupDrawingRectangle = self.temporaryMarkupDrawingRectangle;
      CGRect newTemporaryMarkupDrawingRectangle = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                                        inRowContainingPoint:newDrawingPointTemporaryMarkup
                                                                                 withMetrics:self.boardViewMetrics];

      bool oldTemporaryMarkupDrawingRectangleWasOnTile = ! CGRectIsEmpty(oldTemporaryMarkupDrawingRectangle);
      self.shouldDrawRowWithOriginalMarkup = oldTemporaryMarkupDrawingRectangleWasOnTile;
      self.dirtyRectOriginalLabel = oldTemporaryMarkupDrawingRectangleWasOnTile ? oldTemporaryMarkupDrawingRectangle : CGRectZero;

      bool newTemporaryMarkupDrawingRectangleIsOnTile = ! CGRectIsEmpty(newTemporaryMarkupDrawingRectangle);
      self.shouldDrawRowWithTemporaryMarkup = newTemporaryMarkupDrawingRectangleIsOnTile;
      self.dirtyRectTemporaryLabel = newTemporaryMarkupDrawingRectangleIsOnTile ? newTemporaryMarkupDrawingRectangle : CGRectZero;

      self.temporaryMarkupDrawingRectangle = newTemporaryMarkupDrawingRectangle;

      if (self.shouldDrawRowWithTemporaryMarkup || self.shouldDrawRowWithOriginalMarkup)
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
/// @brief Helper for notify:eventInfo:().
// -----------------------------------------------------------------------------
- (void) calculateDrawingRowsOnTile
{
  // TODO xxx currently it looks as if nobody is using this, so remove if not really needed

  NSMutableArray* drawingRowsOnTile = [NSMutableArray array];

  NSArray* drawingPointsOnTile = [self calculateDrawingPointsOnTile];
  for (GoPoint* drawingPointOnTile in drawingPointsOnTile)
  {
    NSNumber* row = [NSNumber numberWithInt:drawingPointOnTile.vertex.numeric.y];
    if (! [drawingRowsOnTile containsObject:row])
      [drawingRowsOnTile addObject:row];
  }

  self.drawingRowsOnTile = drawingRowsOnTile;
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;
    if (CGRectIsEmpty(self.dirtyRect) && CGRectIsEmpty(self.dirtyRectOriginalLabel) && CGRectIsEmpty(self.dirtyRectTemporaryLabel))
    {
      [self.layer setNeedsDisplay];
    }
    else
    {
      if (! CGRectIsEmpty(self.dirtyRect))
      {
        [self.layer setNeedsDisplayInRect:self.dirtyRect];
      }
      else
      {
        if (! CGRectIsEmpty(self.dirtyRectOriginalLabel))
          [self.layer setNeedsDisplayInRect:self.dirtyRectOriginalLabel];
        if (! CGRectIsEmpty(self.dirtyRectTemporaryLabel))
          [self.layer setNeedsDisplayInRect:self.dirtyRectTemporaryLabel];
      }
    }
    [self invalidateDirtyRects];
  }
}

#pragma mark - CALayerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief CALayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  if (! self.boardViewMetrics.markupLabelFont)
    return;

  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoNode* currentNode = boardPosition.currentNode;
  GoNodeMarkup* nodeMarkup = currentNode.goNodeMarkup;
  if (! nodeMarkup || ! nodeMarkup.labels)
    return;

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];

  GoBoard* board = game.board;

  if (self.shouldDrawRowWithTemporaryMarkup && self.temporaryLabelText)
  {
    if (self.temporaryMarkupCategory == MarkupToolLabel)
    {
      [self drawLabelMarkup:self.temporaryLabelText
                  inContext:context
             inTileWithRect:tileRect
                    atPoint:self.drawingPointTemporaryMarkup];
    }
    else
    {
      // Do not draw - the symbol or marker being moved is drawn in another
      // layer
    }
  }

  [nodeMarkup.labels enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSString* labelText, BOOL* stop)
  {
    // TODO xxx label type should already be available from GoNodeMarkup
    enum GoMarkupLabel labelType = [MarkupUtilities labelTypeOfLabel:labelText];
    if (labelType != GoMarkupLabelLabel)
        return;

    GoPoint* pointWithLabel = [board pointAtVertex:vertexString];
    int rowOfPointWithLabel = pointWithLabel.vertex.numeric.y;

    if (self.shouldDrawRowWithTemporaryMarkup || self.shouldDrawRowWithOriginalMarkup)
    {
      bool shouldDrawLabel = false;
      if (self.shouldDrawRowWithTemporaryMarkup)
      {
        // If the label is on the very same point as the temporary markup then
        // don't draw it - the temporary markup should replace the other label
        if (pointWithLabel == self.drawingPointTemporaryMarkup)
          return;

        int rowOfDrawingPointTemporaryMarkup = self.drawingPointTemporaryMarkup.vertex.numeric.y;
        if (rowOfPointWithLabel == rowOfDrawingPointTemporaryMarkup)
          shouldDrawLabel = true;
      }
      if (self.shouldDrawRowWithOriginalMarkup && ! shouldDrawLabel)
      {
        int rowOfDrawingPointOriginalMarkup = self.drawingPointOriginalMarkup.vertex.numeric.y;
        if (rowOfPointWithLabel == rowOfDrawingPointOriginalMarkup)
          shouldDrawLabel = true;
      }
      if (! shouldDrawLabel)
        return;
    }
    else if (self.pointWithChangedMarkup)
    {
      // TODO xxx who resets self.pointWithChangedMarkup?
      int rowOfPointWithChangedMarkup = self.pointWithChangedMarkup.vertex.numeric.y;
      if (rowOfPointWithLabel != rowOfPointWithChangedMarkup)
        return;
    }

    CGRect canvasRect = [BoardViewDrawingHelper canvasRectForRowContainingPoint:pointWithLabel
                                                                        metrics:self.boardViewMetrics];
    // TODO xxx we could also calculate the point's row and look it up in self.drawingRowsOnTile
    if (! CGRectIntersectsRect(tileRect, canvasRect))
      return;

    [self drawLabelMarkup:labelText
                inContext:context
           inTileWithRect:tileRect
                  atPoint:pointWithLabel];
  }];
}


#pragma mark - Drawing helpers

// -----------------------------------------------------------------------------
/// @brief Private helper that draws a single label.
// -----------------------------------------------------------------------------
- (void) drawLabelMarkup:(NSString*)labelText
               inContext:(CGContextRef)context
          inTileWithRect:(CGRect)tileRect
                 atPoint:(GoPoint*)pointWithLabel
{
  CGSize labelMaximumSize = self.boardViewMetrics.markupLabelMaximumSize;

  // Labels are expected to be long'ish texts that extend outside of a single
  // point cell, so the text must be visible on a variety of backgrounds (white
  // or black stones, but also the board's wooden background). We therefore use
  // white text color and add a shadow to the white colored text to make it
  // visible against a white background.
  UIColor* textColor = [UIColor whiteColor];
  NSDictionary* textAttributes = @{ NSFontAttributeName : self.boardViewMetrics.markupLabelFont,
                                    NSForegroundColorAttributeName : textColor,
                                    NSParagraphStyleAttributeName : self.boardViewMetrics.paragraphStyle,
                                    NSShadowAttributeName: self.boardViewMetrics.whiteTextShadow };

  [BoardViewDrawingHelper drawString:labelText
                         withContext:context
                          attributes:textAttributes
                      inRectWithSize:labelMaximumSize
                     centeredAtPoint:pointWithLabel
                      inTileWithRect:tileRect
                         withMetrics:self.boardViewMetrics];
}

@end
