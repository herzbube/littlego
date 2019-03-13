// -----------------------------------------------------------------------------
// Copyright 2014-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardView.h"
#import "BoardViewAccessibility.h"
#import "BoardTileView.h"
#import "../model/BoardViewMetrics.h"
#import "../model/BoardViewModel.h"
#import "../../main/ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardView.
// -----------------------------------------------------------------------------
@interface BoardView()
@property(nonatomic, assign) float crossHairPointDistanceFromFinger;
@property(nonatomic, retain) BoardViewAccessibility* boardViewAccessibility;
@end


@implementation BoardView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardView object with frame rectangle @a rect.
///
/// @note This is the designated initializer of BoardView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (TiledScrollView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.crossHairPoint = nil;
  self.crossHairPointIsLegalMove = true;
  self.crossHairPointIsIllegalReason = GoMoveIsIllegalReasonUnknown;
  self.boardViewAccessibility = [[[BoardViewAccessibility alloc] initWithBoardView:self] autorelease];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crossHairPoint = nil;
  self.boardViewAccessibility = nil;

  [super dealloc];
}

#pragma mark - Cross-hair handling

// -----------------------------------------------------------------------------
/// @brief Returns a BoardViewIntersection object for the intersection that is
/// closest to the view coordinates @a coordinates. Returns
/// BoardViewIntersectionNull if there is no "closest" intersection.
///
/// @see BoardViewMetrics::intersectionNear:() for details.
// -----------------------------------------------------------------------------
- (BoardViewIntersection) intersectionNear:(CGPoint)coordinates
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  return [metrics intersectionNear:coordinates];
}

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair to the intersection identified by @a point,
/// specifying whether an actual play move at the intersection would be legal.
// -----------------------------------------------------------------------------
- (void) moveCrossHairTo:(GoPoint*)point
             isLegalMove:(bool)isLegalMove
         isIllegalReason:(enum GoMoveIsIllegalReason)illegalReason
{
  if (_crossHairPoint == point && _crossHairPointIsLegalMove == isLegalMove)
    return;

  // Update *BEFORE* self.crossHairPoint so that KVO observers that monitor
  // self.crossHairPoint get all changes at once. Don't use self to update the
  // property because we don't want observers to monitor the property via KVO.
  _crossHairPointIsLegalMove = isLegalMove;
  _crossHairPointIsIllegalReason = illegalReason;
  self.crossHairPoint = point;

  for (BoardTileView* tileView in [self.tileContainerView subviews])
  {
    [tileView notifyLayerDelegates:BVLDEventCrossHairChanged eventInfo:point];
    [tileView delayedDrawLayers];
  }
}

#pragma mark - UIAccessibilityElement overrides

// -----------------------------------------------------------------------------
/// @brief UIAccessibilityElement method.
// -----------------------------------------------------------------------------
- (BOOL) isAccessibilityElement
{
  // Because BoardView is an UIAccessibilityContainer
  return NO;
}

#pragma mark - UIAccessibilityContainer overrides

// -----------------------------------------------------------------------------
/// @brief UIAccessibilityContainer method.
// -----------------------------------------------------------------------------
- (NSArray*) accessibilityElements
{
  return self.boardViewAccessibility.accessibilityElements;
}

@end
