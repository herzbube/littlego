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
#import "../../ui/Tile.h"


// -----------------------------------------------------------------------------
/// @brief The CoordinateLabelsTileView class is a custom view that is
/// responsible for drawing only a small part (called a "tile") of the visible
/// part of one of the coordinate labels axis of the Go board.
///
/// CoordinateLabelsTileView draws either letter or number coordinates,
/// depending on the axis specified during initialization.
///
/// Most of what is said in the documentation of the BoardTileView class also
/// applies to the CoordinateLabelsTileView class. The difference is that
/// CoordinateLabelsTileView has only one layer and therefore does not need to
/// dynamically add/remove layers. Instead, an outside force is responsible for
/// adding/removing CoordinateLabelsTileView instances depending on whether
/// coordinate labels should be displayed, or not.
///
///
/// @par Implementation note
///
/// Coordinate labels must be drawn independently from the remaining board
/// elements so that the user can always see the labels even if the board is
/// zoomed in and scrolled to a position where the board edges are no longer
/// visible.
///
/// The way to achieve this is to display coordinate labels in additional scroll
/// views that scroll independently from the main scroll view that displays the
/// Go board.
///
/// It would have been possible to add BoardTileView instances to those
/// additional scroll views, and to let BoardTileView manage two additional
/// coordinate label layers that are only active when BoardTileView is in
/// "coordinate labels" mode. However, this would have bloated BoardTileView
/// and made the class even more complicated than it already is.
///
/// I believe it is a better design choice to create CoordinateLabelsTileView
/// as a separate class that is dedicated to coordinate label handling.
// -----------------------------------------------------------------------------
@interface CoordinateLabelsTileView : UIView <Tile>
{
}

- (id) initWithFrame:(CGRect)rect axis:(enum CoordinateLabelAxis)axis;

@property(nonatomic, assign) enum CoordinateLabelAxis coordinateLabelAxis;

@end
