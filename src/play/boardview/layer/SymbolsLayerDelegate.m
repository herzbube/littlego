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
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoMove.h"
#import "../../../go/GoNode.h"
#import "../../../go/GoNodeModel.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"
#import "../../../go/GoUtilities.h"
#import "../../../ui/UiSettingsModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
@interface SymbolsLayerDelegate()
@property(nonatomic, assign) BoardViewModel* boardViewModel;
@property(nonatomic, assign) BoardPositionModel* boardPositionModel;
@property(nonatomic, assign) UiSettingsModel* uiSettingsModel;
@property(nonatomic, retain) NSMutableParagraphStyle* paragraphStyle;
@property(nonatomic, retain) NSShadow* nextMoveShadow;
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
  self.nextMoveShadow = [[[NSShadow alloc] init] autorelease];
  self.nextMoveShadow.shadowColor = [UIColor blackColor];
  self.nextMoveShadow.shadowBlurRadius = 5.0;
  self.nextMoveShadow.shadowOffset = CGSizeMake(1.0, 1.0);
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
  self.nextMoveShadow = nil;
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

  GoGame* game = [GoGame sharedGame];

  BoardViewCGLayerCache* cache = [BoardViewCGLayerCache sharedCache];
  CGLayerRef blackLastMoveLayer = [cache layerOfType:BlackLastMoveLayerType];
  if (! blackLastMoveLayer)
  {
    blackLastMoveLayer = CreateSquareSymbolLayer(context, [UIColor blackColor], self.boardViewMetrics);
    [cache setLayer:blackLastMoveLayer ofType:BlackLastMoveLayerType];
    CGLayerRelease(blackLastMoveLayer);
  }
  CGLayerRef whiteLastMoveLayer = [cache layerOfType:WhiteLastMoveLayerType];
  if (! whiteLastMoveLayer)
  {
    whiteLastMoveLayer = CreateSquareSymbolLayer(context, [UIColor whiteColor], self.boardViewMetrics);
    [cache setLayer:whiteLastMoveLayer ofType:WhiteLastMoveLayerType];
    CGLayerRelease(whiteLastMoveLayer);
  }

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];

  if (uiAreaPlayMode == UIAreaPlayModePlay)
  {
    if ([self shouldDisplayMoveNumbers])
    {
      [self drawMoveNumbersInContext:context inTileWithRect:tileRect];
    }
    else
    {
      if (self.boardViewModel.markLastMove)
      {
        GoMove* mostRecentMove;
        GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:game.boardPosition.currentNode];
        if (nodeWithMostRecentMove)
          mostRecentMove = nodeWithMostRecentMove.goMove;
        else
          mostRecentMove = nil;
        if (mostRecentMove && GoMoveTypePlay == mostRecentMove.type)
        {
          CGLayerRef lastMoveLayer;
          if (mostRecentMove.player.isBlack)
            lastMoveLayer = whiteLastMoveLayer;
          else
            lastMoveLayer = blackLastMoveLayer;
          [BoardViewDrawingHelper drawLayer:lastMoveLayer
                                withContext:context
                            centeredAtPoint:mostRecentMove.point
                             inTileWithRect:tileRect
                                withMetrics:self.boardViewMetrics];
        }
      }
    }

    if ([self shouldDisplayNextMoveLabel])
    {
      [self drawNextMoveInContext:context inTileWithRect:tileRect];
    }
  }
  else if (uiAreaPlayMode == UIAreaPlayModeBoardSetup)
  {
    for (GoPoint* handicapPoint in game.handicapPoints)
    {
      [BoardViewDrawingHelper drawLayer:whiteLastMoveLayer
                            withContext:context
                        centeredAtPoint:handicapPoint
                         inTileWithRect:tileRect
                            withMetrics:self.boardViewMetrics];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
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
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (bool) shouldDisplayNextMoveLabel
{
  if (! self.boardViewMetrics.nextMoveLabelFont)
    return false;
  return self.boardPositionModel.markNextMove;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (void) drawMoveNumbersInContext:(CGContextRef)context
                   inTileWithRect:(CGRect)tileRect
{
  UIFont* moveNumberFont = self.boardViewMetrics.moveNumberFont;

  NSMutableArray* pointsAlreadyNumbered = [NSMutableArray arrayWithCapacity:0];
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
    if ([pointsAlreadyNumbered containsObject:pointToBeNumbered])
      continue;
    [pointsAlreadyNumbered addObject:pointToBeNumbered];

    UIColor* textColor;
    if (moveToBeNumbered == lastMove && self.boardViewModel.markLastMove)
      textColor = [UIColor redColor];
    else if (moveToBeNumbered.player.isBlack)
      textColor = [UIColor whiteColor];
    else
      textColor = [UIColor blackColor];
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
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (void) drawNextMoveInContext:(CGContextRef)context
                inTileWithRect:(CGRect)tileRect
{
  GoGame* game = [GoGame sharedGame];
  GoNode* nodeWithNextMove = [GoUtilities nodeWithNextMove:game.boardPosition.currentNode];
  if (! nodeWithNextMove)
    return;
  GoMove* nextMove = nodeWithNextMove.goMove;
  if (GoMoveTypePlay != nextMove.type)
    return;

  NSString* nextMoveLabelText = @"A";
  NSDictionary* textAttributes = @{ NSFontAttributeName : self.boardViewMetrics.nextMoveLabelFont,
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : self.paragraphStyle,
                                    NSShadowAttributeName: self.nextMoveShadow };
  [BoardViewDrawingHelper drawString:nextMoveLabelText
                         withContext:context
                          attributes:textAttributes
                      inRectWithSize:self.boardViewMetrics.nextMoveLabelMaximumSize
                     centeredAtPoint:nextMove.point
                      inTileWithRect:tileRect
                         withMetrics:self.boardViewMetrics];
}

@end
