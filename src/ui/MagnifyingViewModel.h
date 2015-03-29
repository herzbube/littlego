// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The MagnifyingViewModel class provides user defaults data to its
/// clients related to the magnifying glass functionality.
///
/// Currently this model mixes properties used by the magnifying glass
/// component, and properties used by the application embedding the magnifying
/// glass component. A separation will be necessary if the component is ever
/// extracted from the application.
// -----------------------------------------------------------------------------
@interface MagnifyingViewModel : NSObject
{
}

- (id) init;

- (void) readUserDefaults;
- (void) writeUserDefaults;

/// @brief Determines whether the magnifying glass is always on, always off, or
/// automatically enabled/disabled.
@property(nonatomic, assign) enum MagnifyingGlassEnableMode enableMode;
/// @brief If #MagnifyingGlassEnableModeAuto is set, the magnifying glass is
/// enabled automatically if the grid cell size on the board view falls below
/// this threshold.
@property(nonatomic, assign) CGFloat autoThreshold;
/// @brief The distance of the (center of the) magnifying glass from the
/// center of magnification.
@property(nonatomic, assign) CGFloat distanceFromMagnificationCenter;
/// @brief Determines the direction in which the magnifying glass veers away
/// when it reaches the top of the screen.
@property(nonatomic, assign) enum MagnifyingGlassVeerDirection veerDirection;
/// @brief Determines whether the magnifying glass is updated continuously while
/// the user pans around the Go board, or only if the cross-hair intersection
/// changes.
@property(nonatomic, assign) enum MagnifyingGlassUpdateMode updateMode;
/// @brief The size of the magnifying glass, or rather, of the bounding box
/// around the magnifying glass. The bounding box is square which is why a
/// single value is sufficient to define its size.
@property(nonatomic, assign) CGFloat magnifyingGlassDimension;
/// @brief The scale factor by which the magnifying glass magnifies the content.
@property(nonatomic, assign) CGFloat magnification;

@end
