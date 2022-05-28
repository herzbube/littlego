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
#import "../../../ui/UiSettingsModel.h"
#import "../../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
@interface SymbolsLayerDelegate()
@property(nonatomic, assign) BoardViewModel* boardViewModel;
@property(nonatomic, assign) BoardPositionModel* boardPositionModel;
@property(nonatomic, assign) UiSettingsModel* uiSettingsModel;
@property(nonatomic, retain) NSMutableParagraphStyle* paragraphStyle;
@property(nonatomic, retain) NSShadow* whiteTextShadow;
@property(nonatomic, retain) UIColor* lastMoveColorOnBlackStone;
@property(nonatomic, retain) UIColor* lastMoveColorOnWhiteStone;
@property(nonatomic, retain) UIColor* connectionFillColor;
@property(nonatomic, retain) UIColor* connectionStrokeColor;
@property(nonatomic, retain) NSDictionary* blackStrokeSymbolLayerTypes;
@property(nonatomic, retain) NSDictionary* whiteStrokeSymbolLayerTypes;
@end


@implementation SymbolsLayerDelegate

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
  self.paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
  self.paragraphStyle.alignment = NSTextAlignmentCenter;
  self.whiteTextShadow = [[[NSShadow alloc] init] autorelease];
  self.whiteTextShadow.shadowColor = [UIColor blackColor];
  self.whiteTextShadow.shadowBlurRadius = 5.0;
  self.whiteTextShadow.shadowOffset = CGSizeMake(1.0, 1.0);
  // Use colors that are not black and white, to distinguish the last move
  // marker from the square symbol
  self.lastMoveColorOnBlackStone = [UIColor redColor];  // relatively low contrast, but good enough for the moment
  self.lastMoveColorOnWhiteStone = [UIColor redColor];
  self.connectionFillColor = [UIColor whiteColor];
  self.connectionStrokeColor = [UIColor blackColor];

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
  self.paragraphStyle = nil;
  self.whiteTextShadow = nil;
  [super dealloc];
}

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
      self.dirty = true;
      break;
    }
    case BVLDEventInvalidateContent:
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
    // We draw completely different symbols in each of the various modes. Also
    // note that the layer is removed/added dynamically as a result of scoring
    // mode becoming enabled/disabled.
    case BVLDEventUIAreaPlayModeChanged:
    case BVLDEventMarkupPrecedenceChanged:
    {
      self.dirty = true;
      break;
    }
    case BVLDEventHandicapPointChanged:
    {
      GoPoint* handicapPoint = eventInfo;
      CGRect drawingRect = [BoardViewDrawingHelper drawingRectForTile:self.tile
                                                      centeredAtPoint:handicapPoint
                                                          withMetrics:self.boardViewMetrics];
      if (CGRectIsEmpty(drawingRect))
        break;

      self.dirty = true;
      break;
    }
    case BVLDEventSelectedSymbolMarkupStyleChanged:
    {
      BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
      [cache invalidateLayerOfType:BlackSelectedSymbolLayerType];
      [cache invalidateLayerOfType:WhiteSelectedSymbolLayerType];
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

  if (uiAreaPlayMode == UIAreaPlayModePlay)
  {
    // A method that wants to draw a piece of markup on a GoPoint must first
    // check this array if the GoPoint is already in the array. If not the
    // method is allowed to draw on the GoPoint. The method must also add the
    // GoPoint to the array, indicating to later methods that markup is already
    // present on the GoPoint. Thus the order in which drawing methods are
    // invoked determines which markup has precedence.
    NSMutableArray* pointsWithMarkup = [NSMutableArray array];

    if ([self shouldDisplayMoveNumbers])
      [self drawMoveNumbersInContext:context inTileWithRect:tileRect pointsWithMarkup:pointsWithMarkup];

    [self drawMarkupInContext:context inTileWithRect:tileRect pointsWithMarkup:pointsWithMarkup];

    if ([self shouldDisplayLastMoveSymbol])
      [self drawLastMoveSymbolInContext:context inTileWithRect:tileRect pointsWithMarkup:pointsWithMarkup];

    if ([self shouldDisplayNextMoveLabel])
      [self drawNextMoveLabelInContext:context inTileWithRect:tileRect pointsWithMarkup:pointsWithMarkup];

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
    blackLastMoveLayer = CreateSquareSymbolLayer(context, self.lastMoveColorOnWhiteStone, self.boardViewMetrics);
    [cache setLayer:blackLastMoveLayer ofType:BlackLastMoveLayerType];
    CGLayerRelease(blackLastMoveLayer);
  }
  CGLayerRef whiteLastMoveLayer = [cache layerOfType:WhiteLastMoveLayerType];
  if (! whiteLastMoveLayer)
  {
    whiteLastMoveLayer = CreateSquareSymbolLayer(context, self.lastMoveColorOnBlackStone, self.boardViewMetrics);
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

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawMoveNumbersInContext:(CGContextRef)context
                   inTileWithRect:(CGRect)tileRect
                 pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  UIFont* moveNumberFont = self.boardViewMetrics.moveNumberFont;

  GoGame* game = [GoGame sharedGame];

  // Use CGFloat here to guarantee that at least 1 move number is displayed.
  // If we were using an integer type here, the result would be truncated,
  // which for very low numbers (e.g. 0.3) would result in 0 move numbers.
  CGFloat numberOfMovesToBeNumbered = game.nodeModel.numberOfMoves * self.boardViewModel.moveNumbersPercentage;
  GoMove* moveToBeNumbered = game.boardPosition.currentNode.goMove;
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
    if ([pointsWithMarkup containsObject:pointToBeNumbered])
      continue;
    [pointsWithMarkup addObject:pointToBeNumbered];

    UIColor* textColor;
    if (moveToBeNumbered == lastMove && self.boardViewModel.markLastMove)
    {
      if (moveToBeNumbered.player.isBlack)
        textColor = self.lastMoveColorOnBlackStone;
      else
        textColor = self.lastMoveColorOnWhiteStone;
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
                                      NSParagraphStyleAttributeName : self.paragraphStyle };
    [BoardViewDrawingHelper drawString:moveNumberText
                           withContext:context
                            attributes:textAttributes
                        inRectWithSize:self.boardViewMetrics.moveNumberMaximumSize
                       centeredAtPoint:pointToBeNumbered
                        inTileWithRect:tileRect
                           withMetrics:self.boardViewMetrics];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:().
// -----------------------------------------------------------------------------
- (void) drawMarkupInContext:(CGContextRef)context
              inTileWithRect:(CGRect)tileRect
            pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoNode* currentNode = boardPosition.currentNode;
  GoNodeMarkup* nodeMarkup = currentNode.goNodeMarkup;
  if (! nodeMarkup)
    return;

  GoBoard* board = game.board;

  if (self.boardViewModel.markupPrecedence == MarkupPrecedenceSymbols)
    [self drawSymbolsMarkup:nodeMarkup.symbols inContext:context inTileWithRect:tileRect board:board pointsWithMarkup:pointsWithMarkup];
  else
    [self drawLabelsMarkup:nodeMarkup.labels inContext:context inTileWithRect:tileRect board:board pointsWithMarkup:pointsWithMarkup];

  [self drawConnectionsMarkup:nodeMarkup.connections inContext:context inTileWithRect:tileRect board:board];

  if (self.boardViewModel.markupPrecedence == MarkupPrecedenceSymbols)
    [self drawLabelsMarkup:nodeMarkup.labels inContext:context inTileWithRect:tileRect board:board pointsWithMarkup:pointsWithMarkup];
  else
    [self drawSymbolsMarkup:nodeMarkup.symbols inContext:context inTileWithRect:tileRect board:board pointsWithMarkup:pointsWithMarkup];

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
          pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  if (! symbols)
    return;

  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];

  [symbols enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* symbolAsNumber, BOOL* stop)
  {
    GoPoint* pointWithSymbol = [board pointAtVertex:vertexString];
    if ([pointsWithMarkup containsObject:pointWithSymbol])
      return;
    [pointsWithMarkup addObject:pointWithSymbol];

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
  }];
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
                                             self.connectionFillColor,
                                             self.connectionStrokeColor,
                                             fromPoint,
                                             toPoint,
                                             canvasRect,
                                             self.boardViewMetrics);

    [BoardViewDrawingHelper drawLayer:layer
                          withContext:context
                         inCanvasRect:canvasRect
                       inTileWithRect:tileRect
                          withMetrics:self.boardViewMetrics];
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
         pointsWithMarkup:(NSMutableArray*)pointsWithMarkup
{
  if (! labels)
    return;

  UIFont* labelFont = self.boardViewMetrics.moveNumberFont;
  if (! labelFont)
    return;

  // Don't limit the label width. Of course, too long labels look ugly, but
  // that's a data problem.
  CGSize labelMaximumSize = CGSizeMake(self.boardViewMetrics.canvasSize.width,
                                       self.boardViewMetrics.moveNumberMaximumSize.height);

  [labels enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSString* labelText, BOOL* stop)
  {
    GoPoint* pointWithLabel = [board pointAtVertex:vertexString];
    if ([pointsWithMarkup containsObject:pointWithLabel])
      return;
    [pointsWithMarkup addObject:pointWithLabel];

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
                          NSParagraphStyleAttributeName : self.paragraphStyle,
                          NSShadowAttributeName: self.whiteTextShadow };
    }
    else
    {
      textAttributes = @{ NSFontAttributeName : labelFont,
                          NSForegroundColorAttributeName : textColor,
                          NSParagraphStyleAttributeName : self.paragraphStyle };
    }

    [BoardViewDrawingHelper drawString:labelText
                           withContext:context
                            attributes:textAttributes
                        inRectWithSize:labelMaximumSize
                       centeredAtPoint:pointWithLabel
                        inTileWithRect:tileRect
                           withMetrics:self.boardViewMetrics];
  }];
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
  if ([pointsWithMarkup containsObject:pointWithNextMoveLabel])
    return;
  [pointsWithMarkup addObject:pointWithNextMoveLabel];

  NSString* nextMoveLabelText = @"A";
  NSDictionary* textAttributes = @{ NSFontAttributeName : self.boardViewMetrics.nextMoveLabelFont,
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : self.paragraphStyle,
                                    NSShadowAttributeName: self.whiteTextShadow };
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
    [BoardViewDrawingHelper drawLayer:whiteLastMoveLayer
                          withContext:context
                      centeredAtPoint:handicapPoint
                       inTileWithRect:tileRect
                          withMetrics:self.boardViewMetrics];
  }
}

@end
