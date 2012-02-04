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
#import "DeadStonesLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../ScoringModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardRegion.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for DeadStonesLayerDelegate.
// -----------------------------------------------------------------------------
@interface DeadStonesLayerDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) ScoringModel* scoringModel;
//@}
@end


@implementation DeadStonesLayerDelegate

@synthesize scoringModel;


// -----------------------------------------------------------------------------
/// @brief Initializes a DeadStonesLayerDelegate object.
///
/// @note This is the designated initializer of DeadStonesLayerDelegate.
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
/// @brief Deallocates memory allocated by this DeadStonesLayerDelegate object.
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
  UIColor* deadStoneSymbolColor = self.scoringModel.deadStoneSymbolColor;
  bool insetCalculated = false;
  CGFloat inset;
  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    if (! point.region.deadStoneGroup)
      continue;
    // The symbol for marking a dead stone is an "x"; we draw this as the two
    // diagonals of the "inner box" square
    CGRect innerSquare = [self.playViewMetrics innerSquareAtPoint:point];
    // Make the diagonals shorter by making the square slightly smaller
    // (the inset needs to be calculated only once per iteration)
    if (! insetCalculated)
    {
      insetCalculated = true;
      inset = floor(innerSquare.size.width * (1.0 - self.scoringModel.deadStoneSymbolPercentage));
    }
    innerSquare = CGRectInset(innerSquare, inset, inset);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, innerSquare.origin.x, innerSquare.origin.y);
    CGContextAddLineToPoint(context, innerSquare.origin.x + innerSquare.size.width, innerSquare.origin.y + innerSquare.size.width);
    CGContextMoveToPoint(context, innerSquare.origin.x, innerSquare.origin.y + innerSquare.size.width);
    CGContextAddLineToPoint(context, innerSquare.origin.x + innerSquare.size.width, innerSquare.origin.y);
    CGContextSetStrokeColorWithColor(context, deadStoneSymbolColor.CGColor);
    CGContextSetLineWidth(context, self.playViewModel.normalLineWidth);
    CGContextStrokePath(context);
  }
}

@end
