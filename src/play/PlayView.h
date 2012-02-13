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


// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The PlayView class is a custom view that is responsible for drawing
/// a Go board.
///
/// The view content is drawn in layers:
/// - View background
/// - Board background
/// - Grid lines
/// - Star points
/// - Played stones (if any)
/// - Symbols (if any)
/// - Coordinate labels (if any)
/// - Territory coloring (in scoring mode only)
/// - Dead stone state (in scoring mode only)
///
/// In addition, PlayView writes text into a status line and animates an
/// activity indicator, to provide the user with feedback about operations
/// that are currently going on.
///
/// All coordinate calculations are made with integer types. The actual drawing
/// then uses a half pixel "translation" to prevent anti-aliasing when straight
/// lines are drawn. See http://stackoverflow.com/questions/2488115/how-to-set-up-a-user-quartz2d-coordinate-system-with-scaling-that-avoids-fuzzy-dr
/// for details.
///
/// @note It's not possible to turn off anti-aliasing, instead of doing
/// half-pixel translation. The reason is that 1) round shapes (e.g. star
/// points, stones) do need anti-aliasing; and 2) if not all parts of the view
/// are drawn with anti-aliasing, things become mis-aligned (e.g. stones are
/// not exactly centered on line intersections).
///
/// @note All methods that require a view update should invoke delayedUpdate()
/// instead of setNeedsDisplay() so that multiple updates can be coalesced into
/// a single update, after one or more long-running actions have finished.
// -----------------------------------------------------------------------------
@interface PlayView : UIView
{
}

+ (PlayView*) sharedView;
- (GoPoint*) crossHairPointNear:(CGPoint)coordinates;
- (void) moveCrossHairTo:(GoPoint*)point isLegalMove:(bool)isLegalMove;
- (GoPoint*) pointNear:(CGPoint)coordinates;
- (void) actionStarts;
- (void) actionEnds;
- (void) frameChanged;

/// @name Cross-hair point properties
//@{
/// @brief Refers to the GoPoint object that marks the focus of the cross-hair.
///
/// Observers may monitor this property via KVO. If this property changes its
/// value, observers can also get a correctly updated value from property
/// @e crossHairPointIsLegalMove.
@property(nonatomic, retain) GoPoint* crossHairPoint;
/// @brief Is true if the GoPoint object at the focus of the cross-hair
/// represents a legal move.
///
/// This property cannot be monitored via KVO.
@property(nonatomic, assign) bool crossHairPointIsLegalMove;
//@}

@end
