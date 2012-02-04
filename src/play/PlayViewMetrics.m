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
#import "PlayViewMetrics.h"
#import "PlayViewModel.h"
#import "../go/GoBoard.h"
#import "../go/GoGame.h"
#import "../go/GoPoint.h"
#import "../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewMetrics.
// -----------------------------------------------------------------------------
@interface PlayViewMetrics()
/// @name Private helpers
//@{
- (void) updateWithRect:(CGRect)newRect boardDimension:(int)newBoardDimension;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) UIView* playView;
@property(nonatomic, retain) PlayViewModel* playViewModel;
//@}
@end


@implementation PlayViewMetrics

@synthesize playView;
@synthesize playViewModel;
@synthesize rect;
@synthesize boardDimension;
@synthesize portrait;
@synthesize boardSize;
@synthesize boardOuterMargin;
@synthesize boardInnerMargin;
@synthesize topLeftBoardCornerX;
@synthesize topLeftBoardCornerY;
@synthesize topLeftPointX;
@synthesize topLeftPointY;
@synthesize numberOfCells;
@synthesize pointDistance;
@synthesize lineLength;
@synthesize stoneRadius;


// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewMetrics object.
///
/// @note This is the designated initializer of PlayViewMetrics.
// -----------------------------------------------------------------------------
- (id) initWithView:(UIView*)view model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  
  self.playView = view;
  self.playViewModel = model;

  rect = CGRectNull;
  boardDimension = [GoBoard dimensionForSize:GoBoardSizeUndefined];
  // Remaining properties are initialized by updateWithRect:boardDimension:()
  [self updateWithRect:self.playView.bounds boardDimension:self.boardDimension];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewMetrics object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.playViewModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this PlayViewMetrics object based on
/// @a newRect.
// -----------------------------------------------------------------------------
- (void) updateWithRect:(CGRect)newRect
{
  [self updateWithRect:newRect boardDimension:self.boardDimension];
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this PlayViewMetrics object based on
/// @a newBoardSize.
// -----------------------------------------------------------------------------
- (void) updateWithBoardSize:(enum GoBoardSize)newBoardSize
{
  int newBoardDimension = [GoBoard dimensionForSize:newBoardSize];
  [self updateWithRect:self.rect boardDimension:newBoardDimension];
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this PlayViewMetrics object based on
/// @a newRect and @a newBoardDimension.
///
/// This method does nothing if the previous calculation was based on the same
/// rectangle and board dimension.
// -----------------------------------------------------------------------------
- (void) updateWithRect:(CGRect)newRect boardDimension:(int)newBoardDimension
{
  if (CGRectEqualToRect(rect, newRect) && boardDimension == newBoardDimension)
    return;

  // ----------------------------------------------------------------
  // Use newRect and newBoardDimension for calculations. self.rect and
  // self.boardDimension are updated at the very end, after all other properties
  // have been calculated. The reason for this is that clients can use KVO on
  // self.rect or self.boardDimension.
  // ----------------------------------------------------------------

  // The rect is rectangular, but the Go board is square. Examine the rect
  // orientation and use the smaller dimension of the rect as the base for
  // the Go board's dimension.
  self.portrait = newRect.size.height >= newRect.size.width;
  int boardSizeBase = 0;
  if (self.portrait)
    boardSizeBase = newRect.size.width;
  else
    boardSizeBase = newRect.size.height;
  self.boardOuterMargin = floor(boardSizeBase * self.playViewModel.boardOuterMarginPercentage);
  self.boardSize = boardSizeBase - (self.boardOuterMargin * 2);
  
  self.numberOfCells = newBoardDimension - 1;
  if (0 == self.numberOfCells + 1)
  {
    // This branch exists to prevent division by zero; this is expected to occur
    // if board dimension is zero during initialization, but it may also occur
    // later on during the application's life-cycle if we get updated while
    // no GoGame exists.
    self.pointDistance = 0;
  }
  else
  {
    // +1 to self.numberOfCells because we need one-half of a cell on both sides
    // of the board (top/bottom or left/right) to draw a stone
    self.pointDistance = floor(self.boardSize / (self.numberOfCells + 1));
  }
  self.boardInnerMargin = floor(self.pointDistance / 2);
  // Don't use border here - rounding errors might cause improper centering
  self.topLeftBoardCornerX = floor((newRect.size.width - self.boardSize) / 2);
  self.topLeftBoardCornerY = floor((newRect.size.height - self.boardSize) / 2);
  self.lineLength = self.pointDistance * numberOfCells;
  // Don't use padding here, rounding errors mighth cause improper positioning
  self.topLeftPointX = self.topLeftBoardCornerX + (self.boardSize - self.lineLength) / 2;
  self.topLeftPointY = self.topLeftBoardCornerY + (self.boardSize - self.lineLength) / 2;
  
  self.stoneRadius = floor(self.pointDistance / 2 * self.playViewModel.stoneRadiusPercentage);

  // Updating self.rect and self.boardDimension must be the last operation in
  // this method; also use self to update so that the synthesized setter will
  // trigger KVO.
  self.boardDimension = newBoardDimension;
  self.rect = newRect;
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// @a point.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromPoint:(GoPoint*)point
{
  return [self coordinatesFromVertex:point.vertex];
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// @a vertex.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromVertex:(GoVertex*)vertex
{
  struct GoVertexNumeric numericVertex = vertex.numeric;
  return [self coordinatesFromVertexX:numericVertex.x vertexY:numericVertex.y];
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// identified by @a vertexX and @a vertexY.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromVertexX:(int)vertexX vertexY:(int)vertexY
{
  // The origin for Core Graphics is in the bottom-left corner!
  return CGPointMake(self.topLeftPointX + (self.pointDistance * (vertexX - 1)),
                     self.topLeftPointY + self.lineLength - (self.pointDistance * (vertexY - 1)));
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoVertex object for the intersection identified by the view
/// coordinates @a coordinates.
///
/// Returns nil if @a coordinates do not refer to a valid intersection (e.g.
/// because @a coordinates are outside the board's edges).
// -----------------------------------------------------------------------------
- (GoVertex*) vertexFromCoordinates:(CGPoint)coordinates
{
  struct GoVertexNumeric numericVertex;
  numericVertex.x = 1 + (coordinates.x - self.topLeftPointX) / self.pointDistance;
  numericVertex.y = 1 + (self.topLeftPointY + self.lineLength - coordinates.y) / self.pointDistance;
  GoVertex* vertex;
  @try
  {
    vertex = [GoVertex vertexFromNumeric:numericVertex];
  }
  @catch (NSException* exception)
  {
    vertex = nil;
  }
  return vertex;
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoPoint object for the intersection identified by the view
/// coordinates @a coordinates.
///
/// Returns nil if @a coordinates do not refer to a valid intersection (e.g.
/// because @a coordinates are outside the board's edges).
// -----------------------------------------------------------------------------
- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates
{
  GoVertex* vertex = [self vertexFromCoordinates:coordinates];
  if (vertex)
    return [[GoGame sharedGame].board pointAtVertex:vertex.string];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns a rect that describes a square inside the circle that
/// represents the Go stone at @a point.
///
/// The square does not touch the circle, it is slighly inset.
// -----------------------------------------------------------------------------
- (CGRect) innerSquareAtPoint:(GoPoint*)point
{
  CGPoint coordinates = [self coordinatesFromVertex:point.vertex];
  // Geometry tells us that for the square with side length "a":
  //   a = r * sqrt(2)
  int sideLength = floor(self.stoneRadius * sqrt(2));
  CGRect square = [self squareWithCenterPoint:coordinates sideLength:sideLength];
  // We subtract another 2 points because we don't want to touch the circle.
  return CGRectInset(square, 1, 1);
}

// -----------------------------------------------------------------------------
/// @brief Returns a rect that describes a square exactly surrounding the circle
/// that represents the Go stone at @a point.
///
/// Two squares for adjacent points do not overlap, they exactly touch each
/// other.
// -----------------------------------------------------------------------------
- (CGRect) squareAtPoint:(GoPoint*)point
{
  CGPoint coordinates = [self coordinatesFromVertex:point.vertex];
  return [self squareWithCenterPoint:coordinates sideLength:self.pointDistance];
}

// -----------------------------------------------------------------------------
/// @brief Returns a rect that describes a square whose center is at coordinate
/// @a center and whose side length is @a sideLength.
// -----------------------------------------------------------------------------
- (CGRect) squareWithCenterPoint:(CGPoint)center sideLength:(double)sideLength
{
  // The origin for Core Graphics is in the bottom-left corner!
  CGRect square;
  square.origin.x = floor((center.x - (sideLength / 2))) + gHalfPixel;
  square.origin.y = floor((center.y - (sideLength / 2))) + gHalfPixel;
  square.size.width = sideLength;
  square.size.height = sideLength;
  return square;
}

@end
