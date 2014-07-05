// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardTileView.h"
#import "../model/BoardViewMetrics.h"
#import "../model/BoardViewModel.h"
#import "../../main/ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardView.
// -----------------------------------------------------------------------------
@interface BoardView()
@property(nonatomic, assign) float crossHairPointDistanceFromFinger;
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
  [self updateCrossHairPointDistanceFromFinger];
  BoardViewModel* boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
  [boardViewModel addObserver:self forKeyPath:@"stoneDistanceFromFingertip" options:0 context:NULL];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  BoardViewModel* boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
  [boardViewModel removeObserver:self forKeyPath:@"stoneDistanceFromFingertip"];
  self.crossHairPoint = nil;
  [super dealloc];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  BoardViewModel* boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
  if (object == boardViewModel)
  {
    if ([keyPath isEqualToString:@"stoneDistanceFromFingertip"])
      [self updateCrossHairPointDistanceFromFinger];
  }
}

#pragma mark - Cross-hair handling

// -----------------------------------------------------------------------------
/// @brief Updates self.crossHairPointDistanceFromFinger.
///
/// The calculation performed by this method depends on the value of the
/// "stone distance from fingertip" user preference. The value is a percentage
/// that is applied to a maximum distance of n fingertips, i.e. if the user has
/// selected the maximum distance the cross-hair stone will appear n fingertips
/// away from the actual touch point on the screen. Currently n = 3, and 1
/// fingertip is assumed to be the size of a toolbar button as per Apple's HIG.
// -----------------------------------------------------------------------------
- (void) updateCrossHairPointDistanceFromFinger
{
  BoardViewModel* boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
  if (0.0f == boardViewModel.stoneDistanceFromFingertip)
  {
    self.crossHairPointDistanceFromFinger = 0;
  }
  else
  {
    static const float fingertipSizeInPoints = 20.0;  // toolbar button size in points
    static const float numberOfFingertips = 3.0;
    self.crossHairPointDistanceFromFinger = (fingertipSizeInPoints
                                             * numberOfFingertips
                                             * boardViewModel.stoneDistanceFromFingertip);
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a BoardViewIntersection object for the intersection that is
/// closest to the view coordinates @a coordinates. Returns
/// BoardViewIntersectionNull if there is no "closest" intersection.
///
/// Determining "closest" works like this:
/// - If the user has turned this on in the preferences, @a coordinates are
///   adjusted so that the intersection is not directly under the user's
///   fingertip
/// - Otherwise the same rules as for BoardViewMetrics::intersectionNear:()
///   apply - see that method's documentation.
// -----------------------------------------------------------------------------
- (BoardViewIntersection) crossHairIntersectionNear:(CGPoint)coordinates
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  coordinates.y -= self.crossHairPointDistanceFromFinger;
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

@end
