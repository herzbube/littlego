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
#import "SymbolsLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardPositionModel.h"
#import "../../model/PlayViewMetrics.h"
#import "../../model/PlayViewModel.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoMove.h"
#import "../../../go/GoMoveModel.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoScore.h"


CGLayerRef blackLastMoveLayer;
CGLayerRef whiteLastMoveLayer;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
@interface BVSymbolsLayerDelegate()
@property(nonatomic, assign) PlayViewModel* playViewModel;
@property(nonatomic, assign) BoardPositionModel* boardPositionModel;
@property(nonatomic, retain) NSMutableParagraphStyle* paragraphStyle;
@property(nonatomic, retain) NSShadow* nextMoveShadow;
@end


@implementation BVSymbolsLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a SymbolsLayerDelegate object.
///
/// @note This is the designated initializer of SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile
            metrics:(PlayViewMetrics*)metrics
      playViewModel:(PlayViewModel*)playViewModel
 boardPositionModel:(BoardPositionModel*)boardPositionmodel
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  _playViewModel = playViewModel;
  _boardPositionModel = boardPositionmodel;
  self.paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
  self.paragraphStyle.alignment = NSTextAlignmentCenter;
  self.nextMoveShadow = [[[NSShadow alloc] init] autorelease];
  self.nextMoveShadow.shadowColor = [UIColor blackColor];
  self.nextMoveShadow.shadowBlurRadius = 5.0;
  self.nextMoveShadow.shadowOffset = CGSizeMake(1.0, 1.0);
  blackLastMoveLayer = NULL;
  whiteLastMoveLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SymbolsLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self invalidateLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates layers with "last move" symbols.
// -----------------------------------------------------------------------------
- (void) invalidateLayers
{
  if (blackLastMoveLayer)
  {
    CGLayerRelease(blackLastMoveLayer);
    blackLastMoveLayer = NULL;
  }
  if (whiteLastMoveLayer)
  {
    CGLayerRelease(whiteLastMoveLayer);
    whiteLastMoveLayer = NULL;
  }
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
    // TODO xxx remove the next two cases; the layer is added/removed
    // dynamically as a result of scoring becoming enabled/disabled
    case BVLDEventScoringModeEnabled:   // temporarily disable symbols
    case BVLDEventScoringModeDisabled:  // re-enable symbols
    case BVLDEventMarkNextMoveChanged:
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
  // Completely disable symbols while scoring mode is enabled
  GoGame* game = [GoGame sharedGame];
  if (game.score.scoringEnabled)
    return;
  DDLogVerbose(@"SymbolsLayerDelegate is drawing");

  if (! blackLastMoveLayer)
    blackLastMoveLayer = BVCreateSquareSymbolLayer(context, [UIColor blackColor], self.playViewMetrics);
  if (! whiteLastMoveLayer)
    whiteLastMoveLayer = BVCreateSquareSymbolLayer(context, [UIColor whiteColor], self.playViewMetrics);

  CGRect canvasRectTile = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                            metrics:self.playViewMetrics];

  if ([self shouldDisplayMoveNumbers])
  {
    [self drawMoveNumbersInContext:context inTileWithRect:canvasRectTile];
  }
  else
  {
    if (self.playViewModel.markLastMove)
    {
      GoMove* lastMove = game.boardPosition.currentMove;
      if (lastMove && GoMoveTypePlay == lastMove.type)
      {
        CGLayerRef lastMoveLayer;
        if (lastMove.player.isBlack)
          lastMoveLayer = whiteLastMoveLayer;
        else
          lastMoveLayer = blackLastMoveLayer;
        [BoardViewDrawingHelper drawLayer:lastMoveLayer
                              withContext:context
                          centeredAtPoint:lastMove.point
                           inTileWithRect:canvasRectTile
                              withMetrics:self.playViewMetrics];
      }
    }
  }

  if ([self shouldDisplayNextMoveLabel])
  {
    [self drawNextMoveInContext:context inTileWithRect:canvasRectTile];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (bool) shouldDisplayMoveNumbers
{
  if (! self.playViewMetrics.moveNumberFont)
    return false;
  else if (0.0 == self.playViewModel.moveNumbersPercentage)
    return false;
  else
    return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (bool) shouldDisplayNextMoveLabel
{
  if (! self.playViewMetrics.nextMoveLabelFont)
    return false;
  return self.boardPositionModel.markNextMove;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (void) drawMoveNumbersInContext:(CGContextRef)context
                   inTileWithRect:(CGRect)tileRect
{
  UIFont* moveNumberFont = self.playViewMetrics.moveNumberFont;
  DDLogVerbose(@"Drawing move numbers with font size %f", moveNumberFont.pointSize);

  NSMutableArray* pointsAlreadyNumbered = [NSMutableArray arrayWithCapacity:0];
  GoGame* game = [GoGame sharedGame];

  // Use CGFloat here to guarantee that at least 1 move number is displayed.
  // If we were using an integer type here, the result would be truncated,
  // which for very low numbers (e.g. 0.3) would result in 0 move numbers.
  CGFloat numberOfMovesToBeNumbered = game.moveModel.numberOfMoves * self.playViewModel.moveNumbersPercentage;
  GoMove* moveToBeNumbered = game.boardPosition.currentMove;
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
    if (moveToBeNumbered == lastMove && self.playViewModel.markLastMove)
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
                        inRectWithSize:self.playViewMetrics.moveNumberMaximumSize
                       centeredAtPoint:pointToBeNumbered
                        inTileWithRect:tileRect
                           withMetrics:self.playViewMetrics];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (void) drawNextMoveInContext:(CGContextRef)context
                inTileWithRect:(CGRect)tileRect
{
  GoGame* game = [GoGame sharedGame];
  if (game.boardPosition.isLastPosition)
    return;
  GoMove* nextMove;
  if (game.boardPosition.isFirstPosition)
    nextMove = game.firstMove;
  else
    nextMove = game.boardPosition.currentMove.next;
  if (GoMoveTypePlay != nextMove.type)
    return;

  NSString* nextMoveLabelText = @"A";
  NSDictionary* textAttributes = @{ NSFontAttributeName : self.playViewMetrics.nextMoveLabelFont,
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : self.paragraphStyle,
                                    NSShadowAttributeName: self.nextMoveShadow };
  [BoardViewDrawingHelper drawString:nextMoveLabelText
                         withContext:context
                          attributes:textAttributes
                      inRectWithSize:self.playViewMetrics.nextMoveLabelMaximumSize
                     centeredAtPoint:nextMove.point
                      inTileWithRect:tileRect
                         withMetrics:self.playViewMetrics];
}

@end
