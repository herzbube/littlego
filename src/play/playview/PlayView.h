// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayViewIntersection.h"

// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The PlayView class is a custom view that is responsible for drawing
/// the Go board on the "Play" tab.
///
/// The view content is drawn in layers:
/// - View background
/// - Grid lines
/// - Cross-hair lines (during stone placement)
/// - Star points
/// - Played stones (if any)
/// - Cross-hair stone (during stone placement)
/// - Symbols (if any)
/// - Territory coloring (in scoring mode only)
/// - Dead stone state (in scoring mode only)
///
/// @todo These days the class name "PlayView" is a bit of a misnomer, it should
/// probably be renamed to something like "BoardView". The name has its root in
/// the early days of the app when there was only a single view on the "Play"
/// tab and there were only very few classes, so "PlayView" seemed to be a good
/// choice.
///
///
/// @par Coordinate labels
///
/// Coordinate labels are drawn in separate views so that those views can be
/// placed in the view hierarchy independently of PlayView. This is necessary
/// because the user must be able to see coordinate labels even if PlayView is
/// zoomed in and scrolled to a position where the board edges are no longer
/// visible.
///
/// PlayView is responsible for creating and deallocating coordinate label
/// views, and for triggering view updates when events occur. An external
/// controller is responsible for placing coordinate label views into the
/// view hierarchy.
///
///
/// @par Delayed updates
///
/// PlayView utilizes long-running actions to delay view updates. Events that
/// would normally trigger drawing updates are processed as normal, but the
/// drawing itself is delayed. When the #longRunningActionEnds notification
/// is received, all drawing updates that have accumulated are now coalesced
/// into a single update.
///
/// As a consequence, clients that want to update the view must invoke
/// delayedUpdate() instead of setNeedsDisplay(). Using delayedUpdate() makes
/// sure that the update occurs at the right time, either immediately, or after
/// a long-running action has ended.
///
///
/// @par Auto Layout
///
/// PlayView is not a container view (i.e. it does not consist of subviews) but
/// draws its own content. For the purposes of Auto Layout it therefore has an
/// intrinsic content size - its size is not derived from the size of any views
/// that it contains, but from the size of the content that it is supposed to
/// draw.
///
/// On the other hand, PlayView never changes its own content size, regardless
/// of what it is supposed to draw (compare this to, for instance, a UILabel
/// that changes its content size depending on the text that it should display).
/// Instead, PlayView adjusts the stuff it draws to the size that is available.
/// For instance, board and stones are simply drawn bigger or smaller depending
/// on how much space PlayView gets to draw.
///
/// As a consequence, PlayView's intrinsic content size can only change in
/// response to external events. These events must be communicated to PlayView
/// by invoking updateIntrinsicContentSize:(). Currently only a handful events
/// are known:
/// - When the size of the parent scroll view changes (e.g. due to rotation of
///   the interface
/// - When the user zooms the PlayView
///
///
/// @par Implementation notes
///
/// PlayView acts as a facade that hides the drawing and layer management
/// details from outside forces. For instance, although PlayViewController
/// closely interacts with PlayView, it does not need to know how exactly the
/// Go board is drawn. One early implementation of PlayView did all the drawing
/// in a single drawRect:() implementation, while later implementations
/// distributed responsibility for drawing each layer to dedicated layer
/// delegate classes. Because this happened behind the PlayView facade, there
/// was no need to change PlayViewController.
///
/// If we look at PlayView from the inside of the facade, its main
/// responsibility is that of a coordinating agent. PlayView is the central
/// receiver of events that occur in the application. It distributes those
/// events to all of its sub-objects, which then decide on their own whether
/// they are affected by each event, and how. If necessary, PlayView updates
/// drawing metrics before an event is distributed. After an event is
/// distributed, PlayView initiates redrawing at the proper moment. This may
/// be immediately, or after some delay. See the "Delayed updates" section
/// above.
// -----------------------------------------------------------------------------
@interface PlayView : UIView
{
}

- (PlayViewIntersection) crossHairIntersectionNear:(CGPoint)coordinates;
- (void) moveCrossHairTo:(GoPoint*)point isLegalMove:(bool)isLegalMove isIllegalReason:(enum GoMoveIsIllegalReason)illegalReason;
- (PlayViewIntersection) intersectionNear:(CGPoint)coordinates;

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
/// @brief If crossHairPointIsLegalMove is false, this contains the reason why
/// the move is illegal.
///
/// This property cannot be monitored via KVO.
@property(nonatomic, assign) enum GoMoveIsIllegalReason crossHairPointIsIllegalReason;
//@}

@end
