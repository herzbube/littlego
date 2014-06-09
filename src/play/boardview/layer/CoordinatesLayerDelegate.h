// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewLayerDelegateBase.h"


// -----------------------------------------------------------------------------
/// @brief The CoordinatesLayerDelegate class is responsible for drawing
/// coordinate labels in a strip along the horizontal or vertical edge of the
/// Go board.
// -----------------------------------------------------------------------------
@interface BVCoordinatesLayerDelegate : BoardViewLayerDelegateBase
{
}

- (id) initWithTileView:(BoardTileView*)tileView
                metrics:(PlayViewMetrics*)metrics
                   axis:(enum CoordinateLabelAxis)axis;

/// @brief The axis that CoordinatesLayerDelegate is drawing.
@property(nonatomic, assign) enum CoordinateLabelAxis coordinateLabelAxis;

@end
