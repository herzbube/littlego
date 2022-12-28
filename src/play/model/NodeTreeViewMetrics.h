// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The NodeTreeViewMetrics class is a model class that provides
/// locations and sizes (i.e. "metrics") of node tree elements that can be used
/// to draw those elements.
///
/// All metrics refer to an imaginary canvas that contains the entire tree of
/// nodes. The size of the canvas is determined by two things:
/// - A base size that is equal to the bounds size of the scroll view that
///   displays the part of the tree of nodes  that is currently visible
/// - The base size is multiplied by a scale factor that is equal to the zoom
///   scale that is currently in effect.
///
/// Effectively, the canvas is equal to the content of the scroll view that
/// displays the tree of nodes. If the scroll view frame size changes (e.g. when
/// an interface orientation change occurs), someone must invoke
/// updateWithBaseSize:(). If the zoom scale changes, someone must invoke
/// updateWithRelativeZoomScale:().
///
/// Additional properties that influence the metrics calculated by
/// NodeTreeViewMetrics are:
/// - TODO xxx
///
/// If any of these xxx updaters is invoked, NodeTreeViewMetrics re-calculates
/// all of its properties. Clients are expected to use KVO to notice any changes
/// in self.canvasSize, xxx or xxx, and to respond
/// to such changes by initiating the re-drawing of the appropriate parts of the
/// tree of nodes.
///
///
/// @par Calculations
///
/// TODO xxx
///
///
/// @par Anti-aliasing
///
/// See the documentation of BoardViewMetrics for details.
// -----------------------------------------------------------------------------
@interface NodeTreeViewMetrics : NSObject
{
}

- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel;

/// @name Updaters
//@{
- (void) updateWithBaseSize:(CGSize)newBaseSize;
- (void) updateWithRelativeZoomScale:(CGFloat)newRelativeZoomScale;
//@}

/// @name Calculators
//@{
//@}


// -----------------------------------------------------------------------------
/// @name Main properties
// -----------------------------------------------------------------------------
//@{
/// @brief The canvas size. This is a calculated property that depends on the
/// @e baseSize and @e absoluteZoomScale properties.
///
/// Clients that use KVO on this property will be triggered after
/// NodeTreeViewMetrics has updated its values to match the new size.
@property(nonatomic, assign) CGSize canvasSize;
//@}

// -----------------------------------------------------------------------------
/// @name Properties that @e canvasSize depends on
// -----------------------------------------------------------------------------
//@{
@property(nonatomic, assign) CGSize baseSize;
@property(nonatomic, assign) CGFloat absoluteZoomScale;
//@}

// -----------------------------------------------------------------------------
/// @name Properties that depend on main properties
// -----------------------------------------------------------------------------
//@{
//@}

// -----------------------------------------------------------------------------
/// @name Static properties whose values never change
// -----------------------------------------------------------------------------
//@{
/// @brief This is the scaling factor that must be taken into account by layers
/// and drawing methods in order to support Retina displays.
///
/// See the documentation of BoardViewMetrics::contentsScale for details.
@property(nonatomic, assign) CGFloat contentsScale;
@property(nonatomic, assign) CGSize tileSize;
@property(nonatomic, assign) CGFloat minimumAbsoluteZoomScale;
@property(nonatomic, assign) CGFloat maximumAbsoluteZoomScale;
//@}

@end
