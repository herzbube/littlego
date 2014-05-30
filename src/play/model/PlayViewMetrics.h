// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayViewIntersection.h"

// Forward declarations
@class PlayViewModel;
@class GoPoint;
@class GoVertex;


// -----------------------------------------------------------------------------
/// @brief The PlayViewMetrics class is a model class that provides coordinates
/// and sizes of UI elements on the PlayView to clients that need them for
/// drawing.
///
/// If the frame of the Play view changes (e.g. when an interface orientation
/// change occurs), someone must invoke updateWithRect:(). If the size of the
/// Go board that is displayed by the Play view changes (e.g. when a new game
/// is started), someone must invoke updateWithBoardSize:(). If the display of
/// coordinate labels changes, someone must invoke
/// updateWithDisplayCoordinates:().
///
/// In reaction to either of these events, PlayViewMetrics re-calculates all
/// of its properties. Clients are expected to use KVO to notice any changes in
/// self.rect, self.boardSize or self.displayCoordinates, and to respond to such
/// changes by initiating the re-drawing of the appropriate parts of the Go
/// board.
///
///
/// @par Calculations
///
/// The following schematic illustrates the composition of the view for a
/// (theoretical) 4x4 board. Note that view has rectangular dimensions, while
/// the board is square and centered within the view rectangle.
///
/// @verbatim
///                                                      offsetForCenteringX
///       +------- topLeftBoardCorner                   +-----+
///       |    +-- topLeftPoint                         |     |
///       |    |                                        |     v
/// +---- | -- | --------------view-------------------- | ----+ <--+
/// |     v    |                                        v     |    | offsetForCenteringY
/// |     +--- v --------------board--------------------+ <--------+
/// |     |    A           B           C           D    |     |
/// |     |   /-\         /-\                           |     |
/// |     |4 | o |-------| o |--grid---o-----------o   4|     |
/// |     |   \-/         \-/          |           |    |     |
/// |     |    |           |           |           |    |     |
/// |     |    |           |           |           |    |     |
/// |     |    |           |           |           |    |     |
/// |     |    |          /-\         /-\         /-\   |     |
/// |     |3   o---------| o |-------| o |-------| o | 3<-------- coordinate label
/// |     |    |          \-/         \-/         \-/   |     |   coordinateLabelStripWidth
/// |     |    |           |         ^   ^         |    |     |   is the distance from the
/// |     |    |           |         +---+         |    |     |   stone to the board edge
/// |     |    |           |    stoneRadius*2+1    |    |     |
/// |     |    |           |       (diameter)      |    |     |
/// |     |2   o-----------o-----------+-----------o   2|     |
/// |     |    |           |           |           |    |     |
/// |     |    |           |           |           |    |     |
/// |     |    |           |           |           |    |     |
/// |     |    |           |           |           |    |     |
/// |     |    |           |           |           |    |     |
/// |     |1   o-----------o-----------o-----------o   1|     |
/// |     |    ^           ^^         ^            ^    |     |
/// |     +--- | --------- ||  cell   | ---------- | ---+     |
/// |     ^    |           |+--Width--+            |    ^     |
/// +---- |    |           | point    ^            |    | ----+
///       |    |           +-Distance-+            |    |
///       |    +------------lineLength-------------+    |
///       +--------------boardSideLength----------------+
/// @endverbatim
///
///
/// The coordinates of topLeftBoardCorner, topLeftPoint and bottomRightPoint
/// are based on a coordinate system whose origin is in the top-left corner.
/// UIKit and Core Animation use such a coordinate system, while Core Graphics
/// uses a coordinate system with the origin in the lower-left corner. Also see
/// http://developer.apple.com/library/ios/#documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html
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
/// A straight line of width 1 can be drawn in different ways. Core Graphics
/// can be observed to behave differently for the following cases:
/// - The line is created with a path. To prevent anti-aliasing, the path must
///   start and end at coordinates that have fractional x.5 values.
/// - The line is created by filling a path that is a rectangle of width or
///   height 1. To prevent anti-aliasing, the rectangle origin must be at a
///   coordinate that has integral x.0 values.
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

/// @name Updaters
//@{
- (void) updateWithRect:(CGRect)newRect;
- (void) updateWithBoardSize:(enum GoBoardSize)newBoardSize;
- (void) updateWithDisplayCoordinates:(bool)newDisplayCoordinates;
//@}

/// @name Calculators
//@{
- (CGPoint) coordinatesFromPoint:(GoPoint*)point;
- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates;
- (PlayViewIntersection) intersectionNear:(CGPoint)coordinates;
//@}


// -----------------------------------------------------------------------------
/// @name Main properties
// -----------------------------------------------------------------------------
//@{
/// @brief The rectangle that Play view layers must use as their frame.
///
/// Clients that use KVO on this property will be triggered after
/// PlayViewMetrics has updated its values to match the new rectangle.
@property(nonatomic, assign) CGRect rect;
/// @brief The size of the Go board that is drawn by Play view layers.
///
/// Clients that use KVO on this property will be triggered after
/// PlayViewMetrics has updated its values to match the new board size.
@property(nonatomic, assign) enum GoBoardSize boardSize;
/// @brief True if coordinate labels are displayed, false if not.
///
/// Clients that use KVO on this property will be triggered after
/// PlayViewMetrics has updated its values to match the new display coordinates
/// value.
///
/// @note PlayViewModel has a property of the same name, which is the master
/// property on which PlayViewMetrics depends. For this reason, clients that
/// require correct values from PlayViewMetrics must ***NOT*** use KVO on the
/// PlayViewModel property.
@property(nonatomic, assign) bool displayCoordinates;
//@}

// -----------------------------------------------------------------------------
/// @name Properties that depend on main properties
// -----------------------------------------------------------------------------
//@{
/// @brief True if @e rect refers to a rectangle with portrait orientation,
/// false if the rectangle uses landscape orientation.
@property(nonatomic, assign) bool portrait;
@property(nonatomic, assign) int boardSideLength;
@property(nonatomic, assign) CGFloat topLeftBoardCornerX;
@property(nonatomic, assign) CGFloat topLeftBoardCornerY;
@property(nonatomic, assign) CGFloat topLeftPointX;
@property(nonatomic, assign) CGFloat topLeftPointY;
@property(nonatomic, assign) CGFloat bottomRightPointX;
@property(nonatomic, assign) CGFloat bottomRightPointY;
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
/// @brief The width of the strip inside which coordinate labels are drawn. For
/// the horizontal strip this is the strip's height.
///
/// If coordinate labels are not displayed, coordinateLabelStripWidth is 0.
///
/// As shown in the following schematic, the strip width includes
/// coordinateLabelInset.
///
/// @verbatim
/// +------- x------------
/// |       +-+     +-+   \
/// |       |A|     |B|    +-- x = coordinateLabelInset
/// |       +-+     +-+   /
/// |        x------------
/// | +--+  /-\
/// | |19| | o |-----o----
/// | +--+  \-/      |
/// |        |       |
/// |        |       |
/// | +--+  /-\      |
/// | |18| | o |-----o----
/// | +--+  \-/      |
/// |     ^  |       |
/// ^     |
/// |     |
/// +-----+
///  coordinateLabelStripWidth
/// @endverbatim
@property(nonatomic, assign) int coordinateLabelStripWidth;
/// @brief A coordinate label is drawn a small distance away from both the stone
/// and the board edge. coordinateLabelInset denotes that distance.
///
/// If coordinate labels are not displayed, coordinateLabelInset is 0.
/// coordinateLabelInset may also be 0 if coordinateLabelStripWidth is very
/// small and not enough space exists for a pretty inset.
@property(nonatomic, assign) int coordinateLabelInset;
/// @brief The font to use for drawing move numbers. Is nil if no suitable font
/// exists for the current metrics (usually because stoneRadius is too small).
@property(nonatomic, assign) UIFont* moveNumberFont;
/// @brief The maximum size required for drawing the widest possible move
/// number using the current @e moveNumberFont. Is CGSizeZero if no suitable
/// font exists.
@property(nonatomic, assign) CGSize moveNumberMaximumSize;
/// @brief The font to use for drawing coordinate labels. Is nil if no suitable
/// font exists for the current metrics (usually because
/// coordinateLabelStripWidth is too small).
@property(nonatomic, assign) UIFont* coordinateLabelFont;
/// @brief The maximum size required for drawing the widest possible coordinate
/// label using the current @e coordinateLabelFont. Is CGSizeZero if no suitable
/// font exists.
@property(nonatomic, assign) CGSize coordinateLabelMaximumSize;
/// @brief The font to use for drawing the "next move" label. Is nil if no
/// suitable font exists for the current metrics (usually because
/// stoneInnerSquareSize is too small).
@property(nonatomic, assign) UIFont* nextMoveLabelFont;
/// @brief The maximum size required for drawing the widest possible "next move"
/// label using the current @e nextMoveLabelFont. Is CGSizeZero if no suitable
/// font exists.
@property(nonatomic, assign) CGSize nextMoveLabelMaximumSize;
//@}

// -----------------------------------------------------------------------------
/// @name Static properties whose values never change
// -----------------------------------------------------------------------------
//@{
@property(nonatomic, retain) UIColor* lineColor;
@property(nonatomic, assign) int boundingLineWidth;
@property(nonatomic, assign) int normalLineWidth;
@property(nonatomic, retain) UIColor* starPointColor;
@property(nonatomic, assign) int starPointRadius;
@property(nonatomic, assign) float stoneRadiusPercentage;
@property(nonatomic, retain) UIColor* crossHairColor;
//@}

@end
