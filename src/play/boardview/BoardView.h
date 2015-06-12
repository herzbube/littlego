// -----------------------------------------------------------------------------
// Copyright 2014-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "TiledScrollView.h"
#import "BoardViewIntersection.h"

// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The BoardView class subclasses TiledScrollView to add cross-hair
/// handling.
// -----------------------------------------------------------------------------
@interface BoardView : TiledScrollView
{
}

- (BoardViewIntersection) intersectionNear:(CGPoint)coordinates;
- (void) moveCrossHairTo:(GoPoint*)point
             isLegalMove:(bool)isLegalMove
         isIllegalReason:(enum GoMoveIsIllegalReason)illegalReason;

/// @name Cross-hair point properties
//@{
/// @brief Refers to the GoPoint object that marks the focus of the cross-hair.
///
/// Observers may monitor this property via KVO. If this property changes its
/// value, observers can also get updated values from the properties
/// @e crossHairPointIsLegalMove and @e crossHairPointIsIllegalReason.
@property(nonatomic, retain) GoPoint* crossHairPoint;
/// @brief Is true if the GoPoint object at the focus of the cross-hair
/// represents a legal move.
///
/// This property cannot be monitored via KVO.
@property(nonatomic, assign) bool crossHairPointIsLegalMove;
/// @brief If crossHairPointIsLegalMove is false, this contains the reason why
/// the move is illegal.
///
/// This property cannot be monitored via KVO.
@property(nonatomic, assign) enum GoMoveIsIllegalReason crossHairPointIsIllegalReason;
//@}

@end
