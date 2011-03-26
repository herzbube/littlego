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
#import "../go/GoVertex.h"


@interface PlayView(Private)
/// @name UINibLoadingAdditions category
//@{
- (void) awakeFromNib;
//@}
- (void) updateDrawParametersForRect:(CGRect)rect;
// Layer drawing and other GUI updating
- (void) drawBackground:(CGRect)rect;
- (void) drawBoard;
- (void) drawGrid;
- (void) drawStarPoints;
- (void) drawStones;
- (void) drawStone:(UIColor*)color point:(GoPoint*)point;
- (void) drawStone:(UIColor*)color vertex:(GoVertex*)vertex;
- (void) drawStone:(UIColor*)color vertexX:(int)vertexX vertexY:(int)vertexY;
- (void) drawStone:(UIColor*)color coordinates:(CGPoint)coordinates;
- (void) drawSymbols;
- (void) drawLabels;
- (void) updateStatusLine;
- (void) updateActivityIndicator;
// Calculators
- (CGPoint) coordinatesFromPoint:(GoPoint*)point;
- (CGPoint) coordinatesFromVertex:(GoVertex*)vertex;
- (CGPoint) coordinatesFromVertexX:(int)vertexX vertexY:(int)vertexY;
- (GoVertex*) vertexFromCoordinates:(CGPoint)coordinates;
- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates;
// Notification responders
- (void) goGameStateChanged:(NSNotification*)notification;
- (void) goGameFirstMoveChanged:(NSNotification*)notification;
- (void) goGameLastMoveChanged:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
@end

@implementation PlayView

@synthesize statusLine;
@synthesize activityIndicator;

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
@synthesize crossHairColor;
@synthesize crossHairPointDistanceFromFinger;

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

@synthesize crossHairPoint;
@synthesize crossHairPointIsLegalMove;

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

  // Dark gray
  //  self.viewBackgroundColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha: 1.0];
  self.viewBackgroundColor = [UIColor whiteColor];
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
  self.crossHairColor = [UIColor blueColor];
  self.crossHairPointDistanceFromFinger = 2;

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

  self.crossHairPoint = nil;
  self.crossHairPointIsLegalMove = true;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(goGameFirstMoveChanged:) name:goGameFirstMoveChanged object:nil];
  [center addObserver:self selector:@selector(goGameLastMoveChanged:) name:goGameLastMoveChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
}

- (void) dealloc
{
  self.statusLine = nil;
  self.activityIndicator = nil;
  self.viewBackgroundColor = nil;
  self.boardColor = nil;
  self.lineColor = nil;
  self.starPointColor = nil;
  self.crossHairColor = nil;
  self.crossHairPoint = nil;
  [super dealloc];
}

- (void) drawRect:(CGRect)rect
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
  [self updateStatusLine];
  self.crossHairPoint = nil;
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

  CGPoint crossHairCenter = CGPointZero;
  if (self.crossHairPoint)
    crossHairCenter = [self coordinatesFromPoint:self.crossHairPoint];

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
        if (lineStartPointY == crossHairCenter.y)
          CGContextSetStrokeColorWithColor(context, self.crossHairColor.CGColor);
        else
          CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
        lineStartPointY += self.pointDistance;  // calculate for next iteration
      }
      else
      {
        CGContextAddLineToPoint(context, lineStartPointX + gHalfPixel, lineStartPointY + lineLength + gHalfPixel);
        if (lineStartPointX == crossHairCenter.x)
          CGContextSetStrokeColorWithColor(context, self.crossHairColor.CGColor);
        else
          CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
        lineStartPointX += self.pointDistance;  // calculate for next iteration
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
  bool crossHairStoneDrawn = false;
  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    if (point.hasStone)
    {
      UIColor* color;
      // TODO create an isEqualToPoint:(GoPoint*)point in GoPoint
      if (self.crossHairPoint && [self.crossHairPoint.vertex isEqualToVertex:point.vertex])
      {
        color = self.crossHairColor;
        crossHairStoneDrawn = true;
      }
      else if (point.blackStone)
        color = [UIColor blackColor];
      else
        color = [UIColor whiteColor];
      [self drawStone:color vertex:point.vertex];
    }
    else
    {
      // TODO remove this or make it into something that can be turned on
      // at runtime for debugging
//      [self drawEmpty:point];
    }
  }

  // Draw after regular stones to paint the cross-hair stone over any regular
  // stone that might be present
  if (self.crossHairPoint && ! crossHairStoneDrawn)
  {
    // TODO move color handling to a helper function; there is similar code
    // floating around somewhere else (GoGame?)
    UIColor* color = nil;
    switch (game.state)
    {
      case GameHasNotYetStarted:
        color = [UIColor blackColor];
        break;
      case GameHasStarted:
        if (game.lastMove.black)
          color = [UIColor whiteColor];
        else
          color = [UIColor blackColor];
        break;
      default:
        break;
    }
    if (color)
      [self drawStone:color point:self.crossHairPoint];
  }
}

- (void) drawStone:(UIColor*)color point:(GoPoint*)point
{
  [self drawStone:color vertex:point.vertex];
}

- (void) drawStone:(UIColor*)color vertex:(GoVertex*)vertex
{
  struct GoVertexNumeric numericVertex = vertex.numeric;
  [self drawStone:color vertexX:numericVertex.x vertexY:numericVertex.y];
}

- (void) drawStone:(UIColor*)color vertexX:(int)vertexX vertexY:(int)vertexY
{
  [self drawStone:color coordinates:[self coordinatesFromVertexX:vertexX vertexY:vertexY]];
}

- (void) drawStone:(UIColor*)color coordinates:(CGPoint)coordinates
{
  CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, color.CGColor);

  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  int stoneRadius = floor(self.pointDistance / 2 * self.stoneRadiusPercentage);
  CGContextAddArc(context, coordinates.x + gHalfPixel, coordinates.y + gHalfPixel, stoneRadius, startRadius, endRadius, clockwise);
  CGContextFillPath(context);
}

- (void) drawSymbols
{
  // TODO not yet implemented
}

- (void) drawLabels
{
  // TODO not yet implemented
}

- (void) updateStatusLine
{
  NSString* statusText = @"";
  if (self.crossHairPoint)
  {
    if (! self.crossHairPointIsLegalMove)
      statusText = @"You can't play there";
  }
  else
  {
    if ([GoGame sharedGame].isComputerThinking)
    {
      // TODO Insert computer player name here (e.g. "Fuego")
      statusText = @"Computer is thinking...";
    }
  }
  self.statusLine.text = statusText;
}

- (void) updateActivityIndicator
{
  if ([[GoGame sharedGame] isComputerThinking])
    [self.activityIndicator startAnimating];
  else
    [self.activityIndicator stopAnimating];
}

- (void) drawEmpty:(GoPoint*)point
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  CGPoint coordinates = [self coordinatesFromVertexX:numericVertex.x vertexY:numericVertex.y];
  CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [[point.region color] CGColor]);
  
  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  int circleRadius = floor(self.pointDistance / 2 * self.stoneRadiusPercentage / 2);
  CGContextAddArc(context, coordinates.x + gHalfPixel, coordinates.y + gHalfPixel, circleRadius, startRadius, endRadius, clockwise);
  CGContextFillPath(context);
}

- (CGPoint) coordinatesFromPoint:(GoPoint*)point
{
  return [self coordinatesFromVertex:point.vertex];
}

- (CGPoint) coordinatesFromVertex:(GoVertex*)vertex
{
  struct GoVertexNumeric numericVertex = vertex.numeric;
  return [self coordinatesFromVertexX:numericVertex.x vertexY:numericVertex.y];
}

- (CGPoint) coordinatesFromVertexX:(int)vertexX vertexY:(int)vertexY
{
  return CGPointMake(self.topLeftPointX + (self.pointDistance * (vertexX - 1)),
                     self.topLeftPointY + self.lineLength - (self.pointDistance * (vertexY - 1)));
}

- (GoVertex*) vertexFromCoordinates:(CGPoint)coordinates
{
  struct GoVertexNumeric numericVertex;
  numericVertex.x = 1 + (coordinates.x - self.topLeftPointX) / self.pointDistance;
  numericVertex.y = 1 + (self.topLeftPointY + self.lineLength - coordinates.y) / self.pointDistance;
  return [GoVertex vertexFromNumeric:numericVertex];
}

- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates
{
  GoVertex* vertex = [self vertexFromCoordinates:coordinates];
  return [[GoGame sharedGame].board pointAtVertex:vertex.string];
}

- (void) goGameStateChanged:(NSNotification*)notification
{
  // TODO do we need this?
}

- (void) goGameFirstMoveChanged:(NSNotification*)notification
{
  // TODO check if it's possible to update only a rectangle
  [self setNeedsDisplay];
}

- (void) goGameLastMoveChanged:(NSNotification*)notification
{
  // TODO check if it's possible to update only a rectangle
  [self setNeedsDisplay];
}

- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updateStatusLine];
  [self updateActivityIndicator];
}

- (GoPoint*) crossHairPointAt:(CGPoint)coordinates
{
  // Adjust so that the cross-hair is not directly under the user's fingertip,
  // but one point distance above
  coordinates.y -= self.crossHairPointDistanceFromFinger * self.pointDistance;

  // Check if cross-hair is outside the grid and should not be displayed. To
  // make the edge lines accessible in the same way as the inner lines,
  // a padding of half a point distance must be added.
  int halfPointDistance = floor(self.pointDistance / 2);
  if (coordinates.x < self.topLeftPointX)
  {
    if (coordinates.x < self.topLeftPointX - halfPointDistance)
      coordinates = CGPointZero;
    else
      coordinates.x = self.topLeftPointX;
  }
  else if (coordinates.x > self.topLeftPointX + self.lineLength)
  {
    if (coordinates.x > self.topLeftPointX + self.lineLength + halfPointDistance)
      coordinates = CGPointZero;
    else
      coordinates.x = self.topLeftPointX + self.lineLength;
  }
  else if (coordinates.y < self.topLeftPointY)
  {
    if (coordinates.y < self.topLeftPointY - halfPointDistance)
      coordinates = CGPointZero;
    else
      coordinates.y = self.topLeftPointY;
  }
  else if (coordinates.y > self.topLeftPointY + self.lineLength)
  {
    if (coordinates.y > self.topLeftPointY + self.lineLength + halfPointDistance)
      coordinates = CGPointZero;
    else
      coordinates.y = self.topLeftPointY + self.lineLength;
  }
  else
  {
    // Adjust so that the snap-to calculation below switches to the next vertex
    // when the cross-hair has moved half-way through the distance to that vertex
    coordinates.x += halfPointDistance;
    coordinates.y += halfPointDistance;
  }

  // Snap to the nearest vertex if the coordinates were valid
  if (0 == coordinates.x && 0 == coordinates.y)
    return nil;
  else
  {
    coordinates.x = self.topLeftPointX + self.pointDistance * floor((coordinates.x - self.topLeftPointX) / self.pointDistance);
    coordinates.y = self.topLeftPointY + self.pointDistance * floor((coordinates.y - self.topLeftPointY) / self.pointDistance);
    return [self pointFromCoordinates:coordinates];
  }
}

- (void) moveCrossHairTo:(GoPoint*)point isLegalMove:(bool)isLegalMove
{
  // TODO check if it's possible to update only a few rectangles
  self.crossHairPoint = point;
  self.crossHairPointIsLegalMove = isLegalMove;
  [self setNeedsDisplay];
}

@end
