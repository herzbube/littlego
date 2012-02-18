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
- (void) updateWithRect:(CGRect)newRect boardSize:(enum GoBoardSize)newBoardSize;
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
@synthesize boardSize;
@synthesize portrait;
@synthesize boardSideLength;
@synthesize topLeftBoardCornerX;
@synthesize topLeftBoardCornerY;
@synthesize topLeftPointX;
@synthesize topLeftPointY;
@synthesize numberOfCells;
@synthesize cellWidth;
@synthesize pointDistance;
@synthesize lineLength;
@synthesize stoneRadius;
@synthesize pointCellSize;
@synthesize stoneInnerSquareSize;


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
  boardSize = GoBoardSizeUndefined;
  // Remaining properties are initialized by updateWithRect:boardSize:()
  [self updateWithRect:self.playView.bounds boardSize:self.boardSize];

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
  [self updateWithRect:newRect boardSize:self.boardSize];
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this PlayViewMetrics object based on
/// @a newBoardSize.
// -----------------------------------------------------------------------------
- (void) updateWithBoardSize:(enum GoBoardSize)newBoardSize
{
  [self updateWithRect:self.rect boardSize:newBoardSize];
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this PlayViewMetrics object based on
/// @a newRect and @a newBoardSize.
// -----------------------------------------------------------------------------
- (void) updateWithRect:(CGRect)newRect boardSize:(enum GoBoardSize)newBoardSize
{
  self.boardSize = newBoardSize;
  self.rect = newRect;

  // The rect is rectangular, but the Go board is square. Examine the rect
  // orientation and use the smaller dimension of the rect as the base for
  // the Go board's side length.
  self.portrait = newRect.size.height >= newRect.size.width;
  int boardSideLengthBase = 0;
  if (self.portrait)
    boardSideLengthBase = newRect.size.width;
  else
    boardSideLengthBase = newRect.size.height;

  // Outer margin and board side length are not yet final - any rounding errors
  // that occur in the following calculations will re-added to the outer margin,
  // so in the end the margin will be slightly larger, and the board will be
  // slightly smaller than we calculate here.

  // These values must be calculated even if the board size is not yet known
  // so that the board itself can already be drawn.
  // Note: This is important because the board will NOT be redrawn when the
  // board size changes (see BoardLayerDelegate)!
  int boardOuterMargin = floor(boardSideLengthBase * self.playViewModel.boardOuterMarginPercentage);
  self.topLeftBoardCornerX = boardOuterMargin;
  self.topLeftBoardCornerY = boardOuterMargin;
  self.boardSideLength = boardSideLengthBase - (boardOuterMargin * 2);

  if (GoBoardSizeUndefined == newBoardSize)
  {
    // Assign hard-coded values and don't rely on calculations that might
    // produce insane results. This also removes the risk of division by zero
    // errors.
    self.numberOfCells = 0;
    self.cellWidth = 0;
    self.pointDistance = 0;
    self.stoneRadius = 0;
    self.lineLength = 0;
    self.topLeftPointX = self.topLeftBoardCornerX;
    self.topLeftPointY = self.topLeftBoardCornerY;
  }
  else
  {
    self.numberOfCells = newBoardSize - 1;

    // For the purpose of calculating the cell width, we assume that all lines
    // have the same thickness. The difference between normal and bounding line
    // width is added to the *OUTSIDE* of the board (see GridLayerDelegate).
    int numberOfPointsAvailableForCells = self.boardSideLength - newBoardSize * self.playViewModel.normalLineWidth;
    assert(numberOfPointsAvailableForCells >= 0);
    // +1 to self.numberOfCells because we need one-half of a cell on both sides
    // of the board (top/bottom or left/right) to draw, for instance, a stone
    self.cellWidth = floor(numberOfPointsAvailableForCells / (self.numberOfCells + 1));
    // We want an even number so that half a cell leaves us with no fractions,
    // so that we can draw neatly aligned half-cell rectangles 
    if (self.cellWidth % 2 != 0)
    {
      // We can't increase self.cellWidth to get an even number because if
      // self.boardSideLength is very small, increasing self.cellWidth might
      // cause the sum of all cells to exceed self.boardSideLength. Decreasing
      // self.cellWidth therefore is the only option, although this wastes a
      // small amount of screen estate.
      self.cellWidth--;
    }

    self.pointDistance = self.cellWidth + self.playViewModel.normalLineWidth;
    self.stoneRadius = floor(self.cellWidth / 2 * self.playViewModel.stoneRadiusPercentage);
    int pointsUsedForGridLines = ((newBoardSize - 2) * self.playViewModel.normalLineWidth
                                  + 2 * self.playViewModel.boundingLineWidth);
    self.lineLength = pointsUsedForGridLines + self.cellWidth * numberOfCells;

    // This makes sure that the grid is centered. We can't use self.cellWidth
    // as the inner margin, because that parameter might have been adjusted
    // above for even-ness, which would result in a non-centered grid.
    int boardInnerMargin = floor((self.boardSideLength - self.lineLength) / 2);
    assert(2 * boardInnerMargin >= self.cellWidth);
    self.topLeftPointX = self.topLeftBoardCornerX + boardInnerMargin;
    self.topLeftPointY = self.topLeftBoardCornerY + boardInnerMargin;

    // Calculate self.pointCellSize. See property documentation for details
    // what we calculate here.
    int pointCellSideLength = self.cellWidth + self.playViewModel.normalLineWidth;
    self.pointCellSize = CGSizeMake(pointCellSideLength, pointCellSideLength);
    
    // Geometry tells us that for the square with side length "a":
    //   a = r * sqrt(2)
    int stoneInnerSquareSideLength = floor(self.stoneRadius * sqrt(2));
    // Subtract an additional 2 points because we don't want to touch the stone
    // circle
    stoneInnerSquareSideLength -= 2;
    self.stoneInnerSquareSize = CGSizeMake(stoneInnerSquareSideLength, stoneInnerSquareSideLength);
  }  // else [if (GoBoardSizeUndefined == newBoardSize)]
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// @a point.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromPoint:(GoPoint*)point
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  return CGPointMake(self.topLeftPointX + (self.pointDistance * (numericVertex.x - 1)),
                     self.topLeftPointY + (self.pointDistance * (self.boardSize - numericVertex.y)));
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
  struct GoVertexNumeric numericVertex;
  numericVertex.x = 1 + (coordinates.x - self.topLeftPointX) / self.pointDistance;
  numericVertex.y = self.boardSize - (coordinates.y - self.topLeftPointY) / self.pointDistance;
  GoVertex* vertex;
  @try
  {
    vertex = [GoVertex vertexFromNumeric:numericVertex];
  }
  @catch (NSException* exception)
  {
    return nil;
  }
  return [[GoGame sharedGame].board pointAtVertex:vertex.string];
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a stone that
/// uses the specified color @a stoneColor.
///
/// The layer size is taken from the current value of self.pointCellSize. The
/// stone's size is defined by the current value of self.stoneRadius.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this method is responsible for releasing the returned
/// CGLayer object using the function CGLayerRelease when the layer is no
/// longer needed.
// -----------------------------------------------------------------------------
- (CGLayerRef) stoneLayerWithContext:(CGContextRef)context stoneColor:(UIColor*)stoneColor
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = self.pointCellSize;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
  static const int startRadius = 0;
  static const int endRadius = 2 * M_PI;
  static const int clockwise = 0;

  // Half-pixel translation is added at the time when the layer is actually
  // drawn
  CGContextAddArc(layerContext,
                  layerCenter.x,
                  layerCenter.y,
                  self.stoneRadius,
                  startRadius,
                  endRadius,
                  clockwise);
  CGContextSetFillColorWithColor(layerContext, stoneColor.CGColor);
  CGContextFillPath(layerContext);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context so that
/// the layer is centered at the intersection specified by @a point.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CGLayerRef)layer withContext:(CGContextRef)context centeredAtPoint:(GoPoint*)point
{
  // Create a save point that we can restore to before we leave this method
  CGContextSaveGState(context);

  // Adjust the CTM as if we were drawing the layer with its upper-left corner
  // at the specified intersection
  CGPoint pointCoordinates = [self coordinatesFromPoint:point];
  CGContextTranslateCTM(context,
                        pointCoordinates.x,
                        pointCoordinates.y);
  // Align the layer center with the intersection
  CGSize layerSize = CGLayerGetSize(layer);
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = layerSize;
  CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
  CGContextTranslateCTM(context, -layerCenter.x, -layerCenter.y);
  // Half-pixel translation to prevent unnecessary anti-aliasing
  CGContextTranslateCTM(context, gHalfPixel, gHalfPixel);

  // Because of the CTM adjustments, we can now use CGPointZero
  CGContextDrawLayerAtPoint(context, CGPointZero, layer);

  // Restore the drawing context to undo CTM adjustments
  CGContextRestoreGState(context);
}

@end
