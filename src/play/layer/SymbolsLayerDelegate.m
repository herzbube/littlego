// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoPlayer.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for SymbolsLayerDelegate.
// -----------------------------------------------------------------------------
@interface SymbolsLayerDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) ScoringModel* scoringModel;
//@}
@end


@implementation SymbolsLayerDelegate

@synthesize scoringModel;


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
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SymbolsLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scoringModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  if (self.playViewModel.markLastMove && ! self.scoringModel.scoringMode)
  {
    GoMove* lastMove = [GoGame sharedGame].lastMove;
    if (lastMove && GoMoveTypePlay == lastMove.type)
    {
      CGRect lastMoveBox = [self.playViewMetrics innerSquareAtPoint:lastMove.point];
      // TODO move color handling to a helper function; there is similar code
      // floating around somewhere else in this class
      UIColor* lastMoveBoxColor;
      if (lastMove.player.isBlack)
        lastMoveBoxColor = [UIColor whiteColor];
      else
        lastMoveBoxColor = [UIColor blackColor];
      // Now render the box
      CGContextBeginPath(context);
      CGContextAddRect(context, lastMoveBox);
      CGContextSetStrokeColorWithColor(context, lastMoveBoxColor.CGColor);
      CGContextSetLineWidth(context, self.playViewModel.normalLineWidth);
      CGContextStrokePath(context);
    }
  }
}

@end
