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
/// @brief Enumerates the styles of drag handles supported by
/// ResizableStackViewController.
// -----------------------------------------------------------------------------
enum DragHandleStyle
{
  /// @brief Drag handles are drawn as transparent overlays between child views.
  /// Drag handles of this style do not use up any space, at the cost of
  /// slightly covering a small part of the child views' edges. This is the
  /// default drag handle style.
  DragHandleStyleOverlay,
  /// @brief Drag handles are integrated into the stack. Child views are clearly
  /// separated by slim divider views into which the drag handles are embedded.
  /// Drag handles of this style use up a small amount of space.
  ///
  /// THIS STYLE IS CURRENTLY NOT YET IMPLEMENTED. If this style is used it
  /// currently behaves the same as #DragHandleStyleOverlay.
  ///
  /// @todo Implement #DragHandleStyleIntegrated.
  DragHandleStyleIntegrated,
  /// @brief ResizableStackViewController does not display any drag handles.
  /// Child views can be resized by simply dragging them. The edge that is
  /// closest to the location where the drag gesture starts determines which
  /// views are resized.
  ///
  /// This style is not recommended, because it does not give the user a visual
  /// cue that resizing is possible. Also the drag gesture may interfere with
  /// other gestures implemented on child views, or vice versa. This style
  /// exists only because ResizableStackViewController was initially developed
  /// with this style and it seemed a pity to discard the code.
  DragHandleStyleNone,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the presentation styles of drag handles supported by
/// ResizableStackViewController.
// -----------------------------------------------------------------------------
enum DragHandlePresentationStyle
{
  /// @brief Drag handles are drawn as bars with a rounded cap at both ends.
  /// The bar thickness is determined by the ResizableStackViewController
  /// property @e dragHandleThickness. This is the default drag handle
  /// presentation style.
  DragHandlePresentationStyleBar,
  /// @brief Drag handles are drawn as stroked lines. The stroke width is
  /// determined by the ResizableStackViewController property
  /// @e dragHandleThickness.
  DragHandlePresentationStyleLine,
};

// -----------------------------------------------------------------------------
/// @brief The ResizableStackViewController class is a container view controller
/// that arranges the views of its child view controllers in a stack along one
/// axis and lets the user interactively change the view sizes along that axis.
///
/// ResizableStackViewController by default displays a drag handle between each
/// of the views of its child view controllers. A drag handle reacts to a
/// gesture with which the user grabs the handle and moves it along the axis in
/// which ResizableStackViewController arranges its views. Moving the handle
/// only resizes the two views that are adjacent to the handle, the size of
/// other views does not change.
///
/// ResizableStackViewController supports setting a minimum size for each of its
/// arranged views.
///
/// @note If ResizableStackViewController is configured with
/// #DragHandleStyleNone, no drag handles are shown and resizing works by simply
/// dragging any view that is laid out by ResizableStackViewController. This is
/// a legacy feature that may be removed in the future.
///
/// Resizing can be disabled by setting the property @e resizingEnabled to
/// @e false. ResizableStackViewController in that case removes all sizing
/// Auto Layout constraints and no longer allows interactive resizing. Drag
/// handles are no longer displayed. The values of the properties @e sizes
/// and @e minimumSizes are ignored.
///
/// ResizableStackViewController also does not allow interactive resizing while
/// there is only a single child view controller, however in that case it
/// assigns the single child view controller's view a size of 100%.
// -----------------------------------------------------------------------------
@interface ResizableStackViewController : UIViewController <UIGestureRecognizerDelegate>
{
}

+ (ResizableStackViewController*) resizableStackViewControllerWithViewControllers:(NSArray*)viewControllers;
+ (ResizableStackViewController*) resizableStackViewControllerWithViewControllers:(NSArray*)viewControllers
                                                                             axis:(UILayoutConstraintAxis)axis;

/// @brief The child view controllers of ResizableStackViewController.
///
/// When this property is set and the property @e resizingEnabled is @e true,
/// ResizableStackViewController discards the current value of the property
/// @e sizes and instead sets new sizes that equally distribute the available
/// space to the views of the newly set view controllers, as far as is possible
/// by honoring the minimum sizes stored in the property @e minimumSizes. For a
/// detailed description of the distribution algorithm, see the documentation of
/// property @e sizes.
///
/// When this property is set and the property @e resizingEnabled is @e false,
/// ResizableStackViewController does not assign any sizes to the views of the
/// newly set view controllers. It simply layouts them along the currently
/// configured axis. If the number of newly set view controllers differs from
/// the number of sizes, the number of sizes is adjusted accordingly (surplus
/// sizes are discarded from the end of the list, missing sizes are added with
/// value 0).
///
/// Regardless of the value of the property @e resizingEnabled, if the number of
/// newly set view controllers differs from the number of minimum sizes, the
/// number of minimum sizes is adjusted accordingly (surplus minimum sizes are
/// discarded from the end of the list, missing minimum sizes are added with
/// value 0).
///
/// Setting this property with @e nil will result in the property holding an
/// empty array.
@property (nonatomic, copy) NSArray* viewControllers;

/// @brief The axis along which ResizableStackViewController arranges the views
/// of its child view controllers. A stack with a horizontal axis is a row of
/// views, a stack with a vertical axis is a column of views. The default value
/// is @e UILayoutConstraintAxisHorizontal.
@property(nonatomic, assign) UILayoutConstraintAxis axis;

/// @brief The sizes assigned to the views of the child view controllers. Array
/// elements are NSNumber objects that hold a double value. Each double value
/// expresses a view's relative size as a percentage of the container view. For
/// instance, a relative size of 50% is expressed as the double value 0.5.
///
/// The number of sizes stored in this property is equal to the number of view
/// controllers (property @e viewControllers). Index positions in both lists
/// refer to the same view.
///
/// When this property is set ResizableStackViewController updates the size
/// constraints of the views of its child view controllers according to the new
/// values. Obviously, the sum of all values should equal 100%, but
/// ResizableStackViewController does not take corrective action to ensure this.
/// ResizableStackViewController @b does take corrective action in the following
/// cases:
/// - A size that is less than zero is corrected to be zero.
/// - A size that is less than the corresponding minimum size is corrected to be
///   equal to the corresponding minimum size. Because the other sizes are not
///   adjusted, as a result the sum of sizes may may become greater than 100%.
/// - If the new number of sizes exceeds the number of view controllers, surplus
///   sizes are discarded from the end of the list. As a result the sum of the
///   remaining sizes may be less than 100%.
/// - If the new number of sizes is less than the number of view controllers,
///   missing sizes are created to match the two numbers. The new sizes are set
///   so that they fill up any leftover space to 100%. Leftover space is
///   distributed equally among the newly created sizes. Example: If there are
///   3 view controllers, setting this property with only one 50% size will
///   cause two new 25% sizes to be created. The distribution algorithm honors
///   minimum sizes while also following the goal to not exceed 100%. Example:
///   There are 4 view controllers, and minimum sizes of 20%, 30% and 2x 10%
///   are set for them. Setting this property with only one 40% size will cause
///   three new sizes to be created. The attempt to equally distribute the
///   remaining size of 60% and assign 20% to each of the three sizes will fail
///   because of the second minimum size of 30%. The algorithm will therefore
///   set the second size to 30%, and the third and fourth size will get 15%
///   each (equal distribution of the remaining 30%). Note that the end result
///   may exceed 100% because the algorithm never adjusts sizes that are set
///   explicitly. Example: If there are 3 view controllers with minimum sizes
///   30% each, setting this property with only one 60% size will cause two new
///   30% sizes to be created, resulting in a total of 120%.
///
/// Setting this property has no effect on the layout if @a resizingEnabled is
/// @e false.
///
/// Setting this property with @e nil has the same effect as setting an empty
/// array.
///
/// @note In order to avoid unsatisfiable layout constraints due to rounding
/// errors, double values should not be specified with arbitrary fractional
/// digits. Two fractional digits (e.g. 0.01, 0.99) expressing an integer
/// percentage should be sufficient in most cases.
@property (nonatomic, copy) NSArray* sizes;

/// @brief The minimum sizes assigned to the views of the child view
/// controllers. Array elements are NSNumber objects that hold a double value.
/// Each double value expresses a view's relative minimum size as a percentage
/// of the container view. For instance, a relative minimum size of 50% is
/// expressed as the double value 0.5.
///
/// The number of minimum sizes stored in this property is equal to the number
/// of view controllers (property @e viewControllers). Index positions in both
/// lists refer to the same view.
///
/// When this property is set ResizableStackViewController does @b not adjust
/// sizes in the property @e sizes that are lower than the corresponding new
/// minimum sizes. ResizableStackViewController also does not take corrective
/// action to ensure that the sum of new minimum sizes does not exceed 100%.
/// ResizableStackViewController @b does take corrective action in the following
/// cases:
/// - A minimum size that is less than zero is corrected to be zero.
/// - If the new number of minimum sizes exceeds the number of view controllers,
///   surplus minimum sizes are discarded from the end of the list.
/// - If the new number of minimum sizes is less than the number of view
///   controllers, missing minimum sizes are created to match the two numbers.
///   The new minimum sizes are set to 0%.
///
/// Setting this property with @e nil has the same effect as setting an empty
/// array.
///
/// @note In order to avoid unsatisfiable layout constraints due to rounding
/// errors, double values should not be specified with arbitrary fractional
/// digits. Two fractional digits (e.g. 0.01, 0.99) expressing an integer
/// percentage should be sufficient in most cases.
@property (nonatomic, copy) NSArray* minimumSizes;

/// @brief @e true if ResizableStackViewController should apply size constraints
/// to the views of its child view controllers and allow interactive resizing.
/// @e false if ResizableStackViewController should apply no size constraints
/// and not allow interactive resizing. The default value is @e true.
///
/// When this property is set to @e false, ResizableStackViewController removes
/// all size constraints that are currently in effect, and it no longer allows
/// interactive resizing (it no longer displays drag handles). The values of the
/// properties @e sizes and @e minimumSizes are maintained but simply have no
/// effect anymore.
///
/// When this property is set to @e true, ResizableStackViewController applies
/// size constraints corresponding to the value of the property @e sizes to the
/// views of its child view controllers, and it again allows interactive
/// resizing (it displays drag handles).
@property (nonatomic, assign) bool resizingEnabled;

/// @brief Indicator for how far a drag handle must be moved before a resize
/// takes place. A zero value indicates continuous resizes, a non-zero value
/// indicates that resizes take place only in discrete steps. The higher the
/// value the smaller the steps. The default value is 100.
///
/// The total size of the container view is divided by the number that this
/// property holds. The result is the amount of space that the user must move
/// a drag handle before a resize takes place. The default value 100, for
/// instance, causes resizes to take place only every 100th of the container
/// view's size.
///
/// Higher values therefore cause more resizes because the distance that a drag
/// handle must move is smaller. The effect is that the resizing appears to be
/// smoother. However, more resizes also means more redraws, i.e. more CPU
/// usage. A view that is expensive to redraw may require this property to be
/// set with a lower value.
///
/// Lower values cause less resizes. Besides reducing the amount of CPU usage,
/// this can also be interesting to create a snap-to effect for very low values.
@property (nonatomic, assign) unsigned int resizeStepSize;

/// @brief The style of drag handles to be used. The default value is
/// #DragHandleStyleOverlay.
@property (nonatomic, assign) enum DragHandleStyle dragHandleStyle;

/// @brief The spacing to add between resizable panes. Half of the value of this
/// property is added to both panes where they have a common edge. The spacing
/// is useful when @a dragHandleStyle has the value #DragHandleStyleOverlay and
/// the drag handles would draw over the content of the resizable panes.
///
/// The spacing is included in the size of each pane.
@property (nonatomic, assign) CGFloat spacingBetweenResizablePanes;

/// @brief The presentation style of drag handles to be used. The default value
/// is #DragHandlePresentationStyleBar.
@property (nonatomic, assign) enum DragHandlePresentationStyle dragHandlePresentationStyle;

/// @brief The color with which drag handles are filled or stroked (which is
/// determined by the value of the property @e dragHandlePresentationStyle) in
/// light user interface style (i.e. not dark mode). The default is a
/// semi-transparent black color.
@property (nonatomic, retain) UIColor* dragHandleColorLightUserInterfaceStyle;

/// @brief The color with which drag handles are filled or stroked (which is
/// determined by the value of the property @e dragHandlePresentationStyle) in
/// dark user interface style (i.e. dark mode). The default is a
/// semi-transparent white color.
@property (nonatomic, retain) UIColor* dragHandleColorDarkUserInterfaceStyle;

/// @brief The thickness of the visible part of drag handles, i.e. the size
/// of the visible part of drag handles in direction of the axis along which
/// ResizableStackViewController arranges the views of its child view
/// controllers. See property @e dragHandleGrabAreaMargin. The default value is
/// 4.0f.
///
/// If the @e axis property holds the value #UILayoutConstraintAxisHorizontal
/// then this property determines the width of the visible part of drag handles.
/// If the @e axis property holds the value #UILayoutConstraintAxisVertical
/// then this property determines the height of the visible part of drag
/// handles.
@property (nonatomic, assign) CGFloat dragHandleThickness;

/// @brief The size of an additional margin added to increase the grab area of
/// drag handles. Nothing is drawn in the area covered by the margin, i.e. the
/// margin is transparent. The margin is added to @b both sides of drag handles,
/// along the same axis that is also used for @e dragHandleThickness. The
/// default value is 4.0f.
///
/// If the @e axis property holds the value #UILayoutConstraintAxisHorizontal
/// then this property increases the width of drag handles. If the @e axis
/// property holds the value #UILayoutConstraintAxisVertical then this property
/// increases the height of drag handles.
@property (nonatomic, assign) CGFloat dragHandleGrabAreaMargin;

/// @brief The size of drag handles counter the direction of the axis along
/// which ResizableStackViewController arranges the views of its child view
/// controllers. The size is expressed as a percentage relative to the size of
/// ResizableStackViewController's main view in the same direction. For
/// instance, 50% is expressed as the float value 0.5f. The default value is
/// 0.25f.
///
/// If the @e axis property holds the value #UILayoutConstraintAxisHorizontal
/// then this property determines the height of drag handles. If the @e axis
/// property holds the value #UILayoutConstraintAxisVertical then this property
/// determines the width of drag handles.
@property (nonatomic, assign) CGFloat dragHandleSizePercentageCounterAxis;

@end
