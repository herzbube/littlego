// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../ScoringModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
@interface SymbolsLayerDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (void) releaseLayers;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) ScoringModel* scoringModel;
@property(nonatomic, assign) CGLayerRef blackLastMoveLayer;
@property(nonatomic, assign) CGLayerRef whiteLastMoveLayer;
/// @brief Array that contains font objects for fonts with different sizes, and
/// the rectangle size required to draw move numbers with that font.
///
/// Each entry in the @e moveNumberFonts array is another array with three
/// elements: The first element is the font object (an UIFont object), the
/// second and third elements are the rectangle width and height (both NSNumber
/// object with a float value).
///
/// Entries in @e moveNumberFonts appear ordered by font size. The first entry
/// is the one with the largest font size.
@property(nonatomic, retain) NSArray* moveNumberFonts;
@property(nonatomic, assign) bool currentMoveNumberFontNeedsUpdate;
@property(nonatomic, assign) bool currentMoveNumberFontIsValid;
@property(nonatomic, assign) UIFont* currentMoveNumberFont;
@property(nonatomic, assign) CGSize currentMoveNumberSize;
//@}
@end


@implementation SymbolsLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a SymbolsLayerDelegate object.
///
/// @note This is the designated initializer of SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics playViewModel:(PlayViewModel*)playViewModel scoringModel:(ScoringModel*)theScoringModel
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:playViewModel];
  if (! self)
    return nil;
  self.scoringModel = theScoringModel;
  _blackLastMoveLayer = NULL;
  _whiteLastMoveLayer = NULL;
  [self setupCurrentMoveNumberFont];
  [self setupMoveNumberFonts];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SymbolsLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scoringModel = nil;
  [self releaseLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupCurrentMoveNumberFont
{
  self.currentMoveNumberFontNeedsUpdate = true;
  [self invalidateCurrentMoveNumberFont];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupMoveNumberFonts
{
  NSMutableArray* moveNumberFonts = [NSMutableArray arrayWithCapacity:0];
  // This must be the move number that takes up the most drawing space
  NSString* textToDetermineSize = @"388";
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);

  const int maximumFontSize = [UIFont systemFontSize];
  const int minimumFontSize = MIN(8, maximumFontSize);
  for (int fontSize = maximumFontSize; fontSize >= minimumFontSize; --fontSize)
  {
    UIFont* font = [UIFont systemFontOfSize:fontSize];
    CGSize textSize = [textToDetermineSize sizeWithFont:font
                                      constrainedToSize:constraintSize
                                          lineBreakMode:UILineBreakModeWordWrap];
    NSArray* array = [NSArray arrayWithObjects:font,
                                               [NSNumber numberWithFloat:textSize.width],
                                               [NSNumber numberWithFloat:textSize.height],
                                               nil];
    [moveNumberFonts addObject:array];
  }
  self.moveNumberFonts = moveNumberFonts;
}

// -----------------------------------------------------------------------------
/// @brief Fills the out variables @a font and @a textSize with values that are
/// suitable for drawing move numbers with the current play view metrics.
///
/// Returns true if suitable values were found. Returns false if no suitable
/// value were found (the content of @a font and @a textSize in this case is not
/// specified).
///
/// @a textSize is wide enough to draw the widest possible move number using
/// @a font. If a move number about to be drawn is less wide than the maximum,
/// it should be horizontally centered in @a textSize.
///
/// @a textSize is high enough to draw one line of text using @a font.
// -----------------------------------------------------------------------------
- (bool) moveNumberFont:(UIFont**)font textSize:(CGSize*)textSize
{
  CGFloat stoneInnerSquareSizeWidth = self.playViewMetrics.stoneInnerSquareSize.width;
  // Iteration is in order of font size (largest first)
  for (NSArray* array in self.moveNumberFonts)
  {
    CGFloat minimumRequiredWidth = [[array objectAtIndex:1] floatValue];
    if (minimumRequiredWidth > stoneInnerSquareSizeWidth)
      continue;
    CGFloat minimumRequiredHeight = [[array objectAtIndex:2] floatValue];
    *textSize = CGSizeMake(minimumRequiredWidth, minimumRequiredHeight);
    *font = [array objectAtIndex:0];
    return true;
  }
  return false;
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
    _blackLastMoveLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (_whiteLastMoveLayer)
  {
    CGLayerRelease(_whiteLastMoveLayer);
    _whiteLastMoveLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
}

// -----------------------------------------------------------------------------
/// @brief Marks the current move number font properties as invalid.
// -----------------------------------------------------------------------------
- (void) invalidateCurrentMoveNumberFont
{
  self.currentMoveNumberFontIsValid = false;
  self.currentMoveNumberFont = nil;
  self.currentMoveNumberSize = CGSizeZero;
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
      self.currentMoveNumberFontNeedsUpdate = true;
      [self invalidateCurrentMoveNumberFont];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change + clear last move marker
    {
      [self releaseLayers];
      self.dirty = true;
      self.currentMoveNumberFontNeedsUpdate = true;
      [self invalidateCurrentMoveNumberFont];
      break;
    }
    case PVLDEventBoardPositionChanged:
    case PVLDEventMarkLastMoveChanged:
    case PVLDEventMoveNumbersPercentageChanged:
    case PVLDEventScoringModeEnabled:   // temporarily disable symbols
    case PVLDEventScoringModeDisabled:  // re-enable symbols
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
  if (self.scoringModel.scoringMode)
    return;
  DDLogVerbose(@"SymbolsLayerDelegate is drawing");

  if (! _blackLastMoveLayer)
    _blackLastMoveLayer = CreateLastMoveLayer(context, [UIColor blackColor], self);
  if (! _whiteLastMoveLayer)
    _whiteLastMoveLayer = CreateLastMoveLayer(context, [UIColor whiteColor], self);
  if (self.currentMoveNumberFontNeedsUpdate)
  {
    self.currentMoveNumberFontNeedsUpdate = false;
    self.currentMoveNumberFontIsValid = [self moveNumberFont:&_currentMoveNumberFont textSize:&_currentMoveNumberSize];
  }

  if ([self shouldDisplayMoveNumbers])
  {
    [self drawMoveNumbersInContext:context];
  }
  else
  {
    if (self.playViewModel.markLastMove)
    {
      GoMove* lastMove = [GoGame sharedGame].boardPosition.currentMove;
      if (lastMove && GoMoveTypePlay == lastMove.type)
      {
        if (lastMove.player.isBlack)
          [self.playViewMetrics drawLayer:_whiteLastMoveLayer withContext:context centeredAtPoint:lastMove.point];
        else
          [self.playViewMetrics drawLayer:_blackLastMoveLayer withContext:context centeredAtPoint:lastMove.point];
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (bool) shouldDisplayMoveNumbers
{
  if (! self.currentMoveNumberFontIsValid)
    return false;
  else if (0.0 == self.playViewModel.moveNumbersPercentage)
    return false;
  else
    return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (void) drawMoveNumbersInContext:(CGContextRef)context
{
  DDLogVerbose(@"Drawing move numbers with font size %f", self.currentMoveNumberFont.pointSize);

  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = self.currentMoveNumberSize;
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

    // TODO: Creating a new CGLayer for each move number is probably not
    // very efficient, but it allows us to reuse the PlayViewMetrics
    // utility method drawLayer:withContext:centeredAtPoint:. Find out
    // whether creating so many CGLayer objects is really as inefficient
    // as suspected, and if they are, redesign the way how move numbers
    // are drawn.
    CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
    CGContextRef layerContext = CGLayerGetContext(layer);
    UIGraphicsPushContext(layerContext);
    CGContextSetFillColorWithColor(layerContext, textColor.CGColor);
    [moveNumberText drawInRect:layerRect withFont:self.currentMoveNumberFont lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
    UIGraphicsPopContext();
    [self.playViewMetrics drawLayer:layer withContext:context centeredAtPoint:pointToBeNumbered];
    CGLayerRelease(layer);
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a "last move"
/// symbol that uses the specified color @a symbolColor.
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
CGLayerRef CreateLastMoveLayer(CGContextRef context, UIColor* symbolColor, SymbolsLayerDelegate* delegate)
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = delegate.playViewMetrics.stoneInnerSquareSize;
  // It looks better if the marker is slightly inset, and on the iPad we can
  // afford to waste the space
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
  {
    layerRect.size.width -= 2;
    layerRect.size.height -= 2;
  }
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  // Half-pixel translation is added at the time when the layer is actually
  // drawn
  CGContextBeginPath(layerContext);
  CGContextAddRect(layerContext, layerRect);
  CGContextSetStrokeColorWithColor(layerContext, symbolColor.CGColor);
  CGContextSetLineWidth(layerContext, delegate.playViewModel.normalLineWidth);
  CGContextStrokePath(layerContext);

  return layer;
}

@end
