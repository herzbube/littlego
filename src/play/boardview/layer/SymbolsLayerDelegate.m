// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "SymbolsLayerDelegate.h"
#import "BoardViewCGLayerCache.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardPositionModel.h"
#import "../../model/BoardViewMetrics.h"
#import "../../model/BoardViewModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoMove.h"
#import "../../../go/GoNode.h"
#import "../../../go/GoNodeMarkup.h"
#import "../../../go/GoNodeModel.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"
#import "../../../go/GoUtilities.h"
#import "../../../go/GoVertex.h"
#import "../../../ui/UiSettingsModel.h"
#import "../../../utility/MarkupUtilities.h"
#import "../../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
@interface SymbolsLayerDelegate()
@property(nonatomic, assign) BoardViewModel* boardViewModel;
@property(nonatomic, assign) BoardPositionModel* boardPositionModel;
@property(nonatomic, assign) UiSettingsModel* uiSettingsModel;
@property(nonatomic, retain) NSDictionary* blackStrokeSymbolLayerTypes;
@property(nonatomic, retain) NSDictionary* whiteStrokeSymbolLayerTypes;
/// @brief List of GoPoint objects for points that are on this tile.
@property(nonatomic, retain) NSArray* drawingPointsOnTile;
@property(nonatomic, retain) GoPoint* drawingPoint;
@property(nonatomic, retain) NSArray* pointsOnTileInConnectionRectangle;
@property(nonatomic, assign) CGRect dirtyRect;
@property(nonatomic, assign) CGRect temporaryMarkupDrawingRectangle;
@property(nonatomic, assign) bool shouldDrawTemporaryMarkup;
@property(nonatomic, assign) bool shouldDrawOriginalMarkup;
@property(nonatomic, retain) GoPoint* drawingPointTemporaryMarkup;
@property(nonatomic, retain) GoPoint* drawingPointOriginalMarkup;
@property(nonatomic, assign) CGRect dirtyRectTemporaryMarkup;
@property(nonatomic, assign) CGRect dirtyRectOriginalMarkup;
@property(nonatomic, assign) enum MarkupTool temporaryMarkupCategory;
@property(nonatomic, retain) NSNumber* temporarySymbolAsNumber;
@property(nonatomic, retain) NSNumber* temporaryLabelAsNumber;
@property(nonatomic, retain) NSString* temporaryLabelText;
@end


@implementation SymbolsLayerDelegate

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a SymbolsLayerDelegate object.
///
/// @note This is the designated initializer of SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile
            metrics:(BoardViewMetrics*)metrics
     boardViewModel:(BoardViewModel*)boardViewModel
 boardPositionModel:(BoardPositionModel*)boardPositionmodel
    uiSettingsModel:(UiSettingsModel*)uiSettingsModel
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;

  _boardViewModel = boardViewModel;
  _boardPositionModel = boardPositionmodel;
  _uiSettingsModel = uiSettingsModel;

  self.blackStrokeSymbolLayerTypes = @{
    [NSNumber numberWithInt:GoMarkupSymbolCircle] : [NSNumber numberWithInt:BlackCircleSymbolLayerType],
    [NSNumber numberWithInt:GoMarkupSymbolSquare] : [NSNumber numberWithInt:BlackSquareSymbolLayerType],
    [NSNumber numberWithInt:GoMarkupSymbolTriangle] : [NSNumber numberWithInt:BlackTriangleSymbolLayerType],
    [NSNumber numberWithInt:GoMarkupSymbolX] : [NSNumber numberWithInt:BlackXSymbolLayerType],
    [NSNumber numberWithInt:GoMarkupSymbolSelected] : [NSNumber numberWithInt:BlackSelectedSymbolLayerType],
  };
  self.whiteStrokeSymbolLayerTypes = @{
    [NSNumber numberWithInt:GoMarkupSymbolCircle] : [NSNumber numberWithInt:WhiteCircleSymbolLayerType],
    [NSNumber numberWithInt:GoMarkupSymbolSquare] : [NSNumber numberWithInt:WhiteSquareSymbolLayerType],
    [NSNumber numberWithInt:GoMarkupSymbolTriangle] : [NSNumber numberWithInt:WhiteTriangleSymbolLayerType],
    [NSNumber numberWithInt:GoMarkupSymbolX] : [NSNumber numberWithInt:WhiteXSymbolLayerType],
    [NSNumber numberWithInt:GoMarkupSymbolSelected] : [NSNumber numberWithInt:WhiteSelectedSymbolLayerType],
  };

  self.drawingPointsOnTile = @[];
  self.pointsOnTileInConnectionRectangle = nil;
  self.drawingPoint = nil;
  self.dirtyRect = CGRectZero;
  self.temporaryMarkupDrawingRectangle = CGRectZero;
  self.shouldDrawTemporaryMarkup = false;
  self.shouldDrawOriginalMarkup = false;
  self.drawingPointTemporaryMarkup = nil;
  self.drawingPointOriginalMarkup = nil;
  self.dirtyRectTemporaryMarkup = CGRectZero;
  self.dirtyRectOriginalMarkup = CGRectZero;
  self.temporaryMarkupCategory = MarkupToolSymbol;
  self.temporarySymbolAsNumber = nil;
  self.temporaryLabelAsNumber = nil;
  self.temporaryLabelText = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SymbolsLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // There are times when no SymbolsLayerDelegate instances are around to react
  // to events that invalidate the cached CGLayers, so the cached CGLayers will
  // inevitably become out-of-date. To prevent this, we invalidate the CGLayers
  // *NOW*.
  [self invalidateLayers];

  self.boardViewModel = nil;
  self.boardPositionModel = nil;

  self.drawingPointsOnTile = nil;
  self.pointsOnTileInConnectionRectangle = nil;
  self.drawingPoint = nil;
  self.drawingPointTemporaryMarkup = nil;
  self.drawingPointOriginalMarkup = nil;
  self.temporarySymbolAsNumber = nil;
  self.temporaryLabelAsNumber = nil;
  self.temporaryLabelText = nil;

  [super dealloc];
}

#pragma mark - State invalidation

// -----------------------------------------------------------------------------
/// @brief Invalidates layers with "last move" symbols.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  [cache invalidateLayerOfType:BlackLastMoveLayerType];
  [cache invalidateLayerOfType:WhiteLastMoveLayerType];
  [self.blackStrokeSymbolLayerTypes enumerateKeysAndObjectsUsingBlock:^(NSNumber* symbolAsNumber, NSNumber* layerTypeAsNumber, BOOL* stop)
  {
    enum LayerType layerType = layerTypeAsNumber.intValue;
    [cache invalidateLayerOfType:layerType];
  }];
  [self.whiteStrokeSymbolLayerTypes enumerateKeysAndObjectsUsingBlock:^(NSNumber* symbolAsNumber, NSNumber* layerTypeAsNumber, BOOL* stop)
  {
    enum LayerType layerType = layerTypeAsNumber.intValue;
    [cache invalidateLayerOfType:layerType];
  }];
}

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
  self.dirtyRectTemporaryMarkup = CGRectZero;
  self.dirtyRectOriginalMarkup = CGRectZero;
}

// -----------------------------------------------------------------------------
/// @brief Invalidates all dirty data.
// -----------------------------------------------------------------------------
- (void) invalidateDirtyData
{
  self.drawingPoint = nil;
  self.pointsOnTileInConnectionRectangle = nil;

  self.shouldDrawTemporaryMarkup = false;
  self.shouldDrawOriginalMarkup = false;
  self.drawingPointTemporaryMarkup = nil;
  self.drawingPointOriginalMarkup = nil;
  self.temporarySymbolAsNumber = nil;
  self.temporaryLabelAsNumber = nil;
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
      [self invalidateLayers];
      [self invalidateDrawingRectangles];
      [self invalidateDirtyRects];
      [self invalidateDirtyData];
      self.drawingPointsOnTile = [self calculateDrawingPointsOnTile];
      self.dirty = true;
      break;
    }
    case BVLDEventInvalidateContent:
    // We draw completely different symbols in each of the various modes. Also
    // the layer is removed/added dynamically as a result of scoring mode
    // becoming enabled/disabled. This is the only event we get after being
    // added, so we react to it to trigger a redraw.
    case BVLDEventUIAreaPlayModeChanged:
    {
      [self invalidateDrawingRectangles];
      [self invalidateDirtyRects];
      [self invalidateDirtyData];
      self.drawingPointsOnTile = [self calculateDrawingPointsOnTile];
      self.dirty = true;
      break;
    }
    case BVLDEventGoGameStarted:        // clear last move marker
    case BVLDEventBoardPositionChanged:
    // This case covers the following scenario: Board position 0 is selected
    // and the user discards all board positions. In this scenario the event
    // BVLDEventBoardPositionChanged - which usually covers the discard of board
    // positions - does NOT fire because the board position does NOT change.
    case BVLDEventNumberOfBoardPositionsChanged:
    case BVLDEventMarkLastMoveChanged:
    case BVLDEventMoveNumbersPercentageChanged:
    case BVLDEventMarkNextMoveChanged:
    // Marker/symbol precedence is handled in this layer. Label/symbol
    // precedence is handled by reordering layers.
    case BVLDEventMarkupPrecedenceChanged:
    case BVLDEventAllMarkupDiscarded:
    {
      [self invalidateDrawingRectangles];
      [self invalidateDirtyRects];
      [self invalidateDirtyData];
      self.dirty = true;
      break;
    }
    case BVLDEventHandicapPointChanged:
    case BVLDEventMarkupOnPointsDidChange:
    {
      [self invalidateDirtyRects];
      [self invalidateDirtyData];

      NSArray* pointsWithChangedMarkup = eventInfo;
      NSUInteger pointsWithChangedMarkupCount = pointsWithChangedMarkup.count;
      if (pointsWithChangedMarkupCount == 0)
      {
        self.drawingPoint = nil;
        self.pointsOnTileInConnectionRectangle = nil;
        self.dirty = true;
      }
      else if (pointsWithChangedMarkupCount == 1 || pointsWithChangedMarkupCount == 2)
      {
        if (pointsWithChangedMarkupCount == 2)
        {
          NSNumber* labelAsNumber = pointsWithChangedMarkup.lastObject;
          enum GoMarkupLabel label = labelAsNumber.intValue;
          // TODO xxx if no drawing is necessary for labels, do we need to invoke the invalidate... methods at the start of the case?
          if (label == GoMarkupLabelLabel)
            break;
        }

        GoPoint* pointThatChanged = pointsWithChangedMarkup.firstObject;
        CGRect drawingRect = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                        centeredAtPoint:pointThatChanged
                                                            withMetrics:self.boardViewMetrics];
        if (! CGRectIsEmpty(drawingRect))
        {
          self.drawingPoint = pointThatChanged;
          self.pointsOnTileInConnectionRectangle = nil;
          self.dirtyRect = drawingRect;
          self.dirty = true;
        }
      }
      else
      {
        GoPoint* connectionFromPoint = [pointsWithChangedMarkup objectAtIndex:0];
        GoPoint* connectionToPoint = [pointsWithChangedMarkup objectAtIndex:1];
        NSArray* pointsInConnectionRectangle = [pointsWithChangedMarkup objectAtIndex:2];

        CGRect drawingRect = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                              fromPoint:connectionFromPoint
                                                                toPoint:connectionToPoint
                                                            withMetrics:self.boardViewMetrics];
        if (! CGRectIsEmpty(drawingRect))
        {
          self.drawingPoint = nil;
          self.pointsOnTileInConnectionRectangle = [GoUtilities pointsInBothFirstArray:self.drawingPointsOnTile
                                                                        andSecondArray:pointsInConnectionRectangle];
          self.dirtyRect = drawingRect;
          self.dirty = true;
        }
      }

      break;
    }
    case BVLDEventMarkupSymbolDidMove:
    case BVLDEventMarkupMarkerDidMove:
    // We do drawing for temporary markup even if it's a label that is being
    // moved => the label could be moved over a symbol or marker, in which case
    // we don't draw the symbol or marker (to indicate that it would be replaced
    // if the panning gesture ended now).
    case BVLDEventMarkupLabelDidMove:
    {
      NSArray* eventInfoAsArray = eventInfo;
      bool eventInfoIsEmpty = eventInfoAsArray.count == 0;

      GoPoint* newDrawingPointTemporaryMarkup;
      if (event == BVLDEventMarkupSymbolDidMove)
      {
        NSNumber* symbolAsNumber = eventInfoIsEmpty ? nil : [eventInfoAsArray objectAtIndex:0];
        newDrawingPointTemporaryMarkup = eventInfoIsEmpty ? nil : [eventInfoAsArray objectAtIndex:1];

        if (newDrawingPointTemporaryMarkup == self.drawingPointTemporaryMarkup)
          break;

        self.temporaryMarkupCategory = MarkupToolSymbol;
        self.temporarySymbolAsNumber = symbolAsNumber;
      }
      else
      {
        NSNumber* labelAsNumber = eventInfoIsEmpty ? nil : [eventInfoAsArray objectAtIndex:0];
        NSString* labelText = eventInfoIsEmpty ? nil : [eventInfoAsArray objectAtIndex:1];
        newDrawingPointTemporaryMarkup = eventInfoIsEmpty ? nil : [eventInfoAsArray objectAtIndex:2];

        if (newDrawingPointTemporaryMarkup == self.drawingPointTemporaryMarkup)
          break;

        if (event == BVLDEventMarkupMarkerDidMove)
        {
          self.temporaryMarkupCategory = MarkupToolMarker;
          self.temporaryLabelAsNumber = labelAsNumber;
          self.temporaryLabelText = labelText;
        }
        else
        {
          self.temporaryMarkupCategory = MarkupToolLabel;
        }
      }

      // IMPORTANT: The following logic only works if there is a drawing cycle
      // between each notify:eventInfo: that changes something on this tile.
      // If there is no drawing cycle then we will forget about original
      // content to be restored.

      self.drawingPointOriginalMarkup = self.drawingPointTemporaryMarkup;
      self.drawingPointTemporaryMarkup = newDrawingPointTemporaryMarkup;

      CGRect oldTemporaryMarkupDrawingRectangle = self.temporaryMarkupDrawingRectangle;
      CGRect newTemporaryMarkupDrawingRectangle = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                                             centeredAtPoint:newDrawingPointTemporaryMarkup
                                                                                 withMetrics:self.boardViewMetrics];
      if (! CGRectEqualToRect(oldTemporaryMarkupDrawingRectangle, newTemporaryMarkupDrawingRectangle))
      {
        bool oldTemporaryMarkupDrawingRectangleWasOnTile = ! CGRectIsEmpty(oldTemporaryMarkupDrawingRectangle);
        self.shouldDrawOriginalMarkup = oldTemporaryMarkupDrawingRectangleWasOnTile;
        self.dirtyRectOriginalMarkup = oldTemporaryMarkupDrawingRectangleWasOnTile ? oldTemporaryMarkupDrawingRectangle : CGRectZero;

        bool newTemporaryMarkupDrawingRectangleIsOnTile = ! CGRectIsEmpty(newTemporaryMarkupDrawingRectangle);
        self.shouldDrawTemporaryMarkup = newTemporaryMarkupDrawingRectangleIsOnTile;
        self.dirtyRectTemporaryMarkup = newTemporaryMarkupDrawingRectangleIsOnTile ? newTemporaryMarkupDrawingRectangle : CGRectZero;

        self.temporaryMarkupDrawingRectangle = newTemporaryMarkupDrawingRectangle;
        self.dirty = true;
      }

      break;
    }
    case BVLDEventSelectedSymbolMarkupStyleChanged:
    {
      BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
      [cache invalidateLayerOfType:BlackSelectedSymbolLayerType];
      [cache invalidateLayerOfType:WhiteSelectedSymbolLayerType];
      [self invalidateDirtyData];
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
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;
    if (CGRectIsEmpty(self.dirtyRect) && CGRectIsEmpty(self.dirtyRectOriginalMarkup) && CGRectIsEmpty(self.dirtyRectTemporaryMarkup))
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
        if (! CGRectIsEmpty(self.dirtyRectOriginalMarkup))
          [self.layer setNeedsDisplayInRect:self.dirtyRectOriginalMarkup];
        if (! CGRectIsEmpty(self.dirtyRectTemporaryMarkup))
          [self.layer setNeedsDisplayInRect:self.dirtyRectTemporaryMarkup];
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
  enum UIAreaPlayMode uiAreaPlayMode = self.uiSettingsModel.uiAreaPlayMode;

  // Completely disable symbols while scoring mode is enabled
  if (uiAreaPlayMode == UIAreaPlayModeScoring)
    return;

  // Make sure that layers are created before drawing methods that use them are
  // invoked
  [self createLayersIfNecessaryWithContext:context];

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];

  if (uiAreaPlayMode == UIAreaPlayModePlay || uiAreaPlayMode == UIAreaPlayModeEditMarkup)
  {
    // A method that wants to draw something on a GoPoint must first
    // check this array if the GoPoint is already in the array. If not the
    // method is allowed to draw on the GoPoint. The method must also add the
    // GoPoint to the array, indicating to later methods that markup is already
    // present on the GoPoint. Thus the order in which drawing methods are
    // invoked determines which markup has precedence.
    NSMutableArray* pointsWithMarkup = [NSMutableArray array];

    // A method that wants to draw something on a GoPoint must first check this
    // array if the GoPoint is in the array. If not the method is not allowed
    // draw on the GoPoint.
    NSMutableArray* pointsToDrawOn = [NSMutableArray array];

    // Optimization: Drawing original markup is the only other drawing
    // operation that is possible at the same time as drawing temporary
    // markup. So if we don't draw original markup, this flag will get set so
    // that we can skip most of the other drawing routines.
    bool shouldDrawTemporaryMarkupOnly = false;

    if (self.shouldDrawOriginalMarkup || self.shouldDrawTemporaryMarkup)
    {
      // A panning gesture has started, is ongoing, or has ended. We need to
      // draw temporary markup and/or restore original markup that was overdrawn
      // by temporary markup in the previous drawing cycle.

      if (self.shouldDrawTemporaryMarkup)
      {
        // Set flag, as documented above
        shouldDrawTemporaryMarkupOnly = ! self.shouldDrawOriginalMarkup;

        // Make sure that nobody else is drawing over the temporary markup
        [pointsWithMarkup addObject:self.drawingPointTemporaryMarkup];
      }

      if (self.shouldDrawOriginalMarkup)
        [pointsToDrawOn addObject:self.drawingPointOriginalMarkup];
    }
    else
    {
      // Either an element (e.g. markup symbol or label, handicap stone) has
      // been placed on or removed from a single intersection, or a markup
      // connection has been placed or removed. Here we add add the affected
      // points to the pointsToDrawOn array so that not the entire layer needs
      // to be redrawn.

      if (self.drawingPoint)
        [pointsToDrawOn addObject:self.drawingPoint];
      else if (self.pointsOnTileInConnectionRectangle)
        [pointsToDrawOn addObjectsFromArray:self.pointsOnTileInConnectionRectangle];
    }

    if (pointsToDrawOn.count == 0)
      pointsToDrawOn = nil;

    // Drawing markup must have the highest precedence so that in markup editing
    // mode the user can see what she can move around with a panning gesture.
    // Theoretically we could draw markup with different precedences in
    // different modes, but a conscious decision was made against this because
    // it would probably be confusing for the user if in one mode a markup
    // element would be displayed, while in another mode the same markup element
    // would be hidden (e.g. because a move number had precedence).
    // Note: Unfortunately, even if we only draw temporary markup we still have
    // to draw connections because we don't know how they intersect with the
    // temporary markup.
    [self drawMarkupInContext:context inTileWithRect:tileRect pointsToDrawOn:pointsToDrawOn pointsWithMarkup:pointsWithMarkup drawConnectionsOnly:shouldDrawTemporaryMarkupOnly];

    if ([self shouldDisplayMoveNumbers] && ! shouldDrawTemporaryMarkupOnly)
      [self drawMoveNumbersInContext:context inTileWithRect:tileRect pointsToDrawOn:pointsToDrawOn pointsWithMarkup:pointsWithMarkup];

    if (self.shouldDrawTemporaryMarkup)
      [self drawTemporaryMarkupInContext:context inTileWithRect:tileRect];

    if ([self shouldDisplayLastMoveSymbol] && ! shouldDrawTemporaryMarkupOnly)
      [self drawLastMoveSymbolInContext:context inTileWithRect:tileRect pointsToDrawOn:pointsToDrawOn pointsWithMarkup:pointsWithMarkup];

    if ([self shouldDisplayNextMoveLabel] && ! shouldDrawTemporaryMarkupOnly)
      [self drawNextMoveLabelInContext:context inTileWithRect:tileRect pointsToDrawOn:pointsToDrawOn pointsWithMarkup:pointsWithMarkup];
  }
  else if (uiAreaPlayMode == UIAreaPlayModeBoardSetup)
  {
    [self drawHandicapStoneSymbolInContext:context inTileWithRect:tileRect];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) createLayersIfNecessaryWithContext:(CGContextRef)context
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  CGLayerRef blackLastMoveLayer = [cache layerOfType:BlackLastMoveLayerType];
  if (! blackLastMoveLayer)
  {
    blackLastMoveLayer = CreateSquareSymbolLayer(context, self.boardViewMetrics.lastMoveColorOnWhiteStone, self.boardViewMetrics);
    [cache setLayer:blackLastMoveLayer ofType:BlackLastMoveLayerType];
    CGLayerRelease(blackLastMoveLayer);
  }
  CGLayerRef whiteLastMoveLayer = [cache layerOfType:WhiteLastMoveLayerType];
  if (! whiteLastMoveLayer)
  {
    whiteLastMoveLayer = CreateSquareSymbolLayer(context, self.boardViewMetrics.lastMoveColorOnBlackStone, self.boardViewMetrics);
    [cache setLayer:whiteLastMoveLayer ofType:WhiteLastMoveLayerType];
    CGLayerRelease(whiteLastMoveLayer);
  }
  [self createSymbolLayersIfNecessary:self.blackStrokeSymbolLayerTypes withFillColor:[UIColor whiteColor] strokeColor:[UIColor blackColor] context:context];
  [self createSymbolLayersIfNecessary:self.whiteStrokeSymbolLayerTypes withFillColor:[UIColor blackColor] strokeColor:[UIColor whiteColor] context:context];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createLayersIfNecessaryWithContext:().
// -----------------------------------------------------------------------------
- (void) createSymbolLayersIfNecessary:(NSDictionary*)symbolLayerTypes withFillColor:(UIColor*)fillColor strokeColor:(UIColor*)strokeColor context:(CGContextRef)context
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  [symbolLayerTypes enumerateKeysAndObjectsUsingBlock:^(NSNumber* symbolAsNumber, NSNumber* layerTypeAsNumber, BOOL* stop)
  {
    enum LayerType layerType = layerTypeAsNumber.intValue;
    CGLayerRef layer = [cache layerOfType:layerType];
    if (! layer)
    {
      enum GoMarkupSymbol symbol = symbolAsNumber.intValue;
      layer = CreateSymbolLayer(context, symbol, fillColor, strokeColor, self.boardViewModel, self.boardViewMetrics);
      [cache setLayer:layer ofType:layerType];
      CGLayerRelease(layer);
    }
  }];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (bool) shouldDisplayMoveNumbers
{
  if (! self.boardViewMetrics.moveNumberFont)
    return false;
  else if (0.0 == self.boardViewModel.moveNumbersPercentage)
    return false;
  else
    return true;
}

#pragma mark - Drawing - Move numbers

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawMoveNumbersInContext:(CGContextRef)context
                   inTileWithRect:(CGRect)tileRect
                   pointsToDrawOn:(NSArray*)pointsToDrawOn
                 pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  UIFont* moveNumberFont = self.boardViewMetrics.moveNumberFont;

  GoGame* game = [GoGame sharedGame];

  // Use CGFloat here to guarantee that at least 1 move number is displayed.
  // If we were using an integer type here, the result would be truncated,
  // which for very low numbers (e.g. 0.3) would result in 0 move numbers.
  CGFloat numberOfMovesToBeNumbered = game.nodeModel.numberOfMoves * self.boardViewModel.moveNumbersPercentage;
  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:game.boardPosition.currentNode];
  if (! nodeWithMostRecentMove)
    return;

  // Optimization: We don't want the pointsWithMarkup array to grow while we are
  // iterating, because this would vastly increase the time for checking for
  // membership on each iteration. The requirement is that we must not draw on
  // points where some OTHER routine has already drawn its stuff, so checking
  // for membership on the original non-growing array is sufficient.
  NSMutableArray* newPointsWithMarkup = [NSMutableArray array];

  GoMove* moveToBeNumbered = nodeWithMostRecentMove.goMove;
  GoMove* lastMove = moveToBeNumbered;
  for (;
       moveToBeNumbered && numberOfMovesToBeNumbered > 0;
       moveToBeNumbered = moveToBeNumbered.previous, --numberOfMovesToBeNumbered  // two actions !!
       )
  {
    if (GoMoveTypePlay != moveToBeNumbered.type)
      continue;
    GoPoint* pointToBeNumbered = moveToBeNumbered.point;
    if (GoColorNone == pointToBeNumbered.stoneState)
      continue;  // stone placed by this move was captured by a later move
    if (self.shouldDrawTemporaryMarkup && self.drawingPointTemporaryMarkup == pointToBeNumbered)
      continue;  // during panning temporary markup is allowed to be drawn instead of a move number
    if (pointsToDrawOn && ! [pointsToDrawOn containsObject:pointToBeNumbered])
      continue;
    if (! [self.drawingPointsOnTile containsObject:pointToBeNumbered])
      continue;
    if ([pointsWithMarkup containsObject:pointToBeNumbered])
      continue;
    [newPointsWithMarkup addObject:pointToBeNumbered];

    UIColor* textColor;
    if (moveToBeNumbered == lastMove && self.boardViewModel.markLastMove)
    {
      if (moveToBeNumbered.player.isBlack)
        textColor = self.boardViewMetrics.lastMoveColorOnBlackStone;
      else
        textColor = self.boardViewMetrics.lastMoveColorOnWhiteStone;
    }
    else if (moveToBeNumbered.player.isBlack)
    {
      textColor = [UIColor whiteColor];
    }
    else
    {
      textColor = [UIColor blackColor];
    }
    NSString* moveNumberText = [NSString stringWithFormat:@"%d", moveToBeNumbered.moveNumber];
    NSDictionary* textAttributes = @{ NSFontAttributeName : moveNumberFont,
                                      NSForegroundColorAttributeName : textColor,
                                      NSParagraphStyleAttributeName : self.boardViewMetrics.paragraphStyle };
    [BoardViewDrawingHelper drawString:moveNumberText
                           withContext:context
                            attributes:textAttributes
                        inRectWithSize:self.boardViewMetrics.moveNumberMaximumSize
                       centeredAtPoint:pointToBeNumbered
                        inTileWithRect:tileRect
                           withMetrics:self.boardViewMetrics];
  }

  [pointsWithMarkup addObjectsFromArray:newPointsWithMarkup];
}

#pragma mark - Drawing - Temporary markup

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
///
/// Unlike other drawing routines, this method takes the data to draw not from
/// GoNodeMarkup but from member variables.
// -----------------------------------------------------------------------------
- (void) drawTemporaryMarkupInContext:(CGContextRef)context
                       inTileWithRect:(CGRect)tileRect
{
  if (self.temporaryMarkupCategory == MarkupToolSymbol)
  {
    BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
    [self drawSymbolMarkup:self.temporarySymbolAsNumber
                  inContext:context
             inTileWithRect:tileRect
                    atPoint:self.drawingPointTemporaryMarkup
                  withCache:cache];
  }
  else if (self.temporaryMarkupCategory == MarkupToolMarker)
  {
    [self drawLabelMarkup:self.temporaryLabelText
                inContext:context
           inTileWithRect:tileRect
                  atPoint:self.drawingPointTemporaryMarkup
                labelType:self.temporaryLabelAsNumber.intValue];
  }
  else if (self.temporaryMarkupCategory == MarkupToolLabel)
  {
    // Do not draw - the label being moved is drawn in another layer
  }
  else
  {
    assert(0);
  }
}

#pragma mark - Drawing - Markup

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawMarkupInContext:(CGContextRef)context
              inTileWithRect:(CGRect)tileRect
              pointsToDrawOn:(NSArray*)pointsToDrawOn
            pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
         drawConnectionsOnly:(bool)drawConnectionsOnly
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoNode* currentNode = boardPosition.currentNode;
  GoNodeMarkup* nodeMarkup = currentNode.goNodeMarkup;
  if (! nodeMarkup)
    return;

  GoBoard* board = game.board;

  // We don't pass pointsToDrawOn or pointsWithMarkup to the connection drawing
  // routine because all parts of connections that are on this tile have to be
  // re-drawn in full because we don't know how connection rectangles intersect
  // with any point cells on this tile.
  [self drawConnectionsMarkup:nodeMarkup.connections inContext:context inTileWithRect:tileRect board:board];

  if (drawConnectionsOnly)
    return;

  if (self.boardViewModel.markupPrecedence == MarkupPrecedenceSymbols)
  {
    [self drawSymbolsMarkup:nodeMarkup.symbols inContext:context inTileWithRect:tileRect board:board pointsToDrawOn:pointsToDrawOn pointsWithMarkup:pointsWithMarkup];
    [self drawLabelsMarkup:nodeMarkup.labels inContext:context inTileWithRect:tileRect board:board pointsToDrawOn:pointsToDrawOn pointsWithMarkup:pointsWithMarkup];
  }
  else
  {
    [self drawLabelsMarkup:nodeMarkup.labels inContext:context inTileWithRect:tileRect board:board pointsToDrawOn:pointsToDrawOn pointsWithMarkup:pointsWithMarkup];
    [self drawSymbolsMarkup:nodeMarkup.symbols inContext:context inTileWithRect:tileRect board:board pointsToDrawOn:pointsToDrawOn pointsWithMarkup:pointsWithMarkup];
  }

  [self drawDimmingsMarkup:nodeMarkup.dimmings inContext:context inTileWithRect:tileRect board:board];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// drawMarkupInContext:inTileWithRect:pointsWithMarkup:().
// -----------------------------------------------------------------------------
- (void) drawSymbolsMarkup:(NSDictionary*)symbols
                 inContext:(CGContextRef)context
            inTileWithRect:(CGRect)tileRect
                     board:(GoBoard*)board
            pointsToDrawOn:(NSArray*)pointsToDrawOn
          pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  if (! symbols)
    return;

  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];

  [symbols enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* symbolAsNumber, BOOL* stop)
  {
    GoPoint* pointWithSymbol = [board pointAtVertex:vertexString];
    if (pointsToDrawOn && ! [pointsToDrawOn containsObject:pointWithSymbol])
      return;
    if (! [self.drawingPointsOnTile containsObject:pointWithSymbol])
      return;
    if ([pointsWithMarkup containsObject:pointWithSymbol])
      return;
    [pointsWithMarkup addObject:pointWithSymbol];

    [self drawSymbolMarkup:symbolAsNumber
                 inContext:context
            inTileWithRect:tileRect
                   atPoint:pointWithSymbol
                 withCache:cache];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Private helper that draws a single symbol.
// -----------------------------------------------------------------------------
- (void) drawSymbolMarkup:(NSNumber*)symbolAsNumber
                inContext:(CGContextRef)context
           inTileWithRect:(CGRect)tileRect
                  atPoint:(GoPoint*)pointWithSymbol
                withCache:(BoardViewCGLayerCache*)cache
{
  enum GoMarkupSymbol symbol = [symbolAsNumber intValue];

  NSDictionary* symbolLayerTypes;
  if (symbol == GoMarkupSymbolSelected && self.boardViewModel.selectedSymbolMarkupStyle == SelectedSymbolMarkupStyleDotSymbol)
  {
    // The "dot" symbol not only consist of a stroke, it is also filled
    // with the color opposite to the stroke color. Because of that the
    // symbol's primary color is the fill color and we have to invert the
    // logic that is used for the other symbols.
    if (pointWithSymbol.stoneState == GoColorWhite)
      symbolLayerTypes = self.whiteStrokeSymbolLayerTypes;
    else
      symbolLayerTypes = self.blackStrokeSymbolLayerTypes;  // use white filled dot also when intersection is not occupied
  }
  else
  {
    if (pointWithSymbol.stoneState == GoColorBlack)
      symbolLayerTypes = self.whiteStrokeSymbolLayerTypes;
    else
      symbolLayerTypes = self.blackStrokeSymbolLayerTypes;  // use black also when intersection is not occupied
  }

  NSNumber* layerTypeAsNumber = symbolLayerTypes[symbolAsNumber];
  enum LayerType layerType = layerTypeAsNumber.intValue;
  CGLayerRef layer = [cache layerOfType:layerType];

  [BoardViewDrawingHelper drawLayer:layer
                        withContext:context
                    centeredAtPoint:pointWithSymbol
                     inTileWithRect:tileRect
                        withMetrics:self.boardViewMetrics];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// drawMarkupInContext:inTileWithRect:pointsWithMarkup:().
// -----------------------------------------------------------------------------
- (void) drawConnectionsMarkup:(NSDictionary*)connections
                     inContext:(CGContextRef)context
                inTileWithRect:(CGRect)tileRect
                         board:(GoBoard*)board
{
  if (! connections)
    return;

  [connections enumerateKeysAndObjectsUsingBlock:^(NSArray* vertexStrings, NSNumber* connectionAsNumber, BOOL* stop)
  {
    enum GoMarkupConnection connection = connectionAsNumber.intValue;
    GoPoint* fromPoint = [board pointAtVertex:[vertexStrings firstObject]];
    GoPoint* toPoint = [board pointAtVertex:[vertexStrings lastObject]];

    // For symbols which have a fixed size and appearance we can use a
    // pre-drawn and cached layer. This is not possible for connections
    // because they vary in size and angle - every connection has to be drawn
    // on demand. Because of this we try to avoid the drawing if it is
    // not necessary. Unlike with symbols we make the tile intersection check
    // already here in the layer delegate.
    CGRect canvasRect = [BoardViewDrawingHelper canvasRectFromPoint:fromPoint
                                                            toPoint:toPoint
                                                            metrics:self.boardViewMetrics];
    if (! CGRectIntersectsRect(tileRect, canvasRect))
      return;

    CGLayerRef layer = CreateConnectionLayer(context,
                                             connection,
                                             self.boardViewMetrics.connectionFillColor,
                                             self.boardViewMetrics.connectionStrokeColor,
                                             fromPoint,
                                             toPoint,
                                             canvasRect,
                                             self.boardViewMetrics);

    [BoardViewDrawingHelper drawLayer:layer
                          withContext:context
                         inCanvasRect:canvasRect
                       inTileWithRect:tileRect
                          withMetrics:self.boardViewMetrics];

    CGLayerRelease(layer);
  }];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// drawMarkupInContext:inTileWithRect:pointsWithMarkup:().
// -----------------------------------------------------------------------------
- (void) drawLabelsMarkup:(NSDictionary*)labels
                inContext:(CGContextRef)context
           inTileWithRect:(CGRect)tileRect
                    board:(GoBoard*)board
           pointsToDrawOn:(NSArray*)pointsToDrawOn
         pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  if (! labels)
    return;

  if (! self.boardViewMetrics.markupLetterMarkerFont &&
      ! self.boardViewMetrics.markupNumberMarkerFont)
  {
    return;
  }

  [labels enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSArray* labelTypeAndText, BOOL* stop)
  {
    GoPoint* pointWithLabel = [board pointAtVertex:vertexString];
    if (pointsToDrawOn && ! [pointsToDrawOn containsObject:pointWithLabel])
      return;
    if (! [self.drawingPointsOnTile containsObject:pointWithLabel])
      return;
    if ([pointsWithMarkup containsObject:pointWithLabel])
      return;
    [pointsWithMarkup addObject:pointWithLabel];

    // Non-marker labels are drawn on LabelsLayerDelegate. We abort the drawing
    // only after pointsWithMarkup has been populated, because even if we don't
    // draw the non-marker label in this layer, we want to prevent this layer
    // from drawing other lower-precedence drawing artifacts (e.g. move
    // numbers).
    NSNumber* labelTypeAsNumber = labelTypeAndText.firstObject;
    enum GoMarkupLabel labelType = labelTypeAsNumber.intValue;
    if (labelType == GoMarkupLabelLabel)
      return;

    NSString* labelText = labelTypeAndText.lastObject;

    [self drawLabelMarkup:labelText
                inContext:context
           inTileWithRect:tileRect
                  atPoint:pointWithLabel
                labelType:labelType];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Private helper that draws a single label.
// -----------------------------------------------------------------------------
- (void) drawLabelMarkup:(NSString*)labelText
               inContext:(CGContextRef)context
          inTileWithRect:(CGRect)tileRect
                 atPoint:(GoPoint*)pointWithLabel
               labelType:(enum GoMarkupLabel)labelType
{
  UIFont* labelFont;
  CGSize labelMaximumSize;
  [self drawingParametersForLabel:labelType
                             font:&labelFont
                  textMaximumSize:&labelMaximumSize];
  if (! labelFont)
    return;

  // Use white text color when intersection is not occupied, because black
  // colored text is difficult to read on the board's wooden background.
  UIColor* textColor;
  if (pointWithLabel.stoneState == GoColorWhite)
    textColor = [UIColor blackColor];
  else
    textColor = [UIColor whiteColor];

  // For unoccupied intersections add a shadow to the white colored text to
  // improve readability even more
  NSDictionary* textAttributes;
  if (pointWithLabel.stoneState == GoColorNone)
  {
    textAttributes = @{ NSFontAttributeName : labelFont,
                        NSForegroundColorAttributeName : textColor,
                        NSParagraphStyleAttributeName : self.boardViewMetrics.paragraphStyle,
                        NSShadowAttributeName: self.boardViewMetrics.whiteTextShadow };
  }
  else
  {
    textAttributes = @{ NSFontAttributeName : labelFont,
                        NSForegroundColorAttributeName : textColor,
                        NSParagraphStyleAttributeName : self.boardViewMetrics.paragraphStyle };
  }

  [BoardViewDrawingHelper drawString:labelText
                         withContext:context
                          attributes:textAttributes
                      inRectWithSize:labelMaximumSize
                     centeredAtPoint:pointWithLabel
                      inTileWithRect:tileRect
                         withMetrics:self.boardViewMetrics];
}

// -----------------------------------------------------------------------------
/// @brief Determines drawing parameters for drawing a marker or label of type
/// @a label. Fills the out variables @a font and @a textMaximumSize with the
/// parameters found.
// -----------------------------------------------------------------------------
- (void) drawingParametersForLabel:(enum GoMarkupLabel)label
                              font:(UIFont**)font
                   textMaximumSize:(CGSize*)textMaximumSize
{
  switch (label)
  {
    case GoMarkupLabelMarkerNumber:
      *font = self.boardViewMetrics.markupNumberMarkerFont;
      *textMaximumSize = self.boardViewMetrics.markupNumberMarkerMaximumSize;
      break;
    case GoMarkupLabelMarkerLetter:
      *font = self.boardViewMetrics.markupLetterMarkerFont;
      *textMaximumSize = self.boardViewMetrics.markupLetterMarkerMaximumSize;
      break;
    default:
      assert(0);
      *font = nil;
      *textMaximumSize = CGSizeZero;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// drawMarkupInContext:inTileWithRect:pointsWithMarkup:().
// -----------------------------------------------------------------------------
- (void) drawDimmingsMarkup:(NSArray*)dimmings
                  inContext:(CGContextRef)context
             inTileWithRect:(CGRect)tileRect
                      board:(GoBoard*)board
{
  if (! dimmings)
    return;

  // Dimming is currently not supported by this app
}

#pragma mark - Drawing - Last move symbol

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (bool) shouldDisplayLastMoveSymbol
{
  return self.boardViewModel.markLastMove;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawLastMoveSymbolInContext:(CGContextRef)context
                      inTileWithRect:(CGRect)tileRect
                      pointsToDrawOn:(NSArray*)pointsToDrawOn
                    pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  GoGame* game = [GoGame sharedGame];
  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:game.boardPosition.currentNode];
  if (! nodeWithMostRecentMove)
    return;

  GoMove* mostRecentMove = nodeWithMostRecentMove.goMove;
  if (GoMoveTypePlay != mostRecentMove.type)
    return;

  GoPoint* pointWithLastMoveSymbol = mostRecentMove.point;
  if (pointsToDrawOn && ! [pointsToDrawOn containsObject:pointWithLastMoveSymbol])
    return;
  if (! [self.drawingPointsOnTile containsObject:pointWithLastMoveSymbol])
    return;
  if ([pointsWithMarkup containsObject:pointWithLastMoveSymbol])
    return;
  [pointsWithMarkup addObject:pointWithLastMoveSymbol];

  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  CGLayerRef blackLastMoveLayer = [cache layerOfType:BlackLastMoveLayerType];
  CGLayerRef whiteLastMoveLayer = [cache layerOfType:WhiteLastMoveLayerType];

  CGLayerRef lastMoveLayer;
  if (mostRecentMove.player.isBlack)
    lastMoveLayer = whiteLastMoveLayer;
  else
    lastMoveLayer = blackLastMoveLayer;

  [BoardViewDrawingHelper drawLayer:lastMoveLayer
                        withContext:context
                    centeredAtPoint:pointWithLastMoveSymbol
                     inTileWithRect:tileRect
                        withMetrics:self.boardViewMetrics];
}

#pragma mark - Drawing - Next move label

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (bool) shouldDisplayNextMoveLabel
{
  if (! self.boardViewMetrics.nextMoveLabelFont)
    return false;
  return self.boardPositionModel.markNextMove;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawNextMoveLabelInContext:(CGContextRef)context
                     inTileWithRect:(CGRect)tileRect
                     pointsToDrawOn:(NSArray*)pointsToDrawOn
                   pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  GoGame* game = [GoGame sharedGame];
  GoNode* nodeWithNextMove = [GoUtilities nodeWithNextMove:game.boardPosition.currentNode];
  if (! nodeWithNextMove)
    return;

  GoMove* nextMove = nodeWithNextMove.goMove;
  if (GoMoveTypePlay != nextMove.type)
    return;

  GoPoint* pointWithNextMoveLabel = nextMove.point;
  if (pointsToDrawOn && ! [pointsToDrawOn containsObject:pointWithNextMoveLabel])
    return;
  if (! [self.drawingPointsOnTile containsObject:pointWithNextMoveLabel])
    return;
  if ([pointsWithMarkup containsObject:pointWithNextMoveLabel])
    return;
  [pointsWithMarkup addObject:pointWithNextMoveLabel];

  NSString* nextMoveLabelText = @"A";
  NSDictionary* textAttributes = @{ NSFontAttributeName : self.boardViewMetrics.nextMoveLabelFont,
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : self.boardViewMetrics.paragraphStyle,
                                    NSShadowAttributeName: self.boardViewMetrics.whiteTextShadow };
  [BoardViewDrawingHelper drawString:nextMoveLabelText
                         withContext:context
                          attributes:textAttributes
                      inRectWithSize:self.boardViewMetrics.nextMoveLabelMaximumSize
                     centeredAtPoint:pointWithNextMoveLabel
                      inTileWithRect:tileRect
                         withMetrics:self.boardViewMetrics];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawHandicapStoneSymbolInContext:(CGContextRef)context
                           inTileWithRect:(CGRect)tileRect
{
  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  CGLayerRef whiteLastMoveLayer = [cache layerOfType:WhiteLastMoveLayerType];

  GoGame* game = [GoGame sharedGame];
  for (GoPoint* handicapPoint in game.handicapPoints)
  {
    if (! [self.drawingPointsOnTile containsObject:handicapPoint])
      return;

    [BoardViewDrawingHelper drawLayer:whiteLastMoveLayer
                          withContext:context
                      centeredAtPoint:handicapPoint
                       inTileWithRect:tileRect
                          withMetrics:self.boardViewMetrics];
  }
}

@end
