// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayViewLayerDelegateBase.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the axis' supported by CoordinateLabelsLayerDelegate.
// -----------------------------------------------------------------------------
enum CoordinateLabelAxis
{
  CoordinateLabelAxisLetter,
  CoordinateLabelAxisNumber
};


// -----------------------------------------------------------------------------
/// @brief The CoordinateLabelsLayerDelegate class is responsible for drawing
/// coordinate labels in a strip along the horizontal or vertical edge of the
/// Go board.
///
/// CoordinateLabelsLayerDelegate is exceptional in that it is not a sublayer
/// of PlayView. Instead CoordinateLabelsLayerDelegate is a sublayer of a
/// separate coordinate label view (specified as @a mainView parameter when the
/// initializer is invoked). For more information on why this is the case, see
/// the PlayView class documentation.
///
/// Despite this, CoordinateLabelsLayerDelegate adopts the PlayViewLayerDelegate
/// protocol so that it and PlayView can make use of the same event and drawing
/// mechanisms that are also used by other layer delegates.
// -----------------------------------------------------------------------------
@interface CoordinateLabelsLayerDelegate : PlayViewLayerDelegateBase
{
}

- (id) initWithMainView:(UIView*)mainView
                metrics:(PlayViewMetrics*)metrics
                  model:(PlayViewModel*)playViewModel
                   axis:(enum CoordinateLabelAxis)axis;

/// @brief The axis that CoordinateLabelsLayerDelegate is drawing.
@property(nonatomic, assign) enum CoordinateLabelAxis coordinateLabelAxis;

@end
