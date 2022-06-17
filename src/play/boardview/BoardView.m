// -----------------------------------------------------------------------------
// Copyright 2014-2021 Patrick Näf (herzbube@herzbube.ch)
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
@property(nonatomic, retain) GoPoint* crossHairPoint;
@property(nonatomic, assign) bool crossHairPointIsLegalMove;
@property(nonatomic, retain) GoPoint* connectionStartPoint;
@property(nonatomic, retain) GoPoint* connectionEndPoint;
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
  self = [super initWithFrame:rect tileViewClass:[BoardTileView class]];
  if (! self)
    return nil;

  self.crossHairPoint = nil;
  self.crossHairPointIsLegalMove = true;
  self.connectionStartPoint = nil;
  self.connectionEndPoint = nil;
  self.boardViewAccessibility = [[[BoardViewAccessibility alloc] initWithBoardView:self] autorelease];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crossHairPoint = nil;
  self.connectionStartPoint = nil;
  self.connectionEndPoint = nil;
  self.boardViewAccessibility = nil;

  [super dealloc];
}

#pragma mark - Gesture handling

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

#pragma mark - Cross-hair handling

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair to the intersection identified by @a point,
/// specifying whether an actual play move at the intersection would be legal.
// -----------------------------------------------------------------------------
- (void) moveCrossHairTo:(GoPoint*)point
             isLegalMove:(bool)isLegalMove
         isIllegalReason:(enum GoMoveIsIllegalReason)illegalReason
{
  if (self.crossHairPoint == point && self.crossHairPointIsLegalMove == isLegalMove)
    return;

  self.crossHairPointIsLegalMove = isLegalMove;
  self.crossHairPoint = point;

  for (id subview in [self.tileContainerView subviews])
  {
    if (! [subview isKindOfClass:[BoardTileView class]])
      continue;
    BoardTileView* tileView = subview;
    [tileView notifyLayerDelegates:BVLDEventCrossHairChanged eventInfo:point];
    [tileView delayedDrawLayers];
  }
}

// -----------------------------------------------------------------------------
/// @brief Moves the interactively drawn connection of type @a connection so
/// that it is drawn between the points @a startPoint and @a endPoint. If either
/// or both GoPoint parameters is @e nil the connection is removed.
// -----------------------------------------------------------------------------
- (void) moveMarkupConnection:(enum GoMarkupConnection)connection
               withStartPoint:(GoPoint*)startPoint
                   toEndPoint:(GoPoint*)endPoint
{
  if (self.connectionStartPoint == startPoint && self.connectionEndPoint == endPoint)
    return;

  self.connectionStartPoint = startPoint;
  self.connectionEndPoint = endPoint;

  NSArray* eventInfo;
  if (startPoint && endPoint)
    eventInfo = @[[NSNumber numberWithInt:connection], startPoint, endPoint];
  else
    eventInfo = @[];

  for (id subview in [self.tileContainerView subviews])
  {
    if (! [subview isKindOfClass:[BoardTileView class]])
      continue;
    BoardTileView* tileView = subview;
    [tileView notifyLayerDelegates:BVLDEventInteractiveMarkupBetweenPointsDidChange eventInfo:eventInfo];
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
