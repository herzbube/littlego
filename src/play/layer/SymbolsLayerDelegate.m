// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoPlayer.h"

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
    case PVLDEventMarkLastMoveChanged:
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

  if (! _blackLastMoveLayer)
    _blackLastMoveLayer = CreateLastMoveLayer(context, [UIColor blackColor], self);
  if (! _whiteLastMoveLayer)
    _whiteLastMoveLayer = CreateLastMoveLayer(context, [UIColor whiteColor], self);

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
