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
/// @brief The SpacerView class is a UIView subclass with the only purpose to
/// provide an expandable area of screen space, but with a preference of having
/// no size at all.
///
/// The default UIView class has an intrinsic content size with
/// UIViewNoIntrinsicMetric for both width and height. This causes Auto Layout
/// to give an empty UIView (i.e. one without subviews) as much space as is
/// available. SpacerView on the other hand has an intrinsic content size of
/// @e CGSizeZero. This causes Auto Layout to give a SpacerView as little space
/// as possible, preferrably expanding other UIViews instead of SpacerView.
/// However, if there are no other UIViews that can take up the space,
/// SpacerView will expand instead.
///
/// The behaviour of SpacerView can be influenced by the usual methods
/// setContentHuggingPriority:forAxis:() and
/// setContentCompressionResistancePriority:forAxis:().
// -----------------------------------------------------------------------------
@interface SpacerView : UIView
{
}

/// @brief Changes the intrinsic content size value that SpacerView returns when
/// the getter of the property @e intrinsicContentSize is invoked, to the new
/// value @a intrinsicContentSize.
///
/// Invoking this method triggers a new layouting round in the view hierarchy in
/// which SpacerView is located.
///
/// @note This method is not named setIntrinsicContentSize:() to avoid a
/// potential clash with UIKit internals.
- (void) changeIntrinsicContentSize:(CGSize)intrinsicContentSize;

@end
