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


@class PlayViewModel;
@class GoPoint;
@class GoVertex;

// -----------------------------------------------------------------------------
/// @brief The PlayViewMetrics class is responsible for calculating the
/// coordinates and sizes of UI elements on the Play view, and for providing
/// those values to clients that need them for drawing. PlayViewMetrics also
/// provides a few drawing helper methods because their implementation is also
/// calculation-heavy.
///
/// If the frame of the Play view changes (e.g. when an interface orientation
/// change occurs), someone must invoke updateWithRect:(). If the size of the
/// Go board that is displayed by the Play view changes (e.g. when a new game
/// is started), someone must invoke updateWithBoardSize:().
///
/// In reaction to either of these events, PlayViewMetrics re-calculates all
/// of its properties. Re-drawing of layers must be initiated separately.
///
///
/// @par Calculations
///
/// All calculations rely on the coordinate system origin being in the top-left
/// corner.
///
/// The following schematic illustrates the composition of the view for a
/// (theoretical) 4x4 board.
///
/// @verbatim
///    +------ topLeftBoardCorner
///    |   +-- topLeftPoint
///    |   |
/// +- | - | ---------------rect----------------------+
/// |  v   |                boardOuterMargin          |
/// |  +---v----------------board------------------+  |
/// |  |  /-\         /-\                          |  |
/// |  | |-o-|-------|-o-|--grid---o-----------o   |  |
/// |  |  \-/         \-/          |           |   |  |
/// |  |   |           |           |           |   |  |
/// |  |   |           |           |           |   |  |
/// |  |   |           |           |           |   |  |
/// |  |   |          /-\         /-\          |   |  |
/// |  |   o---------|-o-|-------|-o-|---------o   |  |
/// |  |   |          \-/         \-/          |   |  |
/// |  |   |           |         ^   ^         |   |  |
/// |  |   |           |         +---+         |   |  |
/// |  |   |           |    stoneRadius*2+1    |   |  |
/// |  |   |           |       (diameter)      |   |  |
/// |  |   o-----------o-----------+-----------o   |  |
/// |  |   |           |           |           |   |  |
/// |  |   |           |           |           |   |  |
/// |  |   |           |           |           |   |  |
/// |  |   |           |           |           |   |  |
/// |  |   |           |           |           |   |  |
/// |  |   o-----------o-----------o-----------o   |  |
/// |  |   ^           ^^         ^            ^   |  |
/// |  +-- | --------- ||  cell   | ---------- | --+  |
/// |  ^   |           |+--Width--+            |   ^  |
/// +- |   |           | point    ^            |   | -+
///    |   |           +-Distance-+            |   |
///    |   +------------lineLength-------------+   |
///    +--------------boardSideLength--------------+
/// @endverbatim
///
///
/// As a small reminder for how to calculate distances, lengths and sizes in the
/// graphics system: The coordinate system is zero-based, and the distance
/// between two points always includes the starting point, but not the end point
/// (cf. pointDistance in the schematic above).
///
///
/// @par Anti-aliasing
///
/// Most calculations are made with integer types. If necessary, the actual
/// drawing then uses a half-pixel translation to prevent anti-aliasing for
/// straight lines. Half-pixel translation is usually needed when lines have an
/// odd-numbered width (e.g. 1, 3, ...). See http://stackoverflow.com/questions/2488115/how-to-set-up-a-user-quartz2d-coordinate-system-with-scaling-that-avoids-fuzzy-dr
/// for details. Half-pixel translation may also be necessary if something is
/// drawn with its center at an intersection on the Go board, and the
/// intersection coordinate has fractional x.5 values.
///
/// Half-pixel translation may not be required if a CGLayer is drawn with its
/// upper-left corner at a coordinate whose values are integral numbers.
///
/// @note It's not possible to turn off anti-aliasing, instead of doing
/// half-pixel translation. The reason is that 1) round shapes (e.g. star
/// points, stones) do need anti-aliasing; and 2) if only some parts of the view
/// are drawn with anti-aliasing, and others are not, things become mis-aligned
/// (e.g. stones are not exactly centered on line intersections).
// -----------------------------------------------------------------------------
@interface PlayViewMetrics : NSObject
{
}

/// @name Initialization and deallocation
//@{
- (id) initWithView:(UIView*)view model:(PlayViewModel*)model;
- (void) dealloc;
//@}

/// @name Updaters
//@{
- (void) updateWithRect:(CGRect)newRect;
- (void) updateWithBoardSize:(enum GoBoardSize)newBoardSize;
//@}

/// @name Calculators
//@{
- (CGPoint) coordinatesFromPoint:(GoPoint*)point;
- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates;
- (GoPoint*) pointNear:(CGPoint)coordinates;
//@}

/// @name Layer creation functions
///
/// @brief These functions exist as CF-like creation functions to make Xcode's
/// analyze tool happy. If these functions are declared as Obj-C methods, the
/// analyze tool reports a possible memory leak because it does not see the
/// method as conforming to Core Foundation's ownership policy naming
/// conventions.
//@{
CGLayerRef CreateLineLayer(CGContextRef context, UIColor* lineColor, int lineWidth, PlayViewMetrics* metrics);
CGLayerRef CreateStoneLayerWithColor(CGContextRef context, UIColor* stoneColor, PlayViewMetrics* metrics);
CGLayerRef CreateStoneLayerWithImage(CGContextRef context, NSString* stoneImageName, PlayViewMetrics* metrics);
//@}

/// @name Drawing helpers
//@{
- (void) drawLineLayer:(CGLayerRef)layer withContext:(CGContextRef)context horizontal:(bool)horizontal positionedAtPoint:(GoPoint*)point;
- (void) drawLayer:(CGLayerRef)layer withContext:(CGContextRef)context centeredAtPoint:(GoPoint*)point;
//@}


/// @brief The rectangle that Play view layers must use as their frame.
@property(nonatomic, assign) CGRect rect;
/// @brief The size of the Go board that is drawn by Play view layers.
@property(nonatomic, assign) enum GoBoardSize boardSize;
/// @brief True if @e rect refers to a rectangle with portrait orientation,
/// false if the rectangle uses landscape orientation.
@property(nonatomic, assign) bool portrait;
@property(nonatomic, assign) int boardSideLength;
@property(nonatomic, assign) int topLeftBoardCornerX;
@property(nonatomic, assign) int topLeftBoardCornerY;
@property(nonatomic, assign) int topLeftPointX;
@property(nonatomic, assign) int topLeftPointY;
@property(nonatomic, assign) int bottomRightPointX;
@property(nonatomic, assign) int bottomRightPointY;
@property(nonatomic, assign) int numberOfCells;
/// @brief Denotes the number of uncovered points between two grid lines. The
/// numeric value is guaranteed to be an even number.
@property(nonatomic, assign) int cellWidth;
/// @brief Denotes the distance between two points, or intersections, on the
/// Go board. Thickness of normal grid lines is taken into account.
@property(nonatomic, assign) int pointDistance;
/// @brief The length of a grid line. Thickness of bounding and normal grid
/// lines is taken into account.
@property(nonatomic, assign) int lineLength;
/// @brief Radius of the circle that represents a Go stone. The circle is
/// guaranteed to fit into a rectangle of size pointCellSize.
@property(nonatomic, assign) int stoneRadius;
/// @brief Size that denotes a square whose side length is "cellWidth + the
/// width of a normal grid line".
///
/// The purpose of this size is to define the drawing area "owned" by an
/// intersection on the Go board. All drawing artifacts that belong to an
/// intersection (e.g. star point, Go stone, territory for scoring) must stay
/// within the boundaries defined by pointCellSize.
///
/// As the following schematic illustrates, two adjacent rectangles that both
/// use pointCellSize will not overlap.
///
/// @verbatim
/// o------o------o------o
/// |      |      |      |
/// |   +-----++-----+   |
/// |   |  |  ||  |  |   |
/// o---|--A--||--B--|---o
/// |   |  |  ||  |  |   |
/// |   +-----++-----+   |
/// |      |      |      |
/// o------o------o------o
/// @endverbatim
@property(nonatomic, assign) CGSize pointCellSize;
/// @brief Size that denotes a square whose side length makes it fit inside the
/// circle that represents a Go stone (i.e. a circle whose size is defined by
/// stoneRadius).
///
/// The square does not touch the circle, it is slighly inset.
@property(nonatomic, assign) CGSize stoneInnerSquareSize;
/// @brief An offset to subtract from an intersection coordinate component
/// (x or y) to find the coordinate of the starting point to draw a grid line.
@property(nonatomic, assign) CGFloat lineStartOffset;
/// @brief An offset to add or subtract from an intersection coordinate
/// component (x or y) to find the coordinate of the starting point to draw a
/// bounding grid line.
@property(nonatomic, assign) CGFloat boundingLineStrokeOffset;
@end
