// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The KeyboardHeightAdjustment category enhances NSObject by adding
/// functionality that lets an object react to the appearance/disappearance of
/// the device's software keyboard by adjusting the height of a specified
/// UIView.
// -----------------------------------------------------------------------------
@interface NSObject(KeyboardHeightAdjustment)

/// @brief Begins observing system events and reacting to the appearance and
/// disappearance of the device's software keyboard. @a viewToAdjustHeight is
/// the view whose height will change when the keyboard appears/disappears.
/// The bottom edge of @a viewToAdjustHeight is aligned to the bottom edge of
/// @a referenceView.
///
/// The height adjustment works by creating/removing Auto Layout constraints
/// in reaction to the software keyboard appearing/disappearing. The height
/// @a viewToAdjustHeight is defined by aligning the bottom edge of
/// @a viewToAdjustHeight to the bottom edge of the layout guide of
/// @a referenceView. When the keyboard appears this constraint is modified
/// by the height of the keyboard.
///
/// For this scheme to work, a number of things must be guaranteed:
/// - @a viewToAdjustHeight must be a descendant view of @a referenceView in
///   the view hierarchy.
/// - No one else is allowed to define Auto Layout constraints that specify the
///   height of @a viewToAdjustHeight, or the location of the bottom edge of
///   @a viewToAdjustHeight.
/// - @a referenceView must extend to the bottom of the screen to where the
//    keyboard pops up from.
///
/// @note Invoking this method must be balanced by invoking
/// endObservingKeyboardWithViewToAdjustHeight:(). An object can make only one
/// UIView to adjust its height at the same time.
- (void) beginObservingKeyboardWithViewToAdjustHeight:(UIView*)viewToAdjustHeight referenceView:(UIView*)referenceView;

/// @brief Ends observing system events and reacting to the appearance and
/// disappearance of the device's software keyboard.
- (void) endObservingKeyboardWithViewToAdjustHeight:(UIView*)viewToAdjustHeight referenceView:(UIView*)referenceView;

/// @brief Returns true if observing of system events and reacting to the
/// appearance and disappearance of the device's software keyboard is currently
/// active for the combination of @a viewToAdjustHeight and @a referenceView.
/// Returns false if observing is not active, or is active but for a different
/// view.
- (bool) isObservingKeyboardWithViewToAdjustHeight:(UIView*)viewToAdjustHeight referenceView:(UIView*)referenceView;

@end
