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
#import "PlayView.h"
#import "../go/GoGame.h"
#import "../go/GoBoard.h"
#import "../go/GoMove.h"
#import "../go/GoPoint.h"

@class GoPoint;


@interface PlayView(Private)
/// @name UINibLoadingAdditions category
//@{
- (void) awakeFromNib;
//@}

- (void) updateDrawParametersForRect:(CGRect)rect;
- (void) drawBackground:(CGRect)rect;
- (void) drawBoard;
- (void) drawGrid;
- (void) drawStarPoints;
- (void) drawStones;
- (void) drawStone:(bool)black point:(GoPoint*)point;
- (void) drawStone:(bool)black vertexX:(int)vertexX vertexY:(int)vertexY;
- (void) drawStone:(bool)black coordinates:(CGPoint)coordinates;
- (void) drawSymbols;
- (void) drawLabels;
- (CGPoint) coordinatesFromPoint:(GoPoint*)point;
- (CGPoint) coordinatesFromVertexX:(int)vertexX vertexY:(int)vertexY;
@end

@implementation PlayView

@synthesize viewBackgroundColor;
@synthesize boardColor;
@synthesize boardOuterMarginPercentage;
@synthesize boardInnerMarginPercentage;
@synthesize lineColor;
@synthesize boundingLineWidth;
@synthesize normalLineWidth;
@synthesize starPointColor;
@synthesize starPointRadius;
@synthesize stoneRadiusPercentage;
@synthesize previousDrawRect;
@synthesize portrait;
@synthesize boardSize;
@synthesize boardOuterMargin;
@synthesize boardInnerMargin;
@synthesize topLeftBoardCornerX;
@synthesize topLeftBoardCornerY;
@synthesize topLeftPointX;
@synthesize topLeftPointY;
@synthesize pointDistance;
@synthesize lineLength;


static PlayView* sharedView = nil;
+ (PlayView*) sharedView;
{
  @synchronized(self)
  {
    assert(sharedView != nil);
    return sharedView;
  }
}

// -----------------------------------------------------------------------------
/// @brief Is called after an PlayView object has been allocated and initialized
/// from PlayView.xib
///
/// @note This is a method from the UINibLoadingAdditions category (an addition
/// to NSObject, defined in UINibLoading.h). Although it has the same purpose,
/// the implementation via category is different from the NSNibAwaking informal
/// protocol on the Mac OS X platform.
// -----------------------------------------------------------------------------
- (void) awakeFromNib
{
  [super awakeFromNib];

  sharedView = self;

  // Dark gray
  //  self.viewBackgroundColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha: 1.0];
  self.viewBackgroundColor = [UIColor darkGrayColor];
  // Alternative colors: 240/161/83, 250/182/109, 251/172/94, 243/172/95
  self.boardColor = [UIColor colorWithRed:243/255.0 green:172/255.0 blue:95/255.0 alpha: 1.0];
  self.boardOuterMarginPercentage = 0.02;
  self.boardInnerMarginPercentage = 0.02;
  self.lineColor = [UIColor blackColor];
  self.boundingLineWidth = 2;
  self.normalLineWidth = 1;
  self.starPointColor = [UIColor blackColor];
  self.starPointRadius = 3;
  self.stoneRadiusPercentage = 0.95;  // percentage of pointDistance

  self.previousDrawRect = CGRectNull;
  self.portrait = true;
  self.boardSize = 0;
  self.boardOuterMargin = 0;
  self.boardInnerMargin = 0;
  self.topLeftBoardCornerX = 0;
  self.topLeftBoardCornerY = 0;
  self.topLeftPointX = 0;
  self.topLeftPointY = 0;
  self.pointDistance = 0;
  self.lineLength = 0;
}

- (void)dealloc
{
  [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
  [self updateDrawParametersForRect:rect];
  // The order in which draw methods are invoked is important, as each method
  // draws its objects as a new layer on top of the previous layers.
  [self drawBackground:rect];
  [self drawBoard];
  [self drawGrid];
  [self drawStarPoints];
  [self drawStones];
  [self drawSymbols];
  [self drawLabels];
}

- (void) updateDrawParametersForRect:(CGRect)rect
{
  // No need to update if the new rect is the same as the one we did our
  // previous calculations with
  if (CGRectEqualToRect(self.previousDrawRect, rect))
    return;
  self.previousDrawRect = rect;

  // The view rect is rectangular, but the Go board is square. Examine the view
  // rect orientation and use the smaller dimension of the rect as the base for
  // the Go board's dimension.
  self.portrait = rect.size.height >= rect.size.width;
  int boardSizeBase = 0;
  if (self.portrait)
    boardSizeBase = rect.size.width;
  else
    boardSizeBase = rect.size.height;
  self.boardOuterMargin = floor(boardSizeBase * self.boardOuterMarginPercentage);
  self.boardSize = boardSizeBase - (self.boardOuterMargin * 2);
  self.boardInnerMargin = floor(self.boardSize * self.boardInnerMarginPercentage);
  // Don't use border here - rounding errors might cause improper centering
  self.topLeftBoardCornerX = floor((rect.size.width - self.boardSize) / 2);
  self.topLeftBoardCornerY = floor((rect.size.height - self.boardSize) / 2);
  // This is only an approximation - because fractions are lost by the
  // subsequent point distance calculation, the final line length calculation
  // must be based on the point distance
  int lineLengthApproximation = self.boardSize - (self.boardInnerMargin * 2);
  self.pointDistance = floor(lineLengthApproximation / ([GoGame sharedGame].board.size - 1));
  self.lineLength = self.pointDistance * ([GoGame sharedGame].board.size - 1);
  // Don't use padding here, rounding errors mighth cause improper positioning
  self.topLeftPointX = self.topLeftBoardCornerX + (self.boardSize - self.lineLength) / 2;
  self.topLeftPointY = self.topLeftBoardCornerY + (self.boardSize - self.lineLength) / 2;
}

- (void) drawBackground:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, self.viewBackgroundColor.CGColor);
  CGContextFillRect(context, rect);
}

- (void) drawBoard
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, self.boardColor.CGColor);
  CGContextFillRect(context, CGRectMake(self.topLeftBoardCornerX + gHalfPixel,
                                        self.topLeftBoardCornerY + gHalfPixel,
                                        self.boardSize, self.boardSize));
}

- (void) drawGrid
{
  CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);

  // Two iterations for the two directions horizontal and vertical
  for (int lineDirection = 0; lineDirection < 2; ++lineDirection)
  {
    int lineStartPointX = self.topLeftPointX;
    int lineStartPointY = self.topLeftPointY;
    bool drawHorizontalLine = (0 == lineDirection) ? true : false;
    for (int lineCounter = 0; lineCounter < [GoGame sharedGame].board.size; ++lineCounter)
    {
      CGContextBeginPath(context);
      CGContextMoveToPoint(context, lineStartPointX + gHalfPixel, lineStartPointY + gHalfPixel);
      if (drawHorizontalLine)
      {
        CGContextAddLineToPoint(context, lineStartPointX + lineLength + gHalfPixel, lineStartPointY + gHalfPixel);
        lineStartPointY += self.pointDistance;
      }
      else
      {
        CGContextAddLineToPoint(context, lineStartPointX + gHalfPixel, lineStartPointY + lineLength + gHalfPixel);
        lineStartPointX += self.pointDistance;
      }
      if (0 == lineCounter || ([GoGame sharedGame].board.size - 1) == lineCounter)
        CGContextSetLineWidth(context, self.boundingLineWidth);
      else
        CGContextSetLineWidth(context, self.normalLineWidth);
      CGContextStrokePath(context);
    }
  }
}

- (void) drawStarPoints
{
  CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, self.starPointColor.CGColor);

  // TODO: Move definition of star points to somewhere else (e.g. GoBoard).
  // Note that Goban.app draws the following hoshi:
  // - 15x15, 17x17, 19x19 boards: 9 hoshi - 4 corner on the 4th line,
  //   4 edge on the 4th line, 1 in the center
  // - 13x13: 5 hoshi - 4 corner on the 4th line, 1 in the center
  // - 9x9, 11x11: 5 hoshi - 4 corner on the 3rd line, 1 in the center
  // - 7x7: 4 hoshi - 4 corner on the 3rd line
  // Double-check with Fuego. Sensei's Library has less complete information.
  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  const int numberOfStarPoints = 9;
  for (int starPointCounter = 0; starPointCounter < numberOfStarPoints; ++starPointCounter)
  {
    int vertexX = 0;
    int vertexY = 0;
    switch(starPointCounter)
    {
      case 0: vertexX = 4;  vertexY = 4;  break;
      case 1: vertexX = 10; vertexY = 4;  break;
      case 2: vertexX = 16; vertexY = 4;  break;
      case 3: vertexX = 4;  vertexY = 10; break;
      case 4: vertexX = 10; vertexY = 10; break;
      case 5: vertexX = 16; vertexY = 10; break;
      case 6: vertexX = 4;  vertexY = 16; break;
      case 7: vertexX = 10; vertexY = 16; break;
      case 8: vertexX = 16; vertexY = 16; break;
      default: break;
    }
    int starPointCenterPointX = self.topLeftPointX + (self.pointDistance * (vertexX - 1));
    int starPointCenterPointY = self.topLeftPointY + (self.pointDistance * (vertexY - 1));
    CGContextAddArc(context, starPointCenterPointX + gHalfPixel, starPointCenterPointY + gHalfPixel, self.starPointRadius, startRadius, endRadius, clockwise);
    CGContextFillPath(context);
  }
}

- (void) drawStones
{
//  NSString* blackStoneImageName = [[NSBundle mainBundle] pathForResource:@"BlackStone-Goban" ofType:@"tiff"];
//  UIImage* blackStoneImageObj = [[UIImage alloc] initWithContentsOfFile:blackStoneImageName];
//  CGRect blackStoneImageRect;
//  blackStoneImageRect.size.width = distanceBetweenLines;
//  blackStoneImageRect.size.height = distanceBetweenLines;
//  blackStoneImageRect.origin.x = hoshiWithBlackStone.x - (blackStoneImageRect.size.width / 2);
//  blackStoneImageRect.origin.y = hoshiWithBlackStone.y - (blackStoneImageRect.size.height / 2);
//  CGContextDrawImage(context, blackStoneImageRect, [blackStoneImageObj CGImage]);
  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    GoMove* move = point.move;
    if (! move)
      continue;
    enum GoMoveType type = move.type;
    if (type != PlayMove)
      continue;
//    if (! move || move.type != PlayMove)
//      continue;
    [self drawStone:move.black point:point];
  }
}

- (void) drawStone:(bool)black point:(GoPoint*)point
{
  [self drawStone:black vertexX:point.numVertexX vertexY:point.numVertexY];
}

- (void) drawStone:(bool)black vertexX:(int)vertexX vertexY:(int)vertexY
{
  [self drawStone:black coordinates:[self coordinatesFromVertexX:vertexX vertexY:vertexY]];
}

- (void) drawStone:(bool)black coordinates:(CGPoint)coordinates
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  UIColor* stoneColor;
  if (black)
    stoneColor = [UIColor blackColor];
  else
    stoneColor = [UIColor whiteColor];
	CGContextSetFillColorWithColor(context, stoneColor.CGColor);

  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  int stoneRadius = floor(self.pointDistance / 2 * self.stoneRadiusPercentage);
  CGContextAddArc(context, coordinates.x + gHalfPixel, coordinates.y + gHalfPixel, stoneRadius, startRadius, endRadius, clockwise);
  CGContextFillPath(context);
}

- (void) drawSymbols
{
}

- (void) drawLabels
{
}

- (CGPoint) coordinatesFromPoint:(GoPoint*)point
{
  return [self coordinatesFromVertexX:point.numVertexX vertexY:point.numVertexY];
}

- (CGPoint) coordinatesFromVertexX:(int)vertexX vertexY:(int)vertexY
{
  return CGPointMake(self.topLeftPointX + (self.pointDistance * (vertexX - 1)),
                     self.topLeftPointY + (self.pointDistance * (vertexY - 1)));
}

- (void) drawMove:(GoMove*)move
{
  [self setNeedsDisplay];
}

@end
