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


// -----------------------------------------------------------------------------
/// @brief The PlayViewMetrics class is responsible for calculating the
/// coordinates and sizes of UI elements on the Play view, and for providing
/// those values to clients that need them for drawing.
///
/// If the bounds of the Play view change (e.g. when an interface orientation
/// occurs), someone must invoke updateWithRect:().
// -----------------------------------------------------------------------------
@interface PlayViewMetrics : NSObject
{
}

- (id) initWithModel:(PlayViewModel*)model;
- (void) updateWithRect:(CGRect)newRect boardSize:(enum GoBoardSize)newBoardSize;

/// @brief The rectangle that layers must use as their frame.
///
/// This property can be used for KVO. When the change notification fires, all
/// other properties are guaranteed to have updated values.
@property(nonatomic, assign) CGRect rect;
@property(nonatomic, assign) int boardDimension;
@property(nonatomic, assign) bool portrait;
@property(nonatomic, assign) int boardSize;
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
