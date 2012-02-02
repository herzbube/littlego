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


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewMetrics.
// -----------------------------------------------------------------------------
@interface PlayViewMetrics()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) PlayViewModel* playViewModel;
//@}
@end


@implementation PlayViewMetrics

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
- (id) initWithModel:(PlayViewModel*)model
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  
  self.playViewModel = model;

  rect = CGRectNull;
  boardDimension = [GoBoard dimensionForSize:GoBoardSizeUndefined];
  self.portrait = true;
  self.boardSize = 0;
  self.boardOuterMargin = 0;
  self.boardInnerMargin = 0;
  self.topLeftBoardCornerX = 0;
  self.topLeftBoardCornerY = 0;
  self.topLeftPointX = 0;
  self.topLeftPointY = 0;
  self.numberOfCells = 0;
  self.pointDistance = 0;
  self.lineLength = 0;
  self.stoneRadius = 0;

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
/// @a newRect and @a newBoardSize.
///
/// This method does nothing if the previous calculation was based on the same
/// rectangle and board size.
// -----------------------------------------------------------------------------
- (void) updateWithRect:(CGRect)newRect boardSize:(enum GoBoardSize)newBoardSize
{
  int newBoardDimension = [GoBoard dimensionForSize:newBoardSize];
  if (CGRectEqualToRect(rect, newRect) && boardDimension == newBoardDimension)
    return;

  // ----------------------------------------------------------------
  // Use newRect and newBoardDimension for calculations. self.rect is updated
  // at the very end, after all other properties have been calculated. The
  // reason for this is that clients can use KVO on self.rect
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
  // +1 to self.numberOfCells because we need one-half of a cell on both sides
  // of the board (top/bottom or left/right) to draw a stone
  self.pointDistance = floor(self.boardSize / (self.numberOfCells + 1));
  self.boardInnerMargin = floor(self.pointDistance / 2);
  // Don't use border here - rounding errors might cause improper centering
  self.topLeftBoardCornerX = floor((newRect.size.width - self.boardSize) / 2);
  self.topLeftBoardCornerY = floor((newRect.size.height - self.boardSize) / 2);
  self.lineLength = self.pointDistance * numberOfCells;
  // Don't use padding here, rounding errors mighth cause improper positioning
  self.topLeftPointX = self.topLeftBoardCornerX + (self.boardSize - self.lineLength) / 2;
  self.topLeftPointY = self.topLeftBoardCornerY + (self.boardSize - self.lineLength) / 2;
  
  self.stoneRadius = floor(self.pointDistance / 2 * self.playViewModel.stoneRadiusPercentage);

  self.boardDimension = newBoardDimension;
  // Updating self.rect must be the last operation in this method; also use
  // self to update so that the synthesized setter will trigger KVO
  self.rect = newRect;
}

@end
