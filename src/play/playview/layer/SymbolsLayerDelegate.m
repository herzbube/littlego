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
#import "PlayViewDrawingHelper.h"
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

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
@interface SymbolsLayerDelegate()
@property(nonatomic, assign) BoardPositionModel* boardPositionModel;
@property(nonatomic, retain) NSMutableParagraphStyle* paragraphStyle;
@property(nonatomic, retain) NSShadow* shadow;
@property(nonatomic, assign) CGLayerRef blackLastMoveLayer;
@property(nonatomic, assign) CGLayerRef whiteLastMoveLayer;
@property(nonatomic, assign) CGLayerRef nextMoveLayer;
@end


@implementation SymbolsLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a SymbolsLayerDelegate object.
///
/// @note This is the designated initializer of SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithMainView:(UIView*)mainView
                metrics:(PlayViewMetrics*)metrics
          playViewModel:(PlayViewModel*)playViewModel
     boardPositionModel:(BoardPositionModel*)boardPositionmodel
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithMainView:mainView metrics:metrics model:playViewModel];
  if (! self)
    return nil;
  _boardPositionModel = boardPositionmodel;
  self.paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
  self.paragraphStyle.alignment = NSTextAlignmentCenter;
  self.shadow = [[[NSShadow alloc] init] autorelease];
  self.shadow.shadowColor = [UIColor blackColor];
  self.shadow.shadowBlurRadius = 5.0;
  self.shadow.shadowOffset = CGSizeMake(1.0, 1.0);
  _blackLastMoveLayer = NULL;
  _whiteLastMoveLayer = NULL;
  _nextMoveLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SymbolsLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases layers with "last move" symbols if they are currently
/// allocated. Otherwise does nothing.
// -----------------------------------------------------------------------------
- (void) releaseLayers
{
  if (_blackLastMoveLayer)
  {
    CGLayerRelease(_blackLastMoveLayer);
    _blackLastMoveLayer = NULL;
  }
  if (_whiteLastMoveLayer)
  {
    CGLayerRelease(_whiteLastMoveLayer);
    _whiteLastMoveLayer = NULL;
  }
  if (_nextMoveLayer)
  {
    CGLayerRelease(_nextMoveLayer);
    _nextMoveLayer = NULL;
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case PVLDEventRectangleChanged:
    {
      self.layer.frame = self.playViewMetrics.rect;
      [self releaseLayers];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change + clear last move marker
    {
      [self releaseLayers];
      self.dirty = true;
      break;
    }
    case PVLDEventBoardPositionChanged:
    // This case covers the following scenario: Board position 0 is selected
    // and the user discards all board positions. In this scenario the event
    // PVLDEventBoardPositionChanged - which usually covers the discard of board
    // positions - does NOT fire because the board position does NOT change.
    case PVLDEventNumberOfBoardPositionsChanged:
    case PVLDEventMarkLastMoveChanged:
    case PVLDEventMoveNumbersPercentageChanged:
    case PVLDEventScoringModeEnabled:   // temporarily disable symbols
    case PVLDEventScoringModeDisabled:  // re-enable symbols
    case PVLDEventMarkNextMoveChanged:
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

  if (! _blackLastMoveLayer)
    _blackLastMoveLayer = CreateSquareSymbolLayer(context, [UIColor blackColor], self.playViewMetrics);
  if (! _whiteLastMoveLayer)
    _whiteLastMoveLayer = CreateSquareSymbolLayer(context, [UIColor whiteColor], self.playViewMetrics);

  if ([self shouldDisplayMoveNumbers])
  {
    [self drawMoveNumbersInContext:context];
  }
  else
  {
    if (self.playViewModel.markLastMove)
    {
      GoMove* lastMove = game.boardPosition.currentMove;
      if (lastMove && GoMoveTypePlay == lastMove.type)
      {
        if (lastMove.player.isBlack)
          [PlayViewDrawingHelper drawLayer:_whiteLastMoveLayer withContext:context centeredAtPoint:lastMove.point withMetrics:self.playViewMetrics];
        else
          [PlayViewDrawingHelper drawLayer:_blackLastMoveLayer withContext:context centeredAtPoint:lastMove.point withMetrics:self.playViewMetrics];
      }
    }
  }

  if ([self shouldDisplayNextMoveLabel])
  {
    // Create layer only after shouldDisplayNextMoveLabel has made sure that
    // the "next move label font" is not nil and that the layer will actually
    // have a non-zero size.
    if (! _nextMoveLayer)
      _nextMoveLayer = CreateNextMoveLayer(context, self);

    if (! game.boardPosition.isLastPosition)
    {
      GoMove* nextMove;
      if (game.boardPosition.isFirstPosition)
        nextMove = game.firstMove;
      else
        nextMove = game.boardPosition.currentMove.next;
      if (GoMoveTypePlay == nextMove.type)
        [PlayViewDrawingHelper drawLayer:_nextMoveLayer withContext:context centeredAtPoint:nextMove.point withMetrics:self.playViewMetrics];
    }
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
{
  UIFont* moveNumberFont = self.playViewMetrics.moveNumberFont;
  DDLogVerbose(@"Drawing move numbers with font size %f", moveNumberFont.pointSize);

  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = self.playViewMetrics.moveNumberMaximumSize;
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

    // TODO: Creating a new CGLayer for each move number is probably not
    // very efficient, but it allows us to reuse the PlayViewMetrics
    // utility method drawLayer:withContext:centeredAtPoint:. Find out
    // whether creating so many CGLayer objects is really as inefficient
    // as suspected, and if they are, redesign the way how move numbers
    // are drawn.
    CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
    CGContextRef layerContext = CGLayerGetContext(layer);
    UIGraphicsPushContext(layerContext);
    [moveNumberText drawInRect:layerRect withAttributes:textAttributes];
    UIGraphicsPopContext();
    [PlayViewDrawingHelper drawLayer:layer withContext:context centeredAtPoint:pointToBeNumbered withMetrics:self.playViewMetrics];
    CGLayerRelease(layer);
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a "next move"
/// symbol.
///
/// All sizes are taken from the current values in self.playViewMetrics.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this function is responsible for releasing the
/// returned CGLayer object using the function CGLayerRelease when the layer is
/// no longer needed.
// -----------------------------------------------------------------------------
CGLayerRef CreateNextMoveLayer(CGContextRef context, SymbolsLayerDelegate* delegate)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = delegate.playViewMetrics.nextMoveLabelMaximumSize;
  // This function might be called
  if (CGSizeEqualToSize(layerRect.size, CGSizeZero))
    return NULL;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  NSString* nextMoveLabelText = @"A";
  NSDictionary* textAttributes = @{ NSFontAttributeName : delegate.playViewMetrics.nextMoveLabelFont,
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : delegate.paragraphStyle,
                                    NSShadowAttributeName: delegate.shadow };

  UIGraphicsPushContext(layerContext);
  [nextMoveLabelText drawInRect:layerRect withAttributes:textAttributes];
  UIGraphicsPopContext();

  return layer;
}

@end
