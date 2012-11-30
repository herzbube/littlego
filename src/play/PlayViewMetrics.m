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
#import "PlayViewMetrics.h"
#import "PlayViewModel.h"
#import "../go/GoBoard.h"
#import "../go/GoGame.h"
#import "../go/GoPoint.h"
#import "../go/GoVertex.h"
#import "../ui/UiUtilities.h"


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
@synthesize bottomRightPointX;
@synthesize bottomRightPointY;
@synthesize numberOfCells;
@synthesize cellWidth;
@synthesize pointDistance;
@synthesize lineLength;
@synthesize stoneRadius;
@synthesize pointCellSize;
@synthesize stoneInnerSquareSize;
@synthesize lineStartOffset;
@synthesize boundingLineStrokeOffset;


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
    self.bottomRightPointX = self.topLeftPointX;
    self.bottomRightPointY = self.topLeftPointY;
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

    
    
    // Calculate topLeftPointMargin so that the grid is centered. -1 to
    // newBoardSize because our goal is to get the coordinates of the top-left
    // point, which sits in the middle of a normal line. Because the centering
    // calculation divides by 2 we must subtract a full line width here, not
    // just half a line width.
    int widthForCentering = self.cellWidth * numberOfCells + (newBoardSize - 1) * self.playViewModel.normalLineWidth;
    int topLeftPointMargin = floor((self.boardSideLength - widthForCentering) / 2);
    if (topLeftPointMargin < self.cellWidth / 2.0)
    {
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:[NSString stringWithFormat:@"Insufficient space to draw stones: topLeftPointMargin %d is below half-cell width", topLeftPointMargin]
                                                     userInfo:nil];
      @throw exception;
    }
    self.topLeftPointX = self.topLeftBoardCornerX + topLeftPointMargin;
    self.topLeftPointY = self.topLeftBoardCornerY + topLeftPointMargin;
    self.bottomRightPointX = self.topLeftPointX + (newBoardSize - 1) * self.pointDistance;
    self.bottomRightPointY = self.topLeftPointY + (newBoardSize - 1) * self.pointDistance;

    // Calculate self.pointCellSize. See property documentation for details
    // what we calculate here.
    int pointCellSideLength = self.cellWidth + self.playViewModel.normalLineWidth;
    self.pointCellSize = CGSizeMake(pointCellSideLength, pointCellSideLength);

    // Geometry tells us that for the square with side length "a":
    //   a = r * sqrt(2)
    int stoneInnerSquareSideLength = floor(self.stoneRadius * sqrt(2));
    // Subtract an additional 1-2 points because we don't want to touch the
    // stone circle. The square side length must be an odd number to prevent
    // anti-aliasing when the square is drawn (we assume that drawing occurs
    // with playViewModel.normalLineWidth and that the line width is an odd
    // number (typically 1 point)).
    --stoneInnerSquareSideLength;
    if (stoneInnerSquareSideLength % 2 == 0)
      --stoneInnerSquareSideLength;
    self.stoneInnerSquareSize = CGSizeMake(stoneInnerSquareSideLength, stoneInnerSquareSideLength);

    // Schema depicting the horizontal bounding line at the top of the board:
    //
    //       +----------->  +------------------------- startB
    //       |              |
    //       |              |
    //       |              |
    // widthB|              | ------------------------ strokeB
    //       |              |
    //       |        +-->  |   +--------------------- startN
    //       |  widthN|     |   | -------------------- strokeN
    //       +----->  +-->  +-- +---------------------
    //
    // widthN = width normal line
    // widthB = width bounding line
    // startN = start coordinate for normal line
    // startB = start coordinate for bounding line
    // strokeN = stroke coordinate for normal line, also self.topLeftPointY
    // strokeB = stroke coordinate for bounding line
    //
    // Notice how the lower edge of the bounding line is flush with the lower
    // edge of the normal line (it were drawn here). The calculation for
    // strokeB goes like this:
    //       strokeB = strokeN + widthN/2 - widthB/2
    //
    // Based on this, the calculation for startB looks like this:
    //       startB = strokeB - widthB / 2
    int normalLineStrokeCoordinate = self.topLeftPointY;
    CGFloat normalLineHalfWidth = self.playViewModel.normalLineWidth / 2.0;
    CGFloat boundingLineHalfWidth = self.playViewModel.boundingLineWidth / 2.0;
    CGFloat boundingLineStrokeCoordinate = normalLineStrokeCoordinate + normalLineHalfWidth - boundingLineHalfWidth;
    self.boundingLineStrokeOffset = normalLineStrokeCoordinate - boundingLineStrokeCoordinate;
    CGFloat boundingLineStartCoordinate = boundingLineStrokeCoordinate - boundingLineHalfWidth;
    self.lineStartOffset = normalLineStrokeCoordinate - boundingLineStartCoordinate;
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
/// @brief Returns a GoPoint object for the intersection that is closest to the
/// view coordinates @a coordinates. Returns nil if there is no "closest"
/// intersection.
///
/// Determining "closest" works like this:
/// - The closest intersection is the one whose distance to @a coordinates is
///   less than half the distance between two adjacent intersections
///   - During panning this creates a "snap-to" effect when the user's panning
///     fingertip crosses half the distance between two adjacent intersections.
///   - For a tap this simply makes sure that the fingertip does not have to
///     hit the exact coordinate of the intersection.
/// - If @a coordinates are a sufficient distance away from the Go board edges,
///   there is no "closest" intersection
// -----------------------------------------------------------------------------
- (GoPoint*) pointNear:(CGPoint)coordinates
{
  int halfPointDistance = floor(self.pointDistance / 2);
  bool coordinatesOutOfRange = false;

  // Check if coordinates are outside the grid on the x-axis and cannot be
  // mapped to a point. To make the edge lines accessible in the same way as
  // the inner lines, a padding of half a point distance must be added.
  if (coordinates.x < self.topLeftPointX)
  {
    if (coordinates.x < self.topLeftPointX - halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.x = self.topLeftPointX;
  }
  else if (coordinates.x > self.bottomRightPointX)
  {
    if (coordinates.x > self.bottomRightPointX + halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.x = self.bottomRightPointX;
  }
  else
  {
    // Adjust so that the snap-to calculation below switches to the next vertex
    // when the coordinates are half-way through the distance to that vertex
    coordinates.x += halfPointDistance;
  }

  // Unless the x-axis checks have already found the coordinates to be out of
  // range, we now perform the same checks as above on the y-axis
  if (coordinatesOutOfRange)
  {
    // Coordinates are already out of range, no more checks necessary
  }
  else if (coordinates.y < self.topLeftPointY)
  {
    if (coordinates.y < self.topLeftPointY - halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.y = self.topLeftPointY;
  }
  else if (coordinates.y > self.bottomRightPointY)
  {
    if (coordinates.y > self.bottomRightPointY + halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.y = self.bottomRightPointY;
  }
  else
  {
    coordinates.y += halfPointDistance;
  }

  // Snap to the nearest vertex, unless the coordinates were out of range
  if (coordinatesOutOfRange)
    return nil;
  else
  {
    coordinates.x = (self.topLeftPointX
                     + self.pointDistance * floor((coordinates.x - self.topLeftPointX) / self.pointDistance));
    coordinates.y = (self.topLeftPointY
                     + self.pointDistance * floor((coordinates.y - self.topLeftPointY) / self.pointDistance));
    return [self pointFromCoordinates:coordinates];
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a horizontal
/// grid line that uses the specified color @a lineColor and width @a lineWidth.
///
/// If the grid line should be drawn vertically, a 90 degrees rotation must be
/// added to the CTM before drawing.
///
/// All sizes are taken from the current metrics values.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this method is responsible for releasing the returned
/// CGLayer object using the function CGLayerRelease when the layer is no
/// longer needed.
// -----------------------------------------------------------------------------
- (CGLayerRef) lineLayerWithContext:(CGContextRef)context lineColor:(UIColor*)lineColor lineWidth:(int)lineWidth
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = CGSizeMake(self.lineLength, lineWidth);
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGContextSetFillColorWithColor(layerContext, lineColor.CGColor);
  CGContextFillRect(layerContext, layerRect);

  return layer;
}

// -----------------------------------------------------------------------------
/// @brief Draws the layer @a layer using the specified drawing context so that
/// the layer is suitably placed with @a point as the reference.
///
/// The numeric vertex of @a point is also used to determine whether the line
/// to be drawn is a normal or a bounding line.
///
/// @note This method assumes that @a layer contains the drawing operations for
/// rendering a horizontal line. If @a horizontal is false, the CTM will
/// therefore be rotated to make the line point downwards.
// -----------------------------------------------------------------------------
- (void) drawLineLayer:(CGLayerRef)layer withContext:(CGContextRef)context horizontal:(bool)horizontal positionedAtPoint:(GoPoint*)point
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  int lineIndexCountingFromTopLeft;
  if (horizontal)
    lineIndexCountingFromTopLeft = self.boardSize - numericVertex.y;
  else
    lineIndexCountingFromTopLeft = numericVertex.x - 1;
  bool isBoundingLineLeftOrTop = (0 == lineIndexCountingFromTopLeft);
  bool isBoundingLineRightOrBottom = ((self.boardSize - 1) == lineIndexCountingFromTopLeft);
  // Line layer must refer to a horizontal line
  CGSize layerSize = CGLayerGetSize(layer);
  CGFloat lineHalfWidth = layerSize.height / 2.0;

  // Create a save point that we can restore to before we leave this method
  CGContextSaveGState(context);

  CGPoint pointCoordinates = [self coordinatesFromPoint:point];
  if (horizontal)
  {
    // Place line so that its upper-left corner is at the y-position of the
    // specified intersections
    CGContextTranslateCTM(context, self.topLeftPointX, pointCoordinates.y);
    // Place line so that it straddles the y-position of the specified
    // intersection
    CGContextTranslateCTM(context, 0, -lineHalfWidth);
    // If it's a bounding line, adjust the line position so that its edge is
    // in the same position as if a normal line were drawn. The surplus width
    // lies outside of the board. As a result, all cells inside the board have
    // the same size.
    if (isBoundingLineLeftOrTop)
      CGContextTranslateCTM(context, 0, -self.boundingLineStrokeOffset);
    else if (isBoundingLineRightOrBottom)
      CGContextTranslateCTM(context, 0, self.boundingLineStrokeOffset);
    // Adjust horizontal line position so that it starts at the left edge of
    // the left bounding line
    CGContextTranslateCTM(context, -lineStartOffset, 0);
  }
  else
  {
    // Perform translations as if the line were already vertical, pointing
    // downwards from the top-left origin. We are going to perform the rotation
    // further down, but only *AFTER* doing translations; if we were rotating
    // *BEFORE* doing translations, we would have to swap x/y translation
    // components, which would be very confusing and potentially dangerous to
    // the brain of whoever tries to debug this code :-)
    CGContextTranslateCTM(context, pointCoordinates.x, self.topLeftPointY);
    CGContextTranslateCTM(context, -lineHalfWidth, 0);  // use y-coordinate because layer rect is horizontal
    if (isBoundingLineLeftOrTop)
      CGContextTranslateCTM(context, -self.boundingLineStrokeOffset, 0);
    else if (isBoundingLineRightOrBottom)
      CGContextTranslateCTM(context, self.boundingLineStrokeOffset, 0);
    CGContextTranslateCTM(context, 0, -lineStartOffset);
    // Shift all vertical lines 1 point to the right. This is what I call
    // "the mystery point" - I couldn't come up with a satisfactory explanation
    // why this is needed even after hours of geometric drawings and manual
    // calculations. Very unsatisfactory :-(
    CGContextTranslateCTM(context, 1, 0);
    // We are finished with regular translations and are now almost ready to
    // rotate. However, we must still perform one final translation: The one
    // that makes sure that the rotation will align the left (not the right!)
    // border of the line with y-coordinate 0. If this is hard to understand,
    // take a piece of paper and make some drawings. Keep in mind that the
    // origin used for rotation will also be moved by CTM translations (or maybe
    // it's more intuitive to imagine that any artifact will be rotated
    // "in place")!
    CGSize layerSize = CGLayerGetSize(layer);
    CGContextTranslateCTM(context, layerSize.height, 0);
    // Phew, done, finally we can rotate. 
    CGContextRotateCTM(context, [UiUtilities radians:90]);
  }
  // Half-pixel translation to prevent unnecessary anti-aliasing. We need this
  // because above at some point we perform a translation that lets the line
  // straddle the intersection.
  CGContextTranslateCTM(context, gHalfPixel, gHalfPixel);

  // Because of the CTM adjustments, we can now use CGPointZero
  CGContextDrawLayerAtPoint(context, CGPointZero, layer);

  // Restore the drawing context to undo CTM adjustments
  CGContextRestoreGState(context);
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a stone that
/// uses the specified color @a stoneColor.
///
/// All sizes are taken from the current metrics values.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this method is responsible for releasing the returned
/// CGLayer object using the function CGLayerRelease when the layer is no
/// longer needed.
///
/// @note This method is currently not in use, it has been superseded by
/// stoneLayerWithContext:stoneImageNamed:(). This method is preserved for
/// demonstration purposes, i.e. how to draw a simple circle with a fill color.
// -----------------------------------------------------------------------------
- (CGLayerRef) stoneLayerWithContext:(CGContextRef)context stoneColor:(UIColor*)stoneColor
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = self.pointCellSize;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
  const int startRadius = [UiUtilities radians:0];
  const int endRadius = [UiUtilities radians:360];
  const int clockwise = 0;

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
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to draw a stone that
/// uses the bitmap image in the bundle resource file named @a name.
///
/// All sizes are taken from the current metrics values.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this method is responsible for releasing the returned
/// CGLayer object using the function CGLayerRelease when the layer is no
/// longer needed.
// -----------------------------------------------------------------------------
- (CGLayerRef) stoneLayerWithContext:(CGContextRef)context stoneImageNamed:(NSString*)name
{
  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = self.pointCellSize;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  // The values assigned here have been determined experimentally
  CGFloat yAxisAdjustmentToVerticallyCenterImageOnIntersection;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    yAxisAdjustmentToVerticallyCenterImageOnIntersection = 0.5;
  }
  else
  {
    switch (self.boardSize)
    {
      case GoBoardSize7:
      case GoBoardSize9:
        yAxisAdjustmentToVerticallyCenterImageOnIntersection = 2.0;
        break;
      default:
        yAxisAdjustmentToVerticallyCenterImageOnIntersection = 1.0;
        break;
    }
  }
  CGContextTranslateCTM(layerContext, 0, yAxisAdjustmentToVerticallyCenterImageOnIntersection);

  UIImage* stoneImage = [UIImage imageNamed:name];
  // Let UIImage do all the drawing for us. This includes 1) compensating for
  // coordinate system differences (if we use CGContextDrawImage() the image
  // is drawn upside down); and 2) for scaling.
  UIGraphicsPushContext(layerContext);
  [stoneImage drawInRect:layerRect];
  UIGraphicsPopContext();

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
