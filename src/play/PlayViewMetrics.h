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


@class PlayViewModel;
@class GoPoint;
@class GoVertex;

// -----------------------------------------------------------------------------
/// @brief The PlayViewMetrics class is responsible for calculating the
/// coordinates and sizes of UI elements on the Play view, and for providing
/// those values to clients that need them for drawing.
///
/// If the frame of the Play view changes (e.g. when an interface orientation
/// change occurs), someone must invoke updateWithRect:(). If the size of the
/// Go board that is displayed by the Play view changes (e.g. when a new game
/// is started), someone must invoke updateWithBoardSize:().
///
/// In reaction to either of those events, PlayViewMetrics re-calculates all
/// of its properties. The last property that is updated is either @e boardSize,
/// or @e rect, depending on which updater method was invoked. Clients of
/// PlayViewMetrics may use KVO to monitor either of those properties for
/// changes.
// -----------------------------------------------------------------------------
@interface PlayViewMetrics : NSObject
{
}

/// @name Initialization and deallocation
//@{
- (id) initWithView:(UIView*)view model:(PlayViewModel*)model;
- (void) dealloc;
//@}

/// @name Calculators
//@{
- (void) updateWithRect:(CGRect)newRect;
- (void) updateWithBoardSize:(enum GoBoardSize)newBoardSize;
//@}

/// @name Calculators
//@{
- (CGPoint) coordinatesFromPoint:(GoPoint*)point;
- (CGPoint) coordinatesFromVertex:(GoVertex*)vertex;
- (CGPoint) coordinatesFromVertexX:(int)vertexX vertexY:(int)vertexY;
- (GoVertex*) vertexFromCoordinates:(CGPoint)coordinates;
- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates;
- (CGRect) innerSquareAtPoint:(GoPoint*)point;
- (CGRect) squareAtPoint:(GoPoint*)point;
- (CGRect) squareWithCenterPoint:(CGPoint)center sideLength:(double)sideLength;
//@}


/// @brief The rectangle that Play view layers must use as their frame.
///
/// This property can be used for KVO. When the change notification fires, all
/// other properties are guaranteed to have updated values.
@property(nonatomic, assign) CGRect rect;
/// @brief The size of the Go board that is drawn by Play view layers.
///
/// This property can be used for KVO. When the change notification fires, all
/// other properties are guaranteed to have updated values.
@property(nonatomic, assign) enum GoBoardSize boardSize;
@property(nonatomic, assign) bool portrait;
@property(nonatomic, assign) int boardSideLength;
@property(nonatomic, assign) int boardOuterMargin;  // distance to view edge
@property(nonatomic, assign) int boardInnerMargin;  // distance to grid
@property(nonatomic, assign) int topLeftBoardCornerX;
@property(nonatomic, assign) int topLeftBoardCornerY;
@property(nonatomic, assign) int topLeftPointX;
@property(nonatomic, assign) int topLeftPointY;
@property(nonatomic, assign) int numberOfCells;
@property(nonatomic, assign) int pointDistance;
@property(nonatomic, assign) int lineLength;
@property(nonatomic, assign) int stoneRadius;

@end
